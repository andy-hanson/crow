#include <assert.h>
#include <errno.h>
#include <stdatomic.h>
#include <stddef.h>
#include <stdint.h>
typedef struct ctx ctx;
typedef uint8_t byte;
typedef byte* ptr__byte;
typedef uint64_t nat;
typedef int32_t int32;
typedef char* ptr__char;
typedef ptr__char* ptr__ptr__char;
typedef struct fut__int32 fut__int32;
typedef struct lock lock;
typedef struct _atomic_bool _atomic_bool;
typedef uint8_t bool;
typedef struct fut_state__int32 fut_state__int32;
typedef struct fut_state_callbacks__int32 fut_state_callbacks__int32;
typedef struct fut_callback_node__int32 fut_callback_node__int32;
typedef uint8_t _void;
typedef struct exception exception;
typedef struct arr__char arr__char;
struct arr__char {
	nat size;
	ptr__char data;
};
typedef struct result__int32__exception result__int32__exception;
typedef struct ok__int32 ok__int32;
struct ok__int32 {
	int32 value;
};
typedef struct err__exception err__exception;
typedef struct fun_mut1___void__result__int32__exception fun_mut1___void__result__int32__exception;
typedef struct opt__ptr_fut_callback_node__int32 opt__ptr_fut_callback_node__int32;
typedef struct none none;
struct none {
	bool __mustBeNonEmpty;
};
typedef struct some__ptr_fut_callback_node__int32 some__ptr_fut_callback_node__int32;
struct some__ptr_fut_callback_node__int32 {
	fut_callback_node__int32* value;
};
typedef struct fut_state_resolved__int32 fut_state_resolved__int32;
struct fut_state_resolved__int32 {
	int32 value;
};
typedef struct arr__arr__char arr__arr__char;
typedef arr__char* ptr__arr__char;
typedef struct global_ctx global_ctx;
typedef struct vat vat;
typedef struct gc gc;
typedef struct gc_ctx gc_ctx;
typedef struct opt__ptr_gc_ctx opt__ptr_gc_ctx;
typedef struct some__ptr_gc_ctx some__ptr_gc_ctx;
struct some__ptr_gc_ctx {
	gc_ctx* value;
};
typedef struct task task;
typedef struct fun_mut0___void fun_mut0___void;
typedef _void (*fun_ptr2___void__ptr_ctx__ptr__byte)(ctx*, ptr__byte);
typedef struct mut_bag__task mut_bag__task;
typedef struct mut_bag_node__task mut_bag_node__task;
typedef struct opt__ptr_mut_bag_node__task opt__ptr_mut_bag_node__task;
typedef struct some__ptr_mut_bag_node__task some__ptr_mut_bag_node__task;
struct some__ptr_mut_bag_node__task {
	mut_bag_node__task* value;
};
typedef struct mut_arr__nat mut_arr__nat;
typedef nat* ptr__nat;
typedef struct thread_safe_counter thread_safe_counter;
typedef struct fun_mut1___void__exception fun_mut1___void__exception;
typedef struct arr__ptr_vat arr__ptr_vat;
typedef vat** ptr__ptr_vat;
typedef struct condition condition;
typedef struct comparison comparison;
typedef struct less less;
struct less {
	bool __mustBeNonEmpty;
};
typedef struct equal equal;
struct equal {
	bool __mustBeNonEmpty;
};
typedef struct greater greater;
struct greater {
	bool __mustBeNonEmpty;
};
typedef bool* ptr__bool;
typedef int64_t _int;
typedef struct exception_ctx exception_ctx;
typedef struct jmp_buf_tag jmp_buf_tag;
typedef struct bytes64 bytes64;
typedef struct bytes32 bytes32;
typedef struct bytes16 bytes16;
struct bytes16 {
	nat n0;
	nat n1;
};
typedef struct bytes128 bytes128;
typedef struct thread_local_stuff thread_local_stuff;
struct thread_local_stuff {
	exception_ctx* exception_ctx;
};
typedef struct arr__ptr__char arr__ptr__char;
struct arr__ptr__char {
	nat size;
	ptr__ptr__char data;
};
typedef struct fun2__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char fun2__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char;
typedef struct fut___void fut___void;
typedef struct fut_state___void fut_state___void;
typedef struct fut_state_callbacks___void fut_state_callbacks___void;
typedef struct fut_callback_node___void fut_callback_node___void;
typedef struct result___void__exception result___void__exception;
typedef struct ok___void ok___void;
struct ok___void {
	_void value;
};
typedef struct fun_mut1___void__result___void__exception fun_mut1___void__result___void__exception;
typedef struct opt__ptr_fut_callback_node___void opt__ptr_fut_callback_node___void;
typedef struct some__ptr_fut_callback_node___void some__ptr_fut_callback_node___void;
struct some__ptr_fut_callback_node___void {
	fut_callback_node___void* value;
};
typedef struct fut_state_resolved___void fut_state_resolved___void;
struct fut_state_resolved___void {
	_void value;
};
typedef struct fun_ref0__int32 fun_ref0__int32;
typedef struct vat_and_actor_id vat_and_actor_id;
struct vat_and_actor_id {
	nat vat;
	nat actor;
};
typedef struct fun_mut0__ptr_fut__int32 fun_mut0__ptr_fut__int32;
typedef fut__int32* (*fun_ptr2__ptr_fut__int32__ptr_ctx__ptr__byte)(ctx*, ptr__byte);
typedef struct fun_ref1__int32___void fun_ref1__int32___void;
typedef struct fun_mut1__ptr_fut__int32___void fun_mut1__ptr_fut__int32___void;
typedef fut__int32* (*fun_ptr3__ptr_fut__int32__ptr_ctx__ptr__byte___void)(ctx*, ptr__byte, _void);
typedef struct opt__ptr__byte opt__ptr__byte;
typedef struct some__ptr__byte some__ptr__byte;
struct some__ptr__byte {
	ptr__byte value;
};
typedef struct then__ptr_fut__int32__ptr_fut___void__fun_ref1__int32___void__lambda0___closure then__ptr_fut__int32__ptr_fut___void__fun_ref1__int32___void__lambda0___closure;
typedef struct forward_to___void__ptr_fut__int32__ptr_fut__int32__lambda0___closure forward_to___void__ptr_fut__int32__ptr_fut__int32__lambda0___closure;
struct forward_to___void__ptr_fut__int32__ptr_fut__int32__lambda0___closure {
	fut__int32* to;
};
typedef struct call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0___closure call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0___closure;
typedef struct call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0__lambda0___closure call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0__lambda0___closure;
typedef struct call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0__lambda1___closure call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0__lambda1___closure;
struct call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0__lambda1___closure {
	fut__int32* res;
};
typedef struct then2__ptr_fut__int32__ptr_fut___void__fun_ref0__int32__lambda0___closure then2__ptr_fut__int32__ptr_fut___void__fun_ref0__int32__lambda0___closure;
typedef struct call__ptr_fut__int32__fun_ref0__int32__lambda0___closure call__ptr_fut__int32__fun_ref0__int32__lambda0___closure;
typedef struct call__ptr_fut__int32__fun_ref0__int32__lambda0__lambda0___closure call__ptr_fut__int32__fun_ref0__int32__lambda0__lambda0___closure;
typedef struct call__ptr_fut__int32__fun_ref0__int32__lambda0__lambda1___closure call__ptr_fut__int32__fun_ref0__int32__lambda0__lambda1___closure;
struct call__ptr_fut__int32__fun_ref0__int32__lambda0__lambda1___closure {
	fut__int32* res;
};
typedef struct add_first_task__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__lambda0___closure add_first_task__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__lambda0___closure;
typedef struct fun_mut1__arr__char__ptr__char fun_mut1__arr__char__ptr__char;
typedef arr__char (*fun_ptr3__arr__char__ptr_ctx__ptr__byte__ptr__char)(ctx*, ptr__byte, ptr__char);
typedef struct fun_mut1__arr__char__nat fun_mut1__arr__char__nat;
typedef arr__char (*fun_ptr3__arr__char__ptr_ctx__ptr__byte__nat)(ctx*, ptr__byte, nat);
typedef struct mut_arr__arr__char mut_arr__arr__char;
struct mut_arr__arr__char {
	bool frozen__q;
	nat size;
	nat capacity;
	ptr__arr__char data;
};
typedef struct map__arr__arr__char__arr__ptr__char__fun_mut1__arr__char__ptr__char__lambda0___closure map__arr__arr__char__arr__ptr__char__fun_mut1__arr__char__ptr__char__lambda0___closure;
typedef _void (*fun_ptr2___void__nat__ptr_global_ctx)(nat, global_ctx*);
typedef struct thread_args__ptr_global_ctx thread_args__ptr_global_ctx;
struct thread_args__ptr_global_ctx {
	fun_ptr2___void__nat__ptr_global_ctx fun;
	nat thread_id;
	global_ctx* arg;
};
typedef thread_args__ptr_global_ctx* ptr__thread_args__ptr_global_ctx;
typedef ptr__byte (*fun_ptr1__ptr__byte__ptr__byte)(ptr__byte);
typedef struct cell__nat cell__nat;
struct cell__nat {
	nat value;
};
typedef struct cell__ptr__byte cell__ptr__byte;
struct cell__ptr__byte {
	ptr__byte value;
};
typedef struct chosen_task chosen_task;
typedef struct opt__task opt__task;
typedef struct some__task some__task;
typedef struct no_chosen_task no_chosen_task;
struct no_chosen_task {
	bool last_thread_out;
};
typedef struct result__chosen_task__no_chosen_task result__chosen_task__no_chosen_task;
typedef struct ok__chosen_task ok__chosen_task;
typedef struct err__no_chosen_task err__no_chosen_task;
struct err__no_chosen_task {
	no_chosen_task value;
};
typedef struct opt__chosen_task opt__chosen_task;
typedef struct some__chosen_task some__chosen_task;
typedef struct opt__opt__task opt__opt__task;
typedef struct some__opt__task some__opt__task;
typedef struct task_and_nodes task_and_nodes;
typedef struct opt__task_and_nodes opt__task_and_nodes;
typedef struct some__task_and_nodes some__task_and_nodes;
typedef struct arr__nat arr__nat;
struct arr__nat {
	nat size;
	ptr__nat data;
};
typedef struct test_options test_options;
struct test_options {
	bool print_tests__q;
	bool overwrite_output__q;
	nat max_failures;
};
typedef struct opt__test_options opt__test_options;
typedef struct some__test_options some__test_options;
struct some__test_options {
	test_options value;
};
typedef struct opt__arr__arr__char opt__arr__arr__char;
typedef struct some__arr__arr__char some__arr__arr__char;
typedef struct arr__opt__arr__arr__char arr__opt__arr__arr__char;
typedef struct fun1__test_options__arr__opt__arr__arr__char fun1__test_options__arr__opt__arr__arr__char;
typedef struct parsed_cmd_line_args parsed_cmd_line_args;
typedef struct dict__arr__char__arr__arr__char dict__arr__char__arr__arr__char;
typedef struct arr__arr__arr__char arr__arr__arr__char;
typedef struct opt__nat opt__nat;
typedef struct some__nat some__nat;
struct some__nat {
	nat value;
};
typedef struct fun_mut1__bool__arr__char fun_mut1__bool__arr__char;
typedef bool (*fun_ptr3__bool__ptr_ctx__ptr__byte__arr__char)(ctx*, ptr__byte, arr__char);
typedef struct mut_dict__arr__char__arr__arr__char mut_dict__arr__char__arr__arr__char;
typedef struct mut_arr__arr__arr__char mut_arr__arr__arr__char;
typedef struct opt__arr__char opt__arr__char;
typedef struct some__arr__char some__arr__char;
struct some__arr__char {
	arr__char value;
};
typedef struct mut_arr__opt__arr__arr__char mut_arr__opt__arr__arr__char;
typedef struct fun_mut1__opt__arr__arr__char__nat fun_mut1__opt__arr__arr__char__nat;
typedef struct fill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat__opt__arr__arr__char__lambda0___closure fill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat__opt__arr__arr__char__lambda0___closure;
typedef struct cell__bool cell__bool;
struct cell__bool {
	bool value;
};
typedef struct fun_mut2___void__arr__char__arr__arr__char fun_mut2___void__arr__char__arr__arr__char;
typedef struct parse_cmd_line_args__opt__test_options__arr__arr__char__arr__arr__char__fun1__test_options__arr__opt__arr__arr__char__lambda0___closure parse_cmd_line_args__opt__test_options__arr__arr__char__arr__arr__char__fun1__test_options__arr__opt__arr__arr__char__lambda0___closure;
typedef struct index_of__opt__nat__arr__arr__char__arr__char__lambda0___closure index_of__opt__nat__arr__arr__char__arr__char__lambda0___closure;
struct index_of__opt__nat__arr__arr__char__arr__char__lambda0___closure {
	arr__char value;
};
typedef struct fun_mut1__char__nat fun_mut1__char__nat;
typedef char (*fun_ptr3__char__ptr_ctx__ptr__byte__nat)(ctx*, ptr__byte, nat);
typedef struct mut_arr__char mut_arr__char;
struct mut_arr__char {
	bool frozen__q;
	nat size;
	nat capacity;
	ptr__char data;
};
typedef struct _op_plus__arr__char__arr__char__arr__char__lambda0___closure _op_plus__arr__char__arr__char__arr__char__lambda0___closure;
struct _op_plus__arr__char__arr__char__arr__char__lambda0___closure {
	arr__char a;
	arr__char b;
};
typedef struct fun_mut1__bool__char fun_mut1__bool__char;
typedef bool (*fun_ptr3__bool__ptr_ctx__ptr__byte__char)(ctx*, ptr__byte, char);
typedef struct r_index_of__opt__nat__arr__char__char__lambda0___closure r_index_of__opt__nat__arr__char__char__lambda0___closure;
struct r_index_of__opt__nat__arr__char__char__lambda0___closure {
	char value;
};
typedef struct dict__arr__char__arr__char dict__arr__char__arr__char;
typedef struct mut_dict__arr__char__arr__char mut_dict__arr__char__arr__char;
struct mut_dict__arr__char__arr__char {
	mut_arr__arr__char* keys;
	mut_arr__arr__char* values;
};
typedef struct key_value_pair__arr__char__arr__char key_value_pair__arr__char__arr__char;
struct key_value_pair__arr__char__arr__char {
	arr__char key;
	arr__char value;
};
typedef struct failure failure;
struct failure {
	arr__char path;
	arr__char message;
};
typedef struct arr__ptr_failure arr__ptr_failure;
typedef failure** ptr__ptr_failure;
typedef struct result__arr__char__arr__ptr_failure result__arr__char__arr__ptr_failure;
typedef struct ok__arr__char ok__arr__char;
struct ok__arr__char {
	arr__char value;
};
typedef struct err__arr__ptr_failure err__arr__ptr_failure;
typedef struct fun_mut1___void__arr__char fun_mut1___void__arr__char;
typedef _void (*fun_ptr3___void__ptr_ctx__ptr__byte__arr__char)(ctx*, ptr__byte, arr__char);
typedef struct stat_t stat_t;
typedef uint32_t nat32;
typedef struct opt__ptr_stat_t opt__ptr_stat_t;
typedef struct some__ptr_stat_t some__ptr_stat_t;
struct some__ptr_stat_t {
	stat_t* value;
};
typedef struct dirent dirent;
typedef uint16_t nat16;
typedef struct bytes256 bytes256;
typedef struct cell__ptr_dirent cell__ptr_dirent;
struct cell__ptr_dirent {
	dirent* value;
};
typedef struct to_mut_arr__ptr_mut_arr__arr__char__arr__arr__char__lambda0___closure to_mut_arr__ptr_mut_arr__arr__char__arr__arr__char__lambda0___closure;
typedef struct mut_slice__arr__char mut_slice__arr__char;
struct mut_slice__arr__char {
	mut_arr__arr__char* backing;
	nat size;
	nat begin;
};
typedef struct each_child_recursive___void__arr__char__fun_mut1__bool__arr__char__fun_mut1___void__arr__char__lambda0___closure each_child_recursive___void__arr__char__fun_mut1__bool__arr__char__fun_mut1___void__arr__char__lambda0___closure;
typedef struct list_compile_error_tests__arr__arr__char__arr__char__lambda1___closure list_compile_error_tests__arr__arr__char__arr__char__lambda1___closure;
struct list_compile_error_tests__arr__arr__char__arr__char__lambda1___closure {
	mut_arr__arr__char* res;
};
typedef struct fun_mut1__arr__ptr_failure__arr__char fun_mut1__arr__ptr_failure__arr__char;
typedef struct mut_arr__ptr_failure mut_arr__ptr_failure;
struct mut_arr__ptr_failure {
	bool frozen__q;
	nat size;
	nat capacity;
	ptr__ptr_failure data;
};
typedef struct flat_map_with_max_size__arr__ptr_failure__arr__arr__char__nat__fun_mut1__arr__ptr_failure__arr__char__lambda0___closure flat_map_with_max_size__arr__ptr_failure__arr__arr__char__nat__fun_mut1__arr__ptr_failure__arr__char__lambda0___closure;
typedef struct fun_mut1___void__ptr_failure fun_mut1___void__ptr_failure;
typedef _void (*fun_ptr3___void__ptr_ctx__ptr__byte__ptr_failure)(ctx*, ptr__byte, failure*);
typedef struct push_all___void__ptr_mut_arr__ptr_failure__arr__ptr_failure__lambda0___closure push_all___void__ptr_mut_arr__ptr_failure__arr__ptr_failure__lambda0___closure;
struct push_all___void__ptr_mut_arr__ptr_failure__arr__ptr_failure__lambda0___closure {
	mut_arr__ptr_failure* a;
};
typedef struct run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0___closure run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0___closure;
struct run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0___closure {
	test_options options;
	arr__char path_to_noze;
	dict__arr__char__arr__char* env;
};
typedef struct process_result process_result;
struct process_result {
	int32 exit_code;
	arr__char stdout;
	arr__char stderr;
};
typedef struct fun_mut2__arr__char__arr__char__arr__char fun_mut2__arr__char__arr__char__arr__char;
typedef arr__char (*fun_ptr4__arr__char__ptr_ctx__ptr__byte__arr__char__arr__char)(ctx*, ptr__byte, arr__char, arr__char);
typedef struct pipes pipes;
struct pipes {
	int32 write_pipe;
	int32 read_pipe;
};
typedef struct posix_spawn_file_actions_t posix_spawn_file_actions_t;
typedef struct cell__int32 cell__int32;
struct cell__int32 {
	int32 value;
};
typedef struct pollfd pollfd;
typedef int16_t int16;
typedef struct arr__pollfd arr__pollfd;
typedef struct handle_revents_result handle_revents_result;
struct handle_revents_result {
	bool had_pollin__q;
	bool hung_up__q;
};
typedef struct fun_mut1__ptr__char__nat fun_mut1__ptr__char__nat;
typedef ptr__char (*fun_ptr3__ptr__char__ptr_ctx__ptr__byte__nat)(ctx*, ptr__byte, nat);
typedef struct mut_arr__ptr__char mut_arr__ptr__char;
struct mut_arr__ptr__char {
	bool frozen__q;
	nat size;
	nat capacity;
	ptr__ptr__char data;
};
typedef struct _op_plus__arr__ptr__char__arr__ptr__char__arr__ptr__char__lambda0___closure _op_plus__arr__ptr__char__arr__ptr__char__arr__ptr__char__lambda0___closure;
struct _op_plus__arr__ptr__char__arr__ptr__char__arr__ptr__char__lambda0___closure {
	arr__ptr__char a;
	arr__ptr__char b;
};
typedef struct fun_mut1__ptr__char__arr__char fun_mut1__ptr__char__arr__char;
typedef ptr__char (*fun_ptr3__ptr__char__ptr_ctx__ptr__byte__arr__char)(ctx*, ptr__byte, arr__char);
typedef struct map__arr__ptr__char__arr__arr__char__fun_mut1__ptr__char__arr__char__lambda0___closure map__arr__ptr__char__arr__arr__char__fun_mut1__ptr__char__arr__char__lambda0___closure;
typedef struct fun_mut2___void__arr__char__arr__char fun_mut2___void__arr__char__arr__char;
typedef _void (*fun_ptr4___void__ptr_ctx__ptr__byte__arr__char__arr__char)(ctx*, ptr__byte, arr__char, arr__char);
typedef struct convert_environ__ptr__ptr__char__ptr_dict__arr__char__arr__char__lambda0___closure convert_environ__ptr__ptr__char__ptr_dict__arr__char__arr__char__lambda0___closure;
struct convert_environ__ptr__ptr__char__ptr_dict__arr__char__arr__char__lambda0___closure {
	mut_arr__ptr__char* res;
};
typedef struct fun0__result__arr__char__arr__ptr_failure fun0__result__arr__char__arr__ptr_failure;
typedef struct fun_mut1__result__arr__char__arr__ptr_failure__arr__char fun_mut1__result__arr__char__arr__ptr_failure__arr__char;
typedef struct first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure__lambda0___closure first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure__lambda0___closure;
typedef struct first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure__lambda0__lambda0___closure first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure__lambda0__lambda0___closure;
struct first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure__lambda0__lambda0___closure {
	arr__char a_descr;
};
typedef struct do_test__int32__test_options__lambda0___closure do_test__int32__test_options__lambda0___closure;
struct do_test__int32__test_options__lambda0___closure {
	arr__char test_path;
	arr__char noze_exe;
	dict__arr__char__arr__char* env;
	test_options options;
};
typedef struct list_ast_and_model_tests__arr__arr__char__arr__char__lambda1___closure list_ast_and_model_tests__arr__arr__char__arr__char__lambda1___closure;
struct list_ast_and_model_tests__arr__arr__char__arr__char__lambda1___closure {
	mut_arr__arr__char* res;
};
typedef struct run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0___closure run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0___closure;
struct run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0___closure {
	test_options options;
	arr__char path_to_noze;
	dict__arr__char__arr__char* env;
};
typedef struct fun_mut0__arr__ptr_failure fun_mut0__arr__ptr_failure;
typedef struct run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0__lambda0___closure run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0__lambda0___closure;
struct run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0__lambda0___closure {
	arr__char path_to_noze;
	dict__arr__char__arr__char* env;
	arr__char test;
	test_options options;
};
typedef struct run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0__lambda0__lambda0___closure run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0__lambda0__lambda0___closure;
struct run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0__lambda0__lambda0___closure {
	arr__char path_to_noze;
	dict__arr__char__arr__char* env;
	arr__char test;
	test_options options;
};
typedef struct do_test__int32__test_options__lambda0__lambda0___closure do_test__int32__test_options__lambda0__lambda0___closure;
struct do_test__int32__test_options__lambda0__lambda0___closure {
	arr__char test_path;
	arr__char noze_exe;
	dict__arr__char__arr__char* env;
	test_options options;
};
typedef struct list_runnable_tests__arr__arr__char__arr__char__lambda1___closure list_runnable_tests__arr__arr__char__arr__char__lambda1___closure;
struct list_runnable_tests__arr__arr__char__arr__char__lambda1___closure {
	mut_arr__arr__char* res;
};
typedef struct run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0___closure run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0___closure;
struct run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0___closure {
	test_options options;
	arr__char path_to_noze;
	dict__arr__char__arr__char* env;
};
typedef struct do_test__int32__test_options__lambda1___closure do_test__int32__test_options__lambda1___closure;
struct do_test__int32__test_options__lambda1___closure {
	arr__char noze_path;
	test_options options;
};
typedef struct list_lintable_files__arr__arr__char__arr__char__lambda1___closure list_lintable_files__arr__arr__char__arr__char__lambda1___closure;
struct list_lintable_files__arr__arr__char__arr__char__lambda1___closure {
	mut_arr__arr__char* res;
};
typedef struct lint__result__arr__char__arr__ptr_failure__arr__char__test_options__lambda0___closure lint__result__arr__char__arr__ptr_failure__arr__char__test_options__lambda0___closure;
struct lint__result__arr__char__arr__ptr_failure__arr__char__test_options__lambda0___closure {
	test_options options;
};
typedef struct fun_mut2___void__arr__char__nat fun_mut2___void__arr__char__nat;
typedef _void (*fun_ptr4___void__ptr_ctx__ptr__byte__arr__char__nat)(ctx*, ptr__byte, arr__char, nat);
typedef struct fun_mut2___void__char__nat fun_mut2___void__char__nat;
typedef _void (*fun_ptr4___void__ptr_ctx__ptr__byte__char__nat)(ctx*, ptr__byte, char, nat);
typedef struct lines__arr__arr__char__arr__char__lambda0___closure lines__arr__arr__char__arr__char__lambda0___closure;
struct lines__arr__arr__char__arr__char__lambda0___closure {
	mut_arr__arr__char* res;
	arr__char s;
	cell__nat* last_nl;
};
typedef struct lint_file__arr__ptr_failure__arr__char__lambda0___closure lint_file__arr__ptr_failure__arr__char__lambda0___closure;
struct lint_file__arr__ptr_failure__arr__char__lambda0___closure {
	bool err_file__q;
	mut_arr__ptr_failure* res;
	arr__char path;
};
struct ctx {
	ptr__byte gctx_ptr;
	nat vat_id;
	nat actor_id;
	ptr__byte gc_ctx_ptr;
	ptr__byte exception_ctx_ptr;
};
struct _atomic_bool {
	bool value;
};
struct exception {
	arr__char message;
};
struct err__exception {
	exception value;
};
struct opt__ptr_fut_callback_node__int32 {
	int kind;
	union {
		none as_none;
		some__ptr_fut_callback_node__int32 as_some__ptr_fut_callback_node__int32;
	};
};
struct arr__arr__char {
	nat size;
	ptr__arr__char data;
};
typedef fut__int32* (*fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char)(ctx*, arr__arr__char);
struct opt__ptr_gc_ctx {
	int kind;
	union {
		none as_none;
		some__ptr_gc_ctx as_some__ptr_gc_ctx;
	};
};
struct fun_mut0___void {
	fun_ptr2___void__ptr_ctx__ptr__byte fun_ptr;
	ptr__byte closure;
};
struct opt__ptr_mut_bag_node__task {
	int kind;
	union {
		none as_none;
		some__ptr_mut_bag_node__task as_some__ptr_mut_bag_node__task;
	};
};
struct mut_arr__nat {
	bool frozen__q;
	nat size;
	nat capacity;
	ptr__nat data;
};
typedef _void (*fun_ptr3___void__ptr_ctx__ptr__byte__exception)(ctx*, ptr__byte, exception);
struct arr__ptr_vat {
	nat size;
	ptr__ptr_vat data;
};
struct comparison {
	int kind;
	union {
		less as_less;
		equal as_equal;
		greater as_greater;
	};
};
struct bytes32 {
	bytes16 n0;
	bytes16 n1;
};
typedef fut__int32* (*fun_ptr4__ptr_fut__int32__ptr_ctx__ptr__byte__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char)(ctx*, ptr__byte, arr__ptr__char, fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char);
struct result___void__exception {
	int kind;
	union {
		ok___void as_ok___void;
		err__exception as_err__exception;
	};
};
typedef _void (*fun_ptr3___void__ptr_ctx__ptr__byte__result___void__exception)(ctx*, ptr__byte, result___void__exception);
struct opt__ptr_fut_callback_node___void {
	int kind;
	union {
		none as_none;
		some__ptr_fut_callback_node___void as_some__ptr_fut_callback_node___void;
	};
};
struct fun_mut0__ptr_fut__int32 {
	fun_ptr2__ptr_fut__int32__ptr_ctx__ptr__byte fun_ptr;
	ptr__byte closure;
};
struct fun_mut1__ptr_fut__int32___void {
	fun_ptr3__ptr_fut__int32__ptr_ctx__ptr__byte___void fun_ptr;
	ptr__byte closure;
};
struct opt__ptr__byte {
	int kind;
	union {
		none as_none;
		some__ptr__byte as_some__ptr__byte;
	};
};
struct add_first_task__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__lambda0___closure {
	arr__ptr__char all_args;
	fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char main_ptr;
};
struct fun_mut1__arr__char__ptr__char {
	fun_ptr3__arr__char__ptr_ctx__ptr__byte__ptr__char fun_ptr;
	ptr__byte closure;
};
struct fun_mut1__arr__char__nat {
	fun_ptr3__arr__char__ptr_ctx__ptr__byte__nat fun_ptr;
	ptr__byte closure;
};
struct map__arr__arr__char__arr__ptr__char__fun_mut1__arr__char__ptr__char__lambda0___closure {
	fun_mut1__arr__char__ptr__char mapper;
	arr__ptr__char a;
};
struct opt__test_options {
	int kind;
	union {
		none as_none;
		some__test_options as_some__test_options;
	};
};
struct some__arr__arr__char {
	arr__arr__char value;
};
struct parsed_cmd_line_args {
	arr__arr__char nameless;
	dict__arr__char__arr__arr__char* named;
	arr__arr__char after;
};
typedef arr__arr__char* ptr__arr__arr__char;
struct opt__nat {
	int kind;
	union {
		none as_none;
		some__nat as_some__nat;
	};
};
struct fun_mut1__bool__arr__char {
	fun_ptr3__bool__ptr_ctx__ptr__byte__arr__char fun_ptr;
	ptr__byte closure;
};
struct mut_dict__arr__char__arr__arr__char {
	mut_arr__arr__char* keys;
	mut_arr__arr__arr__char* values;
};
struct mut_arr__arr__arr__char {
	bool frozen__q;
	nat size;
	nat capacity;
	ptr__arr__arr__char data;
};
struct opt__arr__char {
	int kind;
	union {
		none as_none;
		some__arr__char as_some__arr__char;
	};
};
typedef _void (*fun_ptr4___void__ptr_ctx__ptr__byte__arr__char__arr__arr__char)(ctx*, ptr__byte, arr__char, arr__arr__char);
struct parse_cmd_line_args__opt__test_options__arr__arr__char__arr__arr__char__fun1__test_options__arr__opt__arr__arr__char__lambda0___closure {
	arr__arr__char t_names;
	cell__bool* help;
	mut_arr__opt__arr__arr__char* values;
};
struct fun_mut1__char__nat {
	fun_ptr3__char__ptr_ctx__ptr__byte__nat fun_ptr;
	ptr__byte closure;
};
struct fun_mut1__bool__char {
	fun_ptr3__bool__ptr_ctx__ptr__byte__char fun_ptr;
	ptr__byte closure;
};
struct dict__arr__char__arr__char {
	arr__arr__char keys;
	arr__arr__char values;
};
struct arr__ptr_failure {
	nat size;
	ptr__ptr_failure data;
};
struct err__arr__ptr_failure {
	arr__ptr_failure value;
};
struct fun_mut1___void__arr__char {
	fun_ptr3___void__ptr_ctx__ptr__byte__arr__char fun_ptr;
	ptr__byte closure;
};
struct stat_t {
	nat st_dev;
	nat32 pad0;
	nat st_ino_unused;
	nat32 st_mode;
	nat32 st_nlink;
	nat st_uid;
	nat st_gid;
	nat st_rdev;
	nat32 pad1;
	_int st_size;
	nat st_blksize;
	nat st_blocks;
	nat st_atime;
	nat st_atime_nsec;
	nat st_mtime;
	nat st_mtime_nsec;
	nat st_ctime;
	nat st_ctime_nsec;
	nat st_ino;
	nat unused;
};
struct opt__ptr_stat_t {
	int kind;
	union {
		none as_none;
		some__ptr_stat_t as_some__ptr_stat_t;
	};
};
struct to_mut_arr__ptr_mut_arr__arr__char__arr__arr__char__lambda0___closure {
	arr__arr__char a;
};
struct each_child_recursive___void__arr__char__fun_mut1__bool__arr__char__fun_mut1___void__arr__char__lambda0___closure {
	fun_mut1__bool__arr__char filter;
	arr__char path;
	fun_mut1___void__arr__char f;
};
typedef arr__ptr_failure (*fun_ptr3__arr__ptr_failure__ptr_ctx__ptr__byte__arr__char)(ctx*, ptr__byte, arr__char);
struct fun_mut1___void__ptr_failure {
	fun_ptr3___void__ptr_ctx__ptr__byte__ptr_failure fun_ptr;
	ptr__byte closure;
};
struct fun_mut2__arr__char__arr__char__arr__char {
	fun_ptr4__arr__char__ptr_ctx__ptr__byte__arr__char__arr__char fun_ptr;
	ptr__byte closure;
};
struct pollfd {
	int32 fd;
	int16 events;
	int16 revents;
};
typedef pollfd* ptr__pollfd;
struct fun_mut1__ptr__char__nat {
	fun_ptr3__ptr__char__ptr_ctx__ptr__byte__nat fun_ptr;
	ptr__byte closure;
};
struct fun_mut1__ptr__char__arr__char {
	fun_ptr3__ptr__char__ptr_ctx__ptr__byte__arr__char fun_ptr;
	ptr__byte closure;
};
struct map__arr__ptr__char__arr__arr__char__fun_mut1__ptr__char__arr__char__lambda0___closure {
	fun_mut1__ptr__char__arr__char mapper;
	arr__arr__char a;
};
struct fun_mut2___void__arr__char__arr__char {
	fun_ptr4___void__ptr_ctx__ptr__byte__arr__char__arr__char fun_ptr;
	ptr__byte closure;
};
typedef arr__ptr_failure (*fun_ptr2__arr__ptr_failure__ptr_ctx__ptr__byte)(ctx*, ptr__byte);
struct fun_mut2___void__arr__char__nat {
	fun_ptr4___void__ptr_ctx__ptr__byte__arr__char__nat fun_ptr;
	ptr__byte closure;
};
struct fun_mut2___void__char__nat {
	fun_ptr4___void__ptr_ctx__ptr__byte__char__nat fun_ptr;
	ptr__byte closure;
};
struct lock {
	_atomic_bool is_locked;
};
struct fut_state_callbacks__int32 {
	opt__ptr_fut_callback_node__int32 head;
};
struct result__int32__exception {
	int kind;
	union {
		ok__int32 as_ok__int32;
		err__exception as_err__exception;
	};
};
typedef _void (*fun_ptr3___void__ptr_ctx__ptr__byte__result__int32__exception)(ctx*, ptr__byte, result__int32__exception);
struct gc {
	lock lk;
	opt__ptr_gc_ctx context_head;
	bool needs_gc;
	bool is_doing_gc;
	ptr__byte begin;
	ptr__byte next_byte;
};
struct gc_ctx {
	gc* gc;
	opt__ptr_gc_ctx next_ctx;
};
struct task {
	nat actor_id;
	fun_mut0___void fun;
};
struct mut_bag__task {
	opt__ptr_mut_bag_node__task head;
};
struct mut_bag_node__task {
	task value;
	opt__ptr_mut_bag_node__task next_node;
};
struct thread_safe_counter {
	lock lk;
	nat value;
};
struct fun_mut1___void__exception {
	fun_ptr3___void__ptr_ctx__ptr__byte__exception fun_ptr;
	ptr__byte closure;
};
struct condition {
	lock lk;
	nat value;
};
struct bytes64 {
	bytes32 n0;
	bytes32 n1;
};
struct bytes128 {
	bytes64 n0;
	bytes64 n1;
};
struct fun2__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char {
	fun_ptr4__ptr_fut__int32__ptr_ctx__ptr__byte__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char fun_ptr;
	ptr__byte closure;
};
struct fut_state_callbacks___void {
	opt__ptr_fut_callback_node___void head;
};
struct fun_mut1___void__result___void__exception {
	fun_ptr3___void__ptr_ctx__ptr__byte__result___void__exception fun_ptr;
	ptr__byte closure;
};
struct fun_ref0__int32 {
	vat_and_actor_id vat_and_actor;
	fun_mut0__ptr_fut__int32 fun;
};
struct fun_ref1__int32___void {
	vat_and_actor_id vat_and_actor;
	fun_mut1__ptr_fut__int32___void fun;
};
struct then__ptr_fut__int32__ptr_fut___void__fun_ref1__int32___void__lambda0___closure {
	fun_ref1__int32___void cb;
	fut__int32* res;
};
struct call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0___closure {
	fun_ref1__int32___void f;
	_void p0;
	fut__int32* res;
};
struct call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0__lambda0___closure {
	fun_ref1__int32___void f;
	_void p0;
	fut__int32* res;
};
struct then2__ptr_fut__int32__ptr_fut___void__fun_ref0__int32__lambda0___closure {
	fun_ref0__int32 cb;
};
struct call__ptr_fut__int32__fun_ref0__int32__lambda0___closure {
	fun_ref0__int32 f;
	fut__int32* res;
};
struct call__ptr_fut__int32__fun_ref0__int32__lambda0__lambda0___closure {
	fun_ref0__int32 f;
	fut__int32* res;
};
struct some__task {
	task value;
};
struct task_and_nodes {
	task task;
	opt__ptr_mut_bag_node__task nodes;
};
struct some__task_and_nodes {
	task_and_nodes value;
};
struct opt__arr__arr__char {
	int kind;
	union {
		none as_none;
		some__arr__arr__char as_some__arr__arr__char;
	};
};
typedef opt__arr__arr__char* ptr__opt__arr__arr__char;
struct arr__arr__arr__char {
	nat size;
	ptr__arr__arr__char data;
};
struct mut_arr__opt__arr__arr__char {
	bool frozen__q;
	nat size;
	nat capacity;
	ptr__opt__arr__arr__char data;
};
typedef opt__arr__arr__char (*fun_ptr3__opt__arr__arr__char__ptr_ctx__ptr__byte__nat)(ctx*, ptr__byte, nat);
struct fill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat__opt__arr__arr__char__lambda0___closure {
	opt__arr__arr__char value;
};
struct fun_mut2___void__arr__char__arr__arr__char {
	fun_ptr4___void__ptr_ctx__ptr__byte__arr__char__arr__arr__char fun_ptr;
	ptr__byte closure;
};
struct result__arr__char__arr__ptr_failure {
	int kind;
	union {
		ok__arr__char as_ok__arr__char;
		err__arr__ptr_failure as_err__arr__ptr_failure;
	};
};
struct bytes256 {
	bytes128 n0;
	bytes128 n1;
};
struct fun_mut1__arr__ptr_failure__arr__char {
	fun_ptr3__arr__ptr_failure__ptr_ctx__ptr__byte__arr__char fun_ptr;
	ptr__byte closure;
};
struct flat_map_with_max_size__arr__ptr_failure__arr__arr__char__nat__fun_mut1__arr__ptr_failure__arr__char__lambda0___closure {
	mut_arr__ptr_failure* res;
	nat max_size;
	fun_mut1__arr__ptr_failure__arr__char mapper;
};
struct posix_spawn_file_actions_t {
	int32 allocated;
	int32 used;
	ptr__byte actions;
	bytes64 pad;
};
struct arr__pollfd {
	nat size;
	ptr__pollfd data;
};
typedef result__arr__char__arr__ptr_failure (*fun_ptr2__result__arr__char__arr__ptr_failure__ptr_ctx__ptr__byte)(ctx*, ptr__byte);
typedef result__arr__char__arr__ptr_failure (*fun_ptr3__result__arr__char__arr__ptr_failure__ptr_ctx__ptr__byte__arr__char)(ctx*, ptr__byte, arr__char);
struct fun_mut0__arr__ptr_failure {
	fun_ptr2__arr__ptr_failure__ptr_ctx__ptr__byte fun_ptr;
	ptr__byte closure;
};
struct fut_state__int32 {
	int kind;
	union {
		fut_state_callbacks__int32 as_fut_state_callbacks__int32;
		fut_state_resolved__int32 as_fut_state_resolved__int32;
		exception as_exception;
	};
};
struct fun_mut1___void__result__int32__exception {
	fun_ptr3___void__ptr_ctx__ptr__byte__result__int32__exception fun_ptr;
	ptr__byte closure;
};
struct global_ctx {
	lock lk;
	arr__ptr_vat vats;
	nat n_live_threads;
	condition may_be_work_to_do;
	bool is_shut_down;
	bool any_unhandled_exceptions__q;
};
struct vat {
	global_ctx* gctx;
	nat id;
	gc gc;
	lock tasks_lock;
	mut_bag__task tasks;
	mut_arr__nat currently_running_actors;
	nat n_threads_running;
	thread_safe_counter next_actor_id;
	fun_mut1___void__exception exception_handler;
};
struct jmp_buf_tag {
	bytes64 jmp_buf;
	int32 mask_was_saved;
	bytes128 saved_mask;
};
typedef jmp_buf_tag* ptr__jmp_buf_tag;
struct fut_state___void {
	int kind;
	union {
		fut_state_callbacks___void as_fut_state_callbacks___void;
		fut_state_resolved___void as_fut_state_resolved___void;
		exception as_exception;
	};
};
struct fut_callback_node___void {
	fun_mut1___void__result___void__exception cb;
	opt__ptr_fut_callback_node___void next_node;
};
struct opt__task {
	int kind;
	union {
		none as_none;
		some__task as_some__task;
	};
};
struct some__opt__task {
	opt__task value;
};
struct opt__task_and_nodes {
	int kind;
	union {
		none as_none;
		some__task_and_nodes as_some__task_and_nodes;
	};
};
struct arr__opt__arr__arr__char {
	nat size;
	ptr__opt__arr__arr__char data;
};
typedef test_options (*fun_ptr3__test_options__ptr_ctx__ptr__byte__arr__opt__arr__arr__char)(ctx*, ptr__byte, arr__opt__arr__arr__char);
struct dict__arr__char__arr__arr__char {
	arr__arr__char keys;
	arr__arr__arr__char values;
};
struct fun_mut1__opt__arr__arr__char__nat {
	fun_ptr3__opt__arr__arr__char__ptr_ctx__ptr__byte__nat fun_ptr;
	ptr__byte closure;
};
struct dirent {
	nat d_ino;
	_int d_off;
	nat16 d_reclen;
	char d_type;
	bytes256 d_name;
};
struct fun0__result__arr__char__arr__ptr_failure {
	fun_ptr2__result__arr__char__arr__ptr_failure__ptr_ctx__ptr__byte fun_ptr;
	ptr__byte closure;
};
struct fun_mut1__result__arr__char__arr__ptr_failure__arr__char {
	fun_ptr3__result__arr__char__arr__ptr_failure__ptr_ctx__ptr__byte__arr__char fun_ptr;
	ptr__byte closure;
};
struct first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure__lambda0___closure {
	fun0__result__arr__char__arr__ptr_failure b;
};
struct fut__int32 {
	lock lk;
	fut_state__int32 state;
};
struct fut_callback_node__int32 {
	fun_mut1___void__result__int32__exception cb;
	opt__ptr_fut_callback_node__int32 next_node;
};
struct exception_ctx {
	ptr__jmp_buf_tag jmp_buf_ptr;
	exception thrown_exception;
};
struct fut___void {
	lock lk;
	fut_state___void state;
};
struct chosen_task {
	vat* vat;
	opt__task task_or_gc;
};
struct ok__chosen_task {
	chosen_task value;
};
struct some__chosen_task {
	chosen_task value;
};
struct opt__opt__task {
	int kind;
	union {
		none as_none;
		some__opt__task as_some__opt__task;
	};
};
struct fun1__test_options__arr__opt__arr__arr__char {
	fun_ptr3__test_options__ptr_ctx__ptr__byte__arr__opt__arr__arr__char fun_ptr;
	ptr__byte closure;
};
struct result__chosen_task__no_chosen_task {
	int kind;
	union {
		ok__chosen_task as_ok__chosen_task;
		err__no_chosen_task as_err__no_chosen_task;
	};
};
struct opt__chosen_task {
	int kind;
	union {
		none as_none;
		some__chosen_task as_some__chosen_task;
	};
};


ctx* _initctx(byte* out, ctx value) {
	ctx* res = (ctx*) out; 
	*res = value;
	return res;
}
ctx _failctx() {
	assert(0);
}


byte* _initbyte(byte* out, byte value) {
	byte* res = (byte*) out; 
	*res = value;
	return res;
}
byte _failbyte() {
	assert(0);
}


ptr__byte* _initptr__byte(byte* out, ptr__byte value) {
	ptr__byte* res = (ptr__byte*) out; 
	*res = value;
	return res;
}
ptr__byte _failptr__byte() {
	assert(0);
}


nat* _initnat(byte* out, nat value) {
	nat* res = (nat*) out; 
	*res = value;
	return res;
}
nat _failnat() {
	assert(0);
}


int32* _initint32(byte* out, int32 value) {
	int32* res = (int32*) out; 
	*res = value;
	return res;
}
int32 _failint32() {
	assert(0);
}


char* _initchar(byte* out, char value) {
	char* res = (char*) out; 
	*res = value;
	return res;
}
char _failchar() {
	assert(0);
}


ptr__char* _initptr__char(byte* out, ptr__char value) {
	ptr__char* res = (ptr__char*) out; 
	*res = value;
	return res;
}
ptr__char _failptr__char() {
	assert(0);
}


ptr__ptr__char* _initptr__ptr__char(byte* out, ptr__ptr__char value) {
	ptr__ptr__char* res = (ptr__ptr__char*) out; 
	*res = value;
	return res;
}
ptr__ptr__char _failptr__ptr__char() {
	assert(0);
}


fut__int32* _initfut__int32(byte* out, fut__int32 value) {
	fut__int32* res = (fut__int32*) out; 
	*res = value;
	return res;
}
fut__int32 _failfut__int32() {
	assert(0);
}


lock* _initlock(byte* out, lock value) {
	lock* res = (lock*) out; 
	*res = value;
	return res;
}
lock _faillock() {
	assert(0);
}


_atomic_bool* _init_atomic_bool(byte* out, _atomic_bool value) {
	_atomic_bool* res = (_atomic_bool*) out; 
	*res = value;
	return res;
}
_atomic_bool _fail_atomic_bool() {
	assert(0);
}


bool* _initbool(byte* out, bool value) {
	bool* res = (bool*) out; 
	*res = value;
	return res;
}
bool _failbool() {
	assert(0);
}


fut_state__int32* _initfut_state__int32(byte* out, fut_state__int32 value) {
	fut_state__int32* res = (fut_state__int32*) out; 
	*res = value;
	return res;
}
fut_state__int32 _failfut_state__int32() {
	assert(0);
}


fut_state_callbacks__int32* _initfut_state_callbacks__int32(byte* out, fut_state_callbacks__int32 value) {
	fut_state_callbacks__int32* res = (fut_state_callbacks__int32*) out; 
	*res = value;
	return res;
}
fut_state_callbacks__int32 _failfut_state_callbacks__int32() {
	assert(0);
}


fut_callback_node__int32* _initfut_callback_node__int32(byte* out, fut_callback_node__int32 value) {
	fut_callback_node__int32* res = (fut_callback_node__int32*) out; 
	*res = value;
	return res;
}
fut_callback_node__int32 _failfut_callback_node__int32() {
	assert(0);
}


_void* _init_void(byte* out, _void value) {
	_void* res = (_void*) out; 
	*res = value;
	return res;
}
_void _fail_void() {
	assert(0);
}


exception* _initexception(byte* out, exception value) {
	exception* res = (exception*) out; 
	*res = value;
	return res;
}
exception _failexception() {
	assert(0);
}


arr__char* _initarr__char(byte* out, arr__char value) {
	arr__char* res = (arr__char*) out; 
	*res = value;
	return res;
}
arr__char _failarr__char() {
	assert(0);
}


result__int32__exception* _initresult__int32__exception(byte* out, result__int32__exception value) {
	result__int32__exception* res = (result__int32__exception*) out; 
	*res = value;
	return res;
}
result__int32__exception _failresult__int32__exception() {
	assert(0);
}


ok__int32* _initok__int32(byte* out, ok__int32 value) {
	ok__int32* res = (ok__int32*) out; 
	*res = value;
	return res;
}
ok__int32 _failok__int32() {
	assert(0);
}


err__exception* _initerr__exception(byte* out, err__exception value) {
	err__exception* res = (err__exception*) out; 
	*res = value;
	return res;
}
err__exception _failerr__exception() {
	assert(0);
}


fun_mut1___void__result__int32__exception* _initfun_mut1___void__result__int32__exception(byte* out, fun_mut1___void__result__int32__exception value) {
	fun_mut1___void__result__int32__exception* res = (fun_mut1___void__result__int32__exception*) out; 
	*res = value;
	return res;
}
fun_mut1___void__result__int32__exception _failfun_mut1___void__result__int32__exception() {
	assert(0);
}


fun_ptr3___void__ptr_ctx__ptr__byte__result__int32__exception* _initfun_ptr3___void__ptr_ctx__ptr__byte__result__int32__exception(byte* out, fun_ptr3___void__ptr_ctx__ptr__byte__result__int32__exception value) {
	fun_ptr3___void__ptr_ctx__ptr__byte__result__int32__exception* res = (fun_ptr3___void__ptr_ctx__ptr__byte__result__int32__exception*) out; 
	*res = value;
	return res;
}
fun_ptr3___void__ptr_ctx__ptr__byte__result__int32__exception _failfun_ptr3___void__ptr_ctx__ptr__byte__result__int32__exception() {
	assert(0);
}


opt__ptr_fut_callback_node__int32* _initopt__ptr_fut_callback_node__int32(byte* out, opt__ptr_fut_callback_node__int32 value) {
	opt__ptr_fut_callback_node__int32* res = (opt__ptr_fut_callback_node__int32*) out; 
	*res = value;
	return res;
}
opt__ptr_fut_callback_node__int32 _failopt__ptr_fut_callback_node__int32() {
	assert(0);
}


none* _initnone(byte* out, none value) {
	none* res = (none*) out; 
	*res = value;
	return res;
}
none _failnone() {
	assert(0);
}


some__ptr_fut_callback_node__int32* _initsome__ptr_fut_callback_node__int32(byte* out, some__ptr_fut_callback_node__int32 value) {
	some__ptr_fut_callback_node__int32* res = (some__ptr_fut_callback_node__int32*) out; 
	*res = value;
	return res;
}
some__ptr_fut_callback_node__int32 _failsome__ptr_fut_callback_node__int32() {
	assert(0);
}


fut_state_resolved__int32* _initfut_state_resolved__int32(byte* out, fut_state_resolved__int32 value) {
	fut_state_resolved__int32* res = (fut_state_resolved__int32*) out; 
	*res = value;
	return res;
}
fut_state_resolved__int32 _failfut_state_resolved__int32() {
	assert(0);
}


arr__arr__char* _initarr__arr__char(byte* out, arr__arr__char value) {
	arr__arr__char* res = (arr__arr__char*) out; 
	*res = value;
	return res;
}
arr__arr__char _failarr__arr__char() {
	assert(0);
}


ptr__arr__char* _initptr__arr__char(byte* out, ptr__arr__char value) {
	ptr__arr__char* res = (ptr__arr__char*) out; 
	*res = value;
	return res;
}
ptr__arr__char _failptr__arr__char() {
	assert(0);
}


fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char* _initfun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char(byte* out, fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char value) {
	fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char* res = (fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char*) out; 
	*res = value;
	return res;
}
fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char _failfun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char() {
	assert(0);
}


global_ctx* _initglobal_ctx(byte* out, global_ctx value) {
	global_ctx* res = (global_ctx*) out; 
	*res = value;
	return res;
}
global_ctx _failglobal_ctx() {
	assert(0);
}


vat* _initvat(byte* out, vat value) {
	vat* res = (vat*) out; 
	*res = value;
	return res;
}
vat _failvat() {
	assert(0);
}


gc* _initgc(byte* out, gc value) {
	gc* res = (gc*) out; 
	*res = value;
	return res;
}
gc _failgc() {
	assert(0);
}


gc_ctx* _initgc_ctx(byte* out, gc_ctx value) {
	gc_ctx* res = (gc_ctx*) out; 
	*res = value;
	return res;
}
gc_ctx _failgc_ctx() {
	assert(0);
}


opt__ptr_gc_ctx* _initopt__ptr_gc_ctx(byte* out, opt__ptr_gc_ctx value) {
	opt__ptr_gc_ctx* res = (opt__ptr_gc_ctx*) out; 
	*res = value;
	return res;
}
opt__ptr_gc_ctx _failopt__ptr_gc_ctx() {
	assert(0);
}


some__ptr_gc_ctx* _initsome__ptr_gc_ctx(byte* out, some__ptr_gc_ctx value) {
	some__ptr_gc_ctx* res = (some__ptr_gc_ctx*) out; 
	*res = value;
	return res;
}
some__ptr_gc_ctx _failsome__ptr_gc_ctx() {
	assert(0);
}


task* _inittask(byte* out, task value) {
	task* res = (task*) out; 
	*res = value;
	return res;
}
task _failtask() {
	assert(0);
}


fun_mut0___void* _initfun_mut0___void(byte* out, fun_mut0___void value) {
	fun_mut0___void* res = (fun_mut0___void*) out; 
	*res = value;
	return res;
}
fun_mut0___void _failfun_mut0___void() {
	assert(0);
}


fun_ptr2___void__ptr_ctx__ptr__byte* _initfun_ptr2___void__ptr_ctx__ptr__byte(byte* out, fun_ptr2___void__ptr_ctx__ptr__byte value) {
	fun_ptr2___void__ptr_ctx__ptr__byte* res = (fun_ptr2___void__ptr_ctx__ptr__byte*) out; 
	*res = value;
	return res;
}
fun_ptr2___void__ptr_ctx__ptr__byte _failfun_ptr2___void__ptr_ctx__ptr__byte() {
	assert(0);
}


mut_bag__task* _initmut_bag__task(byte* out, mut_bag__task value) {
	mut_bag__task* res = (mut_bag__task*) out; 
	*res = value;
	return res;
}
mut_bag__task _failmut_bag__task() {
	assert(0);
}


mut_bag_node__task* _initmut_bag_node__task(byte* out, mut_bag_node__task value) {
	mut_bag_node__task* res = (mut_bag_node__task*) out; 
	*res = value;
	return res;
}
mut_bag_node__task _failmut_bag_node__task() {
	assert(0);
}


opt__ptr_mut_bag_node__task* _initopt__ptr_mut_bag_node__task(byte* out, opt__ptr_mut_bag_node__task value) {
	opt__ptr_mut_bag_node__task* res = (opt__ptr_mut_bag_node__task*) out; 
	*res = value;
	return res;
}
opt__ptr_mut_bag_node__task _failopt__ptr_mut_bag_node__task() {
	assert(0);
}


some__ptr_mut_bag_node__task* _initsome__ptr_mut_bag_node__task(byte* out, some__ptr_mut_bag_node__task value) {
	some__ptr_mut_bag_node__task* res = (some__ptr_mut_bag_node__task*) out; 
	*res = value;
	return res;
}
some__ptr_mut_bag_node__task _failsome__ptr_mut_bag_node__task() {
	assert(0);
}


mut_arr__nat* _initmut_arr__nat(byte* out, mut_arr__nat value) {
	mut_arr__nat* res = (mut_arr__nat*) out; 
	*res = value;
	return res;
}
mut_arr__nat _failmut_arr__nat() {
	assert(0);
}


ptr__nat* _initptr__nat(byte* out, ptr__nat value) {
	ptr__nat* res = (ptr__nat*) out; 
	*res = value;
	return res;
}
ptr__nat _failptr__nat() {
	assert(0);
}


thread_safe_counter* _initthread_safe_counter(byte* out, thread_safe_counter value) {
	thread_safe_counter* res = (thread_safe_counter*) out; 
	*res = value;
	return res;
}
thread_safe_counter _failthread_safe_counter() {
	assert(0);
}


fun_mut1___void__exception* _initfun_mut1___void__exception(byte* out, fun_mut1___void__exception value) {
	fun_mut1___void__exception* res = (fun_mut1___void__exception*) out; 
	*res = value;
	return res;
}
fun_mut1___void__exception _failfun_mut1___void__exception() {
	assert(0);
}


fun_ptr3___void__ptr_ctx__ptr__byte__exception* _initfun_ptr3___void__ptr_ctx__ptr__byte__exception(byte* out, fun_ptr3___void__ptr_ctx__ptr__byte__exception value) {
	fun_ptr3___void__ptr_ctx__ptr__byte__exception* res = (fun_ptr3___void__ptr_ctx__ptr__byte__exception*) out; 
	*res = value;
	return res;
}
fun_ptr3___void__ptr_ctx__ptr__byte__exception _failfun_ptr3___void__ptr_ctx__ptr__byte__exception() {
	assert(0);
}


arr__ptr_vat* _initarr__ptr_vat(byte* out, arr__ptr_vat value) {
	arr__ptr_vat* res = (arr__ptr_vat*) out; 
	*res = value;
	return res;
}
arr__ptr_vat _failarr__ptr_vat() {
	assert(0);
}


ptr__ptr_vat* _initptr__ptr_vat(byte* out, ptr__ptr_vat value) {
	ptr__ptr_vat* res = (ptr__ptr_vat*) out; 
	*res = value;
	return res;
}
ptr__ptr_vat _failptr__ptr_vat() {
	assert(0);
}


condition* _initcondition(byte* out, condition value) {
	condition* res = (condition*) out; 
	*res = value;
	return res;
}
condition _failcondition() {
	assert(0);
}


comparison* _initcomparison(byte* out, comparison value) {
	comparison* res = (comparison*) out; 
	*res = value;
	return res;
}
comparison _failcomparison() {
	assert(0);
}


less* _initless(byte* out, less value) {
	less* res = (less*) out; 
	*res = value;
	return res;
}
less _failless() {
	assert(0);
}


equal* _initequal(byte* out, equal value) {
	equal* res = (equal*) out; 
	*res = value;
	return res;
}
equal _failequal() {
	assert(0);
}


greater* _initgreater(byte* out, greater value) {
	greater* res = (greater*) out; 
	*res = value;
	return res;
}
greater _failgreater() {
	assert(0);
}


ptr__bool* _initptr__bool(byte* out, ptr__bool value) {
	ptr__bool* res = (ptr__bool*) out; 
	*res = value;
	return res;
}
ptr__bool _failptr__bool() {
	assert(0);
}


_int* _init_int(byte* out, _int value) {
	_int* res = (_int*) out; 
	*res = value;
	return res;
}
_int _fail_int() {
	assert(0);
}


exception_ctx* _initexception_ctx(byte* out, exception_ctx value) {
	exception_ctx* res = (exception_ctx*) out; 
	*res = value;
	return res;
}
exception_ctx _failexception_ctx() {
	assert(0);
}


jmp_buf_tag* _initjmp_buf_tag(byte* out, jmp_buf_tag value) {
	jmp_buf_tag* res = (jmp_buf_tag*) out; 
	*res = value;
	return res;
}
jmp_buf_tag _failjmp_buf_tag() {
	assert(0);
}


bytes64* _initbytes64(byte* out, bytes64 value) {
	bytes64* res = (bytes64*) out; 
	*res = value;
	return res;
}
bytes64 _failbytes64() {
	assert(0);
}


bytes32* _initbytes32(byte* out, bytes32 value) {
	bytes32* res = (bytes32*) out; 
	*res = value;
	return res;
}
bytes32 _failbytes32() {
	assert(0);
}


bytes16* _initbytes16(byte* out, bytes16 value) {
	bytes16* res = (bytes16*) out; 
	*res = value;
	return res;
}
bytes16 _failbytes16() {
	assert(0);
}


bytes128* _initbytes128(byte* out, bytes128 value) {
	bytes128* res = (bytes128*) out; 
	*res = value;
	return res;
}
bytes128 _failbytes128() {
	assert(0);
}


ptr__jmp_buf_tag* _initptr__jmp_buf_tag(byte* out, ptr__jmp_buf_tag value) {
	ptr__jmp_buf_tag* res = (ptr__jmp_buf_tag*) out; 
	*res = value;
	return res;
}
ptr__jmp_buf_tag _failptr__jmp_buf_tag() {
	assert(0);
}


thread_local_stuff* _initthread_local_stuff(byte* out, thread_local_stuff value) {
	thread_local_stuff* res = (thread_local_stuff*) out; 
	*res = value;
	return res;
}
thread_local_stuff _failthread_local_stuff() {
	assert(0);
}


arr__ptr__char* _initarr__ptr__char(byte* out, arr__ptr__char value) {
	arr__ptr__char* res = (arr__ptr__char*) out; 
	*res = value;
	return res;
}
arr__ptr__char _failarr__ptr__char() {
	assert(0);
}


fun2__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char* _initfun2__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char(byte* out, fun2__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char value) {
	fun2__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char* res = (fun2__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char*) out; 
	*res = value;
	return res;
}
fun2__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char _failfun2__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char() {
	assert(0);
}


fun_ptr4__ptr_fut__int32__ptr_ctx__ptr__byte__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char* _initfun_ptr4__ptr_fut__int32__ptr_ctx__ptr__byte__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char(byte* out, fun_ptr4__ptr_fut__int32__ptr_ctx__ptr__byte__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char value) {
	fun_ptr4__ptr_fut__int32__ptr_ctx__ptr__byte__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char* res = (fun_ptr4__ptr_fut__int32__ptr_ctx__ptr__byte__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char*) out; 
	*res = value;
	return res;
}
fun_ptr4__ptr_fut__int32__ptr_ctx__ptr__byte__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char _failfun_ptr4__ptr_fut__int32__ptr_ctx__ptr__byte__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char() {
	assert(0);
}


fut___void* _initfut___void(byte* out, fut___void value) {
	fut___void* res = (fut___void*) out; 
	*res = value;
	return res;
}
fut___void _failfut___void() {
	assert(0);
}


fut_state___void* _initfut_state___void(byte* out, fut_state___void value) {
	fut_state___void* res = (fut_state___void*) out; 
	*res = value;
	return res;
}
fut_state___void _failfut_state___void() {
	assert(0);
}


fut_state_callbacks___void* _initfut_state_callbacks___void(byte* out, fut_state_callbacks___void value) {
	fut_state_callbacks___void* res = (fut_state_callbacks___void*) out; 
	*res = value;
	return res;
}
fut_state_callbacks___void _failfut_state_callbacks___void() {
	assert(0);
}


fut_callback_node___void* _initfut_callback_node___void(byte* out, fut_callback_node___void value) {
	fut_callback_node___void* res = (fut_callback_node___void*) out; 
	*res = value;
	return res;
}
fut_callback_node___void _failfut_callback_node___void() {
	assert(0);
}


result___void__exception* _initresult___void__exception(byte* out, result___void__exception value) {
	result___void__exception* res = (result___void__exception*) out; 
	*res = value;
	return res;
}
result___void__exception _failresult___void__exception() {
	assert(0);
}


ok___void* _initok___void(byte* out, ok___void value) {
	ok___void* res = (ok___void*) out; 
	*res = value;
	return res;
}
ok___void _failok___void() {
	assert(0);
}


fun_mut1___void__result___void__exception* _initfun_mut1___void__result___void__exception(byte* out, fun_mut1___void__result___void__exception value) {
	fun_mut1___void__result___void__exception* res = (fun_mut1___void__result___void__exception*) out; 
	*res = value;
	return res;
}
fun_mut1___void__result___void__exception _failfun_mut1___void__result___void__exception() {
	assert(0);
}


fun_ptr3___void__ptr_ctx__ptr__byte__result___void__exception* _initfun_ptr3___void__ptr_ctx__ptr__byte__result___void__exception(byte* out, fun_ptr3___void__ptr_ctx__ptr__byte__result___void__exception value) {
	fun_ptr3___void__ptr_ctx__ptr__byte__result___void__exception* res = (fun_ptr3___void__ptr_ctx__ptr__byte__result___void__exception*) out; 
	*res = value;
	return res;
}
fun_ptr3___void__ptr_ctx__ptr__byte__result___void__exception _failfun_ptr3___void__ptr_ctx__ptr__byte__result___void__exception() {
	assert(0);
}


opt__ptr_fut_callback_node___void* _initopt__ptr_fut_callback_node___void(byte* out, opt__ptr_fut_callback_node___void value) {
	opt__ptr_fut_callback_node___void* res = (opt__ptr_fut_callback_node___void*) out; 
	*res = value;
	return res;
}
opt__ptr_fut_callback_node___void _failopt__ptr_fut_callback_node___void() {
	assert(0);
}


some__ptr_fut_callback_node___void* _initsome__ptr_fut_callback_node___void(byte* out, some__ptr_fut_callback_node___void value) {
	some__ptr_fut_callback_node___void* res = (some__ptr_fut_callback_node___void*) out; 
	*res = value;
	return res;
}
some__ptr_fut_callback_node___void _failsome__ptr_fut_callback_node___void() {
	assert(0);
}


fut_state_resolved___void* _initfut_state_resolved___void(byte* out, fut_state_resolved___void value) {
	fut_state_resolved___void* res = (fut_state_resolved___void*) out; 
	*res = value;
	return res;
}
fut_state_resolved___void _failfut_state_resolved___void() {
	assert(0);
}


fun_ref0__int32* _initfun_ref0__int32(byte* out, fun_ref0__int32 value) {
	fun_ref0__int32* res = (fun_ref0__int32*) out; 
	*res = value;
	return res;
}
fun_ref0__int32 _failfun_ref0__int32() {
	assert(0);
}


vat_and_actor_id* _initvat_and_actor_id(byte* out, vat_and_actor_id value) {
	vat_and_actor_id* res = (vat_and_actor_id*) out; 
	*res = value;
	return res;
}
vat_and_actor_id _failvat_and_actor_id() {
	assert(0);
}


fun_mut0__ptr_fut__int32* _initfun_mut0__ptr_fut__int32(byte* out, fun_mut0__ptr_fut__int32 value) {
	fun_mut0__ptr_fut__int32* res = (fun_mut0__ptr_fut__int32*) out; 
	*res = value;
	return res;
}
fun_mut0__ptr_fut__int32 _failfun_mut0__ptr_fut__int32() {
	assert(0);
}


fun_ptr2__ptr_fut__int32__ptr_ctx__ptr__byte* _initfun_ptr2__ptr_fut__int32__ptr_ctx__ptr__byte(byte* out, fun_ptr2__ptr_fut__int32__ptr_ctx__ptr__byte value) {
	fun_ptr2__ptr_fut__int32__ptr_ctx__ptr__byte* res = (fun_ptr2__ptr_fut__int32__ptr_ctx__ptr__byte*) out; 
	*res = value;
	return res;
}
fun_ptr2__ptr_fut__int32__ptr_ctx__ptr__byte _failfun_ptr2__ptr_fut__int32__ptr_ctx__ptr__byte() {
	assert(0);
}


fun_ref1__int32___void* _initfun_ref1__int32___void(byte* out, fun_ref1__int32___void value) {
	fun_ref1__int32___void* res = (fun_ref1__int32___void*) out; 
	*res = value;
	return res;
}
fun_ref1__int32___void _failfun_ref1__int32___void() {
	assert(0);
}


fun_mut1__ptr_fut__int32___void* _initfun_mut1__ptr_fut__int32___void(byte* out, fun_mut1__ptr_fut__int32___void value) {
	fun_mut1__ptr_fut__int32___void* res = (fun_mut1__ptr_fut__int32___void*) out; 
	*res = value;
	return res;
}
fun_mut1__ptr_fut__int32___void _failfun_mut1__ptr_fut__int32___void() {
	assert(0);
}


fun_ptr3__ptr_fut__int32__ptr_ctx__ptr__byte___void* _initfun_ptr3__ptr_fut__int32__ptr_ctx__ptr__byte___void(byte* out, fun_ptr3__ptr_fut__int32__ptr_ctx__ptr__byte___void value) {
	fun_ptr3__ptr_fut__int32__ptr_ctx__ptr__byte___void* res = (fun_ptr3__ptr_fut__int32__ptr_ctx__ptr__byte___void*) out; 
	*res = value;
	return res;
}
fun_ptr3__ptr_fut__int32__ptr_ctx__ptr__byte___void _failfun_ptr3__ptr_fut__int32__ptr_ctx__ptr__byte___void() {
	assert(0);
}


opt__ptr__byte* _initopt__ptr__byte(byte* out, opt__ptr__byte value) {
	opt__ptr__byte* res = (opt__ptr__byte*) out; 
	*res = value;
	return res;
}
opt__ptr__byte _failopt__ptr__byte() {
	assert(0);
}


some__ptr__byte* _initsome__ptr__byte(byte* out, some__ptr__byte value) {
	some__ptr__byte* res = (some__ptr__byte*) out; 
	*res = value;
	return res;
}
some__ptr__byte _failsome__ptr__byte() {
	assert(0);
}


then__ptr_fut__int32__ptr_fut___void__fun_ref1__int32___void__lambda0___closure* _initthen__ptr_fut__int32__ptr_fut___void__fun_ref1__int32___void__lambda0___closure(byte* out, then__ptr_fut__int32__ptr_fut___void__fun_ref1__int32___void__lambda0___closure value) {
	then__ptr_fut__int32__ptr_fut___void__fun_ref1__int32___void__lambda0___closure* res = (then__ptr_fut__int32__ptr_fut___void__fun_ref1__int32___void__lambda0___closure*) out; 
	*res = value;
	return res;
}
then__ptr_fut__int32__ptr_fut___void__fun_ref1__int32___void__lambda0___closure _failthen__ptr_fut__int32__ptr_fut___void__fun_ref1__int32___void__lambda0___closure() {
	assert(0);
}


forward_to___void__ptr_fut__int32__ptr_fut__int32__lambda0___closure* _initforward_to___void__ptr_fut__int32__ptr_fut__int32__lambda0___closure(byte* out, forward_to___void__ptr_fut__int32__ptr_fut__int32__lambda0___closure value) {
	forward_to___void__ptr_fut__int32__ptr_fut__int32__lambda0___closure* res = (forward_to___void__ptr_fut__int32__ptr_fut__int32__lambda0___closure*) out; 
	*res = value;
	return res;
}
forward_to___void__ptr_fut__int32__ptr_fut__int32__lambda0___closure _failforward_to___void__ptr_fut__int32__ptr_fut__int32__lambda0___closure() {
	assert(0);
}


call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0___closure* _initcall__ptr_fut__int32__fun_ref1__int32___void___void__lambda0___closure(byte* out, call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0___closure value) {
	call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0___closure* res = (call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0___closure*) out; 
	*res = value;
	return res;
}
call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0___closure _failcall__ptr_fut__int32__fun_ref1__int32___void___void__lambda0___closure() {
	assert(0);
}


call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0__lambda0___closure* _initcall__ptr_fut__int32__fun_ref1__int32___void___void__lambda0__lambda0___closure(byte* out, call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0__lambda0___closure value) {
	call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0__lambda0___closure* res = (call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0__lambda0___closure*) out; 
	*res = value;
	return res;
}
call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0__lambda0___closure _failcall__ptr_fut__int32__fun_ref1__int32___void___void__lambda0__lambda0___closure() {
	assert(0);
}


call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0__lambda1___closure* _initcall__ptr_fut__int32__fun_ref1__int32___void___void__lambda0__lambda1___closure(byte* out, call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0__lambda1___closure value) {
	call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0__lambda1___closure* res = (call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0__lambda1___closure*) out; 
	*res = value;
	return res;
}
call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0__lambda1___closure _failcall__ptr_fut__int32__fun_ref1__int32___void___void__lambda0__lambda1___closure() {
	assert(0);
}


then2__ptr_fut__int32__ptr_fut___void__fun_ref0__int32__lambda0___closure* _initthen2__ptr_fut__int32__ptr_fut___void__fun_ref0__int32__lambda0___closure(byte* out, then2__ptr_fut__int32__ptr_fut___void__fun_ref0__int32__lambda0___closure value) {
	then2__ptr_fut__int32__ptr_fut___void__fun_ref0__int32__lambda0___closure* res = (then2__ptr_fut__int32__ptr_fut___void__fun_ref0__int32__lambda0___closure*) out; 
	*res = value;
	return res;
}
then2__ptr_fut__int32__ptr_fut___void__fun_ref0__int32__lambda0___closure _failthen2__ptr_fut__int32__ptr_fut___void__fun_ref0__int32__lambda0___closure() {
	assert(0);
}


call__ptr_fut__int32__fun_ref0__int32__lambda0___closure* _initcall__ptr_fut__int32__fun_ref0__int32__lambda0___closure(byte* out, call__ptr_fut__int32__fun_ref0__int32__lambda0___closure value) {
	call__ptr_fut__int32__fun_ref0__int32__lambda0___closure* res = (call__ptr_fut__int32__fun_ref0__int32__lambda0___closure*) out; 
	*res = value;
	return res;
}
call__ptr_fut__int32__fun_ref0__int32__lambda0___closure _failcall__ptr_fut__int32__fun_ref0__int32__lambda0___closure() {
	assert(0);
}


call__ptr_fut__int32__fun_ref0__int32__lambda0__lambda0___closure* _initcall__ptr_fut__int32__fun_ref0__int32__lambda0__lambda0___closure(byte* out, call__ptr_fut__int32__fun_ref0__int32__lambda0__lambda0___closure value) {
	call__ptr_fut__int32__fun_ref0__int32__lambda0__lambda0___closure* res = (call__ptr_fut__int32__fun_ref0__int32__lambda0__lambda0___closure*) out; 
	*res = value;
	return res;
}
call__ptr_fut__int32__fun_ref0__int32__lambda0__lambda0___closure _failcall__ptr_fut__int32__fun_ref0__int32__lambda0__lambda0___closure() {
	assert(0);
}


call__ptr_fut__int32__fun_ref0__int32__lambda0__lambda1___closure* _initcall__ptr_fut__int32__fun_ref0__int32__lambda0__lambda1___closure(byte* out, call__ptr_fut__int32__fun_ref0__int32__lambda0__lambda1___closure value) {
	call__ptr_fut__int32__fun_ref0__int32__lambda0__lambda1___closure* res = (call__ptr_fut__int32__fun_ref0__int32__lambda0__lambda1___closure*) out; 
	*res = value;
	return res;
}
call__ptr_fut__int32__fun_ref0__int32__lambda0__lambda1___closure _failcall__ptr_fut__int32__fun_ref0__int32__lambda0__lambda1___closure() {
	assert(0);
}


add_first_task__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__lambda0___closure* _initadd_first_task__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__lambda0___closure(byte* out, add_first_task__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__lambda0___closure value) {
	add_first_task__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__lambda0___closure* res = (add_first_task__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__lambda0___closure*) out; 
	*res = value;
	return res;
}
add_first_task__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__lambda0___closure _failadd_first_task__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__lambda0___closure() {
	assert(0);
}


fun_mut1__arr__char__ptr__char* _initfun_mut1__arr__char__ptr__char(byte* out, fun_mut1__arr__char__ptr__char value) {
	fun_mut1__arr__char__ptr__char* res = (fun_mut1__arr__char__ptr__char*) out; 
	*res = value;
	return res;
}
fun_mut1__arr__char__ptr__char _failfun_mut1__arr__char__ptr__char() {
	assert(0);
}


fun_ptr3__arr__char__ptr_ctx__ptr__byte__ptr__char* _initfun_ptr3__arr__char__ptr_ctx__ptr__byte__ptr__char(byte* out, fun_ptr3__arr__char__ptr_ctx__ptr__byte__ptr__char value) {
	fun_ptr3__arr__char__ptr_ctx__ptr__byte__ptr__char* res = (fun_ptr3__arr__char__ptr_ctx__ptr__byte__ptr__char*) out; 
	*res = value;
	return res;
}
fun_ptr3__arr__char__ptr_ctx__ptr__byte__ptr__char _failfun_ptr3__arr__char__ptr_ctx__ptr__byte__ptr__char() {
	assert(0);
}


fun_mut1__arr__char__nat* _initfun_mut1__arr__char__nat(byte* out, fun_mut1__arr__char__nat value) {
	fun_mut1__arr__char__nat* res = (fun_mut1__arr__char__nat*) out; 
	*res = value;
	return res;
}
fun_mut1__arr__char__nat _failfun_mut1__arr__char__nat() {
	assert(0);
}


fun_ptr3__arr__char__ptr_ctx__ptr__byte__nat* _initfun_ptr3__arr__char__ptr_ctx__ptr__byte__nat(byte* out, fun_ptr3__arr__char__ptr_ctx__ptr__byte__nat value) {
	fun_ptr3__arr__char__ptr_ctx__ptr__byte__nat* res = (fun_ptr3__arr__char__ptr_ctx__ptr__byte__nat*) out; 
	*res = value;
	return res;
}
fun_ptr3__arr__char__ptr_ctx__ptr__byte__nat _failfun_ptr3__arr__char__ptr_ctx__ptr__byte__nat() {
	assert(0);
}


mut_arr__arr__char* _initmut_arr__arr__char(byte* out, mut_arr__arr__char value) {
	mut_arr__arr__char* res = (mut_arr__arr__char*) out; 
	*res = value;
	return res;
}
mut_arr__arr__char _failmut_arr__arr__char() {
	assert(0);
}


map__arr__arr__char__arr__ptr__char__fun_mut1__arr__char__ptr__char__lambda0___closure* _initmap__arr__arr__char__arr__ptr__char__fun_mut1__arr__char__ptr__char__lambda0___closure(byte* out, map__arr__arr__char__arr__ptr__char__fun_mut1__arr__char__ptr__char__lambda0___closure value) {
	map__arr__arr__char__arr__ptr__char__fun_mut1__arr__char__ptr__char__lambda0___closure* res = (map__arr__arr__char__arr__ptr__char__fun_mut1__arr__char__ptr__char__lambda0___closure*) out; 
	*res = value;
	return res;
}
map__arr__arr__char__arr__ptr__char__fun_mut1__arr__char__ptr__char__lambda0___closure _failmap__arr__arr__char__arr__ptr__char__fun_mut1__arr__char__ptr__char__lambda0___closure() {
	assert(0);
}


fun_ptr2___void__nat__ptr_global_ctx* _initfun_ptr2___void__nat__ptr_global_ctx(byte* out, fun_ptr2___void__nat__ptr_global_ctx value) {
	fun_ptr2___void__nat__ptr_global_ctx* res = (fun_ptr2___void__nat__ptr_global_ctx*) out; 
	*res = value;
	return res;
}
fun_ptr2___void__nat__ptr_global_ctx _failfun_ptr2___void__nat__ptr_global_ctx() {
	assert(0);
}


thread_args__ptr_global_ctx* _initthread_args__ptr_global_ctx(byte* out, thread_args__ptr_global_ctx value) {
	thread_args__ptr_global_ctx* res = (thread_args__ptr_global_ctx*) out; 
	*res = value;
	return res;
}
thread_args__ptr_global_ctx _failthread_args__ptr_global_ctx() {
	assert(0);
}


ptr__thread_args__ptr_global_ctx* _initptr__thread_args__ptr_global_ctx(byte* out, ptr__thread_args__ptr_global_ctx value) {
	ptr__thread_args__ptr_global_ctx* res = (ptr__thread_args__ptr_global_ctx*) out; 
	*res = value;
	return res;
}
ptr__thread_args__ptr_global_ctx _failptr__thread_args__ptr_global_ctx() {
	assert(0);
}


fun_ptr1__ptr__byte__ptr__byte* _initfun_ptr1__ptr__byte__ptr__byte(byte* out, fun_ptr1__ptr__byte__ptr__byte value) {
	fun_ptr1__ptr__byte__ptr__byte* res = (fun_ptr1__ptr__byte__ptr__byte*) out; 
	*res = value;
	return res;
}
fun_ptr1__ptr__byte__ptr__byte _failfun_ptr1__ptr__byte__ptr__byte() {
	assert(0);
}


cell__nat* _initcell__nat(byte* out, cell__nat value) {
	cell__nat* res = (cell__nat*) out; 
	*res = value;
	return res;
}
cell__nat _failcell__nat() {
	assert(0);
}


cell__ptr__byte* _initcell__ptr__byte(byte* out, cell__ptr__byte value) {
	cell__ptr__byte* res = (cell__ptr__byte*) out; 
	*res = value;
	return res;
}
cell__ptr__byte _failcell__ptr__byte() {
	assert(0);
}


chosen_task* _initchosen_task(byte* out, chosen_task value) {
	chosen_task* res = (chosen_task*) out; 
	*res = value;
	return res;
}
chosen_task _failchosen_task() {
	assert(0);
}


opt__task* _initopt__task(byte* out, opt__task value) {
	opt__task* res = (opt__task*) out; 
	*res = value;
	return res;
}
opt__task _failopt__task() {
	assert(0);
}


some__task* _initsome__task(byte* out, some__task value) {
	some__task* res = (some__task*) out; 
	*res = value;
	return res;
}
some__task _failsome__task() {
	assert(0);
}


no_chosen_task* _initno_chosen_task(byte* out, no_chosen_task value) {
	no_chosen_task* res = (no_chosen_task*) out; 
	*res = value;
	return res;
}
no_chosen_task _failno_chosen_task() {
	assert(0);
}


result__chosen_task__no_chosen_task* _initresult__chosen_task__no_chosen_task(byte* out, result__chosen_task__no_chosen_task value) {
	result__chosen_task__no_chosen_task* res = (result__chosen_task__no_chosen_task*) out; 
	*res = value;
	return res;
}
result__chosen_task__no_chosen_task _failresult__chosen_task__no_chosen_task() {
	assert(0);
}


ok__chosen_task* _initok__chosen_task(byte* out, ok__chosen_task value) {
	ok__chosen_task* res = (ok__chosen_task*) out; 
	*res = value;
	return res;
}
ok__chosen_task _failok__chosen_task() {
	assert(0);
}


err__no_chosen_task* _initerr__no_chosen_task(byte* out, err__no_chosen_task value) {
	err__no_chosen_task* res = (err__no_chosen_task*) out; 
	*res = value;
	return res;
}
err__no_chosen_task _failerr__no_chosen_task() {
	assert(0);
}


opt__chosen_task* _initopt__chosen_task(byte* out, opt__chosen_task value) {
	opt__chosen_task* res = (opt__chosen_task*) out; 
	*res = value;
	return res;
}
opt__chosen_task _failopt__chosen_task() {
	assert(0);
}


some__chosen_task* _initsome__chosen_task(byte* out, some__chosen_task value) {
	some__chosen_task* res = (some__chosen_task*) out; 
	*res = value;
	return res;
}
some__chosen_task _failsome__chosen_task() {
	assert(0);
}


opt__opt__task* _initopt__opt__task(byte* out, opt__opt__task value) {
	opt__opt__task* res = (opt__opt__task*) out; 
	*res = value;
	return res;
}
opt__opt__task _failopt__opt__task() {
	assert(0);
}


some__opt__task* _initsome__opt__task(byte* out, some__opt__task value) {
	some__opt__task* res = (some__opt__task*) out; 
	*res = value;
	return res;
}
some__opt__task _failsome__opt__task() {
	assert(0);
}


task_and_nodes* _inittask_and_nodes(byte* out, task_and_nodes value) {
	task_and_nodes* res = (task_and_nodes*) out; 
	*res = value;
	return res;
}
task_and_nodes _failtask_and_nodes() {
	assert(0);
}


opt__task_and_nodes* _initopt__task_and_nodes(byte* out, opt__task_and_nodes value) {
	opt__task_and_nodes* res = (opt__task_and_nodes*) out; 
	*res = value;
	return res;
}
opt__task_and_nodes _failopt__task_and_nodes() {
	assert(0);
}


some__task_and_nodes* _initsome__task_and_nodes(byte* out, some__task_and_nodes value) {
	some__task_and_nodes* res = (some__task_and_nodes*) out; 
	*res = value;
	return res;
}
some__task_and_nodes _failsome__task_and_nodes() {
	assert(0);
}


arr__nat* _initarr__nat(byte* out, arr__nat value) {
	arr__nat* res = (arr__nat*) out; 
	*res = value;
	return res;
}
arr__nat _failarr__nat() {
	assert(0);
}


test_options* _inittest_options(byte* out, test_options value) {
	test_options* res = (test_options*) out; 
	*res = value;
	return res;
}
test_options _failtest_options() {
	assert(0);
}


opt__test_options* _initopt__test_options(byte* out, opt__test_options value) {
	opt__test_options* res = (opt__test_options*) out; 
	*res = value;
	return res;
}
opt__test_options _failopt__test_options() {
	assert(0);
}


some__test_options* _initsome__test_options(byte* out, some__test_options value) {
	some__test_options* res = (some__test_options*) out; 
	*res = value;
	return res;
}
some__test_options _failsome__test_options() {
	assert(0);
}


opt__arr__arr__char* _initopt__arr__arr__char(byte* out, opt__arr__arr__char value) {
	opt__arr__arr__char* res = (opt__arr__arr__char*) out; 
	*res = value;
	return res;
}
opt__arr__arr__char _failopt__arr__arr__char() {
	assert(0);
}


some__arr__arr__char* _initsome__arr__arr__char(byte* out, some__arr__arr__char value) {
	some__arr__arr__char* res = (some__arr__arr__char*) out; 
	*res = value;
	return res;
}
some__arr__arr__char _failsome__arr__arr__char() {
	assert(0);
}


arr__opt__arr__arr__char* _initarr__opt__arr__arr__char(byte* out, arr__opt__arr__arr__char value) {
	arr__opt__arr__arr__char* res = (arr__opt__arr__arr__char*) out; 
	*res = value;
	return res;
}
arr__opt__arr__arr__char _failarr__opt__arr__arr__char() {
	assert(0);
}


ptr__opt__arr__arr__char* _initptr__opt__arr__arr__char(byte* out, ptr__opt__arr__arr__char value) {
	ptr__opt__arr__arr__char* res = (ptr__opt__arr__arr__char*) out; 
	*res = value;
	return res;
}
ptr__opt__arr__arr__char _failptr__opt__arr__arr__char() {
	assert(0);
}


fun1__test_options__arr__opt__arr__arr__char* _initfun1__test_options__arr__opt__arr__arr__char(byte* out, fun1__test_options__arr__opt__arr__arr__char value) {
	fun1__test_options__arr__opt__arr__arr__char* res = (fun1__test_options__arr__opt__arr__arr__char*) out; 
	*res = value;
	return res;
}
fun1__test_options__arr__opt__arr__arr__char _failfun1__test_options__arr__opt__arr__arr__char() {
	assert(0);
}


fun_ptr3__test_options__ptr_ctx__ptr__byte__arr__opt__arr__arr__char* _initfun_ptr3__test_options__ptr_ctx__ptr__byte__arr__opt__arr__arr__char(byte* out, fun_ptr3__test_options__ptr_ctx__ptr__byte__arr__opt__arr__arr__char value) {
	fun_ptr3__test_options__ptr_ctx__ptr__byte__arr__opt__arr__arr__char* res = (fun_ptr3__test_options__ptr_ctx__ptr__byte__arr__opt__arr__arr__char*) out; 
	*res = value;
	return res;
}
fun_ptr3__test_options__ptr_ctx__ptr__byte__arr__opt__arr__arr__char _failfun_ptr3__test_options__ptr_ctx__ptr__byte__arr__opt__arr__arr__char() {
	assert(0);
}


parsed_cmd_line_args* _initparsed_cmd_line_args(byte* out, parsed_cmd_line_args value) {
	parsed_cmd_line_args* res = (parsed_cmd_line_args*) out; 
	*res = value;
	return res;
}
parsed_cmd_line_args _failparsed_cmd_line_args() {
	assert(0);
}


dict__arr__char__arr__arr__char* _initdict__arr__char__arr__arr__char(byte* out, dict__arr__char__arr__arr__char value) {
	dict__arr__char__arr__arr__char* res = (dict__arr__char__arr__arr__char*) out; 
	*res = value;
	return res;
}
dict__arr__char__arr__arr__char _faildict__arr__char__arr__arr__char() {
	assert(0);
}


arr__arr__arr__char* _initarr__arr__arr__char(byte* out, arr__arr__arr__char value) {
	arr__arr__arr__char* res = (arr__arr__arr__char*) out; 
	*res = value;
	return res;
}
arr__arr__arr__char _failarr__arr__arr__char() {
	assert(0);
}


ptr__arr__arr__char* _initptr__arr__arr__char(byte* out, ptr__arr__arr__char value) {
	ptr__arr__arr__char* res = (ptr__arr__arr__char*) out; 
	*res = value;
	return res;
}
ptr__arr__arr__char _failptr__arr__arr__char() {
	assert(0);
}


opt__nat* _initopt__nat(byte* out, opt__nat value) {
	opt__nat* res = (opt__nat*) out; 
	*res = value;
	return res;
}
opt__nat _failopt__nat() {
	assert(0);
}


some__nat* _initsome__nat(byte* out, some__nat value) {
	some__nat* res = (some__nat*) out; 
	*res = value;
	return res;
}
some__nat _failsome__nat() {
	assert(0);
}


fun_mut1__bool__arr__char* _initfun_mut1__bool__arr__char(byte* out, fun_mut1__bool__arr__char value) {
	fun_mut1__bool__arr__char* res = (fun_mut1__bool__arr__char*) out; 
	*res = value;
	return res;
}
fun_mut1__bool__arr__char _failfun_mut1__bool__arr__char() {
	assert(0);
}


fun_ptr3__bool__ptr_ctx__ptr__byte__arr__char* _initfun_ptr3__bool__ptr_ctx__ptr__byte__arr__char(byte* out, fun_ptr3__bool__ptr_ctx__ptr__byte__arr__char value) {
	fun_ptr3__bool__ptr_ctx__ptr__byte__arr__char* res = (fun_ptr3__bool__ptr_ctx__ptr__byte__arr__char*) out; 
	*res = value;
	return res;
}
fun_ptr3__bool__ptr_ctx__ptr__byte__arr__char _failfun_ptr3__bool__ptr_ctx__ptr__byte__arr__char() {
	assert(0);
}


mut_dict__arr__char__arr__arr__char* _initmut_dict__arr__char__arr__arr__char(byte* out, mut_dict__arr__char__arr__arr__char value) {
	mut_dict__arr__char__arr__arr__char* res = (mut_dict__arr__char__arr__arr__char*) out; 
	*res = value;
	return res;
}
mut_dict__arr__char__arr__arr__char _failmut_dict__arr__char__arr__arr__char() {
	assert(0);
}


mut_arr__arr__arr__char* _initmut_arr__arr__arr__char(byte* out, mut_arr__arr__arr__char value) {
	mut_arr__arr__arr__char* res = (mut_arr__arr__arr__char*) out; 
	*res = value;
	return res;
}
mut_arr__arr__arr__char _failmut_arr__arr__arr__char() {
	assert(0);
}


opt__arr__char* _initopt__arr__char(byte* out, opt__arr__char value) {
	opt__arr__char* res = (opt__arr__char*) out; 
	*res = value;
	return res;
}
opt__arr__char _failopt__arr__char() {
	assert(0);
}


some__arr__char* _initsome__arr__char(byte* out, some__arr__char value) {
	some__arr__char* res = (some__arr__char*) out; 
	*res = value;
	return res;
}
some__arr__char _failsome__arr__char() {
	assert(0);
}


mut_arr__opt__arr__arr__char* _initmut_arr__opt__arr__arr__char(byte* out, mut_arr__opt__arr__arr__char value) {
	mut_arr__opt__arr__arr__char* res = (mut_arr__opt__arr__arr__char*) out; 
	*res = value;
	return res;
}
mut_arr__opt__arr__arr__char _failmut_arr__opt__arr__arr__char() {
	assert(0);
}


fun_mut1__opt__arr__arr__char__nat* _initfun_mut1__opt__arr__arr__char__nat(byte* out, fun_mut1__opt__arr__arr__char__nat value) {
	fun_mut1__opt__arr__arr__char__nat* res = (fun_mut1__opt__arr__arr__char__nat*) out; 
	*res = value;
	return res;
}
fun_mut1__opt__arr__arr__char__nat _failfun_mut1__opt__arr__arr__char__nat() {
	assert(0);
}


fun_ptr3__opt__arr__arr__char__ptr_ctx__ptr__byte__nat* _initfun_ptr3__opt__arr__arr__char__ptr_ctx__ptr__byte__nat(byte* out, fun_ptr3__opt__arr__arr__char__ptr_ctx__ptr__byte__nat value) {
	fun_ptr3__opt__arr__arr__char__ptr_ctx__ptr__byte__nat* res = (fun_ptr3__opt__arr__arr__char__ptr_ctx__ptr__byte__nat*) out; 
	*res = value;
	return res;
}
fun_ptr3__opt__arr__arr__char__ptr_ctx__ptr__byte__nat _failfun_ptr3__opt__arr__arr__char__ptr_ctx__ptr__byte__nat() {
	assert(0);
}


fill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat__opt__arr__arr__char__lambda0___closure* _initfill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat__opt__arr__arr__char__lambda0___closure(byte* out, fill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat__opt__arr__arr__char__lambda0___closure value) {
	fill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat__opt__arr__arr__char__lambda0___closure* res = (fill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat__opt__arr__arr__char__lambda0___closure*) out; 
	*res = value;
	return res;
}
fill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat__opt__arr__arr__char__lambda0___closure _failfill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat__opt__arr__arr__char__lambda0___closure() {
	assert(0);
}


cell__bool* _initcell__bool(byte* out, cell__bool value) {
	cell__bool* res = (cell__bool*) out; 
	*res = value;
	return res;
}
cell__bool _failcell__bool() {
	assert(0);
}


fun_mut2___void__arr__char__arr__arr__char* _initfun_mut2___void__arr__char__arr__arr__char(byte* out, fun_mut2___void__arr__char__arr__arr__char value) {
	fun_mut2___void__arr__char__arr__arr__char* res = (fun_mut2___void__arr__char__arr__arr__char*) out; 
	*res = value;
	return res;
}
fun_mut2___void__arr__char__arr__arr__char _failfun_mut2___void__arr__char__arr__arr__char() {
	assert(0);
}


fun_ptr4___void__ptr_ctx__ptr__byte__arr__char__arr__arr__char* _initfun_ptr4___void__ptr_ctx__ptr__byte__arr__char__arr__arr__char(byte* out, fun_ptr4___void__ptr_ctx__ptr__byte__arr__char__arr__arr__char value) {
	fun_ptr4___void__ptr_ctx__ptr__byte__arr__char__arr__arr__char* res = (fun_ptr4___void__ptr_ctx__ptr__byte__arr__char__arr__arr__char*) out; 
	*res = value;
	return res;
}
fun_ptr4___void__ptr_ctx__ptr__byte__arr__char__arr__arr__char _failfun_ptr4___void__ptr_ctx__ptr__byte__arr__char__arr__arr__char() {
	assert(0);
}


parse_cmd_line_args__opt__test_options__arr__arr__char__arr__arr__char__fun1__test_options__arr__opt__arr__arr__char__lambda0___closure* _initparse_cmd_line_args__opt__test_options__arr__arr__char__arr__arr__char__fun1__test_options__arr__opt__arr__arr__char__lambda0___closure(byte* out, parse_cmd_line_args__opt__test_options__arr__arr__char__arr__arr__char__fun1__test_options__arr__opt__arr__arr__char__lambda0___closure value) {
	parse_cmd_line_args__opt__test_options__arr__arr__char__arr__arr__char__fun1__test_options__arr__opt__arr__arr__char__lambda0___closure* res = (parse_cmd_line_args__opt__test_options__arr__arr__char__arr__arr__char__fun1__test_options__arr__opt__arr__arr__char__lambda0___closure*) out; 
	*res = value;
	return res;
}
parse_cmd_line_args__opt__test_options__arr__arr__char__arr__arr__char__fun1__test_options__arr__opt__arr__arr__char__lambda0___closure _failparse_cmd_line_args__opt__test_options__arr__arr__char__arr__arr__char__fun1__test_options__arr__opt__arr__arr__char__lambda0___closure() {
	assert(0);
}


index_of__opt__nat__arr__arr__char__arr__char__lambda0___closure* _initindex_of__opt__nat__arr__arr__char__arr__char__lambda0___closure(byte* out, index_of__opt__nat__arr__arr__char__arr__char__lambda0___closure value) {
	index_of__opt__nat__arr__arr__char__arr__char__lambda0___closure* res = (index_of__opt__nat__arr__arr__char__arr__char__lambda0___closure*) out; 
	*res = value;
	return res;
}
index_of__opt__nat__arr__arr__char__arr__char__lambda0___closure _failindex_of__opt__nat__arr__arr__char__arr__char__lambda0___closure() {
	assert(0);
}


fun_mut1__char__nat* _initfun_mut1__char__nat(byte* out, fun_mut1__char__nat value) {
	fun_mut1__char__nat* res = (fun_mut1__char__nat*) out; 
	*res = value;
	return res;
}
fun_mut1__char__nat _failfun_mut1__char__nat() {
	assert(0);
}


fun_ptr3__char__ptr_ctx__ptr__byte__nat* _initfun_ptr3__char__ptr_ctx__ptr__byte__nat(byte* out, fun_ptr3__char__ptr_ctx__ptr__byte__nat value) {
	fun_ptr3__char__ptr_ctx__ptr__byte__nat* res = (fun_ptr3__char__ptr_ctx__ptr__byte__nat*) out; 
	*res = value;
	return res;
}
fun_ptr3__char__ptr_ctx__ptr__byte__nat _failfun_ptr3__char__ptr_ctx__ptr__byte__nat() {
	assert(0);
}


mut_arr__char* _initmut_arr__char(byte* out, mut_arr__char value) {
	mut_arr__char* res = (mut_arr__char*) out; 
	*res = value;
	return res;
}
mut_arr__char _failmut_arr__char() {
	assert(0);
}


_op_plus__arr__char__arr__char__arr__char__lambda0___closure* _init_op_plus__arr__char__arr__char__arr__char__lambda0___closure(byte* out, _op_plus__arr__char__arr__char__arr__char__lambda0___closure value) {
	_op_plus__arr__char__arr__char__arr__char__lambda0___closure* res = (_op_plus__arr__char__arr__char__arr__char__lambda0___closure*) out; 
	*res = value;
	return res;
}
_op_plus__arr__char__arr__char__arr__char__lambda0___closure _fail_op_plus__arr__char__arr__char__arr__char__lambda0___closure() {
	assert(0);
}


fun_mut1__bool__char* _initfun_mut1__bool__char(byte* out, fun_mut1__bool__char value) {
	fun_mut1__bool__char* res = (fun_mut1__bool__char*) out; 
	*res = value;
	return res;
}
fun_mut1__bool__char _failfun_mut1__bool__char() {
	assert(0);
}


fun_ptr3__bool__ptr_ctx__ptr__byte__char* _initfun_ptr3__bool__ptr_ctx__ptr__byte__char(byte* out, fun_ptr3__bool__ptr_ctx__ptr__byte__char value) {
	fun_ptr3__bool__ptr_ctx__ptr__byte__char* res = (fun_ptr3__bool__ptr_ctx__ptr__byte__char*) out; 
	*res = value;
	return res;
}
fun_ptr3__bool__ptr_ctx__ptr__byte__char _failfun_ptr3__bool__ptr_ctx__ptr__byte__char() {
	assert(0);
}


r_index_of__opt__nat__arr__char__char__lambda0___closure* _initr_index_of__opt__nat__arr__char__char__lambda0___closure(byte* out, r_index_of__opt__nat__arr__char__char__lambda0___closure value) {
	r_index_of__opt__nat__arr__char__char__lambda0___closure* res = (r_index_of__opt__nat__arr__char__char__lambda0___closure*) out; 
	*res = value;
	return res;
}
r_index_of__opt__nat__arr__char__char__lambda0___closure _failr_index_of__opt__nat__arr__char__char__lambda0___closure() {
	assert(0);
}


dict__arr__char__arr__char* _initdict__arr__char__arr__char(byte* out, dict__arr__char__arr__char value) {
	dict__arr__char__arr__char* res = (dict__arr__char__arr__char*) out; 
	*res = value;
	return res;
}
dict__arr__char__arr__char _faildict__arr__char__arr__char() {
	assert(0);
}


mut_dict__arr__char__arr__char* _initmut_dict__arr__char__arr__char(byte* out, mut_dict__arr__char__arr__char value) {
	mut_dict__arr__char__arr__char* res = (mut_dict__arr__char__arr__char*) out; 
	*res = value;
	return res;
}
mut_dict__arr__char__arr__char _failmut_dict__arr__char__arr__char() {
	assert(0);
}


key_value_pair__arr__char__arr__char* _initkey_value_pair__arr__char__arr__char(byte* out, key_value_pair__arr__char__arr__char value) {
	key_value_pair__arr__char__arr__char* res = (key_value_pair__arr__char__arr__char*) out; 
	*res = value;
	return res;
}
key_value_pair__arr__char__arr__char _failkey_value_pair__arr__char__arr__char() {
	assert(0);
}


failure* _initfailure(byte* out, failure value) {
	failure* res = (failure*) out; 
	*res = value;
	return res;
}
failure _failfailure() {
	assert(0);
}


arr__ptr_failure* _initarr__ptr_failure(byte* out, arr__ptr_failure value) {
	arr__ptr_failure* res = (arr__ptr_failure*) out; 
	*res = value;
	return res;
}
arr__ptr_failure _failarr__ptr_failure() {
	assert(0);
}


ptr__ptr_failure* _initptr__ptr_failure(byte* out, ptr__ptr_failure value) {
	ptr__ptr_failure* res = (ptr__ptr_failure*) out; 
	*res = value;
	return res;
}
ptr__ptr_failure _failptr__ptr_failure() {
	assert(0);
}


result__arr__char__arr__ptr_failure* _initresult__arr__char__arr__ptr_failure(byte* out, result__arr__char__arr__ptr_failure value) {
	result__arr__char__arr__ptr_failure* res = (result__arr__char__arr__ptr_failure*) out; 
	*res = value;
	return res;
}
result__arr__char__arr__ptr_failure _failresult__arr__char__arr__ptr_failure() {
	assert(0);
}


ok__arr__char* _initok__arr__char(byte* out, ok__arr__char value) {
	ok__arr__char* res = (ok__arr__char*) out; 
	*res = value;
	return res;
}
ok__arr__char _failok__arr__char() {
	assert(0);
}


err__arr__ptr_failure* _initerr__arr__ptr_failure(byte* out, err__arr__ptr_failure value) {
	err__arr__ptr_failure* res = (err__arr__ptr_failure*) out; 
	*res = value;
	return res;
}
err__arr__ptr_failure _failerr__arr__ptr_failure() {
	assert(0);
}


fun_mut1___void__arr__char* _initfun_mut1___void__arr__char(byte* out, fun_mut1___void__arr__char value) {
	fun_mut1___void__arr__char* res = (fun_mut1___void__arr__char*) out; 
	*res = value;
	return res;
}
fun_mut1___void__arr__char _failfun_mut1___void__arr__char() {
	assert(0);
}


fun_ptr3___void__ptr_ctx__ptr__byte__arr__char* _initfun_ptr3___void__ptr_ctx__ptr__byte__arr__char(byte* out, fun_ptr3___void__ptr_ctx__ptr__byte__arr__char value) {
	fun_ptr3___void__ptr_ctx__ptr__byte__arr__char* res = (fun_ptr3___void__ptr_ctx__ptr__byte__arr__char*) out; 
	*res = value;
	return res;
}
fun_ptr3___void__ptr_ctx__ptr__byte__arr__char _failfun_ptr3___void__ptr_ctx__ptr__byte__arr__char() {
	assert(0);
}


stat_t* _initstat_t(byte* out, stat_t value) {
	stat_t* res = (stat_t*) out; 
	*res = value;
	return res;
}
stat_t _failstat_t() {
	assert(0);
}


nat32* _initnat32(byte* out, nat32 value) {
	nat32* res = (nat32*) out; 
	*res = value;
	return res;
}
nat32 _failnat32() {
	assert(0);
}


opt__ptr_stat_t* _initopt__ptr_stat_t(byte* out, opt__ptr_stat_t value) {
	opt__ptr_stat_t* res = (opt__ptr_stat_t*) out; 
	*res = value;
	return res;
}
opt__ptr_stat_t _failopt__ptr_stat_t() {
	assert(0);
}


some__ptr_stat_t* _initsome__ptr_stat_t(byte* out, some__ptr_stat_t value) {
	some__ptr_stat_t* res = (some__ptr_stat_t*) out; 
	*res = value;
	return res;
}
some__ptr_stat_t _failsome__ptr_stat_t() {
	assert(0);
}


dirent* _initdirent(byte* out, dirent value) {
	dirent* res = (dirent*) out; 
	*res = value;
	return res;
}
dirent _faildirent() {
	assert(0);
}


nat16* _initnat16(byte* out, nat16 value) {
	nat16* res = (nat16*) out; 
	*res = value;
	return res;
}
nat16 _failnat16() {
	assert(0);
}


bytes256* _initbytes256(byte* out, bytes256 value) {
	bytes256* res = (bytes256*) out; 
	*res = value;
	return res;
}
bytes256 _failbytes256() {
	assert(0);
}


cell__ptr_dirent* _initcell__ptr_dirent(byte* out, cell__ptr_dirent value) {
	cell__ptr_dirent* res = (cell__ptr_dirent*) out; 
	*res = value;
	return res;
}
cell__ptr_dirent _failcell__ptr_dirent() {
	assert(0);
}


to_mut_arr__ptr_mut_arr__arr__char__arr__arr__char__lambda0___closure* _initto_mut_arr__ptr_mut_arr__arr__char__arr__arr__char__lambda0___closure(byte* out, to_mut_arr__ptr_mut_arr__arr__char__arr__arr__char__lambda0___closure value) {
	to_mut_arr__ptr_mut_arr__arr__char__arr__arr__char__lambda0___closure* res = (to_mut_arr__ptr_mut_arr__arr__char__arr__arr__char__lambda0___closure*) out; 
	*res = value;
	return res;
}
to_mut_arr__ptr_mut_arr__arr__char__arr__arr__char__lambda0___closure _failto_mut_arr__ptr_mut_arr__arr__char__arr__arr__char__lambda0___closure() {
	assert(0);
}


mut_slice__arr__char* _initmut_slice__arr__char(byte* out, mut_slice__arr__char value) {
	mut_slice__arr__char* res = (mut_slice__arr__char*) out; 
	*res = value;
	return res;
}
mut_slice__arr__char _failmut_slice__arr__char() {
	assert(0);
}


each_child_recursive___void__arr__char__fun_mut1__bool__arr__char__fun_mut1___void__arr__char__lambda0___closure* _initeach_child_recursive___void__arr__char__fun_mut1__bool__arr__char__fun_mut1___void__arr__char__lambda0___closure(byte* out, each_child_recursive___void__arr__char__fun_mut1__bool__arr__char__fun_mut1___void__arr__char__lambda0___closure value) {
	each_child_recursive___void__arr__char__fun_mut1__bool__arr__char__fun_mut1___void__arr__char__lambda0___closure* res = (each_child_recursive___void__arr__char__fun_mut1__bool__arr__char__fun_mut1___void__arr__char__lambda0___closure*) out; 
	*res = value;
	return res;
}
each_child_recursive___void__arr__char__fun_mut1__bool__arr__char__fun_mut1___void__arr__char__lambda0___closure _faileach_child_recursive___void__arr__char__fun_mut1__bool__arr__char__fun_mut1___void__arr__char__lambda0___closure() {
	assert(0);
}


list_compile_error_tests__arr__arr__char__arr__char__lambda1___closure* _initlist_compile_error_tests__arr__arr__char__arr__char__lambda1___closure(byte* out, list_compile_error_tests__arr__arr__char__arr__char__lambda1___closure value) {
	list_compile_error_tests__arr__arr__char__arr__char__lambda1___closure* res = (list_compile_error_tests__arr__arr__char__arr__char__lambda1___closure*) out; 
	*res = value;
	return res;
}
list_compile_error_tests__arr__arr__char__arr__char__lambda1___closure _faillist_compile_error_tests__arr__arr__char__arr__char__lambda1___closure() {
	assert(0);
}


fun_mut1__arr__ptr_failure__arr__char* _initfun_mut1__arr__ptr_failure__arr__char(byte* out, fun_mut1__arr__ptr_failure__arr__char value) {
	fun_mut1__arr__ptr_failure__arr__char* res = (fun_mut1__arr__ptr_failure__arr__char*) out; 
	*res = value;
	return res;
}
fun_mut1__arr__ptr_failure__arr__char _failfun_mut1__arr__ptr_failure__arr__char() {
	assert(0);
}


fun_ptr3__arr__ptr_failure__ptr_ctx__ptr__byte__arr__char* _initfun_ptr3__arr__ptr_failure__ptr_ctx__ptr__byte__arr__char(byte* out, fun_ptr3__arr__ptr_failure__ptr_ctx__ptr__byte__arr__char value) {
	fun_ptr3__arr__ptr_failure__ptr_ctx__ptr__byte__arr__char* res = (fun_ptr3__arr__ptr_failure__ptr_ctx__ptr__byte__arr__char*) out; 
	*res = value;
	return res;
}
fun_ptr3__arr__ptr_failure__ptr_ctx__ptr__byte__arr__char _failfun_ptr3__arr__ptr_failure__ptr_ctx__ptr__byte__arr__char() {
	assert(0);
}


mut_arr__ptr_failure* _initmut_arr__ptr_failure(byte* out, mut_arr__ptr_failure value) {
	mut_arr__ptr_failure* res = (mut_arr__ptr_failure*) out; 
	*res = value;
	return res;
}
mut_arr__ptr_failure _failmut_arr__ptr_failure() {
	assert(0);
}


flat_map_with_max_size__arr__ptr_failure__arr__arr__char__nat__fun_mut1__arr__ptr_failure__arr__char__lambda0___closure* _initflat_map_with_max_size__arr__ptr_failure__arr__arr__char__nat__fun_mut1__arr__ptr_failure__arr__char__lambda0___closure(byte* out, flat_map_with_max_size__arr__ptr_failure__arr__arr__char__nat__fun_mut1__arr__ptr_failure__arr__char__lambda0___closure value) {
	flat_map_with_max_size__arr__ptr_failure__arr__arr__char__nat__fun_mut1__arr__ptr_failure__arr__char__lambda0___closure* res = (flat_map_with_max_size__arr__ptr_failure__arr__arr__char__nat__fun_mut1__arr__ptr_failure__arr__char__lambda0___closure*) out; 
	*res = value;
	return res;
}
flat_map_with_max_size__arr__ptr_failure__arr__arr__char__nat__fun_mut1__arr__ptr_failure__arr__char__lambda0___closure _failflat_map_with_max_size__arr__ptr_failure__arr__arr__char__nat__fun_mut1__arr__ptr_failure__arr__char__lambda0___closure() {
	assert(0);
}


fun_mut1___void__ptr_failure* _initfun_mut1___void__ptr_failure(byte* out, fun_mut1___void__ptr_failure value) {
	fun_mut1___void__ptr_failure* res = (fun_mut1___void__ptr_failure*) out; 
	*res = value;
	return res;
}
fun_mut1___void__ptr_failure _failfun_mut1___void__ptr_failure() {
	assert(0);
}


fun_ptr3___void__ptr_ctx__ptr__byte__ptr_failure* _initfun_ptr3___void__ptr_ctx__ptr__byte__ptr_failure(byte* out, fun_ptr3___void__ptr_ctx__ptr__byte__ptr_failure value) {
	fun_ptr3___void__ptr_ctx__ptr__byte__ptr_failure* res = (fun_ptr3___void__ptr_ctx__ptr__byte__ptr_failure*) out; 
	*res = value;
	return res;
}
fun_ptr3___void__ptr_ctx__ptr__byte__ptr_failure _failfun_ptr3___void__ptr_ctx__ptr__byte__ptr_failure() {
	assert(0);
}


push_all___void__ptr_mut_arr__ptr_failure__arr__ptr_failure__lambda0___closure* _initpush_all___void__ptr_mut_arr__ptr_failure__arr__ptr_failure__lambda0___closure(byte* out, push_all___void__ptr_mut_arr__ptr_failure__arr__ptr_failure__lambda0___closure value) {
	push_all___void__ptr_mut_arr__ptr_failure__arr__ptr_failure__lambda0___closure* res = (push_all___void__ptr_mut_arr__ptr_failure__arr__ptr_failure__lambda0___closure*) out; 
	*res = value;
	return res;
}
push_all___void__ptr_mut_arr__ptr_failure__arr__ptr_failure__lambda0___closure _failpush_all___void__ptr_mut_arr__ptr_failure__arr__ptr_failure__lambda0___closure() {
	assert(0);
}


run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0___closure* _initrun_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0___closure(byte* out, run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0___closure value) {
	run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0___closure* res = (run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0___closure*) out; 
	*res = value;
	return res;
}
run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0___closure _failrun_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0___closure() {
	assert(0);
}


process_result* _initprocess_result(byte* out, process_result value) {
	process_result* res = (process_result*) out; 
	*res = value;
	return res;
}
process_result _failprocess_result() {
	assert(0);
}


fun_mut2__arr__char__arr__char__arr__char* _initfun_mut2__arr__char__arr__char__arr__char(byte* out, fun_mut2__arr__char__arr__char__arr__char value) {
	fun_mut2__arr__char__arr__char__arr__char* res = (fun_mut2__arr__char__arr__char__arr__char*) out; 
	*res = value;
	return res;
}
fun_mut2__arr__char__arr__char__arr__char _failfun_mut2__arr__char__arr__char__arr__char() {
	assert(0);
}


fun_ptr4__arr__char__ptr_ctx__ptr__byte__arr__char__arr__char* _initfun_ptr4__arr__char__ptr_ctx__ptr__byte__arr__char__arr__char(byte* out, fun_ptr4__arr__char__ptr_ctx__ptr__byte__arr__char__arr__char value) {
	fun_ptr4__arr__char__ptr_ctx__ptr__byte__arr__char__arr__char* res = (fun_ptr4__arr__char__ptr_ctx__ptr__byte__arr__char__arr__char*) out; 
	*res = value;
	return res;
}
fun_ptr4__arr__char__ptr_ctx__ptr__byte__arr__char__arr__char _failfun_ptr4__arr__char__ptr_ctx__ptr__byte__arr__char__arr__char() {
	assert(0);
}


pipes* _initpipes(byte* out, pipes value) {
	pipes* res = (pipes*) out; 
	*res = value;
	return res;
}
pipes _failpipes() {
	assert(0);
}


posix_spawn_file_actions_t* _initposix_spawn_file_actions_t(byte* out, posix_spawn_file_actions_t value) {
	posix_spawn_file_actions_t* res = (posix_spawn_file_actions_t*) out; 
	*res = value;
	return res;
}
posix_spawn_file_actions_t _failposix_spawn_file_actions_t() {
	assert(0);
}


cell__int32* _initcell__int32(byte* out, cell__int32 value) {
	cell__int32* res = (cell__int32*) out; 
	*res = value;
	return res;
}
cell__int32 _failcell__int32() {
	assert(0);
}


pollfd* _initpollfd(byte* out, pollfd value) {
	pollfd* res = (pollfd*) out; 
	*res = value;
	return res;
}
pollfd _failpollfd() {
	assert(0);
}


int16* _initint16(byte* out, int16 value) {
	int16* res = (int16*) out; 
	*res = value;
	return res;
}
int16 _failint16() {
	assert(0);
}


arr__pollfd* _initarr__pollfd(byte* out, arr__pollfd value) {
	arr__pollfd* res = (arr__pollfd*) out; 
	*res = value;
	return res;
}
arr__pollfd _failarr__pollfd() {
	assert(0);
}


ptr__pollfd* _initptr__pollfd(byte* out, ptr__pollfd value) {
	ptr__pollfd* res = (ptr__pollfd*) out; 
	*res = value;
	return res;
}
ptr__pollfd _failptr__pollfd() {
	assert(0);
}


handle_revents_result* _inithandle_revents_result(byte* out, handle_revents_result value) {
	handle_revents_result* res = (handle_revents_result*) out; 
	*res = value;
	return res;
}
handle_revents_result _failhandle_revents_result() {
	assert(0);
}


fun_mut1__ptr__char__nat* _initfun_mut1__ptr__char__nat(byte* out, fun_mut1__ptr__char__nat value) {
	fun_mut1__ptr__char__nat* res = (fun_mut1__ptr__char__nat*) out; 
	*res = value;
	return res;
}
fun_mut1__ptr__char__nat _failfun_mut1__ptr__char__nat() {
	assert(0);
}


fun_ptr3__ptr__char__ptr_ctx__ptr__byte__nat* _initfun_ptr3__ptr__char__ptr_ctx__ptr__byte__nat(byte* out, fun_ptr3__ptr__char__ptr_ctx__ptr__byte__nat value) {
	fun_ptr3__ptr__char__ptr_ctx__ptr__byte__nat* res = (fun_ptr3__ptr__char__ptr_ctx__ptr__byte__nat*) out; 
	*res = value;
	return res;
}
fun_ptr3__ptr__char__ptr_ctx__ptr__byte__nat _failfun_ptr3__ptr__char__ptr_ctx__ptr__byte__nat() {
	assert(0);
}


mut_arr__ptr__char* _initmut_arr__ptr__char(byte* out, mut_arr__ptr__char value) {
	mut_arr__ptr__char* res = (mut_arr__ptr__char*) out; 
	*res = value;
	return res;
}
mut_arr__ptr__char _failmut_arr__ptr__char() {
	assert(0);
}


_op_plus__arr__ptr__char__arr__ptr__char__arr__ptr__char__lambda0___closure* _init_op_plus__arr__ptr__char__arr__ptr__char__arr__ptr__char__lambda0___closure(byte* out, _op_plus__arr__ptr__char__arr__ptr__char__arr__ptr__char__lambda0___closure value) {
	_op_plus__arr__ptr__char__arr__ptr__char__arr__ptr__char__lambda0___closure* res = (_op_plus__arr__ptr__char__arr__ptr__char__arr__ptr__char__lambda0___closure*) out; 
	*res = value;
	return res;
}
_op_plus__arr__ptr__char__arr__ptr__char__arr__ptr__char__lambda0___closure _fail_op_plus__arr__ptr__char__arr__ptr__char__arr__ptr__char__lambda0___closure() {
	assert(0);
}


fun_mut1__ptr__char__arr__char* _initfun_mut1__ptr__char__arr__char(byte* out, fun_mut1__ptr__char__arr__char value) {
	fun_mut1__ptr__char__arr__char* res = (fun_mut1__ptr__char__arr__char*) out; 
	*res = value;
	return res;
}
fun_mut1__ptr__char__arr__char _failfun_mut1__ptr__char__arr__char() {
	assert(0);
}


fun_ptr3__ptr__char__ptr_ctx__ptr__byte__arr__char* _initfun_ptr3__ptr__char__ptr_ctx__ptr__byte__arr__char(byte* out, fun_ptr3__ptr__char__ptr_ctx__ptr__byte__arr__char value) {
	fun_ptr3__ptr__char__ptr_ctx__ptr__byte__arr__char* res = (fun_ptr3__ptr__char__ptr_ctx__ptr__byte__arr__char*) out; 
	*res = value;
	return res;
}
fun_ptr3__ptr__char__ptr_ctx__ptr__byte__arr__char _failfun_ptr3__ptr__char__ptr_ctx__ptr__byte__arr__char() {
	assert(0);
}


map__arr__ptr__char__arr__arr__char__fun_mut1__ptr__char__arr__char__lambda0___closure* _initmap__arr__ptr__char__arr__arr__char__fun_mut1__ptr__char__arr__char__lambda0___closure(byte* out, map__arr__ptr__char__arr__arr__char__fun_mut1__ptr__char__arr__char__lambda0___closure value) {
	map__arr__ptr__char__arr__arr__char__fun_mut1__ptr__char__arr__char__lambda0___closure* res = (map__arr__ptr__char__arr__arr__char__fun_mut1__ptr__char__arr__char__lambda0___closure*) out; 
	*res = value;
	return res;
}
map__arr__ptr__char__arr__arr__char__fun_mut1__ptr__char__arr__char__lambda0___closure _failmap__arr__ptr__char__arr__arr__char__fun_mut1__ptr__char__arr__char__lambda0___closure() {
	assert(0);
}


fun_mut2___void__arr__char__arr__char* _initfun_mut2___void__arr__char__arr__char(byte* out, fun_mut2___void__arr__char__arr__char value) {
	fun_mut2___void__arr__char__arr__char* res = (fun_mut2___void__arr__char__arr__char*) out; 
	*res = value;
	return res;
}
fun_mut2___void__arr__char__arr__char _failfun_mut2___void__arr__char__arr__char() {
	assert(0);
}


fun_ptr4___void__ptr_ctx__ptr__byte__arr__char__arr__char* _initfun_ptr4___void__ptr_ctx__ptr__byte__arr__char__arr__char(byte* out, fun_ptr4___void__ptr_ctx__ptr__byte__arr__char__arr__char value) {
	fun_ptr4___void__ptr_ctx__ptr__byte__arr__char__arr__char* res = (fun_ptr4___void__ptr_ctx__ptr__byte__arr__char__arr__char*) out; 
	*res = value;
	return res;
}
fun_ptr4___void__ptr_ctx__ptr__byte__arr__char__arr__char _failfun_ptr4___void__ptr_ctx__ptr__byte__arr__char__arr__char() {
	assert(0);
}


convert_environ__ptr__ptr__char__ptr_dict__arr__char__arr__char__lambda0___closure* _initconvert_environ__ptr__ptr__char__ptr_dict__arr__char__arr__char__lambda0___closure(byte* out, convert_environ__ptr__ptr__char__ptr_dict__arr__char__arr__char__lambda0___closure value) {
	convert_environ__ptr__ptr__char__ptr_dict__arr__char__arr__char__lambda0___closure* res = (convert_environ__ptr__ptr__char__ptr_dict__arr__char__arr__char__lambda0___closure*) out; 
	*res = value;
	return res;
}
convert_environ__ptr__ptr__char__ptr_dict__arr__char__arr__char__lambda0___closure _failconvert_environ__ptr__ptr__char__ptr_dict__arr__char__arr__char__lambda0___closure() {
	assert(0);
}


fun0__result__arr__char__arr__ptr_failure* _initfun0__result__arr__char__arr__ptr_failure(byte* out, fun0__result__arr__char__arr__ptr_failure value) {
	fun0__result__arr__char__arr__ptr_failure* res = (fun0__result__arr__char__arr__ptr_failure*) out; 
	*res = value;
	return res;
}
fun0__result__arr__char__arr__ptr_failure _failfun0__result__arr__char__arr__ptr_failure() {
	assert(0);
}


fun_ptr2__result__arr__char__arr__ptr_failure__ptr_ctx__ptr__byte* _initfun_ptr2__result__arr__char__arr__ptr_failure__ptr_ctx__ptr__byte(byte* out, fun_ptr2__result__arr__char__arr__ptr_failure__ptr_ctx__ptr__byte value) {
	fun_ptr2__result__arr__char__arr__ptr_failure__ptr_ctx__ptr__byte* res = (fun_ptr2__result__arr__char__arr__ptr_failure__ptr_ctx__ptr__byte*) out; 
	*res = value;
	return res;
}
fun_ptr2__result__arr__char__arr__ptr_failure__ptr_ctx__ptr__byte _failfun_ptr2__result__arr__char__arr__ptr_failure__ptr_ctx__ptr__byte() {
	assert(0);
}


fun_mut1__result__arr__char__arr__ptr_failure__arr__char* _initfun_mut1__result__arr__char__arr__ptr_failure__arr__char(byte* out, fun_mut1__result__arr__char__arr__ptr_failure__arr__char value) {
	fun_mut1__result__arr__char__arr__ptr_failure__arr__char* res = (fun_mut1__result__arr__char__arr__ptr_failure__arr__char*) out; 
	*res = value;
	return res;
}
fun_mut1__result__arr__char__arr__ptr_failure__arr__char _failfun_mut1__result__arr__char__arr__ptr_failure__arr__char() {
	assert(0);
}


fun_ptr3__result__arr__char__arr__ptr_failure__ptr_ctx__ptr__byte__arr__char* _initfun_ptr3__result__arr__char__arr__ptr_failure__ptr_ctx__ptr__byte__arr__char(byte* out, fun_ptr3__result__arr__char__arr__ptr_failure__ptr_ctx__ptr__byte__arr__char value) {
	fun_ptr3__result__arr__char__arr__ptr_failure__ptr_ctx__ptr__byte__arr__char* res = (fun_ptr3__result__arr__char__arr__ptr_failure__ptr_ctx__ptr__byte__arr__char*) out; 
	*res = value;
	return res;
}
fun_ptr3__result__arr__char__arr__ptr_failure__ptr_ctx__ptr__byte__arr__char _failfun_ptr3__result__arr__char__arr__ptr_failure__ptr_ctx__ptr__byte__arr__char() {
	assert(0);
}


first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure__lambda0___closure* _initfirst_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure__lambda0___closure(byte* out, first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure__lambda0___closure value) {
	first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure__lambda0___closure* res = (first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure__lambda0___closure*) out; 
	*res = value;
	return res;
}
first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure__lambda0___closure _failfirst_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure__lambda0___closure() {
	assert(0);
}


first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure__lambda0__lambda0___closure* _initfirst_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure__lambda0__lambda0___closure(byte* out, first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure__lambda0__lambda0___closure value) {
	first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure__lambda0__lambda0___closure* res = (first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure__lambda0__lambda0___closure*) out; 
	*res = value;
	return res;
}
first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure__lambda0__lambda0___closure _failfirst_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure__lambda0__lambda0___closure() {
	assert(0);
}


do_test__int32__test_options__lambda0___closure* _initdo_test__int32__test_options__lambda0___closure(byte* out, do_test__int32__test_options__lambda0___closure value) {
	do_test__int32__test_options__lambda0___closure* res = (do_test__int32__test_options__lambda0___closure*) out; 
	*res = value;
	return res;
}
do_test__int32__test_options__lambda0___closure _faildo_test__int32__test_options__lambda0___closure() {
	assert(0);
}


list_ast_and_model_tests__arr__arr__char__arr__char__lambda1___closure* _initlist_ast_and_model_tests__arr__arr__char__arr__char__lambda1___closure(byte* out, list_ast_and_model_tests__arr__arr__char__arr__char__lambda1___closure value) {
	list_ast_and_model_tests__arr__arr__char__arr__char__lambda1___closure* res = (list_ast_and_model_tests__arr__arr__char__arr__char__lambda1___closure*) out; 
	*res = value;
	return res;
}
list_ast_and_model_tests__arr__arr__char__arr__char__lambda1___closure _faillist_ast_and_model_tests__arr__arr__char__arr__char__lambda1___closure() {
	assert(0);
}


run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0___closure* _initrun_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0___closure(byte* out, run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0___closure value) {
	run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0___closure* res = (run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0___closure*) out; 
	*res = value;
	return res;
}
run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0___closure _failrun_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0___closure() {
	assert(0);
}


fun_mut0__arr__ptr_failure* _initfun_mut0__arr__ptr_failure(byte* out, fun_mut0__arr__ptr_failure value) {
	fun_mut0__arr__ptr_failure* res = (fun_mut0__arr__ptr_failure*) out; 
	*res = value;
	return res;
}
fun_mut0__arr__ptr_failure _failfun_mut0__arr__ptr_failure() {
	assert(0);
}


fun_ptr2__arr__ptr_failure__ptr_ctx__ptr__byte* _initfun_ptr2__arr__ptr_failure__ptr_ctx__ptr__byte(byte* out, fun_ptr2__arr__ptr_failure__ptr_ctx__ptr__byte value) {
	fun_ptr2__arr__ptr_failure__ptr_ctx__ptr__byte* res = (fun_ptr2__arr__ptr_failure__ptr_ctx__ptr__byte*) out; 
	*res = value;
	return res;
}
fun_ptr2__arr__ptr_failure__ptr_ctx__ptr__byte _failfun_ptr2__arr__ptr_failure__ptr_ctx__ptr__byte() {
	assert(0);
}


run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0__lambda0___closure* _initrun_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0__lambda0___closure(byte* out, run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0__lambda0___closure value) {
	run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0__lambda0___closure* res = (run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0__lambda0___closure*) out; 
	*res = value;
	return res;
}
run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0__lambda0___closure _failrun_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0__lambda0___closure() {
	assert(0);
}


run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0__lambda0__lambda0___closure* _initrun_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0__lambda0__lambda0___closure(byte* out, run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0__lambda0__lambda0___closure value) {
	run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0__lambda0__lambda0___closure* res = (run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0__lambda0__lambda0___closure*) out; 
	*res = value;
	return res;
}
run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0__lambda0__lambda0___closure _failrun_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0__lambda0__lambda0___closure() {
	assert(0);
}


do_test__int32__test_options__lambda0__lambda0___closure* _initdo_test__int32__test_options__lambda0__lambda0___closure(byte* out, do_test__int32__test_options__lambda0__lambda0___closure value) {
	do_test__int32__test_options__lambda0__lambda0___closure* res = (do_test__int32__test_options__lambda0__lambda0___closure*) out; 
	*res = value;
	return res;
}
do_test__int32__test_options__lambda0__lambda0___closure _faildo_test__int32__test_options__lambda0__lambda0___closure() {
	assert(0);
}


list_runnable_tests__arr__arr__char__arr__char__lambda1___closure* _initlist_runnable_tests__arr__arr__char__arr__char__lambda1___closure(byte* out, list_runnable_tests__arr__arr__char__arr__char__lambda1___closure value) {
	list_runnable_tests__arr__arr__char__arr__char__lambda1___closure* res = (list_runnable_tests__arr__arr__char__arr__char__lambda1___closure*) out; 
	*res = value;
	return res;
}
list_runnable_tests__arr__arr__char__arr__char__lambda1___closure _faillist_runnable_tests__arr__arr__char__arr__char__lambda1___closure() {
	assert(0);
}


run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0___closure* _initrun_runnable_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0___closure(byte* out, run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0___closure value) {
	run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0___closure* res = (run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0___closure*) out; 
	*res = value;
	return res;
}
run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0___closure _failrun_runnable_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0___closure() {
	assert(0);
}


do_test__int32__test_options__lambda1___closure* _initdo_test__int32__test_options__lambda1___closure(byte* out, do_test__int32__test_options__lambda1___closure value) {
	do_test__int32__test_options__lambda1___closure* res = (do_test__int32__test_options__lambda1___closure*) out; 
	*res = value;
	return res;
}
do_test__int32__test_options__lambda1___closure _faildo_test__int32__test_options__lambda1___closure() {
	assert(0);
}


list_lintable_files__arr__arr__char__arr__char__lambda1___closure* _initlist_lintable_files__arr__arr__char__arr__char__lambda1___closure(byte* out, list_lintable_files__arr__arr__char__arr__char__lambda1___closure value) {
	list_lintable_files__arr__arr__char__arr__char__lambda1___closure* res = (list_lintable_files__arr__arr__char__arr__char__lambda1___closure*) out; 
	*res = value;
	return res;
}
list_lintable_files__arr__arr__char__arr__char__lambda1___closure _faillist_lintable_files__arr__arr__char__arr__char__lambda1___closure() {
	assert(0);
}


lint__result__arr__char__arr__ptr_failure__arr__char__test_options__lambda0___closure* _initlint__result__arr__char__arr__ptr_failure__arr__char__test_options__lambda0___closure(byte* out, lint__result__arr__char__arr__ptr_failure__arr__char__test_options__lambda0___closure value) {
	lint__result__arr__char__arr__ptr_failure__arr__char__test_options__lambda0___closure* res = (lint__result__arr__char__arr__ptr_failure__arr__char__test_options__lambda0___closure*) out; 
	*res = value;
	return res;
}
lint__result__arr__char__arr__ptr_failure__arr__char__test_options__lambda0___closure _faillint__result__arr__char__arr__ptr_failure__arr__char__test_options__lambda0___closure() {
	assert(0);
}


fun_mut2___void__arr__char__nat* _initfun_mut2___void__arr__char__nat(byte* out, fun_mut2___void__arr__char__nat value) {
	fun_mut2___void__arr__char__nat* res = (fun_mut2___void__arr__char__nat*) out; 
	*res = value;
	return res;
}
fun_mut2___void__arr__char__nat _failfun_mut2___void__arr__char__nat() {
	assert(0);
}


fun_ptr4___void__ptr_ctx__ptr__byte__arr__char__nat* _initfun_ptr4___void__ptr_ctx__ptr__byte__arr__char__nat(byte* out, fun_ptr4___void__ptr_ctx__ptr__byte__arr__char__nat value) {
	fun_ptr4___void__ptr_ctx__ptr__byte__arr__char__nat* res = (fun_ptr4___void__ptr_ctx__ptr__byte__arr__char__nat*) out; 
	*res = value;
	return res;
}
fun_ptr4___void__ptr_ctx__ptr__byte__arr__char__nat _failfun_ptr4___void__ptr_ctx__ptr__byte__arr__char__nat() {
	assert(0);
}


fun_mut2___void__char__nat* _initfun_mut2___void__char__nat(byte* out, fun_mut2___void__char__nat value) {
	fun_mut2___void__char__nat* res = (fun_mut2___void__char__nat*) out; 
	*res = value;
	return res;
}
fun_mut2___void__char__nat _failfun_mut2___void__char__nat() {
	assert(0);
}


fun_ptr4___void__ptr_ctx__ptr__byte__char__nat* _initfun_ptr4___void__ptr_ctx__ptr__byte__char__nat(byte* out, fun_ptr4___void__ptr_ctx__ptr__byte__char__nat value) {
	fun_ptr4___void__ptr_ctx__ptr__byte__char__nat* res = (fun_ptr4___void__ptr_ctx__ptr__byte__char__nat*) out; 
	*res = value;
	return res;
}
fun_ptr4___void__ptr_ctx__ptr__byte__char__nat _failfun_ptr4___void__ptr_ctx__ptr__byte__char__nat() {
	assert(0);
}


lines__arr__arr__char__arr__char__lambda0___closure* _initlines__arr__arr__char__arr__char__lambda0___closure(byte* out, lines__arr__arr__char__arr__char__lambda0___closure value) {
	lines__arr__arr__char__arr__char__lambda0___closure* res = (lines__arr__arr__char__arr__char__lambda0___closure*) out; 
	*res = value;
	return res;
}
lines__arr__arr__char__arr__char__lambda0___closure _faillines__arr__arr__char__arr__char__lambda0___closure() {
	assert(0);
}


lint_file__arr__ptr_failure__arr__char__lambda0___closure* _initlint_file__arr__ptr_failure__arr__char__lambda0___closure(byte* out, lint_file__arr__ptr_failure__arr__char__lambda0___closure value) {
	lint_file__arr__ptr_failure__arr__char__lambda0___closure* res = (lint_file__arr__ptr_failure__arr__char__lambda0___closure*) out; 
	*res = value;
	return res;
}
lint_file__arr__ptr_failure__arr__char__lambda0___closure _faillint_file__arr__ptr_failure__arr__char__lambda0___closure() {
	assert(0);
}

void* _failVoidPtr() { assert(0); }
int32 rt_main__int32__int32__ptr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char(int32 argc, ptr__ptr__char argv, fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char main_ptr);
nat as__nat__nat(nat value);
nat two__nat();
nat wrap_incr__nat__nat(nat a);
nat wrap_add__nat__nat__nat(nat a, nat b);
nat one__nat();
lock new_lock__lock();
_atomic_bool new_atomic_bool___atomic_bool();
bool false__bool();
arr__ptr_vat empty_arr__arr__ptr_vat();
nat zero__nat();
ptr__ptr_vat null__ptr__ptr_vat();
condition new_condition__condition();
global_ctx* ref_of_val__ptr_global_ctx__global_ctx(global_ctx b);
vat new_vat__vat__ptr_global_ctx__nat__nat(global_ctx* gctx, nat id, nat max_threads);
mut_arr__nat new_mut_arr_by_val_with_capacity_from_unmanaged_memory__mut_arr__nat__nat(nat capacity);
ptr__nat unmanaged_alloc_elements__ptr__nat__nat(nat size_elements);
ptr__byte unmanaged_alloc_bytes__ptr__byte__nat(nat size);
extern ptr__byte malloc(nat size);
_void hard_forbid___void__bool(bool condition);
_void hard_assert___void__bool(bool condition);
_void if___void__bool___void___void(bool cond, _void if_true, _void if_false);
_void pass___void();
_void hard_fail___void__arr__char(arr__char reason);
bool not__bool__bool(bool a);
bool null__q__bool__ptr__byte(ptr__byte a);
bool _op_equal_equal__bool__ptr__byte__ptr__byte(ptr__byte a, ptr__byte b);
comparison _op_less_equal_greater__comparison__ptr__byte__ptr__byte(ptr__byte a, ptr__byte b);
bool true__bool();
ptr__byte null__ptr__byte();
nat wrap_mul__nat__nat__nat(nat a, nat b);
nat size_of__nat();
ptr__nat ptr_cast__ptr__nat__ptr__byte(ptr__byte p);
gc new_gc__gc();
none none__none();
mut_bag__task new_mut_bag__mut_bag__task();
thread_safe_counter new_thread_safe_counter__thread_safe_counter();
thread_safe_counter new_thread_safe_counter__thread_safe_counter__nat(nat init);
ptr__bool null__ptr__bool();
_void default_exception_handler___void__exception(ctx* _ctx, exception e);
_void print_err_sync_no_newline___void__arr__char(arr__char s);
_void write_sync_no_newline___void__int32__arr__char(int32 fd, arr__char s);
bool _op_equal_equal__bool__nat__nat(nat a, nat b);
comparison _op_less_equal_greater__comparison__nat__nat(nat a, nat b);
nat size_of__nat();
nat size_of__nat();
extern _int write(int32 fd, ptr__byte buff, nat n_bytes);
ptr__byte as_any_ptr__ptr__byte__ptr__char(ptr__char some_ref);
bool _op_equal_equal__bool___int___int(_int a, _int b);
comparison _op_less_equal_greater__comparison___int___int(_int a, _int b);
_int unsafe_to_int___int__nat(nat a);
_void todo___void();
int32 stderr_fd__int32();
int32 two__int32();
int32 wrap_incr__int32__int32(int32 a);
int32 wrap_add__int32__int32__int32(int32 a, int32 b);
int32 one__int32();
_void print_err_sync___void__arr__char(arr__char s);
arr__char if__arr__char__bool__arr__char__arr__char(bool cond, arr__char if_true, arr__char if_false);
bool empty__q__bool__arr__char(arr__char a);
bool zero__q__bool__nat(nat n);
global_ctx* get_gctx__ptr_global_ctx(ctx* _ctx);
global_ctx* as_ref__ptr_global_ctx__ptr__byte(ptr__byte p);
ctx* get_ctx__ptr_ctx(ctx* _ctx);
_void new_vat__vat__ptr_global_ctx__nat__nat__lambda0(ctx* _ctx, ptr__byte _closure, exception it);
vat* ref_of_val__ptr_vat__vat(vat b);
ptr__ptr_vat ptr_to__ptr__ptr_vat__ptr_vat(vat* t);
exception_ctx new_exception_ctx__exception_ctx();
ptr__jmp_buf_tag null__ptr__jmp_buf_tag();
exception_ctx* ref_of_val__ptr_exception_ctx__exception_ctx(exception_ctx b);
ctx new_ctx__ctx__ptr_global_ctx__ptr_thread_local_stuff__ptr_vat__nat(global_ctx* gctx, thread_local_stuff* tls, vat* vat, nat actor_id);
ptr__byte as_any_ptr__ptr__byte__ptr_global_ctx(global_ctx* some_ref);
ptr__byte as_any_ptr__ptr__byte__ptr_gc_ctx(gc_ctx* some_ref);
gc_ctx* get_gc_ctx__ptr_gc_ctx__ptr_gc(gc* gc);
_void acquire_lock___void__ptr_lock(lock* l);
_void acquire_lock_recur___void__ptr_lock__nat(lock* l, nat n_tries);
bool try_acquire_lock__bool__ptr_lock(lock* l);
bool try_set__bool__ptr__atomic_bool(_atomic_bool* a);
bool try_change__bool__ptr__atomic_bool__bool(_atomic_bool* a, bool old_value);
bool compare_exchange_strong__bool__ptr__bool__ptr__bool__bool(ptr__bool value_ptr, ptr__bool expected_ptr, bool desired);
ptr__bool ptr_to__ptr__bool__bool(bool t);
_atomic_bool* ref_of_val__ptr__atomic_bool___atomic_bool(_atomic_bool b);
nat thousand__nat();
nat hundred__nat();
nat ten__nat();
nat nine__nat();
nat eight__nat();
nat seven__nat();
nat six__nat();
nat five__nat();
nat four__nat();
nat three__nat();
_void yield_thread___void();
extern int32 pthread_yield();
extern void usleep(nat micro_seconds);
bool zero__q__bool__int32(int32 i);
bool _op_equal_equal__bool__int32__int32(int32 a, int32 b);
comparison _op_less_equal_greater__comparison__int32__int32(int32 a, int32 b);
int32 zero__int32();
nat noctx_incr__nat__nat(nat n);
bool _op_less__bool__nat__nat(nat a, nat b);
nat billion__nat();
nat million__nat();
lock* ref_of_val__ptr_lock__lock(lock b);
gc_ctx* as_ref__ptr_gc_ctx__ptr__byte(ptr__byte p);
nat size_of__nat();
_void release_lock___void__ptr_lock(lock* l);
_void must_unset___void__ptr__atomic_bool(_atomic_bool* a);
bool try_unset__bool__ptr__atomic_bool(_atomic_bool* a);
gc* ref_of_val__ptr_gc__gc(gc b);
ptr__byte as_any_ptr__ptr__byte__ptr_exception_ctx(exception_ctx* some_ref);
thread_local_stuff* ref_of_val__ptr_thread_local_stuff__thread_local_stuff(thread_local_stuff b);
ctx* ref_of_val__ptr_ctx__ctx(ctx b);
fun2__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char as__fun2__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__fun2__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char(fun2__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char value);
fut__int32* add_first_task__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char(ctx* _ctx, arr__ptr__char all_args, fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char main_ptr);
fut__int32* then2__ptr_fut__int32__ptr_fut___void__fun_ref0__int32(ctx* _ctx, fut___void* f, fun_ref0__int32 cb);
fut__int32* then__ptr_fut__int32__ptr_fut___void__fun_ref1__int32___void(ctx* _ctx, fut___void* f, fun_ref1__int32___void cb);
fut__int32* new_unresolved_fut__ptr_fut__int32(ctx* _ctx);
ptr__byte alloc__ptr__byte__nat(ctx* _ctx, nat size);
ptr__byte gc_alloc__ptr__byte__ptr_gc__nat(ctx* _ctx, gc* gc, nat size);
opt__ptr__byte try_gc_alloc__opt__ptr__byte__ptr_gc__nat(gc* gc, nat size);
some__ptr__byte some__some__ptr__byte__ptr__byte(ptr__byte t);
ptr__byte todo__ptr__byte();
ptr__byte hard_fail__ptr__byte__arr__char(arr__char reason);
gc* get_gc__ptr_gc(ctx* _ctx);
gc_ctx* get_gc_ctx__ptr_gc_ctx(ctx* _ctx);
_void then_void___void__ptr_fut___void__fun_mut1___void__result___void__exception(ctx* _ctx, fut___void* f, fun_mut1___void__result___void__exception cb);
some__ptr_fut_callback_node___void some__some__ptr_fut_callback_node___void__ptr_fut_callback_node___void(fut_callback_node___void* t);
_void call___void__fun_mut1___void__result___void__exception__result___void__exception(ctx* _ctx, fun_mut1___void__result___void__exception f, result___void__exception p0);
_void call_with_ctx___void__ptr_ctx__fun_mut1___void__result___void__exception__result___void__exception(ctx* c, fun_mut1___void__result___void__exception f, result___void__exception p0);
_void call___void__fun_ptr3___void__ptr_ctx__ptr__byte__result___void__exception__ptr_ctx__ptr__byte__result___void__exception(fun_ptr3___void__ptr_ctx__ptr__byte__result___void__exception f, ctx* p0, ptr__byte p1, result___void__exception p2);
ok___void ok__ok___void___void(_void t);
err__exception err__err__exception__exception(exception t);
_void forward_to___void__ptr_fut__int32__ptr_fut__int32(ctx* _ctx, fut__int32* from, fut__int32* to);
_void then_void___void__ptr_fut__int32__fun_mut1___void__result__int32__exception(ctx* _ctx, fut__int32* f, fun_mut1___void__result__int32__exception cb);
some__ptr_fut_callback_node__int32 some__some__ptr_fut_callback_node__int32__ptr_fut_callback_node__int32(fut_callback_node__int32* t);
_void call___void__fun_mut1___void__result__int32__exception__result__int32__exception(ctx* _ctx, fun_mut1___void__result__int32__exception f, result__int32__exception p0);
_void call_with_ctx___void__ptr_ctx__fun_mut1___void__result__int32__exception__result__int32__exception(ctx* c, fun_mut1___void__result__int32__exception f, result__int32__exception p0);
_void call___void__fun_ptr3___void__ptr_ctx__ptr__byte__result__int32__exception__ptr_ctx__ptr__byte__result__int32__exception(fun_ptr3___void__ptr_ctx__ptr__byte__result__int32__exception f, ctx* p0, ptr__byte p1, result__int32__exception p2);
ok__int32 ok__ok__int32__int32(int32 t);
_void resolve_or_reject___void__ptr_fut__int32__result__int32__exception(ctx* _ctx, fut__int32* f, result__int32__exception result);
_void resolve_or_reject_recur___void__opt__ptr_fut_callback_node__int32__result__int32__exception(ctx* _ctx, opt__ptr_fut_callback_node__int32 node, result__int32__exception value);
_void drop___void___void(_void t);
_void forward_to___void__ptr_fut__int32__ptr_fut__int32__lambda0(ctx* _ctx, forward_to___void__ptr_fut__int32__ptr_fut__int32__lambda0___closure* _closure, result__int32__exception it);
fut__int32* call__ptr_fut__int32__fun_ref1__int32___void___void(ctx* _ctx, fun_ref1__int32___void f, _void p0);
vat* get_vat__ptr_vat__nat(ctx* _ctx, nat vat_id);
vat* at__ptr_vat__arr__ptr_vat__nat(ctx* _ctx, arr__ptr_vat a, nat index);
_void assert___void__bool(ctx* _ctx, bool condition);
_void assert___void__bool__arr__char(ctx* _ctx, bool condition, arr__char message);
_void fail___void__arr__char(ctx* _ctx, arr__char reason);
_void throw___void__exception(ctx* _ctx, exception e);
exception_ctx* get_exception_ctx__ptr_exception_ctx(ctx* _ctx);
exception_ctx* as_ref__ptr_exception_ctx__ptr__byte(ptr__byte p);
bool _op_equal_equal__bool__ptr__jmp_buf_tag__ptr__jmp_buf_tag(ptr__jmp_buf_tag a, ptr__jmp_buf_tag b);
comparison _op_less_equal_greater__comparison__ptr__jmp_buf_tag__ptr__jmp_buf_tag(ptr__jmp_buf_tag a, ptr__jmp_buf_tag b);
extern void longjmp(ptr__jmp_buf_tag env, int32 val);
int32 number_to_throw__int32(ctx* _ctx);
int32 seven__int32();
int32 six__int32();
int32 five__int32();
int32 four__int32();
int32 three__int32();
vat* noctx_at__ptr_vat__arr__ptr_vat__nat(arr__ptr_vat a, nat index);
vat* deref__ptr_vat__ptr__ptr_vat(ptr__ptr_vat p);
ptr__ptr_vat _op_plus__ptr__ptr_vat__ptr__ptr_vat__nat(ptr__ptr_vat p, nat offset);
_void add_task___void__ptr_vat__task(ctx* _ctx, vat* v, task t);
mut_bag_node__task* new_mut_bag_node__ptr_mut_bag_node__task__task(ctx* _ctx, task value);
_void add___void__ptr_mut_bag__task__ptr_mut_bag_node__task(mut_bag__task* bag, mut_bag_node__task* node);
some__ptr_mut_bag_node__task some__some__ptr_mut_bag_node__task__ptr_mut_bag_node__task(mut_bag_node__task* t);
mut_bag__task* ref_of_val__ptr_mut_bag__task__mut_bag__task(mut_bag__task b);
_void broadcast___void__ptr_condition(condition* c);
condition* ref_of_val__ptr_condition__condition(condition b);
_void catch___void__fun_mut0___void__fun_mut1___void__exception(ctx* _ctx, fun_mut0___void try, fun_mut1___void__exception catcher);
_void catch_with_exception_ctx___void__ptr_exception_ctx__fun_mut0___void__fun_mut1___void__exception(ctx* _ctx, exception_ctx* ec, fun_mut0___void try, fun_mut1___void__exception catcher);
bytes64 zero__bytes64();
bytes32 zero__bytes32();
bytes16 zero__bytes16();
bytes128 zero__bytes128();
ptr__jmp_buf_tag ptr_to__ptr__jmp_buf_tag__jmp_buf_tag(jmp_buf_tag t);
extern int32 setjmp(ptr__jmp_buf_tag env);
_void call___void__fun_mut0___void(ctx* _ctx, fun_mut0___void f);
_void call_with_ctx___void__ptr_ctx__fun_mut0___void(ctx* c, fun_mut0___void f);
_void call___void__fun_ptr2___void__ptr_ctx__ptr__byte__ptr_ctx__ptr__byte(fun_ptr2___void__ptr_ctx__ptr__byte f, ctx* p0, ptr__byte p1);
_void call___void__fun_mut1___void__exception__exception(ctx* _ctx, fun_mut1___void__exception f, exception p0);
_void call_with_ctx___void__ptr_ctx__fun_mut1___void__exception__exception(ctx* c, fun_mut1___void__exception f, exception p0);
_void call___void__fun_ptr3___void__ptr_ctx__ptr__byte__exception__ptr_ctx__ptr__byte__exception(fun_ptr3___void__ptr_ctx__ptr__byte__exception f, ctx* p0, ptr__byte p1, exception p2);
fut__int32* call__ptr_fut__int32__fun_mut1__ptr_fut__int32___void___void(ctx* _ctx, fun_mut1__ptr_fut__int32___void f, _void p0);
fut__int32* call_with_ctx__ptr_fut__int32__ptr_ctx__fun_mut1__ptr_fut__int32___void___void(ctx* c, fun_mut1__ptr_fut__int32___void f, _void p0);
fut__int32* call__ptr_fut__int32__fun_ptr3__ptr_fut__int32__ptr_ctx__ptr__byte___void__ptr_ctx__ptr__byte___void(fun_ptr3__ptr_fut__int32__ptr_ctx__ptr__byte___void f, ctx* p0, ptr__byte p1, _void p2);
_void call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0__lambda0(ctx* _ctx, call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0__lambda0___closure* _closure);
_void reject___void__ptr_fut__int32__exception(ctx* _ctx, fut__int32* f, exception e);
_void call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0__lambda1(ctx* _ctx, call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0__lambda1___closure* _closure, exception it);
_void call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0(ctx* _ctx, call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0___closure* _closure);
_void then__ptr_fut__int32__ptr_fut___void__fun_ref1__int32___void__lambda0(ctx* _ctx, then__ptr_fut__int32__ptr_fut___void__fun_ref1__int32___void__lambda0___closure* _closure, result___void__exception result);
fut__int32* call__ptr_fut__int32__fun_ref0__int32(ctx* _ctx, fun_ref0__int32 f);
fut__int32* call__ptr_fut__int32__fun_mut0__ptr_fut__int32(ctx* _ctx, fun_mut0__ptr_fut__int32 f);
fut__int32* call_with_ctx__ptr_fut__int32__ptr_ctx__fun_mut0__ptr_fut__int32(ctx* c, fun_mut0__ptr_fut__int32 f);
fut__int32* call__ptr_fut__int32__fun_ptr2__ptr_fut__int32__ptr_ctx__ptr__byte__ptr_ctx__ptr__byte(fun_ptr2__ptr_fut__int32__ptr_ctx__ptr__byte f, ctx* p0, ptr__byte p1);
_void call__ptr_fut__int32__fun_ref0__int32__lambda0__lambda0(ctx* _ctx, call__ptr_fut__int32__fun_ref0__int32__lambda0__lambda0___closure* _closure);
_void call__ptr_fut__int32__fun_ref0__int32__lambda0__lambda1(ctx* _ctx, call__ptr_fut__int32__fun_ref0__int32__lambda0__lambda1___closure* _closure, exception it);
_void call__ptr_fut__int32__fun_ref0__int32__lambda0(ctx* _ctx, call__ptr_fut__int32__fun_ref0__int32__lambda0___closure* _closure);
fut__int32* then2__ptr_fut__int32__ptr_fut___void__fun_ref0__int32__lambda0(ctx* _ctx, then2__ptr_fut__int32__ptr_fut___void__fun_ref0__int32__lambda0___closure* _closure, _void ignore);
vat_and_actor_id cur_actor__vat_and_actor_id(ctx* _ctx);
fut___void* as__ptr_fut___void__ptr_fut___void(fut___void* value);
fut___void* resolved__ptr_fut___void___void(ctx* _ctx, _void value);
arr__ptr__char tail__arr__ptr__char__arr__ptr__char(ctx* _ctx, arr__ptr__char a);
_void forbid___void__bool(ctx* _ctx, bool condition);
_void forbid___void__bool__arr__char(ctx* _ctx, bool condition, arr__char message);
bool empty__q__bool__arr__ptr__char(arr__ptr__char a);
arr__ptr__char slice_starting_at__arr__ptr__char__arr__ptr__char__nat(ctx* _ctx, arr__ptr__char a, nat begin);
bool _op_less_equal__bool__nat__nat(nat a, nat b);
arr__ptr__char slice__arr__ptr__char__arr__ptr__char__nat__nat(ctx* _ctx, arr__ptr__char a, nat begin, nat size);
nat _op_plus__nat__nat__nat(ctx* _ctx, nat a, nat b);
bool and__bool__bool__bool(bool a, bool b);
bool _op_greater_equal__bool__nat__nat(nat a, nat b);
ptr__ptr__char _op_plus__ptr__ptr__char__ptr__ptr__char__nat(ptr__ptr__char p, nat offset);
nat _op_minus__nat__nat__nat(ctx* _ctx, nat a, nat b);
nat wrap_sub__nat__nat__nat(nat a, nat b);
fut__int32* call__ptr_fut__int32__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__ptr_ctx__arr__arr__char(fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char f, ctx* p0, arr__arr__char p1);
arr__arr__char map__arr__arr__char__arr__ptr__char__fun_mut1__arr__char__ptr__char(ctx* _ctx, arr__ptr__char a, fun_mut1__arr__char__ptr__char mapper);
arr__arr__char make_arr__arr__arr__char__nat__fun_mut1__arr__char__nat(ctx* _ctx, nat size, fun_mut1__arr__char__nat f);
arr__arr__char freeze__arr__arr__char__ptr_mut_arr__arr__char(mut_arr__arr__char* a);
arr__arr__char unsafe_as_arr__arr__arr__char__ptr_mut_arr__arr__char(mut_arr__arr__char* a);
mut_arr__arr__char* make_mut_arr__ptr_mut_arr__arr__char__nat__fun_mut1__arr__char__nat(ctx* _ctx, nat size, fun_mut1__arr__char__nat f);
mut_arr__arr__char* new_uninitialized_mut_arr__ptr_mut_arr__arr__char__nat(ctx* _ctx, nat size);
ptr__arr__char uninitialized_data__ptr__arr__char__nat(ctx* _ctx, nat size);
nat size_of__nat();
ptr__arr__char ptr_cast__ptr__arr__char__ptr__byte(ptr__byte p);
_void make_mut_arr_worker___void__ptr_mut_arr__arr__char__nat__nat__fun_mut1__arr__char__nat(ctx* _ctx, mut_arr__arr__char* m, nat lo, nat hi, fun_mut1__arr__char__nat f);
_void set_at___void__ptr_mut_arr__arr__char__nat__arr__char(ctx* _ctx, mut_arr__arr__char* a, nat index, arr__char value);
_void noctx_set_at___void__ptr_mut_arr__arr__char__nat__arr__char(mut_arr__arr__char* a, nat index, arr__char value);
_void set___void__ptr__arr__char__arr__char(ptr__arr__char p, arr__char value);
ptr__arr__char _op_plus__ptr__arr__char__ptr__arr__char__nat(ptr__arr__char p, nat offset);
arr__char call__arr__char__fun_mut1__arr__char__nat__nat(ctx* _ctx, fun_mut1__arr__char__nat f, nat p0);
arr__char call_with_ctx__arr__char__ptr_ctx__fun_mut1__arr__char__nat__nat(ctx* c, fun_mut1__arr__char__nat f, nat p0);
arr__char call__arr__char__fun_ptr3__arr__char__ptr_ctx__ptr__byte__nat__ptr_ctx__ptr__byte__nat(fun_ptr3__arr__char__ptr_ctx__ptr__byte__nat f, ctx* p0, ptr__byte p1, nat p2);
nat _op_div__nat__nat__nat(ctx* _ctx, nat a, nat b);
nat unsafe_div__nat__nat__nat(nat a, nat b);
nat incr__nat__nat(ctx* _ctx, nat n);
arr__char call__arr__char__fun_mut1__arr__char__ptr__char__ptr__char(ctx* _ctx, fun_mut1__arr__char__ptr__char f, ptr__char p0);
arr__char call_with_ctx__arr__char__ptr_ctx__fun_mut1__arr__char__ptr__char__ptr__char(ctx* c, fun_mut1__arr__char__ptr__char f, ptr__char p0);
arr__char call__arr__char__fun_ptr3__arr__char__ptr_ctx__ptr__byte__ptr__char__ptr_ctx__ptr__byte__ptr__char(fun_ptr3__arr__char__ptr_ctx__ptr__byte__ptr__char f, ctx* p0, ptr__byte p1, ptr__char p2);
ptr__char at__ptr__char__arr__ptr__char__nat(ctx* _ctx, arr__ptr__char a, nat index);
ptr__char noctx_at__ptr__char__arr__ptr__char__nat(arr__ptr__char a, nat index);
ptr__char deref__ptr__char__ptr__ptr__char(ptr__ptr__char p);
arr__char map__arr__arr__char__arr__ptr__char__fun_mut1__arr__char__ptr__char__lambda0(ctx* _ctx, map__arr__arr__char__arr__ptr__char__fun_mut1__arr__char__ptr__char__lambda0___closure* _closure, nat i);
arr__char to_str__arr__char__ptr__char(ptr__char a);
arr__char arr_from_begin_end__arr__char__ptr__char__ptr__char(ptr__char begin, ptr__char end);
nat _op_minus__nat__ptr__char__ptr__char(ptr__char a, ptr__char b);
nat to_nat__nat__ptr__char(ptr__char p);
ptr__char _op_minus__ptr__char__ptr__char__nat(ptr__char p, nat offset);
ptr__char find_cstr_end__ptr__char__ptr__char(ptr__char a);
ptr__char find_char_in_cstr__ptr__char__ptr__char__char(ptr__char a, char c);
bool _op_equal_equal__bool__char__char(char a, char b);
comparison _op_less_equal_greater__comparison__char__char(char a, char b);
char deref__char__ptr__char(ptr__char p);
char literal__char__arr__char(arr__char a);
char noctx_at__char__arr__char__nat(arr__char a, nat index);
ptr__char _op_plus__ptr__char__ptr__char__nat(ptr__char p, nat offset);
ptr__char todo__ptr__char();
ptr__char hard_fail__ptr__char__arr__char(arr__char reason);
ptr__char incr__ptr__char__ptr__char(ptr__char p);
arr__char add_first_task__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__lambda0__lambda0(ctx* _ctx, ptr__byte _closure, ptr__char it);
fut__int32* add_first_task__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__lambda0(ctx* _ctx, add_first_task__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__lambda0___closure* _closure);
fut__int32* rt_main__int32__int32__ptr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__lambda0(ctx* _ctx, ptr__byte _closure, arr__ptr__char all_args, fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char main_ptr);
nat unsafe_to_nat__nat___int(_int a);
_int to_int___int__int32(int32 i);
fut__int32* call_with_ctx__ptr_fut__int32__ptr_ctx__fun2__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char(ctx* c, fun2__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char f, arr__ptr__char p0, fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char p1);
fut__int32* call__ptr_fut__int32__fun_ptr4__ptr_fut__int32__ptr_ctx__ptr__byte__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__ptr_ctx__ptr__byte__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char(fun_ptr4__ptr_fut__int32__ptr_ctx__ptr__byte__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char f, ctx* p0, ptr__byte p1, arr__ptr__char p2, fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char p3);
_void run_threads___void__nat__ptr_global_ctx__fun_ptr2___void__nat__ptr_global_ctx(nat n_threads, global_ctx* arg, fun_ptr2___void__nat__ptr_global_ctx fun);
ptr__thread_args__ptr_global_ctx unmanaged_alloc_elements__ptr__thread_args__ptr_global_ctx__nat(nat size_elements);
nat size_of__nat();
ptr__thread_args__ptr_global_ctx ptr_cast__ptr__thread_args__ptr_global_ctx__ptr__byte(ptr__byte p);
_void run_threads_recur___void__nat__nat__ptr__nat__ptr__thread_args__ptr_global_ctx__ptr_global_ctx__fun_ptr2___void__nat__ptr_global_ctx(nat i, nat n_threads, ptr__nat threads, ptr__thread_args__ptr_global_ctx thread_args, global_ctx* arg, fun_ptr2___void__nat__ptr_global_ctx fun);
ptr__thread_args__ptr_global_ctx _op_plus__ptr__thread_args__ptr_global_ctx__ptr__thread_args__ptr_global_ctx__nat(ptr__thread_args__ptr_global_ctx p, nat offset);
_void set___void__ptr__thread_args__ptr_global_ctx__thread_args__ptr_global_ctx(ptr__thread_args__ptr_global_ctx p, thread_args__ptr_global_ctx value);
ptr__nat _op_plus__ptr__nat__ptr__nat__nat(ptr__nat p, nat offset);
fun_ptr1__ptr__byte__ptr__byte as__fun_ptr1__ptr__byte__ptr__byte__fun_ptr1__ptr__byte__ptr__byte(fun_ptr1__ptr__byte__ptr__byte value);
ptr__byte thread_fun__ptr__byte__ptr__byte(ptr__byte args_ptr);
thread_args__ptr_global_ctx* as_ref__ptr_thread_args__ptr_global_ctx__ptr__byte(ptr__byte p);
_void call___void__fun_ptr2___void__nat__ptr_global_ctx__nat__ptr_global_ctx(fun_ptr2___void__nat__ptr_global_ctx f, nat p0, global_ctx* p1);
ptr__byte run_threads_recur___void__nat__nat__ptr__nat__ptr__thread_args__ptr_global_ctx__ptr_global_ctx__fun_ptr2___void__nat__ptr_global_ctx__lambda0(ptr__byte args_ptr);
extern int32 pthread_create(cell__nat* thread, ptr__byte attr, fun_ptr1__ptr__byte__ptr__byte start_routine, ptr__byte arg);
cell__nat* as_cell__ptr_cell__nat__ptr__nat(ptr__nat p);
cell__nat* as_ref__ptr_cell__nat__ptr__byte(ptr__byte p);
ptr__byte as_any_ptr__ptr__byte__ptr__nat(ptr__nat some_ref);
ptr__byte as_any_ptr__ptr__byte__ptr__thread_args__ptr_global_ctx(ptr__thread_args__ptr_global_ctx some_ref);
int32 eagain__int32();
int32 ten__int32();
int32 nine__int32();
int32 eight__int32();
_void join_threads_recur___void__nat__nat__ptr__nat(nat i, nat n_threads, ptr__nat threads);
_void join_one_thread___void__nat(nat tid);
extern int32 pthread_join(nat thread, cell__ptr__byte* thread_return);
cell__ptr__byte* ref_of_val__ptr_cell__ptr__byte__cell__ptr__byte(cell__ptr__byte b);
int32 einval__int32();
int32 esrch__int32();
ptr__byte get__ptr__byte__ptr_cell__ptr__byte(cell__ptr__byte* c);
nat deref__nat__ptr__nat(ptr__nat p);
_void unmanaged_free___void__ptr__nat(ptr__nat p);
extern void free(ptr__byte p);
ptr__byte ptr_cast__ptr__byte__ptr__nat(ptr__nat p);
_void unmanaged_free___void__ptr__thread_args__ptr_global_ctx(ptr__thread_args__ptr_global_ctx p);
ptr__byte ptr_cast__ptr__byte__ptr__thread_args__ptr_global_ctx(ptr__thread_args__ptr_global_ctx p);
_void thread_function___void__nat__ptr_global_ctx(nat thread_id, global_ctx* gctx);
thread_local_stuff as__thread_local_stuff__thread_local_stuff(thread_local_stuff value);
_void thread_function_recur___void__nat__ptr_global_ctx__ptr_thread_local_stuff(nat thread_id, global_ctx* gctx, thread_local_stuff* tls);
nat noctx_decr__nat__nat(nat n);
_void assert_vats_are_shut_down___void__nat__arr__ptr_vat(nat i, arr__ptr_vat vats);
bool empty__q__bool__ptr_mut_bag__task(mut_bag__task* m);
bool empty__q__bool__opt__ptr_mut_bag_node__task(opt__ptr_mut_bag_node__task a);
bool _op_greater__bool__nat__nat(nat a, nat b);
nat get_last_checked__nat__ptr_condition(condition* c);
result__chosen_task__no_chosen_task choose_task__result__chosen_task__no_chosen_task__ptr_global_ctx(global_ctx* gctx);
result__chosen_task__no_chosen_task as__result__chosen_task__no_chosen_task__result__chosen_task__no_chosen_task(result__chosen_task__no_chosen_task value);
opt__chosen_task choose_task_recur__opt__chosen_task__arr__ptr_vat__nat(arr__ptr_vat vats, nat i);
opt__opt__task choose_task_in_vat__opt__opt__task__ptr_vat(vat* vat);
opt__opt__task as__opt__opt__task__opt__opt__task(opt__opt__task value);
some__opt__task some__some__opt__task__opt__task(opt__task t);
opt__task find_and_remove_first_doable_task__opt__task__ptr_vat(vat* vat);
opt__task_and_nodes find_and_remove_first_doable_task_recur__opt__task_and_nodes__ptr_vat__opt__ptr_mut_bag_node__task(vat* vat, opt__ptr_mut_bag_node__task opt_node);
mut_arr__nat* ref_of_val__ptr_mut_arr__nat__mut_arr__nat(mut_arr__nat b);
bool contains__q__bool__ptr_mut_arr__nat__nat(mut_arr__nat* a, nat value);
bool contains_recur__q__bool__arr__nat__nat__nat(arr__nat a, nat value, nat i);
bool or__bool__bool__bool(bool a, bool b);
nat noctx_at__nat__arr__nat__nat(arr__nat a, nat index);
arr__nat temp_as_arr__arr__nat__ptr_mut_arr__nat(mut_arr__nat* a);
_void push_capacity_must_be_sufficient___void__ptr_mut_arr__nat__nat(mut_arr__nat* a, nat value);
_void noctx_set_at___void__ptr_mut_arr__nat__nat__nat(mut_arr__nat* a, nat index, nat value);
_void set___void__ptr__nat__nat(ptr__nat p, nat value);
some__task_and_nodes some__some__task_and_nodes__task_and_nodes(task_and_nodes t);
task_and_nodes as__task_and_nodes__task_and_nodes(task_and_nodes value);
some__task some__some__task__task(task t);
bool empty__q__bool__opt__opt__task(opt__opt__task a);
some__chosen_task some__some__chosen_task__chosen_task(chosen_task t);
err__no_chosen_task err__err__no_chosen_task__no_chosen_task(no_chosen_task t);
ok__chosen_task ok__ok__chosen_task__chosen_task(chosen_task t);
_void do_task___void__ptr_global_ctx__ptr_thread_local_stuff__chosen_task(global_ctx* gctx, thread_local_stuff* tls, chosen_task chosen_task);
_void noctx_must_remove_unordered___void__ptr_mut_arr__nat__nat(mut_arr__nat* a, nat value);
_void noctx_must_remove_unordered_recur___void__ptr_mut_arr__nat__nat__nat(mut_arr__nat* a, nat index, nat value);
nat noctx_at__nat__ptr_mut_arr__nat__nat(mut_arr__nat* a, nat index);
_void drop___void__nat(nat t);
nat noctx_remove_unordered_at_index__nat__ptr_mut_arr__nat__nat(mut_arr__nat* a, nat index);
nat noctx_last__nat__ptr_mut_arr__nat(mut_arr__nat* a);
bool empty__q__bool__ptr_mut_arr__nat(mut_arr__nat* a);
_void return_ctx___void__ptr_ctx(ctx* c);
_void return_gc_ctx___void__ptr_gc_ctx(gc_ctx* gc_ctx);
some__ptr_gc_ctx some__some__ptr_gc_ctx__ptr_gc_ctx(gc_ctx* t);
_void wait_on___void__ptr_condition__nat(condition* c, nat last_checked);
_void rt_main__int32__int32__ptr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__lambda1(nat thread_id, global_ctx* gctx);
result__int32__exception must_be_resolved__result__int32__exception__ptr_fut__int32(fut__int32* f);
result__int32__exception hard_unreachable__result__int32__exception();
result__int32__exception hard_fail__result__int32__exception__arr__char(arr__char reason);
fut__int32* main__ptr_fut__int32__arr__arr__char(ctx* _ctx, arr__arr__char args);
opt__test_options parse_cmd_line_args__opt__test_options__arr__arr__char__arr__arr__char__fun1__test_options__arr__opt__arr__arr__char(ctx* _ctx, arr__arr__char args, arr__arr__char t_names, fun1__test_options__arr__opt__arr__arr__char make_t);
parsed_cmd_line_args* parse_cmd_line_args_dynamic__ptr_parsed_cmd_line_args__arr__arr__char(ctx* _ctx, arr__arr__char args);
opt__nat find_index__opt__nat__arr__arr__char__fun_mut1__bool__arr__char(ctx* _ctx, arr__arr__char a, fun_mut1__bool__arr__char pred);
opt__nat find_index_recur__opt__nat__arr__arr__char__nat__fun_mut1__bool__arr__char(ctx* _ctx, arr__arr__char a, nat index, fun_mut1__bool__arr__char pred);
bool call__bool__fun_mut1__bool__arr__char__arr__char(ctx* _ctx, fun_mut1__bool__arr__char f, arr__char p0);
bool call_with_ctx__bool__ptr_ctx__fun_mut1__bool__arr__char__arr__char(ctx* c, fun_mut1__bool__arr__char f, arr__char p0);
bool call__bool__fun_ptr3__bool__ptr_ctx__ptr__byte__arr__char__ptr_ctx__ptr__byte__arr__char(fun_ptr3__bool__ptr_ctx__ptr__byte__arr__char f, ctx* p0, ptr__byte p1, arr__char p2);
arr__char at__arr__char__arr__arr__char__nat(ctx* _ctx, arr__arr__char a, nat index);
arr__char noctx_at__arr__char__arr__arr__char__nat(arr__arr__char a, nat index);
arr__char deref__arr__char__ptr__arr__char(ptr__arr__char p);
some__nat some__some__nat__nat(nat t);
bool starts_with__q__bool__arr__char__arr__char(ctx* _ctx, arr__char a, arr__char start);
bool arr_eq__q__bool__arr__char__arr__char(ctx* _ctx, arr__char a, arr__char b);
char first__char__arr__char(ctx* _ctx, arr__char a);
char at__char__arr__char__nat(ctx* _ctx, arr__char a, nat index);
arr__char tail__arr__char__arr__char(ctx* _ctx, arr__char a);
arr__char slice_starting_at__arr__char__arr__char__nat(ctx* _ctx, arr__char a, nat begin);
arr__char slice__arr__char__arr__char__nat__nat(ctx* _ctx, arr__char a, nat begin, nat size);
bool parse_cmd_line_args_dynamic__ptr_parsed_cmd_line_args__arr__arr__char__lambda0(ctx* _ctx, ptr__byte _closure, arr__char it);
dict__arr__char__arr__arr__char* empty_dict__ptr_dict__arr__char__arr__arr__char(ctx* _ctx);
arr__arr__char empty_arr__arr__arr__char();
ptr__arr__char null__ptr__arr__char();
arr__arr__arr__char empty_arr__arr__arr__arr__char();
ptr__arr__arr__char null__ptr__arr__arr__char();
arr__arr__char slice_up_to__arr__arr__char__arr__arr__char__nat(ctx* _ctx, arr__arr__char a, nat size);
arr__arr__char slice__arr__arr__char__arr__arr__char__nat__nat(ctx* _ctx, arr__arr__char a, nat begin, nat size);
arr__arr__char slice_starting_at__arr__arr__char__arr__arr__char__nat(ctx* _ctx, arr__arr__char a, nat begin);
bool _op_equal_equal__bool__arr__char__arr__char(arr__char a, arr__char b);
comparison _op_less_equal_greater__comparison__arr__char__arr__char(arr__char a, arr__char b);
bool parse_cmd_line_args_dynamic__ptr_parsed_cmd_line_args__arr__arr__char__lambda1(ctx* _ctx, ptr__byte _closure, arr__char it);
dict__arr__char__arr__arr__char* parse_named_args__ptr_dict__arr__char__arr__arr__char__arr__arr__char(ctx* _ctx, arr__arr__char args);
mut_dict__arr__char__arr__arr__char new_mut_dict__mut_dict__arr__char__arr__arr__char(ctx* _ctx);
mut_arr__arr__char* new_mut_arr__ptr_mut_arr__arr__char(ctx* _ctx);
mut_arr__arr__arr__char* new_mut_arr__ptr_mut_arr__arr__arr__char(ctx* _ctx);
_void parse_named_args_recur___void__arr__arr__char__mut_dict__arr__char__arr__arr__char(ctx* _ctx, arr__arr__char args, mut_dict__arr__char__arr__arr__char builder);
arr__char remove_start__arr__char__arr__char__arr__char(ctx* _ctx, arr__char a, arr__char start);
arr__char force__arr__char__opt__arr__char(ctx* _ctx, opt__arr__char a);
arr__char fail__arr__char__arr__char(ctx* _ctx, arr__char reason);
arr__char throw__arr__char__exception(ctx* _ctx, exception e);
arr__char todo__arr__char();
arr__char hard_fail__arr__char__arr__char(arr__char reason);
opt__arr__char try_remove_start__opt__arr__char__arr__char__arr__char(ctx* _ctx, arr__char a, arr__char start);
some__arr__char some__some__arr__char__arr__char(arr__char t);
arr__char first__arr__char__arr__arr__char(ctx* _ctx, arr__arr__char a);
bool empty__q__bool__arr__arr__char(arr__arr__char a);
arr__arr__char tail__arr__arr__char__arr__arr__char(ctx* _ctx, arr__arr__char a);
bool parse_named_args_recur___void__arr__arr__char__mut_dict__arr__char__arr__arr__char__lambda0(ctx* _ctx, ptr__byte _closure, arr__char it);
_void add___void__mut_dict__arr__char__arr__arr__char__arr__char__arr__arr__char(ctx* _ctx, mut_dict__arr__char__arr__arr__char m, arr__char key, arr__arr__char value);
bool has__q__bool__mut_dict__arr__char__arr__arr__char__arr__char(ctx* _ctx, mut_dict__arr__char__arr__arr__char d, arr__char key);
bool has__q__bool__ptr_dict__arr__char__arr__arr__char__arr__char(ctx* _ctx, dict__arr__char__arr__arr__char* d, arr__char key);
bool has__q__bool__opt__arr__arr__char(opt__arr__arr__char a);
bool empty__q__bool__opt__arr__arr__char(opt__arr__arr__char a);
opt__arr__arr__char get__opt__arr__arr__char__ptr_dict__arr__char__arr__arr__char__arr__char(ctx* _ctx, dict__arr__char__arr__arr__char* d, arr__char key);
opt__arr__arr__char get_recursive__opt__arr__arr__char__arr__arr__char__arr__arr__arr__char__nat__arr__char(ctx* _ctx, arr__arr__char keys, arr__arr__arr__char values, nat idx, arr__char key);
some__arr__arr__char some__some__arr__arr__char__arr__arr__char(arr__arr__char t);
arr__arr__char at__arr__arr__char__arr__arr__arr__char__nat(ctx* _ctx, arr__arr__arr__char a, nat index);
arr__arr__char noctx_at__arr__arr__char__arr__arr__arr__char__nat(arr__arr__arr__char a, nat index);
arr__arr__char deref__arr__arr__char__ptr__arr__arr__char(ptr__arr__arr__char p);
ptr__arr__arr__char _op_plus__ptr__arr__arr__char__ptr__arr__arr__char__nat(ptr__arr__arr__char p, nat offset);
dict__arr__char__arr__arr__char* unsafe_as_dict__ptr_dict__arr__char__arr__arr__char__mut_dict__arr__char__arr__arr__char(ctx* _ctx, mut_dict__arr__char__arr__arr__char m);
arr__arr__arr__char unsafe_as_arr__arr__arr__arr__char__ptr_mut_arr__arr__arr__char(mut_arr__arr__arr__char* a);
_void push___void__ptr_mut_arr__arr__char__arr__char(ctx* _ctx, mut_arr__arr__char* a, arr__char value);
_void increase_capacity_to___void__ptr_mut_arr__arr__char__nat(ctx* _ctx, mut_arr__arr__char* a, nat new_capacity);
_void copy_data_from___void__ptr__arr__char__ptr__arr__char__nat(ctx* _ctx, ptr__arr__char to, ptr__arr__char from, nat len);
_void copy_data_from_small___void__ptr__arr__char__ptr__arr__char__nat(ctx* _ctx, ptr__arr__char to, ptr__arr__char from, nat len);
ptr__arr__char incr__ptr__arr__char__ptr__arr__char(ptr__arr__char p);
nat decr__nat__nat(ctx* _ctx, nat a);
nat wrap_decr__nat__nat(nat a);
nat if__nat__bool__nat__nat(bool cond, nat if_true, nat if_false);
nat _op_times__nat__nat__nat(ctx* _ctx, nat a, nat b);
_void ensure_capacity___void__ptr_mut_arr__arr__char__nat(ctx* _ctx, mut_arr__arr__char* a, nat capacity);
nat round_up_to_power_of_two__nat__nat(ctx* _ctx, nat n);
nat round_up_to_power_of_two_recur__nat__nat__nat(ctx* _ctx, nat acc, nat n);
_void push___void__ptr_mut_arr__arr__arr__char__arr__arr__char(ctx* _ctx, mut_arr__arr__arr__char* a, arr__arr__char value);
_void increase_capacity_to___void__ptr_mut_arr__arr__arr__char__nat(ctx* _ctx, mut_arr__arr__arr__char* a, nat new_capacity);
ptr__arr__arr__char uninitialized_data__ptr__arr__arr__char__nat(ctx* _ctx, nat size);
nat size_of__nat();
ptr__arr__arr__char ptr_cast__ptr__arr__arr__char__ptr__byte(ptr__byte p);
_void copy_data_from___void__ptr__arr__arr__char__ptr__arr__arr__char__nat(ctx* _ctx, ptr__arr__arr__char to, ptr__arr__arr__char from, nat len);
_void copy_data_from_small___void__ptr__arr__arr__char__ptr__arr__arr__char__nat(ctx* _ctx, ptr__arr__arr__char to, ptr__arr__arr__char from, nat len);
_void set___void__ptr__arr__arr__char__arr__arr__char(ptr__arr__arr__char p, arr__arr__char value);
ptr__arr__arr__char incr__ptr__arr__arr__char__ptr__arr__arr__char(ptr__arr__arr__char p);
_void ensure_capacity___void__ptr_mut_arr__arr__arr__char__nat(ctx* _ctx, mut_arr__arr__arr__char* a, nat capacity);
dict__arr__char__arr__arr__char* freeze__ptr_dict__arr__char__arr__arr__char__mut_dict__arr__char__arr__arr__char(ctx* _ctx, mut_dict__arr__char__arr__arr__char m);
arr__arr__arr__char freeze__arr__arr__arr__char__ptr_mut_arr__arr__arr__char(mut_arr__arr__arr__char* a);
arr__arr__char slice_after__arr__arr__char__arr__arr__char__nat(ctx* _ctx, arr__arr__char a, nat before_begin);
mut_arr__opt__arr__arr__char* fill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat__opt__arr__arr__char(ctx* _ctx, nat size, opt__arr__arr__char value);
mut_arr__opt__arr__arr__char* make_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat__fun_mut1__opt__arr__arr__char__nat(ctx* _ctx, nat size, fun_mut1__opt__arr__arr__char__nat f);
mut_arr__opt__arr__arr__char* new_uninitialized_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat(ctx* _ctx, nat size);
ptr__opt__arr__arr__char uninitialized_data__ptr__opt__arr__arr__char__nat(ctx* _ctx, nat size);
nat size_of__nat();
ptr__opt__arr__arr__char ptr_cast__ptr__opt__arr__arr__char__ptr__byte(ptr__byte p);
_void make_mut_arr_worker___void__ptr_mut_arr__opt__arr__arr__char__nat__nat__fun_mut1__opt__arr__arr__char__nat(ctx* _ctx, mut_arr__opt__arr__arr__char* m, nat lo, nat hi, fun_mut1__opt__arr__arr__char__nat f);
_void set_at___void__ptr_mut_arr__opt__arr__arr__char__nat__opt__arr__arr__char(ctx* _ctx, mut_arr__opt__arr__arr__char* a, nat index, opt__arr__arr__char value);
_void noctx_set_at___void__ptr_mut_arr__opt__arr__arr__char__nat__opt__arr__arr__char(mut_arr__opt__arr__arr__char* a, nat index, opt__arr__arr__char value);
_void set___void__ptr__opt__arr__arr__char__opt__arr__arr__char(ptr__opt__arr__arr__char p, opt__arr__arr__char value);
ptr__opt__arr__arr__char _op_plus__ptr__opt__arr__arr__char__ptr__opt__arr__arr__char__nat(ptr__opt__arr__arr__char p, nat offset);
opt__arr__arr__char call__opt__arr__arr__char__fun_mut1__opt__arr__arr__char__nat__nat(ctx* _ctx, fun_mut1__opt__arr__arr__char__nat f, nat p0);
opt__arr__arr__char call_with_ctx__opt__arr__arr__char__ptr_ctx__fun_mut1__opt__arr__arr__char__nat__nat(ctx* c, fun_mut1__opt__arr__arr__char__nat f, nat p0);
opt__arr__arr__char call__opt__arr__arr__char__fun_ptr3__opt__arr__arr__char__ptr_ctx__ptr__byte__nat__ptr_ctx__ptr__byte__nat(fun_ptr3__opt__arr__arr__char__ptr_ctx__ptr__byte__nat f, ctx* p0, ptr__byte p1, nat p2);
opt__arr__arr__char fill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat__opt__arr__arr__char__lambda0(ctx* _ctx, fill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat__opt__arr__arr__char__lambda0___closure* _closure, nat ignore);
cell__bool* new_cell__ptr_cell__bool__bool(ctx* _ctx, bool value);
_void each___void__ptr_dict__arr__char__arr__arr__char__fun_mut2___void__arr__char__arr__arr__char(ctx* _ctx, dict__arr__char__arr__arr__char* d, fun_mut2___void__arr__char__arr__arr__char f);
bool empty__q__bool__ptr_dict__arr__char__arr__arr__char(ctx* _ctx, dict__arr__char__arr__arr__char* d);
_void call___void__fun_mut2___void__arr__char__arr__arr__char__arr__char__arr__arr__char(ctx* _ctx, fun_mut2___void__arr__char__arr__arr__char f, arr__char p0, arr__arr__char p1);
_void call_with_ctx___void__ptr_ctx__fun_mut2___void__arr__char__arr__arr__char__arr__char__arr__arr__char(ctx* c, fun_mut2___void__arr__char__arr__arr__char f, arr__char p0, arr__arr__char p1);
_void call___void__fun_ptr4___void__ptr_ctx__ptr__byte__arr__char__arr__arr__char__ptr_ctx__ptr__byte__arr__char__arr__arr__char(fun_ptr4___void__ptr_ctx__ptr__byte__arr__char__arr__arr__char f, ctx* p0, ptr__byte p1, arr__char p2, arr__arr__char p3);
arr__arr__char first__arr__arr__char__arr__arr__arr__char(ctx* _ctx, arr__arr__arr__char a);
bool empty__q__bool__arr__arr__arr__char(arr__arr__arr__char a);
arr__arr__arr__char tail__arr__arr__arr__char__arr__arr__arr__char(ctx* _ctx, arr__arr__arr__char a);
arr__arr__arr__char slice_starting_at__arr__arr__arr__char__arr__arr__arr__char__nat(ctx* _ctx, arr__arr__arr__char a, nat begin);
arr__arr__arr__char slice__arr__arr__arr__char__arr__arr__arr__char__nat__nat(ctx* _ctx, arr__arr__arr__char a, nat begin, nat size);
opt__nat index_of__opt__nat__arr__arr__char__arr__char(ctx* _ctx, arr__arr__char a, arr__char value);
bool index_of__opt__nat__arr__arr__char__arr__char__lambda0(ctx* _ctx, index_of__opt__nat__arr__arr__char__arr__char__lambda0___closure* _closure, arr__char it);
_void set___void__ptr_cell__bool__bool(cell__bool* c, bool v);
arr__char _op_plus__arr__char__arr__char__arr__char(ctx* _ctx, arr__char a, arr__char b);
arr__char make_arr__arr__char__nat__fun_mut1__char__nat(ctx* _ctx, nat size, fun_mut1__char__nat f);
arr__char freeze__arr__char__ptr_mut_arr__char(mut_arr__char* a);
arr__char unsafe_as_arr__arr__char__ptr_mut_arr__char(mut_arr__char* a);
mut_arr__char* make_mut_arr__ptr_mut_arr__char__nat__fun_mut1__char__nat(ctx* _ctx, nat size, fun_mut1__char__nat f);
mut_arr__char* new_uninitialized_mut_arr__ptr_mut_arr__char__nat(ctx* _ctx, nat size);
ptr__char uninitialized_data__ptr__char__nat(ctx* _ctx, nat size);
ptr__char ptr_cast__ptr__char__ptr__byte(ptr__byte p);
_void make_mut_arr_worker___void__ptr_mut_arr__char__nat__nat__fun_mut1__char__nat(ctx* _ctx, mut_arr__char* m, nat lo, nat hi, fun_mut1__char__nat f);
_void set_at___void__ptr_mut_arr__char__nat__char(ctx* _ctx, mut_arr__char* a, nat index, char value);
_void noctx_set_at___void__ptr_mut_arr__char__nat__char(mut_arr__char* a, nat index, char value);
_void set___void__ptr__char__char(ptr__char p, char value);
char call__char__fun_mut1__char__nat__nat(ctx* _ctx, fun_mut1__char__nat f, nat p0);
char call_with_ctx__char__ptr_ctx__fun_mut1__char__nat__nat(ctx* c, fun_mut1__char__nat f, nat p0);
char call__char__fun_ptr3__char__ptr_ctx__ptr__byte__nat__ptr_ctx__ptr__byte__nat(fun_ptr3__char__ptr_ctx__ptr__byte__nat f, ctx* p0, ptr__byte p1, nat p2);
char _op_plus__arr__char__arr__char__arr__char__lambda0(ctx* _ctx, _op_plus__arr__char__arr__char__arr__char__lambda0___closure* _closure, nat i);
opt__arr__arr__char at__opt__arr__arr__char__ptr_mut_arr__opt__arr__arr__char__nat(ctx* _ctx, mut_arr__opt__arr__arr__char* a, nat index);
opt__arr__arr__char noctx_at__opt__arr__arr__char__ptr_mut_arr__opt__arr__arr__char__nat(mut_arr__opt__arr__arr__char* a, nat index);
opt__arr__arr__char deref__opt__arr__arr__char__ptr__opt__arr__arr__char(ptr__opt__arr__arr__char p);
_void parse_cmd_line_args__opt__test_options__arr__arr__char__arr__arr__char__fun1__test_options__arr__opt__arr__arr__char__lambda0(ctx* _ctx, parse_cmd_line_args__opt__test_options__arr__arr__char__arr__arr__char__fun1__test_options__arr__opt__arr__arr__char__lambda0___closure* _closure, arr__char key, arr__arr__char value);
bool get__bool__ptr_cell__bool(cell__bool* c);
some__test_options some__some__test_options__test_options(test_options t);
test_options call__test_options__fun1__test_options__arr__opt__arr__arr__char__arr__opt__arr__arr__char(ctx* _ctx, fun1__test_options__arr__opt__arr__arr__char f, arr__opt__arr__arr__char p0);
test_options call_with_ctx__test_options__ptr_ctx__fun1__test_options__arr__opt__arr__arr__char__arr__opt__arr__arr__char(ctx* c, fun1__test_options__arr__opt__arr__arr__char f, arr__opt__arr__arr__char p0);
test_options call__test_options__fun_ptr3__test_options__ptr_ctx__ptr__byte__arr__opt__arr__arr__char__ptr_ctx__ptr__byte__arr__opt__arr__arr__char(fun_ptr3__test_options__ptr_ctx__ptr__byte__arr__opt__arr__arr__char f, ctx* p0, ptr__byte p1, arr__opt__arr__arr__char p2);
arr__opt__arr__arr__char freeze__arr__opt__arr__arr__char__ptr_mut_arr__opt__arr__arr__char(mut_arr__opt__arr__arr__char* a);
arr__opt__arr__arr__char unsafe_as_arr__arr__opt__arr__arr__char__ptr_mut_arr__opt__arr__arr__char(mut_arr__opt__arr__arr__char* a);
opt__arr__arr__char at__opt__arr__arr__char__arr__opt__arr__arr__char__nat(ctx* _ctx, arr__opt__arr__arr__char a, nat index);
opt__arr__arr__char noctx_at__opt__arr__arr__char__arr__opt__arr__arr__char__nat(arr__opt__arr__arr__char a, nat index);
nat literal__nat__arr__char(ctx* _ctx, arr__char s);
arr__char rtail__arr__char__arr__char(ctx* _ctx, arr__char a);
nat char_to_nat__nat__char(char c);
nat todo__nat();
nat hard_fail__nat__arr__char(arr__char reason);
char last__char__arr__char(ctx* _ctx, arr__char a);
test_options main__ptr_fut__int32__arr__arr__char__lambda0(ctx* _ctx, ptr__byte _closure, arr__opt__arr__arr__char values);
fut__int32* resolved__ptr_fut__int32__int32(ctx* _ctx, int32 value);
_void print_help___void(ctx* _ctx);
_void print_sync___void__arr__char(arr__char s);
_void print_sync_no_newline___void__arr__char(arr__char s);
int32 stdout_fd__int32();
int32 literal__int32__arr__char(ctx* _ctx, arr__char s);
int32 unsafe_to_int32__int32___int(_int a);
_int as___int___int(_int value);
_int literal___int__arr__char(ctx* _ctx, arr__char s);
_int neg___int__nat(ctx* _ctx, nat n);
_int neg___int___int(ctx* _ctx, _int i);
_int _op_times___int___int___int(ctx* _ctx, _int a, _int b);
bool _op_greater__bool___int___int(_int a, _int b);
bool _op_less_equal__bool___int___int(_int a, _int b);
bool _op_less__bool___int___int(_int a, _int b);
_int neg_million___int();
_int wrap_mul___int___int___int(_int a, _int b);
_int million___int();
_int thousand___int();
_int hundred___int();
_int ten___int();
_int wrap_incr___int___int(_int a);
_int wrap_add___int___int___int(_int a, _int b);
_int one___int();
_int nine___int();
_int eight___int();
_int seven___int();
_int six___int();
_int five___int();
_int four___int();
_int three___int();
_int two___int();
_int neg_one___int();
_int wrap_sub___int___int___int(_int a, _int b);
_int zero___int();
_int to_int___int__nat(ctx* _ctx, nat n);
int32 do_test__int32__test_options(ctx* _ctx, test_options options);
arr__char parent_path__arr__char__arr__char(ctx* _ctx, arr__char a);
opt__nat r_index_of__opt__nat__arr__char__char(ctx* _ctx, arr__char a, char value);
opt__nat find_rindex__opt__nat__arr__char__fun_mut1__bool__char(ctx* _ctx, arr__char a, fun_mut1__bool__char pred);
opt__nat find_rindex_recur__opt__nat__arr__char__nat__fun_mut1__bool__char(ctx* _ctx, arr__char a, nat index, fun_mut1__bool__char pred);
bool call__bool__fun_mut1__bool__char__char(ctx* _ctx, fun_mut1__bool__char f, char p0);
bool call_with_ctx__bool__ptr_ctx__fun_mut1__bool__char__char(ctx* c, fun_mut1__bool__char f, char p0);
bool call__bool__fun_ptr3__bool__ptr_ctx__ptr__byte__char__ptr_ctx__ptr__byte__char(fun_ptr3__bool__ptr_ctx__ptr__byte__char f, ctx* p0, ptr__byte p1, char p2);
bool r_index_of__opt__nat__arr__char__char__lambda0(ctx* _ctx, r_index_of__opt__nat__arr__char__char__lambda0___closure* _closure, char it);
arr__char slice_up_to__arr__char__arr__char__nat(ctx* _ctx, arr__char a, nat size);
arr__char current_executable_path__arr__char(ctx* _ctx);
arr__char read_link__arr__char__arr__char(ctx* _ctx, arr__char path);
extern _int readlink(ptr__char path, ptr__char buf, nat len);
ptr__char to_c_str__ptr__char__arr__char(ctx* _ctx, arr__char a);
_void check_errno_if_neg_one___void___int(ctx* _ctx, _int e);
_void check_posix_error___void__int32(ctx* _ctx, int32 e);
int32 get_errno__int32(ctx* _ctx);
_void hard_unreachable___void();
nat to_nat__nat___int(ctx* _ctx, _int i);
bool negative__q__bool___int(ctx* _ctx, _int i);
arr__char child_path__arr__char__arr__char__arr__char(ctx* _ctx, arr__char a, arr__char child_name);
dict__arr__char__arr__char* get_environ__ptr_dict__arr__char__arr__char(ctx* _ctx);
mut_dict__arr__char__arr__char new_mut_dict__mut_dict__arr__char__arr__char(ctx* _ctx);
_void get_environ_recur___void__ptr__ptr__char__mut_dict__arr__char__arr__char(ctx* _ctx, ptr__ptr__char env, mut_dict__arr__char__arr__char res);
bool null__q__bool__ptr__char(ptr__char a);
bool _op_equal_equal__bool__ptr__char__ptr__char(ptr__char a, ptr__char b);
comparison _op_less_equal_greater__comparison__ptr__char__ptr__char(ptr__char a, ptr__char b);
ptr__char null__ptr__char();
_void add___void__mut_dict__arr__char__arr__char__ptr_key_value_pair__arr__char__arr__char(ctx* _ctx, mut_dict__arr__char__arr__char m, key_value_pair__arr__char__arr__char* pair);
_void add___void__mut_dict__arr__char__arr__char__arr__char__arr__char(ctx* _ctx, mut_dict__arr__char__arr__char m, arr__char key, arr__char value);
bool has__q__bool__mut_dict__arr__char__arr__char__arr__char(ctx* _ctx, mut_dict__arr__char__arr__char d, arr__char key);
bool has__q__bool__ptr_dict__arr__char__arr__char__arr__char(ctx* _ctx, dict__arr__char__arr__char* d, arr__char key);
bool has__q__bool__opt__arr__char(opt__arr__char a);
bool empty__q__bool__opt__arr__char(opt__arr__char a);
opt__arr__char get__opt__arr__char__ptr_dict__arr__char__arr__char__arr__char(ctx* _ctx, dict__arr__char__arr__char* d, arr__char key);
opt__arr__char get_recursive__opt__arr__char__arr__arr__char__arr__arr__char__nat__arr__char(ctx* _ctx, arr__arr__char keys, arr__arr__char values, nat idx, arr__char key);
dict__arr__char__arr__char* unsafe_as_dict__ptr_dict__arr__char__arr__char__mut_dict__arr__char__arr__char(ctx* _ctx, mut_dict__arr__char__arr__char m);
key_value_pair__arr__char__arr__char* parse_environ_entry__ptr_key_value_pair__arr__char__arr__char__ptr__char(ctx* _ctx, ptr__char entry);
ptr__ptr__char incr__ptr__ptr__char__ptr__ptr__char(ptr__ptr__char p);
extern ptr__ptr__char environ;
dict__arr__char__arr__char* freeze__ptr_dict__arr__char__arr__char__mut_dict__arr__char__arr__char(ctx* _ctx, mut_dict__arr__char__arr__char m);
result__arr__char__arr__ptr_failure run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options(ctx* _ctx, arr__char path, arr__char path_to_noze, dict__arr__char__arr__char* env, test_options options);
arr__arr__char list_compile_error_tests__arr__arr__char__arr__char(ctx* _ctx, arr__char path);
fun_mut1__bool__arr__char as__fun_mut1__bool__arr__char__fun_mut1__bool__arr__char(fun_mut1__bool__arr__char value);
bool list_compile_error_tests__arr__arr__char__arr__char__lambda0(ctx* _ctx, ptr__byte _closure, arr__char s);
_void each_child_recursive___void__arr__char__fun_mut1__bool__arr__char__fun_mut1___void__arr__char(ctx* _ctx, arr__char path, fun_mut1__bool__arr__char filter, fun_mut1___void__arr__char f);
bool is_dir__q__bool__arr__char(ctx* _ctx, arr__char path);
bool is_dir__q__bool__ptr__char(ctx* _ctx, ptr__char path);
opt__ptr_stat_t get_stat__opt__ptr_stat_t__ptr__char(ctx* _ctx, ptr__char path);
stat_t* empty_stat__ptr_stat_t(ctx* _ctx);
nat32 zero__nat32();
extern int32 stat(ptr__char path, stat_t* buf);
some__ptr_stat_t some__some__ptr_stat_t__ptr_stat_t(stat_t* t);
int32 neg_one__int32();
int32 wrap_sub__int32__int32__int32(int32 a, int32 b);
int32 enoent__int32();
opt__ptr_stat_t todo__opt__ptr_stat_t();
opt__ptr_stat_t hard_fail__opt__ptr_stat_t__arr__char(arr__char reason);
bool todo__bool();
bool hard_fail__bool__arr__char(arr__char reason);
bool _op_equal_equal__bool__nat32__nat32(nat32 a, nat32 b);
comparison _op_less_equal_greater__comparison__nat32__nat32(nat32 a, nat32 b);
nat32 bits_and__nat32__nat32__nat32(nat32 a, nat32 b);
nat32 s_ifmt__nat32(ctx* _ctx);
nat32 wrap_mul__nat32__nat32__nat32(nat32 a, nat32 b);
nat32 two_pow__nat32__nat32(nat32 pow);
bool zero__q__bool__nat32(nat32 n);
nat32 one__nat32();
nat32 wrap_decr__nat32__nat32(nat32 a);
nat32 wrap_sub__nat32__nat32__nat32(nat32 a, nat32 b);
nat32 two__nat32();
nat32 wrap_incr__nat32__nat32(nat32 a);
nat32 wrap_add__nat32__nat32__nat32(nat32 a, nat32 b);
nat32 twelve__nat32();
nat32 eight__nat32();
nat32 seven__nat32();
nat32 six__nat32();
nat32 five__nat32();
nat32 four__nat32();
nat32 three__nat32();
nat32 fifteen__nat32();
nat32 fourteen__nat32();
nat32 s_ifdir__nat32(ctx* _ctx);
_void each___void__arr__arr__char__fun_mut1___void__arr__char(ctx* _ctx, arr__arr__char a, fun_mut1___void__arr__char f);
_void call___void__fun_mut1___void__arr__char__arr__char(ctx* _ctx, fun_mut1___void__arr__char f, arr__char p0);
_void call_with_ctx___void__ptr_ctx__fun_mut1___void__arr__char__arr__char(ctx* c, fun_mut1___void__arr__char f, arr__char p0);
_void call___void__fun_ptr3___void__ptr_ctx__ptr__byte__arr__char__ptr_ctx__ptr__byte__arr__char(fun_ptr3___void__ptr_ctx__ptr__byte__arr__char f, ctx* p0, ptr__byte p1, arr__char p2);
arr__arr__char read_dir__arr__arr__char__arr__char(ctx* _ctx, arr__char path);
arr__arr__char read_dir__arr__arr__char__ptr__char(ctx* _ctx, ptr__char path);
extern ptr__byte opendir(ptr__char name);
_void read_dir_recur___void__ptr__byte__ptr_mut_arr__arr__char(ctx* _ctx, ptr__byte dirp, mut_arr__arr__char* res);
nat16 zero__nat16();
bytes256 zero__bytes256();
cell__ptr_dirent* new_cell__ptr_cell__ptr_dirent__ptr_dirent(ctx* _ctx, dirent* value);
extern int32 readdir_r(ptr__byte dirp, dirent* entry, cell__ptr_dirent* result);
ptr__byte as_any_ptr__ptr__byte__ptr_dirent(dirent* some_ref);
dirent* get__ptr_dirent__ptr_cell__ptr_dirent(cell__ptr_dirent* c);
bool ptr_eq__bool__ptr_dirent__ptr_dirent(dirent* a, dirent* b);
arr__char get_dirent_name__arr__char__ptr_dirent(dirent* d);
nat size_of__nat();
nat size_of__nat();
ptr__byte _op_plus__ptr__byte__ptr__byte__nat(ptr__byte p, nat offset);
arr__arr__char sort__arr__arr__char__arr__arr__char(ctx* _ctx, arr__arr__char a);
mut_arr__arr__char* to_mut_arr__ptr_mut_arr__arr__char__arr__arr__char(ctx* _ctx, arr__arr__char a);
arr__char to_mut_arr__ptr_mut_arr__arr__char__arr__arr__char__lambda0(ctx* _ctx, to_mut_arr__ptr_mut_arr__arr__char__arr__arr__char__lambda0___closure* _closure, nat i);
_void sort___void__ptr_mut_arr__arr__char(ctx* _ctx, mut_arr__arr__char* a);
_void sort___void__ptr_mut_slice__arr__char(ctx* _ctx, mut_slice__arr__char* a);
_void swap___void__ptr_mut_slice__arr__char__nat__nat(ctx* _ctx, mut_slice__arr__char* a, nat lo, nat hi);
arr__char at__arr__char__ptr_mut_slice__arr__char__nat(ctx* _ctx, mut_slice__arr__char* a, nat index);
arr__char at__arr__char__ptr_mut_arr__arr__char__nat(ctx* _ctx, mut_arr__arr__char* a, nat index);
arr__char noctx_at__arr__char__ptr_mut_arr__arr__char__nat(mut_arr__arr__char* a, nat index);
_void set_at___void__ptr_mut_slice__arr__char__nat__arr__char(ctx* _ctx, mut_slice__arr__char* a, nat index, arr__char value);
nat partition_recur__nat__ptr_mut_slice__arr__char__arr__char__nat__nat(ctx* _ctx, mut_slice__arr__char* a, arr__char pivot, nat l, nat r);
bool _op_less__bool__arr__char__arr__char(arr__char a, arr__char b);
mut_slice__arr__char* slice__ptr_mut_slice__arr__char__ptr_mut_slice__arr__char__nat__nat(ctx* _ctx, mut_slice__arr__char* a, nat lo, nat size);
mut_slice__arr__char* slice__ptr_mut_slice__arr__char__ptr_mut_slice__arr__char__nat(ctx* _ctx, mut_slice__arr__char* a, nat lo);
mut_slice__arr__char* to_mut_slice__ptr_mut_slice__arr__char__ptr_mut_arr__arr__char(ctx* _ctx, mut_arr__arr__char* a);
_void each_child_recursive___void__arr__char__fun_mut1__bool__arr__char__fun_mut1___void__arr__char__lambda0(ctx* _ctx, each_child_recursive___void__arr__char__fun_mut1__bool__arr__char__fun_mut1___void__arr__char__lambda0___closure* _closure, arr__char child_name);
opt__arr__char get_extension__opt__arr__char__arr__char(ctx* _ctx, arr__char name);
opt__nat last_index_of__opt__nat__arr__char__char(ctx* _ctx, arr__char s, char c);
arr__char slice_after__arr__char__arr__char__nat(ctx* _ctx, arr__char a, nat before_begin);
arr__char base_name__arr__char__arr__char(ctx* _ctx, arr__char path);
_void list_compile_error_tests__arr__arr__char__arr__char__lambda1(ctx* _ctx, list_compile_error_tests__arr__arr__char__arr__char__lambda1___closure* _closure, arr__char child);
arr__ptr_failure flat_map_with_max_size__arr__ptr_failure__arr__arr__char__nat__fun_mut1__arr__ptr_failure__arr__char(ctx* _ctx, arr__arr__char a, nat max_size, fun_mut1__arr__ptr_failure__arr__char mapper);
mut_arr__ptr_failure* new_mut_arr__ptr_mut_arr__ptr_failure(ctx* _ctx);
ptr__ptr_failure null__ptr__ptr_failure();
_void push_all___void__ptr_mut_arr__ptr_failure__arr__ptr_failure(ctx* _ctx, mut_arr__ptr_failure* a, arr__ptr_failure values);
_void each___void__arr__ptr_failure__fun_mut1___void__ptr_failure(ctx* _ctx, arr__ptr_failure a, fun_mut1___void__ptr_failure f);
bool empty__q__bool__arr__ptr_failure(arr__ptr_failure a);
_void call___void__fun_mut1___void__ptr_failure__ptr_failure(ctx* _ctx, fun_mut1___void__ptr_failure f, failure* p0);
_void call_with_ctx___void__ptr_ctx__fun_mut1___void__ptr_failure__ptr_failure(ctx* c, fun_mut1___void__ptr_failure f, failure* p0);
_void call___void__fun_ptr3___void__ptr_ctx__ptr__byte__ptr_failure__ptr_ctx__ptr__byte__ptr_failure(fun_ptr3___void__ptr_ctx__ptr__byte__ptr_failure f, ctx* p0, ptr__byte p1, failure* p2);
failure* first__ptr_failure__arr__ptr_failure(ctx* _ctx, arr__ptr_failure a);
failure* at__ptr_failure__arr__ptr_failure__nat(ctx* _ctx, arr__ptr_failure a, nat index);
failure* noctx_at__ptr_failure__arr__ptr_failure__nat(arr__ptr_failure a, nat index);
failure* deref__ptr_failure__ptr__ptr_failure(ptr__ptr_failure p);
ptr__ptr_failure _op_plus__ptr__ptr_failure__ptr__ptr_failure__nat(ptr__ptr_failure p, nat offset);
arr__ptr_failure tail__arr__ptr_failure__arr__ptr_failure(ctx* _ctx, arr__ptr_failure a);
arr__ptr_failure slice_starting_at__arr__ptr_failure__arr__ptr_failure__nat(ctx* _ctx, arr__ptr_failure a, nat begin);
arr__ptr_failure slice__arr__ptr_failure__arr__ptr_failure__nat__nat(ctx* _ctx, arr__ptr_failure a, nat begin, nat size);
_void push___void__ptr_mut_arr__ptr_failure__ptr_failure(ctx* _ctx, mut_arr__ptr_failure* a, failure* value);
_void increase_capacity_to___void__ptr_mut_arr__ptr_failure__nat(ctx* _ctx, mut_arr__ptr_failure* a, nat new_capacity);
ptr__ptr_failure uninitialized_data__ptr__ptr_failure__nat(ctx* _ctx, nat size);
nat size_of__nat();
ptr__ptr_failure ptr_cast__ptr__ptr_failure__ptr__byte(ptr__byte p);
_void copy_data_from___void__ptr__ptr_failure__ptr__ptr_failure__nat(ctx* _ctx, ptr__ptr_failure to, ptr__ptr_failure from, nat len);
_void copy_data_from_small___void__ptr__ptr_failure__ptr__ptr_failure__nat(ctx* _ctx, ptr__ptr_failure to, ptr__ptr_failure from, nat len);
_void set___void__ptr__ptr_failure__ptr_failure(ptr__ptr_failure p, failure* value);
ptr__ptr_failure incr__ptr__ptr_failure__ptr__ptr_failure(ptr__ptr_failure p);
_void ensure_capacity___void__ptr_mut_arr__ptr_failure__nat(ctx* _ctx, mut_arr__ptr_failure* a, nat capacity);
_void push_all___void__ptr_mut_arr__ptr_failure__arr__ptr_failure__lambda0(ctx* _ctx, push_all___void__ptr_mut_arr__ptr_failure__arr__ptr_failure__lambda0___closure* _closure, failure* it);
arr__ptr_failure call__arr__ptr_failure__fun_mut1__arr__ptr_failure__arr__char__arr__char(ctx* _ctx, fun_mut1__arr__ptr_failure__arr__char f, arr__char p0);
arr__ptr_failure call_with_ctx__arr__ptr_failure__ptr_ctx__fun_mut1__arr__ptr_failure__arr__char__arr__char(ctx* c, fun_mut1__arr__ptr_failure__arr__char f, arr__char p0);
arr__ptr_failure call__arr__ptr_failure__fun_ptr3__arr__ptr_failure__ptr_ctx__ptr__byte__arr__char__ptr_ctx__ptr__byte__arr__char(fun_ptr3__arr__ptr_failure__ptr_ctx__ptr__byte__arr__char f, ctx* p0, ptr__byte p1, arr__char p2);
_void reduce_size_if_more_than___void__ptr_mut_arr__ptr_failure__nat(ctx* _ctx, mut_arr__ptr_failure* a, nat new_size);
_void flat_map_with_max_size__arr__ptr_failure__arr__arr__char__nat__fun_mut1__arr__ptr_failure__arr__char__lambda0(ctx* _ctx, flat_map_with_max_size__arr__ptr_failure__arr__arr__char__nat__fun_mut1__arr__ptr_failure__arr__char__lambda0___closure* _closure, arr__char x);
arr__ptr_failure freeze__arr__ptr_failure__ptr_mut_arr__ptr_failure(mut_arr__ptr_failure* a);
arr__ptr_failure unsafe_as_arr__arr__ptr_failure__ptr_mut_arr__ptr_failure(mut_arr__ptr_failure* a);
arr__ptr_failure run_single_compile_error_test__arr__ptr_failure__arr__char__ptr_dict__arr__char__arr__char__arr__char__bool(ctx* _ctx, arr__char path_to_noze, dict__arr__char__arr__char* env, arr__char path, bool overwrite_output__q);
process_result* spawn_and_wait_result__ptr_process_result__arr__char__arr__arr__char__ptr_dict__arr__char__arr__char(ctx* _ctx, arr__char exe, arr__arr__char args, dict__arr__char__arr__char* environ);
arr__char fold__arr__char__arr__char__arr__arr__char__fun_mut2__arr__char__arr__char__arr__char(ctx* _ctx, arr__char val, arr__arr__char a, fun_mut2__arr__char__arr__char__arr__char combine);
arr__char call__arr__char__fun_mut2__arr__char__arr__char__arr__char__arr__char__arr__char(ctx* _ctx, fun_mut2__arr__char__arr__char__arr__char f, arr__char p0, arr__char p1);
arr__char call_with_ctx__arr__char__ptr_ctx__fun_mut2__arr__char__arr__char__arr__char__arr__char__arr__char(ctx* c, fun_mut2__arr__char__arr__char__arr__char f, arr__char p0, arr__char p1);
arr__char call__arr__char__fun_ptr4__arr__char__ptr_ctx__ptr__byte__arr__char__arr__char__ptr_ctx__ptr__byte__arr__char__arr__char(fun_ptr4__arr__char__ptr_ctx__ptr__byte__arr__char__arr__char f, ctx* p0, ptr__byte p1, arr__char p2, arr__char p3);
arr__char spawn_and_wait_result__ptr_process_result__arr__char__arr__arr__char__ptr_dict__arr__char__arr__char__lambda0(ctx* _ctx, ptr__byte _closure, arr__char a, arr__char b);
bool is_file__q__bool__arr__char(ctx* _ctx, arr__char path);
bool is_file__q__bool__ptr__char(ctx* _ctx, ptr__char path);
nat32 s_ifreg__nat32(ctx* _ctx);
process_result* spawn_and_wait_result__ptr_process_result__ptr__char__ptr__ptr__char__ptr__ptr__char(ctx* _ctx, ptr__char exe, ptr__ptr__char args, ptr__ptr__char environ);
pipes* make_pipes__ptr_pipes(ctx* _ctx);
extern int32 pipe(pipes* pipes);
extern int32 posix_spawn_file_actions_init(posix_spawn_file_actions_t* file_actions);
extern int32 posix_spawn_file_actions_addclose(posix_spawn_file_actions_t* file_actions, int32 fd);
extern int32 posix_spawn_file_actions_adddup2(posix_spawn_file_actions_t* file_actions, int32 fd, int32 new_fd);
cell__int32* new_cell__ptr_cell__int32__int32(ctx* _ctx, int32 value);
extern int32 posix_spawn(cell__int32* pid, ptr__char executable_path, posix_spawn_file_actions_t* file_actions, ptr__byte attrp, ptr__ptr__char argv, ptr__ptr__char environ);
int32 get__int32__ptr_cell__int32(cell__int32* c);
extern int32 close(int32 fd);
mut_arr__char* new_mut_arr__ptr_mut_arr__char(ctx* _ctx);
_void keep_polling___void__int32__int32__ptr_mut_arr__char__ptr_mut_arr__char(ctx* _ctx, int32 stdout_pipe, int32 stderr_pipe, mut_arr__char* stdout_builder, mut_arr__char* stderr_builder);
int16 pollin__int16(ctx* _ctx);
int16 two_pow__int16__int16(int16 pow);
bool zero__q__bool__int16(int16 a);
bool _op_equal_equal__bool__int16__int16(int16 a, int16 b);
comparison _op_less_equal_greater__comparison__int16__int16(int16 a, int16 b);
int16 zero__int16();
int16 one__int16();
int16 wrap_mul__int16__int16__int16(int16 a, int16 b);
int16 wrap_decr__int16__int16(int16 a);
int16 wrap_sub__int16__int16__int16(int16 a, int16 b);
int16 two__int16();
int16 wrap_incr__int16__int16(int16 a);
int16 wrap_add__int16__int16__int16(int16 a, int16 b);
pollfd* ref_of_val_at__ptr_pollfd__arr__pollfd__nat(ctx* _ctx, arr__pollfd a, nat index);
pollfd* ref_of_ptr__ptr_pollfd__ptr__pollfd(ptr__pollfd p);
pollfd* ref_of_val__ptr_pollfd__pollfd(pollfd b);
pollfd deref__pollfd__ptr__pollfd(ptr__pollfd p);
ptr__pollfd _op_plus__ptr__pollfd__ptr__pollfd__nat(ptr__pollfd p, nat offset);
extern int32 poll(ptr__pollfd fds, nat n_fds, int32 timeout);
handle_revents_result handle_revents__handle_revents_result__ptr_pollfd__ptr_mut_arr__char(ctx* _ctx, pollfd* pollfd, mut_arr__char* builder);
bool has_pollin__q__bool__int16(ctx* _ctx, int16 revents);
bool bits_intersect__q__bool__int16__int16(int16 a, int16 b);
int16 bits_and__int16__int16__int16(int16 a, int16 b);
_void read_to_buffer_until_eof___void__int32__ptr_mut_arr__char(ctx* _ctx, int32 fd, mut_arr__char* buffer);
nat two_pow__nat__nat(nat pow);
_void ensure_capacity___void__ptr_mut_arr__char__nat(ctx* _ctx, mut_arr__char* a, nat capacity);
_void increase_capacity_to___void__ptr_mut_arr__char__nat(ctx* _ctx, mut_arr__char* a, nat new_capacity);
_void copy_data_from___void__ptr__char__ptr__char__nat(ctx* _ctx, ptr__char to, ptr__char from, nat len);
_void copy_data_from_small___void__ptr__char__ptr__char__nat(ctx* _ctx, ptr__char to, ptr__char from, nat len);
extern _int read(int32 fd, ptr__byte buff, nat n_bytes);
_void unsafe_increase_size___void__ptr_mut_arr__char__nat(ctx* _ctx, mut_arr__char* a, nat increase_by);
_void unsafe_set_size___void__ptr_mut_arr__char__nat(ctx* _ctx, mut_arr__char* a, nat new_size);
bool has_pollhup__q__bool__int16(ctx* _ctx, int16 revents);
int16 pollhup__int16(ctx* _ctx);
int16 four__int16();
int16 three__int16();
bool has_pollpri__q__bool__int16(ctx* _ctx, int16 revents);
int16 pollpri__int16(ctx* _ctx);
bool has_pollout__q__bool__int16(ctx* _ctx, int16 revents);
int16 pollout__int16(ctx* _ctx);
bool has_pollerr__q__bool__int16(ctx* _ctx, int16 revents);
int16 pollerr__int16(ctx* _ctx);
bool has_pollnval__q__bool__int16(ctx* _ctx, int16 revents);
int16 pollnval__int16(ctx* _ctx);
int16 five__int16();
nat to_nat__nat__bool(ctx* _ctx, bool b);
bool any__q__bool__handle_revents_result(ctx* _ctx, handle_revents_result r);
nat to_nat__nat__int32(ctx* _ctx, int32 i);
int32 wait_and_get_exit_code__int32__int32(ctx* _ctx, int32 pid);
extern int32 waitpid(int32 pid, cell__int32* wait_status, int32 options);
bool w_if_exited__bool__int32(ctx* _ctx, int32 status);
int32 w_term_sig__int32__int32(ctx* _ctx, int32 status);
int32 bits_and__int32__int32__int32(int32 a, int32 b);
int32 x7f__int32();
int32 noctx_decr__int32__int32(int32 a);
int32 two_pow__int32__int32(int32 pow);
int32 wrap_mul__int32__int32__int32(int32 a, int32 b);
int32 wrap_decr__int32__int32(int32 a);
int32 w_exit_status__int32__int32(ctx* _ctx, int32 status);
int32 bit_rshift__int32__int32__int32(int32 a, int32 b);
int32 xff00__int32();
int32 xffff__int32();
int32 sixteen__int32();
int32 xff__int32();
bool w_if_signaled__bool__int32(ctx* _ctx, int32 status);
bool _op_bang_equal__bool__int32__int32(int32 a, int32 b);
arr__char to_str__arr__char__int32(ctx* _ctx, int32 i);
arr__char to_str__arr__char___int(ctx* _ctx, _int i);
arr__char to_str__arr__char__nat(ctx* _ctx, nat n);
nat mod__nat__nat__nat(ctx* _ctx, nat a, nat b);
nat unsafe_mod__nat__nat__nat(nat a, nat b);
nat abs__nat___int(ctx* _ctx, _int i);
_int if___int__bool___int___int(bool cond, _int if_true, _int if_false);
int32 todo__int32();
int32 hard_fail__int32__arr__char(arr__char reason);
bool w_if_stopped__bool__int32(ctx* _ctx, int32 status);
bool w_if_continued__bool__int32(ctx* _ctx, int32 status);
ptr__ptr__char convert_args__ptr__ptr__char__ptr__char__arr__arr__char(ctx* _ctx, ptr__char exe_c_str, arr__arr__char args);
arr__ptr__char cons__arr__ptr__char__ptr__char__arr__ptr__char(ctx* _ctx, ptr__char a, arr__ptr__char b);
arr__ptr__char _op_plus__arr__ptr__char__arr__ptr__char__arr__ptr__char(ctx* _ctx, arr__ptr__char a, arr__ptr__char b);
arr__ptr__char make_arr__arr__ptr__char__nat__fun_mut1__ptr__char__nat(ctx* _ctx, nat size, fun_mut1__ptr__char__nat f);
arr__ptr__char freeze__arr__ptr__char__ptr_mut_arr__ptr__char(mut_arr__ptr__char* a);
arr__ptr__char unsafe_as_arr__arr__ptr__char__ptr_mut_arr__ptr__char(mut_arr__ptr__char* a);
mut_arr__ptr__char* make_mut_arr__ptr_mut_arr__ptr__char__nat__fun_mut1__ptr__char__nat(ctx* _ctx, nat size, fun_mut1__ptr__char__nat f);
mut_arr__ptr__char* new_uninitialized_mut_arr__ptr_mut_arr__ptr__char__nat(ctx* _ctx, nat size);
ptr__ptr__char uninitialized_data__ptr__ptr__char__nat(ctx* _ctx, nat size);
nat size_of__nat();
ptr__ptr__char ptr_cast__ptr__ptr__char__ptr__byte(ptr__byte p);
_void make_mut_arr_worker___void__ptr_mut_arr__ptr__char__nat__nat__fun_mut1__ptr__char__nat(ctx* _ctx, mut_arr__ptr__char* m, nat lo, nat hi, fun_mut1__ptr__char__nat f);
_void set_at___void__ptr_mut_arr__ptr__char__nat__ptr__char(ctx* _ctx, mut_arr__ptr__char* a, nat index, ptr__char value);
_void noctx_set_at___void__ptr_mut_arr__ptr__char__nat__ptr__char(mut_arr__ptr__char* a, nat index, ptr__char value);
_void set___void__ptr__ptr__char__ptr__char(ptr__ptr__char p, ptr__char value);
ptr__char call__ptr__char__fun_mut1__ptr__char__nat__nat(ctx* _ctx, fun_mut1__ptr__char__nat f, nat p0);
ptr__char call_with_ctx__ptr__char__ptr_ctx__fun_mut1__ptr__char__nat__nat(ctx* c, fun_mut1__ptr__char__nat f, nat p0);
ptr__char call__ptr__char__fun_ptr3__ptr__char__ptr_ctx__ptr__byte__nat__ptr_ctx__ptr__byte__nat(fun_ptr3__ptr__char__ptr_ctx__ptr__byte__nat f, ctx* p0, ptr__byte p1, nat p2);
ptr__char _op_plus__arr__ptr__char__arr__ptr__char__arr__ptr__char__lambda0(ctx* _ctx, _op_plus__arr__ptr__char__arr__ptr__char__arr__ptr__char__lambda0___closure* _closure, nat i);
arr__ptr__char rcons__arr__ptr__char__arr__ptr__char__ptr__char(ctx* _ctx, arr__ptr__char a, ptr__char b);
arr__ptr__char map__arr__ptr__char__arr__arr__char__fun_mut1__ptr__char__arr__char(ctx* _ctx, arr__arr__char a, fun_mut1__ptr__char__arr__char mapper);
ptr__char call__ptr__char__fun_mut1__ptr__char__arr__char__arr__char(ctx* _ctx, fun_mut1__ptr__char__arr__char f, arr__char p0);
ptr__char call_with_ctx__ptr__char__ptr_ctx__fun_mut1__ptr__char__arr__char__arr__char(ctx* c, fun_mut1__ptr__char__arr__char f, arr__char p0);
ptr__char call__ptr__char__fun_ptr3__ptr__char__ptr_ctx__ptr__byte__arr__char__ptr_ctx__ptr__byte__arr__char(fun_ptr3__ptr__char__ptr_ctx__ptr__byte__arr__char f, ctx* p0, ptr__byte p1, arr__char p2);
ptr__char map__arr__ptr__char__arr__arr__char__fun_mut1__ptr__char__arr__char__lambda0(ctx* _ctx, map__arr__ptr__char__arr__arr__char__fun_mut1__ptr__char__arr__char__lambda0___closure* _closure, nat i);
ptr__char convert_args__ptr__ptr__char__ptr__char__arr__arr__char__lambda0(ctx* _ctx, ptr__byte _closure, arr__char it);
ptr__ptr__char convert_environ__ptr__ptr__char__ptr_dict__arr__char__arr__char(ctx* _ctx, dict__arr__char__arr__char* environ);
mut_arr__ptr__char* new_mut_arr__ptr_mut_arr__ptr__char(ctx* _ctx);
ptr__ptr__char null__ptr__ptr__char();
_void each___void__ptr_dict__arr__char__arr__char__fun_mut2___void__arr__char__arr__char(ctx* _ctx, dict__arr__char__arr__char* d, fun_mut2___void__arr__char__arr__char f);
bool empty__q__bool__ptr_dict__arr__char__arr__char(ctx* _ctx, dict__arr__char__arr__char* d);
_void call___void__fun_mut2___void__arr__char__arr__char__arr__char__arr__char(ctx* _ctx, fun_mut2___void__arr__char__arr__char f, arr__char p0, arr__char p1);
_void call_with_ctx___void__ptr_ctx__fun_mut2___void__arr__char__arr__char__arr__char__arr__char(ctx* c, fun_mut2___void__arr__char__arr__char f, arr__char p0, arr__char p1);
_void call___void__fun_ptr4___void__ptr_ctx__ptr__byte__arr__char__arr__char__ptr_ctx__ptr__byte__arr__char__arr__char(fun_ptr4___void__ptr_ctx__ptr__byte__arr__char__arr__char f, ctx* p0, ptr__byte p1, arr__char p2, arr__char p3);
_void push___void__ptr_mut_arr__ptr__char__ptr__char(ctx* _ctx, mut_arr__ptr__char* a, ptr__char value);
_void increase_capacity_to___void__ptr_mut_arr__ptr__char__nat(ctx* _ctx, mut_arr__ptr__char* a, nat new_capacity);
_void copy_data_from___void__ptr__ptr__char__ptr__ptr__char__nat(ctx* _ctx, ptr__ptr__char to, ptr__ptr__char from, nat len);
_void copy_data_from_small___void__ptr__ptr__char__ptr__ptr__char__nat(ctx* _ctx, ptr__ptr__char to, ptr__ptr__char from, nat len);
_void ensure_capacity___void__ptr_mut_arr__ptr__char__nat(ctx* _ctx, mut_arr__ptr__char* a, nat capacity);
_void convert_environ__ptr__ptr__char__ptr_dict__arr__char__arr__char__lambda0(ctx* _ctx, convert_environ__ptr__ptr__char__ptr_dict__arr__char__arr__char__lambda0___closure* _closure, arr__char key, arr__char value);
process_result* fail__ptr_process_result__arr__char(ctx* _ctx, arr__char reason);
process_result* throw__ptr_process_result__exception(ctx* _ctx, exception e);
process_result* todo__ptr_process_result();
process_result* hard_fail__ptr_process_result__arr__char(arr__char reason);
arr__char remove_colors__arr__char__arr__char(ctx* _ctx, arr__char s);
_void remove_colors_recur___void__arr__char__ptr_mut_arr__char(ctx* _ctx, arr__char s, mut_arr__char* out);
_void remove_colors_recur_2___void__arr__char__ptr_mut_arr__char(ctx* _ctx, arr__char s, mut_arr__char* out);
_void push___void__ptr_mut_arr__char__char(ctx* _ctx, mut_arr__char* a, char value);
arr__ptr_failure handle_output__arr__ptr_failure__arr__char__arr__char__arr__char__bool(ctx* _ctx, arr__char original_path, arr__char output_path, arr__char actual, bool overwrite_output__q);
opt__arr__char try_read_file__opt__arr__char__arr__char(ctx* _ctx, arr__char path);
opt__arr__char try_read_file__opt__arr__char__ptr__char(ctx* _ctx, ptr__char path);
extern int32 open(ptr__char path, int32 oflag, int32 permission);
int32 o_rdonly__int32(ctx* _ctx);
opt__arr__char todo__opt__arr__char();
opt__arr__char hard_fail__opt__arr__char__arr__char(arr__char reason);
extern _int lseek(int32 f, _int offset, int32 whence);
int32 seek_end__int32(ctx* _ctx);
_int billion___int();
bool zero__q__bool___int(_int i);
int32 seek_set__int32(ctx* _ctx);
ptr__byte ptr_cast__ptr__byte__ptr__char(ptr__char p);
_void write_file___void__arr__char__arr__char(ctx* _ctx, arr__char path, arr__char content);
_void write_file___void__ptr__char__arr__char(ctx* _ctx, ptr__char path, arr__char content);
int32 as__int32__int32(int32 value);
int32 bits_or__int32__int32__int32(int32 a, int32 b);
int32 bit_lshift__int32__int32__int32(int32 a, int32 b);
int32 o_creat__int32(ctx* _ctx);
int32 o_wronly__int32(ctx* _ctx);
int32 o_trunc__int32(ctx* _ctx);
arr__ptr_failure empty_arr__arr__ptr_failure();
bool large_strings_eq__q__bool__arr__char__arr__char(ctx* _ctx, arr__char a, arr__char b);
arr__ptr_failure run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0(ctx* _ctx, run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0___closure* _closure, arr__char test);
bool has__q__bool__arr__ptr_failure(arr__ptr_failure a);
err__arr__ptr_failure err__err__arr__ptr_failure__arr__ptr_failure(arr__ptr_failure t);
arr__ptr_failure with_max_size__arr__ptr_failure__arr__ptr_failure__nat(ctx* _ctx, arr__ptr_failure a, nat max_size);
ok__arr__char ok__ok__arr__char__arr__char(arr__char t);
result__arr__char__arr__ptr_failure first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure(ctx* _ctx, result__arr__char__arr__ptr_failure a, fun0__result__arr__char__arr__ptr_failure b);
result__arr__char__arr__ptr_failure then__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun_mut1__result__arr__char__arr__ptr_failure__arr__char(ctx* _ctx, result__arr__char__arr__ptr_failure a, fun_mut1__result__arr__char__arr__ptr_failure__arr__char f);
result__arr__char__arr__ptr_failure call__result__arr__char__arr__ptr_failure__fun_mut1__result__arr__char__arr__ptr_failure__arr__char__arr__char(ctx* _ctx, fun_mut1__result__arr__char__arr__ptr_failure__arr__char f, arr__char p0);
result__arr__char__arr__ptr_failure call_with_ctx__result__arr__char__arr__ptr_failure__ptr_ctx__fun_mut1__result__arr__char__arr__ptr_failure__arr__char__arr__char(ctx* c, fun_mut1__result__arr__char__arr__ptr_failure__arr__char f, arr__char p0);
result__arr__char__arr__ptr_failure call__result__arr__char__arr__ptr_failure__fun_ptr3__result__arr__char__arr__ptr_failure__ptr_ctx__ptr__byte__arr__char__ptr_ctx__ptr__byte__arr__char(fun_ptr3__result__arr__char__arr__ptr_failure__ptr_ctx__ptr__byte__arr__char f, ctx* p0, ptr__byte p1, arr__char p2);
result__arr__char__arr__ptr_failure call__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure(ctx* _ctx, fun0__result__arr__char__arr__ptr_failure f);
result__arr__char__arr__ptr_failure call_with_ctx__result__arr__char__arr__ptr_failure__ptr_ctx__fun0__result__arr__char__arr__ptr_failure(ctx* c, fun0__result__arr__char__arr__ptr_failure f);
result__arr__char__arr__ptr_failure call__result__arr__char__arr__ptr_failure__fun_ptr2__result__arr__char__arr__ptr_failure__ptr_ctx__ptr__byte__ptr_ctx__ptr__byte(fun_ptr2__result__arr__char__arr__ptr_failure__ptr_ctx__ptr__byte f, ctx* p0, ptr__byte p1);
result__arr__char__arr__ptr_failure first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure__lambda0__lambda0(ctx* _ctx, first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure__lambda0__lambda0___closure* _closure, arr__char b_descr);
result__arr__char__arr__ptr_failure first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure__lambda0(ctx* _ctx, first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure__lambda0___closure* _closure, arr__char a_descr);
result__arr__char__arr__ptr_failure run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options(ctx* _ctx, arr__char path, arr__char path_to_noze, dict__arr__char__arr__char* env, test_options options);
arr__arr__char list_ast_and_model_tests__arr__arr__char__arr__char(ctx* _ctx, arr__char path);
bool list_ast_and_model_tests__arr__arr__char__arr__char__lambda0(ctx* _ctx, ptr__byte _closure, arr__char s);
_void list_ast_and_model_tests__arr__arr__char__arr__char__lambda1(ctx* _ctx, list_ast_and_model_tests__arr__arr__char__arr__char__lambda1___closure* _closure, arr__char child);
arr__ptr_failure arr_or__arr__ptr_failure__arr__ptr_failure__fun_mut0__arr__ptr_failure(ctx* _ctx, arr__ptr_failure a, fun_mut0__arr__ptr_failure b);
arr__ptr_failure if__arr__ptr_failure__bool__arr__ptr_failure__arr__ptr_failure(bool cond, arr__ptr_failure if_true, arr__ptr_failure if_false);
arr__ptr_failure call__arr__ptr_failure__fun_mut0__arr__ptr_failure(ctx* _ctx, fun_mut0__arr__ptr_failure f);
arr__ptr_failure call_with_ctx__arr__ptr_failure__ptr_ctx__fun_mut0__arr__ptr_failure(ctx* c, fun_mut0__arr__ptr_failure f);
arr__ptr_failure call__arr__ptr_failure__fun_ptr2__arr__ptr_failure__ptr_ctx__ptr__byte__ptr_ctx__ptr__byte(fun_ptr2__arr__ptr_failure__ptr_ctx__ptr__byte f, ctx* p0, ptr__byte p1);
arr__ptr_failure run_single_ast_or_model_test__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__arr__char__bool(ctx* _ctx, arr__char ast_or_model, arr__char path_to_noze, dict__arr__char__arr__char* env, arr__char path, bool overwrite_output__q);
arr__ptr_failure run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0__lambda0__lambda0(ctx* _ctx, run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0__lambda0__lambda0___closure* _closure);
arr__ptr_failure run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0__lambda0(ctx* _ctx, run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0__lambda0___closure* _closure);
arr__ptr_failure run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0(ctx* _ctx, run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0___closure* _closure, arr__char test);
result__arr__char__arr__ptr_failure run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options(ctx* _ctx, arr__char path, arr__char path_to_noze, dict__arr__char__arr__char* env, test_options options);
arr__arr__char list_runnable_tests__arr__arr__char__arr__char(ctx* _ctx, arr__char path);
bool list_runnable_tests__arr__arr__char__arr__char__lambda0(ctx* _ctx, ptr__byte _closure, arr__char s);
_void list_runnable_tests__arr__arr__char__arr__char__lambda1(ctx* _ctx, list_runnable_tests__arr__arr__char__arr__char__lambda1___closure* _closure, arr__char child);
arr__ptr_failure run_single_runnable_test__arr__ptr_failure__arr__char__ptr_dict__arr__char__arr__char__arr__char__bool(ctx* _ctx, arr__char path_to_noze, dict__arr__char__arr__char* env, arr__char path, bool overwrite_output__q);
arr__ptr_failure run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0(ctx* _ctx, run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0___closure* _closure, arr__char test);
result__arr__char__arr__ptr_failure do_test__int32__test_options__lambda0__lambda0(ctx* _ctx, do_test__int32__test_options__lambda0__lambda0___closure* _closure);
result__arr__char__arr__ptr_failure do_test__int32__test_options__lambda0(ctx* _ctx, do_test__int32__test_options__lambda0___closure* _closure);
result__arr__char__arr__ptr_failure lint__result__arr__char__arr__ptr_failure__arr__char__test_options(ctx* _ctx, arr__char path, test_options options);
arr__arr__char list_lintable_files__arr__arr__char__arr__char(ctx* _ctx, arr__char path);
bool list_lintable_files__arr__arr__char__arr__char__lambda0(ctx* _ctx, ptr__byte _closure, arr__char it);
bool ignore_extension_of_name__bool__arr__char(ctx* _ctx, arr__char name);
bool ignore_extension__bool__arr__char(ctx* _ctx, arr__char ext);
bool contains__q__bool__arr__arr__char__arr__char(arr__arr__char a, arr__char value);
bool contains_recur__q__bool__arr__arr__char__arr__char__nat(arr__arr__char a, arr__char value, nat i);
arr__arr__char ignored_extensions__arr__arr__char(ctx* _ctx);
_void list_lintable_files__arr__arr__char__arr__char__lambda1(ctx* _ctx, list_lintable_files__arr__arr__char__arr__char__lambda1___closure* _closure, arr__char child);
arr__ptr_failure lint_file__arr__ptr_failure__arr__char(ctx* _ctx, arr__char path);
arr__char read_file__arr__char__arr__char(ctx* _ctx, arr__char path);
_void each_with_index___void__arr__arr__char__fun_mut2___void__arr__char__nat(ctx* _ctx, arr__arr__char a, fun_mut2___void__arr__char__nat f);
_void each_with_index_recur___void__arr__arr__char__fun_mut2___void__arr__char__nat__nat(ctx* _ctx, arr__arr__char a, fun_mut2___void__arr__char__nat f, nat n);
_void call___void__fun_mut2___void__arr__char__nat__arr__char__nat(ctx* _ctx, fun_mut2___void__arr__char__nat f, arr__char p0, nat p1);
_void call_with_ctx___void__ptr_ctx__fun_mut2___void__arr__char__nat__arr__char__nat(ctx* c, fun_mut2___void__arr__char__nat f, arr__char p0, nat p1);
_void call___void__fun_ptr4___void__ptr_ctx__ptr__byte__arr__char__nat__ptr_ctx__ptr__byte__arr__char__nat(fun_ptr4___void__ptr_ctx__ptr__byte__arr__char__nat f, ctx* p0, ptr__byte p1, arr__char p2, nat p3);
arr__arr__char lines__arr__arr__char__arr__char(ctx* _ctx, arr__char s);
cell__nat* new_cell__ptr_cell__nat__nat(ctx* _ctx, nat value);
_void each_with_index___void__arr__char__fun_mut2___void__char__nat(ctx* _ctx, arr__char a, fun_mut2___void__char__nat f);
_void each_with_index_recur___void__arr__char__fun_mut2___void__char__nat__nat(ctx* _ctx, arr__char a, fun_mut2___void__char__nat f, nat n);
_void call___void__fun_mut2___void__char__nat__char__nat(ctx* _ctx, fun_mut2___void__char__nat f, char p0, nat p1);
_void call_with_ctx___void__ptr_ctx__fun_mut2___void__char__nat__char__nat(ctx* c, fun_mut2___void__char__nat f, char p0, nat p1);
_void call___void__fun_ptr4___void__ptr_ctx__ptr__byte__char__nat__ptr_ctx__ptr__byte__char__nat(fun_ptr4___void__ptr_ctx__ptr__byte__char__nat f, ctx* p0, ptr__byte p1, char p2, nat p3);
arr__char slice_from_to__arr__char__arr__char__nat__nat(ctx* _ctx, arr__char a, nat begin, nat end);
nat swap__nat__ptr_cell__nat__nat(cell__nat* c, nat v);
nat get__nat__ptr_cell__nat(cell__nat* c);
_void set___void__ptr_cell__nat__nat(cell__nat* c, nat v);
_void lines__arr__arr__char__arr__char__lambda0(ctx* _ctx, lines__arr__arr__char__arr__char__lambda0___closure* _closure, char c, nat index);
bool contains_subsequence__q__bool__arr__char__arr__char(ctx* _ctx, arr__char a, arr__char subseq);
bool has__q__bool__arr__char(arr__char a);
arr__char lstrip__arr__char__arr__char(ctx* _ctx, arr__char a);
nat line_len__nat__arr__char(ctx* _ctx, arr__char line);
nat n_tabs__nat__arr__char(ctx* _ctx, arr__char line);
nat tab_size__nat(ctx* _ctx);
nat max_line_length__nat(ctx* _ctx);
_void lint_file__arr__ptr_failure__arr__char__lambda0(ctx* _ctx, lint_file__arr__ptr_failure__arr__char__lambda0___closure* _closure, arr__char line, nat line_num);
arr__ptr_failure lint__result__arr__char__arr__ptr_failure__arr__char__test_options__lambda0(ctx* _ctx, lint__result__arr__char__arr__ptr_failure__arr__char__test_options__lambda0___closure* _closure, arr__char file);
result__arr__char__arr__ptr_failure do_test__int32__test_options__lambda1(ctx* _ctx, do_test__int32__test_options__lambda1___closure* _closure);
int32 print_failures__int32__result__arr__char__arr__ptr_failure__test_options(ctx* _ctx, result__arr__char__arr__ptr_failure failures, test_options options);
_void print_failure___void__ptr_failure(ctx* _ctx, failure* failure);
_void print_bold___void(ctx* _ctx);
_void print_reset___void(ctx* _ctx);
_void print_failures__int32__result__arr__char__arr__ptr_failure__test_options__lambda0(ctx* _ctx, ptr__byte _closure, failure* it);
int32 to_int32__int32__nat(ctx* _ctx, nat n);
int32 rt_main__int32__int32__ptr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char(int32 argc, ptr__ptr__char argv, fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char main_ptr) {
	nat n_threads;
	global_ctx gctx_by_val;
	global_ctx* gctx;
	vat vat_by_val;
	vat* vat;
	arr__ptr_vat vats;
	exception_ctx ectx;
	thread_local_stuff tls;
	ctx ctx_by_val;
	ctx* ctx;
	fun2__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char add;
	arr__ptr__char all_args;
	fut__int32* main_fut;
	ok__int32 o;
	err__exception e;
	result__int32__exception matched;
	return ((n_threads = two__nat()),
	((gctx_by_val = (global_ctx) {new_lock__lock(), empty_arr__arr__ptr_vat(), n_threads, new_condition__condition(), 0, 0}),
	((gctx = (&(gctx_by_val))),
	((vat_by_val = new_vat__vat__ptr_global_ctx__nat__nat(gctx, 0, n_threads)),
	((vat = (&(vat_by_val))),
	((vats = (arr__ptr_vat) {1, (&(vat))}),
	((gctx->vats = vats), 0,
	((ectx = new_exception_ctx__exception_ctx()),
	((tls = (thread_local_stuff) {(&(ectx))}),
	((ctx_by_val = new_ctx__ctx__ptr_global_ctx__ptr_thread_local_stuff__ptr_vat__nat(gctx, (&(tls)), vat, 0)),
	((ctx = (&(ctx_by_val))),
	((add = (fun2__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char) {
		(fun_ptr4__ptr_fut__int32__ptr_ctx__ptr__byte__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char) rt_main__int32__int32__ptr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__lambda0,
		(ptr__byte) NULL
	}),
	((all_args = (arr__ptr__char) {(nat) (_int) argc, argv}),
	((main_fut = call_with_ctx__ptr_fut__int32__ptr_ctx__fun2__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char(ctx, add, all_args, main_ptr)),
	(run_threads___void__nat__ptr_global_ctx__fun_ptr2___void__nat__ptr_global_ctx(n_threads, gctx, rt_main__int32__int32__ptr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__lambda1),
	gctx->any_unhandled_exceptions__q
		? 1
		: (matched = must_be_resolved__result__int32__exception__ptr_fut__int32(main_fut),
			matched.kind == 0
			? (o = matched.as_ok__int32,
			o.value
			): matched.kind == 1
			? (e = matched.as_err__exception,
			((print_err_sync_no_newline___void__arr__char((arr__char){13, "main failed: "}),
			print_err_sync___void__arr__char(e.value.message)),
			1)
			): _failint32()))))))))))))))));
}
nat two__nat() {
	return wrap_incr__nat__nat(1);
}
nat wrap_incr__nat__nat(nat a) {
	return (a + 1);
}
lock new_lock__lock() {
	return (lock) {new_atomic_bool___atomic_bool()};
}
_atomic_bool new_atomic_bool___atomic_bool() {
	return (_atomic_bool) {0};
}
arr__ptr_vat empty_arr__arr__ptr_vat() {
	return (arr__ptr_vat) {0, NULL};
}
condition new_condition__condition() {
	return (condition) {new_lock__lock(), 0};
}
vat new_vat__vat__ptr_global_ctx__nat__nat(global_ctx* gctx, nat id, nat max_threads) {
	mut_arr__nat actors;
	return ((actors = new_mut_arr_by_val_with_capacity_from_unmanaged_memory__mut_arr__nat__nat(max_threads)),
	(vat) {gctx, id, new_gc__gc(), new_lock__lock(), new_mut_bag__mut_bag__task(), actors, 0, new_thread_safe_counter__thread_safe_counter(), (fun_mut1___void__exception) {
		(fun_ptr3___void__ptr_ctx__ptr__byte__exception) new_vat__vat__ptr_global_ctx__nat__nat__lambda0,
		(ptr__byte) NULL
	}});
}
mut_arr__nat new_mut_arr_by_val_with_capacity_from_unmanaged_memory__mut_arr__nat__nat(nat capacity) {
	return (mut_arr__nat) {0, 0, capacity, unmanaged_alloc_elements__ptr__nat__nat(capacity)};
}
ptr__nat unmanaged_alloc_elements__ptr__nat__nat(nat size_elements) {
	ptr__byte bytes;
	return ((bytes = unmanaged_alloc_bytes__ptr__byte__nat((size_elements * sizeof(nat)))),
	(ptr__nat) bytes);
}
ptr__byte unmanaged_alloc_bytes__ptr__byte__nat(nat size) {
	ptr__byte res;
	return ((res = malloc(size)),
	(hard_forbid___void__bool(null__q__bool__ptr__byte(res)),
	res));
}
_void hard_forbid___void__bool(bool condition) {
	return hard_assert___void__bool(!(condition));
}
_void hard_assert___void__bool(bool condition) {
	return (condition ? 0 : hard_fail___void__arr__char((arr__char){17, "Assertion failed!"}));
}
_void hard_fail___void__arr__char(arr__char reason) {
	assert(0);
}
bool null__q__bool__ptr__byte(ptr__byte a) {
	return _op_equal_equal__bool__ptr__byte__ptr__byte(a, NULL);
}
bool _op_equal_equal__bool__ptr__byte__ptr__byte(ptr__byte a, ptr__byte b) {
	comparison matched;
	return (matched = _op_less_equal_greater__comparison__ptr__byte__ptr__byte(a, b),
		matched.kind == 0
		? 0
		: matched.kind == 1
		? 1
		: matched.kind == 2
		? 0
		: _failbool());
}
comparison _op_less_equal_greater__comparison__ptr__byte__ptr__byte(ptr__byte a, ptr__byte b) {
	return (a < b)
		? (comparison) { 0, .as_less = (less) { 0 } }
		: (b < a)
			? (comparison) { 2, .as_greater = (greater) { 0 } }
			: (comparison) { 1, .as_equal = (equal) { 0 } };
}
gc new_gc__gc() {
	return (gc) {new_lock__lock(), (opt__ptr_gc_ctx) { 0, .as_none = none__none() }, 0, 0, NULL, NULL};
}
none none__none() {
	return (none) { 0 };
}
mut_bag__task new_mut_bag__mut_bag__task() {
	return (mut_bag__task) {(opt__ptr_mut_bag_node__task) { 0, .as_none = none__none() }};
}
thread_safe_counter new_thread_safe_counter__thread_safe_counter() {
	return new_thread_safe_counter__thread_safe_counter__nat(0);
}
thread_safe_counter new_thread_safe_counter__thread_safe_counter__nat(nat init) {
	return (thread_safe_counter) {new_lock__lock(), init};
}
_void default_exception_handler___void__exception(ctx* _ctx, exception e) {
	return ((print_err_sync_no_newline___void__arr__char((arr__char){20, "uncaught exception: "}),
	print_err_sync___void__arr__char((empty__q__bool__arr__char(e.message) ? (arr__char){17, "<<empty message>>"} : e.message))),
	(get_gctx__ptr_global_ctx(_ctx)->any_unhandled_exceptions__q = 1), 0);
}
_void print_err_sync_no_newline___void__arr__char(arr__char s) {
	return write_sync_no_newline___void__int32__arr__char(stderr_fd__int32(), s);
}
_void write_sync_no_newline___void__int32__arr__char(int32 fd, arr__char s) {
	_int res;
	return (hard_assert___void__bool(_op_equal_equal__bool__nat__nat(sizeof(char), sizeof(byte))),
	((res = write(fd, (ptr__byte) s.data, s.size)),
	_op_equal_equal__bool___int___int(res, (_int) s.size)
		? 0
		: todo___void()));
}
bool _op_equal_equal__bool__nat__nat(nat a, nat b) {
	comparison matched;
	return (matched = _op_less_equal_greater__comparison__nat__nat(a, b),
		matched.kind == 0
		? 0
		: matched.kind == 1
		? 1
		: matched.kind == 2
		? 0
		: _failbool());
}
comparison _op_less_equal_greater__comparison__nat__nat(nat a, nat b) {
	return (a < b)
		? (comparison) { 0, .as_less = (less) { 0 } }
		: (b < a)
			? (comparison) { 2, .as_greater = (greater) { 0 } }
			: (comparison) { 1, .as_equal = (equal) { 0 } };
}
bool _op_equal_equal__bool___int___int(_int a, _int b) {
	comparison matched;
	return (matched = _op_less_equal_greater__comparison___int___int(a, b),
		matched.kind == 0
		? 0
		: matched.kind == 1
		? 1
		: matched.kind == 2
		? 0
		: _failbool());
}
comparison _op_less_equal_greater__comparison___int___int(_int a, _int b) {
	return (a < b)
		? (comparison) { 0, .as_less = (less) { 0 } }
		: (b < a)
			? (comparison) { 2, .as_greater = (greater) { 0 } }
			: (comparison) { 1, .as_equal = (equal) { 0 } };
}
_void todo___void() {
	return hard_fail___void__arr__char((arr__char){4, "TODO"});
}
int32 stderr_fd__int32() {
	return two__int32();
}
int32 two__int32() {
	return wrap_incr__int32__int32(1);
}
int32 wrap_incr__int32__int32(int32 a) {
	return (a + 1);
}
_void print_err_sync___void__arr__char(arr__char s) {
	return (print_err_sync_no_newline___void__arr__char(s),
	print_err_sync_no_newline___void__arr__char((arr__char){1, "\n"}));
}
bool empty__q__bool__arr__char(arr__char a) {
	return zero__q__bool__nat(a.size);
}
bool zero__q__bool__nat(nat n) {
	return _op_equal_equal__bool__nat__nat(n, 0);
}
global_ctx* get_gctx__ptr_global_ctx(ctx* _ctx) {
	return (global_ctx*) _ctx->gctx_ptr;
}
_void new_vat__vat__ptr_global_ctx__nat__nat__lambda0(ctx* _ctx, ptr__byte _closure, exception it) {
	return default_exception_handler___void__exception(_ctx, it);
}
exception_ctx new_exception_ctx__exception_ctx() {
	return (exception_ctx) {NULL, (exception) {(arr__char){0, ""}}};
}
ctx new_ctx__ctx__ptr_global_ctx__ptr_thread_local_stuff__ptr_vat__nat(global_ctx* gctx, thread_local_stuff* tls, vat* vat, nat actor_id) {
	return (ctx) {(ptr__byte) gctx, vat->id, actor_id, (ptr__byte) get_gc_ctx__ptr_gc_ctx__ptr_gc((&(vat->gc))), (ptr__byte) tls->exception_ctx};
}
gc_ctx* get_gc_ctx__ptr_gc_ctx__ptr_gc(gc* gc) {
	gc_ctx* c;
	some__ptr_gc_ctx s;
	gc_ctx* c1;
	opt__ptr_gc_ctx matched;
	gc_ctx* res;
	return (acquire_lock___void__ptr_lock((&(gc->lk))),
	((res = (matched = gc->context_head,
		matched.kind == 0
		? ((c = (gc_ctx*) malloc(sizeof(gc_ctx*))),
		(((c->gc = gc), 0,
		(c->next_ctx = (opt__ptr_gc_ctx) { 0, .as_none = none__none() }), 0),
		c))
		: matched.kind == 1
		? (s = matched.as_some__ptr_gc_ctx,
		((c1 = s.value),
		(((gc->context_head = c1->next_ctx), 0,
		(c1->next_ctx = (opt__ptr_gc_ctx) { 0, .as_none = none__none() }), 0),
		c1))
		): _failVoidPtr())),
	(release_lock___void__ptr_lock((&(gc->lk))),
	res)));
}
_void acquire_lock___void__ptr_lock(lock* l) {
	return acquire_lock_recur___void__ptr_lock__nat(l, 0);
}
_void acquire_lock_recur___void__ptr_lock__nat(lock* l, nat n_tries) {
	return try_acquire_lock__bool__ptr_lock(l)
		? 0
		: _op_equal_equal__bool__nat__nat(n_tries, thousand__nat())
			? hard_fail___void__arr__char((arr__char){38, "Couldn\'t acquire lock after 1000 tries"})
			: (yield_thread___void(),
			acquire_lock_recur___void__ptr_lock__nat(l, noctx_incr__nat__nat(n_tries)));
}
bool try_acquire_lock__bool__ptr_lock(lock* l) {
	return try_set__bool__ptr__atomic_bool((&(l->is_locked)));
}
bool try_set__bool__ptr__atomic_bool(_atomic_bool* a) {
	return try_change__bool__ptr__atomic_bool__bool(a, 0);
}
bool try_change__bool__ptr__atomic_bool__bool(_atomic_bool* a, bool old_value) {
	return compare_exchange_strong__bool__ptr__bool__ptr__bool__bool((&(a->value)), (&(old_value)), !(old_value));
}
bool compare_exchange_strong__bool__ptr__bool__ptr__bool__bool(ptr__bool value_ptr, ptr__bool expected_ptr, bool desired) {
	return atomic_compare_exchange_strong(value_ptr, expected_ptr, desired);
}
nat thousand__nat() {
	return (hundred__nat() * ten__nat());
}
nat hundred__nat() {
	return (ten__nat() * ten__nat());
}
nat ten__nat() {
	return wrap_incr__nat__nat(nine__nat());
}
nat nine__nat() {
	return wrap_incr__nat__nat(eight__nat());
}
nat eight__nat() {
	return wrap_incr__nat__nat(seven__nat());
}
nat seven__nat() {
	return wrap_incr__nat__nat(six__nat());
}
nat six__nat() {
	return wrap_incr__nat__nat(five__nat());
}
nat five__nat() {
	return wrap_incr__nat__nat(four__nat());
}
nat four__nat() {
	return wrap_incr__nat__nat(three__nat());
}
nat three__nat() {
	return wrap_incr__nat__nat(two__nat());
}
_void yield_thread___void() {
	int32 err;
	return ((err = pthread_yield()),
	((usleep(thousand__nat()), 0),
	hard_assert___void__bool(zero__q__bool__int32(err))));
}
bool zero__q__bool__int32(int32 i) {
	return _op_equal_equal__bool__int32__int32(i, 0);
}
bool _op_equal_equal__bool__int32__int32(int32 a, int32 b) {
	comparison matched;
	return (matched = _op_less_equal_greater__comparison__int32__int32(a, b),
		matched.kind == 0
		? 0
		: matched.kind == 1
		? 1
		: matched.kind == 2
		? 0
		: _failbool());
}
comparison _op_less_equal_greater__comparison__int32__int32(int32 a, int32 b) {
	return (a < b)
		? (comparison) { 0, .as_less = (less) { 0 } }
		: (b < a)
			? (comparison) { 2, .as_greater = (greater) { 0 } }
			: (comparison) { 1, .as_equal = (equal) { 0 } };
}
nat noctx_incr__nat__nat(nat n) {
	return (hard_assert___void__bool(_op_less__bool__nat__nat(n, billion__nat())),
	wrap_incr__nat__nat(n));
}
bool _op_less__bool__nat__nat(nat a, nat b) {
	comparison matched;
	return (matched = _op_less_equal_greater__comparison__nat__nat(a, b),
		matched.kind == 0
		? 1
		: matched.kind == 1
		? 0
		: matched.kind == 2
		? 0
		: _failbool());
}
nat billion__nat() {
	return (million__nat() * thousand__nat());
}
nat million__nat() {
	return (thousand__nat() * thousand__nat());
}
_void release_lock___void__ptr_lock(lock* l) {
	return must_unset___void__ptr__atomic_bool((&(l->is_locked)));
}
_void must_unset___void__ptr__atomic_bool(_atomic_bool* a) {
	bool did_unset;
	return ((did_unset = try_unset__bool__ptr__atomic_bool(a)),
	hard_assert___void__bool(did_unset));
}
bool try_unset__bool__ptr__atomic_bool(_atomic_bool* a) {
	return try_change__bool__ptr__atomic_bool__bool(a, 1);
}
fut__int32* add_first_task__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char(ctx* _ctx, arr__ptr__char all_args, fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char main_ptr) {
	return then2__ptr_fut__int32__ptr_fut___void__fun_ref0__int32(_ctx, resolved__ptr_fut___void___void(_ctx, 0), (fun_ref0__int32) {cur_actor__vat_and_actor_id(_ctx), (fun_mut0__ptr_fut__int32) {
		(fun_ptr2__ptr_fut__int32__ptr_ctx__ptr__byte) add_first_task__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__lambda0,
		(ptr__byte) _initadd_first_task__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__lambda0___closure(alloc__ptr__byte__nat(_ctx, 24), (add_first_task__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__lambda0___closure) {all_args, main_ptr})
	}});
}
fut__int32* then2__ptr_fut__int32__ptr_fut___void__fun_ref0__int32(ctx* _ctx, fut___void* f, fun_ref0__int32 cb) {
	return then__ptr_fut__int32__ptr_fut___void__fun_ref1__int32___void(_ctx, f, (fun_ref1__int32___void) {cur_actor__vat_and_actor_id(_ctx), (fun_mut1__ptr_fut__int32___void) {
		(fun_ptr3__ptr_fut__int32__ptr_ctx__ptr__byte___void) then2__ptr_fut__int32__ptr_fut___void__fun_ref0__int32__lambda0,
		(ptr__byte) _initthen2__ptr_fut__int32__ptr_fut___void__fun_ref0__int32__lambda0___closure(alloc__ptr__byte__nat(_ctx, 32), (then2__ptr_fut__int32__ptr_fut___void__fun_ref0__int32__lambda0___closure) {cb})
	}});
}
fut__int32* then__ptr_fut__int32__ptr_fut___void__fun_ref1__int32___void(ctx* _ctx, fut___void* f, fun_ref1__int32___void cb) {
	fut__int32* res;
	return ((res = new_unresolved_fut__ptr_fut__int32(_ctx)),
	(then_void___void__ptr_fut___void__fun_mut1___void__result___void__exception(_ctx, f, (fun_mut1___void__result___void__exception) {
		(fun_ptr3___void__ptr_ctx__ptr__byte__result___void__exception) then__ptr_fut__int32__ptr_fut___void__fun_ref1__int32___void__lambda0,
		(ptr__byte) _initthen__ptr_fut__int32__ptr_fut___void__fun_ref1__int32___void__lambda0___closure(alloc__ptr__byte__nat(_ctx, 40), (then__ptr_fut__int32__ptr_fut___void__fun_ref1__int32___void__lambda0___closure) {cb, res})
	}),
	res));
}
fut__int32* new_unresolved_fut__ptr_fut__int32(ctx* _ctx) {
	return _initfut__int32(alloc__ptr__byte__nat(_ctx, 32), (fut__int32) {new_lock__lock(), (fut_state__int32) { 0, .as_fut_state_callbacks__int32 = (fut_state_callbacks__int32) {(opt__ptr_fut_callback_node__int32) { 0, .as_none = none__none() }} }});
}
ptr__byte alloc__ptr__byte__nat(ctx* _ctx, nat size) {
	return gc_alloc__ptr__byte__ptr_gc__nat(_ctx, get_gc__ptr_gc(_ctx), size);
}
ptr__byte gc_alloc__ptr__byte__ptr_gc__nat(ctx* _ctx, gc* gc, nat size) {
	some__ptr__byte s;
	opt__ptr__byte matched;
	return (matched = try_gc_alloc__opt__ptr__byte__ptr_gc__nat(gc, size),
		matched.kind == 0
		? todo__ptr__byte()
		: matched.kind == 1
		? (s = matched.as_some__ptr__byte,
		s.value
		): _failptr__byte());
}
opt__ptr__byte try_gc_alloc__opt__ptr__byte__ptr_gc__nat(gc* gc, nat size) {
	return (opt__ptr__byte) { 1, .as_some__ptr__byte = some__some__ptr__byte__ptr__byte(unmanaged_alloc_bytes__ptr__byte__nat(size)) };
}
some__ptr__byte some__some__ptr__byte__ptr__byte(ptr__byte t) {
	return (some__ptr__byte) {t};
}
ptr__byte todo__ptr__byte() {
	return hard_fail__ptr__byte__arr__char((arr__char){4, "TODO"});
}
ptr__byte hard_fail__ptr__byte__arr__char(arr__char reason) {
	assert(0);
}
gc* get_gc__ptr_gc(ctx* _ctx) {
	return get_gc_ctx__ptr_gc_ctx(_ctx)->gc;
}
gc_ctx* get_gc_ctx__ptr_gc_ctx(ctx* _ctx) {
	return (gc_ctx*) _ctx->gc_ctx_ptr;
}
_void then_void___void__ptr_fut___void__fun_mut1___void__result___void__exception(ctx* _ctx, fut___void* f, fun_mut1___void__result___void__exception cb) {
	fut_state_callbacks___void cbs;
	fut_state_resolved___void r;
	exception e;
	fut_state___void matched;
	return ((acquire_lock___void__ptr_lock((&(f->lk))),
	(matched = f->state,
		matched.kind == 0
		? (cbs = matched.as_fut_state_callbacks___void,
		(f->state = (fut_state___void) { 0, .as_fut_state_callbacks___void = (fut_state_callbacks___void) {(opt__ptr_fut_callback_node___void) { 1, .as_some__ptr_fut_callback_node___void = some__some__ptr_fut_callback_node___void__ptr_fut_callback_node___void(_initfut_callback_node___void(alloc__ptr__byte__nat(_ctx, 32), (fut_callback_node___void) {cb, cbs.head})) }} }), 0
		): matched.kind == 1
		? (r = matched.as_fut_state_resolved___void,
		call___void__fun_mut1___void__result___void__exception__result___void__exception(_ctx, cb, (result___void__exception) { 0, .as_ok___void = ok__ok___void___void(r.value) })
		): matched.kind == 2
		? (e = matched.as_exception,
		call___void__fun_mut1___void__result___void__exception__result___void__exception(_ctx, cb, (result___void__exception) { 1, .as_err__exception = err__err__exception__exception(e) })
		): _fail_void())),
	release_lock___void__ptr_lock((&(f->lk))));
}
some__ptr_fut_callback_node___void some__some__ptr_fut_callback_node___void__ptr_fut_callback_node___void(fut_callback_node___void* t) {
	return (some__ptr_fut_callback_node___void) {t};
}
_void call___void__fun_mut1___void__result___void__exception__result___void__exception(ctx* _ctx, fun_mut1___void__result___void__exception f, result___void__exception p0) {
	return call_with_ctx___void__ptr_ctx__fun_mut1___void__result___void__exception__result___void__exception(_ctx, f, p0);
}
_void call_with_ctx___void__ptr_ctx__fun_mut1___void__result___void__exception__result___void__exception(ctx* c, fun_mut1___void__result___void__exception f, result___void__exception p0) {
	return f.fun_ptr(c, f.closure, p0);
}
ok___void ok__ok___void___void(_void t) {
	return (ok___void) {t};
}
err__exception err__err__exception__exception(exception t) {
	return (err__exception) {t};
}
_void forward_to___void__ptr_fut__int32__ptr_fut__int32(ctx* _ctx, fut__int32* from, fut__int32* to) {
	return then_void___void__ptr_fut__int32__fun_mut1___void__result__int32__exception(_ctx, from, (fun_mut1___void__result__int32__exception) {
		(fun_ptr3___void__ptr_ctx__ptr__byte__result__int32__exception) forward_to___void__ptr_fut__int32__ptr_fut__int32__lambda0,
		(ptr__byte) _initforward_to___void__ptr_fut__int32__ptr_fut__int32__lambda0___closure(alloc__ptr__byte__nat(_ctx, 8), (forward_to___void__ptr_fut__int32__ptr_fut__int32__lambda0___closure) {to})
	});
}
_void then_void___void__ptr_fut__int32__fun_mut1___void__result__int32__exception(ctx* _ctx, fut__int32* f, fun_mut1___void__result__int32__exception cb) {
	fut_state_callbacks__int32 cbs;
	fut_state_resolved__int32 r;
	exception e;
	fut_state__int32 matched;
	return ((acquire_lock___void__ptr_lock((&(f->lk))),
	(matched = f->state,
		matched.kind == 0
		? (cbs = matched.as_fut_state_callbacks__int32,
		(f->state = (fut_state__int32) { 0, .as_fut_state_callbacks__int32 = (fut_state_callbacks__int32) {(opt__ptr_fut_callback_node__int32) { 1, .as_some__ptr_fut_callback_node__int32 = some__some__ptr_fut_callback_node__int32__ptr_fut_callback_node__int32(_initfut_callback_node__int32(alloc__ptr__byte__nat(_ctx, 32), (fut_callback_node__int32) {cb, cbs.head})) }} }), 0
		): matched.kind == 1
		? (r = matched.as_fut_state_resolved__int32,
		call___void__fun_mut1___void__result__int32__exception__result__int32__exception(_ctx, cb, (result__int32__exception) { 0, .as_ok__int32 = ok__ok__int32__int32(r.value) })
		): matched.kind == 2
		? (e = matched.as_exception,
		call___void__fun_mut1___void__result__int32__exception__result__int32__exception(_ctx, cb, (result__int32__exception) { 1, .as_err__exception = err__err__exception__exception(e) })
		): _fail_void())),
	release_lock___void__ptr_lock((&(f->lk))));
}
some__ptr_fut_callback_node__int32 some__some__ptr_fut_callback_node__int32__ptr_fut_callback_node__int32(fut_callback_node__int32* t) {
	return (some__ptr_fut_callback_node__int32) {t};
}
_void call___void__fun_mut1___void__result__int32__exception__result__int32__exception(ctx* _ctx, fun_mut1___void__result__int32__exception f, result__int32__exception p0) {
	return call_with_ctx___void__ptr_ctx__fun_mut1___void__result__int32__exception__result__int32__exception(_ctx, f, p0);
}
_void call_with_ctx___void__ptr_ctx__fun_mut1___void__result__int32__exception__result__int32__exception(ctx* c, fun_mut1___void__result__int32__exception f, result__int32__exception p0) {
	return f.fun_ptr(c, f.closure, p0);
}
ok__int32 ok__ok__int32__int32(int32 t) {
	return (ok__int32) {t};
}
_void resolve_or_reject___void__ptr_fut__int32__result__int32__exception(ctx* _ctx, fut__int32* f, result__int32__exception result) {
	fut_state_callbacks__int32 cbs;
	fut_state__int32 matched;
	ok__int32 o;
	err__exception e;
	result__int32__exception matched1;
	return (((acquire_lock___void__ptr_lock((&(f->lk))),
	(matched = f->state,
		matched.kind == 0
		? (cbs = matched.as_fut_state_callbacks__int32,
		resolve_or_reject_recur___void__opt__ptr_fut_callback_node__int32__result__int32__exception(_ctx, cbs.head, result)
		): matched.kind == 1
		? hard_fail___void__arr__char((arr__char){33, "resolving an already-resolved fut"})
		: matched.kind == 2
		? hard_fail___void__arr__char((arr__char){33, "resolving an already-resolved fut"})
		: _fail_void())),
	(f->state = (matched1 = result,
		matched1.kind == 0
		? (o = matched1.as_ok__int32,
		(fut_state__int32) { 1, .as_fut_state_resolved__int32 = (fut_state_resolved__int32) {o.value} }
		): matched1.kind == 1
		? (e = matched1.as_err__exception,
		(fut_state__int32) { 2, .as_exception = e.value }
		): _failfut_state__int32())), 0),
	release_lock___void__ptr_lock((&(f->lk))));
}
_void resolve_or_reject_recur___void__opt__ptr_fut_callback_node__int32__result__int32__exception(ctx* _ctx, opt__ptr_fut_callback_node__int32 node, result__int32__exception value) {
	some__ptr_fut_callback_node__int32 s;
	opt__ptr_fut_callback_node__int32 matched;
	return (matched = node,
		matched.kind == 0
		? 0
		: matched.kind == 1
		? (s = matched.as_some__ptr_fut_callback_node__int32,
		(drop___void___void(call___void__fun_mut1___void__result__int32__exception__result__int32__exception(_ctx, s.value->cb, value)),
		resolve_or_reject_recur___void__opt__ptr_fut_callback_node__int32__result__int32__exception(_ctx, s.value->next_node, value))
		): _fail_void());
}
_void drop___void___void(_void t) {
	return 0;
}
_void forward_to___void__ptr_fut__int32__ptr_fut__int32__lambda0(ctx* _ctx, forward_to___void__ptr_fut__int32__ptr_fut__int32__lambda0___closure* _closure, result__int32__exception it) {
	return resolve_or_reject___void__ptr_fut__int32__result__int32__exception(_ctx, _closure->to, it);
}
fut__int32* call__ptr_fut__int32__fun_ref1__int32___void___void(ctx* _ctx, fun_ref1__int32___void f, _void p0) {
	vat* vat;
	fut__int32* res;
	return ((vat = get_vat__ptr_vat__nat(_ctx, f.vat_and_actor.vat)),
	((res = new_unresolved_fut__ptr_fut__int32(_ctx)),
	(add_task___void__ptr_vat__task(_ctx, vat, (task) {f.vat_and_actor.actor, (fun_mut0___void) {
		(fun_ptr2___void__ptr_ctx__ptr__byte) call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0,
		(ptr__byte) _initcall__ptr_fut__int32__fun_ref1__int32___void___void__lambda0___closure(alloc__ptr__byte__nat(_ctx, 48), (call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0___closure) {f, p0, res})
	}}),
	res)));
}
vat* get_vat__ptr_vat__nat(ctx* _ctx, nat vat_id) {
	return at__ptr_vat__arr__ptr_vat__nat(_ctx, get_gctx__ptr_global_ctx(_ctx)->vats, vat_id);
}
vat* at__ptr_vat__arr__ptr_vat__nat(ctx* _ctx, arr__ptr_vat a, nat index) {
	return (assert___void__bool(_ctx, _op_less__bool__nat__nat(index, a.size)),
	noctx_at__ptr_vat__arr__ptr_vat__nat(a, index));
}
_void assert___void__bool(ctx* _ctx, bool condition) {
	return assert___void__bool__arr__char(_ctx, condition, (arr__char){13, "assert failed"});
}
_void assert___void__bool__arr__char(ctx* _ctx, bool condition, arr__char message) {
	return (condition ? 0 : fail___void__arr__char(_ctx, message));
}
_void fail___void__arr__char(ctx* _ctx, arr__char reason) {
	return throw___void__exception(_ctx, (exception) {reason});
}
_void throw___void__exception(ctx* _ctx, exception e) {
	exception_ctx* exn_ctx;
	return ((exn_ctx = get_exception_ctx__ptr_exception_ctx(_ctx)),
	(((hard_forbid___void__bool(_op_equal_equal__bool__ptr__jmp_buf_tag__ptr__jmp_buf_tag(exn_ctx->jmp_buf_ptr, NULL)),
	(exn_ctx->thrown_exception = e), 0),
	(longjmp(exn_ctx->jmp_buf_ptr, number_to_throw__int32(_ctx)), 0)),
	todo___void()));
}
exception_ctx* get_exception_ctx__ptr_exception_ctx(ctx* _ctx) {
	return (exception_ctx*) _ctx->exception_ctx_ptr;
}
bool _op_equal_equal__bool__ptr__jmp_buf_tag__ptr__jmp_buf_tag(ptr__jmp_buf_tag a, ptr__jmp_buf_tag b) {
	comparison matched;
	return (matched = _op_less_equal_greater__comparison__ptr__jmp_buf_tag__ptr__jmp_buf_tag(a, b),
		matched.kind == 0
		? 0
		: matched.kind == 1
		? 1
		: matched.kind == 2
		? 0
		: _failbool());
}
comparison _op_less_equal_greater__comparison__ptr__jmp_buf_tag__ptr__jmp_buf_tag(ptr__jmp_buf_tag a, ptr__jmp_buf_tag b) {
	return (a < b)
		? (comparison) { 0, .as_less = (less) { 0 } }
		: (b < a)
			? (comparison) { 2, .as_greater = (greater) { 0 } }
			: (comparison) { 1, .as_equal = (equal) { 0 } };
}
int32 number_to_throw__int32(ctx* _ctx) {
	return seven__int32();
}
int32 seven__int32() {
	return wrap_incr__int32__int32(six__int32());
}
int32 six__int32() {
	return wrap_incr__int32__int32(five__int32());
}
int32 five__int32() {
	return wrap_incr__int32__int32(four__int32());
}
int32 four__int32() {
	return wrap_incr__int32__int32(three__int32());
}
int32 three__int32() {
	return wrap_incr__int32__int32(two__int32());
}
vat* noctx_at__ptr_vat__arr__ptr_vat__nat(arr__ptr_vat a, nat index) {
	return (hard_assert___void__bool(_op_less__bool__nat__nat(index, a.size)),
	*((a.data + index)));
}
_void add_task___void__ptr_vat__task(ctx* _ctx, vat* v, task t) {
	mut_bag_node__task* node;
	return ((node = new_mut_bag_node__ptr_mut_bag_node__task__task(_ctx, t)),
	(((acquire_lock___void__ptr_lock((&(v->tasks_lock))),
	add___void__ptr_mut_bag__task__ptr_mut_bag_node__task((&(v->tasks)), node)),
	release_lock___void__ptr_lock((&(v->tasks_lock)))),
	broadcast___void__ptr_condition((&(v->gctx->may_be_work_to_do)))));
}
mut_bag_node__task* new_mut_bag_node__ptr_mut_bag_node__task__task(ctx* _ctx, task value) {
	return _initmut_bag_node__task(alloc__ptr__byte__nat(_ctx, 40), (mut_bag_node__task) {value, (opt__ptr_mut_bag_node__task) { 0, .as_none = none__none() }});
}
_void add___void__ptr_mut_bag__task__ptr_mut_bag_node__task(mut_bag__task* bag, mut_bag_node__task* node) {
	return ((node->next_node = bag->head), 0,
	(bag->head = (opt__ptr_mut_bag_node__task) { 1, .as_some__ptr_mut_bag_node__task = some__some__ptr_mut_bag_node__task__ptr_mut_bag_node__task(node) }), 0);
}
some__ptr_mut_bag_node__task some__some__ptr_mut_bag_node__task__ptr_mut_bag_node__task(mut_bag_node__task* t) {
	return (some__ptr_mut_bag_node__task) {t};
}
_void broadcast___void__ptr_condition(condition* c) {
	return ((acquire_lock___void__ptr_lock((&(c->lk))),
	(c->value = noctx_incr__nat__nat(c->value)), 0),
	release_lock___void__ptr_lock((&(c->lk))));
}
_void catch___void__fun_mut0___void__fun_mut1___void__exception(ctx* _ctx, fun_mut0___void try, fun_mut1___void__exception catcher) {
	return catch_with_exception_ctx___void__ptr_exception_ctx__fun_mut0___void__fun_mut1___void__exception(_ctx, get_exception_ctx__ptr_exception_ctx(_ctx), try, catcher);
}
_void catch_with_exception_ctx___void__ptr_exception_ctx__fun_mut0___void__fun_mut1___void__exception(ctx* _ctx, exception_ctx* ec, fun_mut0___void try, fun_mut1___void__exception catcher) {
	exception old_thrown_exception;
	ptr__jmp_buf_tag old_jmp_buf;
	jmp_buf_tag store;
	int32 setjmp_result;
	_void res;
	exception thrown_exception;
	return ((old_thrown_exception = ec->thrown_exception),
	((old_jmp_buf = ec->jmp_buf_ptr),
	((store = (jmp_buf_tag) {zero__bytes64(), 0, zero__bytes128()}),
	((ec->jmp_buf_ptr = (&(store))), 0,
	((setjmp_result = setjmp(ec->jmp_buf_ptr)),
	_op_equal_equal__bool__int32__int32(setjmp_result, 0)
		? ((res = call___void__fun_mut0___void(_ctx, try)),
		(((ec->jmp_buf_ptr = old_jmp_buf), 0,
		(ec->thrown_exception = old_thrown_exception), 0),
		res))
		: (assert___void__bool(_ctx, _op_equal_equal__bool__int32__int32(setjmp_result, number_to_throw__int32(_ctx))),
		((thrown_exception = ec->thrown_exception),
		(((ec->jmp_buf_ptr = old_jmp_buf), 0,
		(ec->thrown_exception = old_thrown_exception), 0),
		call___void__fun_mut1___void__exception__exception(_ctx, catcher, thrown_exception)))))))));
}
bytes64 zero__bytes64() {
	return (bytes64) {zero__bytes32(), zero__bytes32()};
}
bytes32 zero__bytes32() {
	return (bytes32) {zero__bytes16(), zero__bytes16()};
}
bytes16 zero__bytes16() {
	return (bytes16) {0, 0};
}
bytes128 zero__bytes128() {
	return (bytes128) {zero__bytes64(), zero__bytes64()};
}
_void call___void__fun_mut0___void(ctx* _ctx, fun_mut0___void f) {
	return call_with_ctx___void__ptr_ctx__fun_mut0___void(_ctx, f);
}
_void call_with_ctx___void__ptr_ctx__fun_mut0___void(ctx* c, fun_mut0___void f) {
	return f.fun_ptr(c, f.closure);
}
_void call___void__fun_mut1___void__exception__exception(ctx* _ctx, fun_mut1___void__exception f, exception p0) {
	return call_with_ctx___void__ptr_ctx__fun_mut1___void__exception__exception(_ctx, f, p0);
}
_void call_with_ctx___void__ptr_ctx__fun_mut1___void__exception__exception(ctx* c, fun_mut1___void__exception f, exception p0) {
	return f.fun_ptr(c, f.closure, p0);
}
fut__int32* call__ptr_fut__int32__fun_mut1__ptr_fut__int32___void___void(ctx* _ctx, fun_mut1__ptr_fut__int32___void f, _void p0) {
	return call_with_ctx__ptr_fut__int32__ptr_ctx__fun_mut1__ptr_fut__int32___void___void(_ctx, f, p0);
}
fut__int32* call_with_ctx__ptr_fut__int32__ptr_ctx__fun_mut1__ptr_fut__int32___void___void(ctx* c, fun_mut1__ptr_fut__int32___void f, _void p0) {
	return f.fun_ptr(c, f.closure, p0);
}
_void call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0__lambda0(ctx* _ctx, call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0__lambda0___closure* _closure) {
	return forward_to___void__ptr_fut__int32__ptr_fut__int32(_ctx, call__ptr_fut__int32__fun_mut1__ptr_fut__int32___void___void(_ctx, _closure->f.fun, _closure->p0), _closure->res);
}
_void reject___void__ptr_fut__int32__exception(ctx* _ctx, fut__int32* f, exception e) {
	return resolve_or_reject___void__ptr_fut__int32__result__int32__exception(_ctx, f, (result__int32__exception) { 1, .as_err__exception = err__err__exception__exception(e) });
}
_void call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0__lambda1(ctx* _ctx, call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0__lambda1___closure* _closure, exception it) {
	return reject___void__ptr_fut__int32__exception(_ctx, _closure->res, it);
}
_void call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0(ctx* _ctx, call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0___closure* _closure) {
	return catch___void__fun_mut0___void__fun_mut1___void__exception(_ctx, (fun_mut0___void) {
		(fun_ptr2___void__ptr_ctx__ptr__byte) call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0__lambda0,
		(ptr__byte) _initcall__ptr_fut__int32__fun_ref1__int32___void___void__lambda0__lambda0___closure(alloc__ptr__byte__nat(_ctx, 48), (call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0__lambda0___closure) {_closure->f, _closure->p0, _closure->res})
	}, (fun_mut1___void__exception) {
		(fun_ptr3___void__ptr_ctx__ptr__byte__exception) call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0__lambda1,
		(ptr__byte) _initcall__ptr_fut__int32__fun_ref1__int32___void___void__lambda0__lambda1___closure(alloc__ptr__byte__nat(_ctx, 8), (call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0__lambda1___closure) {_closure->res})
	});
}
_void then__ptr_fut__int32__ptr_fut___void__fun_ref1__int32___void__lambda0(ctx* _ctx, then__ptr_fut__int32__ptr_fut___void__fun_ref1__int32___void__lambda0___closure* _closure, result___void__exception result) {
	ok___void o;
	err__exception e;
	result___void__exception matched;
	return (matched = result,
		matched.kind == 0
		? (o = matched.as_ok___void,
		forward_to___void__ptr_fut__int32__ptr_fut__int32(_ctx, call__ptr_fut__int32__fun_ref1__int32___void___void(_ctx, _closure->cb, o.value), _closure->res)
		): matched.kind == 1
		? (e = matched.as_err__exception,
		reject___void__ptr_fut__int32__exception(_ctx, _closure->res, e.value)
		): _fail_void());
}
fut__int32* call__ptr_fut__int32__fun_ref0__int32(ctx* _ctx, fun_ref0__int32 f) {
	vat* vat;
	fut__int32* res;
	return ((vat = get_vat__ptr_vat__nat(_ctx, f.vat_and_actor.vat)),
	((res = new_unresolved_fut__ptr_fut__int32(_ctx)),
	(add_task___void__ptr_vat__task(_ctx, vat, (task) {f.vat_and_actor.actor, (fun_mut0___void) {
		(fun_ptr2___void__ptr_ctx__ptr__byte) call__ptr_fut__int32__fun_ref0__int32__lambda0,
		(ptr__byte) _initcall__ptr_fut__int32__fun_ref0__int32__lambda0___closure(alloc__ptr__byte__nat(_ctx, 40), (call__ptr_fut__int32__fun_ref0__int32__lambda0___closure) {f, res})
	}}),
	res)));
}
fut__int32* call__ptr_fut__int32__fun_mut0__ptr_fut__int32(ctx* _ctx, fun_mut0__ptr_fut__int32 f) {
	return call_with_ctx__ptr_fut__int32__ptr_ctx__fun_mut0__ptr_fut__int32(_ctx, f);
}
fut__int32* call_with_ctx__ptr_fut__int32__ptr_ctx__fun_mut0__ptr_fut__int32(ctx* c, fun_mut0__ptr_fut__int32 f) {
	return f.fun_ptr(c, f.closure);
}
_void call__ptr_fut__int32__fun_ref0__int32__lambda0__lambda0(ctx* _ctx, call__ptr_fut__int32__fun_ref0__int32__lambda0__lambda0___closure* _closure) {
	return forward_to___void__ptr_fut__int32__ptr_fut__int32(_ctx, call__ptr_fut__int32__fun_mut0__ptr_fut__int32(_ctx, _closure->f.fun), _closure->res);
}
_void call__ptr_fut__int32__fun_ref0__int32__lambda0__lambda1(ctx* _ctx, call__ptr_fut__int32__fun_ref0__int32__lambda0__lambda1___closure* _closure, exception it) {
	return reject___void__ptr_fut__int32__exception(_ctx, _closure->res, it);
}
_void call__ptr_fut__int32__fun_ref0__int32__lambda0(ctx* _ctx, call__ptr_fut__int32__fun_ref0__int32__lambda0___closure* _closure) {
	return catch___void__fun_mut0___void__fun_mut1___void__exception(_ctx, (fun_mut0___void) {
		(fun_ptr2___void__ptr_ctx__ptr__byte) call__ptr_fut__int32__fun_ref0__int32__lambda0__lambda0,
		(ptr__byte) _initcall__ptr_fut__int32__fun_ref0__int32__lambda0__lambda0___closure(alloc__ptr__byte__nat(_ctx, 40), (call__ptr_fut__int32__fun_ref0__int32__lambda0__lambda0___closure) {_closure->f, _closure->res})
	}, (fun_mut1___void__exception) {
		(fun_ptr3___void__ptr_ctx__ptr__byte__exception) call__ptr_fut__int32__fun_ref0__int32__lambda0__lambda1,
		(ptr__byte) _initcall__ptr_fut__int32__fun_ref0__int32__lambda0__lambda1___closure(alloc__ptr__byte__nat(_ctx, 8), (call__ptr_fut__int32__fun_ref0__int32__lambda0__lambda1___closure) {_closure->res})
	});
}
fut__int32* then2__ptr_fut__int32__ptr_fut___void__fun_ref0__int32__lambda0(ctx* _ctx, then2__ptr_fut__int32__ptr_fut___void__fun_ref0__int32__lambda0___closure* _closure, _void ignore) {
	return call__ptr_fut__int32__fun_ref0__int32(_ctx, _closure->cb);
}
vat_and_actor_id cur_actor__vat_and_actor_id(ctx* _ctx) {
	ctx* c;
	return ((c = _ctx),
	(vat_and_actor_id) {c->vat_id, c->actor_id});
}
fut___void* resolved__ptr_fut___void___void(ctx* _ctx, _void value) {
	return _initfut___void(alloc__ptr__byte__nat(_ctx, 32), (fut___void) {new_lock__lock(), (fut_state___void) { 1, .as_fut_state_resolved___void = (fut_state_resolved___void) {value} }});
}
arr__ptr__char tail__arr__ptr__char__arr__ptr__char(ctx* _ctx, arr__ptr__char a) {
	return (forbid___void__bool(_ctx, empty__q__bool__arr__ptr__char(a)),
	slice_starting_at__arr__ptr__char__arr__ptr__char__nat(_ctx, a, 1));
}
_void forbid___void__bool(ctx* _ctx, bool condition) {
	return forbid___void__bool__arr__char(_ctx, condition, (arr__char){13, "forbid failed"});
}
_void forbid___void__bool__arr__char(ctx* _ctx, bool condition, arr__char message) {
	return (condition ? fail___void__arr__char(_ctx, message) : 0);
}
bool empty__q__bool__arr__ptr__char(arr__ptr__char a) {
	return zero__q__bool__nat(a.size);
}
arr__ptr__char slice_starting_at__arr__ptr__char__arr__ptr__char__nat(ctx* _ctx, arr__ptr__char a, nat begin) {
	return (assert___void__bool(_ctx, _op_less_equal__bool__nat__nat(begin, a.size)),
	slice__arr__ptr__char__arr__ptr__char__nat__nat(_ctx, a, begin, _op_minus__nat__nat__nat(_ctx, a.size, begin)));
}
bool _op_less_equal__bool__nat__nat(nat a, nat b) {
	return !(_op_less__bool__nat__nat(b, a));
}
arr__ptr__char slice__arr__ptr__char__arr__ptr__char__nat__nat(ctx* _ctx, arr__ptr__char a, nat begin, nat size) {
	return (assert___void__bool(_ctx, _op_less_equal__bool__nat__nat(_op_plus__nat__nat__nat(_ctx, begin, size), a.size)),
	(arr__ptr__char) {size, (a.data + begin)});
}
nat _op_plus__nat__nat__nat(ctx* _ctx, nat a, nat b) {
	nat res;
	return ((res = (a + b)),
	(assert___void__bool(_ctx, (_op_greater_equal__bool__nat__nat(res, a) && _op_greater_equal__bool__nat__nat(res, b))),
	res));
}
bool _op_greater_equal__bool__nat__nat(nat a, nat b) {
	return !(_op_less__bool__nat__nat(a, b));
}
nat _op_minus__nat__nat__nat(ctx* _ctx, nat a, nat b) {
	return (assert___void__bool(_ctx, _op_greater_equal__bool__nat__nat(a, b)),
	(a - b));
}
arr__arr__char map__arr__arr__char__arr__ptr__char__fun_mut1__arr__char__ptr__char(ctx* _ctx, arr__ptr__char a, fun_mut1__arr__char__ptr__char mapper) {
	return make_arr__arr__arr__char__nat__fun_mut1__arr__char__nat(_ctx, a.size, (fun_mut1__arr__char__nat) {
		(fun_ptr3__arr__char__ptr_ctx__ptr__byte__nat) map__arr__arr__char__arr__ptr__char__fun_mut1__arr__char__ptr__char__lambda0,
		(ptr__byte) _initmap__arr__arr__char__arr__ptr__char__fun_mut1__arr__char__ptr__char__lambda0___closure(alloc__ptr__byte__nat(_ctx, 32), (map__arr__arr__char__arr__ptr__char__fun_mut1__arr__char__ptr__char__lambda0___closure) {mapper, a})
	});
}
arr__arr__char make_arr__arr__arr__char__nat__fun_mut1__arr__char__nat(ctx* _ctx, nat size, fun_mut1__arr__char__nat f) {
	return freeze__arr__arr__char__ptr_mut_arr__arr__char(make_mut_arr__ptr_mut_arr__arr__char__nat__fun_mut1__arr__char__nat(_ctx, size, f));
}
arr__arr__char freeze__arr__arr__char__ptr_mut_arr__arr__char(mut_arr__arr__char* a) {
	return ((a->frozen__q = 1), 0,
	unsafe_as_arr__arr__arr__char__ptr_mut_arr__arr__char(a));
}
arr__arr__char unsafe_as_arr__arr__arr__char__ptr_mut_arr__arr__char(mut_arr__arr__char* a) {
	return (arr__arr__char) {a->size, a->data};
}
mut_arr__arr__char* make_mut_arr__ptr_mut_arr__arr__char__nat__fun_mut1__arr__char__nat(ctx* _ctx, nat size, fun_mut1__arr__char__nat f) {
	mut_arr__arr__char* res;
	return ((res = new_uninitialized_mut_arr__ptr_mut_arr__arr__char__nat(_ctx, size)),
	(make_mut_arr_worker___void__ptr_mut_arr__arr__char__nat__nat__fun_mut1__arr__char__nat(_ctx, res, 0, size, f),
	res));
}
mut_arr__arr__char* new_uninitialized_mut_arr__ptr_mut_arr__arr__char__nat(ctx* _ctx, nat size) {
	return _initmut_arr__arr__char(alloc__ptr__byte__nat(_ctx, 32), (mut_arr__arr__char) {0, size, size, uninitialized_data__ptr__arr__char__nat(_ctx, size)});
}
ptr__arr__char uninitialized_data__ptr__arr__char__nat(ctx* _ctx, nat size) {
	ptr__byte bptr;
	return ((bptr = alloc__ptr__byte__nat(_ctx, (size * sizeof(arr__char)))),
	(ptr__arr__char) bptr);
}
_void make_mut_arr_worker___void__ptr_mut_arr__arr__char__nat__nat__fun_mut1__arr__char__nat(ctx* _ctx, mut_arr__arr__char* m, nat lo, nat hi, fun_mut1__arr__char__nat f) {
	nat mid;
	return _op_equal_equal__bool__nat__nat(lo, hi)
		? 0
		: (set_at___void__ptr_mut_arr__arr__char__nat__arr__char(_ctx, m, lo, call__arr__char__fun_mut1__arr__char__nat__nat(_ctx, f, lo)),
		((mid = _op_div__nat__nat__nat(_ctx, _op_plus__nat__nat__nat(_ctx, incr__nat__nat(_ctx, lo), hi), two__nat())),
		(make_mut_arr_worker___void__ptr_mut_arr__arr__char__nat__nat__fun_mut1__arr__char__nat(_ctx, m, incr__nat__nat(_ctx, lo), mid, f),
		make_mut_arr_worker___void__ptr_mut_arr__arr__char__nat__nat__fun_mut1__arr__char__nat(_ctx, m, mid, hi, f))));
}
_void set_at___void__ptr_mut_arr__arr__char__nat__arr__char(ctx* _ctx, mut_arr__arr__char* a, nat index, arr__char value) {
	return (assert___void__bool(_ctx, _op_less__bool__nat__nat(index, a->size)),
	noctx_set_at___void__ptr_mut_arr__arr__char__nat__arr__char(a, index, value));
}
_void noctx_set_at___void__ptr_mut_arr__arr__char__nat__arr__char(mut_arr__arr__char* a, nat index, arr__char value) {
	return (hard_assert___void__bool(_op_less__bool__nat__nat(index, a->size)),
	((*((a->data + index)) = value), 0));
}
arr__char call__arr__char__fun_mut1__arr__char__nat__nat(ctx* _ctx, fun_mut1__arr__char__nat f, nat p0) {
	return call_with_ctx__arr__char__ptr_ctx__fun_mut1__arr__char__nat__nat(_ctx, f, p0);
}
arr__char call_with_ctx__arr__char__ptr_ctx__fun_mut1__arr__char__nat__nat(ctx* c, fun_mut1__arr__char__nat f, nat p0) {
	return f.fun_ptr(c, f.closure, p0);
}
nat _op_div__nat__nat__nat(ctx* _ctx, nat a, nat b) {
	return (forbid___void__bool(_ctx, zero__q__bool__nat(b)),
	(a / b));
}
nat incr__nat__nat(ctx* _ctx, nat n) {
	return (assert___void__bool(_ctx, _op_less__bool__nat__nat(n, billion__nat())),
	(n + 1));
}
arr__char call__arr__char__fun_mut1__arr__char__ptr__char__ptr__char(ctx* _ctx, fun_mut1__arr__char__ptr__char f, ptr__char p0) {
	return call_with_ctx__arr__char__ptr_ctx__fun_mut1__arr__char__ptr__char__ptr__char(_ctx, f, p0);
}
arr__char call_with_ctx__arr__char__ptr_ctx__fun_mut1__arr__char__ptr__char__ptr__char(ctx* c, fun_mut1__arr__char__ptr__char f, ptr__char p0) {
	return f.fun_ptr(c, f.closure, p0);
}
ptr__char at__ptr__char__arr__ptr__char__nat(ctx* _ctx, arr__ptr__char a, nat index) {
	return (assert___void__bool(_ctx, _op_less__bool__nat__nat(index, a.size)),
	noctx_at__ptr__char__arr__ptr__char__nat(a, index));
}
ptr__char noctx_at__ptr__char__arr__ptr__char__nat(arr__ptr__char a, nat index) {
	return (hard_assert___void__bool(_op_less__bool__nat__nat(index, a.size)),
	*((a.data + index)));
}
arr__char map__arr__arr__char__arr__ptr__char__fun_mut1__arr__char__ptr__char__lambda0(ctx* _ctx, map__arr__arr__char__arr__ptr__char__fun_mut1__arr__char__ptr__char__lambda0___closure* _closure, nat i) {
	return call__arr__char__fun_mut1__arr__char__ptr__char__ptr__char(_ctx, _closure->mapper, at__ptr__char__arr__ptr__char__nat(_ctx, _closure->a, i));
}
arr__char to_str__arr__char__ptr__char(ptr__char a) {
	return arr_from_begin_end__arr__char__ptr__char__ptr__char(a, find_cstr_end__ptr__char__ptr__char(a));
}
arr__char arr_from_begin_end__arr__char__ptr__char__ptr__char(ptr__char begin, ptr__char end) {
	return (arr__char) {_op_minus__nat__ptr__char__ptr__char(end, begin), begin};
}
nat _op_minus__nat__ptr__char__ptr__char(ptr__char a, ptr__char b) {
	return (nat) (a - (nat) b);
}
ptr__char find_cstr_end__ptr__char__ptr__char(ptr__char a) {
	return find_char_in_cstr__ptr__char__ptr__char__char(a, literal__char__arr__char((arr__char){1, "\0"}));
}
ptr__char find_char_in_cstr__ptr__char__ptr__char__char(ptr__char a, char c) {
	return _op_equal_equal__bool__char__char(*(a), c)
		? a
		: _op_equal_equal__bool__char__char(*(a), literal__char__arr__char((arr__char){1, "\0"}))
			? todo__ptr__char()
			: find_char_in_cstr__ptr__char__ptr__char__char(incr__ptr__char__ptr__char(a), c);
}
bool _op_equal_equal__bool__char__char(char a, char b) {
	comparison matched;
	return (matched = _op_less_equal_greater__comparison__char__char(a, b),
		matched.kind == 0
		? 0
		: matched.kind == 1
		? 1
		: matched.kind == 2
		? 0
		: _failbool());
}
comparison _op_less_equal_greater__comparison__char__char(char a, char b) {
	return (a < b)
		? (comparison) { 0, .as_less = (less) { 0 } }
		: (b < a)
			? (comparison) { 2, .as_greater = (greater) { 0 } }
			: (comparison) { 1, .as_equal = (equal) { 0 } };
}
char literal__char__arr__char(arr__char a) {
	return noctx_at__char__arr__char__nat(a, 0);
}
char noctx_at__char__arr__char__nat(arr__char a, nat index) {
	return (hard_assert___void__bool(_op_less__bool__nat__nat(index, a.size)),
	*((a.data + index)));
}
ptr__char todo__ptr__char() {
	return hard_fail__ptr__char__arr__char((arr__char){4, "TODO"});
}
ptr__char hard_fail__ptr__char__arr__char(arr__char reason) {
	assert(0);
}
ptr__char incr__ptr__char__ptr__char(ptr__char p) {
	return (p + 1);
}
arr__char add_first_task__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__lambda0__lambda0(ctx* _ctx, ptr__byte _closure, ptr__char it) {
	return to_str__arr__char__ptr__char(it);
}
fut__int32* add_first_task__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__lambda0(ctx* _ctx, add_first_task__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__lambda0___closure* _closure) {
	arr__ptr__char args;
	return ((args = tail__arr__ptr__char__arr__ptr__char(_ctx, _closure->all_args)),
	_closure->main_ptr(_ctx, map__arr__arr__char__arr__ptr__char__fun_mut1__arr__char__ptr__char(_ctx, args, (fun_mut1__arr__char__ptr__char) {
		(fun_ptr3__arr__char__ptr_ctx__ptr__byte__ptr__char) add_first_task__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__lambda0__lambda0,
		(ptr__byte) NULL
	})));
}
fut__int32* rt_main__int32__int32__ptr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__lambda0(ctx* _ctx, ptr__byte _closure, arr__ptr__char all_args, fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char main_ptr) {
	return add_first_task__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char(_ctx, all_args, main_ptr);
}
fut__int32* call_with_ctx__ptr_fut__int32__ptr_ctx__fun2__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char(ctx* c, fun2__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char f, arr__ptr__char p0, fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char p1) {
	return f.fun_ptr(c, f.closure, p0, p1);
}
_void run_threads___void__nat__ptr_global_ctx__fun_ptr2___void__nat__ptr_global_ctx(nat n_threads, global_ctx* arg, fun_ptr2___void__nat__ptr_global_ctx fun) {
	ptr__nat threads;
	ptr__thread_args__ptr_global_ctx thread_args;
	return ((threads = unmanaged_alloc_elements__ptr__nat__nat(n_threads)),
	((thread_args = unmanaged_alloc_elements__ptr__thread_args__ptr_global_ctx__nat(n_threads)),
	(((run_threads_recur___void__nat__nat__ptr__nat__ptr__thread_args__ptr_global_ctx__ptr_global_ctx__fun_ptr2___void__nat__ptr_global_ctx(0, n_threads, threads, thread_args, arg, fun),
	join_threads_recur___void__nat__nat__ptr__nat(0, n_threads, threads)),
	unmanaged_free___void__ptr__nat(threads)),
	unmanaged_free___void__ptr__thread_args__ptr_global_ctx(thread_args))));
}
ptr__thread_args__ptr_global_ctx unmanaged_alloc_elements__ptr__thread_args__ptr_global_ctx__nat(nat size_elements) {
	ptr__byte bytes;
	return ((bytes = unmanaged_alloc_bytes__ptr__byte__nat((size_elements * sizeof(thread_args__ptr_global_ctx)))),
	(ptr__thread_args__ptr_global_ctx) bytes);
}
_void run_threads_recur___void__nat__nat__ptr__nat__ptr__thread_args__ptr_global_ctx__ptr_global_ctx__fun_ptr2___void__nat__ptr_global_ctx(nat i, nat n_threads, ptr__nat threads, ptr__thread_args__ptr_global_ctx thread_args, global_ctx* arg, fun_ptr2___void__nat__ptr_global_ctx fun) {
	ptr__thread_args__ptr_global_ctx thread_arg_ptr;
	ptr__nat thread_ptr;
	fun_ptr1__ptr__byte__ptr__byte fn;
	int32 err;
	return _op_equal_equal__bool__nat__nat(i, n_threads)
		? 0
		: ((thread_arg_ptr = (thread_args + i)),
		(((*(thread_arg_ptr) = (thread_args__ptr_global_ctx) {fun, i, arg}), 0),
		((thread_ptr = (threads + i)),
		((fn = run_threads_recur___void__nat__nat__ptr__nat__ptr__thread_args__ptr_global_ctx__ptr_global_ctx__fun_ptr2___void__nat__ptr_global_ctx__lambda0),
		((err = pthread_create(as_cell__ptr_cell__nat__ptr__nat(thread_ptr), NULL, fn, (ptr__byte) thread_arg_ptr)),
		zero__q__bool__int32(err)
			? run_threads_recur___void__nat__nat__ptr__nat__ptr__thread_args__ptr_global_ctx__ptr_global_ctx__fun_ptr2___void__nat__ptr_global_ctx(noctx_incr__nat__nat(i), n_threads, threads, thread_args, arg, fun)
			: _op_equal_equal__bool__int32__int32(err, eagain__int32())
				? todo___void()
				: todo___void())))));
}
ptr__byte thread_fun__ptr__byte__ptr__byte(ptr__byte args_ptr) {
	thread_args__ptr_global_ctx* args;
	return ((args = (thread_args__ptr_global_ctx*) args_ptr),
	(args->fun(args->thread_id, args->arg),
	NULL));
}
ptr__byte run_threads_recur___void__nat__nat__ptr__nat__ptr__thread_args__ptr_global_ctx__ptr_global_ctx__fun_ptr2___void__nat__ptr_global_ctx__lambda0(ptr__byte args_ptr) {
	return thread_fun__ptr__byte__ptr__byte(args_ptr);
}
cell__nat* as_cell__ptr_cell__nat__ptr__nat(ptr__nat p) {
	return (cell__nat*) (ptr__byte) p;
}
int32 eagain__int32() {
	return (ten__int32() + 1);
}
int32 ten__int32() {
	return wrap_incr__int32__int32(nine__int32());
}
int32 nine__int32() {
	return wrap_incr__int32__int32(eight__int32());
}
int32 eight__int32() {
	return (four__int32() + four__int32());
}
_void join_threads_recur___void__nat__nat__ptr__nat(nat i, nat n_threads, ptr__nat threads) {
	return _op_equal_equal__bool__nat__nat(i, n_threads)
		? 0
		: (join_one_thread___void__nat(*((threads + i))),
		join_threads_recur___void__nat__nat__ptr__nat(noctx_incr__nat__nat(i), n_threads, threads));
}
_void join_one_thread___void__nat(nat tid) {
	cell__ptr__byte thread_return;
	int32 err;
	return ((thread_return = (cell__ptr__byte) {NULL}),
	((err = pthread_join(tid, (&(thread_return)))),
	(zero__q__bool__int32(err)
		? 0
		: _op_equal_equal__bool__int32__int32(err, einval__int32())
			? todo___void()
			: _op_equal_equal__bool__int32__int32(err, esrch__int32())
				? todo___void()
				: todo___void(),
	hard_assert___void__bool(_op_equal_equal__bool__ptr__byte__ptr__byte(get__ptr__byte__ptr_cell__ptr__byte((&(thread_return))), NULL)))));
}
int32 einval__int32() {
	return ((ten__int32() + ten__int32()) + two__int32());
}
int32 esrch__int32() {
	return three__int32();
}
ptr__byte get__ptr__byte__ptr_cell__ptr__byte(cell__ptr__byte* c) {
	return c->value;
}
_void unmanaged_free___void__ptr__nat(ptr__nat p) {
	return (free((ptr__byte) p), 0);
}
_void unmanaged_free___void__ptr__thread_args__ptr_global_ctx(ptr__thread_args__ptr_global_ctx p) {
	return (free((ptr__byte) p), 0);
}
_void thread_function___void__nat__ptr_global_ctx(nat thread_id, global_ctx* gctx) {
	exception_ctx ectx;
	thread_local_stuff tls;
	return ((ectx = new_exception_ctx__exception_ctx()),
	((tls = (thread_local_stuff) {(&(ectx))}),
	thread_function_recur___void__nat__ptr_global_ctx__ptr_thread_local_stuff(thread_id, gctx, (&(tls)))));
}
_void thread_function_recur___void__nat__ptr_global_ctx__ptr_thread_local_stuff(nat thread_id, global_ctx* gctx, thread_local_stuff* tls) {
	nat last_checked;
	ok__chosen_task ok_chosen_task;
	err__no_chosen_task e;
	result__chosen_task__no_chosen_task matched;
	return gctx->is_shut_down
		? (((acquire_lock___void__ptr_lock((&(gctx->lk))),
		(gctx->n_live_threads = noctx_decr__nat__nat(gctx->n_live_threads)), 0),
		assert_vats_are_shut_down___void__nat__arr__ptr_vat(0, gctx->vats)),
		release_lock___void__ptr_lock((&(gctx->lk))))
		: (hard_assert___void__bool(_op_greater__bool__nat__nat(gctx->n_live_threads, 0)),
		((last_checked = get_last_checked__nat__ptr_condition((&(gctx->may_be_work_to_do)))),
		((matched = choose_task__result__chosen_task__no_chosen_task__ptr_global_ctx(gctx),
			matched.kind == 0
			? (ok_chosen_task = matched.as_ok__chosen_task,
			do_task___void__ptr_global_ctx__ptr_thread_local_stuff__chosen_task(gctx, tls, ok_chosen_task.value)
			): matched.kind == 1
			? (e = matched.as_err__no_chosen_task,
			(((e.value.last_thread_out
				? ((hard_forbid___void__bool(gctx->is_shut_down),
				(gctx->is_shut_down = 1), 0),
				broadcast___void__ptr_condition((&(gctx->may_be_work_to_do))))
				: wait_on___void__ptr_condition__nat((&(gctx->may_be_work_to_do)), last_checked),
			acquire_lock___void__ptr_lock((&(gctx->lk)))),
			(gctx->n_live_threads = noctx_incr__nat__nat(gctx->n_live_threads)), 0),
			release_lock___void__ptr_lock((&(gctx->lk))))
			): _fail_void()),
		thread_function_recur___void__nat__ptr_global_ctx__ptr_thread_local_stuff(thread_id, gctx, tls))));
}
nat noctx_decr__nat__nat(nat n) {
	return (hard_forbid___void__bool(zero__q__bool__nat(n)),
	(n - 1));
}
_void assert_vats_are_shut_down___void__nat__arr__ptr_vat(nat i, arr__ptr_vat vats) {
	vat* vat;
	return _op_equal_equal__bool__nat__nat(i, vats.size)
		? 0
		: ((vat = noctx_at__ptr_vat__arr__ptr_vat__nat(vats, i)),
		(((((acquire_lock___void__ptr_lock((&(vat->tasks_lock))),
		hard_forbid___void__bool((&(vat->gc))->needs_gc)),
		hard_assert___void__bool(zero__q__bool__nat(vat->n_threads_running))),
		hard_assert___void__bool(empty__q__bool__ptr_mut_bag__task((&(vat->tasks))))),
		release_lock___void__ptr_lock((&(vat->tasks_lock)))),
		assert_vats_are_shut_down___void__nat__arr__ptr_vat(noctx_incr__nat__nat(i), vats)));
}
bool empty__q__bool__ptr_mut_bag__task(mut_bag__task* m) {
	return empty__q__bool__opt__ptr_mut_bag_node__task(m->head);
}
bool empty__q__bool__opt__ptr_mut_bag_node__task(opt__ptr_mut_bag_node__task a) {
	none n;
	some__ptr_mut_bag_node__task s;
	opt__ptr_mut_bag_node__task matched;
	return (matched = a,
		matched.kind == 0
		? (n = matched.as_none,
		1
		): matched.kind == 1
		? (s = matched.as_some__ptr_mut_bag_node__task,
		0
		): _failbool());
}
bool _op_greater__bool__nat__nat(nat a, nat b) {
	return !(_op_less_equal__bool__nat__nat(a, b));
}
nat get_last_checked__nat__ptr_condition(condition* c) {
	return c->value;
}
result__chosen_task__no_chosen_task choose_task__result__chosen_task__no_chosen_task__ptr_global_ctx(global_ctx* gctx) {
	some__chosen_task s;
	opt__chosen_task matched;
	result__chosen_task__no_chosen_task res;
	return (acquire_lock___void__ptr_lock((&(gctx->lk))),
	((res = (matched = choose_task_recur__opt__chosen_task__arr__ptr_vat__nat(gctx->vats, 0),
		matched.kind == 0
		? ((gctx->n_live_threads = noctx_decr__nat__nat(gctx->n_live_threads)), 0,
		(result__chosen_task__no_chosen_task) { 1, .as_err__no_chosen_task = err__err__no_chosen_task__no_chosen_task((no_chosen_task) {zero__q__bool__nat(gctx->n_live_threads)}) })
		: matched.kind == 1
		? (s = matched.as_some__chosen_task,
		(result__chosen_task__no_chosen_task) { 0, .as_ok__chosen_task = ok__ok__chosen_task__chosen_task(s.value) }
		): _failresult__chosen_task__no_chosen_task())),
	(release_lock___void__ptr_lock((&(gctx->lk))),
	res)));
}
opt__chosen_task choose_task_recur__opt__chosen_task__arr__ptr_vat__nat(arr__ptr_vat vats, nat i) {
	vat* vat;
	some__opt__task s;
	opt__opt__task matched;
	return _op_equal_equal__bool__nat__nat(i, vats.size)
		? (opt__chosen_task) { 0, .as_none = none__none() }
		: ((vat = noctx_at__ptr_vat__arr__ptr_vat__nat(vats, i)),
		(matched = choose_task_in_vat__opt__opt__task__ptr_vat(vat),
			matched.kind == 0
			? choose_task_recur__opt__chosen_task__arr__ptr_vat__nat(vats, noctx_incr__nat__nat(i))
			: matched.kind == 1
			? (s = matched.as_some__opt__task,
			(opt__chosen_task) { 1, .as_some__chosen_task = some__some__chosen_task__chosen_task((chosen_task) {vat, s.value}) }
			): _failopt__chosen_task()));
}
opt__opt__task choose_task_in_vat__opt__opt__task__ptr_vat(vat* vat) {
	some__task s;
	opt__task matched;
	opt__opt__task res;
	return (acquire_lock___void__ptr_lock((&(vat->tasks_lock))),
	((res = (&(vat->gc))->needs_gc
		? zero__q__bool__nat(vat->n_threads_running)
			? (opt__opt__task) { 1, .as_some__opt__task = some__some__opt__task__opt__task((opt__task) { 0, .as_none = none__none() }) }
			: (opt__opt__task) { 0, .as_none = none__none() }
		: (matched = find_and_remove_first_doable_task__opt__task__ptr_vat(vat),
			matched.kind == 0
			? (opt__opt__task) { 0, .as_none = none__none() }
			: matched.kind == 1
			? (s = matched.as_some__task,
			(opt__opt__task) { 1, .as_some__opt__task = some__some__opt__task__opt__task((opt__task) { 1, .as_some__task = some__some__task__task(s.value) }) }
			): _failopt__opt__task())),
	((empty__q__bool__opt__opt__task(res)
		? 0
		: (vat->n_threads_running = noctx_incr__nat__nat(vat->n_threads_running)), 0,
	release_lock___void__ptr_lock((&(vat->tasks_lock)))),
	res)));
}
some__opt__task some__some__opt__task__opt__task(opt__task t) {
	return (some__opt__task) {t};
}
opt__task find_and_remove_first_doable_task__opt__task__ptr_vat(vat* vat) {
	mut_bag__task* tasks;
	opt__task_and_nodes res;
	some__task_and_nodes s;
	opt__task_and_nodes matched;
	return ((tasks = (&(vat->tasks))),
	((res = find_and_remove_first_doable_task_recur__opt__task_and_nodes__ptr_vat__opt__ptr_mut_bag_node__task(vat, tasks->head)),
	(matched = res,
		matched.kind == 0
		? (opt__task) { 0, .as_none = none__none() }
		: matched.kind == 1
		? (s = matched.as_some__task_and_nodes,
		((tasks->head = s.value.nodes), 0,
		(opt__task) { 1, .as_some__task = some__some__task__task(s.value.task) })
		): _failopt__task())));
}
opt__task_and_nodes find_and_remove_first_doable_task_recur__opt__task_and_nodes__ptr_vat__opt__ptr_mut_bag_node__task(vat* vat, opt__ptr_mut_bag_node__task opt_node) {
	some__ptr_mut_bag_node__task s;
	mut_bag_node__task* node;
	task task;
	mut_arr__nat* actors;
	bool task_ok;
	some__task_and_nodes ss;
	task_and_nodes tn;
	opt__task_and_nodes matched;
	opt__ptr_mut_bag_node__task matched1;
	return (matched1 = opt_node,
		matched1.kind == 0
		? (opt__task_and_nodes) { 0, .as_none = none__none() }
		: matched1.kind == 1
		? (s = matched1.as_some__ptr_mut_bag_node__task,
		((node = s.value),
		((task = node->value),
		((actors = (&(vat->currently_running_actors))),
		((task_ok = contains__q__bool__ptr_mut_arr__nat__nat(actors, task.actor_id)
			? 0
			: (push_capacity_must_be_sufficient___void__ptr_mut_arr__nat__nat(actors, task.actor_id),
			1)),
		task_ok
			? (opt__task_and_nodes) { 1, .as_some__task_and_nodes = some__some__task_and_nodes__task_and_nodes((task_and_nodes) {task, node->next_node}) }
			: (matched = find_and_remove_first_doable_task_recur__opt__task_and_nodes__ptr_vat__opt__ptr_mut_bag_node__task(vat, node->next_node),
				matched.kind == 0
				? (opt__task_and_nodes) { 0, .as_none = none__none() }
				: matched.kind == 1
				? (ss = matched.as_some__task_and_nodes,
				((tn = ss.value),
				((node->next_node = tn.nodes), 0,
				(opt__task_and_nodes) { 1, .as_some__task_and_nodes = some__some__task_and_nodes__task_and_nodes((task_and_nodes) {tn.task, (opt__ptr_mut_bag_node__task) { 1, .as_some__ptr_mut_bag_node__task = some__some__ptr_mut_bag_node__task__ptr_mut_bag_node__task(node) }}) }))
				): _failopt__task_and_nodes())))))
		): _failopt__task_and_nodes());
}
bool contains__q__bool__ptr_mut_arr__nat__nat(mut_arr__nat* a, nat value) {
	return contains_recur__q__bool__arr__nat__nat__nat(temp_as_arr__arr__nat__ptr_mut_arr__nat(a), value, 0);
}
bool contains_recur__q__bool__arr__nat__nat__nat(arr__nat a, nat value, nat i) {
	return _op_equal_equal__bool__nat__nat(i, a.size)
		? 0
		: (_op_equal_equal__bool__nat__nat(noctx_at__nat__arr__nat__nat(a, i), value) || contains_recur__q__bool__arr__nat__nat__nat(a, value, noctx_incr__nat__nat(i)));
}
nat noctx_at__nat__arr__nat__nat(arr__nat a, nat index) {
	return (hard_assert___void__bool(_op_less__bool__nat__nat(index, a.size)),
	*((a.data + index)));
}
arr__nat temp_as_arr__arr__nat__ptr_mut_arr__nat(mut_arr__nat* a) {
	return (arr__nat) {a->size, a->data};
}
_void push_capacity_must_be_sufficient___void__ptr_mut_arr__nat__nat(mut_arr__nat* a, nat value) {
	nat old_size;
	return (hard_assert___void__bool(_op_less__bool__nat__nat(a->size, a->capacity)),
	((old_size = a->size),
	((a->size = noctx_incr__nat__nat(old_size)), 0,
	noctx_set_at___void__ptr_mut_arr__nat__nat__nat(a, old_size, value))));
}
_void noctx_set_at___void__ptr_mut_arr__nat__nat__nat(mut_arr__nat* a, nat index, nat value) {
	return (hard_assert___void__bool(_op_less__bool__nat__nat(index, a->size)),
	((*((a->data + index)) = value), 0));
}
some__task_and_nodes some__some__task_and_nodes__task_and_nodes(task_and_nodes t) {
	return (some__task_and_nodes) {t};
}
some__task some__some__task__task(task t) {
	return (some__task) {t};
}
bool empty__q__bool__opt__opt__task(opt__opt__task a) {
	none n;
	some__opt__task s;
	opt__opt__task matched;
	return (matched = a,
		matched.kind == 0
		? (n = matched.as_none,
		1
		): matched.kind == 1
		? (s = matched.as_some__opt__task,
		0
		): _failbool());
}
some__chosen_task some__some__chosen_task__chosen_task(chosen_task t) {
	return (some__chosen_task) {t};
}
err__no_chosen_task err__err__no_chosen_task__no_chosen_task(no_chosen_task t) {
	return (err__no_chosen_task) {t};
}
ok__chosen_task ok__ok__chosen_task__chosen_task(chosen_task t) {
	return (ok__chosen_task) {t};
}
_void do_task___void__ptr_global_ctx__ptr_thread_local_stuff__chosen_task(global_ctx* gctx, thread_local_stuff* tls, chosen_task chosen_task) {
	vat* vat;
	some__task some_task;
	task task;
	ctx ctx;
	opt__task matched;
	return ((vat = chosen_task.vat),
	((((matched = chosen_task.task_or_gc,
		matched.kind == 0
		? (todo___void(),
		broadcast___void__ptr_condition((&(gctx->may_be_work_to_do))))
		: matched.kind == 1
		? (some_task = matched.as_some__task,
		((task = some_task.value),
		((ctx = new_ctx__ctx__ptr_global_ctx__ptr_thread_local_stuff__ptr_vat__nat(gctx, tls, vat, task.actor_id)),
		((((call_with_ctx___void__ptr_ctx__fun_mut0___void((&(ctx)), task.fun),
		acquire_lock___void__ptr_lock((&(vat->tasks_lock)))),
		noctx_must_remove_unordered___void__ptr_mut_arr__nat__nat((&(vat->currently_running_actors)), task.actor_id)),
		release_lock___void__ptr_lock((&(vat->tasks_lock)))),
		return_ctx___void__ptr_ctx((&(ctx))))))
		): _fail_void()),
	acquire_lock___void__ptr_lock((&(vat->tasks_lock)))),
	(vat->n_threads_running = noctx_decr__nat__nat(vat->n_threads_running)), 0),
	release_lock___void__ptr_lock((&(vat->tasks_lock)))));
}
_void noctx_must_remove_unordered___void__ptr_mut_arr__nat__nat(mut_arr__nat* a, nat value) {
	return noctx_must_remove_unordered_recur___void__ptr_mut_arr__nat__nat__nat(a, 0, value);
}
_void noctx_must_remove_unordered_recur___void__ptr_mut_arr__nat__nat__nat(mut_arr__nat* a, nat index, nat value) {
	return _op_equal_equal__bool__nat__nat(index, a->size)
		? hard_fail___void__arr__char((arr__char){39, "Did not find the element in the mut-arr"})
		: _op_equal_equal__bool__nat__nat(noctx_at__nat__ptr_mut_arr__nat__nat(a, index), value)
			? drop___void__nat(noctx_remove_unordered_at_index__nat__ptr_mut_arr__nat__nat(a, index))
			: noctx_must_remove_unordered_recur___void__ptr_mut_arr__nat__nat__nat(a, noctx_incr__nat__nat(index), value);
}
nat noctx_at__nat__ptr_mut_arr__nat__nat(mut_arr__nat* a, nat index) {
	return (hard_assert___void__bool(_op_less__bool__nat__nat(index, a->size)),
	*((a->data + index)));
}
_void drop___void__nat(nat t) {
	return 0;
}
nat noctx_remove_unordered_at_index__nat__ptr_mut_arr__nat__nat(mut_arr__nat* a, nat index) {
	nat res;
	return ((res = noctx_at__nat__ptr_mut_arr__nat__nat(a, index)),
	((noctx_set_at___void__ptr_mut_arr__nat__nat__nat(a, index, noctx_last__nat__ptr_mut_arr__nat(a)),
	(a->size = noctx_decr__nat__nat(a->size)), 0),
	res));
}
nat noctx_last__nat__ptr_mut_arr__nat(mut_arr__nat* a) {
	return (hard_forbid___void__bool(empty__q__bool__ptr_mut_arr__nat(a)),
	noctx_at__nat__ptr_mut_arr__nat__nat(a, noctx_decr__nat__nat(a->size)));
}
bool empty__q__bool__ptr_mut_arr__nat(mut_arr__nat* a) {
	return zero__q__bool__nat(a->size);
}
_void return_ctx___void__ptr_ctx(ctx* c) {
	return return_gc_ctx___void__ptr_gc_ctx((gc_ctx*) c->gc_ctx_ptr);
}
_void return_gc_ctx___void__ptr_gc_ctx(gc_ctx* gc_ctx) {
	gc* gc;
	return ((gc = gc_ctx->gc),
	(((acquire_lock___void__ptr_lock((&(gc->lk))),
	(gc_ctx->next_ctx = gc->context_head), 0),
	(gc->context_head = (opt__ptr_gc_ctx) { 1, .as_some__ptr_gc_ctx = some__some__ptr_gc_ctx__ptr_gc_ctx(gc_ctx) }), 0),
	release_lock___void__ptr_lock((&(gc->lk)))));
}
some__ptr_gc_ctx some__some__ptr_gc_ctx__ptr_gc_ctx(gc_ctx* t) {
	return (some__ptr_gc_ctx) {t};
}
_void wait_on___void__ptr_condition__nat(condition* c, nat last_checked) {
	return _op_equal_equal__bool__nat__nat(c->value, last_checked)
		? (yield_thread___void(),
		wait_on___void__ptr_condition__nat(c, last_checked))
		: 0;
}
_void rt_main__int32__int32__ptr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__lambda1(nat thread_id, global_ctx* gctx) {
	return thread_function___void__nat__ptr_global_ctx(thread_id, gctx);
}
result__int32__exception must_be_resolved__result__int32__exception__ptr_fut__int32(fut__int32* f) {
	fut_state_resolved__int32 r;
	exception e;
	fut_state__int32 matched;
	return (matched = f->state,
		matched.kind == 0
		? hard_unreachable__result__int32__exception()
		: matched.kind == 1
		? (r = matched.as_fut_state_resolved__int32,
		(result__int32__exception) { 0, .as_ok__int32 = ok__ok__int32__int32(r.value) }
		): matched.kind == 2
		? (e = matched.as_exception,
		(result__int32__exception) { 1, .as_err__exception = err__err__exception__exception(e) }
		): _failresult__int32__exception());
}
result__int32__exception hard_unreachable__result__int32__exception() {
	return hard_fail__result__int32__exception__arr__char((arr__char){11, "unreachable"});
}
result__int32__exception hard_fail__result__int32__exception__arr__char(arr__char reason) {
	assert(0);
}
fut__int32* main__ptr_fut__int32__arr__arr__char(ctx* _ctx, arr__arr__char args) {
	arr__arr__char arr;
	arr__arr__char option_names;
	opt__test_options options;
	some__test_options s;
	opt__test_options matched;
	return ((option_names = (arr = (arr__arr__char) { 3, (arr__char*) alloc__ptr__byte__nat(_ctx, 48) }, arr.data[0] =(arr__char){11, "print-tests"}, arr.data[1] =(arr__char){16, "overwrite-output"}, arr.data[2] =(arr__char){12, "max-failures"}, arr)),
	((options = parse_cmd_line_args__opt__test_options__arr__arr__char__arr__arr__char__fun1__test_options__arr__opt__arr__arr__char(_ctx, args, option_names, (fun1__test_options__arr__opt__arr__arr__char) {
		(fun_ptr3__test_options__ptr_ctx__ptr__byte__arr__opt__arr__arr__char) main__ptr_fut__int32__arr__arr__char__lambda0,
		(ptr__byte) NULL
	})),
	resolved__ptr_fut__int32__int32(_ctx, (matched = options,
		matched.kind == 0
		? (print_help___void(_ctx),
		literal__int32__arr__char(_ctx, (arr__char){1, "1"}))
		: matched.kind == 1
		? (s = matched.as_some__test_options,
		do_test__int32__test_options(_ctx, s.value)
		): _failint32()))));
}
opt__test_options parse_cmd_line_args__opt__test_options__arr__arr__char__arr__arr__char__fun1__test_options__arr__opt__arr__arr__char(ctx* _ctx, arr__arr__char args, arr__arr__char t_names, fun1__test_options__arr__opt__arr__arr__char make_t) {
	parsed_cmd_line_args* parsed;
	mut_arr__opt__arr__arr__char* values;
	cell__bool* help;
	return ((parsed = parse_cmd_line_args_dynamic__ptr_parsed_cmd_line_args__arr__arr__char(_ctx, args)),
	((assert___void__bool__arr__char(_ctx, empty__q__bool__arr__arr__char(parsed->nameless), (arr__char){26, "Should be no nameless args"}),
	assert___void__bool(_ctx, empty__q__bool__arr__arr__char(parsed->after))),
	((values = fill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat__opt__arr__arr__char(_ctx, t_names.size, (opt__arr__arr__char) { 0, .as_none = none__none() })),
	((help = new_cell__ptr_cell__bool__bool(_ctx, 0)),
	(each___void__ptr_dict__arr__char__arr__arr__char__fun_mut2___void__arr__char__arr__arr__char(_ctx, parsed->named, (fun_mut2___void__arr__char__arr__arr__char) {
		(fun_ptr4___void__ptr_ctx__ptr__byte__arr__char__arr__arr__char) parse_cmd_line_args__opt__test_options__arr__arr__char__arr__arr__char__fun1__test_options__arr__opt__arr__arr__char__lambda0,
		(ptr__byte) _initparse_cmd_line_args__opt__test_options__arr__arr__char__arr__arr__char__fun1__test_options__arr__opt__arr__arr__char__lambda0___closure(alloc__ptr__byte__nat(_ctx, 32), (parse_cmd_line_args__opt__test_options__arr__arr__char__arr__arr__char__fun1__test_options__arr__opt__arr__arr__char__lambda0___closure) {t_names, help, values})
	}),
	get__bool__ptr_cell__bool(help)
		? (opt__test_options) { 0, .as_none = none__none() }
		: (opt__test_options) { 1, .as_some__test_options = some__some__test_options__test_options(call__test_options__fun1__test_options__arr__opt__arr__arr__char__arr__opt__arr__arr__char(_ctx, make_t, freeze__arr__opt__arr__arr__char__ptr_mut_arr__opt__arr__arr__char(values))) })))));
}
parsed_cmd_line_args* parse_cmd_line_args_dynamic__ptr_parsed_cmd_line_args__arr__arr__char(ctx* _ctx, arr__arr__char args) {
	some__nat s;
	nat first_named_arg_index;
	arr__arr__char nameless;
	arr__arr__char rest;
	some__nat s2;
	nat sep_index;
	opt__nat matched;
	opt__nat matched1;
	return (matched1 = find_index__opt__nat__arr__arr__char__fun_mut1__bool__arr__char(_ctx, args, (fun_mut1__bool__arr__char) {
		(fun_ptr3__bool__ptr_ctx__ptr__byte__arr__char) parse_cmd_line_args_dynamic__ptr_parsed_cmd_line_args__arr__arr__char__lambda0,
		(ptr__byte) NULL
	}),
		matched1.kind == 0
		? _initparsed_cmd_line_args(alloc__ptr__byte__nat(_ctx, 40), (parsed_cmd_line_args) {args, empty_dict__ptr_dict__arr__char__arr__arr__char(_ctx), empty_arr__arr__arr__char()})
		: matched1.kind == 1
		? (s = matched1.as_some__nat,
		((first_named_arg_index = s.value),
		((nameless = slice_up_to__arr__arr__char__arr__arr__char__nat(_ctx, args, first_named_arg_index)),
		((rest = slice_starting_at__arr__arr__char__arr__arr__char__nat(_ctx, args, first_named_arg_index)),
		(matched = find_index__opt__nat__arr__arr__char__fun_mut1__bool__arr__char(_ctx, rest, (fun_mut1__bool__arr__char) {
			(fun_ptr3__bool__ptr_ctx__ptr__byte__arr__char) parse_cmd_line_args_dynamic__ptr_parsed_cmd_line_args__arr__arr__char__lambda1,
			(ptr__byte) NULL
		}),
			matched.kind == 0
			? _initparsed_cmd_line_args(alloc__ptr__byte__nat(_ctx, 40), (parsed_cmd_line_args) {nameless, parse_named_args__ptr_dict__arr__char__arr__arr__char__arr__arr__char(_ctx, rest), empty_arr__arr__arr__char()})
			: matched.kind == 1
			? (s2 = matched.as_some__nat,
			((sep_index = s2.value),
			_initparsed_cmd_line_args(alloc__ptr__byte__nat(_ctx, 40), (parsed_cmd_line_args) {nameless, parse_named_args__ptr_dict__arr__char__arr__arr__char__arr__arr__char(_ctx, slice_up_to__arr__arr__char__arr__arr__char__nat(_ctx, rest, sep_index)), slice_after__arr__arr__char__arr__arr__char__nat(_ctx, rest, sep_index)}))
			): _failVoidPtr()))))
		): _failVoidPtr());
}
opt__nat find_index__opt__nat__arr__arr__char__fun_mut1__bool__arr__char(ctx* _ctx, arr__arr__char a, fun_mut1__bool__arr__char pred) {
	return find_index_recur__opt__nat__arr__arr__char__nat__fun_mut1__bool__arr__char(_ctx, a, 0, pred);
}
opt__nat find_index_recur__opt__nat__arr__arr__char__nat__fun_mut1__bool__arr__char(ctx* _ctx, arr__arr__char a, nat index, fun_mut1__bool__arr__char pred) {
	return _op_equal_equal__bool__nat__nat(index, a.size)
		? (opt__nat) { 0, .as_none = none__none() }
		: call__bool__fun_mut1__bool__arr__char__arr__char(_ctx, pred, at__arr__char__arr__arr__char__nat(_ctx, a, index))
			? (opt__nat) { 1, .as_some__nat = some__some__nat__nat(index) }
			: find_index_recur__opt__nat__arr__arr__char__nat__fun_mut1__bool__arr__char(_ctx, a, incr__nat__nat(_ctx, index), pred);
}
bool call__bool__fun_mut1__bool__arr__char__arr__char(ctx* _ctx, fun_mut1__bool__arr__char f, arr__char p0) {
	return call_with_ctx__bool__ptr_ctx__fun_mut1__bool__arr__char__arr__char(_ctx, f, p0);
}
bool call_with_ctx__bool__ptr_ctx__fun_mut1__bool__arr__char__arr__char(ctx* c, fun_mut1__bool__arr__char f, arr__char p0) {
	return f.fun_ptr(c, f.closure, p0);
}
arr__char at__arr__char__arr__arr__char__nat(ctx* _ctx, arr__arr__char a, nat index) {
	return (assert___void__bool(_ctx, _op_less__bool__nat__nat(index, a.size)),
	noctx_at__arr__char__arr__arr__char__nat(a, index));
}
arr__char noctx_at__arr__char__arr__arr__char__nat(arr__arr__char a, nat index) {
	return (hard_assert___void__bool(_op_less__bool__nat__nat(index, a.size)),
	*((a.data + index)));
}
some__nat some__some__nat__nat(nat t) {
	return (some__nat) {t};
}
bool starts_with__q__bool__arr__char__arr__char(ctx* _ctx, arr__char a, arr__char start) {
	return (_op_greater_equal__bool__nat__nat(a.size, start.size) && arr_eq__q__bool__arr__char__arr__char(_ctx, slice__arr__char__arr__char__nat__nat(_ctx, a, 0, start.size), start));
}
bool arr_eq__q__bool__arr__char__arr__char(ctx* _ctx, arr__char a, arr__char b) {
	return (_op_equal_equal__bool__nat__nat(a.size, b.size) && (empty__q__bool__arr__char(a) || (_op_equal_equal__bool__char__char(first__char__arr__char(_ctx, a), first__char__arr__char(_ctx, b)) && arr_eq__q__bool__arr__char__arr__char(_ctx, tail__arr__char__arr__char(_ctx, a), tail__arr__char__arr__char(_ctx, b)))));
}
char first__char__arr__char(ctx* _ctx, arr__char a) {
	return (forbid___void__bool(_ctx, empty__q__bool__arr__char(a)),
	at__char__arr__char__nat(_ctx, a, 0));
}
char at__char__arr__char__nat(ctx* _ctx, arr__char a, nat index) {
	return (assert___void__bool(_ctx, _op_less__bool__nat__nat(index, a.size)),
	noctx_at__char__arr__char__nat(a, index));
}
arr__char tail__arr__char__arr__char(ctx* _ctx, arr__char a) {
	return (forbid___void__bool(_ctx, empty__q__bool__arr__char(a)),
	slice_starting_at__arr__char__arr__char__nat(_ctx, a, 1));
}
arr__char slice_starting_at__arr__char__arr__char__nat(ctx* _ctx, arr__char a, nat begin) {
	return (assert___void__bool(_ctx, _op_less_equal__bool__nat__nat(begin, a.size)),
	slice__arr__char__arr__char__nat__nat(_ctx, a, begin, _op_minus__nat__nat__nat(_ctx, a.size, begin)));
}
arr__char slice__arr__char__arr__char__nat__nat(ctx* _ctx, arr__char a, nat begin, nat size) {
	return (assert___void__bool(_ctx, _op_less_equal__bool__nat__nat(_op_plus__nat__nat__nat(_ctx, begin, size), a.size)),
	(arr__char) {size, (a.data + begin)});
}
bool parse_cmd_line_args_dynamic__ptr_parsed_cmd_line_args__arr__arr__char__lambda0(ctx* _ctx, ptr__byte _closure, arr__char it) {
	return starts_with__q__bool__arr__char__arr__char(_ctx, it, (arr__char){2, "--"});
}
dict__arr__char__arr__arr__char* empty_dict__ptr_dict__arr__char__arr__arr__char(ctx* _ctx) {
	return _initdict__arr__char__arr__arr__char(alloc__ptr__byte__nat(_ctx, 32), (dict__arr__char__arr__arr__char) {empty_arr__arr__arr__char(), empty_arr__arr__arr__arr__char()});
}
arr__arr__char empty_arr__arr__arr__char() {
	return (arr__arr__char) {0, NULL};
}
arr__arr__arr__char empty_arr__arr__arr__arr__char() {
	return (arr__arr__arr__char) {0, NULL};
}
arr__arr__char slice_up_to__arr__arr__char__arr__arr__char__nat(ctx* _ctx, arr__arr__char a, nat size) {
	return (assert___void__bool(_ctx, _op_less__bool__nat__nat(size, a.size)),
	slice__arr__arr__char__arr__arr__char__nat__nat(_ctx, a, 0, size));
}
arr__arr__char slice__arr__arr__char__arr__arr__char__nat__nat(ctx* _ctx, arr__arr__char a, nat begin, nat size) {
	return (assert___void__bool(_ctx, _op_less_equal__bool__nat__nat(_op_plus__nat__nat__nat(_ctx, begin, size), a.size)),
	(arr__arr__char) {size, (a.data + begin)});
}
arr__arr__char slice_starting_at__arr__arr__char__arr__arr__char__nat(ctx* _ctx, arr__arr__char a, nat begin) {
	return (assert___void__bool(_ctx, _op_less_equal__bool__nat__nat(begin, a.size)),
	slice__arr__arr__char__arr__arr__char__nat__nat(_ctx, a, begin, _op_minus__nat__nat__nat(_ctx, a.size, begin)));
}
bool _op_equal_equal__bool__arr__char__arr__char(arr__char a, arr__char b) {
	comparison matched;
	return (matched = _op_less_equal_greater__comparison__arr__char__arr__char(a, b),
		matched.kind == 0
		? 0
		: matched.kind == 1
		? 1
		: matched.kind == 2
		? 0
		: _failbool());
}
comparison _op_less_equal_greater__comparison__arr__char__arr__char(arr__char a, arr__char b) {
	comparison _cmpel;
	comparison _matchedel;
	return (a.size == 0)
		? (b.size == 0)
			? (comparison) { 1, .as_equal = (equal) { 0 } }
			: (comparison) { 0, .as_less = (less) { 0 } }
		: (b.size == 0)
			? (comparison) { 2, .as_greater = (greater) { 0 } }
			: ((_cmpel = _op_less_equal_greater__comparison__char__char(*(a.data), *(b.data))),
			(_matchedel = _cmpel,
				_matchedel.kind == 0
				? _cmpel
				: _matchedel.kind == 1
				? _op_less_equal_greater__comparison__arr__char__arr__char((arr__char) {(a.size - 1), (a.data + 1)}, (arr__char) {(b.size - 1), (b.data + 1)})
				: _matchedel.kind == 2
				? _cmpel
				: _failcomparison()));
}
bool parse_cmd_line_args_dynamic__ptr_parsed_cmd_line_args__arr__arr__char__lambda1(ctx* _ctx, ptr__byte _closure, arr__char it) {
	return _op_equal_equal__bool__arr__char__arr__char(it, (arr__char){2, "--"});
}
dict__arr__char__arr__arr__char* parse_named_args__ptr_dict__arr__char__arr__arr__char__arr__arr__char(ctx* _ctx, arr__arr__char args) {
	mut_dict__arr__char__arr__arr__char b;
	return ((b = new_mut_dict__mut_dict__arr__char__arr__arr__char(_ctx)),
	(parse_named_args_recur___void__arr__arr__char__mut_dict__arr__char__arr__arr__char(_ctx, args, b),
	freeze__ptr_dict__arr__char__arr__arr__char__mut_dict__arr__char__arr__arr__char(_ctx, b)));
}
mut_dict__arr__char__arr__arr__char new_mut_dict__mut_dict__arr__char__arr__arr__char(ctx* _ctx) {
	return (mut_dict__arr__char__arr__arr__char) {new_mut_arr__ptr_mut_arr__arr__char(_ctx), new_mut_arr__ptr_mut_arr__arr__arr__char(_ctx)};
}
mut_arr__arr__char* new_mut_arr__ptr_mut_arr__arr__char(ctx* _ctx) {
	return _initmut_arr__arr__char(alloc__ptr__byte__nat(_ctx, 32), (mut_arr__arr__char) {0, 0, 0, NULL});
}
mut_arr__arr__arr__char* new_mut_arr__ptr_mut_arr__arr__arr__char(ctx* _ctx) {
	return _initmut_arr__arr__arr__char(alloc__ptr__byte__nat(_ctx, 32), (mut_arr__arr__arr__char) {0, 0, 0, NULL});
}
_void parse_named_args_recur___void__arr__arr__char__mut_dict__arr__char__arr__arr__char(ctx* _ctx, arr__arr__char args, mut_dict__arr__char__arr__arr__char builder) {
	arr__char first_name;
	arr__arr__char tl;
	some__nat s;
	nat next_named_arg_index;
	opt__nat matched;
	return ((first_name = remove_start__arr__char__arr__char__arr__char(_ctx, first__arr__char__arr__arr__char(_ctx, args), (arr__char){2, "--"})),
	((tl = tail__arr__arr__char__arr__arr__char(_ctx, args)),
	(matched = find_index__opt__nat__arr__arr__char__fun_mut1__bool__arr__char(_ctx, tl, (fun_mut1__bool__arr__char) {
		(fun_ptr3__bool__ptr_ctx__ptr__byte__arr__char) parse_named_args_recur___void__arr__arr__char__mut_dict__arr__char__arr__arr__char__lambda0,
		(ptr__byte) NULL
	}),
		matched.kind == 0
		? add___void__mut_dict__arr__char__arr__arr__char__arr__char__arr__arr__char(_ctx, builder, first_name, tl)
		: matched.kind == 1
		? (s = matched.as_some__nat,
		((next_named_arg_index = s.value),
		(add___void__mut_dict__arr__char__arr__arr__char__arr__char__arr__arr__char(_ctx, builder, first_name, slice_up_to__arr__arr__char__arr__arr__char__nat(_ctx, tl, next_named_arg_index)),
		parse_named_args_recur___void__arr__arr__char__mut_dict__arr__char__arr__arr__char(_ctx, slice_starting_at__arr__arr__char__arr__arr__char__nat(_ctx, args, next_named_arg_index), builder)))
		): _fail_void())));
}
arr__char remove_start__arr__char__arr__char__arr__char(ctx* _ctx, arr__char a, arr__char start) {
	return force__arr__char__opt__arr__char(_ctx, try_remove_start__opt__arr__char__arr__char__arr__char(_ctx, a, start));
}
arr__char force__arr__char__opt__arr__char(ctx* _ctx, opt__arr__char a) {
	none n;
	some__arr__char s;
	opt__arr__char matched;
	return (matched = a,
		matched.kind == 0
		? (n = matched.as_none,
		fail__arr__char__arr__char(_ctx, (arr__char){27, "tried to force empty option"})
		): matched.kind == 1
		? (s = matched.as_some__arr__char,
		s.value
		): _failarr__char());
}
arr__char fail__arr__char__arr__char(ctx* _ctx, arr__char reason) {
	return throw__arr__char__exception(_ctx, (exception) {reason});
}
arr__char throw__arr__char__exception(ctx* _ctx, exception e) {
	exception_ctx* exn_ctx;
	return ((exn_ctx = get_exception_ctx__ptr_exception_ctx(_ctx)),
	(((hard_forbid___void__bool(_op_equal_equal__bool__ptr__jmp_buf_tag__ptr__jmp_buf_tag(exn_ctx->jmp_buf_ptr, NULL)),
	(exn_ctx->thrown_exception = e), 0),
	(longjmp(exn_ctx->jmp_buf_ptr, number_to_throw__int32(_ctx)), 0)),
	todo__arr__char()));
}
arr__char todo__arr__char() {
	return hard_fail__arr__char__arr__char((arr__char){4, "TODO"});
}
arr__char hard_fail__arr__char__arr__char(arr__char reason) {
	assert(0);
}
opt__arr__char try_remove_start__opt__arr__char__arr__char__arr__char(ctx* _ctx, arr__char a, arr__char start) {
	return starts_with__q__bool__arr__char__arr__char(_ctx, a, start)
		? (opt__arr__char) { 1, .as_some__arr__char = some__some__arr__char__arr__char(slice_starting_at__arr__char__arr__char__nat(_ctx, a, start.size)) }
		: (opt__arr__char) { 0, .as_none = none__none() };
}
some__arr__char some__some__arr__char__arr__char(arr__char t) {
	return (some__arr__char) {t};
}
arr__char first__arr__char__arr__arr__char(ctx* _ctx, arr__arr__char a) {
	return (forbid___void__bool(_ctx, empty__q__bool__arr__arr__char(a)),
	at__arr__char__arr__arr__char__nat(_ctx, a, 0));
}
bool empty__q__bool__arr__arr__char(arr__arr__char a) {
	return zero__q__bool__nat(a.size);
}
arr__arr__char tail__arr__arr__char__arr__arr__char(ctx* _ctx, arr__arr__char a) {
	return (forbid___void__bool(_ctx, empty__q__bool__arr__arr__char(a)),
	slice_starting_at__arr__arr__char__arr__arr__char__nat(_ctx, a, 1));
}
bool parse_named_args_recur___void__arr__arr__char__mut_dict__arr__char__arr__arr__char__lambda0(ctx* _ctx, ptr__byte _closure, arr__char it) {
	return starts_with__q__bool__arr__char__arr__char(_ctx, it, (arr__char){2, "--"});
}
_void add___void__mut_dict__arr__char__arr__arr__char__arr__char__arr__arr__char(ctx* _ctx, mut_dict__arr__char__arr__arr__char m, arr__char key, arr__arr__char value) {
	return ((forbid___void__bool(_ctx, has__q__bool__mut_dict__arr__char__arr__arr__char__arr__char(_ctx, m, key)),
	push___void__ptr_mut_arr__arr__char__arr__char(_ctx, m.keys, key)),
	push___void__ptr_mut_arr__arr__arr__char__arr__arr__char(_ctx, m.values, value));
}
bool has__q__bool__mut_dict__arr__char__arr__arr__char__arr__char(ctx* _ctx, mut_dict__arr__char__arr__arr__char d, arr__char key) {
	return has__q__bool__ptr_dict__arr__char__arr__arr__char__arr__char(_ctx, unsafe_as_dict__ptr_dict__arr__char__arr__arr__char__mut_dict__arr__char__arr__arr__char(_ctx, d), key);
}
bool has__q__bool__ptr_dict__arr__char__arr__arr__char__arr__char(ctx* _ctx, dict__arr__char__arr__arr__char* d, arr__char key) {
	return has__q__bool__opt__arr__arr__char(get__opt__arr__arr__char__ptr_dict__arr__char__arr__arr__char__arr__char(_ctx, d, key));
}
bool has__q__bool__opt__arr__arr__char(opt__arr__arr__char a) {
	return !(empty__q__bool__opt__arr__arr__char(a));
}
bool empty__q__bool__opt__arr__arr__char(opt__arr__arr__char a) {
	none n;
	some__arr__arr__char s;
	opt__arr__arr__char matched;
	return (matched = a,
		matched.kind == 0
		? (n = matched.as_none,
		1
		): matched.kind == 1
		? (s = matched.as_some__arr__arr__char,
		0
		): _failbool());
}
opt__arr__arr__char get__opt__arr__arr__char__ptr_dict__arr__char__arr__arr__char__arr__char(ctx* _ctx, dict__arr__char__arr__arr__char* d, arr__char key) {
	return get_recursive__opt__arr__arr__char__arr__arr__char__arr__arr__arr__char__nat__arr__char(_ctx, d->keys, d->values, 0, key);
}
opt__arr__arr__char get_recursive__opt__arr__arr__char__arr__arr__char__arr__arr__arr__char__nat__arr__char(ctx* _ctx, arr__arr__char keys, arr__arr__arr__char values, nat idx, arr__char key) {
	return _op_equal_equal__bool__nat__nat(idx, keys.size)
		? (opt__arr__arr__char) { 0, .as_none = none__none() }
		: _op_equal_equal__bool__arr__char__arr__char(key, at__arr__char__arr__arr__char__nat(_ctx, keys, idx))
			? (opt__arr__arr__char) { 1, .as_some__arr__arr__char = some__some__arr__arr__char__arr__arr__char(at__arr__arr__char__arr__arr__arr__char__nat(_ctx, values, idx)) }
			: get_recursive__opt__arr__arr__char__arr__arr__char__arr__arr__arr__char__nat__arr__char(_ctx, keys, values, incr__nat__nat(_ctx, idx), key);
}
some__arr__arr__char some__some__arr__arr__char__arr__arr__char(arr__arr__char t) {
	return (some__arr__arr__char) {t};
}
arr__arr__char at__arr__arr__char__arr__arr__arr__char__nat(ctx* _ctx, arr__arr__arr__char a, nat index) {
	return (assert___void__bool(_ctx, _op_less__bool__nat__nat(index, a.size)),
	noctx_at__arr__arr__char__arr__arr__arr__char__nat(a, index));
}
arr__arr__char noctx_at__arr__arr__char__arr__arr__arr__char__nat(arr__arr__arr__char a, nat index) {
	return (hard_assert___void__bool(_op_less__bool__nat__nat(index, a.size)),
	*((a.data + index)));
}
dict__arr__char__arr__arr__char* unsafe_as_dict__ptr_dict__arr__char__arr__arr__char__mut_dict__arr__char__arr__arr__char(ctx* _ctx, mut_dict__arr__char__arr__arr__char m) {
	return _initdict__arr__char__arr__arr__char(alloc__ptr__byte__nat(_ctx, 32), (dict__arr__char__arr__arr__char) {unsafe_as_arr__arr__arr__char__ptr_mut_arr__arr__char(m.keys), unsafe_as_arr__arr__arr__arr__char__ptr_mut_arr__arr__arr__char(m.values)});
}
arr__arr__arr__char unsafe_as_arr__arr__arr__arr__char__ptr_mut_arr__arr__arr__char(mut_arr__arr__arr__char* a) {
	return (arr__arr__arr__char) {a->size, a->data};
}
_void push___void__ptr_mut_arr__arr__char__arr__char(ctx* _ctx, mut_arr__arr__char* a, arr__char value) {
	return ((((_op_equal_equal__bool__nat__nat(a->size, a->capacity)
		? increase_capacity_to___void__ptr_mut_arr__arr__char__nat(_ctx, a, (zero__q__bool__nat(a->size) ? four__nat() : _op_times__nat__nat__nat(_ctx, a->size, two__nat())))
		: 0,
	ensure_capacity___void__ptr_mut_arr__arr__char__nat(_ctx, a, round_up_to_power_of_two__nat__nat(_ctx, incr__nat__nat(_ctx, a->size)))),
	assert___void__bool(_ctx, _op_less__bool__nat__nat(a->size, a->capacity))),
	((*((a->data + a->size)) = value), 0)),
	(a->size = incr__nat__nat(_ctx, a->size)), 0);
}
_void increase_capacity_to___void__ptr_mut_arr__arr__char__nat(ctx* _ctx, mut_arr__arr__char* a, nat new_capacity) {
	ptr__arr__char old_data;
	return (assert___void__bool(_ctx, _op_greater__bool__nat__nat(new_capacity, a->capacity)),
	((old_data = a->data),
	(((a->capacity = new_capacity), 0,
	(a->data = uninitialized_data__ptr__arr__char__nat(_ctx, new_capacity)), 0),
	copy_data_from___void__ptr__arr__char__ptr__arr__char__nat(_ctx, a->data, old_data, a->size))));
}
_void copy_data_from___void__ptr__arr__char__ptr__arr__char__nat(ctx* _ctx, ptr__arr__char to, ptr__arr__char from, nat len) {
	nat hl;
	return _op_less__bool__nat__nat(len, eight__nat())
		? copy_data_from_small___void__ptr__arr__char__ptr__arr__char__nat(_ctx, to, from, len)
		: ((hl = _op_div__nat__nat__nat(_ctx, len, two__nat())),
		(copy_data_from___void__ptr__arr__char__ptr__arr__char__nat(_ctx, to, from, hl),
		copy_data_from___void__ptr__arr__char__ptr__arr__char__nat(_ctx, (to + hl), (from + hl), _op_minus__nat__nat__nat(_ctx, len, hl))));
}
_void copy_data_from_small___void__ptr__arr__char__ptr__arr__char__nat(ctx* _ctx, ptr__arr__char to, ptr__arr__char from, nat len) {
	return zero__q__bool__nat(len)
		? 0
		: (((*(to) = *(from)), 0),
		copy_data_from___void__ptr__arr__char__ptr__arr__char__nat(_ctx, incr__ptr__arr__char__ptr__arr__char(to), incr__ptr__arr__char__ptr__arr__char(from), decr__nat__nat(_ctx, len)));
}
ptr__arr__char incr__ptr__arr__char__ptr__arr__char(ptr__arr__char p) {
	return (p + 1);
}
nat decr__nat__nat(ctx* _ctx, nat a) {
	return (forbid___void__bool(_ctx, zero__q__bool__nat(a)),
	wrap_decr__nat__nat(a));
}
nat wrap_decr__nat__nat(nat a) {
	return (a - 1);
}
nat _op_times__nat__nat__nat(ctx* _ctx, nat a, nat b) {
	nat res;
	return (zero__q__bool__nat(a) || zero__q__bool__nat(b))
		? 0
		: ((res = (a * b)),
		((assert___void__bool(_ctx, _op_equal_equal__bool__nat__nat(_op_div__nat__nat__nat(_ctx, res, b), a)),
		assert___void__bool(_ctx, _op_equal_equal__bool__nat__nat(_op_div__nat__nat__nat(_ctx, res, a), b))),
		res));
}
_void ensure_capacity___void__ptr_mut_arr__arr__char__nat(ctx* _ctx, mut_arr__arr__char* a, nat capacity) {
	return _op_less__bool__nat__nat(a->capacity, capacity)
		? increase_capacity_to___void__ptr_mut_arr__arr__char__nat(_ctx, a, round_up_to_power_of_two__nat__nat(_ctx, capacity))
		: 0;
}
nat round_up_to_power_of_two__nat__nat(ctx* _ctx, nat n) {
	return round_up_to_power_of_two_recur__nat__nat__nat(_ctx, 1, n);
}
nat round_up_to_power_of_two_recur__nat__nat__nat(ctx* _ctx, nat acc, nat n) {
	return _op_greater_equal__bool__nat__nat(acc, n)
		? acc
		: round_up_to_power_of_two_recur__nat__nat__nat(_ctx, _op_times__nat__nat__nat(_ctx, acc, two__nat()), n);
}
_void push___void__ptr_mut_arr__arr__arr__char__arr__arr__char(ctx* _ctx, mut_arr__arr__arr__char* a, arr__arr__char value) {
	return ((((_op_equal_equal__bool__nat__nat(a->size, a->capacity)
		? increase_capacity_to___void__ptr_mut_arr__arr__arr__char__nat(_ctx, a, (zero__q__bool__nat(a->size) ? four__nat() : _op_times__nat__nat__nat(_ctx, a->size, two__nat())))
		: 0,
	ensure_capacity___void__ptr_mut_arr__arr__arr__char__nat(_ctx, a, round_up_to_power_of_two__nat__nat(_ctx, incr__nat__nat(_ctx, a->size)))),
	assert___void__bool(_ctx, _op_less__bool__nat__nat(a->size, a->capacity))),
	((*((a->data + a->size)) = value), 0)),
	(a->size = incr__nat__nat(_ctx, a->size)), 0);
}
_void increase_capacity_to___void__ptr_mut_arr__arr__arr__char__nat(ctx* _ctx, mut_arr__arr__arr__char* a, nat new_capacity) {
	ptr__arr__arr__char old_data;
	return (assert___void__bool(_ctx, _op_greater__bool__nat__nat(new_capacity, a->capacity)),
	((old_data = a->data),
	(((a->capacity = new_capacity), 0,
	(a->data = uninitialized_data__ptr__arr__arr__char__nat(_ctx, new_capacity)), 0),
	copy_data_from___void__ptr__arr__arr__char__ptr__arr__arr__char__nat(_ctx, a->data, old_data, a->size))));
}
ptr__arr__arr__char uninitialized_data__ptr__arr__arr__char__nat(ctx* _ctx, nat size) {
	ptr__byte bptr;
	return ((bptr = alloc__ptr__byte__nat(_ctx, (size * sizeof(arr__arr__char)))),
	(ptr__arr__arr__char) bptr);
}
_void copy_data_from___void__ptr__arr__arr__char__ptr__arr__arr__char__nat(ctx* _ctx, ptr__arr__arr__char to, ptr__arr__arr__char from, nat len) {
	nat hl;
	return _op_less__bool__nat__nat(len, eight__nat())
		? copy_data_from_small___void__ptr__arr__arr__char__ptr__arr__arr__char__nat(_ctx, to, from, len)
		: ((hl = _op_div__nat__nat__nat(_ctx, len, two__nat())),
		(copy_data_from___void__ptr__arr__arr__char__ptr__arr__arr__char__nat(_ctx, to, from, hl),
		copy_data_from___void__ptr__arr__arr__char__ptr__arr__arr__char__nat(_ctx, (to + hl), (from + hl), _op_minus__nat__nat__nat(_ctx, len, hl))));
}
_void copy_data_from_small___void__ptr__arr__arr__char__ptr__arr__arr__char__nat(ctx* _ctx, ptr__arr__arr__char to, ptr__arr__arr__char from, nat len) {
	return zero__q__bool__nat(len)
		? 0
		: (((*(to) = *(from)), 0),
		copy_data_from___void__ptr__arr__arr__char__ptr__arr__arr__char__nat(_ctx, incr__ptr__arr__arr__char__ptr__arr__arr__char(to), incr__ptr__arr__arr__char__ptr__arr__arr__char(from), decr__nat__nat(_ctx, len)));
}
ptr__arr__arr__char incr__ptr__arr__arr__char__ptr__arr__arr__char(ptr__arr__arr__char p) {
	return (p + 1);
}
_void ensure_capacity___void__ptr_mut_arr__arr__arr__char__nat(ctx* _ctx, mut_arr__arr__arr__char* a, nat capacity) {
	return _op_less__bool__nat__nat(a->capacity, capacity)
		? increase_capacity_to___void__ptr_mut_arr__arr__arr__char__nat(_ctx, a, round_up_to_power_of_two__nat__nat(_ctx, capacity))
		: 0;
}
dict__arr__char__arr__arr__char* freeze__ptr_dict__arr__char__arr__arr__char__mut_dict__arr__char__arr__arr__char(ctx* _ctx, mut_dict__arr__char__arr__arr__char m) {
	return _initdict__arr__char__arr__arr__char(alloc__ptr__byte__nat(_ctx, 32), (dict__arr__char__arr__arr__char) {freeze__arr__arr__char__ptr_mut_arr__arr__char(m.keys), freeze__arr__arr__arr__char__ptr_mut_arr__arr__arr__char(m.values)});
}
arr__arr__arr__char freeze__arr__arr__arr__char__ptr_mut_arr__arr__arr__char(mut_arr__arr__arr__char* a) {
	return ((a->frozen__q = 1), 0,
	unsafe_as_arr__arr__arr__arr__char__ptr_mut_arr__arr__arr__char(a));
}
arr__arr__char slice_after__arr__arr__char__arr__arr__char__nat(ctx* _ctx, arr__arr__char a, nat before_begin) {
	return slice_starting_at__arr__arr__char__arr__arr__char__nat(_ctx, a, incr__nat__nat(_ctx, before_begin));
}
mut_arr__opt__arr__arr__char* fill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat__opt__arr__arr__char(ctx* _ctx, nat size, opt__arr__arr__char value) {
	return make_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat__fun_mut1__opt__arr__arr__char__nat(_ctx, size, (fun_mut1__opt__arr__arr__char__nat) {
		(fun_ptr3__opt__arr__arr__char__ptr_ctx__ptr__byte__nat) fill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat__opt__arr__arr__char__lambda0,
		(ptr__byte) _initfill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat__opt__arr__arr__char__lambda0___closure(alloc__ptr__byte__nat(_ctx, 24), (fill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat__opt__arr__arr__char__lambda0___closure) {value})
	});
}
mut_arr__opt__arr__arr__char* make_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat__fun_mut1__opt__arr__arr__char__nat(ctx* _ctx, nat size, fun_mut1__opt__arr__arr__char__nat f) {
	mut_arr__opt__arr__arr__char* res;
	return ((res = new_uninitialized_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat(_ctx, size)),
	(make_mut_arr_worker___void__ptr_mut_arr__opt__arr__arr__char__nat__nat__fun_mut1__opt__arr__arr__char__nat(_ctx, res, 0, size, f),
	res));
}
mut_arr__opt__arr__arr__char* new_uninitialized_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat(ctx* _ctx, nat size) {
	return _initmut_arr__opt__arr__arr__char(alloc__ptr__byte__nat(_ctx, 32), (mut_arr__opt__arr__arr__char) {0, size, size, uninitialized_data__ptr__opt__arr__arr__char__nat(_ctx, size)});
}
ptr__opt__arr__arr__char uninitialized_data__ptr__opt__arr__arr__char__nat(ctx* _ctx, nat size) {
	ptr__byte bptr;
	return ((bptr = alloc__ptr__byte__nat(_ctx, (size * sizeof(opt__arr__arr__char)))),
	(ptr__opt__arr__arr__char) bptr);
}
_void make_mut_arr_worker___void__ptr_mut_arr__opt__arr__arr__char__nat__nat__fun_mut1__opt__arr__arr__char__nat(ctx* _ctx, mut_arr__opt__arr__arr__char* m, nat lo, nat hi, fun_mut1__opt__arr__arr__char__nat f) {
	nat mid;
	return _op_equal_equal__bool__nat__nat(lo, hi)
		? 0
		: (set_at___void__ptr_mut_arr__opt__arr__arr__char__nat__opt__arr__arr__char(_ctx, m, lo, call__opt__arr__arr__char__fun_mut1__opt__arr__arr__char__nat__nat(_ctx, f, lo)),
		((mid = _op_div__nat__nat__nat(_ctx, _op_plus__nat__nat__nat(_ctx, incr__nat__nat(_ctx, lo), hi), two__nat())),
		(make_mut_arr_worker___void__ptr_mut_arr__opt__arr__arr__char__nat__nat__fun_mut1__opt__arr__arr__char__nat(_ctx, m, incr__nat__nat(_ctx, lo), mid, f),
		make_mut_arr_worker___void__ptr_mut_arr__opt__arr__arr__char__nat__nat__fun_mut1__opt__arr__arr__char__nat(_ctx, m, mid, hi, f))));
}
_void set_at___void__ptr_mut_arr__opt__arr__arr__char__nat__opt__arr__arr__char(ctx* _ctx, mut_arr__opt__arr__arr__char* a, nat index, opt__arr__arr__char value) {
	return (assert___void__bool(_ctx, _op_less__bool__nat__nat(index, a->size)),
	noctx_set_at___void__ptr_mut_arr__opt__arr__arr__char__nat__opt__arr__arr__char(a, index, value));
}
_void noctx_set_at___void__ptr_mut_arr__opt__arr__arr__char__nat__opt__arr__arr__char(mut_arr__opt__arr__arr__char* a, nat index, opt__arr__arr__char value) {
	return (hard_assert___void__bool(_op_less__bool__nat__nat(index, a->size)),
	((*((a->data + index)) = value), 0));
}
opt__arr__arr__char call__opt__arr__arr__char__fun_mut1__opt__arr__arr__char__nat__nat(ctx* _ctx, fun_mut1__opt__arr__arr__char__nat f, nat p0) {
	return call_with_ctx__opt__arr__arr__char__ptr_ctx__fun_mut1__opt__arr__arr__char__nat__nat(_ctx, f, p0);
}
opt__arr__arr__char call_with_ctx__opt__arr__arr__char__ptr_ctx__fun_mut1__opt__arr__arr__char__nat__nat(ctx* c, fun_mut1__opt__arr__arr__char__nat f, nat p0) {
	return f.fun_ptr(c, f.closure, p0);
}
opt__arr__arr__char fill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat__opt__arr__arr__char__lambda0(ctx* _ctx, fill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat__opt__arr__arr__char__lambda0___closure* _closure, nat ignore) {
	return _closure->value;
}
cell__bool* new_cell__ptr_cell__bool__bool(ctx* _ctx, bool value) {
	return _initcell__bool(alloc__ptr__byte__nat(_ctx, 1), (cell__bool) {value});
}
_void each___void__ptr_dict__arr__char__arr__arr__char__fun_mut2___void__arr__char__arr__arr__char(ctx* _ctx, dict__arr__char__arr__arr__char* d, fun_mut2___void__arr__char__arr__arr__char f) {
	return empty__q__bool__ptr_dict__arr__char__arr__arr__char(_ctx, d)
		? 0
		: (call___void__fun_mut2___void__arr__char__arr__arr__char__arr__char__arr__arr__char(_ctx, f, first__arr__char__arr__arr__char(_ctx, d->keys), first__arr__arr__char__arr__arr__arr__char(_ctx, d->values)),
		each___void__ptr_dict__arr__char__arr__arr__char__fun_mut2___void__arr__char__arr__arr__char(_ctx, _initdict__arr__char__arr__arr__char(alloc__ptr__byte__nat(_ctx, 32), (dict__arr__char__arr__arr__char) {tail__arr__arr__char__arr__arr__char(_ctx, d->keys), tail__arr__arr__arr__char__arr__arr__arr__char(_ctx, d->values)}), f));
}
bool empty__q__bool__ptr_dict__arr__char__arr__arr__char(ctx* _ctx, dict__arr__char__arr__arr__char* d) {
	return empty__q__bool__arr__arr__char(d->keys);
}
_void call___void__fun_mut2___void__arr__char__arr__arr__char__arr__char__arr__arr__char(ctx* _ctx, fun_mut2___void__arr__char__arr__arr__char f, arr__char p0, arr__arr__char p1) {
	return call_with_ctx___void__ptr_ctx__fun_mut2___void__arr__char__arr__arr__char__arr__char__arr__arr__char(_ctx, f, p0, p1);
}
_void call_with_ctx___void__ptr_ctx__fun_mut2___void__arr__char__arr__arr__char__arr__char__arr__arr__char(ctx* c, fun_mut2___void__arr__char__arr__arr__char f, arr__char p0, arr__arr__char p1) {
	return f.fun_ptr(c, f.closure, p0, p1);
}
arr__arr__char first__arr__arr__char__arr__arr__arr__char(ctx* _ctx, arr__arr__arr__char a) {
	return (forbid___void__bool(_ctx, empty__q__bool__arr__arr__arr__char(a)),
	at__arr__arr__char__arr__arr__arr__char__nat(_ctx, a, 0));
}
bool empty__q__bool__arr__arr__arr__char(arr__arr__arr__char a) {
	return zero__q__bool__nat(a.size);
}
arr__arr__arr__char tail__arr__arr__arr__char__arr__arr__arr__char(ctx* _ctx, arr__arr__arr__char a) {
	return (forbid___void__bool(_ctx, empty__q__bool__arr__arr__arr__char(a)),
	slice_starting_at__arr__arr__arr__char__arr__arr__arr__char__nat(_ctx, a, 1));
}
arr__arr__arr__char slice_starting_at__arr__arr__arr__char__arr__arr__arr__char__nat(ctx* _ctx, arr__arr__arr__char a, nat begin) {
	return (assert___void__bool(_ctx, _op_less_equal__bool__nat__nat(begin, a.size)),
	slice__arr__arr__arr__char__arr__arr__arr__char__nat__nat(_ctx, a, begin, _op_minus__nat__nat__nat(_ctx, a.size, begin)));
}
arr__arr__arr__char slice__arr__arr__arr__char__arr__arr__arr__char__nat__nat(ctx* _ctx, arr__arr__arr__char a, nat begin, nat size) {
	return (assert___void__bool(_ctx, _op_less_equal__bool__nat__nat(_op_plus__nat__nat__nat(_ctx, begin, size), a.size)),
	(arr__arr__arr__char) {size, (a.data + begin)});
}
opt__nat index_of__opt__nat__arr__arr__char__arr__char(ctx* _ctx, arr__arr__char a, arr__char value) {
	return find_index__opt__nat__arr__arr__char__fun_mut1__bool__arr__char(_ctx, a, (fun_mut1__bool__arr__char) {
		(fun_ptr3__bool__ptr_ctx__ptr__byte__arr__char) index_of__opt__nat__arr__arr__char__arr__char__lambda0,
		(ptr__byte) _initindex_of__opt__nat__arr__arr__char__arr__char__lambda0___closure(alloc__ptr__byte__nat(_ctx, 16), (index_of__opt__nat__arr__arr__char__arr__char__lambda0___closure) {value})
	});
}
bool index_of__opt__nat__arr__arr__char__arr__char__lambda0(ctx* _ctx, index_of__opt__nat__arr__arr__char__arr__char__lambda0___closure* _closure, arr__char it) {
	return _op_equal_equal__bool__arr__char__arr__char(it, _closure->value);
}
_void set___void__ptr_cell__bool__bool(cell__bool* c, bool v) {
	return (c->value = v), 0;
}
arr__char _op_plus__arr__char__arr__char__arr__char(ctx* _ctx, arr__char a, arr__char b) {
	return make_arr__arr__char__nat__fun_mut1__char__nat(_ctx, _op_plus__nat__nat__nat(_ctx, a.size, b.size), (fun_mut1__char__nat) {
		(fun_ptr3__char__ptr_ctx__ptr__byte__nat) _op_plus__arr__char__arr__char__arr__char__lambda0,
		(ptr__byte) _init_op_plus__arr__char__arr__char__arr__char__lambda0___closure(alloc__ptr__byte__nat(_ctx, 32), (_op_plus__arr__char__arr__char__arr__char__lambda0___closure) {a, b})
	});
}
arr__char make_arr__arr__char__nat__fun_mut1__char__nat(ctx* _ctx, nat size, fun_mut1__char__nat f) {
	return freeze__arr__char__ptr_mut_arr__char(make_mut_arr__ptr_mut_arr__char__nat__fun_mut1__char__nat(_ctx, size, f));
}
arr__char freeze__arr__char__ptr_mut_arr__char(mut_arr__char* a) {
	return ((a->frozen__q = 1), 0,
	unsafe_as_arr__arr__char__ptr_mut_arr__char(a));
}
arr__char unsafe_as_arr__arr__char__ptr_mut_arr__char(mut_arr__char* a) {
	return (arr__char) {a->size, a->data};
}
mut_arr__char* make_mut_arr__ptr_mut_arr__char__nat__fun_mut1__char__nat(ctx* _ctx, nat size, fun_mut1__char__nat f) {
	mut_arr__char* res;
	return ((res = new_uninitialized_mut_arr__ptr_mut_arr__char__nat(_ctx, size)),
	(make_mut_arr_worker___void__ptr_mut_arr__char__nat__nat__fun_mut1__char__nat(_ctx, res, 0, size, f),
	res));
}
mut_arr__char* new_uninitialized_mut_arr__ptr_mut_arr__char__nat(ctx* _ctx, nat size) {
	return _initmut_arr__char(alloc__ptr__byte__nat(_ctx, 32), (mut_arr__char) {0, size, size, uninitialized_data__ptr__char__nat(_ctx, size)});
}
ptr__char uninitialized_data__ptr__char__nat(ctx* _ctx, nat size) {
	ptr__byte bptr;
	return ((bptr = alloc__ptr__byte__nat(_ctx, (size * sizeof(char)))),
	(ptr__char) bptr);
}
_void make_mut_arr_worker___void__ptr_mut_arr__char__nat__nat__fun_mut1__char__nat(ctx* _ctx, mut_arr__char* m, nat lo, nat hi, fun_mut1__char__nat f) {
	nat mid;
	return _op_equal_equal__bool__nat__nat(lo, hi)
		? 0
		: (set_at___void__ptr_mut_arr__char__nat__char(_ctx, m, lo, call__char__fun_mut1__char__nat__nat(_ctx, f, lo)),
		((mid = _op_div__nat__nat__nat(_ctx, _op_plus__nat__nat__nat(_ctx, incr__nat__nat(_ctx, lo), hi), two__nat())),
		(make_mut_arr_worker___void__ptr_mut_arr__char__nat__nat__fun_mut1__char__nat(_ctx, m, incr__nat__nat(_ctx, lo), mid, f),
		make_mut_arr_worker___void__ptr_mut_arr__char__nat__nat__fun_mut1__char__nat(_ctx, m, mid, hi, f))));
}
_void set_at___void__ptr_mut_arr__char__nat__char(ctx* _ctx, mut_arr__char* a, nat index, char value) {
	return (assert___void__bool(_ctx, _op_less__bool__nat__nat(index, a->size)),
	noctx_set_at___void__ptr_mut_arr__char__nat__char(a, index, value));
}
_void noctx_set_at___void__ptr_mut_arr__char__nat__char(mut_arr__char* a, nat index, char value) {
	return (hard_assert___void__bool(_op_less__bool__nat__nat(index, a->size)),
	((*((a->data + index)) = value), 0));
}
char call__char__fun_mut1__char__nat__nat(ctx* _ctx, fun_mut1__char__nat f, nat p0) {
	return call_with_ctx__char__ptr_ctx__fun_mut1__char__nat__nat(_ctx, f, p0);
}
char call_with_ctx__char__ptr_ctx__fun_mut1__char__nat__nat(ctx* c, fun_mut1__char__nat f, nat p0) {
	return f.fun_ptr(c, f.closure, p0);
}
char _op_plus__arr__char__arr__char__arr__char__lambda0(ctx* _ctx, _op_plus__arr__char__arr__char__arr__char__lambda0___closure* _closure, nat i) {
	return _op_less__bool__nat__nat(i, _closure->a.size)
		? at__char__arr__char__nat(_ctx, _closure->a, i)
		: at__char__arr__char__nat(_ctx, _closure->b, _op_minus__nat__nat__nat(_ctx, i, _closure->a.size));
}
opt__arr__arr__char at__opt__arr__arr__char__ptr_mut_arr__opt__arr__arr__char__nat(ctx* _ctx, mut_arr__opt__arr__arr__char* a, nat index) {
	return (assert___void__bool(_ctx, _op_less__bool__nat__nat(index, a->size)),
	noctx_at__opt__arr__arr__char__ptr_mut_arr__opt__arr__arr__char__nat(a, index));
}
opt__arr__arr__char noctx_at__opt__arr__arr__char__ptr_mut_arr__opt__arr__arr__char__nat(mut_arr__opt__arr__arr__char* a, nat index) {
	return (hard_assert___void__bool(_op_less__bool__nat__nat(index, a->size)),
	*((a->data + index)));
}
_void parse_cmd_line_args__opt__test_options__arr__arr__char__arr__arr__char__fun1__test_options__arr__opt__arr__arr__char__lambda0(ctx* _ctx, parse_cmd_line_args__opt__test_options__arr__arr__char__arr__arr__char__fun1__test_options__arr__opt__arr__arr__char__lambda0___closure* _closure, arr__char key, arr__arr__char value) {
	some__nat s;
	nat idx;
	opt__nat matched;
	return (matched = index_of__opt__nat__arr__arr__char__arr__char(_ctx, _closure->t_names, key),
		matched.kind == 0
		? _op_equal_equal__bool__arr__char__arr__char(key, (arr__char){4, "help"})
			? set___void__ptr_cell__bool__bool(_closure->help, 1)
			: fail___void__arr__char(_ctx, _op_plus__arr__char__arr__char__arr__char(_ctx, (arr__char){15, "Unexpected arg "}, key))
		: matched.kind == 1
		? (s = matched.as_some__nat,
		((idx = s.value),
		(forbid___void__bool(_ctx, has__q__bool__opt__arr__arr__char(at__opt__arr__arr__char__ptr_mut_arr__opt__arr__arr__char__nat(_ctx, _closure->values, idx))),
		set_at___void__ptr_mut_arr__opt__arr__arr__char__nat__opt__arr__arr__char(_ctx, _closure->values, idx, (opt__arr__arr__char) { 1, .as_some__arr__arr__char = some__some__arr__arr__char__arr__arr__char(value) })))
		): _fail_void());
}
bool get__bool__ptr_cell__bool(cell__bool* c) {
	return c->value;
}
some__test_options some__some__test_options__test_options(test_options t) {
	return (some__test_options) {t};
}
test_options call__test_options__fun1__test_options__arr__opt__arr__arr__char__arr__opt__arr__arr__char(ctx* _ctx, fun1__test_options__arr__opt__arr__arr__char f, arr__opt__arr__arr__char p0) {
	return call_with_ctx__test_options__ptr_ctx__fun1__test_options__arr__opt__arr__arr__char__arr__opt__arr__arr__char(_ctx, f, p0);
}
test_options call_with_ctx__test_options__ptr_ctx__fun1__test_options__arr__opt__arr__arr__char__arr__opt__arr__arr__char(ctx* c, fun1__test_options__arr__opt__arr__arr__char f, arr__opt__arr__arr__char p0) {
	return f.fun_ptr(c, f.closure, p0);
}
arr__opt__arr__arr__char freeze__arr__opt__arr__arr__char__ptr_mut_arr__opt__arr__arr__char(mut_arr__opt__arr__arr__char* a) {
	return ((a->frozen__q = 1), 0,
	unsafe_as_arr__arr__opt__arr__arr__char__ptr_mut_arr__opt__arr__arr__char(a));
}
arr__opt__arr__arr__char unsafe_as_arr__arr__opt__arr__arr__char__ptr_mut_arr__opt__arr__arr__char(mut_arr__opt__arr__arr__char* a) {
	return (arr__opt__arr__arr__char) {a->size, a->data};
}
opt__arr__arr__char at__opt__arr__arr__char__arr__opt__arr__arr__char__nat(ctx* _ctx, arr__opt__arr__arr__char a, nat index) {
	return (assert___void__bool(_ctx, _op_less__bool__nat__nat(index, a.size)),
	noctx_at__opt__arr__arr__char__arr__opt__arr__arr__char__nat(a, index));
}
opt__arr__arr__char noctx_at__opt__arr__arr__char__arr__opt__arr__arr__char__nat(arr__opt__arr__arr__char a, nat index) {
	return (hard_assert___void__bool(_op_less__bool__nat__nat(index, a.size)),
	*((a.data + index)));
}
nat literal__nat__arr__char(ctx* _ctx, arr__char s) {
	nat higher_digits;
	return empty__q__bool__arr__char(s)
		? 0
		: ((higher_digits = literal__nat__arr__char(_ctx, rtail__arr__char__arr__char(_ctx, s))),
		_op_plus__nat__nat__nat(_ctx, _op_times__nat__nat__nat(_ctx, higher_digits, ten__nat()), char_to_nat__nat__char(last__char__arr__char(_ctx, s))));
}
arr__char rtail__arr__char__arr__char(ctx* _ctx, arr__char a) {
	return (forbid___void__bool(_ctx, empty__q__bool__arr__char(a)),
	slice__arr__char__arr__char__nat__nat(_ctx, a, 0, decr__nat__nat(_ctx, a.size)));
}
nat char_to_nat__nat__char(char c) {
	return _op_equal_equal__bool__char__char(c, literal__char__arr__char((arr__char){1, "0"}))
		? 0
		: _op_equal_equal__bool__char__char(c, literal__char__arr__char((arr__char){1, "1"}))
			? 1
			: _op_equal_equal__bool__char__char(c, literal__char__arr__char((arr__char){1, "2"}))
				? two__nat()
				: _op_equal_equal__bool__char__char(c, literal__char__arr__char((arr__char){1, "3"}))
					? three__nat()
					: _op_equal_equal__bool__char__char(c, literal__char__arr__char((arr__char){1, "4"}))
						? four__nat()
						: _op_equal_equal__bool__char__char(c, literal__char__arr__char((arr__char){1, "5"}))
							? five__nat()
							: _op_equal_equal__bool__char__char(c, literal__char__arr__char((arr__char){1, "6"}))
								? six__nat()
								: _op_equal_equal__bool__char__char(c, literal__char__arr__char((arr__char){1, "7"}))
									? seven__nat()
									: _op_equal_equal__bool__char__char(c, literal__char__arr__char((arr__char){1, "8"}))
										? eight__nat()
										: _op_equal_equal__bool__char__char(c, literal__char__arr__char((arr__char){1, "9"}))
											? nine__nat()
											: todo__nat();
}
nat todo__nat() {
	return hard_fail__nat__arr__char((arr__char){4, "TODO"});
}
nat hard_fail__nat__arr__char(arr__char reason) {
	assert(0);
}
char last__char__arr__char(ctx* _ctx, arr__char a) {
	return (forbid___void__bool(_ctx, empty__q__bool__arr__char(a)),
	at__char__arr__char__nat(_ctx, a, decr__nat__nat(_ctx, a.size)));
}
test_options main__ptr_fut__int32__arr__arr__char__lambda0(ctx* _ctx, ptr__byte _closure, arr__opt__arr__arr__char values) {
	opt__arr__arr__char print_tests_strs;
	opt__arr__arr__char overwrite_output_strs;
	opt__arr__arr__char max_failures_strs;
	bool print_tests__q;
	some__arr__arr__char s;
	opt__arr__arr__char matched;
	bool overwrite_output__q;
	some__arr__arr__char s1;
	arr__arr__char strs;
	opt__arr__arr__char matched1;
	nat max_failures;
	return ((print_tests_strs = at__opt__arr__arr__char__arr__opt__arr__arr__char__nat(_ctx, values, literal__nat__arr__char(_ctx, (arr__char){1, "0"}))),
	((overwrite_output_strs = at__opt__arr__arr__char__arr__opt__arr__arr__char__nat(_ctx, values, literal__nat__arr__char(_ctx, (arr__char){1, "1"}))),
	((max_failures_strs = at__opt__arr__arr__char__arr__opt__arr__arr__char__nat(_ctx, values, literal__nat__arr__char(_ctx, (arr__char){1, "2"}))),
	((print_tests__q = has__q__bool__opt__arr__arr__char(print_tests_strs)),
	((overwrite_output__q = (matched = overwrite_output_strs,
		matched.kind == 0
		? 0
		: matched.kind == 1
		? (s = matched.as_some__arr__arr__char,
		(assert___void__bool(_ctx, empty__q__bool__arr__arr__char(s.value)),
		1)
		): _failbool())),
	((max_failures = (matched1 = max_failures_strs,
		matched1.kind == 0
		? literal__nat__arr__char(_ctx, (arr__char){3, "100"})
		: matched1.kind == 1
		? (s1 = matched1.as_some__arr__arr__char,
		((strs = s1.value),
		(assert___void__bool(_ctx, _op_equal_equal__bool__nat__nat(strs.size, literal__nat__arr__char(_ctx, (arr__char){1, "1"}))),
		literal__nat__arr__char(_ctx, first__arr__char__arr__arr__char(_ctx, strs))))
		): _failnat())),
	(test_options) {print_tests__q, overwrite_output__q, max_failures}))))));
}
fut__int32* resolved__ptr_fut__int32__int32(ctx* _ctx, int32 value) {
	return _initfut__int32(alloc__ptr__byte__nat(_ctx, 32), (fut__int32) {new_lock__lock(), (fut_state__int32) { 1, .as_fut_state_resolved__int32 = (fut_state_resolved__int32) {value} }});
}
_void print_help___void(ctx* _ctx) {
	return (((print_sync___void__arr__char((arr__char){18, "test -- runs tests"}),
	print_sync___void__arr__char((arr__char){8, "options:"})),
	print_sync___void__arr__char((arr__char){38, "\t--print-tests  : print every test run"})),
	print_sync___void__arr__char((arr__char){64, "\t--max-failures : stop after this many failures. Defaults to 10."}));
}
_void print_sync___void__arr__char(arr__char s) {
	return (print_sync_no_newline___void__arr__char(s),
	print_sync_no_newline___void__arr__char((arr__char){1, "\n"}));
}
_void print_sync_no_newline___void__arr__char(arr__char s) {
	return write_sync_no_newline___void__int32__arr__char(stdout_fd__int32(), s);
}
int32 stdout_fd__int32() {
	return 1;
}
int32 literal__int32__arr__char(ctx* _ctx, arr__char s) {
	return (int32) literal___int__arr__char(_ctx, s);
}
_int literal___int__arr__char(ctx* _ctx, arr__char s) {
	char fst;
	nat n;
	return ((fst = at__char__arr__char__nat(_ctx, s, 0)),
	_op_equal_equal__bool__char__char(fst, literal__char__arr__char((arr__char){1, "-"}))
		? ((n = literal__nat__arr__char(_ctx, tail__arr__char__arr__char(_ctx, s))),
		neg___int__nat(_ctx, n))
		: _op_equal_equal__bool__char__char(fst, literal__char__arr__char((arr__char){1, "+"}))
			? to_int___int__nat(_ctx, literal__nat__arr__char(_ctx, tail__arr__char__arr__char(_ctx, s)))
			: to_int___int__nat(_ctx, literal__nat__arr__char(_ctx, s)));
}
_int neg___int__nat(ctx* _ctx, nat n) {
	return neg___int___int(_ctx, to_int___int__nat(_ctx, n));
}
_int neg___int___int(ctx* _ctx, _int i) {
	return _op_times___int___int___int(_ctx, i, neg_one___int());
}
_int _op_times___int___int___int(ctx* _ctx, _int a, _int b) {
	return ((((assert___void__bool(_ctx, _op_greater__bool___int___int(a, neg_million___int())),
	assert___void__bool(_ctx, _op_less__bool___int___int(a, million___int()))),
	assert___void__bool(_ctx, _op_greater__bool___int___int(b, neg_million___int()))),
	assert___void__bool(_ctx, _op_less__bool___int___int(b, million___int()))),
	(a * b));
}
bool _op_greater__bool___int___int(_int a, _int b) {
	return !(_op_less_equal__bool___int___int(a, b));
}
bool _op_less_equal__bool___int___int(_int a, _int b) {
	return !(_op_less__bool___int___int(b, a));
}
bool _op_less__bool___int___int(_int a, _int b) {
	comparison matched;
	return (matched = _op_less_equal_greater__comparison___int___int(a, b),
		matched.kind == 0
		? 1
		: matched.kind == 1
		? 0
		: matched.kind == 2
		? 0
		: _failbool());
}
_int neg_million___int() {
	return (million___int() * neg_one___int());
}
_int million___int() {
	return (thousand___int() * thousand___int());
}
_int thousand___int() {
	return (hundred___int() * ten___int());
}
_int hundred___int() {
	return (ten___int() * ten___int());
}
_int ten___int() {
	return wrap_incr___int___int(nine___int());
}
_int wrap_incr___int___int(_int a) {
	return (a + 1);
}
_int nine___int() {
	return wrap_incr___int___int(eight___int());
}
_int eight___int() {
	return wrap_incr___int___int(seven___int());
}
_int seven___int() {
	return wrap_incr___int___int(six___int());
}
_int six___int() {
	return wrap_incr___int___int(five___int());
}
_int five___int() {
	return wrap_incr___int___int(four___int());
}
_int four___int() {
	return wrap_incr___int___int(three___int());
}
_int three___int() {
	return wrap_incr___int___int(two___int());
}
_int two___int() {
	return wrap_incr___int___int(1);
}
_int neg_one___int() {
	return (0 - 1);
}
_int to_int___int__nat(ctx* _ctx, nat n) {
	return (assert___void__bool(_ctx, _op_less__bool__nat__nat(n, million__nat())),
	(_int) n);
}
int32 do_test__int32__test_options(ctx* _ctx, test_options options) {
	arr__char test_path;
	arr__char noze_path;
	arr__char noze_exe;
	dict__arr__char__arr__char* env;
	result__arr__char__arr__ptr_failure compile_failures;
	result__arr__char__arr__ptr_failure run_failures;
	result__arr__char__arr__ptr_failure all_failures;
	return ((test_path = parent_path__arr__char__arr__char(_ctx, current_executable_path__arr__char(_ctx))),
	((noze_path = parent_path__arr__char__arr__char(_ctx, test_path)),
	((noze_exe = child_path__arr__char__arr__char__arr__char(_ctx, noze_path, (arr__char){4, "noze"})),
	((env = get_environ__ptr_dict__arr__char__arr__char(_ctx)),
	((compile_failures = run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options(_ctx, child_path__arr__char__arr__char__arr__char(_ctx, test_path, (arr__char){14, "compile-errors"}), noze_exe, env, options)),
	((run_failures = first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure(_ctx, compile_failures, (fun0__result__arr__char__arr__ptr_failure) {
		(fun_ptr2__result__arr__char__arr__ptr_failure__ptr_ctx__ptr__byte) do_test__int32__test_options__lambda0,
		(ptr__byte) _initdo_test__int32__test_options__lambda0___closure(alloc__ptr__byte__nat(_ctx, 56), (do_test__int32__test_options__lambda0___closure) {test_path, noze_exe, env, options})
	})),
	((all_failures = first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure(_ctx, run_failures, (fun0__result__arr__char__arr__ptr_failure) {
		(fun_ptr2__result__arr__char__arr__ptr_failure__ptr_ctx__ptr__byte) do_test__int32__test_options__lambda1,
		(ptr__byte) _initdo_test__int32__test_options__lambda1___closure(alloc__ptr__byte__nat(_ctx, 32), (do_test__int32__test_options__lambda1___closure) {noze_path, options})
	})),
	print_failures__int32__result__arr__char__arr__ptr_failure__test_options(_ctx, all_failures, options))))))));
}
arr__char parent_path__arr__char__arr__char(ctx* _ctx, arr__char a) {
	some__nat s;
	opt__nat matched;
	return (matched = r_index_of__opt__nat__arr__char__char(_ctx, a, literal__char__arr__char((arr__char){1, "/"})),
		matched.kind == 0
		? (arr__char){0, ""}
		: matched.kind == 1
		? (s = matched.as_some__nat,
		slice_up_to__arr__char__arr__char__nat(_ctx, a, s.value)
		): _failarr__char());
}
opt__nat r_index_of__opt__nat__arr__char__char(ctx* _ctx, arr__char a, char value) {
	return find_rindex__opt__nat__arr__char__fun_mut1__bool__char(_ctx, a, (fun_mut1__bool__char) {
		(fun_ptr3__bool__ptr_ctx__ptr__byte__char) r_index_of__opt__nat__arr__char__char__lambda0,
		(ptr__byte) _initr_index_of__opt__nat__arr__char__char__lambda0___closure(alloc__ptr__byte__nat(_ctx, 1), (r_index_of__opt__nat__arr__char__char__lambda0___closure) {value})
	});
}
opt__nat find_rindex__opt__nat__arr__char__fun_mut1__bool__char(ctx* _ctx, arr__char a, fun_mut1__bool__char pred) {
	return empty__q__bool__arr__char(a)
		? (opt__nat) { 0, .as_none = none__none() }
		: find_rindex_recur__opt__nat__arr__char__nat__fun_mut1__bool__char(_ctx, a, decr__nat__nat(_ctx, a.size), pred);
}
opt__nat find_rindex_recur__opt__nat__arr__char__nat__fun_mut1__bool__char(ctx* _ctx, arr__char a, nat index, fun_mut1__bool__char pred) {
	return call__bool__fun_mut1__bool__char__char(_ctx, pred, at__char__arr__char__nat(_ctx, a, index))
		? (opt__nat) { 1, .as_some__nat = some__some__nat__nat(index) }
		: zero__q__bool__nat(index)
			? (opt__nat) { 0, .as_none = none__none() }
			: find_rindex_recur__opt__nat__arr__char__nat__fun_mut1__bool__char(_ctx, a, decr__nat__nat(_ctx, index), pred);
}
bool call__bool__fun_mut1__bool__char__char(ctx* _ctx, fun_mut1__bool__char f, char p0) {
	return call_with_ctx__bool__ptr_ctx__fun_mut1__bool__char__char(_ctx, f, p0);
}
bool call_with_ctx__bool__ptr_ctx__fun_mut1__bool__char__char(ctx* c, fun_mut1__bool__char f, char p0) {
	return f.fun_ptr(c, f.closure, p0);
}
bool r_index_of__opt__nat__arr__char__char__lambda0(ctx* _ctx, r_index_of__opt__nat__arr__char__char__lambda0___closure* _closure, char it) {
	return _op_equal_equal__bool__char__char(it, _closure->value);
}
arr__char slice_up_to__arr__char__arr__char__nat(ctx* _ctx, arr__char a, nat size) {
	return (assert___void__bool(_ctx, _op_less__bool__nat__nat(size, a.size)),
	slice__arr__char__arr__char__nat__nat(_ctx, a, 0, size));
}
arr__char current_executable_path__arr__char(ctx* _ctx) {
	return read_link__arr__char__arr__char(_ctx, (arr__char){14, "/proc/self/exe"});
}
arr__char read_link__arr__char__arr__char(ctx* _ctx, arr__char path) {
	mut_arr__char* buff;
	_int size;
	return ((buff = new_uninitialized_mut_arr__ptr_mut_arr__char__nat(_ctx, thousand__nat())),
	((size = readlink(to_c_str__ptr__char__arr__char(_ctx, path), buff->data, buff->size)),
	(check_errno_if_neg_one___void___int(_ctx, size),
	slice_up_to__arr__char__arr__char__nat(_ctx, freeze__arr__char__ptr_mut_arr__char(buff), to_nat__nat___int(_ctx, size)))));
}
ptr__char to_c_str__ptr__char__arr__char(ctx* _ctx, arr__char a) {
	return _op_plus__arr__char__arr__char__arr__char(_ctx, a, (arr__char){1, "\0"}).data;
}
_void check_errno_if_neg_one___void___int(ctx* _ctx, _int e) {
	return _op_equal_equal__bool___int___int(e, neg_one___int())
		? (check_posix_error___void__int32(_ctx, get_errno__int32(_ctx)),
		hard_unreachable___void())
		: 0;
}
_void check_posix_error___void__int32(ctx* _ctx, int32 e) {
	return assert___void__bool(_ctx, zero__q__bool__int32(e));
}
int32 get_errno__int32(ctx* _ctx) {
	return errno;
}
_void hard_unreachable___void() {
	return hard_fail___void__arr__char((arr__char){11, "unreachable"});
}
nat to_nat__nat___int(ctx* _ctx, _int i) {
	return (forbid___void__bool(_ctx, negative__q__bool___int(_ctx, i)),
	(nat) i);
}
bool negative__q__bool___int(ctx* _ctx, _int i) {
	return _op_less__bool___int___int(i, 0);
}
arr__char child_path__arr__char__arr__char__arr__char(ctx* _ctx, arr__char a, arr__char child_name) {
	return _op_plus__arr__char__arr__char__arr__char(_ctx, _op_plus__arr__char__arr__char__arr__char(_ctx, a, (arr__char){1, "/"}), child_name);
}
dict__arr__char__arr__char* get_environ__ptr_dict__arr__char__arr__char(ctx* _ctx) {
	mut_dict__arr__char__arr__char res;
	return ((res = new_mut_dict__mut_dict__arr__char__arr__char(_ctx)),
	(get_environ_recur___void__ptr__ptr__char__mut_dict__arr__char__arr__char(_ctx, environ, res),
	freeze__ptr_dict__arr__char__arr__char__mut_dict__arr__char__arr__char(_ctx, res)));
}
mut_dict__arr__char__arr__char new_mut_dict__mut_dict__arr__char__arr__char(ctx* _ctx) {
	return (mut_dict__arr__char__arr__char) {new_mut_arr__ptr_mut_arr__arr__char(_ctx), new_mut_arr__ptr_mut_arr__arr__char(_ctx)};
}
_void get_environ_recur___void__ptr__ptr__char__mut_dict__arr__char__arr__char(ctx* _ctx, ptr__ptr__char env, mut_dict__arr__char__arr__char res) {
	return null__q__bool__ptr__char(*(env))
		? 0
		: (add___void__mut_dict__arr__char__arr__char__ptr_key_value_pair__arr__char__arr__char(_ctx, res, parse_environ_entry__ptr_key_value_pair__arr__char__arr__char__ptr__char(_ctx, *(env))),
		get_environ_recur___void__ptr__ptr__char__mut_dict__arr__char__arr__char(_ctx, incr__ptr__ptr__char__ptr__ptr__char(env), res));
}
bool null__q__bool__ptr__char(ptr__char a) {
	return _op_equal_equal__bool__ptr__char__ptr__char(a, NULL);
}
bool _op_equal_equal__bool__ptr__char__ptr__char(ptr__char a, ptr__char b) {
	comparison matched;
	return (matched = _op_less_equal_greater__comparison__ptr__char__ptr__char(a, b),
		matched.kind == 0
		? 0
		: matched.kind == 1
		? 1
		: matched.kind == 2
		? 0
		: _failbool());
}
comparison _op_less_equal_greater__comparison__ptr__char__ptr__char(ptr__char a, ptr__char b) {
	return (a < b)
		? (comparison) { 0, .as_less = (less) { 0 } }
		: (b < a)
			? (comparison) { 2, .as_greater = (greater) { 0 } }
			: (comparison) { 1, .as_equal = (equal) { 0 } };
}
_void add___void__mut_dict__arr__char__arr__char__ptr_key_value_pair__arr__char__arr__char(ctx* _ctx, mut_dict__arr__char__arr__char m, key_value_pair__arr__char__arr__char* pair) {
	return add___void__mut_dict__arr__char__arr__char__arr__char__arr__char(_ctx, m, pair->key, pair->value);
}
_void add___void__mut_dict__arr__char__arr__char__arr__char__arr__char(ctx* _ctx, mut_dict__arr__char__arr__char m, arr__char key, arr__char value) {
	return ((forbid___void__bool(_ctx, has__q__bool__mut_dict__arr__char__arr__char__arr__char(_ctx, m, key)),
	push___void__ptr_mut_arr__arr__char__arr__char(_ctx, m.keys, key)),
	push___void__ptr_mut_arr__arr__char__arr__char(_ctx, m.values, value));
}
bool has__q__bool__mut_dict__arr__char__arr__char__arr__char(ctx* _ctx, mut_dict__arr__char__arr__char d, arr__char key) {
	return has__q__bool__ptr_dict__arr__char__arr__char__arr__char(_ctx, unsafe_as_dict__ptr_dict__arr__char__arr__char__mut_dict__arr__char__arr__char(_ctx, d), key);
}
bool has__q__bool__ptr_dict__arr__char__arr__char__arr__char(ctx* _ctx, dict__arr__char__arr__char* d, arr__char key) {
	return has__q__bool__opt__arr__char(get__opt__arr__char__ptr_dict__arr__char__arr__char__arr__char(_ctx, d, key));
}
bool has__q__bool__opt__arr__char(opt__arr__char a) {
	return !(empty__q__bool__opt__arr__char(a));
}
bool empty__q__bool__opt__arr__char(opt__arr__char a) {
	none n;
	some__arr__char s;
	opt__arr__char matched;
	return (matched = a,
		matched.kind == 0
		? (n = matched.as_none,
		1
		): matched.kind == 1
		? (s = matched.as_some__arr__char,
		0
		): _failbool());
}
opt__arr__char get__opt__arr__char__ptr_dict__arr__char__arr__char__arr__char(ctx* _ctx, dict__arr__char__arr__char* d, arr__char key) {
	return get_recursive__opt__arr__char__arr__arr__char__arr__arr__char__nat__arr__char(_ctx, d->keys, d->values, 0, key);
}
opt__arr__char get_recursive__opt__arr__char__arr__arr__char__arr__arr__char__nat__arr__char(ctx* _ctx, arr__arr__char keys, arr__arr__char values, nat idx, arr__char key) {
	return _op_equal_equal__bool__nat__nat(idx, keys.size)
		? (opt__arr__char) { 0, .as_none = none__none() }
		: _op_equal_equal__bool__arr__char__arr__char(key, at__arr__char__arr__arr__char__nat(_ctx, keys, idx))
			? (opt__arr__char) { 1, .as_some__arr__char = some__some__arr__char__arr__char(at__arr__char__arr__arr__char__nat(_ctx, values, idx)) }
			: get_recursive__opt__arr__char__arr__arr__char__arr__arr__char__nat__arr__char(_ctx, keys, values, incr__nat__nat(_ctx, idx), key);
}
dict__arr__char__arr__char* unsafe_as_dict__ptr_dict__arr__char__arr__char__mut_dict__arr__char__arr__char(ctx* _ctx, mut_dict__arr__char__arr__char m) {
	return _initdict__arr__char__arr__char(alloc__ptr__byte__nat(_ctx, 32), (dict__arr__char__arr__char) {unsafe_as_arr__arr__arr__char__ptr_mut_arr__arr__char(m.keys), unsafe_as_arr__arr__arr__char__ptr_mut_arr__arr__char(m.values)});
}
key_value_pair__arr__char__arr__char* parse_environ_entry__ptr_key_value_pair__arr__char__arr__char__ptr__char(ctx* _ctx, ptr__char entry) {
	ptr__char key_end;
	arr__char key;
	ptr__char value_begin;
	ptr__char value_end;
	arr__char value;
	return ((key_end = find_char_in_cstr__ptr__char__ptr__char__char(entry, literal__char__arr__char((arr__char){1, "="}))),
	((key = arr_from_begin_end__arr__char__ptr__char__ptr__char(entry, key_end)),
	((value_begin = incr__ptr__char__ptr__char(key_end)),
	((value_end = find_cstr_end__ptr__char__ptr__char(value_begin)),
	((value = arr_from_begin_end__arr__char__ptr__char__ptr__char(value_begin, value_end)),
	_initkey_value_pair__arr__char__arr__char(alloc__ptr__byte__nat(_ctx, 32), (key_value_pair__arr__char__arr__char) {key, value}))))));
}
ptr__ptr__char incr__ptr__ptr__char__ptr__ptr__char(ptr__ptr__char p) {
	return (p + 1);
}
dict__arr__char__arr__char* freeze__ptr_dict__arr__char__arr__char__mut_dict__arr__char__arr__char(ctx* _ctx, mut_dict__arr__char__arr__char m) {
	return _initdict__arr__char__arr__char(alloc__ptr__byte__nat(_ctx, 32), (dict__arr__char__arr__char) {freeze__arr__arr__char__ptr_mut_arr__arr__char(m.keys), freeze__arr__arr__char__ptr_mut_arr__arr__char(m.values)});
}
result__arr__char__arr__ptr_failure run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options(ctx* _ctx, arr__char path, arr__char path_to_noze, dict__arr__char__arr__char* env, test_options options) {
	arr__arr__char tests;
	arr__ptr_failure failures;
	return ((tests = list_compile_error_tests__arr__arr__char__arr__char(_ctx, path)),
	((failures = flat_map_with_max_size__arr__ptr_failure__arr__arr__char__nat__fun_mut1__arr__ptr_failure__arr__char(_ctx, tests, options.max_failures, (fun_mut1__arr__ptr_failure__arr__char) {
		(fun_ptr3__arr__ptr_failure__ptr_ctx__ptr__byte__arr__char) run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0,
		(ptr__byte) _initrun_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0___closure(alloc__ptr__byte__nat(_ctx, 40), (run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0___closure) {options, path_to_noze, env})
	})),
	has__q__bool__arr__ptr_failure(failures)
		? (result__arr__char__arr__ptr_failure) { 1, .as_err__arr__ptr_failure = err__err__arr__ptr_failure__arr__ptr_failure(with_max_size__arr__ptr_failure__arr__ptr_failure__nat(_ctx, failures, options.max_failures)) }
		: (result__arr__char__arr__ptr_failure) { 0, .as_ok__arr__char = ok__ok__arr__char__arr__char(_op_plus__arr__char__arr__char__arr__char(_ctx, _op_plus__arr__char__arr__char__arr__char(_ctx, (arr__char){4, "Ran "}, to_str__arr__char__nat(_ctx, tests.size)), (arr__char){20, " compile-error tests"})) }));
}
arr__arr__char list_compile_error_tests__arr__arr__char__arr__char(ctx* _ctx, arr__char path) {
	mut_arr__arr__char* res;
	fun_mut1__bool__arr__char filter;
	return ((res = new_mut_arr__ptr_mut_arr__arr__char(_ctx)),
	((filter = (fun_mut1__bool__arr__char) {
		(fun_ptr3__bool__ptr_ctx__ptr__byte__arr__char) list_compile_error_tests__arr__arr__char__arr__char__lambda0,
		(ptr__byte) NULL
	}),
	(each_child_recursive___void__arr__char__fun_mut1__bool__arr__char__fun_mut1___void__arr__char(_ctx, path, filter, (fun_mut1___void__arr__char) {
		(fun_ptr3___void__ptr_ctx__ptr__byte__arr__char) list_compile_error_tests__arr__arr__char__arr__char__lambda1,
		(ptr__byte) _initlist_compile_error_tests__arr__arr__char__arr__char__lambda1___closure(alloc__ptr__byte__nat(_ctx, 8), (list_compile_error_tests__arr__arr__char__arr__char__lambda1___closure) {res})
	}),
	freeze__arr__arr__char__ptr_mut_arr__arr__char(res))));
}
bool list_compile_error_tests__arr__arr__char__arr__char__lambda0(ctx* _ctx, ptr__byte _closure, arr__char s) {
	return 1;
}
_void each_child_recursive___void__arr__char__fun_mut1__bool__arr__char__fun_mut1___void__arr__char(ctx* _ctx, arr__char path, fun_mut1__bool__arr__char filter, fun_mut1___void__arr__char f) {
	return is_dir__q__bool__arr__char(_ctx, path)
		? each___void__arr__arr__char__fun_mut1___void__arr__char(_ctx, read_dir__arr__arr__char__arr__char(_ctx, path), (fun_mut1___void__arr__char) {
			(fun_ptr3___void__ptr_ctx__ptr__byte__arr__char) each_child_recursive___void__arr__char__fun_mut1__bool__arr__char__fun_mut1___void__arr__char__lambda0,
			(ptr__byte) _initeach_child_recursive___void__arr__char__fun_mut1__bool__arr__char__fun_mut1___void__arr__char__lambda0___closure(alloc__ptr__byte__nat(_ctx, 48), (each_child_recursive___void__arr__char__fun_mut1__bool__arr__char__fun_mut1___void__arr__char__lambda0___closure) {filter, path, f})
		})
		: call___void__fun_mut1___void__arr__char__arr__char(_ctx, f, path);
}
bool is_dir__q__bool__arr__char(ctx* _ctx, arr__char path) {
	return is_dir__q__bool__ptr__char(_ctx, to_c_str__ptr__char__arr__char(_ctx, path));
}
bool is_dir__q__bool__ptr__char(ctx* _ctx, ptr__char path) {
	some__ptr_stat_t s;
	opt__ptr_stat_t matched;
	return (matched = get_stat__opt__ptr_stat_t__ptr__char(_ctx, path),
		matched.kind == 0
		? todo__bool()
		: matched.kind == 1
		? (s = matched.as_some__ptr_stat_t,
		_op_equal_equal__bool__nat32__nat32((s.value->st_mode & s_ifmt__nat32(_ctx)), s_ifdir__nat32(_ctx))
		): _failbool());
}
opt__ptr_stat_t get_stat__opt__ptr_stat_t__ptr__char(ctx* _ctx, ptr__char path) {
	stat_t* s;
	int32 err;
	int32 errno;
	return ((s = empty_stat__ptr_stat_t(_ctx)),
	((err = stat(path, s)),
	_op_equal_equal__bool__int32__int32(err, 0)
		? (opt__ptr_stat_t) { 1, .as_some__ptr_stat_t = some__some__ptr_stat_t__ptr_stat_t(s) }
		: (assert___void__bool(_ctx, _op_equal_equal__bool__int32__int32(err, neg_one__int32())),
		((errno = get_errno__int32(_ctx)),
		_op_equal_equal__bool__int32__int32(errno, enoent__int32())
			? (opt__ptr_stat_t) { 0, .as_none = none__none() }
			: todo__opt__ptr_stat_t()))));
}
stat_t* empty_stat__ptr_stat_t(ctx* _ctx) {
	return _initstat_t(alloc__ptr__byte__nat(_ctx, 152), (stat_t) {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0});
}
some__ptr_stat_t some__some__ptr_stat_t__ptr_stat_t(stat_t* t) {
	return (some__ptr_stat_t) {t};
}
int32 neg_one__int32() {
	return (0 - 1);
}
int32 enoent__int32() {
	return two__int32();
}
opt__ptr_stat_t todo__opt__ptr_stat_t() {
	return hard_fail__opt__ptr_stat_t__arr__char((arr__char){4, "TODO"});
}
opt__ptr_stat_t hard_fail__opt__ptr_stat_t__arr__char(arr__char reason) {
	assert(0);
}
bool todo__bool() {
	return hard_fail__bool__arr__char((arr__char){4, "TODO"});
}
bool hard_fail__bool__arr__char(arr__char reason) {
	assert(0);
}
bool _op_equal_equal__bool__nat32__nat32(nat32 a, nat32 b) {
	comparison matched;
	return (matched = _op_less_equal_greater__comparison__nat32__nat32(a, b),
		matched.kind == 0
		? 0
		: matched.kind == 1
		? 1
		: matched.kind == 2
		? 0
		: _failbool());
}
comparison _op_less_equal_greater__comparison__nat32__nat32(nat32 a, nat32 b) {
	return (a < b)
		? (comparison) { 0, .as_less = (less) { 0 } }
		: (b < a)
			? (comparison) { 2, .as_greater = (greater) { 0 } }
			: (comparison) { 1, .as_equal = (equal) { 0 } };
}
nat32 s_ifmt__nat32(ctx* _ctx) {
	return (two_pow__nat32__nat32(twelve__nat32()) * fifteen__nat32());
}
nat32 two_pow__nat32__nat32(nat32 pow) {
	return zero__q__bool__nat32(pow)
		? 1
		: (two_pow__nat32__nat32(wrap_decr__nat32__nat32(pow)) * two__nat32());
}
bool zero__q__bool__nat32(nat32 n) {
	return _op_equal_equal__bool__nat32__nat32(n, 0);
}
nat32 wrap_decr__nat32__nat32(nat32 a) {
	return (a - 1);
}
nat32 two__nat32() {
	return wrap_incr__nat32__nat32(1);
}
nat32 wrap_incr__nat32__nat32(nat32 a) {
	return (a + 1);
}
nat32 twelve__nat32() {
	return (eight__nat32() + four__nat32());
}
nat32 eight__nat32() {
	return wrap_incr__nat32__nat32(seven__nat32());
}
nat32 seven__nat32() {
	return wrap_incr__nat32__nat32(six__nat32());
}
nat32 six__nat32() {
	return wrap_incr__nat32__nat32(five__nat32());
}
nat32 five__nat32() {
	return wrap_incr__nat32__nat32(four__nat32());
}
nat32 four__nat32() {
	return wrap_incr__nat32__nat32(three__nat32());
}
nat32 three__nat32() {
	return wrap_incr__nat32__nat32(two__nat32());
}
nat32 fifteen__nat32() {
	return wrap_incr__nat32__nat32(fourteen__nat32());
}
nat32 fourteen__nat32() {
	return (twelve__nat32() + two__nat32());
}
nat32 s_ifdir__nat32(ctx* _ctx) {
	return two_pow__nat32__nat32(fourteen__nat32());
}
_void each___void__arr__arr__char__fun_mut1___void__arr__char(ctx* _ctx, arr__arr__char a, fun_mut1___void__arr__char f) {
	return empty__q__bool__arr__arr__char(a)
		? 0
		: (call___void__fun_mut1___void__arr__char__arr__char(_ctx, f, first__arr__char__arr__arr__char(_ctx, a)),
		each___void__arr__arr__char__fun_mut1___void__arr__char(_ctx, tail__arr__arr__char__arr__arr__char(_ctx, a), f));
}
_void call___void__fun_mut1___void__arr__char__arr__char(ctx* _ctx, fun_mut1___void__arr__char f, arr__char p0) {
	return call_with_ctx___void__ptr_ctx__fun_mut1___void__arr__char__arr__char(_ctx, f, p0);
}
_void call_with_ctx___void__ptr_ctx__fun_mut1___void__arr__char__arr__char(ctx* c, fun_mut1___void__arr__char f, arr__char p0) {
	return f.fun_ptr(c, f.closure, p0);
}
arr__arr__char read_dir__arr__arr__char__arr__char(ctx* _ctx, arr__char path) {
	return read_dir__arr__arr__char__ptr__char(_ctx, to_c_str__ptr__char__arr__char(_ctx, path));
}
arr__arr__char read_dir__arr__arr__char__ptr__char(ctx* _ctx, ptr__char path) {
	ptr__byte dirp;
	mut_arr__arr__char* res;
	return ((dirp = opendir(path)),
	(forbid___void__bool(_ctx, null__q__bool__ptr__byte(dirp)),
	((res = new_mut_arr__ptr_mut_arr__arr__char(_ctx)),
	(read_dir_recur___void__ptr__byte__ptr_mut_arr__arr__char(_ctx, dirp, res),
	sort__arr__arr__char__arr__arr__char(_ctx, freeze__arr__arr__char__ptr_mut_arr__arr__char(res))))));
}
_void read_dir_recur___void__ptr__byte__ptr_mut_arr__arr__char(ctx* _ctx, ptr__byte dirp, mut_arr__arr__char* res) {
	dirent* entry;
	cell__ptr_dirent* result;
	int32 err;
	arr__char name;
	return ((entry = _initdirent(alloc__ptr__byte__nat(_ctx, 280), (dirent) {0, 0, 0, literal__char__arr__char((arr__char){1, "\0"}), zero__bytes256()})),
	((result = new_cell__ptr_cell__ptr_dirent__ptr_dirent(_ctx, entry)),
	((err = readdir_r(dirp, entry, result)),
	(assert___void__bool(_ctx, zero__q__bool__int32(err)),
	null__q__bool__ptr__byte((ptr__byte) get__ptr_dirent__ptr_cell__ptr_dirent(result))
		? 0
		: (assert___void__bool(_ctx, ptr_eq__bool__ptr_dirent__ptr_dirent(get__ptr_dirent__ptr_cell__ptr_dirent(result), entry)),
		((name = get_dirent_name__arr__char__ptr_dirent(entry)),
		((_op_equal_equal__bool__arr__char__arr__char(name, (arr__char){1, "."}) || _op_equal_equal__bool__arr__char__arr__char(name, (arr__char){2, ".."}))
			? 0
			: push___void__ptr_mut_arr__arr__char__arr__char(_ctx, res, get_dirent_name__arr__char__ptr_dirent(entry)),
		read_dir_recur___void__ptr__byte__ptr_mut_arr__arr__char(_ctx, dirp, res))))))));
}
bytes256 zero__bytes256() {
	return (bytes256) {zero__bytes128(), zero__bytes128()};
}
cell__ptr_dirent* new_cell__ptr_cell__ptr_dirent__ptr_dirent(ctx* _ctx, dirent* value) {
	return _initcell__ptr_dirent(alloc__ptr__byte__nat(_ctx, 8), (cell__ptr_dirent) {value});
}
dirent* get__ptr_dirent__ptr_cell__ptr_dirent(cell__ptr_dirent* c) {
	return c->value;
}
bool ptr_eq__bool__ptr_dirent__ptr_dirent(dirent* a, dirent* b) {
	return _op_equal_equal__bool__ptr__byte__ptr__byte((ptr__byte) a, (ptr__byte) b);
}
arr__char get_dirent_name__arr__char__ptr_dirent(dirent* d) {
	nat name_offset;
	ptr__byte name_ptr;
	return ((name_offset = (((sizeof(nat) + sizeof(_int)) + sizeof(nat16)) + sizeof(char))),
	((name_ptr = ((ptr__byte) d + name_offset)),
	to_str__arr__char__ptr__char((ptr__char) name_ptr)));
}
arr__arr__char sort__arr__arr__char__arr__arr__char(ctx* _ctx, arr__arr__char a) {
	mut_arr__arr__char* m;
	return ((m = to_mut_arr__ptr_mut_arr__arr__char__arr__arr__char(_ctx, a)),
	(sort___void__ptr_mut_arr__arr__char(_ctx, m),
	freeze__arr__arr__char__ptr_mut_arr__arr__char(m)));
}
mut_arr__arr__char* to_mut_arr__ptr_mut_arr__arr__char__arr__arr__char(ctx* _ctx, arr__arr__char a) {
	return make_mut_arr__ptr_mut_arr__arr__char__nat__fun_mut1__arr__char__nat(_ctx, a.size, (fun_mut1__arr__char__nat) {
		(fun_ptr3__arr__char__ptr_ctx__ptr__byte__nat) to_mut_arr__ptr_mut_arr__arr__char__arr__arr__char__lambda0,
		(ptr__byte) _initto_mut_arr__ptr_mut_arr__arr__char__arr__arr__char__lambda0___closure(alloc__ptr__byte__nat(_ctx, 16), (to_mut_arr__ptr_mut_arr__arr__char__arr__arr__char__lambda0___closure) {a})
	});
}
arr__char to_mut_arr__ptr_mut_arr__arr__char__arr__arr__char__lambda0(ctx* _ctx, to_mut_arr__ptr_mut_arr__arr__char__arr__arr__char__lambda0___closure* _closure, nat i) {
	return at__arr__char__arr__arr__char__nat(_ctx, _closure->a, i);
}
_void sort___void__ptr_mut_arr__arr__char(ctx* _ctx, mut_arr__arr__char* a) {
	return sort___void__ptr_mut_slice__arr__char(_ctx, to_mut_slice__ptr_mut_slice__arr__char__ptr_mut_arr__arr__char(_ctx, a));
}
_void sort___void__ptr_mut_slice__arr__char(ctx* _ctx, mut_slice__arr__char* a) {
	arr__char pivot;
	nat index_of_first_value_gt_pivot;
	nat new_pivot_index;
	return _op_less_equal__bool__nat__nat(a->size, 1)
		? 0
		: (swap___void__ptr_mut_slice__arr__char__nat__nat(_ctx, a, 0, _op_div__nat__nat__nat(_ctx, a->size, two__nat())),
		((pivot = at__arr__char__ptr_mut_slice__arr__char__nat(_ctx, a, 0)),
		((index_of_first_value_gt_pivot = partition_recur__nat__ptr_mut_slice__arr__char__arr__char__nat__nat(_ctx, a, pivot, 1, decr__nat__nat(_ctx, a->size))),
		((new_pivot_index = decr__nat__nat(_ctx, index_of_first_value_gt_pivot)),
		((swap___void__ptr_mut_slice__arr__char__nat__nat(_ctx, a, 0, new_pivot_index),
		sort___void__ptr_mut_slice__arr__char(_ctx, slice__ptr_mut_slice__arr__char__ptr_mut_slice__arr__char__nat__nat(_ctx, a, 0, new_pivot_index))),
		sort___void__ptr_mut_slice__arr__char(_ctx, slice__ptr_mut_slice__arr__char__ptr_mut_slice__arr__char__nat(_ctx, a, incr__nat__nat(_ctx, new_pivot_index))))))));
}
_void swap___void__ptr_mut_slice__arr__char__nat__nat(ctx* _ctx, mut_slice__arr__char* a, nat lo, nat hi) {
	arr__char old_lo;
	return ((old_lo = at__arr__char__ptr_mut_slice__arr__char__nat(_ctx, a, lo)),
	(set_at___void__ptr_mut_slice__arr__char__nat__arr__char(_ctx, a, lo, at__arr__char__ptr_mut_slice__arr__char__nat(_ctx, a, hi)),
	set_at___void__ptr_mut_slice__arr__char__nat__arr__char(_ctx, a, hi, old_lo)));
}
arr__char at__arr__char__ptr_mut_slice__arr__char__nat(ctx* _ctx, mut_slice__arr__char* a, nat index) {
	return (assert___void__bool(_ctx, _op_less__bool__nat__nat(index, a->size)),
	at__arr__char__ptr_mut_arr__arr__char__nat(_ctx, a->backing, _op_plus__nat__nat__nat(_ctx, a->begin, index)));
}
arr__char at__arr__char__ptr_mut_arr__arr__char__nat(ctx* _ctx, mut_arr__arr__char* a, nat index) {
	return (assert___void__bool(_ctx, _op_less__bool__nat__nat(index, a->size)),
	noctx_at__arr__char__ptr_mut_arr__arr__char__nat(a, index));
}
arr__char noctx_at__arr__char__ptr_mut_arr__arr__char__nat(mut_arr__arr__char* a, nat index) {
	return (hard_assert___void__bool(_op_less__bool__nat__nat(index, a->size)),
	*((a->data + index)));
}
_void set_at___void__ptr_mut_slice__arr__char__nat__arr__char(ctx* _ctx, mut_slice__arr__char* a, nat index, arr__char value) {
	return (assert___void__bool(_ctx, _op_less__bool__nat__nat(index, a->size)),
	set_at___void__ptr_mut_arr__arr__char__nat__arr__char(_ctx, a->backing, _op_plus__nat__nat__nat(_ctx, a->begin, index), value));
}
nat partition_recur__nat__ptr_mut_slice__arr__char__arr__char__nat__nat(ctx* _ctx, mut_slice__arr__char* a, arr__char pivot, nat l, nat r) {
	arr__char em;
	return ((assert___void__bool(_ctx, _op_less_equal__bool__nat__nat(l, a->size)),
	assert___void__bool(_ctx, _op_less__bool__nat__nat(r, a->size))),
	_op_less_equal__bool__nat__nat(l, r)
		? ((em = at__arr__char__ptr_mut_slice__arr__char__nat(_ctx, a, l)),
		_op_less__bool__arr__char__arr__char(em, pivot)
			? partition_recur__nat__ptr_mut_slice__arr__char__arr__char__nat__nat(_ctx, a, pivot, incr__nat__nat(_ctx, l), r)
			: (swap___void__ptr_mut_slice__arr__char__nat__nat(_ctx, a, l, r),
			partition_recur__nat__ptr_mut_slice__arr__char__arr__char__nat__nat(_ctx, a, pivot, l, decr__nat__nat(_ctx, r))))
		: l);
}
bool _op_less__bool__arr__char__arr__char(arr__char a, arr__char b) {
	comparison matched;
	return (matched = _op_less_equal_greater__comparison__arr__char__arr__char(a, b),
		matched.kind == 0
		? 1
		: matched.kind == 1
		? 0
		: matched.kind == 2
		? 0
		: _failbool());
}
mut_slice__arr__char* slice__ptr_mut_slice__arr__char__ptr_mut_slice__arr__char__nat__nat(ctx* _ctx, mut_slice__arr__char* a, nat lo, nat size) {
	return (assert___void__bool(_ctx, _op_less_equal__bool__nat__nat(_op_plus__nat__nat__nat(_ctx, lo, size), a->size)),
	_initmut_slice__arr__char(alloc__ptr__byte__nat(_ctx, 24), (mut_slice__arr__char) {a->backing, size, _op_plus__nat__nat__nat(_ctx, a->begin, lo)}));
}
mut_slice__arr__char* slice__ptr_mut_slice__arr__char__ptr_mut_slice__arr__char__nat(ctx* _ctx, mut_slice__arr__char* a, nat lo) {
	return (assert___void__bool(_ctx, _op_less_equal__bool__nat__nat(lo, a->size)),
	slice__ptr_mut_slice__arr__char__ptr_mut_slice__arr__char__nat__nat(_ctx, a, lo, _op_minus__nat__nat__nat(_ctx, a->size, lo)));
}
mut_slice__arr__char* to_mut_slice__ptr_mut_slice__arr__char__ptr_mut_arr__arr__char(ctx* _ctx, mut_arr__arr__char* a) {
	return (forbid___void__bool(_ctx, a->frozen__q),
	_initmut_slice__arr__char(alloc__ptr__byte__nat(_ctx, 24), (mut_slice__arr__char) {a, a->size, 0}));
}
_void each_child_recursive___void__arr__char__fun_mut1__bool__arr__char__fun_mut1___void__arr__char__lambda0(ctx* _ctx, each_child_recursive___void__arr__char__fun_mut1__bool__arr__char__fun_mut1___void__arr__char__lambda0___closure* _closure, arr__char child_name) {
	return call__bool__fun_mut1__bool__arr__char__arr__char(_ctx, _closure->filter, child_name)
		? each_child_recursive___void__arr__char__fun_mut1__bool__arr__char__fun_mut1___void__arr__char(_ctx, child_path__arr__char__arr__char__arr__char(_ctx, _closure->path, child_name), _closure->filter, _closure->f)
		: 0;
}
opt__arr__char get_extension__opt__arr__char__arr__char(ctx* _ctx, arr__char name) {
	some__nat s;
	opt__nat matched;
	return (matched = last_index_of__opt__nat__arr__char__char(_ctx, name, literal__char__arr__char((arr__char){1, "."})),
		matched.kind == 0
		? (opt__arr__char) { 0, .as_none = none__none() }
		: matched.kind == 1
		? (s = matched.as_some__nat,
		(opt__arr__char) { 1, .as_some__arr__char = some__some__arr__char__arr__char(slice_after__arr__char__arr__char__nat(_ctx, name, s.value)) }
		): _failopt__arr__char());
}
opt__nat last_index_of__opt__nat__arr__char__char(ctx* _ctx, arr__char s, char c) {
	return empty__q__bool__arr__char(s)
		? (opt__nat) { 0, .as_none = none__none() }
		: _op_equal_equal__bool__char__char(last__char__arr__char(_ctx, s), c)
			? (opt__nat) { 1, .as_some__nat = some__some__nat__nat(decr__nat__nat(_ctx, s.size)) }
			: last_index_of__opt__nat__arr__char__char(_ctx, rtail__arr__char__arr__char(_ctx, s), c);
}
arr__char slice_after__arr__char__arr__char__nat(ctx* _ctx, arr__char a, nat before_begin) {
	return slice_starting_at__arr__char__arr__char__nat(_ctx, a, incr__nat__nat(_ctx, before_begin));
}
arr__char base_name__arr__char__arr__char(ctx* _ctx, arr__char path) {
	opt__nat i;
	some__nat s;
	opt__nat matched;
	return ((i = last_index_of__opt__nat__arr__char__char(_ctx, path, literal__char__arr__char((arr__char){1, "/"}))),
	(matched = i,
		matched.kind == 0
		? path
		: matched.kind == 1
		? (s = matched.as_some__nat,
		slice_after__arr__char__arr__char__nat(_ctx, path, s.value)
		): _failarr__char()));
}
_void list_compile_error_tests__arr__arr__char__arr__char__lambda1(ctx* _ctx, list_compile_error_tests__arr__arr__char__arr__char__lambda1___closure* _closure, arr__char child) {
	arr__char ext;
	return ((ext = force__arr__char__opt__arr__char(_ctx, get_extension__opt__arr__char__arr__char(_ctx, base_name__arr__char__arr__char(_ctx, child)))),
	_op_equal_equal__bool__arr__char__arr__char(ext, (arr__char){2, "nz"})
		? push___void__ptr_mut_arr__arr__char__arr__char(_ctx, _closure->res, child)
		: _op_equal_equal__bool__arr__char__arr__char(ext, (arr__char){3, "err"})
			? 0
			: todo___void());
}
arr__ptr_failure flat_map_with_max_size__arr__ptr_failure__arr__arr__char__nat__fun_mut1__arr__ptr_failure__arr__char(ctx* _ctx, arr__arr__char a, nat max_size, fun_mut1__arr__ptr_failure__arr__char mapper) {
	mut_arr__ptr_failure* res;
	return ((res = new_mut_arr__ptr_mut_arr__ptr_failure(_ctx)),
	(each___void__arr__arr__char__fun_mut1___void__arr__char(_ctx, a, (fun_mut1___void__arr__char) {
		(fun_ptr3___void__ptr_ctx__ptr__byte__arr__char) flat_map_with_max_size__arr__ptr_failure__arr__arr__char__nat__fun_mut1__arr__ptr_failure__arr__char__lambda0,
		(ptr__byte) _initflat_map_with_max_size__arr__ptr_failure__arr__arr__char__nat__fun_mut1__arr__ptr_failure__arr__char__lambda0___closure(alloc__ptr__byte__nat(_ctx, 32), (flat_map_with_max_size__arr__ptr_failure__arr__arr__char__nat__fun_mut1__arr__ptr_failure__arr__char__lambda0___closure) {res, max_size, mapper})
	}),
	freeze__arr__ptr_failure__ptr_mut_arr__ptr_failure(res)));
}
mut_arr__ptr_failure* new_mut_arr__ptr_mut_arr__ptr_failure(ctx* _ctx) {
	return _initmut_arr__ptr_failure(alloc__ptr__byte__nat(_ctx, 32), (mut_arr__ptr_failure) {0, 0, 0, NULL});
}
_void push_all___void__ptr_mut_arr__ptr_failure__arr__ptr_failure(ctx* _ctx, mut_arr__ptr_failure* a, arr__ptr_failure values) {
	return each___void__arr__ptr_failure__fun_mut1___void__ptr_failure(_ctx, values, (fun_mut1___void__ptr_failure) {
		(fun_ptr3___void__ptr_ctx__ptr__byte__ptr_failure) push_all___void__ptr_mut_arr__ptr_failure__arr__ptr_failure__lambda0,
		(ptr__byte) _initpush_all___void__ptr_mut_arr__ptr_failure__arr__ptr_failure__lambda0___closure(alloc__ptr__byte__nat(_ctx, 8), (push_all___void__ptr_mut_arr__ptr_failure__arr__ptr_failure__lambda0___closure) {a})
	});
}
_void each___void__arr__ptr_failure__fun_mut1___void__ptr_failure(ctx* _ctx, arr__ptr_failure a, fun_mut1___void__ptr_failure f) {
	return empty__q__bool__arr__ptr_failure(a)
		? 0
		: (call___void__fun_mut1___void__ptr_failure__ptr_failure(_ctx, f, first__ptr_failure__arr__ptr_failure(_ctx, a)),
		each___void__arr__ptr_failure__fun_mut1___void__ptr_failure(_ctx, tail__arr__ptr_failure__arr__ptr_failure(_ctx, a), f));
}
bool empty__q__bool__arr__ptr_failure(arr__ptr_failure a) {
	return zero__q__bool__nat(a.size);
}
_void call___void__fun_mut1___void__ptr_failure__ptr_failure(ctx* _ctx, fun_mut1___void__ptr_failure f, failure* p0) {
	return call_with_ctx___void__ptr_ctx__fun_mut1___void__ptr_failure__ptr_failure(_ctx, f, p0);
}
_void call_with_ctx___void__ptr_ctx__fun_mut1___void__ptr_failure__ptr_failure(ctx* c, fun_mut1___void__ptr_failure f, failure* p0) {
	return f.fun_ptr(c, f.closure, p0);
}
failure* first__ptr_failure__arr__ptr_failure(ctx* _ctx, arr__ptr_failure a) {
	return (forbid___void__bool(_ctx, empty__q__bool__arr__ptr_failure(a)),
	at__ptr_failure__arr__ptr_failure__nat(_ctx, a, 0));
}
failure* at__ptr_failure__arr__ptr_failure__nat(ctx* _ctx, arr__ptr_failure a, nat index) {
	return (assert___void__bool(_ctx, _op_less__bool__nat__nat(index, a.size)),
	noctx_at__ptr_failure__arr__ptr_failure__nat(a, index));
}
failure* noctx_at__ptr_failure__arr__ptr_failure__nat(arr__ptr_failure a, nat index) {
	return (hard_assert___void__bool(_op_less__bool__nat__nat(index, a.size)),
	*((a.data + index)));
}
arr__ptr_failure tail__arr__ptr_failure__arr__ptr_failure(ctx* _ctx, arr__ptr_failure a) {
	return (forbid___void__bool(_ctx, empty__q__bool__arr__ptr_failure(a)),
	slice_starting_at__arr__ptr_failure__arr__ptr_failure__nat(_ctx, a, 1));
}
arr__ptr_failure slice_starting_at__arr__ptr_failure__arr__ptr_failure__nat(ctx* _ctx, arr__ptr_failure a, nat begin) {
	return (assert___void__bool(_ctx, _op_less_equal__bool__nat__nat(begin, a.size)),
	slice__arr__ptr_failure__arr__ptr_failure__nat__nat(_ctx, a, begin, _op_minus__nat__nat__nat(_ctx, a.size, begin)));
}
arr__ptr_failure slice__arr__ptr_failure__arr__ptr_failure__nat__nat(ctx* _ctx, arr__ptr_failure a, nat begin, nat size) {
	return (assert___void__bool(_ctx, _op_less_equal__bool__nat__nat(_op_plus__nat__nat__nat(_ctx, begin, size), a.size)),
	(arr__ptr_failure) {size, (a.data + begin)});
}
_void push___void__ptr_mut_arr__ptr_failure__ptr_failure(ctx* _ctx, mut_arr__ptr_failure* a, failure* value) {
	return ((((_op_equal_equal__bool__nat__nat(a->size, a->capacity)
		? increase_capacity_to___void__ptr_mut_arr__ptr_failure__nat(_ctx, a, (zero__q__bool__nat(a->size) ? four__nat() : _op_times__nat__nat__nat(_ctx, a->size, two__nat())))
		: 0,
	ensure_capacity___void__ptr_mut_arr__ptr_failure__nat(_ctx, a, round_up_to_power_of_two__nat__nat(_ctx, incr__nat__nat(_ctx, a->size)))),
	assert___void__bool(_ctx, _op_less__bool__nat__nat(a->size, a->capacity))),
	((*((a->data + a->size)) = value), 0)),
	(a->size = incr__nat__nat(_ctx, a->size)), 0);
}
_void increase_capacity_to___void__ptr_mut_arr__ptr_failure__nat(ctx* _ctx, mut_arr__ptr_failure* a, nat new_capacity) {
	ptr__ptr_failure old_data;
	return (assert___void__bool(_ctx, _op_greater__bool__nat__nat(new_capacity, a->capacity)),
	((old_data = a->data),
	(((a->capacity = new_capacity), 0,
	(a->data = uninitialized_data__ptr__ptr_failure__nat(_ctx, new_capacity)), 0),
	copy_data_from___void__ptr__ptr_failure__ptr__ptr_failure__nat(_ctx, a->data, old_data, a->size))));
}
ptr__ptr_failure uninitialized_data__ptr__ptr_failure__nat(ctx* _ctx, nat size) {
	ptr__byte bptr;
	return ((bptr = alloc__ptr__byte__nat(_ctx, (size * sizeof(failure*)))),
	(ptr__ptr_failure) bptr);
}
_void copy_data_from___void__ptr__ptr_failure__ptr__ptr_failure__nat(ctx* _ctx, ptr__ptr_failure to, ptr__ptr_failure from, nat len) {
	nat hl;
	return _op_less__bool__nat__nat(len, eight__nat())
		? copy_data_from_small___void__ptr__ptr_failure__ptr__ptr_failure__nat(_ctx, to, from, len)
		: ((hl = _op_div__nat__nat__nat(_ctx, len, two__nat())),
		(copy_data_from___void__ptr__ptr_failure__ptr__ptr_failure__nat(_ctx, to, from, hl),
		copy_data_from___void__ptr__ptr_failure__ptr__ptr_failure__nat(_ctx, (to + hl), (from + hl), _op_minus__nat__nat__nat(_ctx, len, hl))));
}
_void copy_data_from_small___void__ptr__ptr_failure__ptr__ptr_failure__nat(ctx* _ctx, ptr__ptr_failure to, ptr__ptr_failure from, nat len) {
	return zero__q__bool__nat(len)
		? 0
		: (((*(to) = *(from)), 0),
		copy_data_from___void__ptr__ptr_failure__ptr__ptr_failure__nat(_ctx, incr__ptr__ptr_failure__ptr__ptr_failure(to), incr__ptr__ptr_failure__ptr__ptr_failure(from), decr__nat__nat(_ctx, len)));
}
ptr__ptr_failure incr__ptr__ptr_failure__ptr__ptr_failure(ptr__ptr_failure p) {
	return (p + 1);
}
_void ensure_capacity___void__ptr_mut_arr__ptr_failure__nat(ctx* _ctx, mut_arr__ptr_failure* a, nat capacity) {
	return _op_less__bool__nat__nat(a->capacity, capacity)
		? increase_capacity_to___void__ptr_mut_arr__ptr_failure__nat(_ctx, a, round_up_to_power_of_two__nat__nat(_ctx, capacity))
		: 0;
}
_void push_all___void__ptr_mut_arr__ptr_failure__arr__ptr_failure__lambda0(ctx* _ctx, push_all___void__ptr_mut_arr__ptr_failure__arr__ptr_failure__lambda0___closure* _closure, failure* it) {
	return push___void__ptr_mut_arr__ptr_failure__ptr_failure(_ctx, _closure->a, it);
}
arr__ptr_failure call__arr__ptr_failure__fun_mut1__arr__ptr_failure__arr__char__arr__char(ctx* _ctx, fun_mut1__arr__ptr_failure__arr__char f, arr__char p0) {
	return call_with_ctx__arr__ptr_failure__ptr_ctx__fun_mut1__arr__ptr_failure__arr__char__arr__char(_ctx, f, p0);
}
arr__ptr_failure call_with_ctx__arr__ptr_failure__ptr_ctx__fun_mut1__arr__ptr_failure__arr__char__arr__char(ctx* c, fun_mut1__arr__ptr_failure__arr__char f, arr__char p0) {
	return f.fun_ptr(c, f.closure, p0);
}
_void reduce_size_if_more_than___void__ptr_mut_arr__ptr_failure__nat(ctx* _ctx, mut_arr__ptr_failure* a, nat new_size) {
	return _op_less__bool__nat__nat(new_size, a->size)
		? (a->size = new_size), 0
		: 0;
}
_void flat_map_with_max_size__arr__ptr_failure__arr__arr__char__nat__fun_mut1__arr__ptr_failure__arr__char__lambda0(ctx* _ctx, flat_map_with_max_size__arr__ptr_failure__arr__arr__char__nat__fun_mut1__arr__ptr_failure__arr__char__lambda0___closure* _closure, arr__char x) {
	return _op_less__bool__nat__nat(_closure->res->size, _closure->max_size)
		? (push_all___void__ptr_mut_arr__ptr_failure__arr__ptr_failure(_ctx, _closure->res, call__arr__ptr_failure__fun_mut1__arr__ptr_failure__arr__char__arr__char(_ctx, _closure->mapper, x)),
		reduce_size_if_more_than___void__ptr_mut_arr__ptr_failure__nat(_ctx, _closure->res, _closure->max_size))
		: 0;
}
arr__ptr_failure freeze__arr__ptr_failure__ptr_mut_arr__ptr_failure(mut_arr__ptr_failure* a) {
	return ((a->frozen__q = 1), 0,
	unsafe_as_arr__arr__ptr_failure__ptr_mut_arr__ptr_failure(a));
}
arr__ptr_failure unsafe_as_arr__arr__ptr_failure__ptr_mut_arr__ptr_failure(mut_arr__ptr_failure* a) {
	return (arr__ptr_failure) {a->size, a->data};
}
arr__ptr_failure run_single_compile_error_test__arr__ptr_failure__arr__char__ptr_dict__arr__char__arr__char__arr__char__bool(ctx* _ctx, arr__char path_to_noze, dict__arr__char__arr__char* env, arr__char path, bool overwrite_output__q) {
	mut_arr__ptr_failure* failures;
	arr__arr__char arr;
	process_result* result;
	arr__char message;
	arr__char stderr_no_color;
	return ((failures = new_mut_arr__ptr_mut_arr__ptr_failure(_ctx)),
	((result = spawn_and_wait_result__ptr_process_result__arr__char__arr__arr__char__ptr_dict__arr__char__arr__char(_ctx, path_to_noze, (arr = (arr__arr__char) { 2, (arr__char*) alloc__ptr__byte__nat(_ctx, 32) }, arr.data[0] =(arr__char){5, "build"}, arr.data[1] =path, arr), env)),
	((_op_equal_equal__bool__int32__int32(result->exit_code, literal__int32__arr__char(_ctx, (arr__char){1, "1"}))
		? 0
		: ((message = _op_plus__arr__char__arr__char__arr__char(_ctx, (arr__char){59, "Compile error should result in exit code of 1. Instead got "}, to_str__arr__char__int32(_ctx, result->exit_code))),
		push___void__ptr_mut_arr__ptr_failure__ptr_failure(_ctx, failures, _initfailure(alloc__ptr__byte__nat(_ctx, 32), (failure) {path, message}))),
	_op_equal_equal__bool__arr__char__arr__char(result->stdout, (arr__char){0, ""})
		? 0
		: push___void__ptr_mut_arr__ptr_failure__ptr_failure(_ctx, failures, _initfailure(alloc__ptr__byte__nat(_ctx, 32), (failure) {path, _op_plus__arr__char__arr__char__arr__char(_ctx, (arr__char){37, "stdout should be empty. Instead got:\n"}, result->stdout)}))),
	((stderr_no_color = remove_colors__arr__char__arr__char(_ctx, result->stderr)),
	(_op_equal_equal__bool__arr__char__arr__char(result->stderr, (arr__char){0, ""})
		? push___void__ptr_mut_arr__ptr_failure__ptr_failure(_ctx, failures, _initfailure(alloc__ptr__byte__nat(_ctx, 32), (failure) {path, (arr__char){15, "stderr is empty"}}))
		: push_all___void__ptr_mut_arr__ptr_failure__arr__ptr_failure(_ctx, failures, handle_output__arr__ptr_failure__arr__char__arr__char__arr__char__bool(_ctx, path, _op_plus__arr__char__arr__char__arr__char(_ctx, path, (arr__char){4, ".err"}), stderr_no_color, overwrite_output__q)),
	freeze__arr__ptr_failure__ptr_mut_arr__ptr_failure(failures))))));
}
process_result* spawn_and_wait_result__ptr_process_result__arr__char__arr__arr__char__ptr_dict__arr__char__arr__char(ctx* _ctx, arr__char exe, arr__arr__char args, dict__arr__char__arr__char* environ) {
	ptr__char exe_c_str;
	return (print_sync___void__arr__char(fold__arr__char__arr__char__arr__arr__char__fun_mut2__arr__char__arr__char__arr__char(_ctx, _op_plus__arr__char__arr__char__arr__char(_ctx, (arr__char){23, "spawn-and-wait-result: "}, exe), args, (fun_mut2__arr__char__arr__char__arr__char) {
		(fun_ptr4__arr__char__ptr_ctx__ptr__byte__arr__char__arr__char) spawn_and_wait_result__ptr_process_result__arr__char__arr__arr__char__ptr_dict__arr__char__arr__char__lambda0,
		(ptr__byte) NULL
	})),
	is_file__q__bool__arr__char(_ctx, exe)
		? ((exe_c_str = to_c_str__ptr__char__arr__char(_ctx, exe)),
		spawn_and_wait_result__ptr_process_result__ptr__char__ptr__ptr__char__ptr__ptr__char(_ctx, exe_c_str, convert_args__ptr__ptr__char__ptr__char__arr__arr__char(_ctx, exe_c_str, args), convert_environ__ptr__ptr__char__ptr_dict__arr__char__arr__char(_ctx, environ)))
		: fail__ptr_process_result__arr__char(_ctx, _op_plus__arr__char__arr__char__arr__char(_ctx, exe, (arr__char){14, " is not a file"})));
}
arr__char fold__arr__char__arr__char__arr__arr__char__fun_mut2__arr__char__arr__char__arr__char(ctx* _ctx, arr__char val, arr__arr__char a, fun_mut2__arr__char__arr__char__arr__char combine) {
	return empty__q__bool__arr__arr__char(a)
		? val
		: fold__arr__char__arr__char__arr__arr__char__fun_mut2__arr__char__arr__char__arr__char(_ctx, call__arr__char__fun_mut2__arr__char__arr__char__arr__char__arr__char__arr__char(_ctx, combine, val, first__arr__char__arr__arr__char(_ctx, a)), tail__arr__arr__char__arr__arr__char(_ctx, a), combine);
}
arr__char call__arr__char__fun_mut2__arr__char__arr__char__arr__char__arr__char__arr__char(ctx* _ctx, fun_mut2__arr__char__arr__char__arr__char f, arr__char p0, arr__char p1) {
	return call_with_ctx__arr__char__ptr_ctx__fun_mut2__arr__char__arr__char__arr__char__arr__char__arr__char(_ctx, f, p0, p1);
}
arr__char call_with_ctx__arr__char__ptr_ctx__fun_mut2__arr__char__arr__char__arr__char__arr__char__arr__char(ctx* c, fun_mut2__arr__char__arr__char__arr__char f, arr__char p0, arr__char p1) {
	return f.fun_ptr(c, f.closure, p0, p1);
}
arr__char spawn_and_wait_result__ptr_process_result__arr__char__arr__arr__char__ptr_dict__arr__char__arr__char__lambda0(ctx* _ctx, ptr__byte _closure, arr__char a, arr__char b) {
	return _op_plus__arr__char__arr__char__arr__char(_ctx, _op_plus__arr__char__arr__char__arr__char(_ctx, a, (arr__char){1, " "}), b);
}
bool is_file__q__bool__arr__char(ctx* _ctx, arr__char path) {
	return is_file__q__bool__ptr__char(_ctx, to_c_str__ptr__char__arr__char(_ctx, path));
}
bool is_file__q__bool__ptr__char(ctx* _ctx, ptr__char path) {
	some__ptr_stat_t s;
	opt__ptr_stat_t matched;
	return (matched = get_stat__opt__ptr_stat_t__ptr__char(_ctx, path),
		matched.kind == 0
		? 0
		: matched.kind == 1
		? (s = matched.as_some__ptr_stat_t,
		_op_equal_equal__bool__nat32__nat32((s.value->st_mode & s_ifmt__nat32(_ctx)), s_ifreg__nat32(_ctx))
		): _failbool());
}
nat32 s_ifreg__nat32(ctx* _ctx) {
	return two_pow__nat32__nat32(fifteen__nat32());
}
process_result* spawn_and_wait_result__ptr_process_result__ptr__char__ptr__ptr__char__ptr__ptr__char(ctx* _ctx, ptr__char exe, ptr__ptr__char args, ptr__ptr__char environ) {
	pipes* stdout_pipes;
	pipes* stderr_pipes;
	posix_spawn_file_actions_t* actions;
	cell__int32* pid_cell;
	int32 pid;
	mut_arr__char* stdout_builder;
	mut_arr__char* stderr_builder;
	int32 exit_code;
	return ((stdout_pipes = make_pipes__ptr_pipes(_ctx)),
	((stderr_pipes = make_pipes__ptr_pipes(_ctx)),
	((actions = _initposix_spawn_file_actions_t(alloc__ptr__byte__nat(_ctx, 80), (posix_spawn_file_actions_t) {0, 0, NULL, zero__bytes64()})),
	(((((((check_posix_error___void__int32(_ctx, posix_spawn_file_actions_init(actions)),
	check_posix_error___void__int32(_ctx, posix_spawn_file_actions_addclose(actions, stdout_pipes->write_pipe))),
	check_posix_error___void__int32(_ctx, posix_spawn_file_actions_addclose(actions, stderr_pipes->write_pipe))),
	check_posix_error___void__int32(_ctx, posix_spawn_file_actions_adddup2(actions, stdout_pipes->read_pipe, stdout_fd__int32()))),
	check_posix_error___void__int32(_ctx, posix_spawn_file_actions_adddup2(actions, stderr_pipes->read_pipe, stderr_fd__int32()))),
	check_posix_error___void__int32(_ctx, posix_spawn_file_actions_addclose(actions, stdout_pipes->read_pipe))),
	check_posix_error___void__int32(_ctx, posix_spawn_file_actions_addclose(actions, stderr_pipes->read_pipe))),
	((pid_cell = new_cell__ptr_cell__int32__int32(_ctx, 0)),
	(check_posix_error___void__int32(_ctx, posix_spawn(pid_cell, exe, actions, NULL, args, environ)),
	((pid = get__int32__ptr_cell__int32(pid_cell)),
	((check_posix_error___void__int32(_ctx, close(stdout_pipes->read_pipe)),
	check_posix_error___void__int32(_ctx, close(stderr_pipes->read_pipe))),
	((stdout_builder = new_mut_arr__ptr_mut_arr__char(_ctx)),
	((stderr_builder = new_mut_arr__ptr_mut_arr__char(_ctx)),
	(keep_polling___void__int32__int32__ptr_mut_arr__char__ptr_mut_arr__char(_ctx, stdout_pipes->write_pipe, stderr_pipes->write_pipe, stdout_builder, stderr_builder),
	((exit_code = wait_and_get_exit_code__int32__int32(_ctx, pid)),
	_initprocess_result(alloc__ptr__byte__nat(_ctx, 40), (process_result) {exit_code, freeze__arr__char__ptr_mut_arr__char(stdout_builder), freeze__arr__char__ptr_mut_arr__char(stderr_builder)})))))))))))));
}
pipes* make_pipes__ptr_pipes(ctx* _ctx) {
	pipes* res;
	return ((res = _initpipes(alloc__ptr__byte__nat(_ctx, 8), (pipes) {0, 0})),
	(check_posix_error___void__int32(_ctx, pipe(res)),
	res));
}
cell__int32* new_cell__ptr_cell__int32__int32(ctx* _ctx, int32 value) {
	return _initcell__int32(alloc__ptr__byte__nat(_ctx, 4), (cell__int32) {value});
}
int32 get__int32__ptr_cell__int32(cell__int32* c) {
	return c->value;
}
mut_arr__char* new_mut_arr__ptr_mut_arr__char(ctx* _ctx) {
	return _initmut_arr__char(alloc__ptr__byte__nat(_ctx, 32), (mut_arr__char) {0, 0, 0, NULL});
}
_void keep_polling___void__int32__int32__ptr_mut_arr__char__ptr_mut_arr__char(ctx* _ctx, int32 stdout_pipe, int32 stderr_pipe, mut_arr__char* stdout_builder, mut_arr__char* stderr_builder) {
	arr__pollfd arr;
	arr__pollfd poll_fds;
	pollfd* stdout_pollfd;
	pollfd* stderr_pollfd;
	int32 n_pollfds_with_events;
	handle_revents_result a;
	handle_revents_result b;
	return ((poll_fds = (arr = (arr__pollfd) { 2, (pollfd*) alloc__ptr__byte__nat(_ctx, 16) }, arr.data[0] =(pollfd) {stdout_pipe, pollin__int16(_ctx), 0}, arr.data[1] =(pollfd) {stderr_pipe, pollin__int16(_ctx), 0}, arr)),
	((stdout_pollfd = ref_of_val_at__ptr_pollfd__arr__pollfd__nat(_ctx, poll_fds, 0)),
	((stderr_pollfd = ref_of_val_at__ptr_pollfd__arr__pollfd__nat(_ctx, poll_fds, 1)),
	((n_pollfds_with_events = poll(poll_fds.data, poll_fds.size, neg_one__int32())),
	zero__q__bool__int32(n_pollfds_with_events)
		? 0
		: ((a = handle_revents__handle_revents_result__ptr_pollfd__ptr_mut_arr__char(_ctx, stdout_pollfd, stdout_builder)),
		((b = handle_revents__handle_revents_result__ptr_pollfd__ptr_mut_arr__char(_ctx, stderr_pollfd, stderr_builder)),
		(assert___void__bool(_ctx, _op_equal_equal__bool__nat__nat(_op_plus__nat__nat__nat(_ctx, to_nat__nat__bool(_ctx, any__q__bool__handle_revents_result(_ctx, a)), to_nat__nat__bool(_ctx, any__q__bool__handle_revents_result(_ctx, b))), to_nat__nat__int32(_ctx, n_pollfds_with_events))),
		(a.hung_up__q && b.hung_up__q)
			? 0
			: keep_polling___void__int32__int32__ptr_mut_arr__char__ptr_mut_arr__char(_ctx, stdout_pipe, stderr_pipe, stdout_builder, stderr_builder))))))));
}
int16 pollin__int16(ctx* _ctx) {
	return two_pow__int16__int16(0);
}
int16 two_pow__int16__int16(int16 pow) {
	return zero__q__bool__int16(pow)
		? 1
		: (two_pow__int16__int16(wrap_decr__int16__int16(pow)) * two__int16());
}
bool zero__q__bool__int16(int16 a) {
	return _op_equal_equal__bool__int16__int16(a, 0);
}
bool _op_equal_equal__bool__int16__int16(int16 a, int16 b) {
	comparison matched;
	return (matched = _op_less_equal_greater__comparison__int16__int16(a, b),
		matched.kind == 0
		? 0
		: matched.kind == 1
		? 1
		: matched.kind == 2
		? 0
		: _failbool());
}
comparison _op_less_equal_greater__comparison__int16__int16(int16 a, int16 b) {
	return (a < b)
		? (comparison) { 0, .as_less = (less) { 0 } }
		: (b < a)
			? (comparison) { 2, .as_greater = (greater) { 0 } }
			: (comparison) { 1, .as_equal = (equal) { 0 } };
}
int16 wrap_decr__int16__int16(int16 a) {
	return (a - 1);
}
int16 two__int16() {
	return wrap_incr__int16__int16(1);
}
int16 wrap_incr__int16__int16(int16 a) {
	return (a + 1);
}
pollfd* ref_of_val_at__ptr_pollfd__arr__pollfd__nat(ctx* _ctx, arr__pollfd a, nat index) {
	return (assert___void__bool(_ctx, _op_less__bool__nat__nat(index, a.size)),
	ref_of_ptr__ptr_pollfd__ptr__pollfd((a.data + index)));
}
pollfd* ref_of_ptr__ptr_pollfd__ptr__pollfd(ptr__pollfd p) {
	return (&(*(p)));
}
handle_revents_result handle_revents__handle_revents_result__ptr_pollfd__ptr_mut_arr__char(ctx* _ctx, pollfd* pollfd, mut_arr__char* builder) {
	int16 revents;
	bool had_pollin__q;
	bool hung_up__q;
	return ((revents = pollfd->revents),
	((had_pollin__q = has_pollin__q__bool__int16(_ctx, revents)),
	(had_pollin__q
		? read_to_buffer_until_eof___void__int32__ptr_mut_arr__char(_ctx, pollfd->fd, builder)
		: 0,
	((hung_up__q = has_pollhup__q__bool__int16(_ctx, revents)),
	((((has_pollpri__q__bool__int16(_ctx, revents) || has_pollout__q__bool__int16(_ctx, revents)) || has_pollerr__q__bool__int16(_ctx, revents)) || has_pollnval__q__bool__int16(_ctx, revents))
		? todo___void()
		: 0,
	(handle_revents_result) {had_pollin__q, hung_up__q})))));
}
bool has_pollin__q__bool__int16(ctx* _ctx, int16 revents) {
	return bits_intersect__q__bool__int16__int16(revents, pollin__int16(_ctx));
}
bool bits_intersect__q__bool__int16__int16(int16 a, int16 b) {
	return !(zero__q__bool__int16((a & b)));
}
_void read_to_buffer_until_eof___void__int32__ptr_mut_arr__char(ctx* _ctx, int32 fd, mut_arr__char* buffer) {
	nat read_max;
	ptr__char add_data_to;
	_int n_bytes_read;
	return ((read_max = two_pow__nat__nat(ten__nat())),
	(ensure_capacity___void__ptr_mut_arr__char__nat(_ctx, buffer, _op_plus__nat__nat__nat(_ctx, buffer->size, read_max)),
	((add_data_to = (buffer->data + buffer->size)),
	((n_bytes_read = read(fd, (ptr__byte) add_data_to, read_max)),
	_op_equal_equal__bool___int___int(n_bytes_read, neg_one___int())
		? todo___void()
		: _op_equal_equal__bool___int___int(n_bytes_read, 0)
			? 0
			: ((assert___void__bool(_ctx, _op_less_equal__bool__nat__nat(to_nat__nat___int(_ctx, n_bytes_read), read_max)),
			unsafe_increase_size___void__ptr_mut_arr__char__nat(_ctx, buffer, to_nat__nat___int(_ctx, n_bytes_read))),
			read_to_buffer_until_eof___void__int32__ptr_mut_arr__char(_ctx, fd, buffer))))));
}
nat two_pow__nat__nat(nat pow) {
	return zero__q__bool__nat(pow)
		? 1
		: (two_pow__nat__nat(wrap_decr__nat__nat(pow)) * two__nat());
}
_void ensure_capacity___void__ptr_mut_arr__char__nat(ctx* _ctx, mut_arr__char* a, nat capacity) {
	return _op_less__bool__nat__nat(a->capacity, capacity)
		? increase_capacity_to___void__ptr_mut_arr__char__nat(_ctx, a, round_up_to_power_of_two__nat__nat(_ctx, capacity))
		: 0;
}
_void increase_capacity_to___void__ptr_mut_arr__char__nat(ctx* _ctx, mut_arr__char* a, nat new_capacity) {
	ptr__char old_data;
	return (assert___void__bool(_ctx, _op_greater__bool__nat__nat(new_capacity, a->capacity)),
	((old_data = a->data),
	(((a->capacity = new_capacity), 0,
	(a->data = uninitialized_data__ptr__char__nat(_ctx, new_capacity)), 0),
	copy_data_from___void__ptr__char__ptr__char__nat(_ctx, a->data, old_data, a->size))));
}
_void copy_data_from___void__ptr__char__ptr__char__nat(ctx* _ctx, ptr__char to, ptr__char from, nat len) {
	nat hl;
	return _op_less__bool__nat__nat(len, eight__nat())
		? copy_data_from_small___void__ptr__char__ptr__char__nat(_ctx, to, from, len)
		: ((hl = _op_div__nat__nat__nat(_ctx, len, two__nat())),
		(copy_data_from___void__ptr__char__ptr__char__nat(_ctx, to, from, hl),
		copy_data_from___void__ptr__char__ptr__char__nat(_ctx, (to + hl), (from + hl), _op_minus__nat__nat__nat(_ctx, len, hl))));
}
_void copy_data_from_small___void__ptr__char__ptr__char__nat(ctx* _ctx, ptr__char to, ptr__char from, nat len) {
	return zero__q__bool__nat(len)
		? 0
		: (((*(to) = *(from)), 0),
		copy_data_from___void__ptr__char__ptr__char__nat(_ctx, incr__ptr__char__ptr__char(to), incr__ptr__char__ptr__char(from), decr__nat__nat(_ctx, len)));
}
_void unsafe_increase_size___void__ptr_mut_arr__char__nat(ctx* _ctx, mut_arr__char* a, nat increase_by) {
	return unsafe_set_size___void__ptr_mut_arr__char__nat(_ctx, a, _op_plus__nat__nat__nat(_ctx, a->size, increase_by));
}
_void unsafe_set_size___void__ptr_mut_arr__char__nat(ctx* _ctx, mut_arr__char* a, nat new_size) {
	return (assert___void__bool(_ctx, _op_less_equal__bool__nat__nat(new_size, a->capacity)),
	(a->size = new_size), 0);
}
bool has_pollhup__q__bool__int16(ctx* _ctx, int16 revents) {
	return bits_intersect__q__bool__int16__int16(revents, pollhup__int16(_ctx));
}
int16 pollhup__int16(ctx* _ctx) {
	return two_pow__int16__int16(four__int16());
}
int16 four__int16() {
	return wrap_incr__int16__int16(three__int16());
}
int16 three__int16() {
	return wrap_incr__int16__int16(two__int16());
}
bool has_pollpri__q__bool__int16(ctx* _ctx, int16 revents) {
	return bits_intersect__q__bool__int16__int16(revents, pollpri__int16(_ctx));
}
int16 pollpri__int16(ctx* _ctx) {
	return two_pow__int16__int16(1);
}
bool has_pollout__q__bool__int16(ctx* _ctx, int16 revents) {
	return bits_intersect__q__bool__int16__int16(revents, pollout__int16(_ctx));
}
int16 pollout__int16(ctx* _ctx) {
	return two_pow__int16__int16(two__int16());
}
bool has_pollerr__q__bool__int16(ctx* _ctx, int16 revents) {
	return bits_intersect__q__bool__int16__int16(revents, pollerr__int16(_ctx));
}
int16 pollerr__int16(ctx* _ctx) {
	return two_pow__int16__int16(three__int16());
}
bool has_pollnval__q__bool__int16(ctx* _ctx, int16 revents) {
	return bits_intersect__q__bool__int16__int16(revents, pollnval__int16(_ctx));
}
int16 pollnval__int16(ctx* _ctx) {
	return two_pow__int16__int16(five__int16());
}
int16 five__int16() {
	return wrap_incr__int16__int16(four__int16());
}
nat to_nat__nat__bool(ctx* _ctx, bool b) {
	return (b ? 1 : 0);
}
bool any__q__bool__handle_revents_result(ctx* _ctx, handle_revents_result r) {
	return (r.had_pollin__q || r.hung_up__q);
}
nat to_nat__nat__int32(ctx* _ctx, int32 i) {
	return to_nat__nat___int(_ctx, (_int) i);
}
int32 wait_and_get_exit_code__int32__int32(ctx* _ctx, int32 pid) {
	cell__int32* wait_status_cell;
	int32 res_pid;
	int32 wait_status;
	int32 signal;
	return ((wait_status_cell = new_cell__ptr_cell__int32__int32(_ctx, 0)),
	((res_pid = waitpid(pid, wait_status_cell, 0)),
	((wait_status = get__int32__ptr_cell__int32(wait_status_cell)),
	(assert___void__bool(_ctx, _op_equal_equal__bool__int32__int32(res_pid, pid)),
	w_if_exited__bool__int32(_ctx, wait_status)
		? w_exit_status__int32__int32(_ctx, wait_status)
		: w_if_signaled__bool__int32(_ctx, wait_status)
			? ((signal = w_term_sig__int32__int32(_ctx, wait_status)),
			(print_sync___void__arr__char(_op_plus__arr__char__arr__char__arr__char(_ctx, (arr__char){31, "Process terminated with signal "}, to_str__arr__char__int32(_ctx, signal))),
			todo__int32()))
			: w_if_stopped__bool__int32(_ctx, wait_status)
				? (print_sync___void__arr__char((arr__char){12, "WAIT STOPPED"}),
				todo__int32())
				: w_if_continued__bool__int32(_ctx, wait_status)
					? todo__int32()
					: todo__int32()))));
}
bool w_if_exited__bool__int32(ctx* _ctx, int32 status) {
	return zero__q__bool__int32(w_term_sig__int32__int32(_ctx, status));
}
int32 w_term_sig__int32__int32(ctx* _ctx, int32 status) {
	return (status & x7f__int32());
}
int32 x7f__int32() {
	return noctx_decr__int32__int32(two_pow__int32__int32(seven__int32()));
}
int32 noctx_decr__int32__int32(int32 a) {
	return (hard_forbid___void__bool(zero__q__bool__int32(a)),
	(a - 1));
}
int32 two_pow__int32__int32(int32 pow) {
	return zero__q__bool__int32(pow)
		? 1
		: (two_pow__int32__int32(wrap_decr__int32__int32(pow)) * two__int32());
}
int32 wrap_decr__int32__int32(int32 a) {
	return (a - 1);
}
int32 w_exit_status__int32__int32(ctx* _ctx, int32 status) {
	return ((status & xff00__int32()) >> eight__int32());
}
int32 xff00__int32() {
	return (xffff__int32() - xff__int32());
}
int32 xffff__int32() {
	return noctx_decr__int32__int32(two_pow__int32__int32(sixteen__int32()));
}
int32 sixteen__int32() {
	return (ten__int32() + six__int32());
}
int32 xff__int32() {
	return noctx_decr__int32__int32(two_pow__int32__int32(eight__int32()));
}
bool w_if_signaled__bool__int32(ctx* _ctx, int32 status) {
	int32 ts;
	return ((ts = w_term_sig__int32__int32(_ctx, status)),
	(_op_bang_equal__bool__int32__int32(ts, 0) && _op_bang_equal__bool__int32__int32(ts, x7f__int32())));
}
bool _op_bang_equal__bool__int32__int32(int32 a, int32 b) {
	return !(_op_equal_equal__bool__int32__int32(a, b));
}
arr__char to_str__arr__char__int32(ctx* _ctx, int32 i) {
	return to_str__arr__char___int(_ctx, (_int) i);
}
arr__char to_str__arr__char___int(ctx* _ctx, _int i) {
	arr__char a;
	return ((a = to_str__arr__char__nat(_ctx, abs__nat___int(_ctx, i))),
	(negative__q__bool___int(_ctx, i) ? _op_plus__arr__char__arr__char__arr__char(_ctx, (arr__char){1, "-"}, a) : a));
}
arr__char to_str__arr__char__nat(ctx* _ctx, nat n) {
	arr__char hi;
	arr__char lo;
	return _op_equal_equal__bool__nat__nat(n, literal__nat__arr__char(_ctx, (arr__char){1, "0"}))
		? (arr__char){1, "0"}
		: _op_equal_equal__bool__nat__nat(n, literal__nat__arr__char(_ctx, (arr__char){1, "1"}))
			? (arr__char){1, "1"}
			: _op_equal_equal__bool__nat__nat(n, literal__nat__arr__char(_ctx, (arr__char){1, "2"}))
				? (arr__char){1, "2"}
				: _op_equal_equal__bool__nat__nat(n, literal__nat__arr__char(_ctx, (arr__char){1, "3"}))
					? (arr__char){1, "3"}
					: _op_equal_equal__bool__nat__nat(n, literal__nat__arr__char(_ctx, (arr__char){1, "4"}))
						? (arr__char){1, "4"}
						: _op_equal_equal__bool__nat__nat(n, literal__nat__arr__char(_ctx, (arr__char){1, "5"}))
							? (arr__char){1, "5"}
							: _op_equal_equal__bool__nat__nat(n, literal__nat__arr__char(_ctx, (arr__char){1, "6"}))
								? (arr__char){1, "6"}
								: _op_equal_equal__bool__nat__nat(n, literal__nat__arr__char(_ctx, (arr__char){1, "7"}))
									? (arr__char){1, "7"}
									: _op_equal_equal__bool__nat__nat(n, literal__nat__arr__char(_ctx, (arr__char){1, "8"}))
										? (arr__char){1, "8"}
										: _op_equal_equal__bool__nat__nat(n, literal__nat__arr__char(_ctx, (arr__char){1, "9"}))
											? (arr__char){1, "9"}
											: ((hi = to_str__arr__char__nat(_ctx, _op_div__nat__nat__nat(_ctx, n, ten__nat()))),
											((lo = to_str__arr__char__nat(_ctx, mod__nat__nat__nat(_ctx, n, ten__nat()))),
											_op_plus__arr__char__arr__char__arr__char(_ctx, hi, lo)));
}
nat mod__nat__nat__nat(ctx* _ctx, nat a, nat b) {
	return (forbid___void__bool(_ctx, zero__q__bool__nat(b)),
	(a % b));
}
nat abs__nat___int(ctx* _ctx, _int i) {
	_int i_abs;
	return ((i_abs = (negative__q__bool___int(_ctx, i) ? neg___int___int(_ctx, i) : i)),
	to_nat__nat___int(_ctx, i_abs));
}
int32 todo__int32() {
	return hard_fail__int32__arr__char((arr__char){4, "TODO"});
}
int32 hard_fail__int32__arr__char(arr__char reason) {
	assert(0);
}
bool w_if_stopped__bool__int32(ctx* _ctx, int32 status) {
	return _op_equal_equal__bool__int32__int32((status & xff__int32()), x7f__int32());
}
bool w_if_continued__bool__int32(ctx* _ctx, int32 status) {
	return _op_equal_equal__bool__int32__int32(status, xffff__int32());
}
ptr__ptr__char convert_args__ptr__ptr__char__ptr__char__arr__arr__char(ctx* _ctx, ptr__char exe_c_str, arr__arr__char args) {
	return cons__arr__ptr__char__ptr__char__arr__ptr__char(_ctx, exe_c_str, rcons__arr__ptr__char__arr__ptr__char__ptr__char(_ctx, map__arr__ptr__char__arr__arr__char__fun_mut1__ptr__char__arr__char(_ctx, args, (fun_mut1__ptr__char__arr__char) {
		(fun_ptr3__ptr__char__ptr_ctx__ptr__byte__arr__char) convert_args__ptr__ptr__char__ptr__char__arr__arr__char__lambda0,
		(ptr__byte) NULL
	}), NULL)).data;
}
arr__ptr__char cons__arr__ptr__char__ptr__char__arr__ptr__char(ctx* _ctx, ptr__char a, arr__ptr__char b) {
	arr__ptr__char arr;
	return _op_plus__arr__ptr__char__arr__ptr__char__arr__ptr__char(_ctx, (arr = (arr__ptr__char) { 1, (ptr__char*) alloc__ptr__byte__nat(_ctx, 8) }, arr.data[0] =a, arr), b);
}
arr__ptr__char _op_plus__arr__ptr__char__arr__ptr__char__arr__ptr__char(ctx* _ctx, arr__ptr__char a, arr__ptr__char b) {
	return make_arr__arr__ptr__char__nat__fun_mut1__ptr__char__nat(_ctx, _op_plus__nat__nat__nat(_ctx, a.size, b.size), (fun_mut1__ptr__char__nat) {
		(fun_ptr3__ptr__char__ptr_ctx__ptr__byte__nat) _op_plus__arr__ptr__char__arr__ptr__char__arr__ptr__char__lambda0,
		(ptr__byte) _init_op_plus__arr__ptr__char__arr__ptr__char__arr__ptr__char__lambda0___closure(alloc__ptr__byte__nat(_ctx, 32), (_op_plus__arr__ptr__char__arr__ptr__char__arr__ptr__char__lambda0___closure) {a, b})
	});
}
arr__ptr__char make_arr__arr__ptr__char__nat__fun_mut1__ptr__char__nat(ctx* _ctx, nat size, fun_mut1__ptr__char__nat f) {
	return freeze__arr__ptr__char__ptr_mut_arr__ptr__char(make_mut_arr__ptr_mut_arr__ptr__char__nat__fun_mut1__ptr__char__nat(_ctx, size, f));
}
arr__ptr__char freeze__arr__ptr__char__ptr_mut_arr__ptr__char(mut_arr__ptr__char* a) {
	return ((a->frozen__q = 1), 0,
	unsafe_as_arr__arr__ptr__char__ptr_mut_arr__ptr__char(a));
}
arr__ptr__char unsafe_as_arr__arr__ptr__char__ptr_mut_arr__ptr__char(mut_arr__ptr__char* a) {
	return (arr__ptr__char) {a->size, a->data};
}
mut_arr__ptr__char* make_mut_arr__ptr_mut_arr__ptr__char__nat__fun_mut1__ptr__char__nat(ctx* _ctx, nat size, fun_mut1__ptr__char__nat f) {
	mut_arr__ptr__char* res;
	return ((res = new_uninitialized_mut_arr__ptr_mut_arr__ptr__char__nat(_ctx, size)),
	(make_mut_arr_worker___void__ptr_mut_arr__ptr__char__nat__nat__fun_mut1__ptr__char__nat(_ctx, res, 0, size, f),
	res));
}
mut_arr__ptr__char* new_uninitialized_mut_arr__ptr_mut_arr__ptr__char__nat(ctx* _ctx, nat size) {
	return _initmut_arr__ptr__char(alloc__ptr__byte__nat(_ctx, 32), (mut_arr__ptr__char) {0, size, size, uninitialized_data__ptr__ptr__char__nat(_ctx, size)});
}
ptr__ptr__char uninitialized_data__ptr__ptr__char__nat(ctx* _ctx, nat size) {
	ptr__byte bptr;
	return ((bptr = alloc__ptr__byte__nat(_ctx, (size * sizeof(ptr__char)))),
	(ptr__ptr__char) bptr);
}
_void make_mut_arr_worker___void__ptr_mut_arr__ptr__char__nat__nat__fun_mut1__ptr__char__nat(ctx* _ctx, mut_arr__ptr__char* m, nat lo, nat hi, fun_mut1__ptr__char__nat f) {
	nat mid;
	return _op_equal_equal__bool__nat__nat(lo, hi)
		? 0
		: (set_at___void__ptr_mut_arr__ptr__char__nat__ptr__char(_ctx, m, lo, call__ptr__char__fun_mut1__ptr__char__nat__nat(_ctx, f, lo)),
		((mid = _op_div__nat__nat__nat(_ctx, _op_plus__nat__nat__nat(_ctx, incr__nat__nat(_ctx, lo), hi), two__nat())),
		(make_mut_arr_worker___void__ptr_mut_arr__ptr__char__nat__nat__fun_mut1__ptr__char__nat(_ctx, m, incr__nat__nat(_ctx, lo), mid, f),
		make_mut_arr_worker___void__ptr_mut_arr__ptr__char__nat__nat__fun_mut1__ptr__char__nat(_ctx, m, mid, hi, f))));
}
_void set_at___void__ptr_mut_arr__ptr__char__nat__ptr__char(ctx* _ctx, mut_arr__ptr__char* a, nat index, ptr__char value) {
	return (assert___void__bool(_ctx, _op_less__bool__nat__nat(index, a->size)),
	noctx_set_at___void__ptr_mut_arr__ptr__char__nat__ptr__char(a, index, value));
}
_void noctx_set_at___void__ptr_mut_arr__ptr__char__nat__ptr__char(mut_arr__ptr__char* a, nat index, ptr__char value) {
	return (hard_assert___void__bool(_op_less__bool__nat__nat(index, a->size)),
	((*((a->data + index)) = value), 0));
}
ptr__char call__ptr__char__fun_mut1__ptr__char__nat__nat(ctx* _ctx, fun_mut1__ptr__char__nat f, nat p0) {
	return call_with_ctx__ptr__char__ptr_ctx__fun_mut1__ptr__char__nat__nat(_ctx, f, p0);
}
ptr__char call_with_ctx__ptr__char__ptr_ctx__fun_mut1__ptr__char__nat__nat(ctx* c, fun_mut1__ptr__char__nat f, nat p0) {
	return f.fun_ptr(c, f.closure, p0);
}
ptr__char _op_plus__arr__ptr__char__arr__ptr__char__arr__ptr__char__lambda0(ctx* _ctx, _op_plus__arr__ptr__char__arr__ptr__char__arr__ptr__char__lambda0___closure* _closure, nat i) {
	return _op_less__bool__nat__nat(i, _closure->a.size)
		? at__ptr__char__arr__ptr__char__nat(_ctx, _closure->a, i)
		: at__ptr__char__arr__ptr__char__nat(_ctx, _closure->b, _op_minus__nat__nat__nat(_ctx, i, _closure->a.size));
}
arr__ptr__char rcons__arr__ptr__char__arr__ptr__char__ptr__char(ctx* _ctx, arr__ptr__char a, ptr__char b) {
	arr__ptr__char arr;
	return _op_plus__arr__ptr__char__arr__ptr__char__arr__ptr__char(_ctx, a, (arr = (arr__ptr__char) { 1, (ptr__char*) alloc__ptr__byte__nat(_ctx, 8) }, arr.data[0] =b, arr));
}
arr__ptr__char map__arr__ptr__char__arr__arr__char__fun_mut1__ptr__char__arr__char(ctx* _ctx, arr__arr__char a, fun_mut1__ptr__char__arr__char mapper) {
	return make_arr__arr__ptr__char__nat__fun_mut1__ptr__char__nat(_ctx, a.size, (fun_mut1__ptr__char__nat) {
		(fun_ptr3__ptr__char__ptr_ctx__ptr__byte__nat) map__arr__ptr__char__arr__arr__char__fun_mut1__ptr__char__arr__char__lambda0,
		(ptr__byte) _initmap__arr__ptr__char__arr__arr__char__fun_mut1__ptr__char__arr__char__lambda0___closure(alloc__ptr__byte__nat(_ctx, 32), (map__arr__ptr__char__arr__arr__char__fun_mut1__ptr__char__arr__char__lambda0___closure) {mapper, a})
	});
}
ptr__char call__ptr__char__fun_mut1__ptr__char__arr__char__arr__char(ctx* _ctx, fun_mut1__ptr__char__arr__char f, arr__char p0) {
	return call_with_ctx__ptr__char__ptr_ctx__fun_mut1__ptr__char__arr__char__arr__char(_ctx, f, p0);
}
ptr__char call_with_ctx__ptr__char__ptr_ctx__fun_mut1__ptr__char__arr__char__arr__char(ctx* c, fun_mut1__ptr__char__arr__char f, arr__char p0) {
	return f.fun_ptr(c, f.closure, p0);
}
ptr__char map__arr__ptr__char__arr__arr__char__fun_mut1__ptr__char__arr__char__lambda0(ctx* _ctx, map__arr__ptr__char__arr__arr__char__fun_mut1__ptr__char__arr__char__lambda0___closure* _closure, nat i) {
	return call__ptr__char__fun_mut1__ptr__char__arr__char__arr__char(_ctx, _closure->mapper, at__arr__char__arr__arr__char__nat(_ctx, _closure->a, i));
}
ptr__char convert_args__ptr__ptr__char__ptr__char__arr__arr__char__lambda0(ctx* _ctx, ptr__byte _closure, arr__char it) {
	return to_c_str__ptr__char__arr__char(_ctx, it);
}
ptr__ptr__char convert_environ__ptr__ptr__char__ptr_dict__arr__char__arr__char(ctx* _ctx, dict__arr__char__arr__char* environ) {
	mut_arr__ptr__char* res;
	return ((res = new_mut_arr__ptr_mut_arr__ptr__char(_ctx)),
	((each___void__ptr_dict__arr__char__arr__char__fun_mut2___void__arr__char__arr__char(_ctx, environ, (fun_mut2___void__arr__char__arr__char) {
		(fun_ptr4___void__ptr_ctx__ptr__byte__arr__char__arr__char) convert_environ__ptr__ptr__char__ptr_dict__arr__char__arr__char__lambda0,
		(ptr__byte) _initconvert_environ__ptr__ptr__char__ptr_dict__arr__char__arr__char__lambda0___closure(alloc__ptr__byte__nat(_ctx, 8), (convert_environ__ptr__ptr__char__ptr_dict__arr__char__arr__char__lambda0___closure) {res})
	}),
	push___void__ptr_mut_arr__ptr__char__ptr__char(_ctx, res, NULL)),
	freeze__arr__ptr__char__ptr_mut_arr__ptr__char(res).data));
}
mut_arr__ptr__char* new_mut_arr__ptr_mut_arr__ptr__char(ctx* _ctx) {
	return _initmut_arr__ptr__char(alloc__ptr__byte__nat(_ctx, 32), (mut_arr__ptr__char) {0, 0, 0, NULL});
}
_void each___void__ptr_dict__arr__char__arr__char__fun_mut2___void__arr__char__arr__char(ctx* _ctx, dict__arr__char__arr__char* d, fun_mut2___void__arr__char__arr__char f) {
	return empty__q__bool__ptr_dict__arr__char__arr__char(_ctx, d)
		? 0
		: (call___void__fun_mut2___void__arr__char__arr__char__arr__char__arr__char(_ctx, f, first__arr__char__arr__arr__char(_ctx, d->keys), first__arr__char__arr__arr__char(_ctx, d->values)),
		each___void__ptr_dict__arr__char__arr__char__fun_mut2___void__arr__char__arr__char(_ctx, _initdict__arr__char__arr__char(alloc__ptr__byte__nat(_ctx, 32), (dict__arr__char__arr__char) {tail__arr__arr__char__arr__arr__char(_ctx, d->keys), tail__arr__arr__char__arr__arr__char(_ctx, d->values)}), f));
}
bool empty__q__bool__ptr_dict__arr__char__arr__char(ctx* _ctx, dict__arr__char__arr__char* d) {
	return empty__q__bool__arr__arr__char(d->keys);
}
_void call___void__fun_mut2___void__arr__char__arr__char__arr__char__arr__char(ctx* _ctx, fun_mut2___void__arr__char__arr__char f, arr__char p0, arr__char p1) {
	return call_with_ctx___void__ptr_ctx__fun_mut2___void__arr__char__arr__char__arr__char__arr__char(_ctx, f, p0, p1);
}
_void call_with_ctx___void__ptr_ctx__fun_mut2___void__arr__char__arr__char__arr__char__arr__char(ctx* c, fun_mut2___void__arr__char__arr__char f, arr__char p0, arr__char p1) {
	return f.fun_ptr(c, f.closure, p0, p1);
}
_void push___void__ptr_mut_arr__ptr__char__ptr__char(ctx* _ctx, mut_arr__ptr__char* a, ptr__char value) {
	return ((((_op_equal_equal__bool__nat__nat(a->size, a->capacity)
		? increase_capacity_to___void__ptr_mut_arr__ptr__char__nat(_ctx, a, (zero__q__bool__nat(a->size) ? four__nat() : _op_times__nat__nat__nat(_ctx, a->size, two__nat())))
		: 0,
	ensure_capacity___void__ptr_mut_arr__ptr__char__nat(_ctx, a, round_up_to_power_of_two__nat__nat(_ctx, incr__nat__nat(_ctx, a->size)))),
	assert___void__bool(_ctx, _op_less__bool__nat__nat(a->size, a->capacity))),
	((*((a->data + a->size)) = value), 0)),
	(a->size = incr__nat__nat(_ctx, a->size)), 0);
}
_void increase_capacity_to___void__ptr_mut_arr__ptr__char__nat(ctx* _ctx, mut_arr__ptr__char* a, nat new_capacity) {
	ptr__ptr__char old_data;
	return (assert___void__bool(_ctx, _op_greater__bool__nat__nat(new_capacity, a->capacity)),
	((old_data = a->data),
	(((a->capacity = new_capacity), 0,
	(a->data = uninitialized_data__ptr__ptr__char__nat(_ctx, new_capacity)), 0),
	copy_data_from___void__ptr__ptr__char__ptr__ptr__char__nat(_ctx, a->data, old_data, a->size))));
}
_void copy_data_from___void__ptr__ptr__char__ptr__ptr__char__nat(ctx* _ctx, ptr__ptr__char to, ptr__ptr__char from, nat len) {
	nat hl;
	return _op_less__bool__nat__nat(len, eight__nat())
		? copy_data_from_small___void__ptr__ptr__char__ptr__ptr__char__nat(_ctx, to, from, len)
		: ((hl = _op_div__nat__nat__nat(_ctx, len, two__nat())),
		(copy_data_from___void__ptr__ptr__char__ptr__ptr__char__nat(_ctx, to, from, hl),
		copy_data_from___void__ptr__ptr__char__ptr__ptr__char__nat(_ctx, (to + hl), (from + hl), _op_minus__nat__nat__nat(_ctx, len, hl))));
}
_void copy_data_from_small___void__ptr__ptr__char__ptr__ptr__char__nat(ctx* _ctx, ptr__ptr__char to, ptr__ptr__char from, nat len) {
	return zero__q__bool__nat(len)
		? 0
		: (((*(to) = *(from)), 0),
		copy_data_from___void__ptr__ptr__char__ptr__ptr__char__nat(_ctx, incr__ptr__ptr__char__ptr__ptr__char(to), incr__ptr__ptr__char__ptr__ptr__char(from), decr__nat__nat(_ctx, len)));
}
_void ensure_capacity___void__ptr_mut_arr__ptr__char__nat(ctx* _ctx, mut_arr__ptr__char* a, nat capacity) {
	return _op_less__bool__nat__nat(a->capacity, capacity)
		? increase_capacity_to___void__ptr_mut_arr__ptr__char__nat(_ctx, a, round_up_to_power_of_two__nat__nat(_ctx, capacity))
		: 0;
}
_void convert_environ__ptr__ptr__char__ptr_dict__arr__char__arr__char__lambda0(ctx* _ctx, convert_environ__ptr__ptr__char__ptr_dict__arr__char__arr__char__lambda0___closure* _closure, arr__char key, arr__char value) {
	return push___void__ptr_mut_arr__ptr__char__ptr__char(_ctx, _closure->res, to_c_str__ptr__char__arr__char(_ctx, _op_plus__arr__char__arr__char__arr__char(_ctx, _op_plus__arr__char__arr__char__arr__char(_ctx, key, (arr__char){1, "="}), value)));
}
process_result* fail__ptr_process_result__arr__char(ctx* _ctx, arr__char reason) {
	return throw__ptr_process_result__exception(_ctx, (exception) {reason});
}
process_result* throw__ptr_process_result__exception(ctx* _ctx, exception e) {
	exception_ctx* exn_ctx;
	return ((exn_ctx = get_exception_ctx__ptr_exception_ctx(_ctx)),
	(((hard_forbid___void__bool(_op_equal_equal__bool__ptr__jmp_buf_tag__ptr__jmp_buf_tag(exn_ctx->jmp_buf_ptr, NULL)),
	(exn_ctx->thrown_exception = e), 0),
	(longjmp(exn_ctx->jmp_buf_ptr, number_to_throw__int32(_ctx)), 0)),
	todo__ptr_process_result()));
}
process_result* todo__ptr_process_result() {
	return hard_fail__ptr_process_result__arr__char((arr__char){4, "TODO"});
}
process_result* hard_fail__ptr_process_result__arr__char(arr__char reason) {
	assert(0);
}
arr__char remove_colors__arr__char__arr__char(ctx* _ctx, arr__char s) {
	mut_arr__char* out;
	return ((out = new_mut_arr__ptr_mut_arr__char(_ctx)),
	(remove_colors_recur___void__arr__char__ptr_mut_arr__char(_ctx, s, out),
	freeze__arr__char__ptr_mut_arr__char(out)));
}
_void remove_colors_recur___void__arr__char__ptr_mut_arr__char(ctx* _ctx, arr__char s, mut_arr__char* out) {
	return empty__q__bool__arr__char(s)
		? 0
		: _op_equal_equal__bool__char__char(first__char__arr__char(_ctx, s), literal__char__arr__char((arr__char){1, "\x1b"}))
			? remove_colors_recur_2___void__arr__char__ptr_mut_arr__char(_ctx, tail__arr__char__arr__char(_ctx, s), out)
			: (push___void__ptr_mut_arr__char__char(_ctx, out, first__char__arr__char(_ctx, s)),
			remove_colors_recur___void__arr__char__ptr_mut_arr__char(_ctx, tail__arr__char__arr__char(_ctx, s), out));
}
_void remove_colors_recur_2___void__arr__char__ptr_mut_arr__char(ctx* _ctx, arr__char s, mut_arr__char* out) {
	return empty__q__bool__arr__char(s)
		? 0
		: _op_equal_equal__bool__char__char(first__char__arr__char(_ctx, s), literal__char__arr__char((arr__char){1, "m"}))
			? remove_colors_recur___void__arr__char__ptr_mut_arr__char(_ctx, tail__arr__char__arr__char(_ctx, s), out)
			: remove_colors_recur_2___void__arr__char__ptr_mut_arr__char(_ctx, tail__arr__char__arr__char(_ctx, s), out);
}
_void push___void__ptr_mut_arr__char__char(ctx* _ctx, mut_arr__char* a, char value) {
	return ((((_op_equal_equal__bool__nat__nat(a->size, a->capacity)
		? increase_capacity_to___void__ptr_mut_arr__char__nat(_ctx, a, (zero__q__bool__nat(a->size) ? four__nat() : _op_times__nat__nat__nat(_ctx, a->size, two__nat())))
		: 0,
	ensure_capacity___void__ptr_mut_arr__char__nat(_ctx, a, round_up_to_power_of_two__nat__nat(_ctx, incr__nat__nat(_ctx, a->size)))),
	assert___void__bool(_ctx, _op_less__bool__nat__nat(a->size, a->capacity))),
	((*((a->data + a->size)) = value), 0)),
	(a->size = incr__nat__nat(_ctx, a->size)), 0);
}
arr__ptr_failure handle_output__arr__ptr_failure__arr__char__arr__char__arr__char__bool(ctx* _ctx, arr__char original_path, arr__char output_path, arr__char actual, bool overwrite_output__q) {
	arr__ptr_failure arr;
	some__arr__char s;
	arr__char message;
	arr__ptr_failure arr1;
	opt__arr__char matched;
	return (matched = try_read_file__opt__arr__char__arr__char(_ctx, output_path),
		matched.kind == 0
		? overwrite_output__q
			? (write_file___void__arr__char__arr__char(_ctx, output_path, actual),
			empty_arr__arr__ptr_failure())
			: (arr = (arr__ptr_failure) { 1, (failure**) alloc__ptr__byte__nat(_ctx, 8) }, arr.data[0] =_initfailure(alloc__ptr__byte__nat(_ctx, 32), (failure) {original_path, _op_plus__arr__char__arr__char__arr__char(_ctx, _op_plus__arr__char__arr__char__arr__char(_ctx, base_name__arr__char__arr__char(_ctx, output_path), (arr__char){29, " does not exist. actual was:\n"}), actual)}), arr)
		: matched.kind == 1
		? (s = matched.as_some__arr__char,
		large_strings_eq__q__bool__arr__char__arr__char(_ctx, s.value, actual)
			? empty_arr__arr__ptr_failure()
			: overwrite_output__q
				? (write_file___void__arr__char__arr__char(_ctx, output_path, actual),
				empty_arr__arr__ptr_failure())
				: ((message = _op_plus__arr__char__arr__char__arr__char(_ctx, _op_plus__arr__char__arr__char__arr__char(_ctx, base_name__arr__char__arr__char(_ctx, output_path), (arr__char){30, " was not as expected. actual:\n"}), actual)),
				(arr1 = (arr__ptr_failure) { 1, (failure**) alloc__ptr__byte__nat(_ctx, 8) }, arr1.data[0] =_initfailure(alloc__ptr__byte__nat(_ctx, 32), (failure) {original_path, message}), arr1))
		): _failarr__ptr_failure());
}
opt__arr__char try_read_file__opt__arr__char__arr__char(ctx* _ctx, arr__char path) {
	return try_read_file__opt__arr__char__ptr__char(_ctx, to_c_str__ptr__char__arr__char(_ctx, path));
}
opt__arr__char try_read_file__opt__arr__char__ptr__char(ctx* _ctx, ptr__char path) {
	int32 fd;
	int32 errno;
	_int file_size;
	_int off;
	nat file_size_nat;
	mut_arr__char* res;
	_int n_bytes_read;
	return is_file__q__bool__ptr__char(_ctx, path)
		? ((fd = open(path, o_rdonly__int32(_ctx), literal__int32__arr__char(_ctx, (arr__char){1, "0"}))),
		_op_equal_equal__bool__int32__int32(fd, neg_one__int32())
			? ((errno = get_errno__int32(_ctx)),
			_op_equal_equal__bool__int32__int32(errno, enoent__int32())
				? (opt__arr__char) { 0, .as_none = none__none() }
				: (print_sync___void__arr__char(_op_plus__arr__char__arr__char__arr__char(_ctx, (arr__char){20, "failed to open file "}, to_str__arr__char__ptr__char(path))),
				todo__opt__arr__char()))
			: ((file_size = lseek(fd, 0, seek_end__int32(_ctx))),
			(((forbid___void__bool(_ctx, _op_equal_equal__bool___int___int(file_size, neg_one___int())),
			assert___void__bool(_ctx, _op_less__bool___int___int(file_size, billion___int()))),
			forbid___void__bool(_ctx, zero__q__bool___int(file_size))),
			((off = lseek(fd, 0, seek_set__int32(_ctx))),
			(assert___void__bool(_ctx, _op_equal_equal__bool___int___int(off, 0)),
			((file_size_nat = to_nat__nat___int(_ctx, file_size)),
			((res = new_uninitialized_mut_arr__ptr_mut_arr__char__nat(_ctx, file_size_nat)),
			((n_bytes_read = read(fd, (ptr__byte) res->data, file_size_nat)),
			(((forbid___void__bool(_ctx, _op_equal_equal__bool___int___int(n_bytes_read, neg_one___int())),
			assert___void__bool(_ctx, _op_equal_equal__bool___int___int(n_bytes_read, file_size))),
			check_posix_error___void__int32(_ctx, close(fd))),
			(opt__arr__char) { 1, .as_some__arr__char = some__some__arr__char__arr__char(freeze__arr__char__ptr_mut_arr__char(res)) })))))))))
		: (opt__arr__char) { 0, .as_none = none__none() };
}
int32 o_rdonly__int32(ctx* _ctx) {
	return 0;
}
opt__arr__char todo__opt__arr__char() {
	return hard_fail__opt__arr__char__arr__char((arr__char){4, "TODO"});
}
opt__arr__char hard_fail__opt__arr__char__arr__char(arr__char reason) {
	assert(0);
}
int32 seek_end__int32(ctx* _ctx) {
	return two__int32();
}
_int billion___int() {
	return (million___int() * thousand___int());
}
bool zero__q__bool___int(_int i) {
	return _op_equal_equal__bool___int___int(i, 0);
}
int32 seek_set__int32(ctx* _ctx) {
	return 0;
}
_void write_file___void__arr__char__arr__char(ctx* _ctx, arr__char path, arr__char content) {
	return write_file___void__ptr__char__arr__char(_ctx, to_c_str__ptr__char__arr__char(_ctx, path), content);
}
_void write_file___void__ptr__char__arr__char(ctx* _ctx, ptr__char path, arr__char content) {
	int32 permission_rdwr;
	int32 permission_rd;
	int32 permission;
	int32 flags;
	int32 fd;
	int32 errno;
	_int wrote_bytes;
	int32 err;
	return ((permission_rdwr = six__int32()),
	((permission_rd = four__int32()),
	((permission = (((permission_rdwr << six__int32()) | (permission_rd << three__int32())) | permission_rd)),
	((flags = ((o_creat__int32(_ctx) | o_wronly__int32(_ctx)) | o_trunc__int32(_ctx))),
	((fd = open(path, flags, permission)),
	_op_equal_equal__bool__int32__int32(fd, neg_one__int32())
		? ((errno = get_errno__int32(_ctx)),
		((((print_sync___void__arr__char(_op_plus__arr__char__arr__char__arr__char(_ctx, (arr__char){31, "failed to open file for write: "}, to_str__arr__char__ptr__char(path))),
		print_sync___void__arr__char(_op_plus__arr__char__arr__char__arr__char(_ctx, (arr__char){7, "errno: "}, to_str__arr__char__int32(_ctx, errno)))),
		print_sync___void__arr__char(_op_plus__arr__char__arr__char__arr__char(_ctx, (arr__char){7, "flags: "}, to_str__arr__char__int32(_ctx, flags)))),
		print_sync___void__arr__char(_op_plus__arr__char__arr__char__arr__char(_ctx, (arr__char){12, "permission: "}, to_str__arr__char__int32(_ctx, permission)))),
		todo___void()))
		: ((wrote_bytes = write(fd, (ptr__byte) content.data, content.size)),
		(_op_equal_equal__bool___int___int(wrote_bytes, to_int___int__nat(_ctx, content.size))
			? 0
			: _op_equal_equal__bool___int___int(wrote_bytes, literal___int__arr__char(_ctx, (arr__char){2, "-1"}))
				? todo___void()
				: todo___void(),
		((err = close(fd)),
		_op_equal_equal__bool__int32__int32(err, 0)
			? 0
			: todo___void()))))))));
}
int32 o_creat__int32(ctx* _ctx) {
	return (1 << six__int32());
}
int32 o_wronly__int32(ctx* _ctx) {
	return 1;
}
int32 o_trunc__int32(ctx* _ctx) {
	return (1 << nine__int32());
}
arr__ptr_failure empty_arr__arr__ptr_failure() {
	return (arr__ptr_failure) {0, NULL};
}
bool large_strings_eq__q__bool__arr__char__arr__char(ctx* _ctx, arr__char a, arr__char b) {
	nat hl;
	return _op_less__bool__nat__nat(a.size, literal__nat__arr__char(_ctx, (arr__char){3, "128"}))
		? _op_equal_equal__bool__arr__char__arr__char(a, b)
		: ((hl = _op_div__nat__nat__nat(_ctx, a.size, literal__nat__arr__char(_ctx, (arr__char){1, "2"}))),
		(_op_equal_equal__bool__arr__char__arr__char(slice__arr__char__arr__char__nat__nat(_ctx, a, 0, hl), slice__arr__char__arr__char__nat__nat(_ctx, b, 0, hl)) && _op_equal_equal__bool__arr__char__arr__char(slice_starting_at__arr__char__arr__char__nat(_ctx, a, hl), slice_starting_at__arr__char__arr__char__nat(_ctx, b, hl))));
}
arr__ptr_failure run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0(ctx* _ctx, run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0___closure* _closure, arr__char test) {
	return (_closure->options.print_tests__q
		? print_sync___void__arr__char(_op_plus__arr__char__arr__char__arr__char(_ctx, (arr__char){11, "noze build "}, test))
		: 0,
	run_single_compile_error_test__arr__ptr_failure__arr__char__ptr_dict__arr__char__arr__char__arr__char__bool(_ctx, _closure->path_to_noze, _closure->env, test, _closure->options.overwrite_output__q));
}
bool has__q__bool__arr__ptr_failure(arr__ptr_failure a) {
	return !(empty__q__bool__arr__ptr_failure(a));
}
err__arr__ptr_failure err__err__arr__ptr_failure__arr__ptr_failure(arr__ptr_failure t) {
	return (err__arr__ptr_failure) {t};
}
arr__ptr_failure with_max_size__arr__ptr_failure__arr__ptr_failure__nat(ctx* _ctx, arr__ptr_failure a, nat max_size) {
	return _op_greater__bool__nat__nat(a.size, max_size)
		? slice__arr__ptr_failure__arr__ptr_failure__nat__nat(_ctx, a, 0, max_size)
		: a;
}
ok__arr__char ok__ok__arr__char__arr__char(arr__char t) {
	return (ok__arr__char) {t};
}
result__arr__char__arr__ptr_failure first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure(ctx* _ctx, result__arr__char__arr__ptr_failure a, fun0__result__arr__char__arr__ptr_failure b) {
	return then__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun_mut1__result__arr__char__arr__ptr_failure__arr__char(_ctx, a, (fun_mut1__result__arr__char__arr__ptr_failure__arr__char) {
		(fun_ptr3__result__arr__char__arr__ptr_failure__ptr_ctx__ptr__byte__arr__char) first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure__lambda0,
		(ptr__byte) _initfirst_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure__lambda0___closure(alloc__ptr__byte__nat(_ctx, 16), (first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure__lambda0___closure) {b})
	});
}
result__arr__char__arr__ptr_failure then__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun_mut1__result__arr__char__arr__ptr_failure__arr__char(ctx* _ctx, result__arr__char__arr__ptr_failure a, fun_mut1__result__arr__char__arr__ptr_failure__arr__char f) {
	ok__arr__char o;
	err__arr__ptr_failure e;
	result__arr__char__arr__ptr_failure matched;
	return (matched = a,
		matched.kind == 0
		? (o = matched.as_ok__arr__char,
		call__result__arr__char__arr__ptr_failure__fun_mut1__result__arr__char__arr__ptr_failure__arr__char__arr__char(_ctx, f, o.value)
		): matched.kind == 1
		? (e = matched.as_err__arr__ptr_failure,
		(result__arr__char__arr__ptr_failure) { 1, .as_err__arr__ptr_failure = e }
		): _failresult__arr__char__arr__ptr_failure());
}
result__arr__char__arr__ptr_failure call__result__arr__char__arr__ptr_failure__fun_mut1__result__arr__char__arr__ptr_failure__arr__char__arr__char(ctx* _ctx, fun_mut1__result__arr__char__arr__ptr_failure__arr__char f, arr__char p0) {
	return call_with_ctx__result__arr__char__arr__ptr_failure__ptr_ctx__fun_mut1__result__arr__char__arr__ptr_failure__arr__char__arr__char(_ctx, f, p0);
}
result__arr__char__arr__ptr_failure call_with_ctx__result__arr__char__arr__ptr_failure__ptr_ctx__fun_mut1__result__arr__char__arr__ptr_failure__arr__char__arr__char(ctx* c, fun_mut1__result__arr__char__arr__ptr_failure__arr__char f, arr__char p0) {
	return f.fun_ptr(c, f.closure, p0);
}
result__arr__char__arr__ptr_failure call__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure(ctx* _ctx, fun0__result__arr__char__arr__ptr_failure f) {
	return call_with_ctx__result__arr__char__arr__ptr_failure__ptr_ctx__fun0__result__arr__char__arr__ptr_failure(_ctx, f);
}
result__arr__char__arr__ptr_failure call_with_ctx__result__arr__char__arr__ptr_failure__ptr_ctx__fun0__result__arr__char__arr__ptr_failure(ctx* c, fun0__result__arr__char__arr__ptr_failure f) {
	return f.fun_ptr(c, f.closure);
}
result__arr__char__arr__ptr_failure first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure__lambda0__lambda0(ctx* _ctx, first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure__lambda0__lambda0___closure* _closure, arr__char b_descr) {
	return (result__arr__char__arr__ptr_failure) { 0, .as_ok__arr__char = ok__ok__arr__char__arr__char(_op_plus__arr__char__arr__char__arr__char(_ctx, _op_plus__arr__char__arr__char__arr__char(_ctx, _closure->a_descr, (arr__char){1, "\n"}), b_descr)) };
}
result__arr__char__arr__ptr_failure first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure__lambda0(ctx* _ctx, first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure__lambda0___closure* _closure, arr__char a_descr) {
	return then__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun_mut1__result__arr__char__arr__ptr_failure__arr__char(_ctx, call__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure(_ctx, _closure->b), (fun_mut1__result__arr__char__arr__ptr_failure__arr__char) {
		(fun_ptr3__result__arr__char__arr__ptr_failure__ptr_ctx__ptr__byte__arr__char) first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure__lambda0__lambda0,
		(ptr__byte) _initfirst_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure__lambda0__lambda0___closure(alloc__ptr__byte__nat(_ctx, 16), (first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure__lambda0__lambda0___closure) {a_descr})
	});
}
result__arr__char__arr__ptr_failure run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options(ctx* _ctx, arr__char path, arr__char path_to_noze, dict__arr__char__arr__char* env, test_options options) {
	arr__arr__char tests;
	arr__ptr_failure failures;
	return ((tests = list_ast_and_model_tests__arr__arr__char__arr__char(_ctx, path)),
	((failures = flat_map_with_max_size__arr__ptr_failure__arr__arr__char__nat__fun_mut1__arr__ptr_failure__arr__char(_ctx, tests, options.max_failures, (fun_mut1__arr__ptr_failure__arr__char) {
		(fun_ptr3__arr__ptr_failure__ptr_ctx__ptr__byte__arr__char) run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0,
		(ptr__byte) _initrun_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0___closure(alloc__ptr__byte__nat(_ctx, 40), (run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0___closure) {options, path_to_noze, env})
	})),
	has__q__bool__arr__ptr_failure(failures)
		? (result__arr__char__arr__ptr_failure) { 1, .as_err__arr__ptr_failure = err__err__arr__ptr_failure__arr__ptr_failure(failures) }
		: (result__arr__char__arr__ptr_failure) { 0, .as_ok__arr__char = ok__ok__arr__char__arr__char(_op_plus__arr__char__arr__char__arr__char(_ctx, _op_plus__arr__char__arr__char__arr__char(_ctx, (arr__char){4, "ran "}, to_str__arr__char__nat(_ctx, tests.size)), (arr__char){10, " ast tests"})) }));
}
arr__arr__char list_ast_and_model_tests__arr__arr__char__arr__char(ctx* _ctx, arr__char path) {
	mut_arr__arr__char* res;
	fun_mut1__bool__arr__char filter;
	return ((res = new_mut_arr__ptr_mut_arr__arr__char(_ctx)),
	((filter = (fun_mut1__bool__arr__char) {
		(fun_ptr3__bool__ptr_ctx__ptr__byte__arr__char) list_ast_and_model_tests__arr__arr__char__arr__char__lambda0,
		(ptr__byte) NULL
	}),
	(each_child_recursive___void__arr__char__fun_mut1__bool__arr__char__fun_mut1___void__arr__char(_ctx, path, filter, (fun_mut1___void__arr__char) {
		(fun_ptr3___void__ptr_ctx__ptr__byte__arr__char) list_ast_and_model_tests__arr__arr__char__arr__char__lambda1,
		(ptr__byte) _initlist_ast_and_model_tests__arr__arr__char__arr__char__lambda1___closure(alloc__ptr__byte__nat(_ctx, 8), (list_ast_and_model_tests__arr__arr__char__arr__char__lambda1___closure) {res})
	}),
	freeze__arr__arr__char__ptr_mut_arr__arr__char(res))));
}
bool list_ast_and_model_tests__arr__arr__char__arr__char__lambda0(ctx* _ctx, ptr__byte _closure, arr__char s) {
	return 1;
}
_void list_ast_and_model_tests__arr__arr__char__arr__char__lambda1(ctx* _ctx, list_ast_and_model_tests__arr__arr__char__arr__char__lambda1___closure* _closure, arr__char child) {
	some__arr__char s;
	opt__arr__char matched;
	return (matched = get_extension__opt__arr__char__arr__char(_ctx, base_name__arr__char__arr__char(_ctx, child)),
		matched.kind == 0
		? 0
		: matched.kind == 1
		? (s = matched.as_some__arr__char,
		(_op_equal_equal__bool__arr__char__arr__char(s.value, (arr__char){2, "nz"}) ? push___void__ptr_mut_arr__arr__char__arr__char(_ctx, _closure->res, child) : 0)
		): _fail_void());
}
arr__ptr_failure arr_or__arr__ptr_failure__arr__ptr_failure__fun_mut0__arr__ptr_failure(ctx* _ctx, arr__ptr_failure a, fun_mut0__arr__ptr_failure b) {
	return (has__q__bool__arr__ptr_failure(a) ? a : call__arr__ptr_failure__fun_mut0__arr__ptr_failure(_ctx, b));
}
arr__ptr_failure call__arr__ptr_failure__fun_mut0__arr__ptr_failure(ctx* _ctx, fun_mut0__arr__ptr_failure f) {
	return call_with_ctx__arr__ptr_failure__ptr_ctx__fun_mut0__arr__ptr_failure(_ctx, f);
}
arr__ptr_failure call_with_ctx__arr__ptr_failure__ptr_ctx__fun_mut0__arr__ptr_failure(ctx* c, fun_mut0__arr__ptr_failure f) {
	return f.fun_ptr(c, f.closure);
}
arr__ptr_failure run_single_ast_or_model_test__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__arr__char__bool(ctx* _ctx, arr__char ast_or_model, arr__char path_to_noze, dict__arr__char__arr__char* env, arr__char path, bool overwrite_output__q) {
	arr__arr__char arr;
	process_result* res;
	arr__char message;
	arr__ptr_failure arr1;
	return ((res = spawn_and_wait_result__ptr_process_result__arr__char__arr__arr__char__ptr_dict__arr__char__arr__char(_ctx, path_to_noze, (arr = (arr__arr__char) { 3, (arr__char*) alloc__ptr__byte__nat(_ctx, 48) }, arr.data[0] =(arr__char){5, "print"}, arr.data[1] =ast_or_model, arr.data[2] =path, arr), env)),
	(_op_equal_equal__bool__int32__int32(res->exit_code, literal__int32__arr__char(_ctx, (arr__char){1, "0"})) && _op_equal_equal__bool__arr__char__arr__char(res->stderr, (arr__char){0, ""}))
		? handle_output__arr__ptr_failure__arr__char__arr__char__arr__char__bool(_ctx, path, _op_plus__arr__char__arr__char__arr__char(_ctx, _op_plus__arr__char__arr__char__arr__char(_ctx, _op_plus__arr__char__arr__char__arr__char(_ctx, path, (arr__char){1, "."}), ast_or_model), (arr__char){5, ".tata"}), res->stdout, overwrite_output__q)
		: ((message = _op_plus__arr__char__arr__char__arr__char(_ctx, _op_plus__arr__char__arr__char__arr__char(_ctx, _op_plus__arr__char__arr__char__arr__char(_ctx, _op_plus__arr__char__arr__char__arr__char(_ctx, _op_plus__arr__char__arr__char__arr__char(_ctx, (arr__char){8, "status: "}, to_str__arr__char__int32(_ctx, res->exit_code)), (arr__char){9, "\nstdout:\n"}), res->stdout), (arr__char){8, "stderr:\n"}), res->stderr)),
		(arr1 = (arr__ptr_failure) { 1, (failure**) alloc__ptr__byte__nat(_ctx, 8) }, arr1.data[0] =_initfailure(alloc__ptr__byte__nat(_ctx, 32), (failure) {path, message}), arr1)));
}
arr__ptr_failure run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0__lambda0__lambda0(ctx* _ctx, run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0__lambda0__lambda0___closure* _closure) {
	return run_single_ast_or_model_test__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__arr__char__bool(_ctx, (arr__char){14, "concrete-model"}, _closure->path_to_noze, _closure->env, _closure->test, _closure->options.overwrite_output__q);
}
arr__ptr_failure run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0__lambda0(ctx* _ctx, run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0__lambda0___closure* _closure) {
	return arr_or__arr__ptr_failure__arr__ptr_failure__fun_mut0__arr__ptr_failure(_ctx, run_single_ast_or_model_test__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__arr__char__bool(_ctx, (arr__char){5, "model"}, _closure->path_to_noze, _closure->env, _closure->test, _closure->options.overwrite_output__q), (fun_mut0__arr__ptr_failure) {
		(fun_ptr2__arr__ptr_failure__ptr_ctx__ptr__byte) run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0__lambda0__lambda0,
		(ptr__byte) _initrun_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0__lambda0__lambda0___closure(alloc__ptr__byte__nat(_ctx, 56), (run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0__lambda0__lambda0___closure) {_closure->path_to_noze, _closure->env, _closure->test, _closure->options})
	});
}
arr__ptr_failure run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0(ctx* _ctx, run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0___closure* _closure, arr__char test) {
	return ((_closure->options.print_tests__q ? print_sync___void__arr__char(_op_plus__arr__char__arr__char__arr__char(_ctx, (arr__char){9, "noze ast "}, test)) : 0),
	arr_or__arr__ptr_failure__arr__ptr_failure__fun_mut0__arr__ptr_failure(_ctx, run_single_ast_or_model_test__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__arr__char__bool(_ctx, (arr__char){3, "ast"}, _closure->path_to_noze, _closure->env, test, _closure->options.overwrite_output__q), (fun_mut0__arr__ptr_failure) {
		(fun_ptr2__arr__ptr_failure__ptr_ctx__ptr__byte) run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0__lambda0,
		(ptr__byte) _initrun_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0__lambda0___closure(alloc__ptr__byte__nat(_ctx, 56), (run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0__lambda0___closure) {_closure->path_to_noze, _closure->env, test, _closure->options})
	}));
}
result__arr__char__arr__ptr_failure run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options(ctx* _ctx, arr__char path, arr__char path_to_noze, dict__arr__char__arr__char* env, test_options options) {
	arr__arr__char tests;
	arr__ptr_failure failures;
	return ((tests = list_runnable_tests__arr__arr__char__arr__char(_ctx, path)),
	((failures = flat_map_with_max_size__arr__ptr_failure__arr__arr__char__nat__fun_mut1__arr__ptr_failure__arr__char(_ctx, tests, options.max_failures, (fun_mut1__arr__ptr_failure__arr__char) {
		(fun_ptr3__arr__ptr_failure__ptr_ctx__ptr__byte__arr__char) run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0,
		(ptr__byte) _initrun_runnable_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0___closure(alloc__ptr__byte__nat(_ctx, 40), (run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0___closure) {options, path_to_noze, env})
	})),
	has__q__bool__arr__ptr_failure(failures)
		? (result__arr__char__arr__ptr_failure) { 1, .as_err__arr__ptr_failure = err__err__arr__ptr_failure__arr__ptr_failure(failures) }
		: (result__arr__char__arr__ptr_failure) { 0, .as_ok__arr__char = ok__ok__arr__char__arr__char(_op_plus__arr__char__arr__char__arr__char(_ctx, _op_plus__arr__char__arr__char__arr__char(_ctx, (arr__char){4, "ran "}, to_str__arr__char__nat(_ctx, tests.size)), (arr__char){15, " runnable tests"})) }));
}
arr__arr__char list_runnable_tests__arr__arr__char__arr__char(ctx* _ctx, arr__char path) {
	mut_arr__arr__char* res;
	fun_mut1__bool__arr__char filter;
	return ((res = new_mut_arr__ptr_mut_arr__arr__char(_ctx)),
	((filter = (fun_mut1__bool__arr__char) {
		(fun_ptr3__bool__ptr_ctx__ptr__byte__arr__char) list_runnable_tests__arr__arr__char__arr__char__lambda0,
		(ptr__byte) NULL
	}),
	(each_child_recursive___void__arr__char__fun_mut1__bool__arr__char__fun_mut1___void__arr__char(_ctx, path, filter, (fun_mut1___void__arr__char) {
		(fun_ptr3___void__ptr_ctx__ptr__byte__arr__char) list_runnable_tests__arr__arr__char__arr__char__lambda1,
		(ptr__byte) _initlist_runnable_tests__arr__arr__char__arr__char__lambda1___closure(alloc__ptr__byte__nat(_ctx, 8), (list_runnable_tests__arr__arr__char__arr__char__lambda1___closure) {res})
	}),
	freeze__arr__arr__char__ptr_mut_arr__arr__char(res))));
}
bool list_runnable_tests__arr__arr__char__arr__char__lambda0(ctx* _ctx, ptr__byte _closure, arr__char s) {
	return 1;
}
_void list_runnable_tests__arr__arr__char__arr__char__lambda1(ctx* _ctx, list_runnable_tests__arr__arr__char__arr__char__lambda1___closure* _closure, arr__char child) {
	some__arr__char s;
	opt__arr__char matched;
	return (matched = get_extension__opt__arr__char__arr__char(_ctx, base_name__arr__char__arr__char(_ctx, child)),
		matched.kind == 0
		? 0
		: matched.kind == 1
		? (s = matched.as_some__arr__char,
		(_op_equal_equal__bool__arr__char__arr__char(s.value, (arr__char){2, "nz"}) ? push___void__ptr_mut_arr__arr__char__arr__char(_ctx, _closure->res, child) : 0)
		): _fail_void());
}
arr__ptr_failure run_single_runnable_test__arr__ptr_failure__arr__char__ptr_dict__arr__char__arr__char__arr__char__bool(ctx* _ctx, arr__char path_to_noze, dict__arr__char__arr__char* env, arr__char path, bool overwrite_output__q) {
	arr__arr__char arr;
	process_result* res;
	arr__char message;
	arr__ptr_failure arr1;
	return ((res = spawn_and_wait_result__ptr_process_result__arr__char__arr__arr__char__ptr_dict__arr__char__arr__char(_ctx, path_to_noze, (arr = (arr__arr__char) { 2, (arr__char*) alloc__ptr__byte__nat(_ctx, 32) }, arr.data[0] =(arr__char){3, "run"}, arr.data[1] =path, arr), env)),
	(_op_equal_equal__bool__int32__int32(res->exit_code, literal__int32__arr__char(_ctx, (arr__char){1, "0"})) && _op_equal_equal__bool__arr__char__arr__char(res->stderr, (arr__char){0, ""}))
		? handle_output__arr__ptr_failure__arr__char__arr__char__arr__char__bool(_ctx, path, _op_plus__arr__char__arr__char__arr__char(_ctx, path, (arr__char){7, ".stdout"}), res->stdout, overwrite_output__q)
		: ((message = _op_plus__arr__char__arr__char__arr__char(_ctx, _op_plus__arr__char__arr__char__arr__char(_ctx, _op_plus__arr__char__arr__char__arr__char(_ctx, _op_plus__arr__char__arr__char__arr__char(_ctx, _op_plus__arr__char__arr__char__arr__char(_ctx, (arr__char){8, "status: "}, to_str__arr__char__int32(_ctx, res->exit_code)), (arr__char){9, "\nstdout:\n"}), res->stdout), (arr__char){8, "stderr:\n"}), res->stderr)),
		(arr1 = (arr__ptr_failure) { 1, (failure**) alloc__ptr__byte__nat(_ctx, 8) }, arr1.data[0] =_initfailure(alloc__ptr__byte__nat(_ctx, 32), (failure) {path, message}), arr1)));
}
arr__ptr_failure run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0(ctx* _ctx, run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0___closure* _closure, arr__char test) {
	return ((_closure->options.print_tests__q ? print_sync___void__arr__char(_op_plus__arr__char__arr__char__arr__char(_ctx, (arr__char){9, "noze run "}, test)) : 0),
	run_single_runnable_test__arr__ptr_failure__arr__char__ptr_dict__arr__char__arr__char__arr__char__bool(_ctx, _closure->path_to_noze, _closure->env, test, _closure->options.overwrite_output__q));
}
result__arr__char__arr__ptr_failure do_test__int32__test_options__lambda0__lambda0(ctx* _ctx, do_test__int32__test_options__lambda0__lambda0___closure* _closure) {
	return run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options(_ctx, child_path__arr__char__arr__char__arr__char(_ctx, _closure->test_path, (arr__char){8, "runnable"}), _closure->noze_exe, _closure->env, _closure->options);
}
result__arr__char__arr__ptr_failure do_test__int32__test_options__lambda0(ctx* _ctx, do_test__int32__test_options__lambda0___closure* _closure) {
	return first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure(_ctx, run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options(_ctx, child_path__arr__char__arr__char__arr__char(_ctx, _closure->test_path, (arr__char){8, "runnable"}), _closure->noze_exe, _closure->env, _closure->options), (fun0__result__arr__char__arr__ptr_failure) {
		(fun_ptr2__result__arr__char__arr__ptr_failure__ptr_ctx__ptr__byte) do_test__int32__test_options__lambda0__lambda0,
		(ptr__byte) _initdo_test__int32__test_options__lambda0__lambda0___closure(alloc__ptr__byte__nat(_ctx, 56), (do_test__int32__test_options__lambda0__lambda0___closure) {_closure->test_path, _closure->noze_exe, _closure->env, _closure->options})
	});
}
result__arr__char__arr__ptr_failure lint__result__arr__char__arr__ptr_failure__arr__char__test_options(ctx* _ctx, arr__char path, test_options options) {
	arr__arr__char files;
	arr__ptr_failure failures;
	return ((files = list_lintable_files__arr__arr__char__arr__char(_ctx, path)),
	((failures = flat_map_with_max_size__arr__ptr_failure__arr__arr__char__nat__fun_mut1__arr__ptr_failure__arr__char(_ctx, files, options.max_failures, (fun_mut1__arr__ptr_failure__arr__char) {
		(fun_ptr3__arr__ptr_failure__ptr_ctx__ptr__byte__arr__char) lint__result__arr__char__arr__ptr_failure__arr__char__test_options__lambda0,
		(ptr__byte) _initlint__result__arr__char__arr__ptr_failure__arr__char__test_options__lambda0___closure(alloc__ptr__byte__nat(_ctx, 16), (lint__result__arr__char__arr__ptr_failure__arr__char__test_options__lambda0___closure) {options})
	})),
	has__q__bool__arr__ptr_failure(failures)
		? (result__arr__char__arr__ptr_failure) { 1, .as_err__arr__ptr_failure = err__err__arr__ptr_failure__arr__ptr_failure(failures) }
		: (result__arr__char__arr__ptr_failure) { 0, .as_ok__arr__char = ok__ok__arr__char__arr__char(_op_plus__arr__char__arr__char__arr__char(_ctx, _op_plus__arr__char__arr__char__arr__char(_ctx, (arr__char){7, "Linted "}, to_str__arr__char__nat(_ctx, files.size)), (arr__char){6, " files"})) }));
}
arr__arr__char list_lintable_files__arr__arr__char__arr__char(ctx* _ctx, arr__char path) {
	mut_arr__arr__char* res;
	return ((res = new_mut_arr__ptr_mut_arr__arr__char(_ctx)),
	(each_child_recursive___void__arr__char__fun_mut1__bool__arr__char__fun_mut1___void__arr__char(_ctx, path, (fun_mut1__bool__arr__char) {
		(fun_ptr3__bool__ptr_ctx__ptr__byte__arr__char) list_lintable_files__arr__arr__char__arr__char__lambda0,
		(ptr__byte) NULL
	}, (fun_mut1___void__arr__char) {
		(fun_ptr3___void__ptr_ctx__ptr__byte__arr__char) list_lintable_files__arr__arr__char__arr__char__lambda1,
		(ptr__byte) _initlist_lintable_files__arr__arr__char__arr__char__lambda1___closure(alloc__ptr__byte__nat(_ctx, 8), (list_lintable_files__arr__arr__char__arr__char__lambda1___closure) {res})
	}),
	freeze__arr__arr__char__ptr_mut_arr__arr__char(res)));
}
bool list_lintable_files__arr__arr__char__arr__char__lambda0(ctx* _ctx, ptr__byte _closure, arr__char it) {
	return !((_op_equal_equal__bool__char__char(first__char__arr__char(_ctx, it), literal__char__arr__char((arr__char){1, "."})) || _op_equal_equal__bool__arr__char__arr__char(it, (arr__char){7, "libfirm"})));
}
bool ignore_extension_of_name__bool__arr__char(ctx* _ctx, arr__char name) {
	some__arr__char s;
	opt__arr__char matched;
	return (matched = get_extension__opt__arr__char__arr__char(_ctx, name),
		matched.kind == 0
		? 1
		: matched.kind == 1
		? (s = matched.as_some__arr__char,
		ignore_extension__bool__arr__char(_ctx, s.value)
		): _failbool());
}
bool ignore_extension__bool__arr__char(ctx* _ctx, arr__char ext) {
	return contains__q__bool__arr__arr__char__arr__char(ignored_extensions__arr__arr__char(_ctx), ext);
}
bool contains__q__bool__arr__arr__char__arr__char(arr__arr__char a, arr__char value) {
	return contains_recur__q__bool__arr__arr__char__arr__char__nat(a, value, 0);
}
bool contains_recur__q__bool__arr__arr__char__arr__char__nat(arr__arr__char a, arr__char value, nat i) {
	return _op_equal_equal__bool__nat__nat(i, a.size)
		? 0
		: (_op_equal_equal__bool__arr__char__arr__char(noctx_at__arr__char__arr__arr__char__nat(a, i), value) || contains_recur__q__bool__arr__arr__char__arr__char__nat(a, value, noctx_incr__nat__nat(i)));
}
arr__arr__char ignored_extensions__arr__arr__char(ctx* _ctx) {
	arr__arr__char arr;
	return (arr = (arr__arr__char) { 6, (arr__char*) alloc__ptr__byte__nat(_ctx, 96) }, arr.data[0] =(arr__char){1, "c"}, arr.data[1] =(arr__char){4, "data"}, arr.data[2] =(arr__char){1, "o"}, arr.data[3] =(arr__char){3, "out"}, arr.data[4] =(arr__char){4, "tata"}, arr.data[5] =(arr__char){10, "tmLanguage"}, arr);
}
_void list_lintable_files__arr__arr__char__arr__char__lambda1(ctx* _ctx, list_lintable_files__arr__arr__char__arr__char__lambda1___closure* _closure, arr__char child) {
	return ignore_extension_of_name__bool__arr__char(_ctx, base_name__arr__char__arr__char(_ctx, child))
		? 0
		: push___void__ptr_mut_arr__arr__char__arr__char(_ctx, _closure->res, child);
}
arr__ptr_failure lint_file__arr__ptr_failure__arr__char(ctx* _ctx, arr__char path) {
	arr__char text;
	mut_arr__ptr_failure* res;
	bool err_file__q;
	return ((text = read_file__arr__char__arr__char(_ctx, path)),
	((res = new_mut_arr__ptr_mut_arr__ptr_failure(_ctx)),
	((err_file__q = _op_equal_equal__bool__arr__char__arr__char(force__arr__char__opt__arr__char(_ctx, get_extension__opt__arr__char__arr__char(_ctx, path)), (arr__char){3, "err"})),
	(each_with_index___void__arr__arr__char__fun_mut2___void__arr__char__nat(_ctx, lines__arr__arr__char__arr__char(_ctx, text), (fun_mut2___void__arr__char__nat) {
		(fun_ptr4___void__ptr_ctx__ptr__byte__arr__char__nat) lint_file__arr__ptr_failure__arr__char__lambda0,
		(ptr__byte) _initlint_file__arr__ptr_failure__arr__char__lambda0___closure(alloc__ptr__byte__nat(_ctx, 32), (lint_file__arr__ptr_failure__arr__char__lambda0___closure) {err_file__q, res, path})
	}),
	freeze__arr__ptr_failure__ptr_mut_arr__ptr_failure(res)))));
}
arr__char read_file__arr__char__arr__char(ctx* _ctx, arr__char path) {
	some__arr__char s;
	opt__arr__char matched;
	return (matched = try_read_file__opt__arr__char__arr__char(_ctx, path),
		matched.kind == 0
		? (print_sync___void__arr__char(_op_plus__arr__char__arr__char__arr__char(_ctx, (arr__char){21, "file does not exist: "}, path)),
		(arr__char){0, ""})
		: matched.kind == 1
		? (s = matched.as_some__arr__char,
		s.value
		): _failarr__char());
}
_void each_with_index___void__arr__arr__char__fun_mut2___void__arr__char__nat(ctx* _ctx, arr__arr__char a, fun_mut2___void__arr__char__nat f) {
	return each_with_index_recur___void__arr__arr__char__fun_mut2___void__arr__char__nat__nat(_ctx, a, f, 0);
}
_void each_with_index_recur___void__arr__arr__char__fun_mut2___void__arr__char__nat__nat(ctx* _ctx, arr__arr__char a, fun_mut2___void__arr__char__nat f, nat n) {
	return _op_equal_equal__bool__nat__nat(n, a.size)
		? 0
		: (call___void__fun_mut2___void__arr__char__nat__arr__char__nat(_ctx, f, at__arr__char__arr__arr__char__nat(_ctx, a, n), n),
		each_with_index_recur___void__arr__arr__char__fun_mut2___void__arr__char__nat__nat(_ctx, a, f, incr__nat__nat(_ctx, n)));
}
_void call___void__fun_mut2___void__arr__char__nat__arr__char__nat(ctx* _ctx, fun_mut2___void__arr__char__nat f, arr__char p0, nat p1) {
	return call_with_ctx___void__ptr_ctx__fun_mut2___void__arr__char__nat__arr__char__nat(_ctx, f, p0, p1);
}
_void call_with_ctx___void__ptr_ctx__fun_mut2___void__arr__char__nat__arr__char__nat(ctx* c, fun_mut2___void__arr__char__nat f, arr__char p0, nat p1) {
	return f.fun_ptr(c, f.closure, p0, p1);
}
arr__arr__char lines__arr__arr__char__arr__char(ctx* _ctx, arr__char s) {
	mut_arr__arr__char* res;
	cell__nat* last_nl;
	return ((res = new_mut_arr__ptr_mut_arr__arr__char(_ctx)),
	((last_nl = new_cell__ptr_cell__nat__nat(_ctx, 0)),
	((each_with_index___void__arr__char__fun_mut2___void__char__nat(_ctx, s, (fun_mut2___void__char__nat) {
		(fun_ptr4___void__ptr_ctx__ptr__byte__char__nat) lines__arr__arr__char__arr__char__lambda0,
		(ptr__byte) _initlines__arr__arr__char__arr__char__lambda0___closure(alloc__ptr__byte__nat(_ctx, 32), (lines__arr__arr__char__arr__char__lambda0___closure) {res, s, last_nl})
	}),
	push___void__ptr_mut_arr__arr__char__arr__char(_ctx, res, slice_from_to__arr__char__arr__char__nat__nat(_ctx, s, get__nat__ptr_cell__nat(last_nl), s.size))),
	freeze__arr__arr__char__ptr_mut_arr__arr__char(res))));
}
cell__nat* new_cell__ptr_cell__nat__nat(ctx* _ctx, nat value) {
	return _initcell__nat(alloc__ptr__byte__nat(_ctx, 8), (cell__nat) {value});
}
_void each_with_index___void__arr__char__fun_mut2___void__char__nat(ctx* _ctx, arr__char a, fun_mut2___void__char__nat f) {
	return each_with_index_recur___void__arr__char__fun_mut2___void__char__nat__nat(_ctx, a, f, 0);
}
_void each_with_index_recur___void__arr__char__fun_mut2___void__char__nat__nat(ctx* _ctx, arr__char a, fun_mut2___void__char__nat f, nat n) {
	return _op_equal_equal__bool__nat__nat(n, a.size)
		? 0
		: (call___void__fun_mut2___void__char__nat__char__nat(_ctx, f, at__char__arr__char__nat(_ctx, a, n), n),
		each_with_index_recur___void__arr__char__fun_mut2___void__char__nat__nat(_ctx, a, f, incr__nat__nat(_ctx, n)));
}
_void call___void__fun_mut2___void__char__nat__char__nat(ctx* _ctx, fun_mut2___void__char__nat f, char p0, nat p1) {
	return call_with_ctx___void__ptr_ctx__fun_mut2___void__char__nat__char__nat(_ctx, f, p0, p1);
}
_void call_with_ctx___void__ptr_ctx__fun_mut2___void__char__nat__char__nat(ctx* c, fun_mut2___void__char__nat f, char p0, nat p1) {
	return f.fun_ptr(c, f.closure, p0, p1);
}
arr__char slice_from_to__arr__char__arr__char__nat__nat(ctx* _ctx, arr__char a, nat begin, nat end) {
	return (assert___void__bool(_ctx, _op_less_equal__bool__nat__nat(begin, end)),
	slice__arr__char__arr__char__nat__nat(_ctx, a, begin, _op_minus__nat__nat__nat(_ctx, end, begin)));
}
nat swap__nat__ptr_cell__nat__nat(cell__nat* c, nat v) {
	nat res;
	return ((res = get__nat__ptr_cell__nat(c)),
	(set___void__ptr_cell__nat__nat(c, v),
	res));
}
nat get__nat__ptr_cell__nat(cell__nat* c) {
	return c->value;
}
_void set___void__ptr_cell__nat__nat(cell__nat* c, nat v) {
	return (c->value = v), 0;
}
_void lines__arr__arr__char__arr__char__lambda0(ctx* _ctx, lines__arr__arr__char__arr__char__lambda0___closure* _closure, char c, nat index) {
	return _op_equal_equal__bool__char__char(c, literal__char__arr__char((arr__char){1, "\n"}))
		? push___void__ptr_mut_arr__arr__char__arr__char(_ctx, _closure->res, slice_from_to__arr__char__arr__char__nat__nat(_ctx, _closure->s, swap__nat__ptr_cell__nat__nat(_closure->last_nl, incr__nat__nat(_ctx, index)), index))
		: 0;
}
bool contains_subsequence__q__bool__arr__char__arr__char(ctx* _ctx, arr__char a, arr__char subseq) {
	return (starts_with__q__bool__arr__char__arr__char(_ctx, a, subseq) || (has__q__bool__arr__char(a) && starts_with__q__bool__arr__char__arr__char(_ctx, tail__arr__char__arr__char(_ctx, a), subseq)));
}
bool has__q__bool__arr__char(arr__char a) {
	return !(empty__q__bool__arr__char(a));
}
arr__char lstrip__arr__char__arr__char(ctx* _ctx, arr__char a) {
	return (has__q__bool__arr__char(a) && _op_equal_equal__bool__char__char(first__char__arr__char(_ctx, a), literal__char__arr__char((arr__char){1, " "})))
		? lstrip__arr__char__arr__char(_ctx, tail__arr__char__arr__char(_ctx, a))
		: a;
}
nat line_len__nat__arr__char(ctx* _ctx, arr__char line) {
	return _op_plus__nat__nat__nat(_ctx, _op_times__nat__nat__nat(_ctx, n_tabs__nat__arr__char(_ctx, line), _op_minus__nat__nat__nat(_ctx, tab_size__nat(_ctx), literal__nat__arr__char(_ctx, (arr__char){1, "1"}))), line.size);
}
nat n_tabs__nat__arr__char(ctx* _ctx, arr__char line) {
	return (!(empty__q__bool__arr__char(line)) && _op_equal_equal__bool__char__char(first__char__arr__char(_ctx, line), literal__char__arr__char((arr__char){1, "\t"})))
		? incr__nat__nat(_ctx, n_tabs__nat__arr__char(_ctx, tail__arr__char__arr__char(_ctx, line)))
		: 0;
}
nat tab_size__nat(ctx* _ctx) {
	return literal__nat__arr__char(_ctx, (arr__char){1, "4"});
}
nat max_line_length__nat(ctx* _ctx) {
	return literal__nat__arr__char(_ctx, (arr__char){3, "120"});
}
_void lint_file__arr__ptr_failure__arr__char__lambda0(ctx* _ctx, lint_file__arr__ptr_failure__arr__char__lambda0___closure* _closure, arr__char line, nat line_num) {
	arr__char ln;
	arr__char message;
	nat width;
	arr__char message1;
	return ((ln = to_str__arr__char__nat(_ctx, incr__nat__nat(_ctx, line_num))),
	((!(_closure->err_file__q) && contains_subsequence__q__bool__arr__char__arr__char(_ctx, lstrip__arr__char__arr__char(_ctx, line), (arr__char){2, "  "}))
		? ((message = _op_plus__arr__char__arr__char__arr__char(_ctx, _op_plus__arr__char__arr__char__arr__char(_ctx, (arr__char){5, "line "}, ln), (arr__char){24, " contains a double space"})),
		push___void__ptr_mut_arr__ptr_failure__ptr_failure(_ctx, _closure->res, _initfailure(alloc__ptr__byte__nat(_ctx, 32), (failure) {_closure->path, message})))
		: 0,
	((width = line_len__nat__arr__char(_ctx, line)),
	_op_greater__bool__nat__nat(width, max_line_length__nat(_ctx))
		? ((message1 = _op_plus__arr__char__arr__char__arr__char(_ctx, _op_plus__arr__char__arr__char__arr__char(_ctx, _op_plus__arr__char__arr__char__arr__char(_ctx, _op_plus__arr__char__arr__char__arr__char(_ctx, _op_plus__arr__char__arr__char__arr__char(_ctx, (arr__char){5, "line "}, ln), (arr__char){4, " is "}), to_str__arr__char__nat(_ctx, width)), (arr__char){28, " columns long, should be <= "}), to_str__arr__char__nat(_ctx, max_line_length__nat(_ctx)))),
		push___void__ptr_mut_arr__ptr_failure__ptr_failure(_ctx, _closure->res, _initfailure(alloc__ptr__byte__nat(_ctx, 32), (failure) {_closure->path, message1})))
		: 0)));
}
arr__ptr_failure lint__result__arr__char__arr__ptr_failure__arr__char__test_options__lambda0(ctx* _ctx, lint__result__arr__char__arr__ptr_failure__arr__char__test_options__lambda0___closure* _closure, arr__char file) {
	return (_closure->options.print_tests__q
		? print_sync___void__arr__char(_op_plus__arr__char__arr__char__arr__char(_ctx, (arr__char){5, "lint "}, file))
		: 0,
	lint_file__arr__ptr_failure__arr__char(_ctx, file));
}
result__arr__char__arr__ptr_failure do_test__int32__test_options__lambda1(ctx* _ctx, do_test__int32__test_options__lambda1___closure* _closure) {
	return lint__result__arr__char__arr__ptr_failure__arr__char__test_options(_ctx, _closure->noze_path, _closure->options);
}
int32 print_failures__int32__result__arr__char__arr__ptr_failure__test_options(ctx* _ctx, result__arr__char__arr__ptr_failure failures, test_options options) {
	ok__arr__char o;
	err__arr__ptr_failure e;
	nat n_failures;
	result__arr__char__arr__ptr_failure matched;
	return (matched = failures,
		matched.kind == 0
		? (o = matched.as_ok__arr__char,
		(print_sync___void__arr__char(o.value),
		literal__int32__arr__char(_ctx, (arr__char){1, "0"}))
		): matched.kind == 1
		? (e = matched.as_err__arr__ptr_failure,
		(each___void__arr__ptr_failure__fun_mut1___void__ptr_failure(_ctx, e.value, (fun_mut1___void__ptr_failure) {
			(fun_ptr3___void__ptr_ctx__ptr__byte__ptr_failure) print_failures__int32__result__arr__char__arr__ptr_failure__test_options__lambda0,
			(ptr__byte) NULL
		}),
		((n_failures = e.value.size),
		(print_sync___void__arr__char(_op_equal_equal__bool__nat__nat(n_failures, options.max_failures)
			? _op_plus__arr__char__arr__char__arr__char(_ctx, _op_plus__arr__char__arr__char__arr__char(_ctx, (arr__char){15, "hit maximum of "}, to_str__arr__char__nat(_ctx, options.max_failures)), (arr__char){9, " failures"})
			: _op_plus__arr__char__arr__char__arr__char(_ctx, to_str__arr__char__nat(_ctx, n_failures), (arr__char){9, " failures"})),
		to_int32__int32__nat(_ctx, n_failures))))
		): _failint32());
}
_void print_failure___void__ptr_failure(ctx* _ctx, failure* failure) {
	return ((((print_bold___void(_ctx),
	print_sync_no_newline___void__arr__char(failure->path)),
	print_reset___void(_ctx)),
	print_sync_no_newline___void__arr__char((arr__char){1, " "})),
	print_sync___void__arr__char(failure->message));
}
_void print_bold___void(ctx* _ctx) {
	return print_sync_no_newline___void__arr__char((arr__char){4, "\x1b[1m"});
}
_void print_reset___void(ctx* _ctx) {
	return print_sync_no_newline___void__arr__char((arr__char){3, "\x1b[m"});
}
_void print_failures__int32__result__arr__char__arr__ptr_failure__test_options__lambda0(ctx* _ctx, ptr__byte _closure, failure* it) {
	return print_failure___void__ptr_failure(_ctx, it);
}
int32 to_int32__int32__nat(ctx* _ctx, nat n) {
	return (assert___void__bool(_ctx, _op_less__bool__nat__nat(n, million__nat())),
	(int32) (_int) n);
}


int main(int argc, char** argv) {
	assert(sizeof(ctx) == 40);
	assert(sizeof(byte) == 1);
	assert(sizeof(ptr__byte) == 8);
	assert(sizeof(nat) == 8);
	assert(sizeof(int32) == 4);
	assert(sizeof(char) == 1);
	assert(sizeof(ptr__char) == 8);
	assert(sizeof(ptr__ptr__char) == 8);
	assert(sizeof(fut__int32) == 32);
	assert(sizeof(lock) == 1);
	assert(sizeof(_atomic_bool) == 1);
	assert(sizeof(bool) == 1);
	assert(sizeof(fut_state__int32) == 24);
	assert(sizeof(fut_state_callbacks__int32) == 16);
	assert(sizeof(fut_callback_node__int32) == 32);
	assert(sizeof(_void) == 1);
	assert(sizeof(exception) == 16);
	assert(sizeof(arr__char) == 16);
	assert(sizeof(result__int32__exception) == 24);
	assert(sizeof(ok__int32) == 4);
	assert(sizeof(err__exception) == 16);
	assert(sizeof(fun_mut1___void__result__int32__exception) == 16);
	assert(sizeof(fun_ptr3___void__ptr_ctx__ptr__byte__result__int32__exception) == 8);
	assert(sizeof(opt__ptr_fut_callback_node__int32) == 16);
	assert(sizeof(none) == 1);
	assert(sizeof(some__ptr_fut_callback_node__int32) == 8);
	assert(sizeof(fut_state_resolved__int32) == 4);
	assert(sizeof(arr__arr__char) == 16);
	assert(sizeof(ptr__arr__char) == 8);
	assert(sizeof(fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char) == 8);
	assert(sizeof(global_ctx) == 56);
	assert(sizeof(vat) == 160);
	assert(sizeof(gc) == 48);
	assert(sizeof(gc_ctx) == 24);
	assert(sizeof(opt__ptr_gc_ctx) == 16);
	assert(sizeof(some__ptr_gc_ctx) == 8);
	assert(sizeof(task) == 24);
	assert(sizeof(fun_mut0___void) == 16);
	assert(sizeof(fun_ptr2___void__ptr_ctx__ptr__byte) == 8);
	assert(sizeof(mut_bag__task) == 16);
	assert(sizeof(mut_bag_node__task) == 40);
	assert(sizeof(opt__ptr_mut_bag_node__task) == 16);
	assert(sizeof(some__ptr_mut_bag_node__task) == 8);
	assert(sizeof(mut_arr__nat) == 32);
	assert(sizeof(ptr__nat) == 8);
	assert(sizeof(thread_safe_counter) == 16);
	assert(sizeof(fun_mut1___void__exception) == 16);
	assert(sizeof(fun_ptr3___void__ptr_ctx__ptr__byte__exception) == 8);
	assert(sizeof(arr__ptr_vat) == 16);
	assert(sizeof(ptr__ptr_vat) == 8);
	assert(sizeof(condition) == 16);
	assert(sizeof(comparison) == 8);
	assert(sizeof(less) == 1);
	assert(sizeof(equal) == 1);
	assert(sizeof(greater) == 1);
	assert(sizeof(ptr__bool) == 8);
	assert(sizeof(_int) == 8);
	assert(sizeof(exception_ctx) == 24);
	assert(sizeof(jmp_buf_tag) == 200);
	assert(sizeof(bytes64) == 64);
	assert(sizeof(bytes32) == 32);
	assert(sizeof(bytes16) == 16);
	assert(sizeof(bytes128) == 128);
	assert(sizeof(ptr__jmp_buf_tag) == 8);
	assert(sizeof(thread_local_stuff) == 8);
	assert(sizeof(arr__ptr__char) == 16);
	assert(sizeof(fun2__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char) == 16);
	assert(sizeof(fun_ptr4__ptr_fut__int32__ptr_ctx__ptr__byte__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char) == 8);
	assert(sizeof(fut___void) == 32);
	assert(sizeof(fut_state___void) == 24);
	assert(sizeof(fut_state_callbacks___void) == 16);
	assert(sizeof(fut_callback_node___void) == 32);
	assert(sizeof(result___void__exception) == 24);
	assert(sizeof(ok___void) == 1);
	assert(sizeof(fun_mut1___void__result___void__exception) == 16);
	assert(sizeof(fun_ptr3___void__ptr_ctx__ptr__byte__result___void__exception) == 8);
	assert(sizeof(opt__ptr_fut_callback_node___void) == 16);
	assert(sizeof(some__ptr_fut_callback_node___void) == 8);
	assert(sizeof(fut_state_resolved___void) == 1);
	assert(sizeof(fun_ref0__int32) == 32);
	assert(sizeof(vat_and_actor_id) == 16);
	assert(sizeof(fun_mut0__ptr_fut__int32) == 16);
	assert(sizeof(fun_ptr2__ptr_fut__int32__ptr_ctx__ptr__byte) == 8);
	assert(sizeof(fun_ref1__int32___void) == 32);
	assert(sizeof(fun_mut1__ptr_fut__int32___void) == 16);
	assert(sizeof(fun_ptr3__ptr_fut__int32__ptr_ctx__ptr__byte___void) == 8);
	assert(sizeof(opt__ptr__byte) == 16);
	assert(sizeof(some__ptr__byte) == 8);
	assert(sizeof(then__ptr_fut__int32__ptr_fut___void__fun_ref1__int32___void__lambda0___closure) == 40);
	assert(sizeof(forward_to___void__ptr_fut__int32__ptr_fut__int32__lambda0___closure) == 8);
	assert(sizeof(call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0___closure) == 48);
	assert(sizeof(call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0__lambda0___closure) == 48);
	assert(sizeof(call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0__lambda1___closure) == 8);
	assert(sizeof(then2__ptr_fut__int32__ptr_fut___void__fun_ref0__int32__lambda0___closure) == 32);
	assert(sizeof(call__ptr_fut__int32__fun_ref0__int32__lambda0___closure) == 40);
	assert(sizeof(call__ptr_fut__int32__fun_ref0__int32__lambda0__lambda0___closure) == 40);
	assert(sizeof(call__ptr_fut__int32__fun_ref0__int32__lambda0__lambda1___closure) == 8);
	assert(sizeof(add_first_task__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__lambda0___closure) == 24);
	assert(sizeof(fun_mut1__arr__char__ptr__char) == 16);
	assert(sizeof(fun_ptr3__arr__char__ptr_ctx__ptr__byte__ptr__char) == 8);
	assert(sizeof(fun_mut1__arr__char__nat) == 16);
	assert(sizeof(fun_ptr3__arr__char__ptr_ctx__ptr__byte__nat) == 8);
	assert(sizeof(mut_arr__arr__char) == 32);
	assert(sizeof(map__arr__arr__char__arr__ptr__char__fun_mut1__arr__char__ptr__char__lambda0___closure) == 32);
	assert(sizeof(fun_ptr2___void__nat__ptr_global_ctx) == 8);
	assert(sizeof(thread_args__ptr_global_ctx) == 24);
	assert(sizeof(ptr__thread_args__ptr_global_ctx) == 8);
	assert(sizeof(fun_ptr1__ptr__byte__ptr__byte) == 8);
	assert(sizeof(cell__nat) == 8);
	assert(sizeof(cell__ptr__byte) == 8);
	assert(sizeof(chosen_task) == 40);
	assert(sizeof(opt__task) == 32);
	assert(sizeof(some__task) == 24);
	assert(sizeof(no_chosen_task) == 1);
	assert(sizeof(result__chosen_task__no_chosen_task) == 48);
	assert(sizeof(ok__chosen_task) == 40);
	assert(sizeof(err__no_chosen_task) == 1);
	assert(sizeof(opt__chosen_task) == 48);
	assert(sizeof(some__chosen_task) == 40);
	assert(sizeof(opt__opt__task) == 40);
	assert(sizeof(some__opt__task) == 32);
	assert(sizeof(task_and_nodes) == 40);
	assert(sizeof(opt__task_and_nodes) == 48);
	assert(sizeof(some__task_and_nodes) == 40);
	assert(sizeof(arr__nat) == 16);
	assert(sizeof(test_options) == 16);
	assert(sizeof(opt__test_options) == 24);
	assert(sizeof(some__test_options) == 16);
	assert(sizeof(opt__arr__arr__char) == 24);
	assert(sizeof(some__arr__arr__char) == 16);
	assert(sizeof(arr__opt__arr__arr__char) == 16);
	assert(sizeof(ptr__opt__arr__arr__char) == 8);
	assert(sizeof(fun1__test_options__arr__opt__arr__arr__char) == 16);
	assert(sizeof(fun_ptr3__test_options__ptr_ctx__ptr__byte__arr__opt__arr__arr__char) == 8);
	assert(sizeof(parsed_cmd_line_args) == 40);
	assert(sizeof(dict__arr__char__arr__arr__char) == 32);
	assert(sizeof(arr__arr__arr__char) == 16);
	assert(sizeof(ptr__arr__arr__char) == 8);
	assert(sizeof(opt__nat) == 16);
	assert(sizeof(some__nat) == 8);
	assert(sizeof(fun_mut1__bool__arr__char) == 16);
	assert(sizeof(fun_ptr3__bool__ptr_ctx__ptr__byte__arr__char) == 8);
	assert(sizeof(mut_dict__arr__char__arr__arr__char) == 16);
	assert(sizeof(mut_arr__arr__arr__char) == 32);
	assert(sizeof(opt__arr__char) == 24);
	assert(sizeof(some__arr__char) == 16);
	assert(sizeof(mut_arr__opt__arr__arr__char) == 32);
	assert(sizeof(fun_mut1__opt__arr__arr__char__nat) == 16);
	assert(sizeof(fun_ptr3__opt__arr__arr__char__ptr_ctx__ptr__byte__nat) == 8);
	assert(sizeof(fill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat__opt__arr__arr__char__lambda0___closure) == 24);
	assert(sizeof(cell__bool) == 1);
	assert(sizeof(fun_mut2___void__arr__char__arr__arr__char) == 16);
	assert(sizeof(fun_ptr4___void__ptr_ctx__ptr__byte__arr__char__arr__arr__char) == 8);
	assert(sizeof(parse_cmd_line_args__opt__test_options__arr__arr__char__arr__arr__char__fun1__test_options__arr__opt__arr__arr__char__lambda0___closure) == 32);
	assert(sizeof(index_of__opt__nat__arr__arr__char__arr__char__lambda0___closure) == 16);
	assert(sizeof(fun_mut1__char__nat) == 16);
	assert(sizeof(fun_ptr3__char__ptr_ctx__ptr__byte__nat) == 8);
	assert(sizeof(mut_arr__char) == 32);
	assert(sizeof(_op_plus__arr__char__arr__char__arr__char__lambda0___closure) == 32);
	assert(sizeof(fun_mut1__bool__char) == 16);
	assert(sizeof(fun_ptr3__bool__ptr_ctx__ptr__byte__char) == 8);
	assert(sizeof(r_index_of__opt__nat__arr__char__char__lambda0___closure) == 1);
	assert(sizeof(dict__arr__char__arr__char) == 32);
	assert(sizeof(mut_dict__arr__char__arr__char) == 16);
	assert(sizeof(key_value_pair__arr__char__arr__char) == 32);
	assert(sizeof(failure) == 32);
	assert(sizeof(arr__ptr_failure) == 16);
	assert(sizeof(ptr__ptr_failure) == 8);
	assert(sizeof(result__arr__char__arr__ptr_failure) == 24);
	assert(sizeof(ok__arr__char) == 16);
	assert(sizeof(err__arr__ptr_failure) == 16);
	assert(sizeof(fun_mut1___void__arr__char) == 16);
	assert(sizeof(fun_ptr3___void__ptr_ctx__ptr__byte__arr__char) == 8);
	assert(sizeof(stat_t) == 152);
	assert(sizeof(nat32) == 4);
	assert(sizeof(opt__ptr_stat_t) == 16);
	assert(sizeof(some__ptr_stat_t) == 8);
	assert(sizeof(dirent) == 280);
	assert(sizeof(nat16) == 2);
	assert(sizeof(bytes256) == 256);
	assert(sizeof(cell__ptr_dirent) == 8);
	assert(sizeof(to_mut_arr__ptr_mut_arr__arr__char__arr__arr__char__lambda0___closure) == 16);
	assert(sizeof(mut_slice__arr__char) == 24);
	assert(sizeof(each_child_recursive___void__arr__char__fun_mut1__bool__arr__char__fun_mut1___void__arr__char__lambda0___closure) == 48);
	assert(sizeof(list_compile_error_tests__arr__arr__char__arr__char__lambda1___closure) == 8);
	assert(sizeof(fun_mut1__arr__ptr_failure__arr__char) == 16);
	assert(sizeof(fun_ptr3__arr__ptr_failure__ptr_ctx__ptr__byte__arr__char) == 8);
	assert(sizeof(mut_arr__ptr_failure) == 32);
	assert(sizeof(flat_map_with_max_size__arr__ptr_failure__arr__arr__char__nat__fun_mut1__arr__ptr_failure__arr__char__lambda0___closure) == 32);
	assert(sizeof(fun_mut1___void__ptr_failure) == 16);
	assert(sizeof(fun_ptr3___void__ptr_ctx__ptr__byte__ptr_failure) == 8);
	assert(sizeof(push_all___void__ptr_mut_arr__ptr_failure__arr__ptr_failure__lambda0___closure) == 8);
	assert(sizeof(run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0___closure) == 40);
	assert(sizeof(process_result) == 40);
	assert(sizeof(fun_mut2__arr__char__arr__char__arr__char) == 16);
	assert(sizeof(fun_ptr4__arr__char__ptr_ctx__ptr__byte__arr__char__arr__char) == 8);
	assert(sizeof(pipes) == 8);
	assert(sizeof(posix_spawn_file_actions_t) == 80);
	assert(sizeof(cell__int32) == 4);
	assert(sizeof(pollfd) == 8);
	assert(sizeof(int16) == 2);
	assert(sizeof(arr__pollfd) == 16);
	assert(sizeof(ptr__pollfd) == 8);
	assert(sizeof(handle_revents_result) == 2);
	assert(sizeof(fun_mut1__ptr__char__nat) == 16);
	assert(sizeof(fun_ptr3__ptr__char__ptr_ctx__ptr__byte__nat) == 8);
	assert(sizeof(mut_arr__ptr__char) == 32);
	assert(sizeof(_op_plus__arr__ptr__char__arr__ptr__char__arr__ptr__char__lambda0___closure) == 32);
	assert(sizeof(fun_mut1__ptr__char__arr__char) == 16);
	assert(sizeof(fun_ptr3__ptr__char__ptr_ctx__ptr__byte__arr__char) == 8);
	assert(sizeof(map__arr__ptr__char__arr__arr__char__fun_mut1__ptr__char__arr__char__lambda0___closure) == 32);
	assert(sizeof(fun_mut2___void__arr__char__arr__char) == 16);
	assert(sizeof(fun_ptr4___void__ptr_ctx__ptr__byte__arr__char__arr__char) == 8);
	assert(sizeof(convert_environ__ptr__ptr__char__ptr_dict__arr__char__arr__char__lambda0___closure) == 8);
	assert(sizeof(fun0__result__arr__char__arr__ptr_failure) == 16);
	assert(sizeof(fun_ptr2__result__arr__char__arr__ptr_failure__ptr_ctx__ptr__byte) == 8);
	assert(sizeof(fun_mut1__result__arr__char__arr__ptr_failure__arr__char) == 16);
	assert(sizeof(fun_ptr3__result__arr__char__arr__ptr_failure__ptr_ctx__ptr__byte__arr__char) == 8);
	assert(sizeof(first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure__lambda0___closure) == 16);
	assert(sizeof(first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure__lambda0__lambda0___closure) == 16);
	assert(sizeof(do_test__int32__test_options__lambda0___closure) == 56);
	assert(sizeof(list_ast_and_model_tests__arr__arr__char__arr__char__lambda1___closure) == 8);
	assert(sizeof(run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0___closure) == 40);
	assert(sizeof(fun_mut0__arr__ptr_failure) == 16);
	assert(sizeof(fun_ptr2__arr__ptr_failure__ptr_ctx__ptr__byte) == 8);
	assert(sizeof(run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0__lambda0___closure) == 56);
	assert(sizeof(run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0__lambda0__lambda0___closure) == 56);
	assert(sizeof(do_test__int32__test_options__lambda0__lambda0___closure) == 56);
	assert(sizeof(list_runnable_tests__arr__arr__char__arr__char__lambda1___closure) == 8);
	assert(sizeof(run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0___closure) == 40);
	assert(sizeof(do_test__int32__test_options__lambda1___closure) == 32);
	assert(sizeof(list_lintable_files__arr__arr__char__arr__char__lambda1___closure) == 8);
	assert(sizeof(lint__result__arr__char__arr__ptr_failure__arr__char__test_options__lambda0___closure) == 16);
	assert(sizeof(fun_mut2___void__arr__char__nat) == 16);
	assert(sizeof(fun_ptr4___void__ptr_ctx__ptr__byte__arr__char__nat) == 8);
	assert(sizeof(fun_mut2___void__char__nat) == 16);
	assert(sizeof(fun_ptr4___void__ptr_ctx__ptr__byte__char__nat) == 8);
	assert(sizeof(lines__arr__arr__char__arr__char__lambda0___closure) == 32);
	assert(sizeof(lint_file__arr__ptr_failure__arr__char__lambda0___closure) == 32);

	return rt_main__int32__int32__ptr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char(argc, argv, main__ptr_fut__int32__arr__arr__char);
}
