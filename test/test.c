#include <assert.h>
#include <errno.h>
#include <stdatomic.h>
#include <stddef.h>
#include <stdint.h>
typedef int32_t int32;
typedef struct global_ctx global_ctx;
typedef struct vat vat;
typedef struct arr__ptr_vat arr__ptr_vat;
typedef struct exception_ctx exception_ctx;
typedef struct thread_local_stuff thread_local_stuff;
struct thread_local_stuff {
	exception_ctx* exception_ctx;
};
typedef struct ctx ctx;
typedef struct fun2__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char fun2__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char;
typedef struct arr__ptr__char arr__ptr__char;
typedef struct fut__int32 fut__int32;
typedef struct ok__int32 ok__int32;
struct ok__int32 {
	int32 value;
};
typedef struct err__exception err__exception;
typedef struct result__int32__exception result__int32__exception;
typedef struct arr__arr__char arr__arr__char;
typedef struct lock lock;
typedef uint64_t nat;
typedef struct condition condition;
typedef uint8_t bool;
typedef struct gc gc;
typedef struct mut_bag__task mut_bag__task;
typedef struct mut_arr__nat mut_arr__nat;
typedef struct thread_safe_counter thread_safe_counter;
typedef struct fun_mut1___void__exception fun_mut1___void__exception;
typedef vat** ptr__ptr_vat;
typedef struct exception exception;
typedef struct fut_state__int32 fut_state__int32;
typedef struct _atomic_bool _atomic_bool;
struct _atomic_bool {
	bool value;
};
typedef struct opt__ptr_gc_ctx opt__ptr_gc_ctx;
typedef struct opt__ptr_mut_bag_node__task opt__ptr_mut_bag_node__task;
typedef nat* ptr__nat;
typedef struct jmp_buf_tag jmp_buf_tag;
typedef struct arr__char arr__char;
typedef uint8_t byte;
typedef struct fut_state_callbacks__int32 fut_state_callbacks__int32;
typedef struct fut_state_resolved__int32 fut_state_resolved__int32;
struct fut_state_resolved__int32 {
	int32 value;
};
typedef struct none none;
struct none {
	bool __mustBeNonEmpty;
};
typedef struct some__ptr_gc_ctx some__ptr_gc_ctx;
typedef struct some__ptr_mut_bag_node__task some__ptr_mut_bag_node__task;
typedef uint8_t _void;
typedef struct bytes64 bytes64;
typedef struct bytes128 bytes128;
typedef struct opt__ptr_fut_callback_node__int32 opt__ptr_fut_callback_node__int32;
typedef struct gc_ctx gc_ctx;
typedef struct mut_bag_node__task mut_bag_node__task;
typedef struct bytes32 bytes32;
typedef struct some__ptr_fut_callback_node__int32 some__ptr_fut_callback_node__int32;
typedef struct task task;
typedef struct bytes16 bytes16;
struct bytes16 {
	nat n0;
	nat n1;
};
typedef struct fut_callback_node__int32 fut_callback_node__int32;
typedef struct fun_mut0___void fun_mut0___void;
typedef struct fun_mut1___void__result__int32__exception fun_mut1___void__result__int32__exception;
typedef struct opt__test_options opt__test_options;
typedef struct some__test_options some__test_options;
typedef struct test_options test_options;
struct test_options {
	bool print_tests__q;
	nat max_failures;
};
typedef int64_t _int;
typedef _void (*fun_ptr2___void__nat__ptr_global_ctx)(nat, global_ctx*);
typedef struct thread_args__ptr_global_ctx thread_args__ptr_global_ctx;
struct thread_args__ptr_global_ctx {
	fun_ptr2___void__nat__ptr_global_ctx fun;
	nat thread_id;
	global_ctx* arg;
};
typedef struct parsed_cmd_line_args parsed_cmd_line_args;
typedef struct mut_arr__opt__arr__arr__char mut_arr__opt__arr__arr__char;
typedef struct cell__bool cell__bool;
struct cell__bool {
	bool value;
};
typedef struct dict__arr__char__arr__arr__char dict__arr__char__arr__arr__char;
typedef struct arr__arr__arr__char arr__arr__arr__char;
typedef struct opt__arr__arr__char opt__arr__arr__char;
typedef struct some__arr__arr__char some__arr__arr__char;
typedef struct dict__arr__char__arr__char dict__arr__char__arr__char;
typedef struct result__arr__char__arr__ptr_failure result__arr__char__arr__ptr_failure;
typedef struct ok__arr__char ok__arr__char;
typedef struct err__arr__ptr_failure err__arr__ptr_failure;
typedef struct arr__ptr_failure arr__ptr_failure;
typedef struct failure failure;
typedef struct fun_ref0__int32 fun_ref0__int32;
typedef struct vat_and_actor_id vat_and_actor_id;
struct vat_and_actor_id {
	nat vat;
	nat actor;
};
typedef struct fun_mut0__ptr_fut__int32 fun_mut0__ptr_fut__int32;
typedef struct ok__chosen_task ok__chosen_task;
typedef struct err__no_chosen_task err__no_chosen_task;
typedef struct result__chosen_task__no_chosen_task result__chosen_task__no_chosen_task;
typedef struct chosen_task chosen_task;
typedef struct no_chosen_task no_chosen_task;
struct no_chosen_task {
	bool last_thread_out;
};
typedef struct opt__task opt__task;
typedef struct some__task some__task;
typedef struct some__nat some__nat;
struct some__nat {
	nat value;
};
typedef struct opt__nat opt__nat;
struct opt__nat {
	int kind;
	union {
		none as_none;
		some__nat as_some__nat;
	};
};
typedef struct parse_cmd_line_args__opt__test_options__arr__arr__char___arr__arr__char___fun1__test_options__arr__opt__arr__arr__char__id5___lambda0___closure parse_cmd_line_args__opt__test_options__arr__arr__char___arr__arr__char___fun1__test_options__arr__opt__arr__arr__char__id5___lambda0___closure;
typedef struct arr__opt__arr__arr__char arr__opt__arr__arr__char;
typedef struct mut_dict__arr__char__arr__char mut_dict__arr__char__arr__char;
typedef struct mut_arr__arr__char mut_arr__arr__char;
typedef struct do_test__int32__test_options___lambda0___closure do_test__int32__test_options___lambda0___closure;
typedef struct do_test__int32__test_options___lambda1___closure do_test__int32__test_options___lambda1___closure;
typedef struct fut___void fut___void;
typedef struct fun_ref1__int32___void fun_ref1__int32___void;
typedef struct fut_state___void fut_state___void;
typedef struct fun_mut1__ptr_fut__int32___void fun_mut1__ptr_fut__int32___void;
typedef struct fut_state_callbacks___void fut_state_callbacks___void;
typedef struct fut_state_resolved___void fut_state_resolved___void;
struct fut_state_resolved___void {
	_void value;
};
typedef struct opt__ptr_fut_callback_node___void opt__ptr_fut_callback_node___void;
typedef struct some__ptr_fut_callback_node___void some__ptr_fut_callback_node___void;
typedef struct fut_callback_node___void fut_callback_node___void;
typedef struct fun_mut1___void__result___void__exception fun_mut1___void__result___void__exception;
typedef struct result___void__exception result___void__exception;
typedef struct ok___void ok___void;
struct ok___void {
	_void value;
};
typedef struct add_first_task__ptr_fut__int32__arr__ptr__char___fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char___lambda0___closure add_first_task__ptr_fut__int32__arr__ptr__char___fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char___lambda0___closure;
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
typedef struct cell__nat cell__nat;
struct cell__nat {
	nat value;
};
typedef struct cell__ptr__byte cell__ptr__byte;
typedef struct some__chosen_task some__chosen_task;
typedef struct opt__chosen_task opt__chosen_task;
typedef struct mut_dict__arr__char__arr__arr__char mut_dict__arr__char__arr__arr__char;
typedef struct mut_arr__arr__arr__char mut_arr__arr__arr__char;
typedef struct fill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat___opt__arr__arr__char___lambda0___closure fill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat___opt__arr__arr__char___lambda0___closure;
typedef struct some__ptr__byte some__ptr__byte;
typedef struct opt__ptr__byte opt__ptr__byte;
typedef struct mut_arr__char mut_arr__char;
typedef struct run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure;
typedef struct mut_arr__ptr_failure mut_arr__ptr_failure;
typedef struct first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda0___closure__klbdo_test__int32__test_options___lambda0___lambda0___closure first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda0___closure__klbdo_test__int32__test_options___lambda0___lambda0___closure;
typedef struct first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda1___closure__klbdo_test__int32__test_options___lambda1___lambda0___closure first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda1___closure__klbdo_test__int32__test_options___lambda1___lambda0___closure;
typedef struct then2__ptr_fut__int32__ptr_fut___void___fun_ref0__int32___lambda0___closure then2__ptr_fut__int32__ptr_fut___void___fun_ref0__int32___lambda0___closure;
typedef struct some__opt__task some__opt__task;
typedef struct opt__opt__task opt__opt__task;
typedef struct r_index_of__opt__nat__arr__char___char___lambda0___closure r_index_of__opt__nat__arr__char___char___lambda0___closure;
struct r_index_of__opt__nat__arr__char___char___lambda0___closure {
	char value;
};
typedef struct _op_plus__arr__char__arr__char___arr__char___lambda0___closure _op_plus__arr__char__arr__char___arr__char___lambda0___closure;
typedef struct key_value_pair__arr__char__arr__char key_value_pair__arr__char__arr__char;
typedef struct list_compile_error_tests__arr__arr__char__arr__char___lambda0___closure list_compile_error_tests__arr__arr__char__arr__char___lambda0___closure;
struct list_compile_error_tests__arr__arr__char__arr__char___lambda0___closure {
	mut_arr__arr__char* res;
};
typedef struct flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure__klbrun_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___lambda0___closure flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure__klbrun_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___lambda0___closure;
typedef struct then__ptr_fut__int32__ptr_fut___void___fun_ref1__int32___void___lambda0___closure then__ptr_fut__int32__ptr_fut___void___fun_ref1__int32___void___lambda0___closure;
typedef struct map__arr__arr__char__arr__ptr__char___fun_mut1__arr__char__ptr__char__id1___lambda0___closure map__arr__arr__char__arr__ptr__char___fun_mut1__arr__char__ptr__char__id1___lambda0___closure;
typedef struct index_of__opt__nat__arr__arr__char___arr__char___lambda0___closure index_of__opt__nat__arr__arr__char___arr__char___lambda0___closure;
typedef struct each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id9___list_compile_error_tests__arr__arr__char__arr__char___lambda0___closure__klblist_compile_error_tests__arr__arr__char__arr__char___lambda0___lambda0___closure each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id9___list_compile_error_tests__arr__arr__char__arr__char___lambda0___closure__klblist_compile_error_tests__arr__arr__char__arr__char___lambda0___lambda0___closure;
typedef struct first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda0___closure__klbdo_test__int32__test_options___lambda0___lambda0___lambda0___closure first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda0___closure__klbdo_test__int32__test_options___lambda0___lambda0___lambda0___closure;
typedef struct first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda1___closure__klbdo_test__int32__test_options___lambda1___lambda0___lambda0___closure first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda1___closure__klbdo_test__int32__test_options___lambda1___lambda0___lambda0___closure;
typedef struct call__ptr_fut__int32__fun_ref0__int32___lambda0___closure call__ptr_fut__int32__fun_ref0__int32___lambda0___closure;
typedef struct opt__task_and_nodes opt__task_and_nodes;
typedef struct some__task_and_nodes some__task_and_nodes;
typedef struct task_and_nodes task_and_nodes;
typedef struct opt__arr__char opt__arr__char;
typedef struct some__arr__char some__arr__char;
typedef struct some__ptr_stat_t some__ptr_stat_t;
typedef struct opt__ptr_stat_t opt__ptr_stat_t;
typedef struct stat_t stat_t;
typedef uint32_t nat32;
typedef bool* ptr__bool;
typedef struct call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda0___closure call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda0___closure;
typedef struct call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda1___closure call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda1___closure;
struct call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda1___closure {
	fut__int32* res;
};
typedef struct dirent dirent;
typedef struct cell__ptr_dirent cell__ptr_dirent;
struct cell__ptr_dirent {
	dirent* value;
};
typedef uint16_t nat16;
typedef struct bytes256 bytes256;
typedef struct push_all___void__ptr_mut_arr__ptr_failure___arr__ptr_failure___lambda0___closure push_all___void__ptr_mut_arr__ptr_failure___arr__ptr_failure___lambda0___closure;
struct push_all___void__ptr_mut_arr__ptr_failure___arr__ptr_failure___lambda0___closure {
	mut_arr__ptr_failure* a;
};
typedef struct process_result process_result;
typedef struct run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure;
typedef struct lint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___closure lint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___closure;
struct lint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___closure {
	test_options options;
};
typedef struct forward_to___void__ptr_fut__int32___ptr_fut__int32___lambda0___closure forward_to___void__ptr_fut__int32___ptr_fut__int32___lambda0___closure;
struct forward_to___void__ptr_fut__int32___ptr_fut__int32___lambda0___closure {
	fut__int32* to;
};
typedef struct call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0___closure call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0___closure;
typedef struct list_runnable_tests__arr__arr__char__arr__char___lambda0___closure list_runnable_tests__arr__arr__char__arr__char___lambda0___closure;
struct list_runnable_tests__arr__arr__char__arr__char___lambda0___closure {
	mut_arr__arr__char* res;
};
typedef struct flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure__klbrun_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___lambda0___closure flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure__klbrun_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___lambda0___closure;
typedef struct list_lintable_files__arr__arr__char__arr__char___lambda1___closure list_lintable_files__arr__arr__char__arr__char___lambda1___closure;
struct list_lintable_files__arr__arr__char__arr__char___lambda1___closure {
	mut_arr__arr__char* res;
};
typedef struct flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___lint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___closure__klblint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___lambda0___closure flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___lint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___closure__klblint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___lambda0___closure;
struct flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___lint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___closure__klblint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___lambda0___closure {
	mut_arr__ptr_failure* res;
	nat max_size;
	lint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___closure mapper;
};
typedef struct call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda0___closure call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda0___closure;
typedef struct call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda1___closure call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda1___closure;
struct call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda1___closure {
	fut__int32* res;
};
typedef struct arr__nat arr__nat;
struct arr__nat {
	nat size;
	ptr__nat data;
};
typedef struct to_mut_arr__ptr_mut_arr__arr__char__arr__arr__char___lambda0___closure to_mut_arr__ptr_mut_arr__arr__char__arr__arr__char___lambda0___closure;
typedef struct mut_slice__arr__char mut_slice__arr__char;
struct mut_slice__arr__char {
	mut_arr__arr__char* backing;
	nat size;
	nat begin;
};
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
typedef struct mut_arr__ptr__char mut_arr__ptr__char;
typedef struct each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id9___list_runnable_tests__arr__arr__char__arr__char___lambda0___closure__klblist_runnable_tests__arr__arr__char__arr__char___lambda0___lambda0___closure each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id9___list_runnable_tests__arr__arr__char__arr__char___lambda0___closure__klblist_runnable_tests__arr__arr__char__arr__char___lambda0___lambda0___closure;
typedef struct each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id11___list_lintable_files__arr__arr__char__arr__char___lambda1___closure__klblist_lintable_files__arr__arr__char__arr__char___lambda1___lambda0___closure each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id11___list_lintable_files__arr__arr__char__arr__char___lambda1___closure__klblist_lintable_files__arr__arr__char__arr__char___lambda1___lambda0___closure;
typedef struct arr__pollfd arr__pollfd;
typedef struct pollfd pollfd;
typedef struct handle_revents_result handle_revents_result;
struct handle_revents_result {
	bool had_pollin__q;
	bool hung_up__q;
};
typedef int16_t int16;
typedef struct convert_environ__ptr__ptr__char__ptr_dict__arr__char__arr__char___lambda0___closure convert_environ__ptr__ptr__char__ptr_dict__arr__char__arr__char___lambda0___closure;
struct convert_environ__ptr__ptr__char__ptr_dict__arr__char__arr__char___lambda0___closure {
	mut_arr__ptr__char* res;
};
typedef struct map__arr__ptr__char__arr__arr__char___fun_mut1__ptr__char__arr__char__id10___lambda0___closure map__arr__ptr__char__arr__arr__char___fun_mut1__ptr__char__arr__char__id10___lambda0___closure;
typedef struct _op_plus__arr__ptr__char__arr__ptr__char___arr__ptr__char___lambda0___closure _op_plus__arr__ptr__char__arr__ptr__char___arr__ptr__char___lambda0___closure;
typedef struct lint_file__arr__ptr_failure__arr__char___lambda0___closure lint_file__arr__ptr_failure__arr__char___lambda0___closure;
typedef struct lines__arr__arr__char__arr__char___lambda0___closure lines__arr__arr__char__arr__char___lambda0___closure;
typedef struct _op_plus__arr__char__arr__char__id23___arr__char__id29___lambda0___closure _op_plus__arr__char__arr__char__id23___arr__char__id29___lambda0___closure;
struct arr__ptr_vat {
	nat size;
	ptr__ptr_vat data;
};
typedef char* ptr__char;
struct lock {
	_atomic_bool is_locked;
};
struct condition {
	lock lk;
	nat value;
};
struct mut_arr__nat {
	bool frozen__q;
	nat size;
	nat capacity;
	ptr__nat data;
};
struct thread_safe_counter {
	lock lk;
	nat value;
};
typedef byte* ptr__byte;
struct arr__char {
	nat size;
	ptr__char data;
};
struct some__ptr_gc_ctx {
	gc_ctx* value;
};
struct some__ptr_mut_bag_node__task {
	mut_bag_node__task* value;
};
struct bytes32 {
	bytes16 n0;
	bytes16 n1;
};
struct some__ptr_fut_callback_node__int32 {
	fut_callback_node__int32* value;
};
typedef _void (*fun_ptr2___void__ptr_ctx__ptr__byte)(ctx*, ptr__byte);
struct some__test_options {
	test_options value;
};
typedef thread_args__ptr_global_ctx* ptr__thread_args__ptr_global_ctx;
struct ok__arr__char {
	arr__char value;
};
typedef failure** ptr__ptr_failure;
struct failure {
	arr__char path;
	arr__char message;
};
typedef fut__int32* (*fun_ptr2__ptr_fut__int32__ptr_ctx__ptr__byte)(ctx*, ptr__byte);
struct err__no_chosen_task {
	no_chosen_task value;
};
struct mut_dict__arr__char__arr__char {
	mut_arr__arr__char* keys;
	mut_arr__arr__char* values;
};
struct do_test__int32__test_options___lambda0___closure {
	arr__char test_path;
	arr__char noze_exe;
	dict__arr__char__arr__char* env;
	test_options options;
};
struct do_test__int32__test_options___lambda1___closure {
	arr__char noze_path;
	test_options options;
};
typedef fut__int32* (*fun_ptr3__ptr_fut__int32__ptr_ctx__ptr__byte___void)(ctx*, ptr__byte, _void);
struct some__ptr_fut_callback_node___void {
	fut_callback_node___void* value;
};
struct comparison {
	int kind;
	union {
		less as_less;
		equal as_equal;
		greater as_greater;
	};
};
typedef ptr__byte (*fun_ptr1__ptr__byte__ptr__byte)(ptr__byte);
struct cell__ptr__byte {
	ptr__byte value;
};
struct mut_dict__arr__char__arr__arr__char {
	mut_arr__arr__char* keys;
	mut_arr__arr__arr__char* values;
};
struct some__ptr__byte {
	ptr__byte value;
};
struct opt__ptr__byte {
	int kind;
	union {
		none as_none;
		some__ptr__byte as_some__ptr__byte;
	};
};
struct mut_arr__char {
	bool frozen__q;
	nat size;
	nat capacity;
	ptr__char data;
};
struct run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure {
	test_options options;
	arr__char path_to_noze;
	dict__arr__char__arr__char* env;
};
struct mut_arr__ptr_failure {
	bool frozen__q;
	nat size;
	nat capacity;
	ptr__ptr_failure data;
};
struct first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda0___closure__klbdo_test__int32__test_options___lambda0___lambda0___closure {
	do_test__int32__test_options___lambda0___closure b;
};
struct first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda1___closure__klbdo_test__int32__test_options___lambda1___lambda0___closure {
	do_test__int32__test_options___lambda1___closure b;
};
struct _op_plus__arr__char__arr__char___arr__char___lambda0___closure {
	arr__char a;
	arr__char b;
};
struct key_value_pair__arr__char__arr__char {
	arr__char key;
	arr__char value;
};
struct flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure__klbrun_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___lambda0___closure {
	mut_arr__ptr_failure* res;
	nat max_size;
	run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure mapper;
};
struct index_of__opt__nat__arr__arr__char___arr__char___lambda0___closure {
	arr__char value;
};
struct each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id9___list_compile_error_tests__arr__arr__char__arr__char___lambda0___closure__klblist_compile_error_tests__arr__arr__char__arr__char___lambda0___lambda0___closure {
	arr__char path;
	list_compile_error_tests__arr__arr__char__arr__char___lambda0___closure f;
};
struct first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda0___closure__klbdo_test__int32__test_options___lambda0___lambda0___lambda0___closure {
	arr__char a_descr;
};
struct first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda1___closure__klbdo_test__int32__test_options___lambda1___lambda0___lambda0___closure {
	arr__char a_descr;
};
struct some__arr__char {
	arr__char value;
};
struct some__ptr_stat_t {
	stat_t* value;
};
struct opt__ptr_stat_t {
	int kind;
	union {
		none as_none;
		some__ptr_stat_t as_some__ptr_stat_t;
	};
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
struct process_result {
	int32 exit_code;
	arr__char stdout;
	arr__char stderr;
};
struct run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure {
	test_options options;
	arr__char path_to_noze;
	dict__arr__char__arr__char* env;
};
struct flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure__klbrun_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___lambda0___closure {
	mut_arr__ptr_failure* res;
	nat max_size;
	run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure mapper;
};
struct each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id9___list_runnable_tests__arr__arr__char__arr__char___lambda0___closure__klblist_runnable_tests__arr__arr__char__arr__char___lambda0___lambda0___closure {
	arr__char path;
	list_runnable_tests__arr__arr__char__arr__char___lambda0___closure f;
};
struct each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id11___list_lintable_files__arr__arr__char__arr__char___lambda1___closure__klblist_lintable_files__arr__arr__char__arr__char___lambda1___lambda0___closure {
	arr__char path;
	list_lintable_files__arr__arr__char__arr__char___lambda1___closure f;
};
struct pollfd {
	int32 fd;
	int16 events;
	int16 revents;
};
typedef pollfd* ptr__pollfd;
struct lint_file__arr__ptr_failure__arr__char___lambda0___closure {
	bool err_file__q;
	mut_arr__ptr_failure* res;
	arr__char path;
};
struct lines__arr__arr__char__arr__char___lambda0___closure {
	mut_arr__arr__char* res;
	arr__char s;
	cell__nat* last_nl;
};
struct _op_plus__arr__char__arr__char__id23___arr__char__id29___lambda0___closure {
	arr__char a;
	arr__char b;
};
typedef ptr__char* ptr__ptr__char;
struct global_ctx {
	lock lk;
	arr__ptr_vat vats;
	nat n_live_threads;
	condition may_be_work_to_do;
	bool is_shut_down;
	bool any_unhandled_exceptions__q;
};
struct ctx {
	ptr__byte gctx_ptr;
	nat vat_id;
	nat actor_id;
	ptr__byte gc_ctx_ptr;
	ptr__byte exception_ctx_ptr;
};
struct arr__ptr__char {
	nat size;
	ptr__ptr__char data;
};
struct exception {
	arr__char message;
};
typedef arr__char* ptr__arr__char;
struct opt__ptr_gc_ctx {
	int kind;
	union {
		none as_none;
		some__ptr_gc_ctx as_some__ptr_gc_ctx;
	};
};
struct opt__ptr_mut_bag_node__task {
	int kind;
	union {
		none as_none;
		some__ptr_mut_bag_node__task as_some__ptr_mut_bag_node__task;
	};
};
typedef _void (*fun_ptr3___void__ptr_ctx__ptr__byte__exception)(ctx*, ptr__byte, exception);
struct bytes64 {
	bytes32 n0;
	bytes32 n1;
};
struct bytes128 {
	bytes64 n0;
	bytes64 n1;
};
struct opt__ptr_fut_callback_node__int32 {
	int kind;
	union {
		none as_none;
		some__ptr_fut_callback_node__int32 as_some__ptr_fut_callback_node__int32;
	};
};
struct gc_ctx {
	gc* gc;
	opt__ptr_gc_ctx next_ctx;
};
struct fun_mut0___void {
	fun_ptr2___void__ptr_ctx__ptr__byte fun_ptr;
	ptr__byte closure;
};
struct opt__test_options {
	int kind;
	union {
		none as_none;
		some__test_options as_some__test_options;
	};
};
struct arr__ptr_failure {
	nat size;
	ptr__ptr_failure data;
};
struct fun_mut0__ptr_fut__int32 {
	fun_ptr2__ptr_fut__int32__ptr_ctx__ptr__byte fun_ptr;
	ptr__byte closure;
};
struct mut_arr__arr__char {
	bool frozen__q;
	nat size;
	nat capacity;
	ptr__arr__char data;
};
struct fun_mut1__ptr_fut__int32___void {
	fun_ptr3__ptr_fut__int32__ptr_ctx__ptr__byte___void fun_ptr;
	ptr__byte closure;
};
struct opt__ptr_fut_callback_node___void {
	int kind;
	union {
		none as_none;
		some__ptr_fut_callback_node___void as_some__ptr_fut_callback_node___void;
	};
};
struct map__arr__arr__char__arr__ptr__char___fun_mut1__arr__char__ptr__char__id1___lambda0___closure {
	arr__ptr__char a;
};
struct opt__arr__char {
	int kind;
	union {
		none as_none;
		some__arr__char as_some__arr__char;
	};
};
struct bytes256 {
	bytes128 n0;
	bytes128 n1;
};
struct posix_spawn_file_actions_t {
	int32 allocated;
	int32 used;
	ptr__byte actions;
	bytes64 pad;
};
struct mut_arr__ptr__char {
	bool frozen__q;
	nat size;
	nat capacity;
	ptr__ptr__char data;
};
struct arr__pollfd {
	nat size;
	ptr__pollfd data;
};
struct _op_plus__arr__ptr__char__arr__ptr__char___arr__ptr__char___lambda0___closure {
	arr__ptr__char a;
	arr__ptr__char b;
};
struct err__exception {
	exception value;
};
struct result__int32__exception {
	int kind;
	union {
		ok__int32 as_ok__int32;
		err__exception as_err__exception;
	};
};
struct arr__arr__char {
	nat size;
	ptr__arr__char data;
};
struct gc {
	lock lk;
	opt__ptr_gc_ctx context_head;
	bool needs_gc;
	bool is_doing_gc;
	ptr__byte begin;
	ptr__byte next_byte;
};
struct mut_bag__task {
	opt__ptr_mut_bag_node__task head;
};
struct fun_mut1___void__exception {
	fun_ptr3___void__ptr_ctx__ptr__byte__exception fun_ptr;
	ptr__byte closure;
};
struct jmp_buf_tag {
	bytes64 jmp_buf;
	int32 mask_was_saved;
	bytes128 saved_mask;
};
struct fut_state_callbacks__int32 {
	opt__ptr_fut_callback_node__int32 head;
};
struct task {
	nat actor_id;
	fun_mut0___void fun;
};
typedef _void (*fun_ptr3___void__ptr_ctx__ptr__byte__result__int32__exception)(ctx*, ptr__byte, result__int32__exception);
struct parsed_cmd_line_args {
	arr__arr__char nameless;
	dict__arr__char__arr__arr__char* named;
	arr__arr__char after;
};
typedef arr__arr__char* ptr__arr__arr__char;
struct some__arr__arr__char {
	arr__arr__char value;
};
struct dict__arr__char__arr__char {
	arr__arr__char keys;
	arr__arr__char values;
};
struct err__arr__ptr_failure {
	arr__ptr_failure value;
};
struct fun_ref0__int32 {
	vat_and_actor_id vat_and_actor;
	fun_mut0__ptr_fut__int32 fun;
};
struct some__task {
	task value;
};
struct parse_cmd_line_args__opt__test_options__arr__arr__char___arr__arr__char___fun1__test_options__arr__opt__arr__arr__char__id5___lambda0___closure {
	arr__arr__char t_names;
	cell__bool* help;
	mut_arr__opt__arr__arr__char* values;
};
struct fun_ref1__int32___void {
	vat_and_actor_id vat_and_actor;
	fun_mut1__ptr_fut__int32___void fun;
};
struct fut_state_callbacks___void {
	opt__ptr_fut_callback_node___void head;
};
struct result___void__exception {
	int kind;
	union {
		ok___void as_ok___void;
		err__exception as_err__exception;
	};
};
struct mut_arr__arr__arr__char {
	bool frozen__q;
	nat size;
	nat capacity;
	ptr__arr__arr__char data;
};
struct then2__ptr_fut__int32__ptr_fut___void___fun_ref0__int32___lambda0___closure {
	fun_ref0__int32 cb;
};
struct then__ptr_fut__int32__ptr_fut___void___fun_ref1__int32___void___lambda0___closure {
	fun_ref1__int32___void cb;
	fut__int32* res;
};
struct call__ptr_fut__int32__fun_ref0__int32___lambda0___closure {
	fun_ref0__int32 f;
	fut__int32* res;
};
struct task_and_nodes {
	task task;
	opt__ptr_mut_bag_node__task nodes;
};
struct call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda0___closure {
	fun_ref0__int32 f;
	fut__int32* res;
};
struct dirent {
	nat d_ino;
	_int d_off;
	nat16 d_reclen;
	char d_type;
	bytes256 d_name;
};
struct call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0___closure {
	fun_ref1__int32___void f;
	_void p0;
	fut__int32* res;
};
struct call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda0___closure {
	fun_ref1__int32___void f;
	_void p0;
	fut__int32* res;
};
struct to_mut_arr__ptr_mut_arr__arr__char__arr__arr__char___lambda0___closure {
	arr__arr__char a;
};
struct map__arr__ptr__char__arr__arr__char___fun_mut1__ptr__char__arr__char__id10___lambda0___closure {
	arr__arr__char a;
};
typedef fut__int32* (*fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char)(ctx*, arr__arr__char);
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
typedef jmp_buf_tag* ptr__jmp_buf_tag;
typedef fut__int32* (*fun_ptr4__ptr_fut__int32__ptr_ctx__ptr__byte__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char)(ctx*, ptr__byte, arr__ptr__char, fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char);
struct fut_state__int32 {
	int kind;
	union {
		fut_state_callbacks__int32 as_fut_state_callbacks__int32;
		fut_state_resolved__int32 as_fut_state_resolved__int32;
		exception as_exception;
	};
};
struct mut_bag_node__task {
	task value;
	opt__ptr_mut_bag_node__task next_node;
};
struct fun_mut1___void__result__int32__exception {
	fun_ptr3___void__ptr_ctx__ptr__byte__result__int32__exception fun_ptr;
	ptr__byte closure;
};
struct arr__arr__arr__char {
	nat size;
	ptr__arr__arr__char data;
};
struct opt__arr__arr__char {
	int kind;
	union {
		none as_none;
		some__arr__arr__char as_some__arr__arr__char;
	};
};
struct result__arr__char__arr__ptr_failure {
	int kind;
	union {
		ok__arr__char as_ok__arr__char;
		err__arr__ptr_failure as_err__arr__ptr_failure;
	};
};
struct opt__task {
	int kind;
	union {
		none as_none;
		some__task as_some__task;
	};
};
struct fut_state___void {
	int kind;
	union {
		fut_state_callbacks___void as_fut_state_callbacks___void;
		fut_state_resolved___void as_fut_state_resolved___void;
		exception as_exception;
	};
};
typedef _void (*fun_ptr3___void__ptr_ctx__ptr__byte__result___void__exception)(ctx*, ptr__byte, result___void__exception);
struct add_first_task__ptr_fut__int32__arr__ptr__char___fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char___lambda0___closure {
	arr__ptr__char all_args;
	fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char main_ptr;
};
struct fill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat___opt__arr__arr__char___lambda0___closure {
	opt__arr__arr__char value;
};
struct some__opt__task {
	opt__task value;
};
struct opt__opt__task {
	int kind;
	union {
		none as_none;
		some__opt__task as_some__opt__task;
	};
};
struct some__task_and_nodes {
	task_and_nodes value;
};
struct exception_ctx {
	ptr__jmp_buf_tag jmp_buf_ptr;
	exception thrown_exception;
};
struct fun2__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char {
	fun_ptr4__ptr_fut__int32__ptr_ctx__ptr__byte__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char fun_ptr;
	ptr__byte closure;
};
struct fut__int32 {
	lock lk;
	fut_state__int32 state;
};
struct fut_callback_node__int32 {
	fun_mut1___void__result__int32__exception cb;
	opt__ptr_fut_callback_node__int32 next_node;
};
struct dict__arr__char__arr__arr__char {
	arr__arr__char keys;
	arr__arr__arr__char values;
};
typedef opt__arr__arr__char* ptr__opt__arr__arr__char;
struct chosen_task {
	vat* vat;
	opt__task task_or_gc;
};
struct arr__opt__arr__arr__char {
	nat size;
	ptr__opt__arr__arr__char data;
};
struct fut___void {
	lock lk;
	fut_state___void state;
};
struct fun_mut1___void__result___void__exception {
	fun_ptr3___void__ptr_ctx__ptr__byte__result___void__exception fun_ptr;
	ptr__byte closure;
};
struct some__chosen_task {
	chosen_task value;
};
struct opt__chosen_task {
	int kind;
	union {
		none as_none;
		some__chosen_task as_some__chosen_task;
	};
};
struct opt__task_and_nodes {
	int kind;
	union {
		none as_none;
		some__task_and_nodes as_some__task_and_nodes;
	};
};
struct mut_arr__opt__arr__arr__char {
	bool frozen__q;
	nat size;
	nat capacity;
	ptr__opt__arr__arr__char data;
};
struct ok__chosen_task {
	chosen_task value;
};
struct result__chosen_task__no_chosen_task {
	int kind;
	union {
		ok__chosen_task as_ok__chosen_task;
		err__no_chosen_task as_err__no_chosen_task;
	};
};
struct fut_callback_node___void {
	fun_mut1___void__result___void__exception cb;
	opt__ptr_fut_callback_node___void next_node;
};

#define _constant____arr__ptr_vat__0 { 0ull, NULL }
static char _constantArrBacking13[13] = "main failed: ";
#define _constant____arr__char__13 { 13ull, (_constantArrBacking13 + 0) }
static char _constantArrBacking14[11] = "print-tests";
#define _constant____arr__char__14 { 11ull, (_constantArrBacking14 + 0) }
static char _constantArrBacking15[12] = "max-failures";
#define _constant____arr__char__15 { 12ull, (_constantArrBacking15 + 0) }
static arr__char _constantArrBacking16[2] = {_constant____arr__char__14, _constant____arr__char__15};
#define _constant____arr__arr__char__0 { 2ull, (_constantArrBacking16 + 0) }
#define _constant____arr__char__5 { 0ull, NULL }
#define _constant____exception__0 { _constant____arr__char__5 }
static char _constantArrBacking4[1] = "\n";
#define _constant____arr__char__4 { 1ull, (_constantArrBacking4 + 0) }
static char _constantArrBacking19[26] = "Should be no nameless args";
#define _constant____arr__char__18 { 26ull, (_constantArrBacking19 + 0) }
#define _constant____none__0 { 0 }
#define _constant__opt__arr__arr__char__0 { 0, .as_none = _constant____none__0 }
#define _constant__opt__test_options__0 { 0, .as_none = _constant____none__0 }
static char _constantArrBacking33[18] = "test -- runs tests";
#define _constant____arr__char__37 { 18ull, (_constantArrBacking33 + 0) }
static char _constantArrBacking34[8] = "options:";
#define _constant____arr__char__38 { 8ull, (_constantArrBacking34 + 0) }
static char _constantArrBacking35[38] = "\t--print-tests  : print every test run";
#define _constant____arr__char__39 { 38ull, (_constantArrBacking35 + 0) }
static char _constantArrBacking36[64] = "\t--max-failures : stop after this many failures. Defaults to 10.";
#define _constant____arr__char__40 { 64ull, (_constantArrBacking36 + 0) }
static char _constantArrBacking41[3] = "bin";
#define _constant____arr__char__45 { 3ull, (_constantArrBacking41 + 0) }
static char _constantArrBacking42[4] = "noze";
#define _constant____arr__char__46 { 4ull, (_constantArrBacking42 + 0) }
static char _constantArrBacking44[14] = "compile-errors";
#define _constant____arr__char__48 { 14ull, (_constantArrBacking44 + 0) }
#define _constant__opt__ptr_gc_ctx__0 { 0, .as_none = _constant____none__0 }
#define _constant__opt__ptr_mut_bag_node__task__0 { 0, .as_none = _constant____none__0 }
#define _constant____arr__arr__char__1 { 0ull, NULL }
#define _constant____arr__arr__arr__char__0 { 0ull, NULL }
static dict__arr__char__arr__arr__char _constant____ptr_dict__arr__char__arr__arr__char__0 = { _constant____arr__arr__char__1, _constant____arr__arr__arr__char__0 };
static char _constantArrBacking8[13] = "assert failed";
#define _constant____arr__char__8 { 13ull, (_constantArrBacking8 + 0) }
static char _constantArrBacking39[14] = "/proc/self/exe";
#define _constant____arr__char__43 { 14ull, (_constantArrBacking39 + 0) }
static char _constantArrBacking40[1] = "/";
#define _constant____arr__char__44 { 1ull, (_constantArrBacking40 + 0) }
static char _constantArrBacking62[4] = "Ran ";
#define _constant____arr__char__74 { 4ull, (_constantArrBacking62 + 0) }
static char _constantArrBacking63[20] = " compile-error tests";
#define _constant____arr__char__75 { 20ull, (_constantArrBacking63 + 0) }
static char _constantArrBacking92[15] = "hit maximum of ";
#define _constant____arr__char__106 { 15ull, (_constantArrBacking92 + 0) }
static char _constantArrBacking93[9] = " failures";
#define _constant____arr__char__107 { 9ull, (_constantArrBacking93 + 0) }
static char _constantArrBacking1[20] = "uncaught exception: ";
#define _constant____arr__char__1 { 20ull, (_constantArrBacking1 + 0) }
static char _constantArrBacking3[17] = "<<empty message>>";
#define _constant____arr__char__3 { 17ull, (_constantArrBacking3 + 0) }
#define _constant____fut_state_resolved___void__0 { 0 }
#define _constant__fut_state___void__0 { 1, .as_fut_state_resolved___void = _constant____fut_state_resolved___void__0 }
static char _constantArrBacking20[4] = "help";
#define _constant____arr__char__19 { 4ull, (_constantArrBacking20 + 0) }
static char _constantArrBacking21[15] = "Unexpected arg ";
#define _constant____arr__char__20 { 15ull, (_constantArrBacking21 + 0) }
static char _constantArrBacking22[1] = "0";
#define _constant____arr__char__21 { 1ull, (_constantArrBacking22 + 0) }
static char _constantArrBacking23[1] = "1";
#define _constant____arr__char__23 { 1ull, (_constantArrBacking23 + 0) }
static char _constantArrBacking25[1] = "2";
#define _constant____arr__char__29 { 1ull, (_constantArrBacking25 + 0) }
static char _constantArrBacking26[1] = "3";
#define _constant____arr__char__30 { 1ull, (_constantArrBacking26 + 0) }
static char _constantArrBacking27[1] = "4";
#define _constant____arr__char__31 { 1ull, (_constantArrBacking27 + 0) }
static char _constantArrBacking28[1] = "5";
#define _constant____arr__char__32 { 1ull, (_constantArrBacking28 + 0) }
static char _constantArrBacking29[1] = "6";
#define _constant____arr__char__33 { 1ull, (_constantArrBacking29 + 0) }
static char _constantArrBacking30[1] = "7";
#define _constant____arr__char__34 { 1ull, (_constantArrBacking30 + 0) }
static char _constantArrBacking31[1] = "8";
#define _constant____arr__char__35 { 1ull, (_constantArrBacking31 + 0) }
static char _constantArrBacking32[1] = "9";
#define _constant____arr__char__36 { 1ull, (_constantArrBacking32 + 0) }
#define _constant__opt__chosen_task__0 { 0, .as_none = _constant____none__0 }
#define _constant__opt__nat__0 { 0, .as_none = _constant____none__0 }
static char _constantArrBacking17[2] = "--";
#define _constant____arr__char__16 { 2ull, (_constantArrBacking17 + 0) }
static char _constantArrBacking7[13] = "forbid failed";
#define _constant____arr__char__7 { 13ull, (_constantArrBacking7 + 0) }
static char _constantArrBacking9[1] = "\0";
#define _constant____arr__char__9 { 1ull, (_constantArrBacking9 + 0) }
#define _constant__opt__ptr_fut_callback_node__int32__0 { 0, .as_none = _constant____none__0 }
#define _constant____fut_state_callbacks__int32__0 { _constant__opt__ptr_fut_callback_node__int32__0 }
#define _constant__fut_state__int32__0 { 0, .as_fut_state_callbacks__int32 = _constant____fut_state_callbacks__int32__0 }
#define _constant__opt__task__0 { 0, .as_none = _constant____none__0 }
#define _constant____some__opt__task__0 { _constant__opt__task__0 }
#define _constant__opt__opt__task__0 { 1, .as_some__opt__task = _constant____some__opt__task__0 }
#define _constant__opt__opt__task__1 { 0, .as_none = _constant____none__0 }
static char _constantArrBacking47[2] = "nz";
#define _constant____arr__char__51 { 2ull, (_constantArrBacking47 + 0) }
static char _constantArrBacking48[3] = "err";
#define _constant____arr__char__52 { 3ull, (_constantArrBacking48 + 0) }
static char _constantArrBacking64[8] = "runnable";
#define _constant____arr__char__76 { 8ull, (_constantArrBacking64 + 0) }
static char _constantArrBacking80[1] = " ";
#define _constant____arr__char__91 { 1ull, (_constantArrBacking80 + 0) }
#define _constant__opt__arr__char__0 { 0, .as_none = _constant____none__0 }
static char _constantArrBacking49[11] = "noze build ";
#define _constant____arr__char__53 { 11ull, (_constantArrBacking49 + 0) }
static char _constantArrBacking71[4] = "ran ";
#define _constant____arr__char__83 { 4ull, (_constantArrBacking71 + 0) }
static char _constantArrBacking72[15] = " runnable tests";
#define _constant____arr__char__84 { 15ull, (_constantArrBacking72 + 0) }
static char _constantArrBacking88[7] = "Linted ";
#define _constant____arr__char__102 { 7ull, (_constantArrBacking88 + 0) }
static char _constantArrBacking89[6] = " files";
#define _constant____arr__char__103 { 6ull, (_constantArrBacking89 + 0) }
static char _constantArrBacking90[4] = "\x1b[1m";
#define _constant____arr__char__104 { 4ull, (_constantArrBacking90 + 0) }
static char _constantArrBacking91[3] = "\x1b[m";
#define _constant____arr__char__105 { 3ull, (_constantArrBacking91 + 0) }
#define _constant__opt__task_and_nodes__0 { 0, .as_none = _constant____none__0 }
#define _constant__opt__ptr_stat_t__0 { 0, .as_none = _constant____none__0 }
#define _constant____bytes16__0 { 0ull, 0ull }
#define _constant____bytes32__0 { _constant____bytes16__0, _constant____bytes16__0 }
#define _constant____bytes64__0 { _constant____bytes32__0, _constant____bytes32__0 }
#define _constant____bytes128__0 { _constant____bytes64__0, _constant____bytes64__0 }
#define _constant____bytes256__0 { _constant____bytes128__0, _constant____bytes128__0 }
static char _constantArrBacking45[1] = ".";
#define _constant____arr__char__49 { 1ull, (_constantArrBacking45 + 0) }
static char _constantArrBacking46[2] = "..";
#define _constant____arr__char__50 { 2ull, (_constantArrBacking46 + 0) }
static char _constantArrBacking50[5] = "build";
#define _constant____arr__char__54 { 5ull, (_constantArrBacking50 + 0) }
static char _constantArrBacking54[59] = "Compile error should result in exit code of 1. Instead got ";
#define _constant____arr__char__66 { 59ull, (_constantArrBacking54 + 0) }
static char _constantArrBacking55[37] = "stdout should be empty. Instead got:\n";
#define _constant____arr__char__67 { 37ull, (_constantArrBacking55 + 0) }
static char _constantArrBacking58[15] = "stderr is empty";
#define _constant____arr__char__70 { 15ull, (_constantArrBacking58 + 0) }
static char _constantArrBacking60[29] = " does not exist. stderr was:\n";
#define _constant____arr__char__72 { 29ull, (_constantArrBacking60 + 0) }
static char _constantArrBacking61[44] = "got different stderr than expected. actual:\n";
#define _constant____arr__char__73 { 44ull, (_constantArrBacking61 + 0) }
#define _constant____jmp_buf_tag__0 { _constant____bytes64__0, 0, _constant____bytes128__0 }
static char _constantArrBacking18[27] = "tried to force empty option";
#define _constant____arr__char__17 { 27ull, (_constantArrBacking18 + 0) }
#define _constant____exception__1 { _constant____arr__char__17 }
static char _constantArrBacking53[14] = " is not a file";
#define _constant____arr__char__65 { 14ull, (_constantArrBacking53 + 0) }
static char _constantArrBacking37[1] = "-";
#define _constant____arr__char__41 { 1ull, (_constantArrBacking37 + 0) }
static char _constantArrBacking59[20] = "failed to open file ";
#define _constant____arr__char__71 { 20ull, (_constantArrBacking59 + 0) }
static char _constantArrBacking65[1] = "c";
#define _constant____arr__char__77 { 1ull, (_constantArrBacking65 + 0) }
static char _constantArrBacking51[31] = "Process terminated with signal ";
#define _constant____arr__char__55 { 31ull, (_constantArrBacking51 + 0) }
static char _constantArrBacking52[12] = "WAIT STOPPED";
#define _constant____arr__char__64 { 12ull, (_constantArrBacking52 + 0) }
static char _constantArrBacking66[9] = "noze run ";
#define _constant____arr__char__78 { 9ull, (_constantArrBacking66 + 0) }
static char _constantArrBacking79[5] = "lint ";
#define _constant____arr__char__90 { 5ull, (_constantArrBacking79 + 0) }
static char _constantArrBacking43[1] = "=";
#define _constant____arr__char__47 { 1ull, (_constantArrBacking43 + 0) }
static char _constantArrBacking67[3] = "run";
#define _constant____arr__char__79 { 3ull, (_constantArrBacking67 + 0) }
static process_result _constant____ptr_process_result__0 = { 0, _constant____arr__char__5, _constant____arr__char__5 };
#define _constant____arr__ptr_failure__0 { 0ull, NULL }
static char _constantArrBacking68[9] = "\nstatus: ";
#define _constant____arr__char__80 { 9ull, (_constantArrBacking68 + 0) }
static char _constantArrBacking69[9] = "\nstdout:\n";
#define _constant____arr__char__81 { 9ull, (_constantArrBacking69 + 0) }
static char _constantArrBacking70[8] = "stderr:\n";
#define _constant____arr__char__82 { 8ull, (_constantArrBacking70 + 0) }
static char _constantArrBacking73[7] = "libfirm";
#define _constant____arr__char__85 { 7ull, (_constantArrBacking73 + 0) }
static char _constantArrBacking74[4] = "data";
#define _constant____arr__char__86 { 4ull, (_constantArrBacking74 + 0) }
static char _constantArrBacking75[1] = "o";
#define _constant____arr__char__87 { 1ull, (_constantArrBacking75 + 0) }
static char _constantArrBacking76[3] = "out";
#define _constant____arr__char__88 { 3ull, (_constantArrBacking76 + 0) }
static char _constantArrBacking77[10] = "tmLanguage";
#define _constant____arr__char__89 { 10ull, (_constantArrBacking77 + 0) }
static arr__char _constantArrBacking78[5] = {_constant____arr__char__77, _constant____arr__char__86, _constant____arr__char__87, _constant____arr__char__88, _constant____arr__char__89};
#define _constant____arr__arr__char__2 { 5ull, (_constantArrBacking78 + 0) }
static char _constantArrBacking81[2] = "  ";
#define _constant____arr__char__92 { 2ull, (_constantArrBacking81 + 0) }
static char _constantArrBacking82[5] = "line ";
#define _constant____arr__char__93 { 5ull, (_constantArrBacking82 + 0) }
static char _constantArrBacking83[24] = " contains a double space";
#define _constant____arr__char__94 { 24ull, (_constantArrBacking83 + 0) }
static char _constantArrBacking86[4] = " is ";
#define _constant____arr__char__100 { 4ull, (_constantArrBacking86 + 0) }
static char _constantArrBacking87[28] = " columns long, should be <= ";
#define _constant____arr__char__101 { 28ull, (_constantArrBacking87 + 0) }

int32* _initint32(byte* out, int32 value) {
	int32* res = (int32*) out;
	*res = value;
	return res;
}
int32 _failint32() {
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


arr__ptr_vat* _initarr__ptr_vat(byte* out, arr__ptr_vat value) {
	arr__ptr_vat* res = (arr__ptr_vat*) out;
	*res = value;
	return res;
}
arr__ptr_vat _failarr__ptr_vat() {
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


thread_local_stuff* _initthread_local_stuff(byte* out, thread_local_stuff value) {
	thread_local_stuff* res = (thread_local_stuff*) out;
	*res = value;
	return res;
}
thread_local_stuff _failthread_local_stuff() {
	assert(0);
}


ctx* _initctx(byte* out, ctx value) {
	ctx* res = (ctx*) out;
	*res = value;
	return res;
}
ctx _failctx() {
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


arr__ptr__char* _initarr__ptr__char(byte* out, arr__ptr__char value) {
	arr__ptr__char* res = (arr__ptr__char*) out;
	*res = value;
	return res;
}
arr__ptr__char _failarr__ptr__char() {
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


result__int32__exception* _initresult__int32__exception(byte* out, result__int32__exception value) {
	result__int32__exception* res = (result__int32__exception*) out;
	*res = value;
	return res;
}
result__int32__exception _failresult__int32__exception() {
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


arr__arr__char* _initarr__arr__char(byte* out, arr__arr__char value) {
	arr__arr__char* res = (arr__arr__char*) out;
	*res = value;
	return res;
}
arr__arr__char _failarr__arr__char() {
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


nat* _initnat(byte* out, nat value) {
	nat* res = (nat*) out;
	*res = value;
	return res;
}
nat _failnat() {
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


bool* _initbool(byte* out, bool value) {
	bool* res = (bool*) out;
	*res = value;
	return res;
}
bool _failbool() {
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


mut_bag__task* _initmut_bag__task(byte* out, mut_bag__task value) {
	mut_bag__task* res = (mut_bag__task*) out;
	*res = value;
	return res;
}
mut_bag__task _failmut_bag__task() {
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


ptr__ptr_vat* _initptr__ptr_vat(byte* out, ptr__ptr_vat value) {
	ptr__ptr_vat* res = (ptr__ptr_vat*) out;
	*res = value;
	return res;
}
ptr__ptr_vat _failptr__ptr_vat() {
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


exception* _initexception(byte* out, exception value) {
	exception* res = (exception*) out;
	*res = value;
	return res;
}
exception _failexception() {
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


fun_ptr4__ptr_fut__int32__ptr_ctx__ptr__byte__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char* _initfun_ptr4__ptr_fut__int32__ptr_ctx__ptr__byte__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char(byte* out, fun_ptr4__ptr_fut__int32__ptr_ctx__ptr__byte__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char value) {
	fun_ptr4__ptr_fut__int32__ptr_ctx__ptr__byte__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char* res = (fun_ptr4__ptr_fut__int32__ptr_ctx__ptr__byte__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char*) out;
	*res = value;
	return res;
}
fun_ptr4__ptr_fut__int32__ptr_ctx__ptr__byte__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char _failfun_ptr4__ptr_fut__int32__ptr_ctx__ptr__byte__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char() {
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


char* _initchar(byte* out, char value) {
	char* res = (char*) out;
	*res = value;
	return res;
}
char _failchar() {
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


_atomic_bool* _init_atomic_bool(byte* out, _atomic_bool value) {
	_atomic_bool* res = (_atomic_bool*) out;
	*res = value;
	return res;
}
_atomic_bool _fail_atomic_bool() {
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


opt__ptr_mut_bag_node__task* _initopt__ptr_mut_bag_node__task(byte* out, opt__ptr_mut_bag_node__task value) {
	opt__ptr_mut_bag_node__task* res = (opt__ptr_mut_bag_node__task*) out;
	*res = value;
	return res;
}
opt__ptr_mut_bag_node__task _failopt__ptr_mut_bag_node__task() {
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


fun_ptr3___void__ptr_ctx__ptr__byte__exception* _initfun_ptr3___void__ptr_ctx__ptr__byte__exception(byte* out, fun_ptr3___void__ptr_ctx__ptr__byte__exception value) {
	fun_ptr3___void__ptr_ctx__ptr__byte__exception* res = (fun_ptr3___void__ptr_ctx__ptr__byte__exception*) out;
	*res = value;
	return res;
}
fun_ptr3___void__ptr_ctx__ptr__byte__exception _failfun_ptr3___void__ptr_ctx__ptr__byte__exception() {
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


arr__char* _initarr__char(byte* out, arr__char value) {
	arr__char* res = (arr__char*) out;
	*res = value;
	return res;
}
arr__char _failarr__char() {
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


fut_state_callbacks__int32* _initfut_state_callbacks__int32(byte* out, fut_state_callbacks__int32 value) {
	fut_state_callbacks__int32* res = (fut_state_callbacks__int32*) out;
	*res = value;
	return res;
}
fut_state_callbacks__int32 _failfut_state_callbacks__int32() {
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


none* _initnone(byte* out, none value) {
	none* res = (none*) out;
	*res = value;
	return res;
}
none _failnone() {
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


some__ptr_mut_bag_node__task* _initsome__ptr_mut_bag_node__task(byte* out, some__ptr_mut_bag_node__task value) {
	some__ptr_mut_bag_node__task* res = (some__ptr_mut_bag_node__task*) out;
	*res = value;
	return res;
}
some__ptr_mut_bag_node__task _failsome__ptr_mut_bag_node__task() {
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


bytes64* _initbytes64(byte* out, bytes64 value) {
	bytes64* res = (bytes64*) out;
	*res = value;
	return res;
}
bytes64 _failbytes64() {
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


opt__ptr_fut_callback_node__int32* _initopt__ptr_fut_callback_node__int32(byte* out, opt__ptr_fut_callback_node__int32 value) {
	opt__ptr_fut_callback_node__int32* res = (opt__ptr_fut_callback_node__int32*) out;
	*res = value;
	return res;
}
opt__ptr_fut_callback_node__int32 _failopt__ptr_fut_callback_node__int32() {
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


mut_bag_node__task* _initmut_bag_node__task(byte* out, mut_bag_node__task value) {
	mut_bag_node__task* res = (mut_bag_node__task*) out;
	*res = value;
	return res;
}
mut_bag_node__task _failmut_bag_node__task() {
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


some__ptr_fut_callback_node__int32* _initsome__ptr_fut_callback_node__int32(byte* out, some__ptr_fut_callback_node__int32 value) {
	some__ptr_fut_callback_node__int32* res = (some__ptr_fut_callback_node__int32*) out;
	*res = value;
	return res;
}
some__ptr_fut_callback_node__int32 _failsome__ptr_fut_callback_node__int32() {
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


bytes16* _initbytes16(byte* out, bytes16 value) {
	bytes16* res = (bytes16*) out;
	*res = value;
	return res;
}
bytes16 _failbytes16() {
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


fun_mut0___void* _initfun_mut0___void(byte* out, fun_mut0___void value) {
	fun_mut0___void* res = (fun_mut0___void*) out;
	*res = value;
	return res;
}
fun_mut0___void _failfun_mut0___void() {
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


fun_ptr2___void__ptr_ctx__ptr__byte* _initfun_ptr2___void__ptr_ctx__ptr__byte(byte* out, fun_ptr2___void__ptr_ctx__ptr__byte value) {
	fun_ptr2___void__ptr_ctx__ptr__byte* res = (fun_ptr2___void__ptr_ctx__ptr__byte*) out;
	*res = value;
	return res;
}
fun_ptr2___void__ptr_ctx__ptr__byte _failfun_ptr2___void__ptr_ctx__ptr__byte() {
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


test_options* _inittest_options(byte* out, test_options value) {
	test_options* res = (test_options*) out;
	*res = value;
	return res;
}
test_options _failtest_options() {
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


fun_ptr2___void__nat__ptr_global_ctx* _initfun_ptr2___void__nat__ptr_global_ctx(byte* out, fun_ptr2___void__nat__ptr_global_ctx value) {
	fun_ptr2___void__nat__ptr_global_ctx* res = (fun_ptr2___void__nat__ptr_global_ctx*) out;
	*res = value;
	return res;
}
fun_ptr2___void__nat__ptr_global_ctx _failfun_ptr2___void__nat__ptr_global_ctx() {
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


thread_args__ptr_global_ctx* _initthread_args__ptr_global_ctx(byte* out, thread_args__ptr_global_ctx value) {
	thread_args__ptr_global_ctx* res = (thread_args__ptr_global_ctx*) out;
	*res = value;
	return res;
}
thread_args__ptr_global_ctx _failthread_args__ptr_global_ctx() {
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


mut_arr__opt__arr__arr__char* _initmut_arr__opt__arr__arr__char(byte* out, mut_arr__opt__arr__arr__char value) {
	mut_arr__opt__arr__arr__char* res = (mut_arr__opt__arr__arr__char*) out;
	*res = value;
	return res;
}
mut_arr__opt__arr__arr__char _failmut_arr__opt__arr__arr__char() {
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


dict__arr__char__arr__arr__char* _initdict__arr__char__arr__arr__char(byte* out, dict__arr__char__arr__arr__char value) {
	dict__arr__char__arr__arr__char* res = (dict__arr__char__arr__arr__char*) out;
	*res = value;
	return res;
}
dict__arr__char__arr__arr__char _faildict__arr__char__arr__arr__char() {
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


arr__arr__arr__char* _initarr__arr__arr__char(byte* out, arr__arr__arr__char value) {
	arr__arr__arr__char* res = (arr__arr__arr__char*) out;
	*res = value;
	return res;
}
arr__arr__arr__char _failarr__arr__arr__char() {
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


ptr__arr__arr__char* _initptr__arr__arr__char(byte* out, ptr__arr__arr__char value) {
	ptr__arr__arr__char* res = (ptr__arr__arr__char*) out;
	*res = value;
	return res;
}
ptr__arr__arr__char _failptr__arr__arr__char() {
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


dict__arr__char__arr__char* _initdict__arr__char__arr__char(byte* out, dict__arr__char__arr__char value) {
	dict__arr__char__arr__char* res = (dict__arr__char__arr__char*) out;
	*res = value;
	return res;
}
dict__arr__char__arr__char _faildict__arr__char__arr__char() {
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


failure* _initfailure(byte* out, failure value) {
	failure* res = (failure*) out;
	*res = value;
	return res;
}
failure _failfailure() {
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


result__chosen_task__no_chosen_task* _initresult__chosen_task__no_chosen_task(byte* out, result__chosen_task__no_chosen_task value) {
	result__chosen_task__no_chosen_task* res = (result__chosen_task__no_chosen_task*) out;
	*res = value;
	return res;
}
result__chosen_task__no_chosen_task _failresult__chosen_task__no_chosen_task() {
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


no_chosen_task* _initno_chosen_task(byte* out, no_chosen_task value) {
	no_chosen_task* res = (no_chosen_task*) out;
	*res = value;
	return res;
}
no_chosen_task _failno_chosen_task() {
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


some__nat* _initsome__nat(byte* out, some__nat value) {
	some__nat* res = (some__nat*) out;
	*res = value;
	return res;
}
some__nat _failsome__nat() {
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


parse_cmd_line_args__opt__test_options__arr__arr__char___arr__arr__char___fun1__test_options__arr__opt__arr__arr__char__id5___lambda0___closure* _initparse_cmd_line_args__opt__test_options__arr__arr__char___arr__arr__char___fun1__test_options__arr__opt__arr__arr__char__id5___lambda0___closure(byte* out, parse_cmd_line_args__opt__test_options__arr__arr__char___arr__arr__char___fun1__test_options__arr__opt__arr__arr__char__id5___lambda0___closure value) {
	parse_cmd_line_args__opt__test_options__arr__arr__char___arr__arr__char___fun1__test_options__arr__opt__arr__arr__char__id5___lambda0___closure* res = (parse_cmd_line_args__opt__test_options__arr__arr__char___arr__arr__char___fun1__test_options__arr__opt__arr__arr__char__id5___lambda0___closure*) out;
	*res = value;
	return res;
}
parse_cmd_line_args__opt__test_options__arr__arr__char___arr__arr__char___fun1__test_options__arr__opt__arr__arr__char__id5___lambda0___closure _failparse_cmd_line_args__opt__test_options__arr__arr__char___arr__arr__char___fun1__test_options__arr__opt__arr__arr__char__id5___lambda0___closure() {
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


mut_dict__arr__char__arr__char* _initmut_dict__arr__char__arr__char(byte* out, mut_dict__arr__char__arr__char value) {
	mut_dict__arr__char__arr__char* res = (mut_dict__arr__char__arr__char*) out;
	*res = value;
	return res;
}
mut_dict__arr__char__arr__char _failmut_dict__arr__char__arr__char() {
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


do_test__int32__test_options___lambda0___closure* _initdo_test__int32__test_options___lambda0___closure(byte* out, do_test__int32__test_options___lambda0___closure value) {
	do_test__int32__test_options___lambda0___closure* res = (do_test__int32__test_options___lambda0___closure*) out;
	*res = value;
	return res;
}
do_test__int32__test_options___lambda0___closure _faildo_test__int32__test_options___lambda0___closure() {
	assert(0);
}


do_test__int32__test_options___lambda1___closure* _initdo_test__int32__test_options___lambda1___closure(byte* out, do_test__int32__test_options___lambda1___closure value) {
	do_test__int32__test_options___lambda1___closure* res = (do_test__int32__test_options___lambda1___closure*) out;
	*res = value;
	return res;
}
do_test__int32__test_options___lambda1___closure _faildo_test__int32__test_options___lambda1___closure() {
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


fun_ref1__int32___void* _initfun_ref1__int32___void(byte* out, fun_ref1__int32___void value) {
	fun_ref1__int32___void* res = (fun_ref1__int32___void*) out;
	*res = value;
	return res;
}
fun_ref1__int32___void _failfun_ref1__int32___void() {
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


fun_mut1__ptr_fut__int32___void* _initfun_mut1__ptr_fut__int32___void(byte* out, fun_mut1__ptr_fut__int32___void value) {
	fun_mut1__ptr_fut__int32___void* res = (fun_mut1__ptr_fut__int32___void*) out;
	*res = value;
	return res;
}
fun_mut1__ptr_fut__int32___void _failfun_mut1__ptr_fut__int32___void() {
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


fut_state_resolved___void* _initfut_state_resolved___void(byte* out, fut_state_resolved___void value) {
	fut_state_resolved___void* res = (fut_state_resolved___void*) out;
	*res = value;
	return res;
}
fut_state_resolved___void _failfut_state_resolved___void() {
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


fut_callback_node___void* _initfut_callback_node___void(byte* out, fut_callback_node___void value) {
	fut_callback_node___void* res = (fut_callback_node___void*) out;
	*res = value;
	return res;
}
fut_callback_node___void _failfut_callback_node___void() {
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


add_first_task__ptr_fut__int32__arr__ptr__char___fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char___lambda0___closure* _initadd_first_task__ptr_fut__int32__arr__ptr__char___fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char___lambda0___closure(byte* out, add_first_task__ptr_fut__int32__arr__ptr__char___fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char___lambda0___closure value) {
	add_first_task__ptr_fut__int32__arr__ptr__char___fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char___lambda0___closure* res = (add_first_task__ptr_fut__int32__arr__ptr__char___fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char___lambda0___closure*) out;
	*res = value;
	return res;
}
add_first_task__ptr_fut__int32__arr__ptr__char___fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char___lambda0___closure _failadd_first_task__ptr_fut__int32__arr__ptr__char___fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char___lambda0___closure() {
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


cell__nat* _initcell__nat(byte* out, cell__nat value) {
	cell__nat* res = (cell__nat*) out;
	*res = value;
	return res;
}
cell__nat _failcell__nat() {
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


cell__ptr__byte* _initcell__ptr__byte(byte* out, cell__ptr__byte value) {
	cell__ptr__byte* res = (cell__ptr__byte*) out;
	*res = value;
	return res;
}
cell__ptr__byte _failcell__ptr__byte() {
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


opt__chosen_task* _initopt__chosen_task(byte* out, opt__chosen_task value) {
	opt__chosen_task* res = (opt__chosen_task*) out;
	*res = value;
	return res;
}
opt__chosen_task _failopt__chosen_task() {
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


fill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat___opt__arr__arr__char___lambda0___closure* _initfill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat___opt__arr__arr__char___lambda0___closure(byte* out, fill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat___opt__arr__arr__char___lambda0___closure value) {
	fill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat___opt__arr__arr__char___lambda0___closure* res = (fill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat___opt__arr__arr__char___lambda0___closure*) out;
	*res = value;
	return res;
}
fill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat___opt__arr__arr__char___lambda0___closure _failfill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat___opt__arr__arr__char___lambda0___closure() {
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


opt__ptr__byte* _initopt__ptr__byte(byte* out, opt__ptr__byte value) {
	opt__ptr__byte* res = (opt__ptr__byte*) out;
	*res = value;
	return res;
}
opt__ptr__byte _failopt__ptr__byte() {
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


run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure* _initrun_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure(byte* out, run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure value) {
	run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure* res = (run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure*) out;
	*res = value;
	return res;
}
run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure _failrun_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure() {
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


first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda0___closure__klbdo_test__int32__test_options___lambda0___lambda0___closure* _initfirst_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda0___closure__klbdo_test__int32__test_options___lambda0___lambda0___closure(byte* out, first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda0___closure__klbdo_test__int32__test_options___lambda0___lambda0___closure value) {
	first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda0___closure__klbdo_test__int32__test_options___lambda0___lambda0___closure* res = (first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda0___closure__klbdo_test__int32__test_options___lambda0___lambda0___closure*) out;
	*res = value;
	return res;
}
first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda0___closure__klbdo_test__int32__test_options___lambda0___lambda0___closure _failfirst_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda0___closure__klbdo_test__int32__test_options___lambda0___lambda0___closure() {
	assert(0);
}


first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda1___closure__klbdo_test__int32__test_options___lambda1___lambda0___closure* _initfirst_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda1___closure__klbdo_test__int32__test_options___lambda1___lambda0___closure(byte* out, first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda1___closure__klbdo_test__int32__test_options___lambda1___lambda0___closure value) {
	first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda1___closure__klbdo_test__int32__test_options___lambda1___lambda0___closure* res = (first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda1___closure__klbdo_test__int32__test_options___lambda1___lambda0___closure*) out;
	*res = value;
	return res;
}
first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda1___closure__klbdo_test__int32__test_options___lambda1___lambda0___closure _failfirst_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda1___closure__klbdo_test__int32__test_options___lambda1___lambda0___closure() {
	assert(0);
}


then2__ptr_fut__int32__ptr_fut___void___fun_ref0__int32___lambda0___closure* _initthen2__ptr_fut__int32__ptr_fut___void___fun_ref0__int32___lambda0___closure(byte* out, then2__ptr_fut__int32__ptr_fut___void___fun_ref0__int32___lambda0___closure value) {
	then2__ptr_fut__int32__ptr_fut___void___fun_ref0__int32___lambda0___closure* res = (then2__ptr_fut__int32__ptr_fut___void___fun_ref0__int32___lambda0___closure*) out;
	*res = value;
	return res;
}
then2__ptr_fut__int32__ptr_fut___void___fun_ref0__int32___lambda0___closure _failthen2__ptr_fut__int32__ptr_fut___void___fun_ref0__int32___lambda0___closure() {
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


opt__opt__task* _initopt__opt__task(byte* out, opt__opt__task value) {
	opt__opt__task* res = (opt__opt__task*) out;
	*res = value;
	return res;
}
opt__opt__task _failopt__opt__task() {
	assert(0);
}


r_index_of__opt__nat__arr__char___char___lambda0___closure* _initr_index_of__opt__nat__arr__char___char___lambda0___closure(byte* out, r_index_of__opt__nat__arr__char___char___lambda0___closure value) {
	r_index_of__opt__nat__arr__char___char___lambda0___closure* res = (r_index_of__opt__nat__arr__char___char___lambda0___closure*) out;
	*res = value;
	return res;
}
r_index_of__opt__nat__arr__char___char___lambda0___closure _failr_index_of__opt__nat__arr__char___char___lambda0___closure() {
	assert(0);
}


_op_plus__arr__char__arr__char___arr__char___lambda0___closure* _init_op_plus__arr__char__arr__char___arr__char___lambda0___closure(byte* out, _op_plus__arr__char__arr__char___arr__char___lambda0___closure value) {
	_op_plus__arr__char__arr__char___arr__char___lambda0___closure* res = (_op_plus__arr__char__arr__char___arr__char___lambda0___closure*) out;
	*res = value;
	return res;
}
_op_plus__arr__char__arr__char___arr__char___lambda0___closure _fail_op_plus__arr__char__arr__char___arr__char___lambda0___closure() {
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


list_compile_error_tests__arr__arr__char__arr__char___lambda0___closure* _initlist_compile_error_tests__arr__arr__char__arr__char___lambda0___closure(byte* out, list_compile_error_tests__arr__arr__char__arr__char___lambda0___closure value) {
	list_compile_error_tests__arr__arr__char__arr__char___lambda0___closure* res = (list_compile_error_tests__arr__arr__char__arr__char___lambda0___closure*) out;
	*res = value;
	return res;
}
list_compile_error_tests__arr__arr__char__arr__char___lambda0___closure _faillist_compile_error_tests__arr__arr__char__arr__char___lambda0___closure() {
	assert(0);
}


flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure__klbrun_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___lambda0___closure* _initflat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure__klbrun_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___lambda0___closure(byte* out, flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure__klbrun_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___lambda0___closure value) {
	flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure__klbrun_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___lambda0___closure* res = (flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure__klbrun_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___lambda0___closure*) out;
	*res = value;
	return res;
}
flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure__klbrun_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___lambda0___closure _failflat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure__klbrun_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___lambda0___closure() {
	assert(0);
}


then__ptr_fut__int32__ptr_fut___void___fun_ref1__int32___void___lambda0___closure* _initthen__ptr_fut__int32__ptr_fut___void___fun_ref1__int32___void___lambda0___closure(byte* out, then__ptr_fut__int32__ptr_fut___void___fun_ref1__int32___void___lambda0___closure value) {
	then__ptr_fut__int32__ptr_fut___void___fun_ref1__int32___void___lambda0___closure* res = (then__ptr_fut__int32__ptr_fut___void___fun_ref1__int32___void___lambda0___closure*) out;
	*res = value;
	return res;
}
then__ptr_fut__int32__ptr_fut___void___fun_ref1__int32___void___lambda0___closure _failthen__ptr_fut__int32__ptr_fut___void___fun_ref1__int32___void___lambda0___closure() {
	assert(0);
}


map__arr__arr__char__arr__ptr__char___fun_mut1__arr__char__ptr__char__id1___lambda0___closure* _initmap__arr__arr__char__arr__ptr__char___fun_mut1__arr__char__ptr__char__id1___lambda0___closure(byte* out, map__arr__arr__char__arr__ptr__char___fun_mut1__arr__char__ptr__char__id1___lambda0___closure value) {
	map__arr__arr__char__arr__ptr__char___fun_mut1__arr__char__ptr__char__id1___lambda0___closure* res = (map__arr__arr__char__arr__ptr__char___fun_mut1__arr__char__ptr__char__id1___lambda0___closure*) out;
	*res = value;
	return res;
}
map__arr__arr__char__arr__ptr__char___fun_mut1__arr__char__ptr__char__id1___lambda0___closure _failmap__arr__arr__char__arr__ptr__char___fun_mut1__arr__char__ptr__char__id1___lambda0___closure() {
	assert(0);
}


index_of__opt__nat__arr__arr__char___arr__char___lambda0___closure* _initindex_of__opt__nat__arr__arr__char___arr__char___lambda0___closure(byte* out, index_of__opt__nat__arr__arr__char___arr__char___lambda0___closure value) {
	index_of__opt__nat__arr__arr__char___arr__char___lambda0___closure* res = (index_of__opt__nat__arr__arr__char___arr__char___lambda0___closure*) out;
	*res = value;
	return res;
}
index_of__opt__nat__arr__arr__char___arr__char___lambda0___closure _failindex_of__opt__nat__arr__arr__char___arr__char___lambda0___closure() {
	assert(0);
}


each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id9___list_compile_error_tests__arr__arr__char__arr__char___lambda0___closure__klblist_compile_error_tests__arr__arr__char__arr__char___lambda0___lambda0___closure* _initeach_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id9___list_compile_error_tests__arr__arr__char__arr__char___lambda0___closure__klblist_compile_error_tests__arr__arr__char__arr__char___lambda0___lambda0___closure(byte* out, each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id9___list_compile_error_tests__arr__arr__char__arr__char___lambda0___closure__klblist_compile_error_tests__arr__arr__char__arr__char___lambda0___lambda0___closure value) {
	each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id9___list_compile_error_tests__arr__arr__char__arr__char___lambda0___closure__klblist_compile_error_tests__arr__arr__char__arr__char___lambda0___lambda0___closure* res = (each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id9___list_compile_error_tests__arr__arr__char__arr__char___lambda0___closure__klblist_compile_error_tests__arr__arr__char__arr__char___lambda0___lambda0___closure*) out;
	*res = value;
	return res;
}
each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id9___list_compile_error_tests__arr__arr__char__arr__char___lambda0___closure__klblist_compile_error_tests__arr__arr__char__arr__char___lambda0___lambda0___closure _faileach_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id9___list_compile_error_tests__arr__arr__char__arr__char___lambda0___closure__klblist_compile_error_tests__arr__arr__char__arr__char___lambda0___lambda0___closure() {
	assert(0);
}


first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda0___closure__klbdo_test__int32__test_options___lambda0___lambda0___lambda0___closure* _initfirst_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda0___closure__klbdo_test__int32__test_options___lambda0___lambda0___lambda0___closure(byte* out, first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda0___closure__klbdo_test__int32__test_options___lambda0___lambda0___lambda0___closure value) {
	first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda0___closure__klbdo_test__int32__test_options___lambda0___lambda0___lambda0___closure* res = (first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda0___closure__klbdo_test__int32__test_options___lambda0___lambda0___lambda0___closure*) out;
	*res = value;
	return res;
}
first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda0___closure__klbdo_test__int32__test_options___lambda0___lambda0___lambda0___closure _failfirst_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda0___closure__klbdo_test__int32__test_options___lambda0___lambda0___lambda0___closure() {
	assert(0);
}


first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda1___closure__klbdo_test__int32__test_options___lambda1___lambda0___lambda0___closure* _initfirst_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda1___closure__klbdo_test__int32__test_options___lambda1___lambda0___lambda0___closure(byte* out, first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda1___closure__klbdo_test__int32__test_options___lambda1___lambda0___lambda0___closure value) {
	first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda1___closure__klbdo_test__int32__test_options___lambda1___lambda0___lambda0___closure* res = (first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda1___closure__klbdo_test__int32__test_options___lambda1___lambda0___lambda0___closure*) out;
	*res = value;
	return res;
}
first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda1___closure__klbdo_test__int32__test_options___lambda1___lambda0___lambda0___closure _failfirst_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda1___closure__klbdo_test__int32__test_options___lambda1___lambda0___lambda0___closure() {
	assert(0);
}


call__ptr_fut__int32__fun_ref0__int32___lambda0___closure* _initcall__ptr_fut__int32__fun_ref0__int32___lambda0___closure(byte* out, call__ptr_fut__int32__fun_ref0__int32___lambda0___closure value) {
	call__ptr_fut__int32__fun_ref0__int32___lambda0___closure* res = (call__ptr_fut__int32__fun_ref0__int32___lambda0___closure*) out;
	*res = value;
	return res;
}
call__ptr_fut__int32__fun_ref0__int32___lambda0___closure _failcall__ptr_fut__int32__fun_ref0__int32___lambda0___closure() {
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


task_and_nodes* _inittask_and_nodes(byte* out, task_and_nodes value) {
	task_and_nodes* res = (task_and_nodes*) out;
	*res = value;
	return res;
}
task_and_nodes _failtask_and_nodes() {
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


some__ptr_stat_t* _initsome__ptr_stat_t(byte* out, some__ptr_stat_t value) {
	some__ptr_stat_t* res = (some__ptr_stat_t*) out;
	*res = value;
	return res;
}
some__ptr_stat_t _failsome__ptr_stat_t() {
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


ptr__bool* _initptr__bool(byte* out, ptr__bool value) {
	ptr__bool* res = (ptr__bool*) out;
	*res = value;
	return res;
}
ptr__bool _failptr__bool() {
	assert(0);
}


call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda0___closure* _initcall__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda0___closure(byte* out, call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda0___closure value) {
	call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda0___closure* res = (call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda0___closure*) out;
	*res = value;
	return res;
}
call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda0___closure _failcall__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda0___closure() {
	assert(0);
}


call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda1___closure* _initcall__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda1___closure(byte* out, call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda1___closure value) {
	call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda1___closure* res = (call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda1___closure*) out;
	*res = value;
	return res;
}
call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda1___closure _failcall__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda1___closure() {
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


cell__ptr_dirent* _initcell__ptr_dirent(byte* out, cell__ptr_dirent value) {
	cell__ptr_dirent* res = (cell__ptr_dirent*) out;
	*res = value;
	return res;
}
cell__ptr_dirent _failcell__ptr_dirent() {
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


push_all___void__ptr_mut_arr__ptr_failure___arr__ptr_failure___lambda0___closure* _initpush_all___void__ptr_mut_arr__ptr_failure___arr__ptr_failure___lambda0___closure(byte* out, push_all___void__ptr_mut_arr__ptr_failure___arr__ptr_failure___lambda0___closure value) {
	push_all___void__ptr_mut_arr__ptr_failure___arr__ptr_failure___lambda0___closure* res = (push_all___void__ptr_mut_arr__ptr_failure___arr__ptr_failure___lambda0___closure*) out;
	*res = value;
	return res;
}
push_all___void__ptr_mut_arr__ptr_failure___arr__ptr_failure___lambda0___closure _failpush_all___void__ptr_mut_arr__ptr_failure___arr__ptr_failure___lambda0___closure() {
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


run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure* _initrun_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure(byte* out, run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure value) {
	run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure* res = (run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure*) out;
	*res = value;
	return res;
}
run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure _failrun_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure() {
	assert(0);
}


lint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___closure* _initlint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___closure(byte* out, lint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___closure value) {
	lint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___closure* res = (lint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___closure*) out;
	*res = value;
	return res;
}
lint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___closure _faillint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___closure() {
	assert(0);
}


forward_to___void__ptr_fut__int32___ptr_fut__int32___lambda0___closure* _initforward_to___void__ptr_fut__int32___ptr_fut__int32___lambda0___closure(byte* out, forward_to___void__ptr_fut__int32___ptr_fut__int32___lambda0___closure value) {
	forward_to___void__ptr_fut__int32___ptr_fut__int32___lambda0___closure* res = (forward_to___void__ptr_fut__int32___ptr_fut__int32___lambda0___closure*) out;
	*res = value;
	return res;
}
forward_to___void__ptr_fut__int32___ptr_fut__int32___lambda0___closure _failforward_to___void__ptr_fut__int32___ptr_fut__int32___lambda0___closure() {
	assert(0);
}


call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0___closure* _initcall__ptr_fut__int32__fun_ref1__int32___void____void___lambda0___closure(byte* out, call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0___closure value) {
	call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0___closure* res = (call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0___closure*) out;
	*res = value;
	return res;
}
call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0___closure _failcall__ptr_fut__int32__fun_ref1__int32___void____void___lambda0___closure() {
	assert(0);
}


list_runnable_tests__arr__arr__char__arr__char___lambda0___closure* _initlist_runnable_tests__arr__arr__char__arr__char___lambda0___closure(byte* out, list_runnable_tests__arr__arr__char__arr__char___lambda0___closure value) {
	list_runnable_tests__arr__arr__char__arr__char___lambda0___closure* res = (list_runnable_tests__arr__arr__char__arr__char___lambda0___closure*) out;
	*res = value;
	return res;
}
list_runnable_tests__arr__arr__char__arr__char___lambda0___closure _faillist_runnable_tests__arr__arr__char__arr__char___lambda0___closure() {
	assert(0);
}


flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure__klbrun_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___lambda0___closure* _initflat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure__klbrun_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___lambda0___closure(byte* out, flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure__klbrun_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___lambda0___closure value) {
	flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure__klbrun_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___lambda0___closure* res = (flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure__klbrun_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___lambda0___closure*) out;
	*res = value;
	return res;
}
flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure__klbrun_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___lambda0___closure _failflat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure__klbrun_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___lambda0___closure() {
	assert(0);
}


list_lintable_files__arr__arr__char__arr__char___lambda1___closure* _initlist_lintable_files__arr__arr__char__arr__char___lambda1___closure(byte* out, list_lintable_files__arr__arr__char__arr__char___lambda1___closure value) {
	list_lintable_files__arr__arr__char__arr__char___lambda1___closure* res = (list_lintable_files__arr__arr__char__arr__char___lambda1___closure*) out;
	*res = value;
	return res;
}
list_lintable_files__arr__arr__char__arr__char___lambda1___closure _faillist_lintable_files__arr__arr__char__arr__char___lambda1___closure() {
	assert(0);
}


flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___lint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___closure__klblint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___lambda0___closure* _initflat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___lint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___closure__klblint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___lambda0___closure(byte* out, flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___lint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___closure__klblint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___lambda0___closure value) {
	flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___lint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___closure__klblint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___lambda0___closure* res = (flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___lint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___closure__klblint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___lambda0___closure*) out;
	*res = value;
	return res;
}
flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___lint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___closure__klblint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___lambda0___closure _failflat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___lint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___closure__klblint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___lambda0___closure() {
	assert(0);
}


call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda0___closure* _initcall__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda0___closure(byte* out, call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda0___closure value) {
	call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda0___closure* res = (call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda0___closure*) out;
	*res = value;
	return res;
}
call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda0___closure _failcall__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda0___closure() {
	assert(0);
}


call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda1___closure* _initcall__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda1___closure(byte* out, call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda1___closure value) {
	call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda1___closure* res = (call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda1___closure*) out;
	*res = value;
	return res;
}
call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda1___closure _failcall__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda1___closure() {
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


to_mut_arr__ptr_mut_arr__arr__char__arr__arr__char___lambda0___closure* _initto_mut_arr__ptr_mut_arr__arr__char__arr__arr__char___lambda0___closure(byte* out, to_mut_arr__ptr_mut_arr__arr__char__arr__arr__char___lambda0___closure value) {
	to_mut_arr__ptr_mut_arr__arr__char__arr__arr__char___lambda0___closure* res = (to_mut_arr__ptr_mut_arr__arr__char__arr__arr__char___lambda0___closure*) out;
	*res = value;
	return res;
}
to_mut_arr__ptr_mut_arr__arr__char__arr__arr__char___lambda0___closure _failto_mut_arr__ptr_mut_arr__arr__char__arr__arr__char___lambda0___closure() {
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


mut_arr__ptr__char* _initmut_arr__ptr__char(byte* out, mut_arr__ptr__char value) {
	mut_arr__ptr__char* res = (mut_arr__ptr__char*) out;
	*res = value;
	return res;
}
mut_arr__ptr__char _failmut_arr__ptr__char() {
	assert(0);
}


each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id9___list_runnable_tests__arr__arr__char__arr__char___lambda0___closure__klblist_runnable_tests__arr__arr__char__arr__char___lambda0___lambda0___closure* _initeach_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id9___list_runnable_tests__arr__arr__char__arr__char___lambda0___closure__klblist_runnable_tests__arr__arr__char__arr__char___lambda0___lambda0___closure(byte* out, each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id9___list_runnable_tests__arr__arr__char__arr__char___lambda0___closure__klblist_runnable_tests__arr__arr__char__arr__char___lambda0___lambda0___closure value) {
	each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id9___list_runnable_tests__arr__arr__char__arr__char___lambda0___closure__klblist_runnable_tests__arr__arr__char__arr__char___lambda0___lambda0___closure* res = (each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id9___list_runnable_tests__arr__arr__char__arr__char___lambda0___closure__klblist_runnable_tests__arr__arr__char__arr__char___lambda0___lambda0___closure*) out;
	*res = value;
	return res;
}
each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id9___list_runnable_tests__arr__arr__char__arr__char___lambda0___closure__klblist_runnable_tests__arr__arr__char__arr__char___lambda0___lambda0___closure _faileach_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id9___list_runnable_tests__arr__arr__char__arr__char___lambda0___closure__klblist_runnable_tests__arr__arr__char__arr__char___lambda0___lambda0___closure() {
	assert(0);
}


each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id11___list_lintable_files__arr__arr__char__arr__char___lambda1___closure__klblist_lintable_files__arr__arr__char__arr__char___lambda1___lambda0___closure* _initeach_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id11___list_lintable_files__arr__arr__char__arr__char___lambda1___closure__klblist_lintable_files__arr__arr__char__arr__char___lambda1___lambda0___closure(byte* out, each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id11___list_lintable_files__arr__arr__char__arr__char___lambda1___closure__klblist_lintable_files__arr__arr__char__arr__char___lambda1___lambda0___closure value) {
	each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id11___list_lintable_files__arr__arr__char__arr__char___lambda1___closure__klblist_lintable_files__arr__arr__char__arr__char___lambda1___lambda0___closure* res = (each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id11___list_lintable_files__arr__arr__char__arr__char___lambda1___closure__klblist_lintable_files__arr__arr__char__arr__char___lambda1___lambda0___closure*) out;
	*res = value;
	return res;
}
each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id11___list_lintable_files__arr__arr__char__arr__char___lambda1___closure__klblist_lintable_files__arr__arr__char__arr__char___lambda1___lambda0___closure _faileach_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id11___list_lintable_files__arr__arr__char__arr__char___lambda1___closure__klblist_lintable_files__arr__arr__char__arr__char___lambda1___lambda0___closure() {
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


pollfd* _initpollfd(byte* out, pollfd value) {
	pollfd* res = (pollfd*) out;
	*res = value;
	return res;
}
pollfd _failpollfd() {
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


ptr__pollfd* _initptr__pollfd(byte* out, ptr__pollfd value) {
	ptr__pollfd* res = (ptr__pollfd*) out;
	*res = value;
	return res;
}
ptr__pollfd _failptr__pollfd() {
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


convert_environ__ptr__ptr__char__ptr_dict__arr__char__arr__char___lambda0___closure* _initconvert_environ__ptr__ptr__char__ptr_dict__arr__char__arr__char___lambda0___closure(byte* out, convert_environ__ptr__ptr__char__ptr_dict__arr__char__arr__char___lambda0___closure value) {
	convert_environ__ptr__ptr__char__ptr_dict__arr__char__arr__char___lambda0___closure* res = (convert_environ__ptr__ptr__char__ptr_dict__arr__char__arr__char___lambda0___closure*) out;
	*res = value;
	return res;
}
convert_environ__ptr__ptr__char__ptr_dict__arr__char__arr__char___lambda0___closure _failconvert_environ__ptr__ptr__char__ptr_dict__arr__char__arr__char___lambda0___closure() {
	assert(0);
}


map__arr__ptr__char__arr__arr__char___fun_mut1__ptr__char__arr__char__id10___lambda0___closure* _initmap__arr__ptr__char__arr__arr__char___fun_mut1__ptr__char__arr__char__id10___lambda0___closure(byte* out, map__arr__ptr__char__arr__arr__char___fun_mut1__ptr__char__arr__char__id10___lambda0___closure value) {
	map__arr__ptr__char__arr__arr__char___fun_mut1__ptr__char__arr__char__id10___lambda0___closure* res = (map__arr__ptr__char__arr__arr__char___fun_mut1__ptr__char__arr__char__id10___lambda0___closure*) out;
	*res = value;
	return res;
}
map__arr__ptr__char__arr__arr__char___fun_mut1__ptr__char__arr__char__id10___lambda0___closure _failmap__arr__ptr__char__arr__arr__char___fun_mut1__ptr__char__arr__char__id10___lambda0___closure() {
	assert(0);
}


_op_plus__arr__ptr__char__arr__ptr__char___arr__ptr__char___lambda0___closure* _init_op_plus__arr__ptr__char__arr__ptr__char___arr__ptr__char___lambda0___closure(byte* out, _op_plus__arr__ptr__char__arr__ptr__char___arr__ptr__char___lambda0___closure value) {
	_op_plus__arr__ptr__char__arr__ptr__char___arr__ptr__char___lambda0___closure* res = (_op_plus__arr__ptr__char__arr__ptr__char___arr__ptr__char___lambda0___closure*) out;
	*res = value;
	return res;
}
_op_plus__arr__ptr__char__arr__ptr__char___arr__ptr__char___lambda0___closure _fail_op_plus__arr__ptr__char__arr__ptr__char___arr__ptr__char___lambda0___closure() {
	assert(0);
}


lint_file__arr__ptr_failure__arr__char___lambda0___closure* _initlint_file__arr__ptr_failure__arr__char___lambda0___closure(byte* out, lint_file__arr__ptr_failure__arr__char___lambda0___closure value) {
	lint_file__arr__ptr_failure__arr__char___lambda0___closure* res = (lint_file__arr__ptr_failure__arr__char___lambda0___closure*) out;
	*res = value;
	return res;
}
lint_file__arr__ptr_failure__arr__char___lambda0___closure _faillint_file__arr__ptr_failure__arr__char___lambda0___closure() {
	assert(0);
}


lines__arr__arr__char__arr__char___lambda0___closure* _initlines__arr__arr__char__arr__char___lambda0___closure(byte* out, lines__arr__arr__char__arr__char___lambda0___closure value) {
	lines__arr__arr__char__arr__char___lambda0___closure* res = (lines__arr__arr__char__arr__char___lambda0___closure*) out;
	*res = value;
	return res;
}
lines__arr__arr__char__arr__char___lambda0___closure _faillines__arr__arr__char__arr__char___lambda0___closure() {
	assert(0);
}


_op_plus__arr__char__arr__char__id23___arr__char__id29___lambda0___closure* _init_op_plus__arr__char__arr__char__id23___arr__char__id29___lambda0___closure(byte* out, _op_plus__arr__char__arr__char__id23___arr__char__id29___lambda0___closure value) {
	_op_plus__arr__char__arr__char__id23___arr__char__id29___lambda0___closure* res = (_op_plus__arr__char__arr__char__id23___arr__char__id29___lambda0___closure*) out;
	*res = value;
	return res;
}
_op_plus__arr__char__arr__char__id23___arr__char__id29___lambda0___closure _fail_op_plus__arr__char__arr__char__id23___arr__char__id29___lambda0___closure() {
	assert(0);
}

void* _failVoidPtr() { assert(0); }
int32 rt_main__int32__int32___ptr__ptr__char___fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char_(int32 argc, ptr__ptr__char argv, fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char main_ptr);
fut__int32* main__ptr_fut__int32__arr__arr__char_(ctx* _ctx, arr__arr__char args);
lock new_lock__lock();
condition new_condition__condition();
global_ctx* ref_of_val__ptr_global_ctx__global_ctx_(global_ctx b);
vat new_vat__vat__ptr_global_ctx___nat___nat_(global_ctx* gctx, nat id, nat max_threads);
vat* ref_of_val__ptr_vat__vat_(vat b);
ptr__ptr_vat ptr_to__ptr__ptr_vat__ptr_vat_(vat* t);
exception_ctx new_exception_ctx__exception_ctx();
exception_ctx* ref_of_val__ptr_exception_ctx__exception_ctx_(exception_ctx b);
ctx new_ctx__ctx__ptr_global_ctx___ptr_thread_local_stuff___ptr_vat___nat_(global_ctx* gctx, thread_local_stuff* tls, vat* vat, nat actor_id);
thread_local_stuff* ref_of_val__ptr_thread_local_stuff__thread_local_stuff_(thread_local_stuff b);
ctx* ref_of_val__ptr_ctx__ctx_(ctx b);
fun2__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char as_non_const__fun2__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__fun2__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char_(fun2__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char value);
fut__int32* add_first_task__ptr_fut__int32__arr__ptr__char___fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char___asLambda____dynamic(ctx* _ctx, ptr__byte __unused, arr__ptr__char all_args, fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char main_ptr);
nat unsafe_to_nat__nat___int_(_int a);
_int to_int___int__int32_(int32 i);
fut__int32* call_with_ctx__ptr_fut__int32__ptr_ctx___fun2__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char___arr__ptr__char___fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char_(ctx* c, fun2__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char f, arr__ptr__char p0, fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char p1);
_void run_threads___void__nat___ptr_global_ctx___fun_ptr2___void__nat__ptr_global_ctx_(nat n_threads, global_ctx* arg, fun_ptr2___void__nat__ptr_global_ctx fun);
result__int32__exception must_be_resolved__result__int32__exception__ptr_fut__int32_(fut__int32* f);
_void print_err_sync_no_newline___void__arr__char_(arr__char s);
_void print_err_sync___void__arr__char_(arr__char s);
_void thread_function___void__nat___ptr_global_ctx_(nat thread_id, global_ctx* gctx);
opt__test_options parse_cmd_line_args__opt__test_options__arr__arr__char___arr__arr__char___fun1__test_options__arr__opt__arr__arr__char__id5_(ctx* _ctx, arr__arr__char args, arr__arr__char t_names);
fut__int32* resolved__ptr_fut__int32__int32_(ctx* _ctx, int32 value);
_void print_help___void(ctx* _ctx);
int32 do_test__int32__test_options_(ctx* _ctx, test_options options);
_atomic_bool new_atomic_bool___atomic_bool();
mut_arr__nat new_mut_arr_by_val_with_capacity_from_unmanaged_memory__mut_arr__nat__nat_(nat capacity);
gc new_gc__gc();
mut_bag__task new_mut_bag__mut_bag__task();
thread_safe_counter new_thread_safe_counter__thread_safe_counter();
_void default_exception_handler___void__exception___asLambda___dynamic(ctx* _ctx, ptr__byte __unused, exception e);
ptr__byte as_any_ptr__ptr__byte__ptr_global_ctx_(global_ctx* some_ref);
ptr__byte as_any_ptr__ptr__byte__ptr_gc_ctx_(gc_ctx* some_ref);
gc_ctx* get_gc_ctx__ptr_gc_ctx__ptr_gc_(gc* gc);
gc* ref_of_val__ptr_gc__gc_(gc b);
ptr__byte as_any_ptr__ptr__byte__ptr_exception_ctx_(exception_ctx* some_ref);
fut__int32* add_first_task__ptr_fut__int32__arr__ptr__char___fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char_(ctx* _ctx, arr__ptr__char all_args, fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char main_ptr);
fut__int32* call__ptr_fut__int32__fun_ptr4__ptr_fut__int32__ptr_ctx__ptr__byte__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char___ptr_ctx___ptr__byte___arr__ptr__char___fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char_(fun_ptr4__ptr_fut__int32__ptr_ctx__ptr__byte__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char f, ctx* p0, ptr__byte p1, arr__ptr__char p2, fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char p3);
ptr__nat unmanaged_alloc_elements__ptr__nat__nat_(nat size_elements);
ptr__thread_args__ptr_global_ctx unmanaged_alloc_elements__ptr__thread_args__ptr_global_ctx__nat_(nat size_elements);
_void run_threads_recur___void__nat___nat___ptr__nat___ptr__thread_args__ptr_global_ctx___ptr_global_ctx___fun_ptr2___void__nat__ptr_global_ctx_(nat i, nat n_threads, ptr__nat threads, ptr__thread_args__ptr_global_ctx thread_args, global_ctx* arg, fun_ptr2___void__nat__ptr_global_ctx fun);
_void join_threads_recur___void__nat___nat___ptr__nat_(nat i, nat n_threads, ptr__nat threads);
_void unmanaged_free___void__ptr__nat_(ptr__nat p);
_void unmanaged_free___void__ptr__thread_args__ptr_global_ctx_(ptr__thread_args__ptr_global_ctx p);
result__int32__exception hard_unreachable__result__int32__exception();
ok__int32 ok__ok__int32__int32_(int32 t);
err__exception err__err__exception__exception_(exception t);
_void write_sync_no_newline___void__int32___arr__char_(int32 fd, arr__char s);
thread_local_stuff as__thread_local_stuff__thread_local_stuff_(thread_local_stuff value);
_void thread_function_recur___void__nat___ptr_global_ctx___ptr_thread_local_stuff_(nat thread_id, global_ctx* gctx, thread_local_stuff* tls);
parsed_cmd_line_args* parse_cmd_line_args_dynamic__ptr_parsed_cmd_line_args__arr__arr__char_(ctx* _ctx, arr__arr__char args);
_void assert___void__bool___arr__char_(ctx* _ctx, bool condition, arr__char message);
bool empty__q__bool__arr__arr__char_(arr__arr__char a);
_void assert___void__bool_(ctx* _ctx, bool condition);
mut_arr__opt__arr__arr__char* fill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat___opt__arr__arr__char_(ctx* _ctx, nat size, opt__arr__arr__char value);
cell__bool* new_cell__ptr_cell__bool__bool__id1_(ctx* _ctx);
_void each___void__ptr_dict__arr__char__arr__arr__char___parse_cmd_line_args__opt__test_options__arr__arr__char___arr__arr__char___fun1__test_options__arr__opt__arr__arr__char__id5___lambda0___closure__klbparse_cmd_line_args__opt__test_options__arr__arr__char___arr__arr__char___fun1__test_options__arr__opt__arr__arr__char__id5___lambda0_(ctx* _ctx, dict__arr__char__arr__arr__char* d, parse_cmd_line_args__opt__test_options__arr__arr__char___arr__arr__char___fun1__test_options__arr__opt__arr__arr__char__id5___lambda0___closure f);
bool get__bool__ptr_cell__bool_(cell__bool* c);
some__test_options some__some__test_options__test_options_(test_options t);
test_options main__ptr_fut__int32__arr__arr__char___lambda0_(ctx* _ctx, arr__opt__arr__arr__char values);
arr__opt__arr__arr__char freeze__arr__opt__arr__arr__char__ptr_mut_arr__opt__arr__arr__char_(mut_arr__opt__arr__arr__char* a);
ptr__byte alloc__ptr__byte__nat_(ctx* _ctx, nat size);
_void print_sync___void__arr__char_(arr__char s);
arr__char parent_path__arr__char__arr__char_(ctx* _ctx, arr__char a);
arr__char current_executable_path__arr__char(ctx* _ctx);
arr__char child_path__arr__char__arr__char___arr__char_(ctx* _ctx, arr__char a, arr__char child_name);
dict__arr__char__arr__char* get_environ__ptr_dict__arr__char__arr__char(ctx* _ctx);
result__arr__char__arr__ptr_failure run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options_(ctx* _ctx, arr__char path, arr__char path_to_noze, dict__arr__char__arr__char* env, test_options options);
result__arr__char__arr__ptr_failure first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda0___closure__klbdo_test__int32__test_options___lambda0_(ctx* _ctx, result__arr__char__arr__ptr_failure a, do_test__int32__test_options___lambda0___closure b);
result__arr__char__arr__ptr_failure first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda1___closure__klbdo_test__int32__test_options___lambda1_(ctx* _ctx, result__arr__char__arr__ptr_failure a, do_test__int32__test_options___lambda1___closure b);
int32 print_failures__int32__result__arr__char__arr__ptr_failure___test_options_(ctx* _ctx, result__arr__char__arr__ptr_failure failures, test_options options);
thread_safe_counter new_thread_safe_counter__thread_safe_counter__nat__id0_();
_void default_exception_handler___void__exception_(ctx* _ctx, exception e);
_void acquire_lock___void__ptr_lock_(lock* l);
lock* ref_of_val__ptr_lock__lock_(lock b);
gc_ctx* as_ref__ptr_gc_ctx__ptr__byte_(ptr__byte p);
extern ptr__byte malloc(nat size);
_void release_lock___void__ptr_lock_(lock* l);
fut__int32* then2__ptr_fut__int32__ptr_fut___void___fun_ref0__int32_(ctx* _ctx, fut___void* f, fun_ref0__int32 cb);
fut___void* as__ptr_fut___void__ptr_fut___void_(fut___void* value);
fut___void* resolved__ptr_fut___void___void__id0_(ctx* _ctx);
vat_and_actor_id cur_actor__vat_and_actor_id(ctx* _ctx);
fut__int32* add_first_task__ptr_fut__int32__arr__ptr__char___fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char___lambda0__dynamic(ctx* _ctx, add_first_task__ptr_fut__int32__arr__ptr__char___fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char___lambda0___closure* _closure);
ptr__byte unmanaged_alloc_bytes__ptr__byte__nat_(nat size);
nat wrap_mul__nat__nat___nat_(nat a, nat b);
ptr__nat ptr_cast__ptr__nat__ptr__byte_(ptr__byte p);
ptr__thread_args__ptr_global_ctx ptr_cast__ptr__thread_args__ptr_global_ctx__ptr__byte_(ptr__byte p);
bool _op_equal_equal__bool__nat___nat_(nat a, nat b);
ptr__thread_args__ptr_global_ctx _op_plus__ptr__thread_args__ptr_global_ctx__ptr__thread_args__ptr_global_ctx___nat_(ptr__thread_args__ptr_global_ctx p, nat offset);
_void set___void__ptr__thread_args__ptr_global_ctx___thread_args__ptr_global_ctx_(ptr__thread_args__ptr_global_ctx p, thread_args__ptr_global_ctx value);
ptr__nat _op_plus__ptr__nat__ptr__nat___nat_(ptr__nat p, nat offset);
extern int32 pthread_create(cell__nat* thread, ptr__byte attr, fun_ptr1__ptr__byte__ptr__byte start_routine, ptr__byte arg);
cell__nat* as_cell__ptr_cell__nat__ptr__nat_(ptr__nat p);
ptr__byte as_any_ptr__ptr__byte__ptr__thread_args__ptr_global_ctx_(ptr__thread_args__ptr_global_ctx some_ref);
bool zero__q__bool__int32_(int32 i);
nat noctx_incr__nat__nat_(nat n);
bool _op_equal_equal__bool__int32___int32_(int32 a, int32 b);
_void todo___void();
ptr__byte thread_fun__ptr__byte__ptr__byte_(ptr__byte args_ptr);
_void join_one_thread___void__nat_(nat tid);
nat deref__nat__ptr__nat_(ptr__nat p);
extern void free(ptr__byte p);
ptr__byte ptr_cast__ptr__byte__ptr__nat_(ptr__nat p);
ptr__byte ptr_cast__ptr__byte__ptr__thread_args__ptr_global_ctx_(ptr__thread_args__ptr_global_ctx p);
result__int32__exception hard_fail__result__int32__exception__arr__char__id12_();
extern _int write(int32 fd, ptr__byte buff, nat n_bytes);
ptr__byte as_any_ptr__ptr__byte__ptr__char_(ptr__char some_ref);
bool _op_equal_equal__bool___int____int_(_int a, _int b);
_int unsafe_to_int___int__nat_(nat a);
nat noctx_decr__nat__nat_(nat n);
_void assert_vats_are_shut_down___void__nat___arr__ptr_vat_(nat i, arr__ptr_vat vats);
_void hard_assert___void__bool_(bool condition);
bool _op_greater__bool__nat___nat_(nat a, nat b);
nat get_last_checked__nat__ptr_condition_(condition* c);
condition* ref_of_val__ptr_condition__condition_(condition b);
result__chosen_task__no_chosen_task choose_task__result__chosen_task__no_chosen_task__ptr_global_ctx_(global_ctx* gctx);
_void do_task___void__ptr_global_ctx___ptr_thread_local_stuff___chosen_task_(global_ctx* gctx, thread_local_stuff* tls, chosen_task chosen_task);
_void hard_forbid___void__bool_(bool condition);
_void broadcast___void__ptr_condition_(condition* c);
_void wait_on___void__ptr_condition___nat_(condition* c, nat last_checked);
opt__nat find_index__opt__nat__arr__arr__char___fun_mut1__bool__arr__char__id6_(ctx* _ctx, arr__arr__char a);
arr__arr__char slice_up_to__arr__arr__char__arr__arr__char___nat_(ctx* _ctx, arr__arr__char a, nat size);
arr__arr__char slice_starting_at__arr__arr__char__arr__arr__char___nat_(ctx* _ctx, arr__arr__char a, nat begin);
opt__nat find_index__opt__nat__arr__arr__char___fun_mut1__bool__arr__char__id7_(ctx* _ctx, arr__arr__char a);
dict__arr__char__arr__arr__char* parse_named_args__ptr_dict__arr__char__arr__arr__char__arr__arr__char_(ctx* _ctx, arr__arr__char args);
arr__arr__char slice_after__arr__arr__char__arr__arr__char___nat_(ctx* _ctx, arr__arr__char a, nat before_begin);
_void if___void__bool____void____void_(bool cond, _void if_true, _void if_false);
_void fail___void__arr__char_(ctx* _ctx, arr__char reason);
bool zero__q__bool__nat_(nat n);
mut_arr__opt__arr__arr__char* make_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat___fill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat___opt__arr__arr__char___lambda0___closure__klbfill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat___opt__arr__arr__char___lambda0_(ctx* _ctx, nat size, fill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat___opt__arr__arr__char___lambda0___closure f);
bool empty__q__bool__ptr_dict__arr__char__arr__arr__char_(ctx* _ctx, dict__arr__char__arr__arr__char* d);
_void parse_cmd_line_args__opt__test_options__arr__arr__char___arr__arr__char___fun1__test_options__arr__opt__arr__arr__char__id5___lambda0__(ctx* _ctx, parse_cmd_line_args__opt__test_options__arr__arr__char___arr__arr__char___fun1__test_options__arr__opt__arr__arr__char__id5___lambda0___closure _closure, arr__char key, arr__arr__char value);
arr__char first__arr__char__arr__arr__char_(ctx* _ctx, arr__arr__char a);
arr__arr__char first__arr__arr__char__arr__arr__arr__char_(ctx* _ctx, arr__arr__arr__char a);
arr__arr__char tail__arr__arr__char__arr__arr__char_(ctx* _ctx, arr__arr__char a);
arr__arr__arr__char tail__arr__arr__arr__char__arr__arr__arr__char_(ctx* _ctx, arr__arr__arr__char a);
opt__arr__arr__char at__opt__arr__arr__char__arr__opt__arr__arr__char___nat_(ctx* _ctx, arr__opt__arr__arr__char a, nat index);
bool has__q__bool__opt__arr__arr__char_(opt__arr__arr__char a);
nat as__nat__nat_(nat value);
nat literal__nat__arr__char_(ctx* _ctx, arr__char s);
arr__opt__arr__arr__char unsafe_as_arr__arr__opt__arr__arr__char__ptr_mut_arr__opt__arr__arr__char_(mut_arr__opt__arr__arr__char* a);
ptr__byte gc_alloc__ptr__byte__ptr_gc___nat_(ctx* _ctx, gc* gc, nat size);
gc* get_gc__ptr_gc(ctx* _ctx);
_void print_sync_no_newline___void__arr__char_(arr__char s);
opt__nat r_index_of__opt__nat__arr__char___char_(ctx* _ctx, arr__char a, char value);
arr__char slice_up_to__arr__char__arr__char___nat_(ctx* _ctx, arr__char a, nat size);
arr__char read_link__arr__char__arr__char_(ctx* _ctx, arr__char path);
arr__char _op_plus__arr__char__arr__char___arr__char_(ctx* _ctx, arr__char a, arr__char b);
mut_dict__arr__char__arr__char new_mut_dict__mut_dict__arr__char__arr__char(ctx* _ctx);
_void get_environ_recur___void__ptr__ptr__char___mut_dict__arr__char__arr__char_(ctx* _ctx, ptr__ptr__char env, mut_dict__arr__char__arr__char res);
extern ptr__ptr__char environ;
dict__arr__char__arr__char* freeze__ptr_dict__arr__char__arr__char__mut_dict__arr__char__arr__char_(ctx* _ctx, mut_dict__arr__char__arr__char m);
arr__arr__char list_compile_error_tests__arr__arr__char__arr__char_(ctx* _ctx, arr__char path);
arr__ptr_failure flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure__klbrun_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0_(ctx* _ctx, arr__arr__char a, nat max_size, run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure mapper);
bool has__q__bool__arr__ptr_failure_(arr__ptr_failure a);
err__arr__ptr_failure err__err__arr__ptr_failure__arr__ptr_failure_(arr__ptr_failure t);
arr__ptr_failure with_max_size__arr__ptr_failure__arr__ptr_failure___nat_(ctx* _ctx, arr__ptr_failure a, nat max_size);
ok__arr__char ok__ok__arr__char__arr__char_(arr__char t);
arr__char to_str__arr__char__nat_(ctx* _ctx, nat n);
result__arr__char__arr__ptr_failure then__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda0___closure__klbdo_test__int32__test_options___lambda0___lambda0___closure__klbfirst_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda0___closure__klbdo_test__int32__test_options___lambda0___lambda0_(ctx* _ctx, result__arr__char__arr__ptr_failure a, first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda0___closure__klbdo_test__int32__test_options___lambda0___lambda0___closure f);
result__arr__char__arr__ptr_failure then__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda1___closure__klbdo_test__int32__test_options___lambda1___lambda0___closure__klbfirst_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda1___closure__klbdo_test__int32__test_options___lambda1___lambda0_(ctx* _ctx, result__arr__char__arr__ptr_failure a, first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda1___closure__klbdo_test__int32__test_options___lambda1___lambda0___closure f);
_void each___void__arr__ptr_failure___fun_mut1___void__ptr_failure__id12_(ctx* _ctx, arr__ptr_failure a);
int32 to_int32__int32__nat_(ctx* _ctx, nat n);
arr__char if__arr__char__bool___arr__char___arr__char_(bool cond, arr__char if_true, arr__char if_false);
bool empty__q__bool__arr__char_(arr__char a);
global_ctx* get_gctx__ptr_global_ctx(ctx* _ctx);
_void acquire_lock_recur___void__ptr_lock___nat_(lock* l, nat n_tries);
_void must_unset___void__ptr__atomic_bool_(_atomic_bool* a);
_atomic_bool* ref_of_val__ptr__atomic_bool___atomic_bool_(_atomic_bool b);
fut__int32* then__ptr_fut__int32__ptr_fut___void___fun_ref1__int32___void_(ctx* _ctx, fut___void* f, fun_ref1__int32___void cb);
fut__int32* then2__ptr_fut__int32__ptr_fut___void___fun_ref0__int32___lambda0___dynamic(ctx* _ctx, then2__ptr_fut__int32__ptr_fut___void___fun_ref0__int32___lambda0___closure* _closure, _void ignore);
ctx* get_ctx__ptr_ctx(ctx* _ctx);
arr__ptr__char tail__arr__ptr__char__arr__ptr__char_(ctx* _ctx, arr__ptr__char a);
fut__int32* call__ptr_fut__int32__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char___ptr_ctx___arr__arr__char_(fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char f, ctx* p0, arr__arr__char p1);
arr__arr__char map__arr__arr__char__arr__ptr__char___fun_mut1__arr__char__ptr__char__id1_(ctx* _ctx, arr__ptr__char a);
bool null__q__bool__ptr__byte_(ptr__byte a);
comparison _op_less_equal_greater__comparison__nat___nat_(nat a, nat b);
cell__nat* as_ref__ptr_cell__nat__ptr__byte_(ptr__byte p);
ptr__byte as_any_ptr__ptr__byte__ptr__nat_(ptr__nat some_ref);
bool _op_less__bool__nat___nat_(nat a, nat b);
nat wrap_incr__nat__nat_(nat a);
comparison _op_less_equal_greater__comparison__int32___int32_(int32 a, int32 b);
_void hard_fail___void__arr__char__id2_();
thread_args__ptr_global_ctx* as_ref__ptr_thread_args__ptr_global_ctx__ptr__byte_(ptr__byte p);
_void call___void__fun_ptr2___void__nat__ptr_global_ctx___nat___ptr_global_ctx_(fun_ptr2___void__nat__ptr_global_ctx f, nat p0, global_ctx* p1);
extern int32 pthread_join(nat thread, cell__ptr__byte* thread_return);
cell__ptr__byte* ref_of_val__ptr_cell__ptr__byte__cell__ptr__byte_(cell__ptr__byte b);
bool _op_equal_equal__bool__ptr__byte___ptr__byte_(ptr__byte a, ptr__byte b);
ptr__byte get__ptr__byte__ptr_cell__ptr__byte_(cell__ptr__byte* c);
comparison _op_less_equal_greater__comparison___int____int_(_int a, _int b);
nat wrap_sub__nat__nat___nat_(nat a, nat b);
vat* noctx_at__ptr_vat__arr__ptr_vat___nat_(arr__ptr_vat a, nat index);
bool empty__q__bool__ptr_mut_bag__task_(mut_bag__task* m);
mut_bag__task* ref_of_val__ptr_mut_bag__task__mut_bag__task_(mut_bag__task b);
_void hard_fail___void__arr__char__id0_();
bool not__bool__bool_(bool a);
bool _op_less_equal__bool__nat___nat_(nat a, nat b);
result__chosen_task__no_chosen_task as__result__chosen_task__no_chosen_task__result__chosen_task__no_chosen_task_(result__chosen_task__no_chosen_task value);
opt__chosen_task choose_task_recur__opt__chosen_task__arr__ptr_vat___nat_(arr__ptr_vat vats, nat i);
err__no_chosen_task err__err__no_chosen_task__no_chosen_task_(no_chosen_task t);
ok__chosen_task ok__ok__chosen_task__chosen_task_(chosen_task t);
_void call_with_ctx___void__ptr_ctx___fun_mut0___void_(ctx* c, fun_mut0___void f);
_void noctx_must_remove_unordered___void__ptr_mut_arr__nat___nat_(mut_arr__nat* a, nat value);
mut_arr__nat* ref_of_val__ptr_mut_arr__nat__mut_arr__nat_(mut_arr__nat b);
_void return_ctx___void__ptr_ctx_(ctx* c);
_void yield_thread___void();
opt__nat find_index_recur__opt__nat__arr__arr__char___nat___fun_mut1__bool__arr__char__id6_(ctx* _ctx, arr__arr__char a, nat index);
arr__arr__char slice__arr__arr__char__arr__arr__char___nat___nat_(ctx* _ctx, arr__arr__char a, nat begin, nat size);
nat _op_minus__nat__nat___nat_(ctx* _ctx, nat a, nat b);
opt__nat find_index_recur__opt__nat__arr__arr__char___nat___fun_mut1__bool__arr__char__id7_(ctx* _ctx, arr__arr__char a, nat index);
mut_dict__arr__char__arr__arr__char new_mut_dict__mut_dict__arr__char__arr__arr__char(ctx* _ctx);
_void parse_named_args_recur___void__arr__arr__char___mut_dict__arr__char__arr__arr__char_(ctx* _ctx, arr__arr__char args, mut_dict__arr__char__arr__arr__char builder);
dict__arr__char__arr__arr__char* freeze__ptr_dict__arr__char__arr__arr__char__mut_dict__arr__char__arr__arr__char_(ctx* _ctx, mut_dict__arr__char__arr__arr__char m);
nat incr__nat__nat_(ctx* _ctx, nat n);
_void throw___void__exception_(ctx* _ctx, exception e);
mut_arr__opt__arr__arr__char* new_uninitialized_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat_(ctx* _ctx, nat size);
_void make_mut_arr_worker___void__ptr_mut_arr__opt__arr__arr__char___nat___fill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat___opt__arr__arr__char___lambda0___closure__klbfill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat___opt__arr__arr__char___lambda0_(ctx* _ctx, mut_arr__opt__arr__arr__char* m, nat i, fill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat___opt__arr__arr__char___lambda0___closure f);
opt__nat index_of__opt__nat__arr__arr__char___arr__char_(ctx* _ctx, arr__arr__char a, arr__char value);
bool _op_equal_equal__bool__arr__char___arr__char_(arr__char a, arr__char b);
_void set___void__ptr_cell__bool___bool_(cell__bool* c, bool v);
_void forbid___void__bool_(ctx* _ctx, bool condition);
opt__arr__arr__char at__opt__arr__arr__char__ptr_mut_arr__opt__arr__arr__char___nat_(ctx* _ctx, mut_arr__opt__arr__arr__char* a, nat index);
_void set_at___void__ptr_mut_arr__opt__arr__arr__char___nat___opt__arr__arr__char_(ctx* _ctx, mut_arr__opt__arr__arr__char* a, nat index, opt__arr__arr__char value);
some__arr__arr__char some__some__arr__arr__char__arr__arr__char_(arr__arr__char t);
arr__char at__arr__char__arr__arr__char___nat_(ctx* _ctx, arr__arr__char a, nat index);
bool empty__q__bool__arr__arr__arr__char_(arr__arr__arr__char a);
arr__arr__char at__arr__arr__char__arr__arr__arr__char___nat_(ctx* _ctx, arr__arr__arr__char a, nat index);
arr__arr__arr__char slice_starting_at__arr__arr__arr__char__arr__arr__arr__char___nat_(ctx* _ctx, arr__arr__arr__char a, nat begin);
opt__arr__arr__char noctx_at__opt__arr__arr__char__arr__opt__arr__arr__char___nat_(arr__opt__arr__arr__char a, nat index);
bool empty__q__bool__opt__arr__arr__char_(opt__arr__arr__char a);
arr__char rtail__arr__char__arr__char_(ctx* _ctx, arr__char a);
nat _op_plus__nat__nat___nat_(ctx* _ctx, nat a, nat b);
nat _op_times__nat__nat___nat_(ctx* _ctx, nat a, nat b);
nat char_to_nat__nat__char_(char c);
char last__char__arr__char_(ctx* _ctx, arr__char a);
opt__ptr__byte try_gc_alloc__opt__ptr__byte__ptr_gc___nat_(gc* gc, nat size);
ptr__byte todo__ptr__byte();
gc_ctx* get_gc_ctx__ptr_gc_ctx(ctx* _ctx);
opt__nat find_rindex__opt__nat__arr__char___r_index_of__opt__nat__arr__char___char___lambda0___closure__klbr_index_of__opt__nat__arr__char___char___lambda0_(ctx* _ctx, arr__char a, r_index_of__opt__nat__arr__char___char___lambda0___closure pred);
arr__char slice__arr__char__arr__char___nat___nat_(ctx* _ctx, arr__char a, nat begin, nat size);
mut_arr__char* new_uninitialized_mut_arr__ptr_mut_arr__char__nat__id1000_(ctx* _ctx);
extern _int readlink(ptr__char path, ptr__char buf, nat len);
ptr__char to_c_str__ptr__char__arr__char_(ctx* _ctx, arr__char a);
_void check_errno_if_neg_one___void___int_(ctx* _ctx, _int e);
arr__char freeze__arr__char__ptr_mut_arr__char_(mut_arr__char* a);
nat to_nat__nat___int_(ctx* _ctx, _int i);
arr__char make_arr__arr__char__nat____op_plus__arr__char__arr__char___arr__char___lambda0___closure__klb_op_plus__arr__char__arr__char___arr__char___lambda0_(ctx* _ctx, nat size, _op_plus__arr__char__arr__char___arr__char___lambda0___closure f);
mut_arr__arr__char* new_mut_arr__ptr_mut_arr__arr__char(ctx* _ctx);
bool null__q__bool__ptr__char_(ptr__char a);
ptr__char deref__ptr__char__ptr__ptr__char_(ptr__ptr__char p);
_void add___void__mut_dict__arr__char__arr__char___ptr_key_value_pair__arr__char__arr__char_(ctx* _ctx, mut_dict__arr__char__arr__char m, key_value_pair__arr__char__arr__char* pair);
key_value_pair__arr__char__arr__char* parse_environ_entry__ptr_key_value_pair__arr__char__arr__char__ptr__char_(ctx* _ctx, ptr__char entry);
ptr__ptr__char incr__ptr__ptr__char__ptr__ptr__char_(ptr__ptr__char p);
arr__arr__char freeze__arr__arr__char__ptr_mut_arr__arr__char_(mut_arr__arr__char* a);
_void each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id9___list_compile_error_tests__arr__arr__char__arr__char___lambda0___closure__klblist_compile_error_tests__arr__arr__char__arr__char___lambda0_(ctx* _ctx, arr__char path, list_compile_error_tests__arr__arr__char__arr__char___lambda0___closure f);
mut_arr__ptr_failure* new_mut_arr__ptr_mut_arr__ptr_failure(ctx* _ctx);
_void each___void__arr__arr__char___flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure__klbrun_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___lambda0___closure__klbflat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure__klbrun_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___lambda0_(ctx* _ctx, arr__arr__char a, flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure__klbrun_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___lambda0___closure f);
arr__ptr_failure freeze__arr__ptr_failure__ptr_mut_arr__ptr_failure_(mut_arr__ptr_failure* a);
bool empty__q__bool__arr__ptr_failure_(arr__ptr_failure a);
arr__ptr_failure slice__arr__ptr_failure__arr__ptr_failure___nat___nat_(ctx* _ctx, arr__ptr_failure a, nat begin, nat size);
nat _op_div__nat__nat___nat_(ctx* _ctx, nat a, nat b);
nat mod__nat__nat___nat_(ctx* _ctx, nat a, nat b);
result__arr__char__arr__ptr_failure first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda0___closure__klbdo_test__int32__test_options___lambda0___lambda0_(ctx* _ctx, first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda0___closure__klbdo_test__int32__test_options___lambda0___lambda0___closure _closure, arr__char a_descr);
result__arr__char__arr__ptr_failure first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda1___closure__klbdo_test__int32__test_options___lambda1___lambda0_(ctx* _ctx, first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda1___closure__klbdo_test__int32__test_options___lambda1___lambda0___closure _closure, arr__char a_descr);
_void print_failure___void__ptr_failure___asLambda_(ctx* _ctx, failure* failure);
failure* first__ptr_failure__arr__ptr_failure_(ctx* _ctx, arr__ptr_failure a);
arr__ptr_failure tail__arr__ptr_failure__arr__ptr_failure_(ctx* _ctx, arr__ptr_failure a);
int32 unsafe_to_int32__int32___int_(_int a);
global_ctx* as_ref__ptr_global_ctx__ptr__byte_(ptr__byte p);
bool try_acquire_lock__bool__ptr_lock_(lock* l);
_void hard_fail___void__arr__char__id6_();
bool try_unset__bool__ptr__atomic_bool_(_atomic_bool* a);
fut__int32* new_unresolved_fut__ptr_fut__int32(ctx* _ctx);
_void then_void___void__ptr_fut___void___then__ptr_fut__int32__ptr_fut___void___fun_ref1__int32___void___lambda0___closure__klbthen__ptr_fut__int32__ptr_fut___void___fun_ref1__int32___void___lambda0_(ctx* _ctx, fut___void* f, then__ptr_fut__int32__ptr_fut___void___fun_ref1__int32___void___lambda0___closure cb);
fut__int32* call__ptr_fut__int32__fun_ref0__int32_(ctx* _ctx, fun_ref0__int32 f);
bool empty__q__bool__arr__ptr__char_(arr__ptr__char a);
arr__ptr__char slice_starting_at__arr__ptr__char__arr__ptr__char___nat_(ctx* _ctx, arr__ptr__char a, nat begin);
arr__arr__char make_arr__arr__arr__char__nat___map__arr__arr__char__arr__ptr__char___fun_mut1__arr__char__ptr__char__id1___lambda0___closure__klbmap__arr__arr__char__arr__ptr__char___fun_mut1__arr__char__ptr__char__id1___lambda0_(ctx* _ctx, nat size, map__arr__arr__char__arr__ptr__char___fun_mut1__arr__char__ptr__char__id1___lambda0___closure f);
nat wrap_add__nat__nat___nat_(nat a, nat b);
comparison _op_less_equal_greater__comparison__ptr__byte___ptr__byte_(ptr__byte a, ptr__byte b);
vat* deref__ptr_vat__ptr__ptr_vat_(ptr__ptr_vat p);
ptr__ptr_vat _op_plus__ptr__ptr_vat__ptr__ptr_vat___nat_(ptr__ptr_vat p, nat offset);
bool empty__q__bool__opt__ptr_mut_bag_node__task_(opt__ptr_mut_bag_node__task a);
opt__opt__task choose_task_in_vat__opt__opt__task__ptr_vat_(vat* vat);
some__chosen_task some__some__chosen_task__chosen_task_(chosen_task t);
_void call___void__fun_ptr2___void__ptr_ctx__ptr__byte___ptr_ctx___ptr__byte_(fun_ptr2___void__ptr_ctx__ptr__byte f, ctx* p0, ptr__byte p1);
_void noctx_must_remove_unordered_recur___void__ptr_mut_arr__nat___nat___nat_(mut_arr__nat* a, nat index, nat value);
_void return_gc_ctx___void__ptr_gc_ctx_(gc_ctx* gc_ctx);
extern int32 pthread_yield();
extern void usleep(nat micro_seconds);
bool parse_cmd_line_args_dynamic__ptr_parsed_cmd_line_args__arr__arr__char___lambda0_(ctx* _ctx, arr__char it);
some__nat some__some__nat__nat_(nat t);
ptr__arr__char _op_plus__ptr__arr__char__ptr__arr__char___nat_(ptr__arr__char p, nat offset);
bool _op_greater_equal__bool__nat___nat_(nat a, nat b);
bool parse_cmd_line_args_dynamic__ptr_parsed_cmd_line_args__arr__arr__char___lambda1_(ctx* _ctx, arr__char it);
mut_arr__arr__arr__char* new_mut_arr__ptr_mut_arr__arr__arr__char(ctx* _ctx);
arr__char remove_start__arr__char__arr__char___arr__char_(ctx* _ctx, arr__char a, arr__char start);
opt__nat find_index__opt__nat__arr__arr__char___fun_mut1__bool__arr__char__id8_(ctx* _ctx, arr__arr__char a);
_void add___void__mut_dict__arr__char__arr__arr__char___arr__char___arr__arr__char_(ctx* _ctx, mut_dict__arr__char__arr__arr__char m, arr__char key, arr__arr__char value);
arr__arr__arr__char freeze__arr__arr__arr__char__ptr_mut_arr__arr__arr__char_(mut_arr__arr__arr__char* a);
exception_ctx* get_exception_ctx__ptr_exception_ctx(ctx* _ctx);
bool _op_equal_equal__bool__ptr__jmp_buf_tag___ptr__jmp_buf_tag_(ptr__jmp_buf_tag a, ptr__jmp_buf_tag b);
extern void longjmp(ptr__jmp_buf_tag env, int32 val);
ptr__opt__arr__arr__char uninitialized_data__ptr__opt__arr__arr__char__nat_(ctx* _ctx, nat size);
opt__arr__arr__char fill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat___opt__arr__arr__char___lambda0_(ctx* _ctx, fill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat___opt__arr__arr__char___lambda0___closure _closure, nat ignore);
opt__nat find_index__opt__nat__arr__arr__char___index_of__opt__nat__arr__arr__char___arr__char___lambda0___closure__klbindex_of__opt__nat__arr__arr__char___arr__char___lambda0_(ctx* _ctx, arr__arr__char a, index_of__opt__nat__arr__arr__char___arr__char___lambda0___closure pred);
comparison _op_less_equal_greater__comparison__arr__char___arr__char_(arr__char a, arr__char b);
_void forbid___void__bool___arr__char_(ctx* _ctx, bool condition, arr__char message);
opt__arr__arr__char noctx_at__opt__arr__arr__char__ptr_mut_arr__opt__arr__arr__char___nat_(mut_arr__opt__arr__arr__char* a, nat index);
_void noctx_set_at___void__ptr_mut_arr__opt__arr__arr__char___nat___opt__arr__arr__char_(mut_arr__opt__arr__arr__char* a, nat index, opt__arr__arr__char value);
arr__char noctx_at__arr__char__arr__arr__char___nat_(arr__arr__char a, nat index);
arr__arr__char noctx_at__arr__arr__char__arr__arr__arr__char___nat_(arr__arr__arr__char a, nat index);
arr__arr__arr__char slice__arr__arr__arr__char__arr__arr__arr__char___nat___nat_(ctx* _ctx, arr__arr__arr__char a, nat begin, nat size);
opt__arr__arr__char deref__opt__arr__arr__char__ptr__opt__arr__arr__char_(ptr__opt__arr__arr__char p);
ptr__opt__arr__arr__char _op_plus__ptr__opt__arr__arr__char__ptr__opt__arr__arr__char___nat_(ptr__opt__arr__arr__char p, nat offset);
nat decr__nat__nat_(ctx* _ctx, nat a);
bool and__bool__bool___bool_(bool a, bool b);
bool or__bool__bool___bool_(bool a, bool b);
bool _op_equal_equal__bool__char___char_(char a, char b);
nat todo__nat();
char at__char__arr__char___nat_(ctx* _ctx, arr__char a, nat index);
some__ptr__byte some__some__ptr__byte__ptr__byte_(ptr__byte t);
ptr__byte hard_fail__ptr__byte__arr__char__id2_();
opt__nat find_rindex_recur__opt__nat__arr__char___nat___r_index_of__opt__nat__arr__char___char___lambda0___closure__klbr_index_of__opt__nat__arr__char___char___lambda0_(ctx* _ctx, arr__char a, nat index, r_index_of__opt__nat__arr__char___char___lambda0___closure pred);
ptr__char _op_plus__ptr__char__ptr__char___nat_(ptr__char p, nat offset);
ptr__char uninitialized_data__ptr__char__nat__id1000_(ctx* _ctx);
_void check_posix_error___void__int32_(ctx* _ctx, int32 e);
int32 get_errno__int32(ctx* _ctx);
_void hard_unreachable___void();
arr__char unsafe_as_arr__arr__char__ptr_mut_arr__char_(mut_arr__char* a);
bool negative__q__bool___int_(ctx* _ctx, _int i);
mut_arr__char* make_mut_arr__ptr_mut_arr__char__nat____op_plus__arr__char__arr__char___arr__char___lambda0___closure__klb_op_plus__arr__char__arr__char___arr__char___lambda0_(ctx* _ctx, nat size, _op_plus__arr__char__arr__char___arr__char___lambda0___closure f);
bool _op_equal_equal__bool__ptr__char___ptr__char_(ptr__char a, ptr__char b);
_void add___void__mut_dict__arr__char__arr__char___arr__char___arr__char_(ctx* _ctx, mut_dict__arr__char__arr__char m, arr__char key, arr__char value);
ptr__char find_char_in_cstr__ptr__char__ptr__char___char_(ptr__char a, char c);
arr__char arr_from_begin_end__arr__char__ptr__char___ptr__char_(ptr__char begin, ptr__char end);
ptr__char incr__ptr__char__ptr__char_(ptr__char p);
ptr__char find_cstr_end__ptr__char__ptr__char_(ptr__char a);
ptr__ptr__char _op_plus__ptr__ptr__char__ptr__ptr__char___nat_(ptr__ptr__char p, nat offset);
arr__arr__char unsafe_as_arr__arr__arr__char__ptr_mut_arr__arr__char_(mut_arr__arr__char* a);
bool is_dir__q__bool__arr__char_(ctx* _ctx, arr__char path);
_void each___void__arr__arr__char___each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id9___list_compile_error_tests__arr__arr__char__arr__char___lambda0___closure__klblist_compile_error_tests__arr__arr__char__arr__char___lambda0___lambda0___closure__klbeach_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id9___list_compile_error_tests__arr__arr__char__arr__char___lambda0___closure__klblist_compile_error_tests__arr__arr__char__arr__char___lambda0___lambda0_(ctx* _ctx, arr__arr__char a, each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id9___list_compile_error_tests__arr__arr__char__arr__char___lambda0___closure__klblist_compile_error_tests__arr__arr__char__arr__char___lambda0___lambda0___closure f);
arr__arr__char read_dir__arr__arr__char__arr__char_(ctx* _ctx, arr__char path);
_void list_compile_error_tests__arr__arr__char__arr__char___lambda0_(ctx* _ctx, list_compile_error_tests__arr__arr__char__arr__char___lambda0___closure _closure, arr__char child);
_void flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure__klbrun_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___lambda0_(ctx* _ctx, flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure__klbrun_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___lambda0___closure _closure, arr__char x);
arr__ptr_failure unsafe_as_arr__arr__ptr_failure__ptr_mut_arr__ptr_failure_(mut_arr__ptr_failure* a);
ptr__ptr_failure _op_plus__ptr__ptr_failure__ptr__ptr_failure___nat_(ptr__ptr_failure p, nat offset);
nat unsafe_div__nat__nat___nat_(nat a, nat b);
nat unsafe_mod__nat__nat___nat_(nat a, nat b);
result__arr__char__arr__ptr_failure then__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda0___closure__klbdo_test__int32__test_options___lambda0___lambda0___lambda0___closure__klbfirst_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda0___closure__klbdo_test__int32__test_options___lambda0___lambda0___lambda0_(ctx* _ctx, result__arr__char__arr__ptr_failure a, first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda0___closure__klbdo_test__int32__test_options___lambda0___lambda0___lambda0___closure f);
result__arr__char__arr__ptr_failure do_test__int32__test_options___lambda0(ctx* _ctx, do_test__int32__test_options___lambda0___closure _closure);
result__arr__char__arr__ptr_failure then__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda1___closure__klbdo_test__int32__test_options___lambda1___lambda0___lambda0___closure__klbfirst_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda1___closure__klbdo_test__int32__test_options___lambda1___lambda0___lambda0_(ctx* _ctx, result__arr__char__arr__ptr_failure a, first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda1___closure__klbdo_test__int32__test_options___lambda1___lambda0___lambda0___closure f);
result__arr__char__arr__ptr_failure do_test__int32__test_options___lambda1(ctx* _ctx, do_test__int32__test_options___lambda1___closure _closure);
_void print_failure___void__ptr_failure_(ctx* _ctx, failure* failure);
failure* at__ptr_failure__arr__ptr_failure___nat_(ctx* _ctx, arr__ptr_failure a, nat index);
arr__ptr_failure slice_starting_at__arr__ptr_failure__arr__ptr_failure___nat_(ctx* _ctx, arr__ptr_failure a, nat begin);
bool try_set__bool__ptr__atomic_bool_(_atomic_bool* a);
bool try_change__bool__ptr__atomic_bool___bool_(_atomic_bool* a, bool old_value);
some__ptr_fut_callback_node___void some__some__ptr_fut_callback_node___void__ptr_fut_callback_node___void_(fut_callback_node___void* t);
_void then__ptr_fut__int32__ptr_fut___void___fun_ref1__int32___void___lambda0___dynamic(ctx* _ctx, then__ptr_fut__int32__ptr_fut___void___fun_ref1__int32___void___lambda0___closure* _closure, result___void__exception result);
_void then__ptr_fut__int32__ptr_fut___void___fun_ref1__int32___void___lambda0_(ctx* _ctx, then__ptr_fut__int32__ptr_fut___void___fun_ref1__int32___void___lambda0___closure _closure, result___void__exception result);
ok___void ok__ok___void___void_(_void t);
vat* get_vat__ptr_vat__nat_(ctx* _ctx, nat vat_id);
_void add_task___void__ptr_vat___task_(ctx* _ctx, vat* v, task t);
_void call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic(ctx* _ctx, call__ptr_fut__int32__fun_ref0__int32___lambda0___closure* _closure);
arr__ptr__char slice__arr__ptr__char__arr__ptr__char___nat___nat_(ctx* _ctx, arr__ptr__char a, nat begin, nat size);
mut_arr__arr__char* make_mut_arr__ptr_mut_arr__arr__char__nat___map__arr__arr__char__arr__ptr__char___fun_mut1__arr__char__ptr__char__id1___lambda0___closure__klbmap__arr__arr__char__arr__ptr__char___fun_mut1__arr__char__ptr__char__id1___lambda0_(ctx* _ctx, nat size, map__arr__arr__char__arr__ptr__char___fun_mut1__arr__char__ptr__char__id1___lambda0___closure f);
opt__opt__task as__opt__opt__task__opt__opt__task_(opt__opt__task value);
opt__task find_and_remove_first_doable_task__opt__task__ptr_vat_(vat* vat);
some__opt__task some__some__opt__task__opt__task_(opt__task t);
some__task some__some__task__task_(task t);
bool empty__q__bool__opt__opt__task_(opt__opt__task a);
_void hard_fail___void__arr__char__id11_();
nat noctx_at__nat__ptr_mut_arr__nat___nat_(mut_arr__nat* a, nat index);
_void drop___void__nat_(nat t);
nat noctx_remove_unordered_at_index__nat__ptr_mut_arr__nat___nat_(mut_arr__nat* a, nat index);
some__ptr_gc_ctx some__some__ptr_gc_ctx__ptr_gc_ctx_(gc_ctx* t);
bool starts_with__q__bool__arr__char___arr__char_(ctx* _ctx, arr__char a, arr__char start);
arr__char force__arr__char__opt__arr__char_(ctx* _ctx, opt__arr__char a);
opt__arr__char try_remove_start__opt__arr__char__arr__char___arr__char_(ctx* _ctx, arr__char a, arr__char start);
opt__nat find_index_recur__opt__nat__arr__arr__char___nat___fun_mut1__bool__arr__char__id8_(ctx* _ctx, arr__arr__char a, nat index);
bool has__q__bool__mut_dict__arr__char__arr__arr__char___arr__char_(ctx* _ctx, mut_dict__arr__char__arr__arr__char d, arr__char key);
_void push___void__ptr_mut_arr__arr__char___arr__char_(ctx* _ctx, mut_arr__arr__char* a, arr__char value);
_void push___void__ptr_mut_arr__arr__arr__char___arr__arr__char_(ctx* _ctx, mut_arr__arr__arr__char* a, arr__arr__char value);
arr__arr__arr__char unsafe_as_arr__arr__arr__arr__char__ptr_mut_arr__arr__arr__char_(mut_arr__arr__arr__char* a);
exception_ctx* as_ref__ptr_exception_ctx__ptr__byte_(ptr__byte p);
comparison _op_less_equal_greater__comparison__ptr__jmp_buf_tag___ptr__jmp_buf_tag_(ptr__jmp_buf_tag a, ptr__jmp_buf_tag b);
ptr__opt__arr__arr__char ptr_cast__ptr__opt__arr__arr__char__ptr__byte_(ptr__byte p);
opt__nat find_index_recur__opt__nat__arr__arr__char___nat___index_of__opt__nat__arr__arr__char___arr__char___lambda0___closure__klbindex_of__opt__nat__arr__arr__char___arr__char___lambda0_(ctx* _ctx, arr__arr__char a, nat index, index_of__opt__nat__arr__arr__char___arr__char___lambda0___closure pred);
comparison _op_less_equal_greater__comparison__char___char_(char a, char b);
_void set___void__ptr__opt__arr__arr__char___opt__arr__arr__char_(ptr__opt__arr__arr__char p, opt__arr__arr__char value);
arr__char deref__arr__char__ptr__arr__char_(ptr__arr__char p);
arr__arr__char deref__arr__arr__char__ptr__arr__arr__char_(ptr__arr__arr__char p);
ptr__arr__arr__char _op_plus__ptr__arr__arr__char__ptr__arr__arr__char___nat_(ptr__arr__arr__char p, nat offset);
nat wrap_decr__nat__nat_(nat a);
nat hard_fail__nat__arr__char__id2_();
char noctx_at__char__arr__char___nat_(arr__char a, nat index);
bool r_index_of__opt__nat__arr__char___char___lambda0_(ctx* _ctx, r_index_of__opt__nat__arr__char___char___lambda0___closure _closure, char it);
ptr__byte alloc__ptr__byte__nat__id1000_(ctx* _ctx);
ptr__char ptr_cast__ptr__char__ptr__byte_(ptr__byte p);
_void hard_fail___void__arr__char__id12_();
bool _op_less__bool___int____int_(_int a, _int b);
mut_arr__char* new_uninitialized_mut_arr__ptr_mut_arr__char__nat_(ctx* _ctx, nat size);
_void make_mut_arr_worker___void__ptr_mut_arr__char___nat____op_plus__arr__char__arr__char___arr__char___lambda0___closure__klb_op_plus__arr__char__arr__char___arr__char___lambda0_(ctx* _ctx, mut_arr__char* m, nat i, _op_plus__arr__char__arr__char___arr__char___lambda0___closure f);
comparison _op_less_equal_greater__comparison__ptr__char___ptr__char_(ptr__char a, ptr__char b);
bool has__q__bool__mut_dict__arr__char__arr__char___arr__char_(ctx* _ctx, mut_dict__arr__char__arr__char d, arr__char key);
char deref__char__ptr__char_(ptr__char p);
ptr__char todo__ptr__char();
nat _op_minus__nat__ptr__char___ptr__char_(ptr__char a, ptr__char b);
bool is_dir__q__bool__ptr__char_(ctx* _ctx, ptr__char path);
_void each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id9___list_compile_error_tests__arr__arr__char__arr__char___lambda0___closure__klblist_compile_error_tests__arr__arr__char__arr__char___lambda0___lambda0_(ctx* _ctx, each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id9___list_compile_error_tests__arr__arr__char__arr__char___lambda0___closure__klblist_compile_error_tests__arr__arr__char__arr__char___lambda0___lambda0___closure _closure, arr__char child_name);
arr__arr__char read_dir__arr__arr__char__ptr__char_(ctx* _ctx, ptr__char path);
opt__arr__char get_extension__opt__arr__char__arr__char_(ctx* _ctx, arr__char name);
arr__char base_name__arr__char__arr__char_(ctx* _ctx, arr__char path);
_void push_all___void__ptr_mut_arr__ptr_failure___arr__ptr_failure_(ctx* _ctx, mut_arr__ptr_failure* a, arr__ptr_failure values);
arr__ptr_failure run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0_(ctx* _ctx, run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure _closure, arr__char test);
_void reduce_size_if_more_than___void__ptr_mut_arr__ptr_failure___nat_(ctx* _ctx, mut_arr__ptr_failure* a, nat new_size);
result__arr__char__arr__ptr_failure first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda0___closure__klbdo_test__int32__test_options___lambda0___lambda0___lambda0_(ctx* _ctx, first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda0___closure__klbdo_test__int32__test_options___lambda0___lambda0___lambda0___closure _closure, arr__char b_descr);
result__arr__char__arr__ptr_failure run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options_(ctx* _ctx, arr__char path, arr__char path_to_noze, dict__arr__char__arr__char* env, test_options options);
result__arr__char__arr__ptr_failure first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda1___closure__klbdo_test__int32__test_options___lambda1___lambda0___lambda0_(ctx* _ctx, first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda1___closure__klbdo_test__int32__test_options___lambda1___lambda0___lambda0___closure _closure, arr__char b_descr);
result__arr__char__arr__ptr_failure lint__result__arr__char__arr__ptr_failure__arr__char___test_options_(ctx* _ctx, arr__char path, test_options options);
_void print_bold___void(ctx* _ctx);
_void print_reset___void(ctx* _ctx);
failure* noctx_at__ptr_failure__arr__ptr_failure___nat_(arr__ptr_failure a, nat index);
bool compare_exchange_strong__bool__ptr__bool___ptr__bool___bool_(ptr__bool value_ptr, ptr__bool expected_ptr, bool desired);
ptr__bool ptr_to__ptr__bool__bool_(bool t);
_void forward_to___void__ptr_fut__int32___ptr_fut__int32_(ctx* _ctx, fut__int32* from, fut__int32* to);
fut__int32* call__ptr_fut__int32__fun_ref1__int32___void____void_(ctx* _ctx, fun_ref1__int32___void f, _void p0);
_void reject___void__ptr_fut__int32___exception_(ctx* _ctx, fut__int32* f, exception e);
vat* at__ptr_vat__arr__ptr_vat___nat_(ctx* _ctx, arr__ptr_vat a, nat index);
mut_bag_node__task* new_mut_bag_node__ptr_mut_bag_node__task__task_(ctx* _ctx, task value);
_void add___void__ptr_mut_bag__task___ptr_mut_bag_node__task_(mut_bag__task* bag, mut_bag_node__task* node);
_void catch___void__call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda0___closure__klbcall__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda0___call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda1___closure__klbcall__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda1_(ctx* _ctx, call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda0___closure try, call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda1___closure catcher);
mut_arr__arr__char* new_uninitialized_mut_arr__ptr_mut_arr__arr__char__nat_(ctx* _ctx, nat size);
_void make_mut_arr_worker___void__ptr_mut_arr__arr__char___nat___map__arr__arr__char__arr__ptr__char___fun_mut1__arr__char__ptr__char__id1___lambda0___closure__klbmap__arr__arr__char__arr__ptr__char___fun_mut1__arr__char__ptr__char__id1___lambda0_(ctx* _ctx, mut_arr__arr__char* m, nat i, map__arr__arr__char__arr__ptr__char___fun_mut1__arr__char__ptr__char__id1___lambda0___closure f);
opt__task_and_nodes find_and_remove_first_doable_task_recur__opt__task_and_nodes__ptr_vat___opt__ptr_mut_bag_node__task_(vat* vat, opt__ptr_mut_bag_node__task opt_node);
_void noctx_set_at___void__ptr_mut_arr__nat___nat___nat_(mut_arr__nat* a, nat index, nat value);
nat noctx_last__nat__ptr_mut_arr__nat_(mut_arr__nat* a);
bool arr_eq__q__bool__arr__char___arr__char_(ctx* _ctx, arr__char a, arr__char b);
arr__char fail__arr__char__arr__char__id17_(ctx* _ctx);
some__arr__char some__some__arr__char__arr__char_(arr__char t);
arr__char slice_starting_at__arr__char__arr__char___nat_(ctx* _ctx, arr__char a, nat begin);
bool parse_named_args_recur___void__arr__arr__char___mut_dict__arr__char__arr__arr__char___lambda0_(ctx* _ctx, arr__char it);
bool has__q__bool__ptr_dict__arr__char__arr__arr__char___arr__char_(ctx* _ctx, dict__arr__char__arr__arr__char* d, arr__char key);
dict__arr__char__arr__arr__char* unsafe_as_dict__ptr_dict__arr__char__arr__arr__char__mut_dict__arr__char__arr__arr__char_(ctx* _ctx, mut_dict__arr__char__arr__arr__char m);
_void increase_capacity_to___void__ptr_mut_arr__arr__char___nat_(ctx* _ctx, mut_arr__arr__char* a, nat new_capacity);
nat if__nat__bool___nat___nat_(bool cond, nat if_true, nat if_false);
_void ensure_capacity___void__ptr_mut_arr__arr__char___nat_(ctx* _ctx, mut_arr__arr__char* a, nat capacity);
nat round_up_to_power_of_two__nat__nat_(ctx* _ctx, nat n);
_void set___void__ptr__arr__char___arr__char_(ptr__arr__char p, arr__char value);
_void increase_capacity_to___void__ptr_mut_arr__arr__arr__char___nat_(ctx* _ctx, mut_arr__arr__arr__char* a, nat new_capacity);
_void ensure_capacity___void__ptr_mut_arr__arr__arr__char___nat_(ctx* _ctx, mut_arr__arr__arr__char* a, nat capacity);
_void set___void__ptr__arr__arr__char___arr__arr__char_(ptr__arr__arr__char p, arr__arr__char value);
bool index_of__opt__nat__arr__arr__char___arr__char___lambda0_(ctx* _ctx, index_of__opt__nat__arr__arr__char___arr__char___lambda0___closure _closure, arr__char it);
ptr__char uninitialized_data__ptr__char__nat_(ctx* _ctx, nat size);
_void set_at___void__ptr_mut_arr__char___nat___char_(ctx* _ctx, mut_arr__char* a, nat index, char value);
char _op_plus__arr__char__arr__char___arr__char___lambda0_(ctx* _ctx, _op_plus__arr__char__arr__char___arr__char___lambda0___closure _closure, nat i);
bool has__q__bool__ptr_dict__arr__char__arr__char___arr__char_(ctx* _ctx, dict__arr__char__arr__char* d, arr__char key);
dict__arr__char__arr__char* unsafe_as_dict__ptr_dict__arr__char__arr__char__mut_dict__arr__char__arr__char_(ctx* _ctx, mut_dict__arr__char__arr__char m);
ptr__char hard_fail__ptr__char__arr__char__id2_();
nat to_nat__nat__ptr__char_(ptr__char p);
ptr__char _op_minus__ptr__char__ptr__char___nat_(ptr__char p, nat offset);
opt__ptr_stat_t get_stat__opt__ptr_stat_t__ptr__char_(ctx* _ctx, ptr__char path);
bool todo__bool();
bool _op_equal_equal__bool__nat32___nat32_(nat32 a, nat32 b);
nat32 bits_and__nat32__nat32___nat32_(nat32 a, nat32 b);
bool always_true__bool__arr__char___asLambda_(ctx* _ctx, arr__char a);
extern ptr__byte opendir(ptr__char name);
_void read_dir_recur___void__ptr__byte___ptr_mut_arr__arr__char_(ctx* _ctx, ptr__byte dirp, mut_arr__arr__char* res);
arr__arr__char sort__arr__arr__char__arr__arr__char_(ctx* _ctx, arr__arr__char a);
opt__nat last_index_of__opt__nat__arr__char___char_(ctx* _ctx, arr__char s, char c);
arr__char slice_after__arr__char__arr__char___nat_(ctx* _ctx, arr__char a, nat before_begin);
_void each___void__arr__ptr_failure___push_all___void__ptr_mut_arr__ptr_failure___arr__ptr_failure___lambda0___closure__klbpush_all___void__ptr_mut_arr__ptr_failure___arr__ptr_failure___lambda0_(ctx* _ctx, arr__ptr_failure a, push_all___void__ptr_mut_arr__ptr_failure___arr__ptr_failure___lambda0___closure f);
arr__ptr_failure run_single_compile_error_test__arr__ptr_failure__arr__char___ptr_dict__arr__char__arr__char___arr__char_(ctx* _ctx, arr__char path_to_noze, dict__arr__char__arr__char* env, arr__char path);
arr__arr__char list_runnable_tests__arr__arr__char__arr__char_(ctx* _ctx, arr__char path);
arr__ptr_failure flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure__klbrun_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0_(ctx* _ctx, arr__arr__char a, nat max_size, run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure mapper);
arr__arr__char list_lintable_files__arr__arr__char__arr__char_(ctx* _ctx, arr__char path);
arr__ptr_failure flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___lint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___closure__klblint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0_(ctx* _ctx, arr__arr__char a, nat max_size, lint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___closure mapper);
failure* deref__ptr_failure__ptr__ptr_failure_(ptr__ptr_failure p);
_void then_void___void__ptr_fut__int32___forward_to___void__ptr_fut__int32___ptr_fut__int32___lambda0___closure__klbforward_to___void__ptr_fut__int32___ptr_fut__int32___lambda0_(ctx* _ctx, fut__int32* f, forward_to___void__ptr_fut__int32___ptr_fut__int32___lambda0___closure cb);
_void call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic(ctx* _ctx, call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0___closure* _closure);
_void resolve_or_reject___void__ptr_fut__int32___result__int32__exception_(ctx* _ctx, fut__int32* f, result__int32__exception result);
some__ptr_mut_bag_node__task some__some__ptr_mut_bag_node__task__ptr_mut_bag_node__task_(mut_bag_node__task* t);
_void catch_with_exception_ctx___void__ptr_exception_ctx___call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda0___closure__klbcall__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda0___call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda1___closure__klbcall__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda1_(ctx* _ctx, exception_ctx* ec, call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda0___closure try, call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda1___closure catcher);
ptr__arr__char uninitialized_data__ptr__arr__char__nat_(ctx* _ctx, nat size);
_void set_at___void__ptr_mut_arr__arr__char___nat___arr__char_(ctx* _ctx, mut_arr__arr__char* a, nat index, arr__char value);
arr__char map__arr__arr__char__arr__ptr__char___fun_mut1__arr__char__ptr__char__id1___lambda0_(ctx* _ctx, map__arr__arr__char__arr__ptr__char___fun_mut1__arr__char__ptr__char__id1___lambda0___closure _closure, nat i);
bool contains__q__bool__ptr_mut_arr__nat___nat_(mut_arr__nat* a, nat value);
_void push_capacity_must_be_sufficient___void__ptr_mut_arr__nat___nat_(mut_arr__nat* a, nat value);
some__task_and_nodes some__some__task_and_nodes__task_and_nodes_(task_and_nodes t);
task_and_nodes as__task_and_nodes__task_and_nodes_(task_and_nodes value);
_void set___void__ptr__nat___nat_(ptr__nat p, nat value);
bool empty__q__bool__ptr_mut_arr__nat_(mut_arr__nat* a);
char first__char__arr__char_(ctx* _ctx, arr__char a);
arr__char tail__arr__char__arr__char_(ctx* _ctx, arr__char a);
arr__char throw__arr__char__exception__id1_(ctx* _ctx);
opt__arr__arr__char get__opt__arr__arr__char__ptr_dict__arr__char__arr__arr__char___arr__char_(ctx* _ctx, dict__arr__char__arr__arr__char* d, arr__char key);
_void copy_data_from___void__ptr__arr__char___ptr__arr__char___nat_(ctx* _ctx, ptr__arr__char to, ptr__arr__char from, nat len);
nat round_up_to_power_of_two_recur__nat__nat___nat_(ctx* _ctx, nat acc, nat n);
ptr__arr__arr__char uninitialized_data__ptr__arr__arr__char__nat_(ctx* _ctx, nat size);
_void copy_data_from___void__ptr__arr__arr__char___ptr__arr__arr__char___nat_(ctx* _ctx, ptr__arr__arr__char to, ptr__arr__arr__char from, nat len);
_void noctx_set_at___void__ptr_mut_arr__char___nat___char_(mut_arr__char* a, nat index, char value);
bool has__q__bool__opt__arr__char_(opt__arr__char a);
opt__arr__char get__opt__arr__char__ptr_dict__arr__char__arr__char___arr__char_(ctx* _ctx, dict__arr__char__arr__char* d, arr__char key);
stat_t* empty_stat__ptr_stat_t(ctx* _ctx);
extern int32 stat(ptr__char path, stat_t* buf);
some__ptr_stat_t some__some__ptr_stat_t__ptr_stat_t_(stat_t* t);
opt__ptr_stat_t todo__opt__ptr_stat_t();
bool hard_fail__bool__arr__char__id2_();
comparison _op_less_equal_greater__comparison__nat32___nat32_(nat32 a, nat32 b);
bool always_true__bool__arr__char_(ctx* _ctx, arr__char a);
cell__ptr_dirent* new_cell__ptr_cell__ptr_dirent__ptr_dirent_(ctx* _ctx, dirent* value);
extern int32 readdir_r(ptr__byte dirp, dirent* entry, cell__ptr_dirent* result);
ptr__byte as_any_ptr__ptr__byte__ptr_dirent_(dirent* some_ref);
dirent* get__ptr_dirent__ptr_cell__ptr_dirent_(cell__ptr_dirent* c);
bool ptr_eq__bool__ptr_dirent___ptr_dirent_(dirent* a, dirent* b);
arr__char get_dirent_name__arr__char__ptr_dirent_(dirent* d);
mut_arr__arr__char* to_mut_arr__ptr_mut_arr__arr__char__arr__arr__char_(ctx* _ctx, arr__arr__char a);
_void sort___void__ptr_mut_arr__arr__char_(ctx* _ctx, mut_arr__arr__char* a);
_void push_all___void__ptr_mut_arr__ptr_failure___arr__ptr_failure___lambda0_(ctx* _ctx, push_all___void__ptr_mut_arr__ptr_failure___arr__ptr_failure___lambda0___closure _closure, failure* it);
process_result* spawn_and_wait_result__ptr_process_result__arr__char___arr__arr__char___ptr_dict__arr__char__arr__char_(ctx* _ctx, arr__char exe, arr__arr__char args, dict__arr__char__arr__char* environ);
arr__char to_str__arr__char__int32_(ctx* _ctx, int32 i);
_void push___void__ptr_mut_arr__ptr_failure___ptr_failure_(ctx* _ctx, mut_arr__ptr_failure* a, failure* value);
arr__char remove_colors__arr__char__arr__char_(ctx* _ctx, arr__char s);
arr__char change_extension__arr__char__arr__char___arr__char_(ctx* _ctx, arr__char name, arr__char ext);
opt__arr__char try_read_file__opt__arr__char__arr__char_(ctx* _ctx, arr__char path);
_void each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id9___list_runnable_tests__arr__arr__char__arr__char___lambda0___closure__klblist_runnable_tests__arr__arr__char__arr__char___lambda0_(ctx* _ctx, arr__char path, list_runnable_tests__arr__arr__char__arr__char___lambda0___closure f);
_void each___void__arr__arr__char___flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure__klbrun_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___lambda0___closure__klbflat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure__klbrun_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___lambda0_(ctx* _ctx, arr__arr__char a, flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure__klbrun_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___lambda0___closure f);
_void each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id11___list_lintable_files__arr__arr__char__arr__char___lambda1___closure__klblist_lintable_files__arr__arr__char__arr__char___lambda1_(ctx* _ctx, arr__char path, list_lintable_files__arr__arr__char__arr__char___lambda1___closure f);
_void each___void__arr__arr__char___flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___lint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___closure__klblint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___lambda0___closure__klbflat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___lint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___closure__klblint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___lambda0_(ctx* _ctx, arr__arr__char a, flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___lint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___closure__klblint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___lambda0___closure f);
some__ptr_fut_callback_node__int32 some__some__ptr_fut_callback_node__int32__ptr_fut_callback_node__int32_(fut_callback_node__int32* t);
_void forward_to___void__ptr_fut__int32___ptr_fut__int32___lambda0___dynamic(ctx* _ctx, forward_to___void__ptr_fut__int32___ptr_fut__int32___lambda0___closure* _closure, result__int32__exception it);
_void forward_to___void__ptr_fut__int32___ptr_fut__int32___lambda0_(ctx* _ctx, forward_to___void__ptr_fut__int32___ptr_fut__int32___lambda0___closure _closure, result__int32__exception it);
_void catch___void__call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda0___closure__klbcall__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda0___call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda1___closure__klbcall__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda1_(ctx* _ctx, call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda0___closure try, call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda1___closure catcher);
_void resolve_or_reject_recur___void__opt__ptr_fut_callback_node__int32___result__int32__exception_(ctx* _ctx, opt__ptr_fut_callback_node__int32 node, result__int32__exception value);
_void hard_fail___void__arr__char__id10_();
ptr__jmp_buf_tag ptr_to__ptr__jmp_buf_tag__jmp_buf_tag_(jmp_buf_tag t);
extern int32 setjmp(ptr__jmp_buf_tag env);
_void call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda0(ctx* _ctx, call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda0___closure _closure);
_void call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda1_(ctx* _ctx, call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda1___closure _closure, exception it);
ptr__arr__char ptr_cast__ptr__arr__char__ptr__byte_(ptr__byte p);
_void noctx_set_at___void__ptr_mut_arr__arr__char___nat___arr__char_(mut_arr__arr__char* a, nat index, arr__char value);
arr__char add_first_task__ptr_fut__int32__arr__ptr__char___fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char___lambda0__dynamic__lambda0_(ctx* _ctx, ptr__char it);
ptr__char at__ptr__char__arr__ptr__char___nat_(ctx* _ctx, arr__ptr__char a, nat index);
bool contains_recur__q__bool__arr__nat___nat___nat_(arr__nat a, nat value, nat i);
arr__nat temp_as_arr__arr__nat__ptr_mut_arr__nat_(mut_arr__nat* a);
arr__char todo__arr__char();
opt__arr__arr__char get_recursive__opt__arr__arr__char__arr__arr__char___arr__arr__arr__char___nat___arr__char_(ctx* _ctx, arr__arr__char keys, arr__arr__arr__char values, nat idx, arr__char key);
ptr__arr__char incr__ptr__arr__char__ptr__arr__char_(ptr__arr__char p);
ptr__arr__arr__char ptr_cast__ptr__arr__arr__char__ptr__byte_(ptr__byte p);
ptr__arr__arr__char incr__ptr__arr__arr__char__ptr__arr__arr__char_(ptr__arr__arr__char p);
_void set___void__ptr__char___char_(ptr__char p, char value);
bool empty__q__bool__opt__arr__char_(opt__arr__char a);
opt__arr__char get_recursive__opt__arr__char__arr__arr__char___arr__arr__char___nat___arr__char_(ctx* _ctx, arr__arr__char keys, arr__arr__char values, nat idx, arr__char key);
opt__ptr_stat_t hard_fail__opt__ptr_stat_t__arr__char__id2_();
ptr__byte _op_plus__ptr__byte__ptr__byte___nat_(ptr__byte p, nat offset);
arr__char to_str__arr__char__ptr__char_(ptr__char a);
mut_arr__arr__char* make_mut_arr__ptr_mut_arr__arr__char__nat___to_mut_arr__ptr_mut_arr__arr__char__arr__arr__char___lambda0___closure__klbto_mut_arr__ptr_mut_arr__arr__char__arr__arr__char___lambda0_(ctx* _ctx, nat size, to_mut_arr__ptr_mut_arr__arr__char__arr__arr__char___lambda0___closure f);
_void sort___void__ptr_mut_slice__arr__char_(ctx* _ctx, mut_slice__arr__char* a);
mut_slice__arr__char* to_mut_slice__ptr_mut_slice__arr__char__ptr_mut_arr__arr__char_(ctx* _ctx, mut_arr__arr__char* a);
bool is_file__q__bool__arr__char_(ctx* _ctx, arr__char path);
process_result* spawn_and_wait_result__ptr_process_result__ptr__char___ptr__ptr__char___ptr__ptr__char_(ctx* _ctx, ptr__char exe, ptr__ptr__char args, ptr__ptr__char environ);
ptr__ptr__char convert_args__ptr__ptr__char__ptr__char___arr__arr__char_(ctx* _ctx, ptr__char exe_c_str, arr__arr__char args);
ptr__ptr__char convert_environ__ptr__ptr__char__ptr_dict__arr__char__arr__char_(ctx* _ctx, dict__arr__char__arr__char* environ);
process_result* fail__ptr_process_result__arr__char_(ctx* _ctx, arr__char reason);
arr__char to_str__arr__char___int_(ctx* _ctx, _int i);
_void increase_capacity_to___void__ptr_mut_arr__ptr_failure___nat_(ctx* _ctx, mut_arr__ptr_failure* a, nat new_capacity);
_void ensure_capacity___void__ptr_mut_arr__ptr_failure___nat_(ctx* _ctx, mut_arr__ptr_failure* a, nat capacity);
_void set___void__ptr__ptr_failure___ptr_failure_(ptr__ptr_failure p, failure* value);
mut_arr__char* new_mut_arr__ptr_mut_arr__char(ctx* _ctx);
_void remove_colors_recur___void__arr__char___ptr_mut_arr__char_(ctx* _ctx, arr__char s, mut_arr__char* out);
arr__char add_extension__arr__char__arr__char___arr__char_(ctx* _ctx, arr__char name, arr__char ext);
arr__char remove_extension__arr__char__arr__char_(ctx* _ctx, arr__char name);
opt__arr__char try_read_file__opt__arr__char__ptr__char_(ctx* _ctx, ptr__char path);
_void each___void__arr__arr__char___each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id9___list_runnable_tests__arr__arr__char__arr__char___lambda0___closure__klblist_runnable_tests__arr__arr__char__arr__char___lambda0___lambda0___closure__klbeach_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id9___list_runnable_tests__arr__arr__char__arr__char___lambda0___closure__klblist_runnable_tests__arr__arr__char__arr__char___lambda0___lambda0_(ctx* _ctx, arr__arr__char a, each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id9___list_runnable_tests__arr__arr__char__arr__char___lambda0___closure__klblist_runnable_tests__arr__arr__char__arr__char___lambda0___lambda0___closure f);
_void list_runnable_tests__arr__arr__char__arr__char___lambda0_(ctx* _ctx, list_runnable_tests__arr__arr__char__arr__char___lambda0___closure _closure, arr__char child);
_void flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure__klbrun_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___lambda0_(ctx* _ctx, flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure__klbrun_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___lambda0___closure _closure, arr__char x);
_void each___void__arr__arr__char___each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id11___list_lintable_files__arr__arr__char__arr__char___lambda1___closure__klblist_lintable_files__arr__arr__char__arr__char___lambda1___lambda0___closure__klbeach_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id11___list_lintable_files__arr__arr__char__arr__char___lambda1___closure__klblist_lintable_files__arr__arr__char__arr__char___lambda1___lambda0_(ctx* _ctx, arr__arr__char a, each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id11___list_lintable_files__arr__arr__char__arr__char___lambda1___closure__klblist_lintable_files__arr__arr__char__arr__char___lambda1___lambda0___closure f);
_void list_lintable_files__arr__arr__char__arr__char___lambda1_(ctx* _ctx, list_lintable_files__arr__arr__char__arr__char___lambda1___closure _closure, arr__char child);
_void flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___lint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___closure__klblint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___lambda0_(ctx* _ctx, flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___lint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___closure__klblint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___lambda0___closure _closure, arr__char x);
_void catch_with_exception_ctx___void__ptr_exception_ctx___call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda0___closure__klbcall__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda0___call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda1___closure__klbcall__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda1_(ctx* _ctx, exception_ctx* ec, call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda0___closure try, call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda1___closure catcher);
_void drop___void___void_(_void t);
_void call___void__fun_mut1___void__result__int32__exception___result__int32__exception_(ctx* _ctx, fun_mut1___void__result__int32__exception f, result__int32__exception p0);
fut__int32* call__ptr_fut__int32__fun_mut0__ptr_fut__int32_(ctx* _ctx, fun_mut0__ptr_fut__int32 f);
ptr__char noctx_at__ptr__char__arr__ptr__char___nat_(arr__ptr__char a, nat index);
nat noctx_at__nat__arr__nat___nat_(arr__nat a, nat index);
arr__char hard_fail__arr__char__arr__char__id2_();
_void make_mut_arr_worker___void__ptr_mut_arr__arr__char___nat___to_mut_arr__ptr_mut_arr__arr__char__arr__arr__char___lambda0___closure__klbto_mut_arr__ptr_mut_arr__arr__char__arr__arr__char___lambda0_(ctx* _ctx, mut_arr__arr__char* m, nat i, to_mut_arr__ptr_mut_arr__arr__char__arr__arr__char___lambda0___closure f);
_void swap___void__ptr_mut_slice__arr__char___nat___nat_(ctx* _ctx, mut_slice__arr__char* a, nat lo, nat hi);
arr__char at__arr__char__ptr_mut_slice__arr__char___nat_(ctx* _ctx, mut_slice__arr__char* a, nat index);
nat partition_recur__nat__ptr_mut_slice__arr__char___arr__char___nat___nat_(ctx* _ctx, mut_slice__arr__char* a, arr__char pivot, nat l, nat r);
mut_slice__arr__char* slice__ptr_mut_slice__arr__char__ptr_mut_slice__arr__char___nat___nat_(ctx* _ctx, mut_slice__arr__char* a, nat lo, nat size);
mut_slice__arr__char* slice__ptr_mut_slice__arr__char__ptr_mut_slice__arr__char___nat_(ctx* _ctx, mut_slice__arr__char* a, nat lo);
bool is_file__q__bool__ptr__char_(ctx* _ctx, ptr__char path);
pipes* make_pipes__ptr_pipes(ctx* _ctx);
extern int32 posix_spawn_file_actions_init(posix_spawn_file_actions_t* file_actions);
extern int32 posix_spawn_file_actions_addclose(posix_spawn_file_actions_t* file_actions, int32 fd);
extern int32 posix_spawn_file_actions_adddup2(posix_spawn_file_actions_t* file_actions, int32 fd, int32 new_fd);
cell__int32* new_cell__ptr_cell__int32__int32__id0_(ctx* _ctx);
extern int32 posix_spawn(cell__int32* pid, ptr__char executable_path, posix_spawn_file_actions_t* file_actions, ptr__byte attrp, ptr__ptr__char argv, ptr__ptr__char environ);
int32 get__int32__ptr_cell__int32_(cell__int32* c);
extern int32 close(int32 fd);
_void keep_polling___void__int32___int32___ptr_mut_arr__char___ptr_mut_arr__char_(ctx* _ctx, int32 stdout_pipe, int32 stderr_pipe, mut_arr__char* stdout_builder, mut_arr__char* stderr_builder);
int32 wait_and_get_exit_code__int32__int32_(ctx* _ctx, int32 pid);
arr__ptr__char cons__arr__ptr__char__ptr__char___arr__ptr__char_(ctx* _ctx, ptr__char a, arr__ptr__char b);
arr__ptr__char rcons__arr__ptr__char__arr__ptr__char___ptr__char_(ctx* _ctx, arr__ptr__char a, ptr__char b);
arr__ptr__char map__arr__ptr__char__arr__arr__char___fun_mut1__ptr__char__arr__char__id10_(ctx* _ctx, arr__arr__char a);
mut_arr__ptr__char* new_mut_arr__ptr_mut_arr__ptr__char(ctx* _ctx);
_void each___void__ptr_dict__arr__char__arr__char___convert_environ__ptr__ptr__char__ptr_dict__arr__char__arr__char___lambda0___closure__klbconvert_environ__ptr__ptr__char__ptr_dict__arr__char__arr__char___lambda0_(ctx* _ctx, dict__arr__char__arr__char* d, convert_environ__ptr__ptr__char__ptr_dict__arr__char__arr__char___lambda0___closure f);
_void push___void__ptr_mut_arr__ptr__char___ptr__char_(ctx* _ctx, mut_arr__ptr__char* a, ptr__char value);
arr__ptr__char freeze__arr__ptr__char__ptr_mut_arr__ptr__char_(mut_arr__ptr__char* a);
process_result* throw__ptr_process_result__exception_(ctx* _ctx, exception e);
nat abs__nat___int_(ctx* _ctx, _int i);
ptr__ptr_failure uninitialized_data__ptr__ptr_failure__nat_(ctx* _ctx, nat size);
_void copy_data_from___void__ptr__ptr_failure___ptr__ptr_failure___nat_(ctx* _ctx, ptr__ptr_failure to, ptr__ptr_failure from, nat len);
_void remove_colors_recur_2___void__arr__char___ptr_mut_arr__char_(ctx* _ctx, arr__char s, mut_arr__char* out);
_void push___void__ptr_mut_arr__char___char_(ctx* _ctx, mut_arr__char* a, char value);
extern int32 open(ptr__char path, int32 oflag);
opt__arr__char todo__opt__arr__char();
extern _int lseek(int32 f, _int offset, int32 whence);
bool zero__q__bool___int_(_int i);
extern _int read(int32 fd, ptr__byte buff, nat n_bytes);
ptr__byte ptr_cast__ptr__byte__ptr__char_(ptr__char p);
_void each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id9___list_runnable_tests__arr__arr__char__arr__char___lambda0___closure__klblist_runnable_tests__arr__arr__char__arr__char___lambda0___lambda0_(ctx* _ctx, each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id9___list_runnable_tests__arr__arr__char__arr__char___lambda0___closure__klblist_runnable_tests__arr__arr__char__arr__char___lambda0___lambda0___closure _closure, arr__char child_name);
arr__ptr_failure run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0_(ctx* _ctx, run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure _closure, arr__char test);
_void each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id11___list_lintable_files__arr__arr__char__arr__char___lambda1___closure__klblist_lintable_files__arr__arr__char__arr__char___lambda1___lambda0_(ctx* _ctx, each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id11___list_lintable_files__arr__arr__char__arr__char___lambda1___closure__klblist_lintable_files__arr__arr__char__arr__char___lambda1___lambda0___closure _closure, arr__char child_name);
bool ignore_extension_of_name__bool__arr__char_(ctx* _ctx, arr__char name);
arr__ptr_failure lint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0_(ctx* _ctx, lint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___closure _closure, arr__char file);
_void call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda0(ctx* _ctx, call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda0___closure _closure);
_void call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda1_(ctx* _ctx, call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda1___closure _closure, exception it);
_void call_with_ctx___void__ptr_ctx___fun_mut1___void__result__int32__exception___result__int32__exception_(ctx* c, fun_mut1___void__result__int32__exception f, result__int32__exception p0);
fut__int32* call_with_ctx__ptr_fut__int32__ptr_ctx___fun_mut0__ptr_fut__int32_(ctx* c, fun_mut0__ptr_fut__int32 f);
arr__char to_mut_arr__ptr_mut_arr__arr__char__arr__arr__char___lambda0_(ctx* _ctx, to_mut_arr__ptr_mut_arr__arr__char__arr__arr__char___lambda0___closure _closure, nat i);
_void set_at___void__ptr_mut_slice__arr__char___nat___arr__char_(ctx* _ctx, mut_slice__arr__char* a, nat index, arr__char value);
arr__char at__arr__char__ptr_mut_arr__arr__char___nat_(ctx* _ctx, mut_arr__arr__char* a, nat index);
bool _op_less__bool__arr__char___arr__char_(arr__char a, arr__char b);
extern int32 pipe(pipes* pipes);
pollfd* ref_of_val_at__ptr_pollfd__arr__pollfd___nat_(ctx* _ctx, arr__pollfd a, nat index);
extern int32 poll(ptr__pollfd fds, nat n_fds, int32 timeout);
handle_revents_result handle_revents__handle_revents_result__ptr_pollfd___ptr_mut_arr__char_(ctx* _ctx, pollfd* pollfd, mut_arr__char* builder);
nat to_nat__nat__bool_(ctx* _ctx, bool b);
bool any__q__bool__handle_revents_result_(ctx* _ctx, handle_revents_result r);
nat to_nat__nat__int32_(ctx* _ctx, int32 i);
extern int32 waitpid(int32 pid, cell__int32* wait_status, int32 options);
bool w_if_exited__bool__int32_(ctx* _ctx, int32 status);
int32 w_exit_status__int32__int32_(ctx* _ctx, int32 status);
bool w_if_signaled__bool__int32_(ctx* _ctx, int32 status);
int32 w_term_sig__int32__int32_(ctx* _ctx, int32 status);
int32 todo__int32();
bool w_if_stopped__bool__int32_(ctx* _ctx, int32 status);
bool w_if_continued__bool__int32_(ctx* _ctx, int32 status);
arr__ptr__char _op_plus__arr__ptr__char__arr__ptr__char___arr__ptr__char_(ctx* _ctx, arr__ptr__char a, arr__ptr__char b);
arr__ptr__char make_arr__arr__ptr__char__nat___map__arr__ptr__char__arr__arr__char___fun_mut1__ptr__char__arr__char__id10___lambda0___closure__klbmap__arr__ptr__char__arr__arr__char___fun_mut1__ptr__char__arr__char__id10___lambda0_(ctx* _ctx, nat size, map__arr__ptr__char__arr__arr__char___fun_mut1__ptr__char__arr__char__id10___lambda0___closure f);
bool empty__q__bool__ptr_dict__arr__char__arr__char_(ctx* _ctx, dict__arr__char__arr__char* d);
_void convert_environ__ptr__ptr__char__ptr_dict__arr__char__arr__char___lambda0__(ctx* _ctx, convert_environ__ptr__ptr__char__ptr_dict__arr__char__arr__char___lambda0___closure _closure, arr__char key, arr__char value);
_void increase_capacity_to___void__ptr_mut_arr__ptr__char___nat_(ctx* _ctx, mut_arr__ptr__char* a, nat new_capacity);
_void ensure_capacity___void__ptr_mut_arr__ptr__char___nat_(ctx* _ctx, mut_arr__ptr__char* a, nat capacity);
_void set___void__ptr__ptr__char___ptr__char_(ptr__ptr__char p, ptr__char value);
arr__ptr__char unsafe_as_arr__arr__ptr__char__ptr_mut_arr__ptr__char_(mut_arr__ptr__char* a);
process_result* todo__ptr_process_result();
_int if___int__bool____int____int_(bool cond, _int if_true, _int if_false);
_int neg___int___int_(ctx* _ctx, _int i);
ptr__ptr_failure ptr_cast__ptr__ptr_failure__ptr__byte_(ptr__byte p);
ptr__ptr_failure incr__ptr__ptr_failure__ptr__ptr_failure_(ptr__ptr_failure p);
_void increase_capacity_to___void__ptr_mut_arr__char___nat_(ctx* _ctx, mut_arr__char* a, nat new_capacity);
_void ensure_capacity___void__ptr_mut_arr__char___nat_(ctx* _ctx, mut_arr__char* a, nat capacity);
opt__arr__char hard_fail__opt__arr__char__arr__char__id2_();
arr__ptr_failure run_single_runnable_test__arr__ptr_failure__arr__char___ptr_dict__arr__char__arr__char___arr__char_(ctx* _ctx, arr__char path_to_noze, dict__arr__char__arr__char* env, arr__char path);
bool list_lintable_files__arr__arr__char__arr__char___lambda0_(ctx* _ctx, arr__char it);
bool ignore_extension__bool__arr__char_(ctx* _ctx, arr__char ext);
arr__ptr_failure lint_file__arr__ptr_failure__arr__char_(ctx* _ctx, arr__char path);
fut__int32* call__ptr_fut__int32__fun_mut1__ptr_fut__int32___void____void_(ctx* _ctx, fun_mut1__ptr_fut__int32___void f, _void p0);
_void call___void__fun_ptr3___void__ptr_ctx__ptr__byte__result__int32__exception___ptr_ctx___ptr__byte___result__int32__exception_(fun_ptr3___void__ptr_ctx__ptr__byte__result__int32__exception f, ctx* p0, ptr__byte p1, result__int32__exception p2);
fut__int32* call__ptr_fut__int32__fun_ptr2__ptr_fut__int32__ptr_ctx__ptr__byte___ptr_ctx___ptr__byte_(fun_ptr2__ptr_fut__int32__ptr_ctx__ptr__byte f, ctx* p0, ptr__byte p1);
arr__char noctx_at__arr__char__ptr_mut_arr__arr__char___nat_(mut_arr__arr__char* a, nat index);
pollfd* ref_of_ptr__ptr_pollfd__ptr__pollfd_(ptr__pollfd p);
ptr__pollfd _op_plus__ptr__pollfd__ptr__pollfd___nat_(ptr__pollfd p, nat offset);
bool has_pollin__q__bool__int16_(ctx* _ctx, int16 revents);
_void read_to_buffer_until_eof___void__int32___ptr_mut_arr__char_(ctx* _ctx, int32 fd, mut_arr__char* buffer);
bool has_pollhup__q__bool__int16_(ctx* _ctx, int16 revents);
bool has_pollpri__q__bool__int16_(ctx* _ctx, int16 revents);
bool has_pollout__q__bool__int16_(ctx* _ctx, int16 revents);
bool has_pollerr__q__bool__int16_(ctx* _ctx, int16 revents);
bool has_pollnval__q__bool__int16_(ctx* _ctx, int16 revents);
int32 bit_rshift__int32__int32___int32_(int32 a, int32 b);
int32 bits_and__int32__int32___int32_(int32 a, int32 b);
bool _op_bang_equal__bool__int32___int32_(int32 a, int32 b);
int32 hard_fail__int32__arr__char__id2_();
arr__ptr__char make_arr__arr__ptr__char__nat____op_plus__arr__ptr__char__arr__ptr__char___arr__ptr__char___lambda0___closure__klb_op_plus__arr__ptr__char__arr__ptr__char___arr__ptr__char___lambda0_(ctx* _ctx, nat size, _op_plus__arr__ptr__char__arr__ptr__char___arr__ptr__char___lambda0___closure f);
mut_arr__ptr__char* make_mut_arr__ptr_mut_arr__ptr__char__nat___map__arr__ptr__char__arr__arr__char___fun_mut1__ptr__char__arr__char__id10___lambda0___closure__klbmap__arr__ptr__char__arr__arr__char___fun_mut1__ptr__char__arr__char__id10___lambda0_(ctx* _ctx, nat size, map__arr__ptr__char__arr__arr__char___fun_mut1__ptr__char__arr__char__id10___lambda0___closure f);
ptr__ptr__char uninitialized_data__ptr__ptr__char__nat_(ctx* _ctx, nat size);
_void copy_data_from___void__ptr__ptr__char___ptr__ptr__char___nat_(ctx* _ctx, ptr__ptr__char to, ptr__ptr__char from, nat len);
process_result* hard_fail__ptr_process_result__arr__char__id2_();
_int _op_times___int___int____int_(ctx* _ctx, _int a, _int b);
_void copy_data_from___void__ptr__char___ptr__char___nat_(ctx* _ctx, ptr__char to, ptr__char from, nat len);
bool _op_equal_equal__bool__ptr_process_result___ptr_process_result_(process_result* a, process_result* b);
bool contains__q__bool__arr__arr__char___arr__char_(arr__arr__char a, arr__char value);
arr__char read_file__arr__char__arr__char_(ctx* _ctx, arr__char path);
_void each_with_index___void__arr__arr__char___lint_file__arr__ptr_failure__arr__char___lambda0___closure__klblint_file__arr__ptr_failure__arr__char___lambda0_(ctx* _ctx, arr__arr__char a, lint_file__arr__ptr_failure__arr__char___lambda0___closure f);
arr__arr__char lines__arr__arr__char__arr__char_(ctx* _ctx, arr__char s);
fut__int32* call_with_ctx__ptr_fut__int32__ptr_ctx___fun_mut1__ptr_fut__int32___void____void_(ctx* c, fun_mut1__ptr_fut__int32___void f, _void p0);
pollfd* ref_of_val__ptr_pollfd__pollfd_(pollfd b);
pollfd deref__pollfd__ptr__pollfd_(ptr__pollfd p);
bool bits_intersect__q__bool__int16___int16_(int16 a, int16 b);
_void unsafe_increase_size___void__ptr_mut_arr__char___nat_(ctx* _ctx, mut_arr__char* a, nat increase_by);
mut_arr__ptr__char* make_mut_arr__ptr_mut_arr__ptr__char__nat____op_plus__arr__ptr__char__arr__ptr__char___arr__ptr__char___lambda0___closure__klb_op_plus__arr__ptr__char__arr__ptr__char___arr__ptr__char___lambda0_(ctx* _ctx, nat size, _op_plus__arr__ptr__char__arr__ptr__char___arr__ptr__char___lambda0___closure f);
mut_arr__ptr__char* new_uninitialized_mut_arr__ptr_mut_arr__ptr__char__nat_(ctx* _ctx, nat size);
_void make_mut_arr_worker___void__ptr_mut_arr__ptr__char___nat___map__arr__ptr__char__arr__arr__char___fun_mut1__ptr__char__arr__char__id10___lambda0___closure__klbmap__arr__ptr__char__arr__arr__char___fun_mut1__ptr__char__arr__char__id10___lambda0_(ctx* _ctx, mut_arr__ptr__char* m, nat i, map__arr__ptr__char__arr__arr__char___fun_mut1__ptr__char__arr__char__id10___lambda0___closure f);
ptr__ptr__char ptr_cast__ptr__ptr__char__ptr__byte_(ptr__byte p);
bool _op_greater__bool___int____int_(_int a, _int b);
_int wrap_mul___int___int____int_(_int a, _int b);
comparison _op_less_equal_greater__comparison__ptr_process_result___ptr_process_result_(process_result* a, process_result* b);
bool contains_recur__q__bool__arr__arr__char___arr__char___nat_(arr__arr__char a, arr__char value, nat i);
_void each_with_index_recur___void__arr__arr__char___lint_file__arr__ptr_failure__arr__char___lambda0___closure__klblint_file__arr__ptr_failure__arr__char___lambda0___nat_(ctx* _ctx, arr__arr__char a, lint_file__arr__ptr_failure__arr__char___lambda0___closure f, nat n);
cell__nat* new_cell__ptr_cell__nat__nat__id0_(ctx* _ctx);
_void each_with_index___void__arr__char___lines__arr__arr__char__arr__char___lambda0___closure__klblines__arr__arr__char__arr__char___lambda0_(ctx* _ctx, arr__char a, lines__arr__arr__char__arr__char___lambda0___closure f);
arr__char slice_from_to__arr__char__arr__char___nat___nat_(ctx* _ctx, arr__char a, nat begin, nat end);
nat get__nat__ptr_cell__nat_(cell__nat* c);
fut__int32* call__ptr_fut__int32__fun_ptr3__ptr_fut__int32__ptr_ctx__ptr__byte___void___ptr_ctx___ptr__byte____void_(fun_ptr3__ptr_fut__int32__ptr_ctx__ptr__byte___void f, ctx* p0, ptr__byte p1, _void p2);
bool zero__q__bool__int16_(int16 a);
int16 bits_and__int16__int16___int16_(int16 a, int16 b);
_void unsafe_set_size___void__ptr_mut_arr__char___nat_(ctx* _ctx, mut_arr__char* a, nat new_size);
_void make_mut_arr_worker___void__ptr_mut_arr__ptr__char___nat____op_plus__arr__ptr__char__arr__ptr__char___arr__ptr__char___lambda0___closure__klb_op_plus__arr__ptr__char__arr__ptr__char___arr__ptr__char___lambda0_(ctx* _ctx, mut_arr__ptr__char* m, nat i, _op_plus__arr__ptr__char__arr__ptr__char___arr__ptr__char___lambda0___closure f);
_void set_at___void__ptr_mut_arr__ptr__char___nat___ptr__char_(ctx* _ctx, mut_arr__ptr__char* a, nat index, ptr__char value);
ptr__char map__arr__ptr__char__arr__arr__char___fun_mut1__ptr__char__arr__char__id10___lambda0_(ctx* _ctx, map__arr__ptr__char__arr__arr__char___fun_mut1__ptr__char__arr__char__id10___lambda0___closure _closure, nat i);
bool _op_less_equal__bool___int____int_(_int a, _int b);
_void lint_file__arr__ptr_failure__arr__char___lambda0__(ctx* _ctx, lint_file__arr__ptr_failure__arr__char___lambda0___closure _closure, arr__char line, nat line_num);
_void each_with_index_recur___void__arr__char___lines__arr__arr__char__arr__char___lambda0___closure__klblines__arr__arr__char__arr__char___lambda0___nat_(ctx* _ctx, arr__char a, lines__arr__arr__char__arr__char___lambda0___closure f, nat n);
bool _op_equal_equal__bool__int16___int16_(int16 a, int16 b);
ptr__char _op_plus__arr__ptr__char__arr__ptr__char___arr__ptr__char___lambda0_(ctx* _ctx, _op_plus__arr__ptr__char__arr__ptr__char___arr__ptr__char___lambda0___closure _closure, nat i);
_void noctx_set_at___void__ptr_mut_arr__ptr__char___nat___ptr__char_(mut_arr__ptr__char* a, nat index, ptr__char value);
ptr__char convert_args__ptr__ptr__char__ptr__char___arr__arr__char___lambda0_(ctx* _ctx, arr__char it);
bool contains_subsequence__q__bool__arr__char___arr__char_(ctx* _ctx, arr__char a, arr__char subseq);
arr__char lstrip__arr__char__arr__char_(ctx* _ctx, arr__char a);
nat line_len__nat__arr__char_(ctx* _ctx, arr__char line);
arr__char to_str__arr__char__nat__id120_(ctx* _ctx);
_void lines__arr__arr__char__arr__char___lambda0__(ctx* _ctx, lines__arr__arr__char__arr__char___lambda0___closure _closure, char c, nat index);
comparison _op_less_equal_greater__comparison__int16___int16_(int16 a, int16 b);
bool has__q__bool__arr__char_(arr__char a);
nat n_tabs__nat__arr__char_(ctx* _ctx, arr__char line);
arr__char to_str__arr__char__nat__id12_(ctx* _ctx);
nat swap__nat__ptr_cell__nat___nat_(cell__nat* c, nat v);
arr__char _op_plus__arr__char__arr__char__id23___arr__char__id29_(ctx* _ctx);
_void set___void__ptr_cell__nat___nat_(cell__nat* c, nat v);
arr__char make_arr__arr__char__nat____op_plus__arr__char__arr__char__id23___arr__char__id29___lambda0___closure__klb_op_plus__arr__char__arr__char__id23___arr__char__id29___lambda0_(ctx* _ctx, nat size, _op_plus__arr__char__arr__char__id23___arr__char__id29___lambda0___closure f);
mut_arr__char* make_mut_arr__ptr_mut_arr__char__nat____op_plus__arr__char__arr__char__id23___arr__char__id29___lambda0___closure__klb_op_plus__arr__char__arr__char__id23___arr__char__id29___lambda0_(ctx* _ctx, nat size, _op_plus__arr__char__arr__char__id23___arr__char__id29___lambda0___closure f);
_void make_mut_arr_worker___void__ptr_mut_arr__char___nat____op_plus__arr__char__arr__char__id23___arr__char__id29___lambda0___closure__klb_op_plus__arr__char__arr__char__id23___arr__char__id29___lambda0_(ctx* _ctx, mut_arr__char* m, nat i, _op_plus__arr__char__arr__char__id23___arr__char__id29___lambda0___closure f);
char _op_plus__arr__char__arr__char__id23___arr__char__id29___lambda0_(ctx* _ctx, _op_plus__arr__char__arr__char__id23___arr__char__id29___lambda0___closure _closure, nat i);
int32 rt_main__int32__int32___ptr__ptr__char___fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char_(int32 argc, ptr__ptr__char argv, fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char main_ptr) {
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
	return ((gctx_by_val = (global_ctx) {new_lock__lock(), (arr__ptr_vat) _constant____arr__ptr_vat__0, 2ull, new_condition__condition(), 0, 0}),
	((gctx = (&(gctx_by_val))),
	((vat_by_val = new_vat__vat__ptr_global_ctx___nat___nat_(gctx, 0ull, 2ull)),
	((vat = (&(vat_by_val))),
	((vats = (arr__ptr_vat) {1ull, (&(vat))}),
	((gctx->vats = vats), 0,
	((ectx = new_exception_ctx__exception_ctx()),
	((tls = (thread_local_stuff) {(&(ectx))}),
	((ctx_by_val = new_ctx__ctx__ptr_global_ctx___ptr_thread_local_stuff___ptr_vat___nat_(gctx, (&(tls)), vat, 0ull)),
	((ctx = (&(ctx_by_val))),
	((add = (fun2__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char) {
		(fun_ptr4__ptr_fut__int32__ptr_ctx__ptr__byte__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char) add_first_task__ptr_fut__int32__arr__ptr__char___fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char___asLambda____dynamic, (ptr__byte) NULL }),
		((all_args = (arr__ptr__char) {(nat) (_int) argc, argv}),
		((main_fut = call_with_ctx__ptr_fut__int32__ptr_ctx___fun2__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char___arr__ptr__char___fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char_(ctx, add, all_args, main_ptr)),
		(run_threads___void__nat___ptr_global_ctx___fun_ptr2___void__nat__ptr_global_ctx_(2ull, gctx, (&thread_function___void__nat___ptr_global_ctx_)),
		gctx->any_unhandled_exceptions__q
			? 1
			: (matched = must_be_resolved__result__int32__exception__ptr_fut__int32_(main_fut),
				matched.kind == 0
				? (o = matched.as_ok__int32,
				o.value
				): matched.kind == 1
				? (e = matched.as_err__exception,
				((print_err_sync_no_newline___void__arr__char_((arr__char) _constant____arr__char__13),
				print_err_sync___void__arr__char_(e.value.message)),
				1)
				): _failint32())))))))))))))));
}
fut__int32* main__ptr_fut__int32__arr__arr__char_(ctx* _ctx, arr__arr__char args) {
	opt__test_options options;
	some__test_options s;
	opt__test_options matched;
	return ((options = parse_cmd_line_args__opt__test_options__arr__arr__char___arr__arr__char___fun1__test_options__arr__opt__arr__arr__char__id5_(_ctx, args, (arr__arr__char) _constant____arr__arr__char__0)),
	resolved__ptr_fut__int32__int32_(_ctx, (matched = options,
		matched.kind == 0
		? (print_help___void(_ctx),
		1)
		: matched.kind == 1
		? (s = matched.as_some__test_options,
		do_test__int32__test_options_(_ctx, s.value)
		): _failint32())));
}
lock new_lock__lock() {
	return (lock) {new_atomic_bool___atomic_bool()};
}
condition new_condition__condition() {
	return (condition) {new_lock__lock(), 0ull};
}
vat new_vat__vat__ptr_global_ctx___nat___nat_(global_ctx* gctx, nat id, nat max_threads) {
	mut_arr__nat actors;
	return ((actors = new_mut_arr_by_val_with_capacity_from_unmanaged_memory__mut_arr__nat__nat_(max_threads)),
	(vat) {gctx, id, new_gc__gc(), new_lock__lock(), new_mut_bag__mut_bag__task(), actors, 0ull, new_thread_safe_counter__thread_safe_counter(), (fun_mut1___void__exception) {
		(fun_ptr3___void__ptr_ctx__ptr__byte__exception) default_exception_handler___void__exception___asLambda___dynamic, (ptr__byte) NULL }});
}
exception_ctx new_exception_ctx__exception_ctx() {
	return (exception_ctx) {NULL, (exception) _constant____exception__0};
}
ctx new_ctx__ctx__ptr_global_ctx___ptr_thread_local_stuff___ptr_vat___nat_(global_ctx* gctx, thread_local_stuff* tls, vat* vat, nat actor_id) {
	return (ctx) {(ptr__byte) gctx, vat->id, actor_id, (ptr__byte) get_gc_ctx__ptr_gc_ctx__ptr_gc_((&(vat->gc))), (ptr__byte) tls->exception_ctx};
}
fut__int32* add_first_task__ptr_fut__int32__arr__ptr__char___fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char___asLambda____dynamic(ctx* _ctx, ptr__byte __unused, arr__ptr__char all_args, fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char main_ptr) {
	return add_first_task__ptr_fut__int32__arr__ptr__char___fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char_(_ctx, all_args, main_ptr);
}
fut__int32* call_with_ctx__ptr_fut__int32__ptr_ctx___fun2__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char___arr__ptr__char___fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char_(ctx* c, fun2__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char f, arr__ptr__char p0, fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char p1) {
	return f.fun_ptr(c, f.closure, p0, p1);
}
_void run_threads___void__nat___ptr_global_ctx___fun_ptr2___void__nat__ptr_global_ctx_(nat n_threads, global_ctx* arg, fun_ptr2___void__nat__ptr_global_ctx fun) {
	ptr__nat threads;
	ptr__thread_args__ptr_global_ctx thread_args;
	return ((threads = unmanaged_alloc_elements__ptr__nat__nat_(n_threads)),
	((thread_args = unmanaged_alloc_elements__ptr__thread_args__ptr_global_ctx__nat_(n_threads)),
	(((run_threads_recur___void__nat___nat___ptr__nat___ptr__thread_args__ptr_global_ctx___ptr_global_ctx___fun_ptr2___void__nat__ptr_global_ctx_(0ull, n_threads, threads, thread_args, arg, fun),
	join_threads_recur___void__nat___nat___ptr__nat_(0ull, n_threads, threads)),
	unmanaged_free___void__ptr__nat_(threads)),
	unmanaged_free___void__ptr__thread_args__ptr_global_ctx_(thread_args))));
}
result__int32__exception must_be_resolved__result__int32__exception__ptr_fut__int32_(fut__int32* f) {
	fut_state_resolved__int32 r;
	exception e;
	fut_state__int32 matched;
	return (matched = f->state,
		matched.kind == 0
		? hard_unreachable__result__int32__exception()
		: matched.kind == 1
		? (r = matched.as_fut_state_resolved__int32,
		(result__int32__exception) { 0, .as_ok__int32 = ok__ok__int32__int32_(r.value) }
		): matched.kind == 2
		? (e = matched.as_exception,
		(result__int32__exception) { 1, .as_err__exception = err__err__exception__exception_(e) }
		): _failresult__int32__exception());
}
_void print_err_sync_no_newline___void__arr__char_(arr__char s) {
	return write_sync_no_newline___void__int32___arr__char_(2, s);
}
_void print_err_sync___void__arr__char_(arr__char s) {
	return (print_err_sync_no_newline___void__arr__char_(s),
	print_err_sync_no_newline___void__arr__char_((arr__char) _constant____arr__char__4));
}
_void thread_function___void__nat___ptr_global_ctx_(nat thread_id, global_ctx* gctx) {
	exception_ctx ectx;
	thread_local_stuff tls;
	return ((ectx = new_exception_ctx__exception_ctx()),
	((tls = (thread_local_stuff) {(&(ectx))}),
	thread_function_recur___void__nat___ptr_global_ctx___ptr_thread_local_stuff_(thread_id, gctx, (&(tls)))));
}
opt__test_options parse_cmd_line_args__opt__test_options__arr__arr__char___arr__arr__char___fun1__test_options__arr__opt__arr__arr__char__id5_(ctx* _ctx, arr__arr__char args, arr__arr__char t_names) {
	parsed_cmd_line_args* parsed;
	mut_arr__opt__arr__arr__char* values;
	cell__bool* help;
	return ((parsed = parse_cmd_line_args_dynamic__ptr_parsed_cmd_line_args__arr__arr__char_(_ctx, args)),
	((assert___void__bool___arr__char_(_ctx, empty__q__bool__arr__arr__char_(parsed->nameless), (arr__char) _constant____arr__char__18),
	assert___void__bool_(_ctx, empty__q__bool__arr__arr__char_(parsed->after))),
	((values = fill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat___opt__arr__arr__char_(_ctx, t_names.size, (opt__arr__arr__char) _constant__opt__arr__arr__char__0)),
	((help = new_cell__ptr_cell__bool__bool__id1_(_ctx)),
	(each___void__ptr_dict__arr__char__arr__arr__char___parse_cmd_line_args__opt__test_options__arr__arr__char___arr__arr__char___fun1__test_options__arr__opt__arr__arr__char__id5___lambda0___closure__klbparse_cmd_line_args__opt__test_options__arr__arr__char___arr__arr__char___fun1__test_options__arr__opt__arr__arr__char__id5___lambda0_(_ctx, parsed->named, (parse_cmd_line_args__opt__test_options__arr__arr__char___arr__arr__char___fun1__test_options__arr__opt__arr__arr__char__id5___lambda0___closure) {t_names, help, values}),
	get__bool__ptr_cell__bool_(help)
		? (opt__test_options) _constant__opt__test_options__0
		: (opt__test_options) { 1, .as_some__test_options = some__some__test_options__test_options_(main__ptr_fut__int32__arr__arr__char___lambda0_(_ctx, freeze__arr__opt__arr__arr__char__ptr_mut_arr__opt__arr__arr__char_(values))) })))));
}
fut__int32* resolved__ptr_fut__int32__int32_(ctx* _ctx, int32 value) {
	return _initfut__int32(alloc__ptr__byte__nat_(_ctx, 32), (fut__int32) {new_lock__lock(), (fut_state__int32) { 1, .as_fut_state_resolved__int32 = (fut_state_resolved__int32) {value} }});
}
_void print_help___void(ctx* _ctx) {
	return (((print_sync___void__arr__char_((arr__char) _constant____arr__char__37),
	print_sync___void__arr__char_((arr__char) _constant____arr__char__38)),
	print_sync___void__arr__char_((arr__char) _constant____arr__char__39)),
	print_sync___void__arr__char_((arr__char) _constant____arr__char__40));
}
int32 do_test__int32__test_options_(ctx* _ctx, test_options options) {
	arr__char test_path;
	arr__char noze_path;
	arr__char noze_exe;
	dict__arr__char__arr__char* env;
	result__arr__char__arr__ptr_failure compile_failures;
	result__arr__char__arr__ptr_failure run_failures;
	result__arr__char__arr__ptr_failure all_failures;
	return ((test_path = parent_path__arr__char__arr__char_(_ctx, current_executable_path__arr__char(_ctx))),
	((noze_path = parent_path__arr__char__arr__char_(_ctx, test_path)),
	((noze_exe = child_path__arr__char__arr__char___arr__char_(_ctx, child_path__arr__char__arr__char___arr__char_(_ctx, noze_path, (arr__char) _constant____arr__char__45), (arr__char) _constant____arr__char__46)),
	((env = get_environ__ptr_dict__arr__char__arr__char(_ctx)),
	((compile_failures = run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options_(_ctx, child_path__arr__char__arr__char___arr__char_(_ctx, test_path, (arr__char) _constant____arr__char__48), noze_exe, env, options)),
	((run_failures = first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda0___closure__klbdo_test__int32__test_options___lambda0_(_ctx, compile_failures, (do_test__int32__test_options___lambda0___closure) {test_path, noze_exe, env, options})),
	((all_failures = first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda1___closure__klbdo_test__int32__test_options___lambda1_(_ctx, run_failures, (do_test__int32__test_options___lambda1___closure) {noze_path, options})),
	print_failures__int32__result__arr__char__arr__ptr_failure___test_options_(_ctx, all_failures, options))))))));
}
_atomic_bool new_atomic_bool___atomic_bool() {
	return (_atomic_bool) {0};
}
mut_arr__nat new_mut_arr_by_val_with_capacity_from_unmanaged_memory__mut_arr__nat__nat_(nat capacity) {
	return (mut_arr__nat) {0, 0ull, capacity, unmanaged_alloc_elements__ptr__nat__nat_(capacity)};
}
gc new_gc__gc() {
	return (gc) {new_lock__lock(), (opt__ptr_gc_ctx) _constant__opt__ptr_gc_ctx__0, 0, 0, NULL, NULL};
}
mut_bag__task new_mut_bag__mut_bag__task() {
	return (mut_bag__task) {(opt__ptr_mut_bag_node__task) _constant__opt__ptr_mut_bag_node__task__0};
}
thread_safe_counter new_thread_safe_counter__thread_safe_counter() {
	return new_thread_safe_counter__thread_safe_counter__nat__id0_();
}
_void default_exception_handler___void__exception___asLambda___dynamic(ctx* _ctx, ptr__byte __unused, exception e) {
	return default_exception_handler___void__exception_(_ctx, e);
}
gc_ctx* get_gc_ctx__ptr_gc_ctx__ptr_gc_(gc* gc) {
	gc_ctx* c;
	some__ptr_gc_ctx s;
	gc_ctx* c1;
	opt__ptr_gc_ctx matched;
	gc_ctx* res;
	return (acquire_lock___void__ptr_lock_((&(gc->lk))),
	((res = (matched = gc->context_head,
		matched.kind == 0
		? ((c = (gc_ctx*) malloc(8ull)),
		(((c->gc = gc), 0,
		(c->next_ctx = (opt__ptr_gc_ctx) _constant__opt__ptr_gc_ctx__0), 0),
		c))
		: matched.kind == 1
		? (s = matched.as_some__ptr_gc_ctx,
		((c1 = s.value),
		(((gc->context_head = c1->next_ctx), 0,
		(c1->next_ctx = (opt__ptr_gc_ctx) _constant__opt__ptr_gc_ctx__0), 0),
		c1))
		): _failVoidPtr())),
	(release_lock___void__ptr_lock_((&(gc->lk))),
	res)));
}
fut__int32* add_first_task__ptr_fut__int32__arr__ptr__char___fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char_(ctx* _ctx, arr__ptr__char all_args, fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char main_ptr) {
	return then2__ptr_fut__int32__ptr_fut___void___fun_ref0__int32_(_ctx, resolved__ptr_fut___void___void__id0_(_ctx), (fun_ref0__int32) {cur_actor__vat_and_actor_id(_ctx), (fun_mut0__ptr_fut__int32) {
		(fun_ptr2__ptr_fut__int32__ptr_ctx__ptr__byte) add_first_task__ptr_fut__int32__arr__ptr__char___fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char___lambda0__dynamic, (ptr__byte) _initadd_first_task__ptr_fut__int32__arr__ptr__char___fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char___lambda0___closure(alloc__ptr__byte__nat_(_ctx, 24), (add_first_task__ptr_fut__int32__arr__ptr__char___fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char___lambda0___closure) {all_args, main_ptr}) }});
}
ptr__nat unmanaged_alloc_elements__ptr__nat__nat_(nat size_elements) {
	ptr__byte bytes;
	return ((bytes = unmanaged_alloc_bytes__ptr__byte__nat_((size_elements * 8ull))),
	(ptr__nat) bytes);
}
ptr__thread_args__ptr_global_ctx unmanaged_alloc_elements__ptr__thread_args__ptr_global_ctx__nat_(nat size_elements) {
	ptr__byte bytes;
	return ((bytes = unmanaged_alloc_bytes__ptr__byte__nat_((size_elements * 24ull))),
	(ptr__thread_args__ptr_global_ctx) bytes);
}
_void run_threads_recur___void__nat___nat___ptr__nat___ptr__thread_args__ptr_global_ctx___ptr_global_ctx___fun_ptr2___void__nat__ptr_global_ctx_(nat i, nat n_threads, ptr__nat threads, ptr__thread_args__ptr_global_ctx thread_args, global_ctx* arg, fun_ptr2___void__nat__ptr_global_ctx fun) {
	ptr__thread_args__ptr_global_ctx thread_arg_ptr;
	ptr__nat thread_ptr;
	int32 err;
	return _op_equal_equal__bool__nat___nat_(i, n_threads)
		? 0
		: ((thread_arg_ptr = (thread_args + i)),
		(((*(thread_arg_ptr) = (thread_args__ptr_global_ctx) {fun, i, arg}), 0),
		((thread_ptr = (threads + i)),
		((err = pthread_create(as_cell__ptr_cell__nat__ptr__nat_(thread_ptr), NULL, (&thread_fun__ptr__byte__ptr__byte_), (ptr__byte) thread_arg_ptr)),
		zero__q__bool__int32_(err)
			? run_threads_recur___void__nat___nat___ptr__nat___ptr__thread_args__ptr_global_ctx___ptr_global_ctx___fun_ptr2___void__nat__ptr_global_ctx_(noctx_incr__nat__nat_(i), n_threads, threads, thread_args, arg, fun)
			: _op_equal_equal__bool__int32___int32_(err, 11)
				? todo___void()
				: todo___void()))));
}
_void join_threads_recur___void__nat___nat___ptr__nat_(nat i, nat n_threads, ptr__nat threads) {
	return _op_equal_equal__bool__nat___nat_(i, n_threads)
		? 0
		: (join_one_thread___void__nat_(*((threads + i))),
		join_threads_recur___void__nat___nat___ptr__nat_(noctx_incr__nat__nat_(i), n_threads, threads));
}
_void unmanaged_free___void__ptr__nat_(ptr__nat p) {
	return (free((ptr__byte) p), 0);
}
_void unmanaged_free___void__ptr__thread_args__ptr_global_ctx_(ptr__thread_args__ptr_global_ctx p) {
	return (free((ptr__byte) p), 0);
}
result__int32__exception hard_unreachable__result__int32__exception() {
	return hard_fail__result__int32__exception__arr__char__id12_();
}
ok__int32 ok__ok__int32__int32_(int32 t) {
	return (ok__int32) {t};
}
err__exception err__err__exception__exception_(exception t) {
	return (err__exception) {t};
}
_void write_sync_no_newline___void__int32___arr__char_(int32 fd, arr__char s) {
	_int res;
	return ((res = write(fd, (ptr__byte) s.data, s.size)),
	_op_equal_equal__bool___int____int_(res, (_int) s.size)
		? 0
		: todo___void());
}
_void thread_function_recur___void__nat___ptr_global_ctx___ptr_thread_local_stuff_(nat thread_id, global_ctx* gctx, thread_local_stuff* tls) {
	nat last_checked;
	ok__chosen_task ok_chosen_task;
	err__no_chosen_task e;
	result__chosen_task__no_chosen_task matched;
	return gctx->is_shut_down
		? (((acquire_lock___void__ptr_lock_((&(gctx->lk))),
		(gctx->n_live_threads = noctx_decr__nat__nat_(gctx->n_live_threads)), 0),
		assert_vats_are_shut_down___void__nat___arr__ptr_vat_(0ull, gctx->vats)),
		release_lock___void__ptr_lock_((&(gctx->lk))))
		: (hard_assert___void__bool_(_op_greater__bool__nat___nat_(gctx->n_live_threads, 0ull)),
		((last_checked = get_last_checked__nat__ptr_condition_((&(gctx->may_be_work_to_do)))),
		((matched = choose_task__result__chosen_task__no_chosen_task__ptr_global_ctx_(gctx),
			matched.kind == 0
			? (ok_chosen_task = matched.as_ok__chosen_task,
			do_task___void__ptr_global_ctx___ptr_thread_local_stuff___chosen_task_(gctx, tls, ok_chosen_task.value)
			): matched.kind == 1
			? (e = matched.as_err__no_chosen_task,
			(((e.value.last_thread_out
				? ((hard_forbid___void__bool_(gctx->is_shut_down),
				(gctx->is_shut_down = 1), 0),
				broadcast___void__ptr_condition_((&(gctx->may_be_work_to_do))))
				: wait_on___void__ptr_condition___nat_((&(gctx->may_be_work_to_do)), last_checked),
			acquire_lock___void__ptr_lock_((&(gctx->lk)))),
			(gctx->n_live_threads = noctx_incr__nat__nat_(gctx->n_live_threads)), 0),
			release_lock___void__ptr_lock_((&(gctx->lk))))
			): _fail_void()),
		thread_function_recur___void__nat___ptr_global_ctx___ptr_thread_local_stuff_(thread_id, gctx, tls))));
}
parsed_cmd_line_args* parse_cmd_line_args_dynamic__ptr_parsed_cmd_line_args__arr__arr__char_(ctx* _ctx, arr__arr__char args) {
	some__nat s;
	nat first_named_arg_index;
	arr__arr__char nameless;
	arr__arr__char rest;
	some__nat s2;
	nat sep_index;
	opt__nat matched;
	opt__nat matched1;
	return (matched1 = find_index__opt__nat__arr__arr__char___fun_mut1__bool__arr__char__id6_(_ctx, args),
		matched1.kind == 0
		? _initparsed_cmd_line_args(alloc__ptr__byte__nat_(_ctx, 40), (parsed_cmd_line_args) {args, &_constant____ptr_dict__arr__char__arr__arr__char__0, (arr__arr__char) _constant____arr__arr__char__1})
		: matched1.kind == 1
		? (s = matched1.as_some__nat,
		((first_named_arg_index = s.value),
		((nameless = slice_up_to__arr__arr__char__arr__arr__char___nat_(_ctx, args, first_named_arg_index)),
		((rest = slice_starting_at__arr__arr__char__arr__arr__char___nat_(_ctx, args, first_named_arg_index)),
		(matched = find_index__opt__nat__arr__arr__char___fun_mut1__bool__arr__char__id7_(_ctx, rest),
			matched.kind == 0
			? _initparsed_cmd_line_args(alloc__ptr__byte__nat_(_ctx, 40), (parsed_cmd_line_args) {nameless, parse_named_args__ptr_dict__arr__char__arr__arr__char__arr__arr__char_(_ctx, rest), (arr__arr__char) _constant____arr__arr__char__1})
			: matched.kind == 1
			? (s2 = matched.as_some__nat,
			((sep_index = s2.value),
			_initparsed_cmd_line_args(alloc__ptr__byte__nat_(_ctx, 40), (parsed_cmd_line_args) {nameless, parse_named_args__ptr_dict__arr__char__arr__arr__char__arr__arr__char_(_ctx, slice_up_to__arr__arr__char__arr__arr__char___nat_(_ctx, rest, sep_index)), slice_after__arr__arr__char__arr__arr__char___nat_(_ctx, rest, sep_index)}))
			): _failVoidPtr()))))
		): _failVoidPtr());
}
_void assert___void__bool___arr__char_(ctx* _ctx, bool condition, arr__char message) {
	return (condition ? 0 : fail___void__arr__char_(_ctx, message));
}
bool empty__q__bool__arr__arr__char_(arr__arr__char a) {
	return zero__q__bool__nat_(a.size);
}
_void assert___void__bool_(ctx* _ctx, bool condition) {
	return assert___void__bool___arr__char_(_ctx, condition, (arr__char) _constant____arr__char__8);
}
mut_arr__opt__arr__arr__char* fill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat___opt__arr__arr__char_(ctx* _ctx, nat size, opt__arr__arr__char value) {
	return make_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat___fill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat___opt__arr__arr__char___lambda0___closure__klbfill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat___opt__arr__arr__char___lambda0_(_ctx, size, (fill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat___opt__arr__arr__char___lambda0___closure) {value});
}
cell__bool* new_cell__ptr_cell__bool__bool__id1_(ctx* _ctx) {
	return _initcell__bool(alloc__ptr__byte__nat_(_ctx, 1), (cell__bool) {0});
}
_void each___void__ptr_dict__arr__char__arr__arr__char___parse_cmd_line_args__opt__test_options__arr__arr__char___arr__arr__char___fun1__test_options__arr__opt__arr__arr__char__id5___lambda0___closure__klbparse_cmd_line_args__opt__test_options__arr__arr__char___arr__arr__char___fun1__test_options__arr__opt__arr__arr__char__id5___lambda0_(ctx* _ctx, dict__arr__char__arr__arr__char* d, parse_cmd_line_args__opt__test_options__arr__arr__char___arr__arr__char___fun1__test_options__arr__opt__arr__arr__char__id5___lambda0___closure f) {
	return empty__q__bool__ptr_dict__arr__char__arr__arr__char_(_ctx, d)
		? 0
		: (parse_cmd_line_args__opt__test_options__arr__arr__char___arr__arr__char___fun1__test_options__arr__opt__arr__arr__char__id5___lambda0__(_ctx, f, first__arr__char__arr__arr__char_(_ctx, d->keys), first__arr__arr__char__arr__arr__arr__char_(_ctx, d->values)),
		each___void__ptr_dict__arr__char__arr__arr__char___parse_cmd_line_args__opt__test_options__arr__arr__char___arr__arr__char___fun1__test_options__arr__opt__arr__arr__char__id5___lambda0___closure__klbparse_cmd_line_args__opt__test_options__arr__arr__char___arr__arr__char___fun1__test_options__arr__opt__arr__arr__char__id5___lambda0_(_ctx, _initdict__arr__char__arr__arr__char(alloc__ptr__byte__nat_(_ctx, 32), (dict__arr__char__arr__arr__char) {tail__arr__arr__char__arr__arr__char_(_ctx, d->keys), tail__arr__arr__arr__char__arr__arr__arr__char_(_ctx, d->values)}), f));
}
bool get__bool__ptr_cell__bool_(cell__bool* c) {
	return c->value;
}
some__test_options some__some__test_options__test_options_(test_options t) {
	return (some__test_options) {t};
}
test_options main__ptr_fut__int32__arr__arr__char___lambda0_(ctx* _ctx, arr__opt__arr__arr__char values) {
	opt__arr__arr__char print_tests_strs;
	opt__arr__arr__char max_failures_strs;
	bool print_tests__q;
	some__arr__arr__char s;
	arr__arr__char strs;
	opt__arr__arr__char matched;
	nat max_failures;
	return ((print_tests_strs = at__opt__arr__arr__char__arr__opt__arr__arr__char___nat_(_ctx, values, 0ull)),
	((max_failures_strs = at__opt__arr__arr__char__arr__opt__arr__arr__char___nat_(_ctx, values, 1ull)),
	((print_tests__q = has__q__bool__opt__arr__arr__char_(print_tests_strs)),
	((max_failures = (matched = max_failures_strs,
		matched.kind == 0
		? 100ull
		: matched.kind == 1
		? (s = matched.as_some__arr__arr__char,
		((strs = s.value),
		(assert___void__bool_(_ctx, _op_equal_equal__bool__nat___nat_(strs.size, 1ull)),
		literal__nat__arr__char_(_ctx, first__arr__char__arr__arr__char_(_ctx, strs))))
		): _failnat())),
	(test_options) {print_tests__q, max_failures}))));
}
arr__opt__arr__arr__char freeze__arr__opt__arr__arr__char__ptr_mut_arr__opt__arr__arr__char_(mut_arr__opt__arr__arr__char* a) {
	return ((a->frozen__q = 1), 0,
	unsafe_as_arr__arr__opt__arr__arr__char__ptr_mut_arr__opt__arr__arr__char_(a));
}
ptr__byte alloc__ptr__byte__nat_(ctx* _ctx, nat size) {
	return gc_alloc__ptr__byte__ptr_gc___nat_(_ctx, get_gc__ptr_gc(_ctx), size);
}
_void print_sync___void__arr__char_(arr__char s) {
	return (print_sync_no_newline___void__arr__char_(s),
	print_sync_no_newline___void__arr__char_((arr__char) _constant____arr__char__4));
}
arr__char parent_path__arr__char__arr__char_(ctx* _ctx, arr__char a) {
	some__nat s;
	opt__nat matched;
	return (matched = r_index_of__opt__nat__arr__char___char_(_ctx, a, '/'),
		matched.kind == 0
		? (arr__char) _constant____arr__char__5
		: matched.kind == 1
		? (s = matched.as_some__nat,
		slice_up_to__arr__char__arr__char___nat_(_ctx, a, s.value)
		): _failarr__char());
}
arr__char current_executable_path__arr__char(ctx* _ctx) {
	return read_link__arr__char__arr__char_(_ctx, (arr__char) _constant____arr__char__43);
}
arr__char child_path__arr__char__arr__char___arr__char_(ctx* _ctx, arr__char a, arr__char child_name) {
	return _op_plus__arr__char__arr__char___arr__char_(_ctx, _op_plus__arr__char__arr__char___arr__char_(_ctx, a, (arr__char) _constant____arr__char__44), child_name);
}
dict__arr__char__arr__char* get_environ__ptr_dict__arr__char__arr__char(ctx* _ctx) {
	mut_dict__arr__char__arr__char res;
	return ((res = new_mut_dict__mut_dict__arr__char__arr__char(_ctx)),
	(get_environ_recur___void__ptr__ptr__char___mut_dict__arr__char__arr__char_(_ctx, environ, res),
	freeze__ptr_dict__arr__char__arr__char__mut_dict__arr__char__arr__char_(_ctx, res)));
}
result__arr__char__arr__ptr_failure run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options_(ctx* _ctx, arr__char path, arr__char path_to_noze, dict__arr__char__arr__char* env, test_options options) {
	arr__arr__char tests;
	arr__ptr_failure failures;
	return ((tests = list_compile_error_tests__arr__arr__char__arr__char_(_ctx, path)),
	((failures = flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure__klbrun_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0_(_ctx, tests, options.max_failures, (run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure) {options, path_to_noze, env})),
	has__q__bool__arr__ptr_failure_(failures)
		? (result__arr__char__arr__ptr_failure) { 1, .as_err__arr__ptr_failure = err__err__arr__ptr_failure__arr__ptr_failure_(with_max_size__arr__ptr_failure__arr__ptr_failure___nat_(_ctx, failures, options.max_failures)) }
		: (result__arr__char__arr__ptr_failure) { 0, .as_ok__arr__char = ok__ok__arr__char__arr__char_(_op_plus__arr__char__arr__char___arr__char_(_ctx, _op_plus__arr__char__arr__char___arr__char_(_ctx, (arr__char) _constant____arr__char__74, to_str__arr__char__nat_(_ctx, tests.size)), (arr__char) _constant____arr__char__75)) }));
}
result__arr__char__arr__ptr_failure first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda0___closure__klbdo_test__int32__test_options___lambda0_(ctx* _ctx, result__arr__char__arr__ptr_failure a, do_test__int32__test_options___lambda0___closure b) {
	return then__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda0___closure__klbdo_test__int32__test_options___lambda0___lambda0___closure__klbfirst_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda0___closure__klbdo_test__int32__test_options___lambda0___lambda0_(_ctx, a, (first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda0___closure__klbdo_test__int32__test_options___lambda0___lambda0___closure) {b});
}
result__arr__char__arr__ptr_failure first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda1___closure__klbdo_test__int32__test_options___lambda1_(ctx* _ctx, result__arr__char__arr__ptr_failure a, do_test__int32__test_options___lambda1___closure b) {
	return then__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda1___closure__klbdo_test__int32__test_options___lambda1___lambda0___closure__klbfirst_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda1___closure__klbdo_test__int32__test_options___lambda1___lambda0_(_ctx, a, (first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda1___closure__klbdo_test__int32__test_options___lambda1___lambda0___closure) {b});
}
int32 print_failures__int32__result__arr__char__arr__ptr_failure___test_options_(ctx* _ctx, result__arr__char__arr__ptr_failure failures, test_options options) {
	ok__arr__char o;
	err__arr__ptr_failure e;
	nat n_failures;
	result__arr__char__arr__ptr_failure matched;
	return (matched = failures,
		matched.kind == 0
		? (o = matched.as_ok__arr__char,
		(print_sync___void__arr__char_(o.value),
		0)
		): matched.kind == 1
		? (e = matched.as_err__arr__ptr_failure,
		(each___void__arr__ptr_failure___fun_mut1___void__ptr_failure__id12_(_ctx, e.value),
		((n_failures = e.value.size),
		(print_sync___void__arr__char_(_op_equal_equal__bool__nat___nat_(n_failures, options.max_failures)
			? _op_plus__arr__char__arr__char___arr__char_(_ctx, _op_plus__arr__char__arr__char___arr__char_(_ctx, (arr__char) _constant____arr__char__106, to_str__arr__char__nat_(_ctx, options.max_failures)), (arr__char) _constant____arr__char__107)
			: _op_plus__arr__char__arr__char___arr__char_(_ctx, to_str__arr__char__nat_(_ctx, n_failures), (arr__char) _constant____arr__char__107)),
		to_int32__int32__nat_(_ctx, n_failures))))
		): _failint32());
}
thread_safe_counter new_thread_safe_counter__thread_safe_counter__nat__id0_() {
	return (thread_safe_counter) {new_lock__lock(), 0ull};
}
_void default_exception_handler___void__exception_(ctx* _ctx, exception e) {
	return ((print_err_sync_no_newline___void__arr__char_((arr__char) _constant____arr__char__1),
	print_err_sync___void__arr__char_((empty__q__bool__arr__char_(e.message) ? (arr__char) _constant____arr__char__3 : e.message))),
	(get_gctx__ptr_global_ctx(_ctx)->any_unhandled_exceptions__q = 1), 0);
}
_void acquire_lock___void__ptr_lock_(lock* l) {
	return acquire_lock_recur___void__ptr_lock___nat_(l, 0ull);
}
_void release_lock___void__ptr_lock_(lock* l) {
	return must_unset___void__ptr__atomic_bool_((&(l->is_locked)));
}
fut__int32* then2__ptr_fut__int32__ptr_fut___void___fun_ref0__int32_(ctx* _ctx, fut___void* f, fun_ref0__int32 cb) {
	return then__ptr_fut__int32__ptr_fut___void___fun_ref1__int32___void_(_ctx, f, (fun_ref1__int32___void) {cur_actor__vat_and_actor_id(_ctx), (fun_mut1__ptr_fut__int32___void) {
		(fun_ptr3__ptr_fut__int32__ptr_ctx__ptr__byte___void) then2__ptr_fut__int32__ptr_fut___void___fun_ref0__int32___lambda0___dynamic, (ptr__byte) _initthen2__ptr_fut__int32__ptr_fut___void___fun_ref0__int32___lambda0___closure(alloc__ptr__byte__nat_(_ctx, 32), (then2__ptr_fut__int32__ptr_fut___void___fun_ref0__int32___lambda0___closure) {cb}) }});
}
fut___void* resolved__ptr_fut___void___void__id0_(ctx* _ctx) {
	return _initfut___void(alloc__ptr__byte__nat_(_ctx, 32), (fut___void) {new_lock__lock(), (fut_state___void) _constant__fut_state___void__0});
}
vat_and_actor_id cur_actor__vat_and_actor_id(ctx* _ctx) {
	ctx* c;
	return ((c = _ctx),
	(vat_and_actor_id) {c->vat_id, c->actor_id});
}
fut__int32* add_first_task__ptr_fut__int32__arr__ptr__char___fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char___lambda0__dynamic(ctx* _ctx, add_first_task__ptr_fut__int32__arr__ptr__char___fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char___lambda0___closure* _closure) {
	arr__ptr__char args;
	return ((args = tail__arr__ptr__char__arr__ptr__char_(_ctx, _closure->all_args)),
	_closure->main_ptr(_ctx, map__arr__arr__char__arr__ptr__char___fun_mut1__arr__char__ptr__char__id1_(_ctx, args)));
}
ptr__byte unmanaged_alloc_bytes__ptr__byte__nat_(nat size) {
	ptr__byte res;
	return ((res = malloc(size)),
	(hard_forbid___void__bool_(null__q__bool__ptr__byte_(res)),
	res));
}
bool _op_equal_equal__bool__nat___nat_(nat a, nat b) {
	comparison matched;
	return (matched = _op_less_equal_greater__comparison__nat___nat_(a, b),
		matched.kind == 0
		? 0
		: matched.kind == 1
		? 1
		: matched.kind == 2
		? 0
		: _failbool());
}
cell__nat* as_cell__ptr_cell__nat__ptr__nat_(ptr__nat p) {
	return (cell__nat*) (ptr__byte) p;
}
bool zero__q__bool__int32_(int32 i) {
	return _op_equal_equal__bool__int32___int32_(i, 0);
}
nat noctx_incr__nat__nat_(nat n) {
	return (hard_assert___void__bool_(_op_less__bool__nat___nat_(n, 1000000000ull)),
	wrap_incr__nat__nat_(n));
}
bool _op_equal_equal__bool__int32___int32_(int32 a, int32 b) {
	comparison matched;
	return (matched = _op_less_equal_greater__comparison__int32___int32_(a, b),
		matched.kind == 0
		? 0
		: matched.kind == 1
		? 1
		: matched.kind == 2
		? 0
		: _failbool());
}
_void todo___void() {
	return hard_fail___void__arr__char__id2_();
}
ptr__byte thread_fun__ptr__byte__ptr__byte_(ptr__byte args_ptr) {
	thread_args__ptr_global_ctx* args;
	return ((args = (thread_args__ptr_global_ctx*) args_ptr),
	(args->fun(args->thread_id, args->arg),
	NULL));
}
_void join_one_thread___void__nat_(nat tid) {
	cell__ptr__byte thread_return;
	int32 err;
	return ((thread_return = (cell__ptr__byte) {NULL}),
	((err = pthread_join(tid, (&(thread_return)))),
	(zero__q__bool__int32_(err)
		? 0
		: _op_equal_equal__bool__int32___int32_(err, 22)
			? todo___void()
			: _op_equal_equal__bool__int32___int32_(err, 3)
				? todo___void()
				: todo___void(),
	hard_assert___void__bool_(_op_equal_equal__bool__ptr__byte___ptr__byte_(get__ptr__byte__ptr_cell__ptr__byte_((&(thread_return))), NULL)))));
}
result__int32__exception hard_fail__result__int32__exception__arr__char__id12_() {
	assert(0);
}
bool _op_equal_equal__bool___int____int_(_int a, _int b) {
	comparison matched;
	return (matched = _op_less_equal_greater__comparison___int____int_(a, b),
		matched.kind == 0
		? 0
		: matched.kind == 1
		? 1
		: matched.kind == 2
		? 0
		: _failbool());
}
nat noctx_decr__nat__nat_(nat n) {
	return (hard_forbid___void__bool_(zero__q__bool__nat_(n)),
	(n - 1ull));
}
_void assert_vats_are_shut_down___void__nat___arr__ptr_vat_(nat i, arr__ptr_vat vats) {
	vat* vat;
	return _op_equal_equal__bool__nat___nat_(i, vats.size)
		? 0
		: ((vat = noctx_at__ptr_vat__arr__ptr_vat___nat_(vats, i)),
		(((((acquire_lock___void__ptr_lock_((&(vat->tasks_lock))),
		hard_forbid___void__bool_((&(vat->gc))->needs_gc)),
		hard_assert___void__bool_(zero__q__bool__nat_(vat->n_threads_running))),
		hard_assert___void__bool_(empty__q__bool__ptr_mut_bag__task_((&(vat->tasks))))),
		release_lock___void__ptr_lock_((&(vat->tasks_lock)))),
		assert_vats_are_shut_down___void__nat___arr__ptr_vat_(noctx_incr__nat__nat_(i), vats)));
}
_void hard_assert___void__bool_(bool condition) {
	return (condition ? 0 : hard_fail___void__arr__char__id0_());
}
bool _op_greater__bool__nat___nat_(nat a, nat b) {
	return !(_op_less_equal__bool__nat___nat_(a, b));
}
nat get_last_checked__nat__ptr_condition_(condition* c) {
	return c->value;
}
result__chosen_task__no_chosen_task choose_task__result__chosen_task__no_chosen_task__ptr_global_ctx_(global_ctx* gctx) {
	some__chosen_task s;
	opt__chosen_task matched;
	result__chosen_task__no_chosen_task res;
	return (acquire_lock___void__ptr_lock_((&(gctx->lk))),
	((res = (matched = choose_task_recur__opt__chosen_task__arr__ptr_vat___nat_(gctx->vats, 0ull),
		matched.kind == 0
		? ((gctx->n_live_threads = noctx_decr__nat__nat_(gctx->n_live_threads)), 0,
		(result__chosen_task__no_chosen_task) { 1, .as_err__no_chosen_task = err__err__no_chosen_task__no_chosen_task_((no_chosen_task) {zero__q__bool__nat_(gctx->n_live_threads)}) })
		: matched.kind == 1
		? (s = matched.as_some__chosen_task,
		(result__chosen_task__no_chosen_task) { 0, .as_ok__chosen_task = ok__ok__chosen_task__chosen_task_(s.value) }
		): _failresult__chosen_task__no_chosen_task())),
	(release_lock___void__ptr_lock_((&(gctx->lk))),
	res)));
}
_void do_task___void__ptr_global_ctx___ptr_thread_local_stuff___chosen_task_(global_ctx* gctx, thread_local_stuff* tls, chosen_task chosen_task) {
	vat* vat;
	some__task some_task;
	task task;
	ctx ctx;
	opt__task matched;
	return ((vat = chosen_task.vat),
	((((matched = chosen_task.task_or_gc,
		matched.kind == 0
		? (todo___void(),
		broadcast___void__ptr_condition_((&(gctx->may_be_work_to_do))))
		: matched.kind == 1
		? (some_task = matched.as_some__task,
		((task = some_task.value),
		((ctx = new_ctx__ctx__ptr_global_ctx___ptr_thread_local_stuff___ptr_vat___nat_(gctx, tls, vat, task.actor_id)),
		((((call_with_ctx___void__ptr_ctx___fun_mut0___void_((&(ctx)), task.fun),
		acquire_lock___void__ptr_lock_((&(vat->tasks_lock)))),
		noctx_must_remove_unordered___void__ptr_mut_arr__nat___nat_((&(vat->currently_running_actors)), task.actor_id)),
		release_lock___void__ptr_lock_((&(vat->tasks_lock)))),
		return_ctx___void__ptr_ctx_((&(ctx))))))
		): _fail_void()),
	acquire_lock___void__ptr_lock_((&(vat->tasks_lock)))),
	(vat->n_threads_running = noctx_decr__nat__nat_(vat->n_threads_running)), 0),
	release_lock___void__ptr_lock_((&(vat->tasks_lock)))));
}
_void hard_forbid___void__bool_(bool condition) {
	return hard_assert___void__bool_(!(condition));
}
_void broadcast___void__ptr_condition_(condition* c) {
	return ((acquire_lock___void__ptr_lock_((&(c->lk))),
	(c->value = noctx_incr__nat__nat_(c->value)), 0),
	release_lock___void__ptr_lock_((&(c->lk))));
}
_void wait_on___void__ptr_condition___nat_(condition* c, nat last_checked) {
	return _op_equal_equal__bool__nat___nat_(c->value, last_checked)
		? (yield_thread___void(),
		wait_on___void__ptr_condition___nat_(c, last_checked))
		: 0;
}
opt__nat find_index__opt__nat__arr__arr__char___fun_mut1__bool__arr__char__id6_(ctx* _ctx, arr__arr__char a) {
	return find_index_recur__opt__nat__arr__arr__char___nat___fun_mut1__bool__arr__char__id6_(_ctx, a, 0ull);
}
arr__arr__char slice_up_to__arr__arr__char__arr__arr__char___nat_(ctx* _ctx, arr__arr__char a, nat size) {
	return (assert___void__bool_(_ctx, _op_less__bool__nat___nat_(size, a.size)),
	slice__arr__arr__char__arr__arr__char___nat___nat_(_ctx, a, 0ull, size));
}
arr__arr__char slice_starting_at__arr__arr__char__arr__arr__char___nat_(ctx* _ctx, arr__arr__char a, nat begin) {
	return (assert___void__bool_(_ctx, _op_less_equal__bool__nat___nat_(begin, a.size)),
	slice__arr__arr__char__arr__arr__char___nat___nat_(_ctx, a, begin, _op_minus__nat__nat___nat_(_ctx, a.size, begin)));
}
opt__nat find_index__opt__nat__arr__arr__char___fun_mut1__bool__arr__char__id7_(ctx* _ctx, arr__arr__char a) {
	return find_index_recur__opt__nat__arr__arr__char___nat___fun_mut1__bool__arr__char__id7_(_ctx, a, 0ull);
}
dict__arr__char__arr__arr__char* parse_named_args__ptr_dict__arr__char__arr__arr__char__arr__arr__char_(ctx* _ctx, arr__arr__char args) {
	mut_dict__arr__char__arr__arr__char b;
	return ((b = new_mut_dict__mut_dict__arr__char__arr__arr__char(_ctx)),
	(parse_named_args_recur___void__arr__arr__char___mut_dict__arr__char__arr__arr__char_(_ctx, args, b),
	freeze__ptr_dict__arr__char__arr__arr__char__mut_dict__arr__char__arr__arr__char_(_ctx, b)));
}
arr__arr__char slice_after__arr__arr__char__arr__arr__char___nat_(ctx* _ctx, arr__arr__char a, nat before_begin) {
	return slice_starting_at__arr__arr__char__arr__arr__char___nat_(_ctx, a, incr__nat__nat_(_ctx, before_begin));
}
_void fail___void__arr__char_(ctx* _ctx, arr__char reason) {
	return throw___void__exception_(_ctx, (exception) {reason});
}
bool zero__q__bool__nat_(nat n) {
	return _op_equal_equal__bool__nat___nat_(n, 0ull);
}
mut_arr__opt__arr__arr__char* make_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat___fill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat___opt__arr__arr__char___lambda0___closure__klbfill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat___opt__arr__arr__char___lambda0_(ctx* _ctx, nat size, fill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat___opt__arr__arr__char___lambda0___closure f) {
	mut_arr__opt__arr__arr__char* res;
	return ((res = new_uninitialized_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat_(_ctx, size)),
	(make_mut_arr_worker___void__ptr_mut_arr__opt__arr__arr__char___nat___fill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat___opt__arr__arr__char___lambda0___closure__klbfill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat___opt__arr__arr__char___lambda0_(_ctx, res, 0ull, f),
	res));
}
bool empty__q__bool__ptr_dict__arr__char__arr__arr__char_(ctx* _ctx, dict__arr__char__arr__arr__char* d) {
	return empty__q__bool__arr__arr__char_(d->keys);
}
_void parse_cmd_line_args__opt__test_options__arr__arr__char___arr__arr__char___fun1__test_options__arr__opt__arr__arr__char__id5___lambda0__(ctx* _ctx, parse_cmd_line_args__opt__test_options__arr__arr__char___arr__arr__char___fun1__test_options__arr__opt__arr__arr__char__id5___lambda0___closure _closure, arr__char key, arr__arr__char value) {
	some__nat s;
	nat idx;
	opt__nat matched;
	return (matched = index_of__opt__nat__arr__arr__char___arr__char_(_ctx, _closure.t_names, key),
		matched.kind == 0
		? _op_equal_equal__bool__arr__char___arr__char_(key, (arr__char) _constant____arr__char__19)
			? set___void__ptr_cell__bool___bool_(_closure.help, 1)
			: fail___void__arr__char_(_ctx, _op_plus__arr__char__arr__char___arr__char_(_ctx, (arr__char) _constant____arr__char__20, key))
		: matched.kind == 1
		? (s = matched.as_some__nat,
		((idx = s.value),
		(forbid___void__bool_(_ctx, has__q__bool__opt__arr__arr__char_(at__opt__arr__arr__char__ptr_mut_arr__opt__arr__arr__char___nat_(_ctx, _closure.values, idx))),
		set_at___void__ptr_mut_arr__opt__arr__arr__char___nat___opt__arr__arr__char_(_ctx, _closure.values, idx, (opt__arr__arr__char) { 1, .as_some__arr__arr__char = some__some__arr__arr__char__arr__arr__char_(value) })))
		): _fail_void());
}
arr__char first__arr__char__arr__arr__char_(ctx* _ctx, arr__arr__char a) {
	return (forbid___void__bool_(_ctx, empty__q__bool__arr__arr__char_(a)),
	at__arr__char__arr__arr__char___nat_(_ctx, a, 0ull));
}
arr__arr__char first__arr__arr__char__arr__arr__arr__char_(ctx* _ctx, arr__arr__arr__char a) {
	return (forbid___void__bool_(_ctx, empty__q__bool__arr__arr__arr__char_(a)),
	at__arr__arr__char__arr__arr__arr__char___nat_(_ctx, a, 0ull));
}
arr__arr__char tail__arr__arr__char__arr__arr__char_(ctx* _ctx, arr__arr__char a) {
	return (forbid___void__bool_(_ctx, empty__q__bool__arr__arr__char_(a)),
	slice_starting_at__arr__arr__char__arr__arr__char___nat_(_ctx, a, 1ull));
}
arr__arr__arr__char tail__arr__arr__arr__char__arr__arr__arr__char_(ctx* _ctx, arr__arr__arr__char a) {
	return (forbid___void__bool_(_ctx, empty__q__bool__arr__arr__arr__char_(a)),
	slice_starting_at__arr__arr__arr__char__arr__arr__arr__char___nat_(_ctx, a, 1ull));
}
opt__arr__arr__char at__opt__arr__arr__char__arr__opt__arr__arr__char___nat_(ctx* _ctx, arr__opt__arr__arr__char a, nat index) {
	return (assert___void__bool_(_ctx, _op_less__bool__nat___nat_(index, a.size)),
	noctx_at__opt__arr__arr__char__arr__opt__arr__arr__char___nat_(a, index));
}
bool has__q__bool__opt__arr__arr__char_(opt__arr__arr__char a) {
	return !(empty__q__bool__opt__arr__arr__char_(a));
}
nat literal__nat__arr__char_(ctx* _ctx, arr__char s) {
	nat higher_digits;
	return empty__q__bool__arr__char_(s)
		? 0ull
		: ((higher_digits = literal__nat__arr__char_(_ctx, rtail__arr__char__arr__char_(_ctx, s))),
		_op_plus__nat__nat___nat_(_ctx, _op_times__nat__nat___nat_(_ctx, higher_digits, 10ull), char_to_nat__nat__char_(last__char__arr__char_(_ctx, s))));
}
arr__opt__arr__arr__char unsafe_as_arr__arr__opt__arr__arr__char__ptr_mut_arr__opt__arr__arr__char_(mut_arr__opt__arr__arr__char* a) {
	return (arr__opt__arr__arr__char) {a->size, a->data};
}
ptr__byte gc_alloc__ptr__byte__ptr_gc___nat_(ctx* _ctx, gc* gc, nat size) {
	some__ptr__byte s;
	opt__ptr__byte matched;
	return (matched = try_gc_alloc__opt__ptr__byte__ptr_gc___nat_(gc, size),
		matched.kind == 0
		? todo__ptr__byte()
		: matched.kind == 1
		? (s = matched.as_some__ptr__byte,
		s.value
		): _failptr__byte());
}
gc* get_gc__ptr_gc(ctx* _ctx) {
	return get_gc_ctx__ptr_gc_ctx(_ctx)->gc;
}
_void print_sync_no_newline___void__arr__char_(arr__char s) {
	return write_sync_no_newline___void__int32___arr__char_(1, s);
}
opt__nat r_index_of__opt__nat__arr__char___char_(ctx* _ctx, arr__char a, char value) {
	return find_rindex__opt__nat__arr__char___r_index_of__opt__nat__arr__char___char___lambda0___closure__klbr_index_of__opt__nat__arr__char___char___lambda0_(_ctx, a, (r_index_of__opt__nat__arr__char___char___lambda0___closure) {value});
}
arr__char slice_up_to__arr__char__arr__char___nat_(ctx* _ctx, arr__char a, nat size) {
	return (assert___void__bool_(_ctx, _op_less__bool__nat___nat_(size, a.size)),
	slice__arr__char__arr__char___nat___nat_(_ctx, a, 0ull, size));
}
arr__char read_link__arr__char__arr__char_(ctx* _ctx, arr__char path) {
	mut_arr__char* buff;
	_int size;
	return ((buff = new_uninitialized_mut_arr__ptr_mut_arr__char__nat__id1000_(_ctx)),
	((size = readlink(to_c_str__ptr__char__arr__char_(_ctx, path), buff->data, buff->size)),
	(check_errno_if_neg_one___void___int_(_ctx, size),
	slice_up_to__arr__char__arr__char___nat_(_ctx, freeze__arr__char__ptr_mut_arr__char_(buff), to_nat__nat___int_(_ctx, size)))));
}
arr__char _op_plus__arr__char__arr__char___arr__char_(ctx* _ctx, arr__char a, arr__char b) {
	return make_arr__arr__char__nat____op_plus__arr__char__arr__char___arr__char___lambda0___closure__klb_op_plus__arr__char__arr__char___arr__char___lambda0_(_ctx, _op_plus__nat__nat___nat_(_ctx, a.size, b.size), (_op_plus__arr__char__arr__char___arr__char___lambda0___closure) {a, b});
}
mut_dict__arr__char__arr__char new_mut_dict__mut_dict__arr__char__arr__char(ctx* _ctx) {
	return (mut_dict__arr__char__arr__char) {new_mut_arr__ptr_mut_arr__arr__char(_ctx), new_mut_arr__ptr_mut_arr__arr__char(_ctx)};
}
_void get_environ_recur___void__ptr__ptr__char___mut_dict__arr__char__arr__char_(ctx* _ctx, ptr__ptr__char env, mut_dict__arr__char__arr__char res) {
	return null__q__bool__ptr__char_(*(env))
		? 0
		: (add___void__mut_dict__arr__char__arr__char___ptr_key_value_pair__arr__char__arr__char_(_ctx, res, parse_environ_entry__ptr_key_value_pair__arr__char__arr__char__ptr__char_(_ctx, *(env))),
		get_environ_recur___void__ptr__ptr__char___mut_dict__arr__char__arr__char_(_ctx, incr__ptr__ptr__char__ptr__ptr__char_(env), res));
}
dict__arr__char__arr__char* freeze__ptr_dict__arr__char__arr__char__mut_dict__arr__char__arr__char_(ctx* _ctx, mut_dict__arr__char__arr__char m) {
	return _initdict__arr__char__arr__char(alloc__ptr__byte__nat_(_ctx, 32), (dict__arr__char__arr__char) {freeze__arr__arr__char__ptr_mut_arr__arr__char_(m.keys), freeze__arr__arr__char__ptr_mut_arr__arr__char_(m.values)});
}
arr__arr__char list_compile_error_tests__arr__arr__char__arr__char_(ctx* _ctx, arr__char path) {
	mut_arr__arr__char* res;
	return ((res = new_mut_arr__ptr_mut_arr__arr__char(_ctx)),
	(each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id9___list_compile_error_tests__arr__arr__char__arr__char___lambda0___closure__klblist_compile_error_tests__arr__arr__char__arr__char___lambda0_(_ctx, path, (list_compile_error_tests__arr__arr__char__arr__char___lambda0___closure) {res}),
	freeze__arr__arr__char__ptr_mut_arr__arr__char_(res)));
}
arr__ptr_failure flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure__klbrun_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0_(ctx* _ctx, arr__arr__char a, nat max_size, run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure mapper) {
	mut_arr__ptr_failure* res;
	return ((res = new_mut_arr__ptr_mut_arr__ptr_failure(_ctx)),
	(each___void__arr__arr__char___flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure__klbrun_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___lambda0___closure__klbflat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure__klbrun_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___lambda0_(_ctx, a, (flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure__klbrun_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___lambda0___closure) {res, max_size, mapper}),
	freeze__arr__ptr_failure__ptr_mut_arr__ptr_failure_(res)));
}
bool has__q__bool__arr__ptr_failure_(arr__ptr_failure a) {
	return !(empty__q__bool__arr__ptr_failure_(a));
}
err__arr__ptr_failure err__err__arr__ptr_failure__arr__ptr_failure_(arr__ptr_failure t) {
	return (err__arr__ptr_failure) {t};
}
arr__ptr_failure with_max_size__arr__ptr_failure__arr__ptr_failure___nat_(ctx* _ctx, arr__ptr_failure a, nat max_size) {
	return _op_greater__bool__nat___nat_(a.size, max_size)
		? slice__arr__ptr_failure__arr__ptr_failure___nat___nat_(_ctx, a, 0ull, max_size)
		: a;
}
ok__arr__char ok__ok__arr__char__arr__char_(arr__char t) {
	return (ok__arr__char) {t};
}
arr__char to_str__arr__char__nat_(ctx* _ctx, nat n) {
	arr__char hi;
	arr__char lo;
	return _op_equal_equal__bool__nat___nat_(n, 0ull)
		? (arr__char) _constant____arr__char__21
		: _op_equal_equal__bool__nat___nat_(n, 1ull)
			? (arr__char) _constant____arr__char__23
			: _op_equal_equal__bool__nat___nat_(n, 2ull)
				? (arr__char) _constant____arr__char__29
				: _op_equal_equal__bool__nat___nat_(n, 3ull)
					? (arr__char) _constant____arr__char__30
					: _op_equal_equal__bool__nat___nat_(n, 4ull)
						? (arr__char) _constant____arr__char__31
						: _op_equal_equal__bool__nat___nat_(n, 5ull)
							? (arr__char) _constant____arr__char__32
							: _op_equal_equal__bool__nat___nat_(n, 6ull)
								? (arr__char) _constant____arr__char__33
								: _op_equal_equal__bool__nat___nat_(n, 7ull)
									? (arr__char) _constant____arr__char__34
									: _op_equal_equal__bool__nat___nat_(n, 8ull)
										? (arr__char) _constant____arr__char__35
										: _op_equal_equal__bool__nat___nat_(n, 9ull)
											? (arr__char) _constant____arr__char__36
											: ((hi = to_str__arr__char__nat_(_ctx, _op_div__nat__nat___nat_(_ctx, n, 10ull))),
											((lo = to_str__arr__char__nat_(_ctx, mod__nat__nat___nat_(_ctx, n, 10ull))),
											_op_plus__arr__char__arr__char___arr__char_(_ctx, hi, lo)));
}
result__arr__char__arr__ptr_failure then__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda0___closure__klbdo_test__int32__test_options___lambda0___lambda0___closure__klbfirst_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda0___closure__klbdo_test__int32__test_options___lambda0___lambda0_(ctx* _ctx, result__arr__char__arr__ptr_failure a, first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda0___closure__klbdo_test__int32__test_options___lambda0___lambda0___closure f) {
	ok__arr__char o;
	err__arr__ptr_failure e;
	result__arr__char__arr__ptr_failure matched;
	return (matched = a,
		matched.kind == 0
		? (o = matched.as_ok__arr__char,
		first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda0___closure__klbdo_test__int32__test_options___lambda0___lambda0_(_ctx, f, o.value)
		): matched.kind == 1
		? (e = matched.as_err__arr__ptr_failure,
		(result__arr__char__arr__ptr_failure) { 1, .as_err__arr__ptr_failure = e }
		): _failresult__arr__char__arr__ptr_failure());
}
result__arr__char__arr__ptr_failure then__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda1___closure__klbdo_test__int32__test_options___lambda1___lambda0___closure__klbfirst_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda1___closure__klbdo_test__int32__test_options___lambda1___lambda0_(ctx* _ctx, result__arr__char__arr__ptr_failure a, first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda1___closure__klbdo_test__int32__test_options___lambda1___lambda0___closure f) {
	ok__arr__char o;
	err__arr__ptr_failure e;
	result__arr__char__arr__ptr_failure matched;
	return (matched = a,
		matched.kind == 0
		? (o = matched.as_ok__arr__char,
		first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda1___closure__klbdo_test__int32__test_options___lambda1___lambda0_(_ctx, f, o.value)
		): matched.kind == 1
		? (e = matched.as_err__arr__ptr_failure,
		(result__arr__char__arr__ptr_failure) { 1, .as_err__arr__ptr_failure = e }
		): _failresult__arr__char__arr__ptr_failure());
}
_void each___void__arr__ptr_failure___fun_mut1___void__ptr_failure__id12_(ctx* _ctx, arr__ptr_failure a) {
	return empty__q__bool__arr__ptr_failure_(a)
		? 0
		: (print_failure___void__ptr_failure___asLambda_(_ctx, first__ptr_failure__arr__ptr_failure_(_ctx, a)),
		each___void__arr__ptr_failure___fun_mut1___void__ptr_failure__id12_(_ctx, tail__arr__ptr_failure__arr__ptr_failure_(_ctx, a)));
}
int32 to_int32__int32__nat_(ctx* _ctx, nat n) {
	return (assert___void__bool_(_ctx, _op_less__bool__nat___nat_(n, 1000000ull)),
	(int32) (_int) n);
}
bool empty__q__bool__arr__char_(arr__char a) {
	return zero__q__bool__nat_(a.size);
}
global_ctx* get_gctx__ptr_global_ctx(ctx* _ctx) {
	return (global_ctx*) _ctx->gctx_ptr;
}
_void acquire_lock_recur___void__ptr_lock___nat_(lock* l, nat n_tries) {
	return try_acquire_lock__bool__ptr_lock_(l)
		? 0
		: _op_equal_equal__bool__nat___nat_(n_tries, 1000ull)
			? hard_fail___void__arr__char__id6_()
			: (yield_thread___void(),
			acquire_lock_recur___void__ptr_lock___nat_(l, noctx_incr__nat__nat_(n_tries)));
}
_void must_unset___void__ptr__atomic_bool_(_atomic_bool* a) {
	bool did_unset;
	return ((did_unset = try_unset__bool__ptr__atomic_bool_(a)),
	hard_assert___void__bool_(did_unset));
}
fut__int32* then__ptr_fut__int32__ptr_fut___void___fun_ref1__int32___void_(ctx* _ctx, fut___void* f, fun_ref1__int32___void cb) {
	fut__int32* res;
	return ((res = new_unresolved_fut__ptr_fut__int32(_ctx)),
	(then_void___void__ptr_fut___void___then__ptr_fut__int32__ptr_fut___void___fun_ref1__int32___void___lambda0___closure__klbthen__ptr_fut__int32__ptr_fut___void___fun_ref1__int32___void___lambda0_(_ctx, f, (then__ptr_fut__int32__ptr_fut___void___fun_ref1__int32___void___lambda0___closure) {cb, res}),
	res));
}
fut__int32* then2__ptr_fut__int32__ptr_fut___void___fun_ref0__int32___lambda0___dynamic(ctx* _ctx, then2__ptr_fut__int32__ptr_fut___void___fun_ref0__int32___lambda0___closure* _closure, _void ignore) {
	return call__ptr_fut__int32__fun_ref0__int32_(_ctx, _closure->cb);
}
arr__ptr__char tail__arr__ptr__char__arr__ptr__char_(ctx* _ctx, arr__ptr__char a) {
	return (forbid___void__bool_(_ctx, empty__q__bool__arr__ptr__char_(a)),
	slice_starting_at__arr__ptr__char__arr__ptr__char___nat_(_ctx, a, 1ull));
}
arr__arr__char map__arr__arr__char__arr__ptr__char___fun_mut1__arr__char__ptr__char__id1_(ctx* _ctx, arr__ptr__char a) {
	return make_arr__arr__arr__char__nat___map__arr__arr__char__arr__ptr__char___fun_mut1__arr__char__ptr__char__id1___lambda0___closure__klbmap__arr__arr__char__arr__ptr__char___fun_mut1__arr__char__ptr__char__id1___lambda0_(_ctx, a.size, (map__arr__arr__char__arr__ptr__char___fun_mut1__arr__char__ptr__char__id1___lambda0___closure) {a});
}
bool null__q__bool__ptr__byte_(ptr__byte a) {
	return _op_equal_equal__bool__ptr__byte___ptr__byte_(a, NULL);
}
comparison _op_less_equal_greater__comparison__nat___nat_(nat a, nat b) {
	return (a < b)
		? (comparison) { 0, .as_less = (less) { 0 } }
		: (b < a)
			? (comparison) { 2, .as_greater = (greater) { 0 } }
			: (comparison) { 1, .as_equal = (equal) { 0 } };
}
bool _op_less__bool__nat___nat_(nat a, nat b) {
	comparison matched;
	return (matched = _op_less_equal_greater__comparison__nat___nat_(a, b),
		matched.kind == 0
		? 1
		: matched.kind == 1
		? 0
		: matched.kind == 2
		? 0
		: _failbool());
}
nat wrap_incr__nat__nat_(nat a) {
	return (a + 1ull);
}
comparison _op_less_equal_greater__comparison__int32___int32_(int32 a, int32 b) {
	return (a < b)
		? (comparison) { 0, .as_less = (less) { 0 } }
		: (b < a)
			? (comparison) { 2, .as_greater = (greater) { 0 } }
			: (comparison) { 1, .as_equal = (equal) { 0 } };
}
_void hard_fail___void__arr__char__id2_() {
	assert(0);
}
bool _op_equal_equal__bool__ptr__byte___ptr__byte_(ptr__byte a, ptr__byte b) {
	comparison matched;
	return (matched = _op_less_equal_greater__comparison__ptr__byte___ptr__byte_(a, b),
		matched.kind == 0
		? 0
		: matched.kind == 1
		? 1
		: matched.kind == 2
		? 0
		: _failbool());
}
ptr__byte get__ptr__byte__ptr_cell__ptr__byte_(cell__ptr__byte* c) {
	return c->value;
}
comparison _op_less_equal_greater__comparison___int____int_(_int a, _int b) {
	return (a < b)
		? (comparison) { 0, .as_less = (less) { 0 } }
		: (b < a)
			? (comparison) { 2, .as_greater = (greater) { 0 } }
			: (comparison) { 1, .as_equal = (equal) { 0 } };
}
vat* noctx_at__ptr_vat__arr__ptr_vat___nat_(arr__ptr_vat a, nat index) {
	return (hard_assert___void__bool_(_op_less__bool__nat___nat_(index, a.size)),
	*((a.data + index)));
}
bool empty__q__bool__ptr_mut_bag__task_(mut_bag__task* m) {
	return empty__q__bool__opt__ptr_mut_bag_node__task_(m->head);
}
_void hard_fail___void__arr__char__id0_() {
	assert(0);
}
bool _op_less_equal__bool__nat___nat_(nat a, nat b) {
	return !(_op_less__bool__nat___nat_(b, a));
}
opt__chosen_task choose_task_recur__opt__chosen_task__arr__ptr_vat___nat_(arr__ptr_vat vats, nat i) {
	vat* vat;
	some__opt__task s;
	opt__opt__task matched;
	return _op_equal_equal__bool__nat___nat_(i, vats.size)
		? (opt__chosen_task) _constant__opt__chosen_task__0
		: ((vat = noctx_at__ptr_vat__arr__ptr_vat___nat_(vats, i)),
		(matched = choose_task_in_vat__opt__opt__task__ptr_vat_(vat),
			matched.kind == 0
			? choose_task_recur__opt__chosen_task__arr__ptr_vat___nat_(vats, noctx_incr__nat__nat_(i))
			: matched.kind == 1
			? (s = matched.as_some__opt__task,
			(opt__chosen_task) { 1, .as_some__chosen_task = some__some__chosen_task__chosen_task_((chosen_task) {vat, s.value}) }
			): _failopt__chosen_task()));
}
err__no_chosen_task err__err__no_chosen_task__no_chosen_task_(no_chosen_task t) {
	return (err__no_chosen_task) {t};
}
ok__chosen_task ok__ok__chosen_task__chosen_task_(chosen_task t) {
	return (ok__chosen_task) {t};
}
_void call_with_ctx___void__ptr_ctx___fun_mut0___void_(ctx* c, fun_mut0___void f) {
	return f.fun_ptr(c, f.closure);
}
_void noctx_must_remove_unordered___void__ptr_mut_arr__nat___nat_(mut_arr__nat* a, nat value) {
	return noctx_must_remove_unordered_recur___void__ptr_mut_arr__nat___nat___nat_(a, 0ull, value);
}
_void return_ctx___void__ptr_ctx_(ctx* c) {
	return return_gc_ctx___void__ptr_gc_ctx_((gc_ctx*) c->gc_ctx_ptr);
}
_void yield_thread___void() {
	int32 err;
	return ((err = pthread_yield()),
	((usleep(1000ull), 0),
	hard_assert___void__bool_(zero__q__bool__int32_(err))));
}
opt__nat find_index_recur__opt__nat__arr__arr__char___nat___fun_mut1__bool__arr__char__id6_(ctx* _ctx, arr__arr__char a, nat index) {
	return _op_equal_equal__bool__nat___nat_(index, a.size)
		? (opt__nat) _constant__opt__nat__0
		: parse_cmd_line_args_dynamic__ptr_parsed_cmd_line_args__arr__arr__char___lambda0_(_ctx, at__arr__char__arr__arr__char___nat_(_ctx, a, index))
			? (opt__nat) { 1, .as_some__nat = some__some__nat__nat_(index) }
			: find_index_recur__opt__nat__arr__arr__char___nat___fun_mut1__bool__arr__char__id6_(_ctx, a, incr__nat__nat_(_ctx, index));
}
arr__arr__char slice__arr__arr__char__arr__arr__char___nat___nat_(ctx* _ctx, arr__arr__char a, nat begin, nat size) {
	return (assert___void__bool_(_ctx, _op_less_equal__bool__nat___nat_(_op_plus__nat__nat___nat_(_ctx, begin, size), a.size)),
	(arr__arr__char) {size, (a.data + begin)});
}
nat _op_minus__nat__nat___nat_(ctx* _ctx, nat a, nat b) {
	return (assert___void__bool_(_ctx, _op_greater_equal__bool__nat___nat_(a, b)),
	(a - b));
}
opt__nat find_index_recur__opt__nat__arr__arr__char___nat___fun_mut1__bool__arr__char__id7_(ctx* _ctx, arr__arr__char a, nat index) {
	return _op_equal_equal__bool__nat___nat_(index, a.size)
		? (opt__nat) _constant__opt__nat__0
		: parse_cmd_line_args_dynamic__ptr_parsed_cmd_line_args__arr__arr__char___lambda1_(_ctx, at__arr__char__arr__arr__char___nat_(_ctx, a, index))
			? (opt__nat) { 1, .as_some__nat = some__some__nat__nat_(index) }
			: find_index_recur__opt__nat__arr__arr__char___nat___fun_mut1__bool__arr__char__id7_(_ctx, a, incr__nat__nat_(_ctx, index));
}
mut_dict__arr__char__arr__arr__char new_mut_dict__mut_dict__arr__char__arr__arr__char(ctx* _ctx) {
	return (mut_dict__arr__char__arr__arr__char) {new_mut_arr__ptr_mut_arr__arr__char(_ctx), new_mut_arr__ptr_mut_arr__arr__arr__char(_ctx)};
}
_void parse_named_args_recur___void__arr__arr__char___mut_dict__arr__char__arr__arr__char_(ctx* _ctx, arr__arr__char args, mut_dict__arr__char__arr__arr__char builder) {
	arr__char first_name;
	arr__arr__char tl;
	some__nat s;
	nat next_named_arg_index;
	opt__nat matched;
	return ((first_name = remove_start__arr__char__arr__char___arr__char_(_ctx, first__arr__char__arr__arr__char_(_ctx, args), (arr__char) _constant____arr__char__16)),
	((tl = tail__arr__arr__char__arr__arr__char_(_ctx, args)),
	(matched = find_index__opt__nat__arr__arr__char___fun_mut1__bool__arr__char__id8_(_ctx, tl),
		matched.kind == 0
		? add___void__mut_dict__arr__char__arr__arr__char___arr__char___arr__arr__char_(_ctx, builder, first_name, tl)
		: matched.kind == 1
		? (s = matched.as_some__nat,
		((next_named_arg_index = s.value),
		(add___void__mut_dict__arr__char__arr__arr__char___arr__char___arr__arr__char_(_ctx, builder, first_name, slice_up_to__arr__arr__char__arr__arr__char___nat_(_ctx, tl, next_named_arg_index)),
		parse_named_args_recur___void__arr__arr__char___mut_dict__arr__char__arr__arr__char_(_ctx, slice_starting_at__arr__arr__char__arr__arr__char___nat_(_ctx, args, next_named_arg_index), builder)))
		): _fail_void())));
}
dict__arr__char__arr__arr__char* freeze__ptr_dict__arr__char__arr__arr__char__mut_dict__arr__char__arr__arr__char_(ctx* _ctx, mut_dict__arr__char__arr__arr__char m) {
	return _initdict__arr__char__arr__arr__char(alloc__ptr__byte__nat_(_ctx, 32), (dict__arr__char__arr__arr__char) {freeze__arr__arr__char__ptr_mut_arr__arr__char_(m.keys), freeze__arr__arr__arr__char__ptr_mut_arr__arr__arr__char_(m.values)});
}
nat incr__nat__nat_(ctx* _ctx, nat n) {
	return (assert___void__bool_(_ctx, _op_less__bool__nat___nat_(n, 1000000000ull)),
	(n + 1ull));
}
_void throw___void__exception_(ctx* _ctx, exception e) {
	exception_ctx* exn_ctx;
	return ((exn_ctx = get_exception_ctx__ptr_exception_ctx(_ctx)),
	(((hard_forbid___void__bool_(_op_equal_equal__bool__ptr__jmp_buf_tag___ptr__jmp_buf_tag_(exn_ctx->jmp_buf_ptr, NULL)),
	(exn_ctx->thrown_exception = e), 0),
	(longjmp(exn_ctx->jmp_buf_ptr, 7), 0)),
	todo___void()));
}
mut_arr__opt__arr__arr__char* new_uninitialized_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat_(ctx* _ctx, nat size) {
	return _initmut_arr__opt__arr__arr__char(alloc__ptr__byte__nat_(_ctx, 32), (mut_arr__opt__arr__arr__char) {0, size, size, uninitialized_data__ptr__opt__arr__arr__char__nat_(_ctx, size)});
}
_void make_mut_arr_worker___void__ptr_mut_arr__opt__arr__arr__char___nat___fill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat___opt__arr__arr__char___lambda0___closure__klbfill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat___opt__arr__arr__char___lambda0_(ctx* _ctx, mut_arr__opt__arr__arr__char* m, nat i, fill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat___opt__arr__arr__char___lambda0___closure f) {
	return _op_equal_equal__bool__nat___nat_(i, m->size)
		? 0
		: (set_at___void__ptr_mut_arr__opt__arr__arr__char___nat___opt__arr__arr__char_(_ctx, m, i, fill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat___opt__arr__arr__char___lambda0_(_ctx, f, i)),
		make_mut_arr_worker___void__ptr_mut_arr__opt__arr__arr__char___nat___fill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat___opt__arr__arr__char___lambda0___closure__klbfill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat___opt__arr__arr__char___lambda0_(_ctx, m, incr__nat__nat_(_ctx, i), f));
}
opt__nat index_of__opt__nat__arr__arr__char___arr__char_(ctx* _ctx, arr__arr__char a, arr__char value) {
	return find_index__opt__nat__arr__arr__char___index_of__opt__nat__arr__arr__char___arr__char___lambda0___closure__klbindex_of__opt__nat__arr__arr__char___arr__char___lambda0_(_ctx, a, (index_of__opt__nat__arr__arr__char___arr__char___lambda0___closure) {value});
}
bool _op_equal_equal__bool__arr__char___arr__char_(arr__char a, arr__char b) {
	comparison matched;
	return (matched = _op_less_equal_greater__comparison__arr__char___arr__char_(a, b),
		matched.kind == 0
		? 0
		: matched.kind == 1
		? 1
		: matched.kind == 2
		? 0
		: _failbool());
}
_void set___void__ptr_cell__bool___bool_(cell__bool* c, bool v) {
	return (c->value = v), 0;
}
_void forbid___void__bool_(ctx* _ctx, bool condition) {
	return forbid___void__bool___arr__char_(_ctx, condition, (arr__char) _constant____arr__char__7);
}
opt__arr__arr__char at__opt__arr__arr__char__ptr_mut_arr__opt__arr__arr__char___nat_(ctx* _ctx, mut_arr__opt__arr__arr__char* a, nat index) {
	return (assert___void__bool_(_ctx, _op_less__bool__nat___nat_(index, a->size)),
	noctx_at__opt__arr__arr__char__ptr_mut_arr__opt__arr__arr__char___nat_(a, index));
}
_void set_at___void__ptr_mut_arr__opt__arr__arr__char___nat___opt__arr__arr__char_(ctx* _ctx, mut_arr__opt__arr__arr__char* a, nat index, opt__arr__arr__char value) {
	return (assert___void__bool_(_ctx, _op_less__bool__nat___nat_(index, a->size)),
	noctx_set_at___void__ptr_mut_arr__opt__arr__arr__char___nat___opt__arr__arr__char_(a, index, value));
}
some__arr__arr__char some__some__arr__arr__char__arr__arr__char_(arr__arr__char t) {
	return (some__arr__arr__char) {t};
}
arr__char at__arr__char__arr__arr__char___nat_(ctx* _ctx, arr__arr__char a, nat index) {
	return (assert___void__bool_(_ctx, _op_less__bool__nat___nat_(index, a.size)),
	noctx_at__arr__char__arr__arr__char___nat_(a, index));
}
bool empty__q__bool__arr__arr__arr__char_(arr__arr__arr__char a) {
	return zero__q__bool__nat_(a.size);
}
arr__arr__char at__arr__arr__char__arr__arr__arr__char___nat_(ctx* _ctx, arr__arr__arr__char a, nat index) {
	return (assert___void__bool_(_ctx, _op_less__bool__nat___nat_(index, a.size)),
	noctx_at__arr__arr__char__arr__arr__arr__char___nat_(a, index));
}
arr__arr__arr__char slice_starting_at__arr__arr__arr__char__arr__arr__arr__char___nat_(ctx* _ctx, arr__arr__arr__char a, nat begin) {
	return (assert___void__bool_(_ctx, _op_less_equal__bool__nat___nat_(begin, a.size)),
	slice__arr__arr__arr__char__arr__arr__arr__char___nat___nat_(_ctx, a, begin, _op_minus__nat__nat___nat_(_ctx, a.size, begin)));
}
opt__arr__arr__char noctx_at__opt__arr__arr__char__arr__opt__arr__arr__char___nat_(arr__opt__arr__arr__char a, nat index) {
	return (hard_assert___void__bool_(_op_less__bool__nat___nat_(index, a.size)),
	*((a.data + index)));
}
bool empty__q__bool__opt__arr__arr__char_(opt__arr__arr__char a) {
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
arr__char rtail__arr__char__arr__char_(ctx* _ctx, arr__char a) {
	return (forbid___void__bool_(_ctx, empty__q__bool__arr__char_(a)),
	slice__arr__char__arr__char___nat___nat_(_ctx, a, 0ull, decr__nat__nat_(_ctx, a.size)));
}
nat _op_plus__nat__nat___nat_(ctx* _ctx, nat a, nat b) {
	nat res;
	return ((res = (a + b)),
	(assert___void__bool_(_ctx, (_op_greater_equal__bool__nat___nat_(res, a) && _op_greater_equal__bool__nat___nat_(res, b))),
	res));
}
nat _op_times__nat__nat___nat_(ctx* _ctx, nat a, nat b) {
	nat res;
	return (zero__q__bool__nat_(a) || zero__q__bool__nat_(b))
		? 0ull
		: ((res = (a * b)),
		((assert___void__bool_(_ctx, _op_equal_equal__bool__nat___nat_(_op_div__nat__nat___nat_(_ctx, res, b), a)),
		assert___void__bool_(_ctx, _op_equal_equal__bool__nat___nat_(_op_div__nat__nat___nat_(_ctx, res, a), b))),
		res));
}
nat char_to_nat__nat__char_(char c) {
	return _op_equal_equal__bool__char___char_(c, '0')
		? 0ull
		: _op_equal_equal__bool__char___char_(c, '1')
			? 1ull
			: _op_equal_equal__bool__char___char_(c, '2')
				? 2ull
				: _op_equal_equal__bool__char___char_(c, '3')
					? 3ull
					: _op_equal_equal__bool__char___char_(c, '4')
						? 4ull
						: _op_equal_equal__bool__char___char_(c, '5')
							? 5ull
							: _op_equal_equal__bool__char___char_(c, '6')
								? 6ull
								: _op_equal_equal__bool__char___char_(c, '7')
									? 7ull
									: _op_equal_equal__bool__char___char_(c, '8')
										? 8ull
										: _op_equal_equal__bool__char___char_(c, '9')
											? 9ull
											: todo__nat();
}
char last__char__arr__char_(ctx* _ctx, arr__char a) {
	return (forbid___void__bool_(_ctx, empty__q__bool__arr__char_(a)),
	at__char__arr__char___nat_(_ctx, a, decr__nat__nat_(_ctx, a.size)));
}
opt__ptr__byte try_gc_alloc__opt__ptr__byte__ptr_gc___nat_(gc* gc, nat size) {
	return (opt__ptr__byte) { 1, .as_some__ptr__byte = some__some__ptr__byte__ptr__byte_(unmanaged_alloc_bytes__ptr__byte__nat_(size)) };
}
ptr__byte todo__ptr__byte() {
	return hard_fail__ptr__byte__arr__char__id2_();
}
gc_ctx* get_gc_ctx__ptr_gc_ctx(ctx* _ctx) {
	return (gc_ctx*) _ctx->gc_ctx_ptr;
}
opt__nat find_rindex__opt__nat__arr__char___r_index_of__opt__nat__arr__char___char___lambda0___closure__klbr_index_of__opt__nat__arr__char___char___lambda0_(ctx* _ctx, arr__char a, r_index_of__opt__nat__arr__char___char___lambda0___closure pred) {
	return empty__q__bool__arr__char_(a)
		? (opt__nat) _constant__opt__nat__0
		: find_rindex_recur__opt__nat__arr__char___nat___r_index_of__opt__nat__arr__char___char___lambda0___closure__klbr_index_of__opt__nat__arr__char___char___lambda0_(_ctx, a, decr__nat__nat_(_ctx, a.size), pred);
}
arr__char slice__arr__char__arr__char___nat___nat_(ctx* _ctx, arr__char a, nat begin, nat size) {
	return (assert___void__bool_(_ctx, _op_less_equal__bool__nat___nat_(_op_plus__nat__nat___nat_(_ctx, begin, size), a.size)),
	(arr__char) {size, (a.data + begin)});
}
mut_arr__char* new_uninitialized_mut_arr__ptr_mut_arr__char__nat__id1000_(ctx* _ctx) {
	return _initmut_arr__char(alloc__ptr__byte__nat_(_ctx, 32), (mut_arr__char) {0, 1000ull, 1000ull, uninitialized_data__ptr__char__nat__id1000_(_ctx)});
}
ptr__char to_c_str__ptr__char__arr__char_(ctx* _ctx, arr__char a) {
	return _op_plus__arr__char__arr__char___arr__char_(_ctx, a, (arr__char) _constant____arr__char__9).data;
}
_void check_errno_if_neg_one___void___int_(ctx* _ctx, _int e) {
	return _op_equal_equal__bool___int____int_(e, -1ll)
		? (check_posix_error___void__int32_(_ctx, get_errno__int32(_ctx)),
		hard_unreachable___void())
		: 0;
}
arr__char freeze__arr__char__ptr_mut_arr__char_(mut_arr__char* a) {
	return ((a->frozen__q = 1), 0,
	unsafe_as_arr__arr__char__ptr_mut_arr__char_(a));
}
nat to_nat__nat___int_(ctx* _ctx, _int i) {
	return (forbid___void__bool_(_ctx, negative__q__bool___int_(_ctx, i)),
	(nat) i);
}
arr__char make_arr__arr__char__nat____op_plus__arr__char__arr__char___arr__char___lambda0___closure__klb_op_plus__arr__char__arr__char___arr__char___lambda0_(ctx* _ctx, nat size, _op_plus__arr__char__arr__char___arr__char___lambda0___closure f) {
	return freeze__arr__char__ptr_mut_arr__char_(make_mut_arr__ptr_mut_arr__char__nat____op_plus__arr__char__arr__char___arr__char___lambda0___closure__klb_op_plus__arr__char__arr__char___arr__char___lambda0_(_ctx, size, f));
}
mut_arr__arr__char* new_mut_arr__ptr_mut_arr__arr__char(ctx* _ctx) {
	return _initmut_arr__arr__char(alloc__ptr__byte__nat_(_ctx, 32), (mut_arr__arr__char) {0, 0ull, 0ull, NULL});
}
bool null__q__bool__ptr__char_(ptr__char a) {
	return _op_equal_equal__bool__ptr__char___ptr__char_(a, NULL);
}
_void add___void__mut_dict__arr__char__arr__char___ptr_key_value_pair__arr__char__arr__char_(ctx* _ctx, mut_dict__arr__char__arr__char m, key_value_pair__arr__char__arr__char* pair) {
	return add___void__mut_dict__arr__char__arr__char___arr__char___arr__char_(_ctx, m, pair->key, pair->value);
}
key_value_pair__arr__char__arr__char* parse_environ_entry__ptr_key_value_pair__arr__char__arr__char__ptr__char_(ctx* _ctx, ptr__char entry) {
	ptr__char key_end;
	arr__char key;
	ptr__char value_begin;
	ptr__char value_end;
	arr__char value;
	return ((key_end = find_char_in_cstr__ptr__char__ptr__char___char_(entry, '=')),
	((key = arr_from_begin_end__arr__char__ptr__char___ptr__char_(entry, key_end)),
	((value_begin = incr__ptr__char__ptr__char_(key_end)),
	((value_end = find_cstr_end__ptr__char__ptr__char_(value_begin)),
	((value = arr_from_begin_end__arr__char__ptr__char___ptr__char_(value_begin, value_end)),
	_initkey_value_pair__arr__char__arr__char(alloc__ptr__byte__nat_(_ctx, 32), (key_value_pair__arr__char__arr__char) {key, value}))))));
}
ptr__ptr__char incr__ptr__ptr__char__ptr__ptr__char_(ptr__ptr__char p) {
	return (p + 1ull);
}
arr__arr__char freeze__arr__arr__char__ptr_mut_arr__arr__char_(mut_arr__arr__char* a) {
	return ((a->frozen__q = 1), 0,
	unsafe_as_arr__arr__arr__char__ptr_mut_arr__arr__char_(a));
}
_void each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id9___list_compile_error_tests__arr__arr__char__arr__char___lambda0___closure__klblist_compile_error_tests__arr__arr__char__arr__char___lambda0_(ctx* _ctx, arr__char path, list_compile_error_tests__arr__arr__char__arr__char___lambda0___closure f) {
	return is_dir__q__bool__arr__char_(_ctx, path)
		? each___void__arr__arr__char___each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id9___list_compile_error_tests__arr__arr__char__arr__char___lambda0___closure__klblist_compile_error_tests__arr__arr__char__arr__char___lambda0___lambda0___closure__klbeach_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id9___list_compile_error_tests__arr__arr__char__arr__char___lambda0___closure__klblist_compile_error_tests__arr__arr__char__arr__char___lambda0___lambda0_(_ctx, read_dir__arr__arr__char__arr__char_(_ctx, path), (each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id9___list_compile_error_tests__arr__arr__char__arr__char___lambda0___closure__klblist_compile_error_tests__arr__arr__char__arr__char___lambda0___lambda0___closure) {path, f})
		: list_compile_error_tests__arr__arr__char__arr__char___lambda0_(_ctx, f, path);
}
mut_arr__ptr_failure* new_mut_arr__ptr_mut_arr__ptr_failure(ctx* _ctx) {
	return _initmut_arr__ptr_failure(alloc__ptr__byte__nat_(_ctx, 32), (mut_arr__ptr_failure) {0, 0ull, 0ull, NULL});
}
_void each___void__arr__arr__char___flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure__klbrun_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___lambda0___closure__klbflat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure__klbrun_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___lambda0_(ctx* _ctx, arr__arr__char a, flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure__klbrun_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___lambda0___closure f) {
	return empty__q__bool__arr__arr__char_(a)
		? 0
		: (flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure__klbrun_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___lambda0_(_ctx, f, first__arr__char__arr__arr__char_(_ctx, a)),
		each___void__arr__arr__char___flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure__klbrun_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___lambda0___closure__klbflat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure__klbrun_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___lambda0_(_ctx, tail__arr__arr__char__arr__arr__char_(_ctx, a), f));
}
arr__ptr_failure freeze__arr__ptr_failure__ptr_mut_arr__ptr_failure_(mut_arr__ptr_failure* a) {
	return ((a->frozen__q = 1), 0,
	unsafe_as_arr__arr__ptr_failure__ptr_mut_arr__ptr_failure_(a));
}
bool empty__q__bool__arr__ptr_failure_(arr__ptr_failure a) {
	return zero__q__bool__nat_(a.size);
}
arr__ptr_failure slice__arr__ptr_failure__arr__ptr_failure___nat___nat_(ctx* _ctx, arr__ptr_failure a, nat begin, nat size) {
	return (assert___void__bool_(_ctx, _op_less_equal__bool__nat___nat_(_op_plus__nat__nat___nat_(_ctx, begin, size), a.size)),
	(arr__ptr_failure) {size, (a.data + begin)});
}
nat _op_div__nat__nat___nat_(ctx* _ctx, nat a, nat b) {
	return (forbid___void__bool_(_ctx, zero__q__bool__nat_(b)),
	(a / b));
}
nat mod__nat__nat___nat_(ctx* _ctx, nat a, nat b) {
	return (forbid___void__bool_(_ctx, zero__q__bool__nat_(b)),
	(a % b));
}
result__arr__char__arr__ptr_failure first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda0___closure__klbdo_test__int32__test_options___lambda0___lambda0_(ctx* _ctx, first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda0___closure__klbdo_test__int32__test_options___lambda0___lambda0___closure _closure, arr__char a_descr) {
	return then__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda0___closure__klbdo_test__int32__test_options___lambda0___lambda0___lambda0___closure__klbfirst_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda0___closure__klbdo_test__int32__test_options___lambda0___lambda0___lambda0_(_ctx, do_test__int32__test_options___lambda0(_ctx, _closure.b), (first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda0___closure__klbdo_test__int32__test_options___lambda0___lambda0___lambda0___closure) {a_descr});
}
result__arr__char__arr__ptr_failure first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda1___closure__klbdo_test__int32__test_options___lambda1___lambda0_(ctx* _ctx, first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda1___closure__klbdo_test__int32__test_options___lambda1___lambda0___closure _closure, arr__char a_descr) {
	return then__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda1___closure__klbdo_test__int32__test_options___lambda1___lambda0___lambda0___closure__klbfirst_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda1___closure__klbdo_test__int32__test_options___lambda1___lambda0___lambda0_(_ctx, do_test__int32__test_options___lambda1(_ctx, _closure.b), (first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda1___closure__klbdo_test__int32__test_options___lambda1___lambda0___lambda0___closure) {a_descr});
}
_void print_failure___void__ptr_failure___asLambda_(ctx* _ctx, failure* failure) {
	return print_failure___void__ptr_failure_(_ctx, failure);
}
failure* first__ptr_failure__arr__ptr_failure_(ctx* _ctx, arr__ptr_failure a) {
	return (forbid___void__bool_(_ctx, empty__q__bool__arr__ptr_failure_(a)),
	at__ptr_failure__arr__ptr_failure___nat_(_ctx, a, 0ull));
}
arr__ptr_failure tail__arr__ptr_failure__arr__ptr_failure_(ctx* _ctx, arr__ptr_failure a) {
	return (forbid___void__bool_(_ctx, empty__q__bool__arr__ptr_failure_(a)),
	slice_starting_at__arr__ptr_failure__arr__ptr_failure___nat_(_ctx, a, 1ull));
}
bool try_acquire_lock__bool__ptr_lock_(lock* l) {
	return try_set__bool__ptr__atomic_bool_((&(l->is_locked)));
}
_void hard_fail___void__arr__char__id6_() {
	assert(0);
}
bool try_unset__bool__ptr__atomic_bool_(_atomic_bool* a) {
	return try_change__bool__ptr__atomic_bool___bool_(a, 1);
}
fut__int32* new_unresolved_fut__ptr_fut__int32(ctx* _ctx) {
	return _initfut__int32(alloc__ptr__byte__nat_(_ctx, 32), (fut__int32) {new_lock__lock(), (fut_state__int32) _constant__fut_state__int32__0});
}
_void then_void___void__ptr_fut___void___then__ptr_fut__int32__ptr_fut___void___fun_ref1__int32___void___lambda0___closure__klbthen__ptr_fut__int32__ptr_fut___void___fun_ref1__int32___void___lambda0_(ctx* _ctx, fut___void* f, then__ptr_fut__int32__ptr_fut___void___fun_ref1__int32___void___lambda0___closure cb) {
	fut_state_callbacks___void cbs;
	fut_state_resolved___void r;
	exception e;
	fut_state___void matched;
	return ((acquire_lock___void__ptr_lock_((&(f->lk))),
	(matched = f->state,
		matched.kind == 0
		? (cbs = matched.as_fut_state_callbacks___void,
		(f->state = (fut_state___void) { 0, .as_fut_state_callbacks___void = (fut_state_callbacks___void) {(opt__ptr_fut_callback_node___void) { 1, .as_some__ptr_fut_callback_node___void = some__some__ptr_fut_callback_node___void__ptr_fut_callback_node___void_(_initfut_callback_node___void(alloc__ptr__byte__nat_(_ctx, 32), (fut_callback_node___void) {(fun_mut1___void__result___void__exception) {
			(fun_ptr3___void__ptr_ctx__ptr__byte__result___void__exception) then__ptr_fut__int32__ptr_fut___void___fun_ref1__int32___void___lambda0___dynamic, (ptr__byte) _initthen__ptr_fut__int32__ptr_fut___void___fun_ref1__int32___void___lambda0___closure(alloc__ptr__byte__nat_(_ctx, 40), cb) }, cbs.head})) }} }), 0
			): matched.kind == 1
			? (r = matched.as_fut_state_resolved___void,
			then__ptr_fut__int32__ptr_fut___void___fun_ref1__int32___void___lambda0_(_ctx, cb, (result___void__exception) { 0, .as_ok___void = ok__ok___void___void_(r.value) })
			): matched.kind == 2
			? (e = matched.as_exception,
			then__ptr_fut__int32__ptr_fut___void___fun_ref1__int32___void___lambda0_(_ctx, cb, (result___void__exception) { 1, .as_err__exception = err__err__exception__exception_(e) })
			): _fail_void())),
		release_lock___void__ptr_lock_((&(f->lk))));
}
fut__int32* call__ptr_fut__int32__fun_ref0__int32_(ctx* _ctx, fun_ref0__int32 f) {
	vat* vat;
	fut__int32* res;
	return ((vat = get_vat__ptr_vat__nat_(_ctx, f.vat_and_actor.vat)),
	((res = new_unresolved_fut__ptr_fut__int32(_ctx)),
	(add_task___void__ptr_vat___task_(_ctx, vat, (task) {f.vat_and_actor.actor, (fun_mut0___void) {
		(fun_ptr2___void__ptr_ctx__ptr__byte) call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic, (ptr__byte) _initcall__ptr_fut__int32__fun_ref0__int32___lambda0___closure(alloc__ptr__byte__nat_(_ctx, 40), (call__ptr_fut__int32__fun_ref0__int32___lambda0___closure) {f, res}) }}),
		res)));
}
bool empty__q__bool__arr__ptr__char_(arr__ptr__char a) {
	return zero__q__bool__nat_(a.size);
}
arr__ptr__char slice_starting_at__arr__ptr__char__arr__ptr__char___nat_(ctx* _ctx, arr__ptr__char a, nat begin) {
	return (assert___void__bool_(_ctx, _op_less_equal__bool__nat___nat_(begin, a.size)),
	slice__arr__ptr__char__arr__ptr__char___nat___nat_(_ctx, a, begin, _op_minus__nat__nat___nat_(_ctx, a.size, begin)));
}
arr__arr__char make_arr__arr__arr__char__nat___map__arr__arr__char__arr__ptr__char___fun_mut1__arr__char__ptr__char__id1___lambda0___closure__klbmap__arr__arr__char__arr__ptr__char___fun_mut1__arr__char__ptr__char__id1___lambda0_(ctx* _ctx, nat size, map__arr__arr__char__arr__ptr__char___fun_mut1__arr__char__ptr__char__id1___lambda0___closure f) {
	return freeze__arr__arr__char__ptr_mut_arr__arr__char_(make_mut_arr__ptr_mut_arr__arr__char__nat___map__arr__arr__char__arr__ptr__char___fun_mut1__arr__char__ptr__char__id1___lambda0___closure__klbmap__arr__arr__char__arr__ptr__char___fun_mut1__arr__char__ptr__char__id1___lambda0_(_ctx, size, f));
}
comparison _op_less_equal_greater__comparison__ptr__byte___ptr__byte_(ptr__byte a, ptr__byte b) {
	return (a < b)
		? (comparison) { 0, .as_less = (less) { 0 } }
		: (b < a)
			? (comparison) { 2, .as_greater = (greater) { 0 } }
			: (comparison) { 1, .as_equal = (equal) { 0 } };
}
bool empty__q__bool__opt__ptr_mut_bag_node__task_(opt__ptr_mut_bag_node__task a) {
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
opt__opt__task choose_task_in_vat__opt__opt__task__ptr_vat_(vat* vat) {
	some__task s;
	opt__task matched;
	opt__opt__task res;
	return (acquire_lock___void__ptr_lock_((&(vat->tasks_lock))),
	((res = (&(vat->gc))->needs_gc
		? zero__q__bool__nat_(vat->n_threads_running)
			? (opt__opt__task) _constant__opt__opt__task__0
			: (opt__opt__task) _constant__opt__opt__task__1
		: (matched = find_and_remove_first_doable_task__opt__task__ptr_vat_(vat),
			matched.kind == 0
			? (opt__opt__task) _constant__opt__opt__task__1
			: matched.kind == 1
			? (s = matched.as_some__task,
			(opt__opt__task) { 1, .as_some__opt__task = some__some__opt__task__opt__task_((opt__task) { 1, .as_some__task = some__some__task__task_(s.value) }) }
			): _failopt__opt__task())),
	((empty__q__bool__opt__opt__task_(res)
		? 0
		: (vat->n_threads_running = noctx_incr__nat__nat_(vat->n_threads_running)), 0,
	release_lock___void__ptr_lock_((&(vat->tasks_lock)))),
	res)));
}
some__chosen_task some__some__chosen_task__chosen_task_(chosen_task t) {
	return (some__chosen_task) {t};
}
_void noctx_must_remove_unordered_recur___void__ptr_mut_arr__nat___nat___nat_(mut_arr__nat* a, nat index, nat value) {
	return _op_equal_equal__bool__nat___nat_(index, a->size)
		? hard_fail___void__arr__char__id11_()
		: _op_equal_equal__bool__nat___nat_(noctx_at__nat__ptr_mut_arr__nat___nat_(a, index), value)
			? drop___void__nat_(noctx_remove_unordered_at_index__nat__ptr_mut_arr__nat___nat_(a, index))
			: noctx_must_remove_unordered_recur___void__ptr_mut_arr__nat___nat___nat_(a, noctx_incr__nat__nat_(index), value);
}
_void return_gc_ctx___void__ptr_gc_ctx_(gc_ctx* gc_ctx) {
	gc* gc;
	return ((gc = gc_ctx->gc),
	(((acquire_lock___void__ptr_lock_((&(gc->lk))),
	(gc_ctx->next_ctx = gc->context_head), 0),
	(gc->context_head = (opt__ptr_gc_ctx) { 1, .as_some__ptr_gc_ctx = some__some__ptr_gc_ctx__ptr_gc_ctx_(gc_ctx) }), 0),
	release_lock___void__ptr_lock_((&(gc->lk)))));
}
bool parse_cmd_line_args_dynamic__ptr_parsed_cmd_line_args__arr__arr__char___lambda0_(ctx* _ctx, arr__char it) {
	return starts_with__q__bool__arr__char___arr__char_(_ctx, it, (arr__char) _constant____arr__char__16);
}
some__nat some__some__nat__nat_(nat t) {
	return (some__nat) {t};
}
bool _op_greater_equal__bool__nat___nat_(nat a, nat b) {
	return !(_op_less__bool__nat___nat_(a, b));
}
bool parse_cmd_line_args_dynamic__ptr_parsed_cmd_line_args__arr__arr__char___lambda1_(ctx* _ctx, arr__char it) {
	return _op_equal_equal__bool__arr__char___arr__char_(it, (arr__char) _constant____arr__char__16);
}
mut_arr__arr__arr__char* new_mut_arr__ptr_mut_arr__arr__arr__char(ctx* _ctx) {
	return _initmut_arr__arr__arr__char(alloc__ptr__byte__nat_(_ctx, 32), (mut_arr__arr__arr__char) {0, 0ull, 0ull, NULL});
}
arr__char remove_start__arr__char__arr__char___arr__char_(ctx* _ctx, arr__char a, arr__char start) {
	return force__arr__char__opt__arr__char_(_ctx, try_remove_start__opt__arr__char__arr__char___arr__char_(_ctx, a, start));
}
opt__nat find_index__opt__nat__arr__arr__char___fun_mut1__bool__arr__char__id8_(ctx* _ctx, arr__arr__char a) {
	return find_index_recur__opt__nat__arr__arr__char___nat___fun_mut1__bool__arr__char__id8_(_ctx, a, 0ull);
}
_void add___void__mut_dict__arr__char__arr__arr__char___arr__char___arr__arr__char_(ctx* _ctx, mut_dict__arr__char__arr__arr__char m, arr__char key, arr__arr__char value) {
	return ((forbid___void__bool_(_ctx, has__q__bool__mut_dict__arr__char__arr__arr__char___arr__char_(_ctx, m, key)),
	push___void__ptr_mut_arr__arr__char___arr__char_(_ctx, m.keys, key)),
	push___void__ptr_mut_arr__arr__arr__char___arr__arr__char_(_ctx, m.values, value));
}
arr__arr__arr__char freeze__arr__arr__arr__char__ptr_mut_arr__arr__arr__char_(mut_arr__arr__arr__char* a) {
	return ((a->frozen__q = 1), 0,
	unsafe_as_arr__arr__arr__arr__char__ptr_mut_arr__arr__arr__char_(a));
}
exception_ctx* get_exception_ctx__ptr_exception_ctx(ctx* _ctx) {
	return (exception_ctx*) _ctx->exception_ctx_ptr;
}
bool _op_equal_equal__bool__ptr__jmp_buf_tag___ptr__jmp_buf_tag_(ptr__jmp_buf_tag a, ptr__jmp_buf_tag b) {
	comparison matched;
	return (matched = _op_less_equal_greater__comparison__ptr__jmp_buf_tag___ptr__jmp_buf_tag_(a, b),
		matched.kind == 0
		? 0
		: matched.kind == 1
		? 1
		: matched.kind == 2
		? 0
		: _failbool());
}
ptr__opt__arr__arr__char uninitialized_data__ptr__opt__arr__arr__char__nat_(ctx* _ctx, nat size) {
	ptr__byte bptr;
	return ((bptr = alloc__ptr__byte__nat_(_ctx, (size * 24ull))),
	(ptr__opt__arr__arr__char) bptr);
}
opt__arr__arr__char fill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat___opt__arr__arr__char___lambda0_(ctx* _ctx, fill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat___opt__arr__arr__char___lambda0___closure _closure, nat ignore) {
	return _closure.value;
}
opt__nat find_index__opt__nat__arr__arr__char___index_of__opt__nat__arr__arr__char___arr__char___lambda0___closure__klbindex_of__opt__nat__arr__arr__char___arr__char___lambda0_(ctx* _ctx, arr__arr__char a, index_of__opt__nat__arr__arr__char___arr__char___lambda0___closure pred) {
	return find_index_recur__opt__nat__arr__arr__char___nat___index_of__opt__nat__arr__arr__char___arr__char___lambda0___closure__klbindex_of__opt__nat__arr__arr__char___arr__char___lambda0_(_ctx, a, 0ull, pred);
}
comparison _op_less_equal_greater__comparison__arr__char___arr__char_(arr__char a, arr__char b) {
	comparison _cmpel;
	comparison _matchedel;
	return (a.size == 0ull)
		? (b.size == 0ull)
			? (comparison) { 1, .as_equal = (equal) { 0 } }
			: (comparison) { 0, .as_less = (less) { 0 } }
		: (b.size == 0ull)
			? (comparison) { 2, .as_greater = (greater) { 0 } }
			: ((_cmpel = _op_less_equal_greater__comparison__char___char_(*(a.data), *(b.data))),
			(_matchedel = _op_less_equal_greater__comparison__char___char_(*(a.data), *(b.data)),
				_matchedel.kind == 0
				? _cmpel
				: _matchedel.kind == 1
				? _op_less_equal_greater__comparison__arr__char___arr__char_((arr__char) {(a.size - 1ull), (a.data + 1ull)}, (arr__char) {(b.size - 1ull), (b.data + 1ull)})
				: _matchedel.kind == 2
				? _cmpel
				: _failcomparison()));
}
_void forbid___void__bool___arr__char_(ctx* _ctx, bool condition, arr__char message) {
	return (condition ? fail___void__arr__char_(_ctx, message) : 0);
}
opt__arr__arr__char noctx_at__opt__arr__arr__char__ptr_mut_arr__opt__arr__arr__char___nat_(mut_arr__opt__arr__arr__char* a, nat index) {
	return (hard_assert___void__bool_(_op_less__bool__nat___nat_(index, a->size)),
	*((a->data + index)));
}
_void noctx_set_at___void__ptr_mut_arr__opt__arr__arr__char___nat___opt__arr__arr__char_(mut_arr__opt__arr__arr__char* a, nat index, opt__arr__arr__char value) {
	return (hard_assert___void__bool_(_op_less__bool__nat___nat_(index, a->size)),
	((*((a->data + index)) = value), 0));
}
arr__char noctx_at__arr__char__arr__arr__char___nat_(arr__arr__char a, nat index) {
	return (hard_assert___void__bool_(_op_less__bool__nat___nat_(index, a.size)),
	*((a.data + index)));
}
arr__arr__char noctx_at__arr__arr__char__arr__arr__arr__char___nat_(arr__arr__arr__char a, nat index) {
	return (hard_assert___void__bool_(_op_less__bool__nat___nat_(index, a.size)),
	*((a.data + index)));
}
arr__arr__arr__char slice__arr__arr__arr__char__arr__arr__arr__char___nat___nat_(ctx* _ctx, arr__arr__arr__char a, nat begin, nat size) {
	return (assert___void__bool_(_ctx, _op_less_equal__bool__nat___nat_(_op_plus__nat__nat___nat_(_ctx, begin, size), a.size)),
	(arr__arr__arr__char) {size, (a.data + begin)});
}
nat decr__nat__nat_(ctx* _ctx, nat a) {
	return (forbid___void__bool_(_ctx, zero__q__bool__nat_(a)),
	wrap_decr__nat__nat_(a));
}
bool _op_equal_equal__bool__char___char_(char a, char b) {
	comparison matched;
	return (matched = _op_less_equal_greater__comparison__char___char_(a, b),
		matched.kind == 0
		? 0
		: matched.kind == 1
		? 1
		: matched.kind == 2
		? 0
		: _failbool());
}
nat todo__nat() {
	return hard_fail__nat__arr__char__id2_();
}
char at__char__arr__char___nat_(ctx* _ctx, arr__char a, nat index) {
	return (assert___void__bool_(_ctx, _op_less__bool__nat___nat_(index, a.size)),
	noctx_at__char__arr__char___nat_(a, index));
}
some__ptr__byte some__some__ptr__byte__ptr__byte_(ptr__byte t) {
	return (some__ptr__byte) {t};
}
ptr__byte hard_fail__ptr__byte__arr__char__id2_() {
	assert(0);
}
opt__nat find_rindex_recur__opt__nat__arr__char___nat___r_index_of__opt__nat__arr__char___char___lambda0___closure__klbr_index_of__opt__nat__arr__char___char___lambda0_(ctx* _ctx, arr__char a, nat index, r_index_of__opt__nat__arr__char___char___lambda0___closure pred) {
	return r_index_of__opt__nat__arr__char___char___lambda0_(_ctx, pred, at__char__arr__char___nat_(_ctx, a, index))
		? (opt__nat) { 1, .as_some__nat = some__some__nat__nat_(index) }
		: zero__q__bool__nat_(index)
			? (opt__nat) _constant__opt__nat__0
			: find_rindex_recur__opt__nat__arr__char___nat___r_index_of__opt__nat__arr__char___char___lambda0___closure__klbr_index_of__opt__nat__arr__char___char___lambda0_(_ctx, a, decr__nat__nat_(_ctx, index), pred);
}
ptr__char uninitialized_data__ptr__char__nat__id1000_(ctx* _ctx) {
	ptr__byte bptr;
	return ((bptr = alloc__ptr__byte__nat__id1000_(_ctx)),
	(ptr__char) bptr);
}
_void check_posix_error___void__int32_(ctx* _ctx, int32 e) {
	return assert___void__bool_(_ctx, zero__q__bool__int32_(e));
}
int32 get_errno__int32(ctx* _ctx) {
	return errno;assert(0);
}
_void hard_unreachable___void() {
	return hard_fail___void__arr__char__id12_();
}
arr__char unsafe_as_arr__arr__char__ptr_mut_arr__char_(mut_arr__char* a) {
	return (arr__char) {a->size, a->data};
}
bool negative__q__bool___int_(ctx* _ctx, _int i) {
	return _op_less__bool___int____int_(i, 0ll);
}
mut_arr__char* make_mut_arr__ptr_mut_arr__char__nat____op_plus__arr__char__arr__char___arr__char___lambda0___closure__klb_op_plus__arr__char__arr__char___arr__char___lambda0_(ctx* _ctx, nat size, _op_plus__arr__char__arr__char___arr__char___lambda0___closure f) {
	mut_arr__char* res;
	return ((res = new_uninitialized_mut_arr__ptr_mut_arr__char__nat_(_ctx, size)),
	(make_mut_arr_worker___void__ptr_mut_arr__char___nat____op_plus__arr__char__arr__char___arr__char___lambda0___closure__klb_op_plus__arr__char__arr__char___arr__char___lambda0_(_ctx, res, 0ull, f),
	res));
}
bool _op_equal_equal__bool__ptr__char___ptr__char_(ptr__char a, ptr__char b) {
	comparison matched;
	return (matched = _op_less_equal_greater__comparison__ptr__char___ptr__char_(a, b),
		matched.kind == 0
		? 0
		: matched.kind == 1
		? 1
		: matched.kind == 2
		? 0
		: _failbool());
}
_void add___void__mut_dict__arr__char__arr__char___arr__char___arr__char_(ctx* _ctx, mut_dict__arr__char__arr__char m, arr__char key, arr__char value) {
	return ((forbid___void__bool_(_ctx, has__q__bool__mut_dict__arr__char__arr__char___arr__char_(_ctx, m, key)),
	push___void__ptr_mut_arr__arr__char___arr__char_(_ctx, m.keys, key)),
	push___void__ptr_mut_arr__arr__char___arr__char_(_ctx, m.values, value));
}
ptr__char find_char_in_cstr__ptr__char__ptr__char___char_(ptr__char a, char c) {
	return _op_equal_equal__bool__char___char_(*(a), c)
		? a
		: _op_equal_equal__bool__char___char_(*(a), '\0')
			? todo__ptr__char()
			: find_char_in_cstr__ptr__char__ptr__char___char_(incr__ptr__char__ptr__char_(a), c);
}
arr__char arr_from_begin_end__arr__char__ptr__char___ptr__char_(ptr__char begin, ptr__char end) {
	return (arr__char) {_op_minus__nat__ptr__char___ptr__char_(end, begin), begin};
}
ptr__char incr__ptr__char__ptr__char_(ptr__char p) {
	return (p + 1ull);
}
ptr__char find_cstr_end__ptr__char__ptr__char_(ptr__char a) {
	return find_char_in_cstr__ptr__char__ptr__char___char_(a, '\0');
}
arr__arr__char unsafe_as_arr__arr__arr__char__ptr_mut_arr__arr__char_(mut_arr__arr__char* a) {
	return (arr__arr__char) {a->size, a->data};
}
bool is_dir__q__bool__arr__char_(ctx* _ctx, arr__char path) {
	return is_dir__q__bool__ptr__char_(_ctx, to_c_str__ptr__char__arr__char_(_ctx, path));
}
_void each___void__arr__arr__char___each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id9___list_compile_error_tests__arr__arr__char__arr__char___lambda0___closure__klblist_compile_error_tests__arr__arr__char__arr__char___lambda0___lambda0___closure__klbeach_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id9___list_compile_error_tests__arr__arr__char__arr__char___lambda0___closure__klblist_compile_error_tests__arr__arr__char__arr__char___lambda0___lambda0_(ctx* _ctx, arr__arr__char a, each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id9___list_compile_error_tests__arr__arr__char__arr__char___lambda0___closure__klblist_compile_error_tests__arr__arr__char__arr__char___lambda0___lambda0___closure f) {
	return empty__q__bool__arr__arr__char_(a)
		? 0
		: (each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id9___list_compile_error_tests__arr__arr__char__arr__char___lambda0___closure__klblist_compile_error_tests__arr__arr__char__arr__char___lambda0___lambda0_(_ctx, f, first__arr__char__arr__arr__char_(_ctx, a)),
		each___void__arr__arr__char___each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id9___list_compile_error_tests__arr__arr__char__arr__char___lambda0___closure__klblist_compile_error_tests__arr__arr__char__arr__char___lambda0___lambda0___closure__klbeach_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id9___list_compile_error_tests__arr__arr__char__arr__char___lambda0___closure__klblist_compile_error_tests__arr__arr__char__arr__char___lambda0___lambda0_(_ctx, tail__arr__arr__char__arr__arr__char_(_ctx, a), f));
}
arr__arr__char read_dir__arr__arr__char__arr__char_(ctx* _ctx, arr__char path) {
	return read_dir__arr__arr__char__ptr__char_(_ctx, to_c_str__ptr__char__arr__char_(_ctx, path));
}
_void list_compile_error_tests__arr__arr__char__arr__char___lambda0_(ctx* _ctx, list_compile_error_tests__arr__arr__char__arr__char___lambda0___closure _closure, arr__char child) {
	arr__char ext;
	return ((ext = force__arr__char__opt__arr__char_(_ctx, get_extension__opt__arr__char__arr__char_(_ctx, base_name__arr__char__arr__char_(_ctx, child)))),
	_op_equal_equal__bool__arr__char___arr__char_(ext, (arr__char) _constant____arr__char__51)
		? push___void__ptr_mut_arr__arr__char___arr__char_(_ctx, _closure.res, child)
		: _op_equal_equal__bool__arr__char___arr__char_(ext, (arr__char) _constant____arr__char__52)
			? 0
			: todo___void());
}
_void flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure__klbrun_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___lambda0_(ctx* _ctx, flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure__klbrun_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___lambda0___closure _closure, arr__char x) {
	return _op_less__bool__nat___nat_(_closure.res->size, _closure.max_size)
		? (push_all___void__ptr_mut_arr__ptr_failure___arr__ptr_failure_(_ctx, _closure.res, run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0_(_ctx, _closure.mapper, x)),
		reduce_size_if_more_than___void__ptr_mut_arr__ptr_failure___nat_(_ctx, _closure.res, _closure.max_size))
		: 0;
}
arr__ptr_failure unsafe_as_arr__arr__ptr_failure__ptr_mut_arr__ptr_failure_(mut_arr__ptr_failure* a) {
	return (arr__ptr_failure) {a->size, a->data};
}
result__arr__char__arr__ptr_failure then__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda0___closure__klbdo_test__int32__test_options___lambda0___lambda0___lambda0___closure__klbfirst_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda0___closure__klbdo_test__int32__test_options___lambda0___lambda0___lambda0_(ctx* _ctx, result__arr__char__arr__ptr_failure a, first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda0___closure__klbdo_test__int32__test_options___lambda0___lambda0___lambda0___closure f) {
	ok__arr__char o;
	err__arr__ptr_failure e;
	result__arr__char__arr__ptr_failure matched;
	return (matched = a,
		matched.kind == 0
		? (o = matched.as_ok__arr__char,
		first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda0___closure__klbdo_test__int32__test_options___lambda0___lambda0___lambda0_(_ctx, f, o.value)
		): matched.kind == 1
		? (e = matched.as_err__arr__ptr_failure,
		(result__arr__char__arr__ptr_failure) { 1, .as_err__arr__ptr_failure = e }
		): _failresult__arr__char__arr__ptr_failure());
}
result__arr__char__arr__ptr_failure do_test__int32__test_options___lambda0(ctx* _ctx, do_test__int32__test_options___lambda0___closure _closure) {
	return run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options_(_ctx, child_path__arr__char__arr__char___arr__char_(_ctx, _closure.test_path, (arr__char) _constant____arr__char__76), _closure.noze_exe, _closure.env, _closure.options);
}
result__arr__char__arr__ptr_failure then__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda1___closure__klbdo_test__int32__test_options___lambda1___lambda0___lambda0___closure__klbfirst_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda1___closure__klbdo_test__int32__test_options___lambda1___lambda0___lambda0_(ctx* _ctx, result__arr__char__arr__ptr_failure a, first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda1___closure__klbdo_test__int32__test_options___lambda1___lambda0___lambda0___closure f) {
	ok__arr__char o;
	err__arr__ptr_failure e;
	result__arr__char__arr__ptr_failure matched;
	return (matched = a,
		matched.kind == 0
		? (o = matched.as_ok__arr__char,
		first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda1___closure__klbdo_test__int32__test_options___lambda1___lambda0___lambda0_(_ctx, f, o.value)
		): matched.kind == 1
		? (e = matched.as_err__arr__ptr_failure,
		(result__arr__char__arr__ptr_failure) { 1, .as_err__arr__ptr_failure = e }
		): _failresult__arr__char__arr__ptr_failure());
}
result__arr__char__arr__ptr_failure do_test__int32__test_options___lambda1(ctx* _ctx, do_test__int32__test_options___lambda1___closure _closure) {
	return lint__result__arr__char__arr__ptr_failure__arr__char___test_options_(_ctx, _closure.noze_path, _closure.options);
}
_void print_failure___void__ptr_failure_(ctx* _ctx, failure* failure) {
	return ((((print_bold___void(_ctx),
	print_sync_no_newline___void__arr__char_(failure->path)),
	print_reset___void(_ctx)),
	print_sync_no_newline___void__arr__char_((arr__char) _constant____arr__char__91)),
	print_sync___void__arr__char_(failure->message));
}
failure* at__ptr_failure__arr__ptr_failure___nat_(ctx* _ctx, arr__ptr_failure a, nat index) {
	return (assert___void__bool_(_ctx, _op_less__bool__nat___nat_(index, a.size)),
	noctx_at__ptr_failure__arr__ptr_failure___nat_(a, index));
}
arr__ptr_failure slice_starting_at__arr__ptr_failure__arr__ptr_failure___nat_(ctx* _ctx, arr__ptr_failure a, nat begin) {
	return (assert___void__bool_(_ctx, _op_less_equal__bool__nat___nat_(begin, a.size)),
	slice__arr__ptr_failure__arr__ptr_failure___nat___nat_(_ctx, a, begin, _op_minus__nat__nat___nat_(_ctx, a.size, begin)));
}
bool try_set__bool__ptr__atomic_bool_(_atomic_bool* a) {
	return try_change__bool__ptr__atomic_bool___bool_(a, 0);
}
bool try_change__bool__ptr__atomic_bool___bool_(_atomic_bool* a, bool old_value) {
	return compare_exchange_strong__bool__ptr__bool___ptr__bool___bool_((&(a->value)), (&(old_value)), !(old_value));
}
some__ptr_fut_callback_node___void some__some__ptr_fut_callback_node___void__ptr_fut_callback_node___void_(fut_callback_node___void* t) {
	return (some__ptr_fut_callback_node___void) {t};
}
_void then__ptr_fut__int32__ptr_fut___void___fun_ref1__int32___void___lambda0___dynamic(ctx* _ctx, then__ptr_fut__int32__ptr_fut___void___fun_ref1__int32___void___lambda0___closure* _closure, result___void__exception result) {
	ok___void o;
	err__exception e;
	result___void__exception matched;
	return (matched = result,
		matched.kind == 0
		? (o = matched.as_ok___void,
		forward_to___void__ptr_fut__int32___ptr_fut__int32_(_ctx, call__ptr_fut__int32__fun_ref1__int32___void____void_(_ctx, _closure->cb, o.value), _closure->res)
		): matched.kind == 1
		? (e = matched.as_err__exception,
		reject___void__ptr_fut__int32___exception_(_ctx, _closure->res, e.value)
		): _fail_void());
}
_void then__ptr_fut__int32__ptr_fut___void___fun_ref1__int32___void___lambda0_(ctx* _ctx, then__ptr_fut__int32__ptr_fut___void___fun_ref1__int32___void___lambda0___closure _closure, result___void__exception result) {
	ok___void o;
	err__exception e;
	result___void__exception matched;
	return (matched = result,
		matched.kind == 0
		? (o = matched.as_ok___void,
		forward_to___void__ptr_fut__int32___ptr_fut__int32_(_ctx, call__ptr_fut__int32__fun_ref1__int32___void____void_(_ctx, _closure.cb, o.value), _closure.res)
		): matched.kind == 1
		? (e = matched.as_err__exception,
		reject___void__ptr_fut__int32___exception_(_ctx, _closure.res, e.value)
		): _fail_void());
}
ok___void ok__ok___void___void_(_void t) {
	return (ok___void) {t};
}
vat* get_vat__ptr_vat__nat_(ctx* _ctx, nat vat_id) {
	return at__ptr_vat__arr__ptr_vat___nat_(_ctx, get_gctx__ptr_global_ctx(_ctx)->vats, vat_id);
}
_void add_task___void__ptr_vat___task_(ctx* _ctx, vat* v, task t) {
	mut_bag_node__task* node;
	return ((node = new_mut_bag_node__ptr_mut_bag_node__task__task_(_ctx, t)),
	(((acquire_lock___void__ptr_lock_((&(v->tasks_lock))),
	add___void__ptr_mut_bag__task___ptr_mut_bag_node__task_((&(v->tasks)), node)),
	release_lock___void__ptr_lock_((&(v->tasks_lock)))),
	broadcast___void__ptr_condition_((&(v->gctx->may_be_work_to_do)))));
}
_void call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic(ctx* _ctx, call__ptr_fut__int32__fun_ref0__int32___lambda0___closure* _closure) {
	return catch___void__call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda0___closure__klbcall__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda0___call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda1___closure__klbcall__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda1_(_ctx, (call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda0___closure) {_closure->f, _closure->res}, (call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda1___closure) {_closure->res});
}
arr__ptr__char slice__arr__ptr__char__arr__ptr__char___nat___nat_(ctx* _ctx, arr__ptr__char a, nat begin, nat size) {
	return (assert___void__bool_(_ctx, _op_less_equal__bool__nat___nat_(_op_plus__nat__nat___nat_(_ctx, begin, size), a.size)),
	(arr__ptr__char) {size, (a.data + begin)});
}
mut_arr__arr__char* make_mut_arr__ptr_mut_arr__arr__char__nat___map__arr__arr__char__arr__ptr__char___fun_mut1__arr__char__ptr__char__id1___lambda0___closure__klbmap__arr__arr__char__arr__ptr__char___fun_mut1__arr__char__ptr__char__id1___lambda0_(ctx* _ctx, nat size, map__arr__arr__char__arr__ptr__char___fun_mut1__arr__char__ptr__char__id1___lambda0___closure f) {
	mut_arr__arr__char* res;
	return ((res = new_uninitialized_mut_arr__ptr_mut_arr__arr__char__nat_(_ctx, size)),
	(make_mut_arr_worker___void__ptr_mut_arr__arr__char___nat___map__arr__arr__char__arr__ptr__char___fun_mut1__arr__char__ptr__char__id1___lambda0___closure__klbmap__arr__arr__char__arr__ptr__char___fun_mut1__arr__char__ptr__char__id1___lambda0_(_ctx, res, 0ull, f),
	res));
}
opt__task find_and_remove_first_doable_task__opt__task__ptr_vat_(vat* vat) {
	mut_bag__task* tasks;
	opt__task_and_nodes res;
	some__task_and_nodes s;
	opt__task_and_nodes matched;
	return ((tasks = (&(vat->tasks))),
	((res = find_and_remove_first_doable_task_recur__opt__task_and_nodes__ptr_vat___opt__ptr_mut_bag_node__task_(vat, tasks->head)),
	(matched = res,
		matched.kind == 0
		? (opt__task) _constant__opt__task__0
		: matched.kind == 1
		? (s = matched.as_some__task_and_nodes,
		((tasks->head = s.value.nodes), 0,
		(opt__task) { 1, .as_some__task = some__some__task__task_(s.value.task) })
		): _failopt__task())));
}
some__opt__task some__some__opt__task__opt__task_(opt__task t) {
	return (some__opt__task) {t};
}
some__task some__some__task__task_(task t) {
	return (some__task) {t};
}
bool empty__q__bool__opt__opt__task_(opt__opt__task a) {
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
_void hard_fail___void__arr__char__id11_() {
	assert(0);
}
nat noctx_at__nat__ptr_mut_arr__nat___nat_(mut_arr__nat* a, nat index) {
	return (hard_assert___void__bool_(_op_less__bool__nat___nat_(index, a->size)),
	*((a->data + index)));
}
_void drop___void__nat_(nat t) {
	return 0;
}
nat noctx_remove_unordered_at_index__nat__ptr_mut_arr__nat___nat_(mut_arr__nat* a, nat index) {
	nat res;
	return ((res = noctx_at__nat__ptr_mut_arr__nat___nat_(a, index)),
	((noctx_set_at___void__ptr_mut_arr__nat___nat___nat_(a, index, noctx_last__nat__ptr_mut_arr__nat_(a)),
	(a->size = noctx_decr__nat__nat_(a->size)), 0),
	res));
}
some__ptr_gc_ctx some__some__ptr_gc_ctx__ptr_gc_ctx_(gc_ctx* t) {
	return (some__ptr_gc_ctx) {t};
}
bool starts_with__q__bool__arr__char___arr__char_(ctx* _ctx, arr__char a, arr__char start) {
	return (_op_greater_equal__bool__nat___nat_(a.size, start.size) && arr_eq__q__bool__arr__char___arr__char_(_ctx, slice__arr__char__arr__char___nat___nat_(_ctx, a, 0ull, start.size), start));
}
arr__char force__arr__char__opt__arr__char_(ctx* _ctx, opt__arr__char a) {
	none n;
	some__arr__char s;
	opt__arr__char matched;
	return (matched = a,
		matched.kind == 0
		? (n = matched.as_none,
		fail__arr__char__arr__char__id17_(_ctx)
		): matched.kind == 1
		? (s = matched.as_some__arr__char,
		s.value
		): _failarr__char());
}
opt__arr__char try_remove_start__opt__arr__char__arr__char___arr__char_(ctx* _ctx, arr__char a, arr__char start) {
	return starts_with__q__bool__arr__char___arr__char_(_ctx, a, start)
		? (opt__arr__char) { 1, .as_some__arr__char = some__some__arr__char__arr__char_(slice_starting_at__arr__char__arr__char___nat_(_ctx, a, start.size)) }
		: (opt__arr__char) _constant__opt__arr__char__0;
}
opt__nat find_index_recur__opt__nat__arr__arr__char___nat___fun_mut1__bool__arr__char__id8_(ctx* _ctx, arr__arr__char a, nat index) {
	return _op_equal_equal__bool__nat___nat_(index, a.size)
		? (opt__nat) _constant__opt__nat__0
		: parse_named_args_recur___void__arr__arr__char___mut_dict__arr__char__arr__arr__char___lambda0_(_ctx, at__arr__char__arr__arr__char___nat_(_ctx, a, index))
			? (opt__nat) { 1, .as_some__nat = some__some__nat__nat_(index) }
			: find_index_recur__opt__nat__arr__arr__char___nat___fun_mut1__bool__arr__char__id8_(_ctx, a, incr__nat__nat_(_ctx, index));
}
bool has__q__bool__mut_dict__arr__char__arr__arr__char___arr__char_(ctx* _ctx, mut_dict__arr__char__arr__arr__char d, arr__char key) {
	return has__q__bool__ptr_dict__arr__char__arr__arr__char___arr__char_(_ctx, unsafe_as_dict__ptr_dict__arr__char__arr__arr__char__mut_dict__arr__char__arr__arr__char_(_ctx, d), key);
}
_void push___void__ptr_mut_arr__arr__char___arr__char_(ctx* _ctx, mut_arr__arr__char* a, arr__char value) {
	return ((((_op_equal_equal__bool__nat___nat_(a->size, a->capacity)
		? increase_capacity_to___void__ptr_mut_arr__arr__char___nat_(_ctx, a, (zero__q__bool__nat_(a->size) ? 4ull : _op_times__nat__nat___nat_(_ctx, a->size, 2ull)))
		: 0,
	ensure_capacity___void__ptr_mut_arr__arr__char___nat_(_ctx, a, round_up_to_power_of_two__nat__nat_(_ctx, incr__nat__nat_(_ctx, a->size)))),
	assert___void__bool_(_ctx, _op_less__bool__nat___nat_(a->size, a->capacity))),
	((*((a->data + a->size)) = value), 0)),
	(a->size = incr__nat__nat_(_ctx, a->size)), 0);
}
_void push___void__ptr_mut_arr__arr__arr__char___arr__arr__char_(ctx* _ctx, mut_arr__arr__arr__char* a, arr__arr__char value) {
	return ((((_op_equal_equal__bool__nat___nat_(a->size, a->capacity)
		? increase_capacity_to___void__ptr_mut_arr__arr__arr__char___nat_(_ctx, a, (zero__q__bool__nat_(a->size) ? 4ull : _op_times__nat__nat___nat_(_ctx, a->size, 2ull)))
		: 0,
	ensure_capacity___void__ptr_mut_arr__arr__arr__char___nat_(_ctx, a, round_up_to_power_of_two__nat__nat_(_ctx, incr__nat__nat_(_ctx, a->size)))),
	assert___void__bool_(_ctx, _op_less__bool__nat___nat_(a->size, a->capacity))),
	((*((a->data + a->size)) = value), 0)),
	(a->size = incr__nat__nat_(_ctx, a->size)), 0);
}
arr__arr__arr__char unsafe_as_arr__arr__arr__arr__char__ptr_mut_arr__arr__arr__char_(mut_arr__arr__arr__char* a) {
	return (arr__arr__arr__char) {a->size, a->data};
}
comparison _op_less_equal_greater__comparison__ptr__jmp_buf_tag___ptr__jmp_buf_tag_(ptr__jmp_buf_tag a, ptr__jmp_buf_tag b) {
	return (a < b)
		? (comparison) { 0, .as_less = (less) { 0 } }
		: (b < a)
			? (comparison) { 2, .as_greater = (greater) { 0 } }
			: (comparison) { 1, .as_equal = (equal) { 0 } };
}
opt__nat find_index_recur__opt__nat__arr__arr__char___nat___index_of__opt__nat__arr__arr__char___arr__char___lambda0___closure__klbindex_of__opt__nat__arr__arr__char___arr__char___lambda0_(ctx* _ctx, arr__arr__char a, nat index, index_of__opt__nat__arr__arr__char___arr__char___lambda0___closure pred) {
	return _op_equal_equal__bool__nat___nat_(index, a.size)
		? (opt__nat) _constant__opt__nat__0
		: index_of__opt__nat__arr__arr__char___arr__char___lambda0_(_ctx, pred, at__arr__char__arr__arr__char___nat_(_ctx, a, index))
			? (opt__nat) { 1, .as_some__nat = some__some__nat__nat_(index) }
			: find_index_recur__opt__nat__arr__arr__char___nat___index_of__opt__nat__arr__arr__char___arr__char___lambda0___closure__klbindex_of__opt__nat__arr__arr__char___arr__char___lambda0_(_ctx, a, incr__nat__nat_(_ctx, index), pred);
}
comparison _op_less_equal_greater__comparison__char___char_(char a, char b) {
	return (a < b)
		? (comparison) { 0, .as_less = (less) { 0 } }
		: (b < a)
			? (comparison) { 2, .as_greater = (greater) { 0 } }
			: (comparison) { 1, .as_equal = (equal) { 0 } };
}
nat wrap_decr__nat__nat_(nat a) {
	return (a - 1ull);
}
nat hard_fail__nat__arr__char__id2_() {
	assert(0);
}
char noctx_at__char__arr__char___nat_(arr__char a, nat index) {
	return (hard_assert___void__bool_(_op_less__bool__nat___nat_(index, a.size)),
	*((a.data + index)));
}
bool r_index_of__opt__nat__arr__char___char___lambda0_(ctx* _ctx, r_index_of__opt__nat__arr__char___char___lambda0___closure _closure, char it) {
	return _op_equal_equal__bool__char___char_(it, _closure.value);
}
ptr__byte alloc__ptr__byte__nat__id1000_(ctx* _ctx) {
	return gc_alloc__ptr__byte__ptr_gc___nat_(_ctx, get_gc__ptr_gc(_ctx), 1000ull);
}
_void hard_fail___void__arr__char__id12_() {
	assert(0);
}
bool _op_less__bool___int____int_(_int a, _int b) {
	comparison matched;
	return (matched = _op_less_equal_greater__comparison___int____int_(a, b),
		matched.kind == 0
		? 1
		: matched.kind == 1
		? 0
		: matched.kind == 2
		? 0
		: _failbool());
}
mut_arr__char* new_uninitialized_mut_arr__ptr_mut_arr__char__nat_(ctx* _ctx, nat size) {
	return _initmut_arr__char(alloc__ptr__byte__nat_(_ctx, 32), (mut_arr__char) {0, size, size, uninitialized_data__ptr__char__nat_(_ctx, size)});
}
_void make_mut_arr_worker___void__ptr_mut_arr__char___nat____op_plus__arr__char__arr__char___arr__char___lambda0___closure__klb_op_plus__arr__char__arr__char___arr__char___lambda0_(ctx* _ctx, mut_arr__char* m, nat i, _op_plus__arr__char__arr__char___arr__char___lambda0___closure f) {
	return _op_equal_equal__bool__nat___nat_(i, m->size)
		? 0
		: (set_at___void__ptr_mut_arr__char___nat___char_(_ctx, m, i, _op_plus__arr__char__arr__char___arr__char___lambda0_(_ctx, f, i)),
		make_mut_arr_worker___void__ptr_mut_arr__char___nat____op_plus__arr__char__arr__char___arr__char___lambda0___closure__klb_op_plus__arr__char__arr__char___arr__char___lambda0_(_ctx, m, incr__nat__nat_(_ctx, i), f));
}
comparison _op_less_equal_greater__comparison__ptr__char___ptr__char_(ptr__char a, ptr__char b) {
	return (a < b)
		? (comparison) { 0, .as_less = (less) { 0 } }
		: (b < a)
			? (comparison) { 2, .as_greater = (greater) { 0 } }
			: (comparison) { 1, .as_equal = (equal) { 0 } };
}
bool has__q__bool__mut_dict__arr__char__arr__char___arr__char_(ctx* _ctx, mut_dict__arr__char__arr__char d, arr__char key) {
	return has__q__bool__ptr_dict__arr__char__arr__char___arr__char_(_ctx, unsafe_as_dict__ptr_dict__arr__char__arr__char__mut_dict__arr__char__arr__char_(_ctx, d), key);
}
ptr__char todo__ptr__char() {
	return hard_fail__ptr__char__arr__char__id2_();
}
nat _op_minus__nat__ptr__char___ptr__char_(ptr__char a, ptr__char b) {
	return (nat) (a - (nat) b);
}
bool is_dir__q__bool__ptr__char_(ctx* _ctx, ptr__char path) {
	some__ptr_stat_t s;
	opt__ptr_stat_t matched;
	return (matched = get_stat__opt__ptr_stat_t__ptr__char_(_ctx, path),
		matched.kind == 0
		? todo__bool()
		: matched.kind == 1
		? (s = matched.as_some__ptr_stat_t,
		_op_equal_equal__bool__nat32___nat32_((s.value->st_mode & 61440u), 16384u)
		): _failbool());
}
_void each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id9___list_compile_error_tests__arr__arr__char__arr__char___lambda0___closure__klblist_compile_error_tests__arr__arr__char__arr__char___lambda0___lambda0_(ctx* _ctx, each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id9___list_compile_error_tests__arr__arr__char__arr__char___lambda0___closure__klblist_compile_error_tests__arr__arr__char__arr__char___lambda0___lambda0___closure _closure, arr__char child_name) {
	return always_true__bool__arr__char___asLambda_(_ctx, child_name)
		? each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id9___list_compile_error_tests__arr__arr__char__arr__char___lambda0___closure__klblist_compile_error_tests__arr__arr__char__arr__char___lambda0_(_ctx, child_path__arr__char__arr__char___arr__char_(_ctx, _closure.path, child_name), _closure.f)
		: 0;
}
arr__arr__char read_dir__arr__arr__char__ptr__char_(ctx* _ctx, ptr__char path) {
	ptr__byte dirp;
	mut_arr__arr__char* res;
	return ((dirp = opendir(path)),
	(forbid___void__bool_(_ctx, null__q__bool__ptr__byte_(dirp)),
	((res = new_mut_arr__ptr_mut_arr__arr__char(_ctx)),
	(read_dir_recur___void__ptr__byte___ptr_mut_arr__arr__char_(_ctx, dirp, res),
	sort__arr__arr__char__arr__arr__char_(_ctx, freeze__arr__arr__char__ptr_mut_arr__arr__char_(res))))));
}
opt__arr__char get_extension__opt__arr__char__arr__char_(ctx* _ctx, arr__char name) {
	some__nat s;
	opt__nat matched;
	return (matched = last_index_of__opt__nat__arr__char___char_(_ctx, name, '.'),
		matched.kind == 0
		? (opt__arr__char) _constant__opt__arr__char__0
		: matched.kind == 1
		? (s = matched.as_some__nat,
		(opt__arr__char) { 1, .as_some__arr__char = some__some__arr__char__arr__char_(slice_after__arr__char__arr__char___nat_(_ctx, name, s.value)) }
		): _failopt__arr__char());
}
arr__char base_name__arr__char__arr__char_(ctx* _ctx, arr__char path) {
	opt__nat i;
	some__nat s;
	opt__nat matched;
	return ((i = last_index_of__opt__nat__arr__char___char_(_ctx, path, '/')),
	(matched = i,
		matched.kind == 0
		? path
		: matched.kind == 1
		? (s = matched.as_some__nat,
		slice_after__arr__char__arr__char___nat_(_ctx, path, s.value)
		): _failarr__char()));
}
_void push_all___void__ptr_mut_arr__ptr_failure___arr__ptr_failure_(ctx* _ctx, mut_arr__ptr_failure* a, arr__ptr_failure values) {
	return each___void__arr__ptr_failure___push_all___void__ptr_mut_arr__ptr_failure___arr__ptr_failure___lambda0___closure__klbpush_all___void__ptr_mut_arr__ptr_failure___arr__ptr_failure___lambda0_(_ctx, values, (push_all___void__ptr_mut_arr__ptr_failure___arr__ptr_failure___lambda0___closure) {a});
}
arr__ptr_failure run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0_(ctx* _ctx, run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure _closure, arr__char test) {
	return (_closure.options.print_tests__q
		? print_sync___void__arr__char_(_op_plus__arr__char__arr__char___arr__char_(_ctx, (arr__char) _constant____arr__char__53, test))
		: 0,
	run_single_compile_error_test__arr__ptr_failure__arr__char___ptr_dict__arr__char__arr__char___arr__char_(_ctx, _closure.path_to_noze, _closure.env, test));
}
_void reduce_size_if_more_than___void__ptr_mut_arr__ptr_failure___nat_(ctx* _ctx, mut_arr__ptr_failure* a, nat new_size) {
	return _op_less__bool__nat___nat_(new_size, a->size)
		? (a->size = new_size), 0
		: 0;
}
result__arr__char__arr__ptr_failure first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda0___closure__klbdo_test__int32__test_options___lambda0___lambda0___lambda0_(ctx* _ctx, first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda0___closure__klbdo_test__int32__test_options___lambda0___lambda0___lambda0___closure _closure, arr__char b_descr) {
	return (result__arr__char__arr__ptr_failure) { 0, .as_ok__arr__char = ok__ok__arr__char__arr__char_(_op_plus__arr__char__arr__char___arr__char_(_ctx, _op_plus__arr__char__arr__char___arr__char_(_ctx, _closure.a_descr, (arr__char) _constant____arr__char__4), b_descr)) };
}
result__arr__char__arr__ptr_failure run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options_(ctx* _ctx, arr__char path, arr__char path_to_noze, dict__arr__char__arr__char* env, test_options options) {
	arr__arr__char tests;
	arr__ptr_failure failures;
	return ((tests = list_runnable_tests__arr__arr__char__arr__char_(_ctx, path)),
	((failures = flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure__klbrun_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0_(_ctx, tests, options.max_failures, (run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure) {options, path_to_noze, env})),
	has__q__bool__arr__ptr_failure_(failures)
		? (result__arr__char__arr__ptr_failure) { 1, .as_err__arr__ptr_failure = err__err__arr__ptr_failure__arr__ptr_failure_(failures) }
		: (result__arr__char__arr__ptr_failure) { 0, .as_ok__arr__char = ok__ok__arr__char__arr__char_(_op_plus__arr__char__arr__char___arr__char_(_ctx, _op_plus__arr__char__arr__char___arr__char_(_ctx, (arr__char) _constant____arr__char__83, to_str__arr__char__nat_(_ctx, tests.size)), (arr__char) _constant____arr__char__84)) }));
}
result__arr__char__arr__ptr_failure first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda1___closure__klbdo_test__int32__test_options___lambda1___lambda0___lambda0_(ctx* _ctx, first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda1___closure__klbdo_test__int32__test_options___lambda1___lambda0___lambda0___closure _closure, arr__char b_descr) {
	return (result__arr__char__arr__ptr_failure) { 0, .as_ok__arr__char = ok__ok__arr__char__arr__char_(_op_plus__arr__char__arr__char___arr__char_(_ctx, _op_plus__arr__char__arr__char___arr__char_(_ctx, _closure.a_descr, (arr__char) _constant____arr__char__4), b_descr)) };
}
result__arr__char__arr__ptr_failure lint__result__arr__char__arr__ptr_failure__arr__char___test_options_(ctx* _ctx, arr__char path, test_options options) {
	arr__arr__char files;
	arr__ptr_failure failures;
	return ((files = list_lintable_files__arr__arr__char__arr__char_(_ctx, path)),
	((failures = flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___lint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___closure__klblint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0_(_ctx, files, options.max_failures, (lint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___closure) {options})),
	has__q__bool__arr__ptr_failure_(failures)
		? (result__arr__char__arr__ptr_failure) { 1, .as_err__arr__ptr_failure = err__err__arr__ptr_failure__arr__ptr_failure_(failures) }
		: (result__arr__char__arr__ptr_failure) { 0, .as_ok__arr__char = ok__ok__arr__char__arr__char_(_op_plus__arr__char__arr__char___arr__char_(_ctx, _op_plus__arr__char__arr__char___arr__char_(_ctx, (arr__char) _constant____arr__char__102, to_str__arr__char__nat_(_ctx, files.size)), (arr__char) _constant____arr__char__103)) }));
}
_void print_bold___void(ctx* _ctx) {
	return print_sync_no_newline___void__arr__char_((arr__char) _constant____arr__char__104);
}
_void print_reset___void(ctx* _ctx) {
	return print_sync_no_newline___void__arr__char_((arr__char) _constant____arr__char__105);
}
failure* noctx_at__ptr_failure__arr__ptr_failure___nat_(arr__ptr_failure a, nat index) {
	return (hard_assert___void__bool_(_op_less__bool__nat___nat_(index, a.size)),
	*((a.data + index)));
}
bool compare_exchange_strong__bool__ptr__bool___ptr__bool___bool_(ptr__bool value_ptr, ptr__bool expected_ptr, bool desired) {
	return atomic_compare_exchange_strong(value_ptr, expected_ptr, desired);
}
_void forward_to___void__ptr_fut__int32___ptr_fut__int32_(ctx* _ctx, fut__int32* from, fut__int32* to) {
	return then_void___void__ptr_fut__int32___forward_to___void__ptr_fut__int32___ptr_fut__int32___lambda0___closure__klbforward_to___void__ptr_fut__int32___ptr_fut__int32___lambda0_(_ctx, from, (forward_to___void__ptr_fut__int32___ptr_fut__int32___lambda0___closure) {to});
}
fut__int32* call__ptr_fut__int32__fun_ref1__int32___void____void_(ctx* _ctx, fun_ref1__int32___void f, _void p0) {
	vat* vat;
	fut__int32* res;
	return ((vat = get_vat__ptr_vat__nat_(_ctx, f.vat_and_actor.vat)),
	((res = new_unresolved_fut__ptr_fut__int32(_ctx)),
	(add_task___void__ptr_vat___task_(_ctx, vat, (task) {f.vat_and_actor.actor, (fun_mut0___void) {
		(fun_ptr2___void__ptr_ctx__ptr__byte) call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic, (ptr__byte) _initcall__ptr_fut__int32__fun_ref1__int32___void____void___lambda0___closure(alloc__ptr__byte__nat_(_ctx, 48), (call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0___closure) {f, p0, res}) }}),
		res)));
}
_void reject___void__ptr_fut__int32___exception_(ctx* _ctx, fut__int32* f, exception e) {
	return resolve_or_reject___void__ptr_fut__int32___result__int32__exception_(_ctx, f, (result__int32__exception) { 1, .as_err__exception = err__err__exception__exception_(e) });
}
vat* at__ptr_vat__arr__ptr_vat___nat_(ctx* _ctx, arr__ptr_vat a, nat index) {
	return (assert___void__bool_(_ctx, _op_less__bool__nat___nat_(index, a.size)),
	noctx_at__ptr_vat__arr__ptr_vat___nat_(a, index));
}
mut_bag_node__task* new_mut_bag_node__ptr_mut_bag_node__task__task_(ctx* _ctx, task value) {
	return _initmut_bag_node__task(alloc__ptr__byte__nat_(_ctx, 40), (mut_bag_node__task) {value, (opt__ptr_mut_bag_node__task) _constant__opt__ptr_mut_bag_node__task__0});
}
_void add___void__ptr_mut_bag__task___ptr_mut_bag_node__task_(mut_bag__task* bag, mut_bag_node__task* node) {
	return ((node->next_node = bag->head), 0,
	(bag->head = (opt__ptr_mut_bag_node__task) { 1, .as_some__ptr_mut_bag_node__task = some__some__ptr_mut_bag_node__task__ptr_mut_bag_node__task_(node) }), 0);
}
_void catch___void__call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda0___closure__klbcall__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda0___call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda1___closure__klbcall__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda1_(ctx* _ctx, call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda0___closure try, call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda1___closure catcher) {
	return catch_with_exception_ctx___void__ptr_exception_ctx___call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda0___closure__klbcall__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda0___call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda1___closure__klbcall__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda1_(_ctx, get_exception_ctx__ptr_exception_ctx(_ctx), try, catcher);
}
mut_arr__arr__char* new_uninitialized_mut_arr__ptr_mut_arr__arr__char__nat_(ctx* _ctx, nat size) {
	return _initmut_arr__arr__char(alloc__ptr__byte__nat_(_ctx, 32), (mut_arr__arr__char) {0, size, size, uninitialized_data__ptr__arr__char__nat_(_ctx, size)});
}
_void make_mut_arr_worker___void__ptr_mut_arr__arr__char___nat___map__arr__arr__char__arr__ptr__char___fun_mut1__arr__char__ptr__char__id1___lambda0___closure__klbmap__arr__arr__char__arr__ptr__char___fun_mut1__arr__char__ptr__char__id1___lambda0_(ctx* _ctx, mut_arr__arr__char* m, nat i, map__arr__arr__char__arr__ptr__char___fun_mut1__arr__char__ptr__char__id1___lambda0___closure f) {
	return _op_equal_equal__bool__nat___nat_(i, m->size)
		? 0
		: (set_at___void__ptr_mut_arr__arr__char___nat___arr__char_(_ctx, m, i, map__arr__arr__char__arr__ptr__char___fun_mut1__arr__char__ptr__char__id1___lambda0_(_ctx, f, i)),
		make_mut_arr_worker___void__ptr_mut_arr__arr__char___nat___map__arr__arr__char__arr__ptr__char___fun_mut1__arr__char__ptr__char__id1___lambda0___closure__klbmap__arr__arr__char__arr__ptr__char___fun_mut1__arr__char__ptr__char__id1___lambda0_(_ctx, m, incr__nat__nat_(_ctx, i), f));
}
opt__task_and_nodes find_and_remove_first_doable_task_recur__opt__task_and_nodes__ptr_vat___opt__ptr_mut_bag_node__task_(vat* vat, opt__ptr_mut_bag_node__task opt_node) {
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
		? (opt__task_and_nodes) _constant__opt__task_and_nodes__0
		: matched1.kind == 1
		? (s = matched1.as_some__ptr_mut_bag_node__task,
		((node = s.value),
		((task = node->value),
		((actors = (&(vat->currently_running_actors))),
		((task_ok = contains__q__bool__ptr_mut_arr__nat___nat_(actors, task.actor_id)
			? 0
			: (push_capacity_must_be_sufficient___void__ptr_mut_arr__nat___nat_(actors, task.actor_id),
			1)),
		task_ok
			? (opt__task_and_nodes) { 1, .as_some__task_and_nodes = some__some__task_and_nodes__task_and_nodes_((task_and_nodes) {task, node->next_node}) }
			: (matched = find_and_remove_first_doable_task_recur__opt__task_and_nodes__ptr_vat___opt__ptr_mut_bag_node__task_(vat, node->next_node),
				matched.kind == 0
				? (opt__task_and_nodes) _constant__opt__task_and_nodes__0
				: matched.kind == 1
				? (ss = matched.as_some__task_and_nodes,
				((tn = ss.value),
				((node->next_node = tn.nodes), 0,
				(opt__task_and_nodes) { 1, .as_some__task_and_nodes = some__some__task_and_nodes__task_and_nodes_((task_and_nodes) {tn.task, (opt__ptr_mut_bag_node__task) { 1, .as_some__ptr_mut_bag_node__task = some__some__ptr_mut_bag_node__task__ptr_mut_bag_node__task_(node) }}) }))
				): _failopt__task_and_nodes())))))
		): _failopt__task_and_nodes());
}
_void noctx_set_at___void__ptr_mut_arr__nat___nat___nat_(mut_arr__nat* a, nat index, nat value) {
	return (hard_assert___void__bool_(_op_less__bool__nat___nat_(index, a->size)),
	((*((a->data + index)) = value), 0));
}
nat noctx_last__nat__ptr_mut_arr__nat_(mut_arr__nat* a) {
	return (hard_forbid___void__bool_(empty__q__bool__ptr_mut_arr__nat_(a)),
	noctx_at__nat__ptr_mut_arr__nat___nat_(a, noctx_decr__nat__nat_(a->size)));
}
bool arr_eq__q__bool__arr__char___arr__char_(ctx* _ctx, arr__char a, arr__char b) {
	return (_op_equal_equal__bool__nat___nat_(a.size, b.size) && (empty__q__bool__arr__char_(a) || (_op_equal_equal__bool__char___char_(first__char__arr__char_(_ctx, a), first__char__arr__char_(_ctx, b)) && arr_eq__q__bool__arr__char___arr__char_(_ctx, tail__arr__char__arr__char_(_ctx, a), tail__arr__char__arr__char_(_ctx, b)))));
}
arr__char fail__arr__char__arr__char__id17_(ctx* _ctx) {
	return throw__arr__char__exception__id1_(_ctx);
}
some__arr__char some__some__arr__char__arr__char_(arr__char t) {
	return (some__arr__char) {t};
}
arr__char slice_starting_at__arr__char__arr__char___nat_(ctx* _ctx, arr__char a, nat begin) {
	return (assert___void__bool_(_ctx, _op_less_equal__bool__nat___nat_(begin, a.size)),
	slice__arr__char__arr__char___nat___nat_(_ctx, a, begin, _op_minus__nat__nat___nat_(_ctx, a.size, begin)));
}
bool parse_named_args_recur___void__arr__arr__char___mut_dict__arr__char__arr__arr__char___lambda0_(ctx* _ctx, arr__char it) {
	return starts_with__q__bool__arr__char___arr__char_(_ctx, it, (arr__char) _constant____arr__char__16);
}
bool has__q__bool__ptr_dict__arr__char__arr__arr__char___arr__char_(ctx* _ctx, dict__arr__char__arr__arr__char* d, arr__char key) {
	return has__q__bool__opt__arr__arr__char_(get__opt__arr__arr__char__ptr_dict__arr__char__arr__arr__char___arr__char_(_ctx, d, key));
}
dict__arr__char__arr__arr__char* unsafe_as_dict__ptr_dict__arr__char__arr__arr__char__mut_dict__arr__char__arr__arr__char_(ctx* _ctx, mut_dict__arr__char__arr__arr__char m) {
	return _initdict__arr__char__arr__arr__char(alloc__ptr__byte__nat_(_ctx, 32), (dict__arr__char__arr__arr__char) {unsafe_as_arr__arr__arr__char__ptr_mut_arr__arr__char_(m.keys), unsafe_as_arr__arr__arr__arr__char__ptr_mut_arr__arr__arr__char_(m.values)});
}
_void increase_capacity_to___void__ptr_mut_arr__arr__char___nat_(ctx* _ctx, mut_arr__arr__char* a, nat new_capacity) {
	ptr__arr__char old_data;
	return (assert___void__bool_(_ctx, _op_greater__bool__nat___nat_(new_capacity, a->capacity)),
	((old_data = a->data),
	(((a->capacity = new_capacity), 0,
	(a->data = uninitialized_data__ptr__arr__char__nat_(_ctx, new_capacity)), 0),
	copy_data_from___void__ptr__arr__char___ptr__arr__char___nat_(_ctx, a->data, old_data, a->size))));
}
_void ensure_capacity___void__ptr_mut_arr__arr__char___nat_(ctx* _ctx, mut_arr__arr__char* a, nat capacity) {
	return _op_less__bool__nat___nat_(a->capacity, capacity)
		? increase_capacity_to___void__ptr_mut_arr__arr__char___nat_(_ctx, a, round_up_to_power_of_two__nat__nat_(_ctx, capacity))
		: 0;
}
nat round_up_to_power_of_two__nat__nat_(ctx* _ctx, nat n) {
	return round_up_to_power_of_two_recur__nat__nat___nat_(_ctx, 1ull, n);
}
_void increase_capacity_to___void__ptr_mut_arr__arr__arr__char___nat_(ctx* _ctx, mut_arr__arr__arr__char* a, nat new_capacity) {
	ptr__arr__arr__char old_data;
	return (assert___void__bool_(_ctx, _op_greater__bool__nat___nat_(new_capacity, a->capacity)),
	((old_data = a->data),
	(((a->capacity = new_capacity), 0,
	(a->data = uninitialized_data__ptr__arr__arr__char__nat_(_ctx, new_capacity)), 0),
	copy_data_from___void__ptr__arr__arr__char___ptr__arr__arr__char___nat_(_ctx, a->data, old_data, a->size))));
}
_void ensure_capacity___void__ptr_mut_arr__arr__arr__char___nat_(ctx* _ctx, mut_arr__arr__arr__char* a, nat capacity) {
	return _op_less__bool__nat___nat_(a->capacity, capacity)
		? increase_capacity_to___void__ptr_mut_arr__arr__arr__char___nat_(_ctx, a, round_up_to_power_of_two__nat__nat_(_ctx, capacity))
		: 0;
}
bool index_of__opt__nat__arr__arr__char___arr__char___lambda0_(ctx* _ctx, index_of__opt__nat__arr__arr__char___arr__char___lambda0___closure _closure, arr__char it) {
	return _op_equal_equal__bool__arr__char___arr__char_(it, _closure.value);
}
ptr__char uninitialized_data__ptr__char__nat_(ctx* _ctx, nat size) {
	ptr__byte bptr;
	return ((bptr = alloc__ptr__byte__nat_(_ctx, (size * 1ull))),
	(ptr__char) bptr);
}
_void set_at___void__ptr_mut_arr__char___nat___char_(ctx* _ctx, mut_arr__char* a, nat index, char value) {
	return (assert___void__bool_(_ctx, _op_less__bool__nat___nat_(index, a->size)),
	noctx_set_at___void__ptr_mut_arr__char___nat___char_(a, index, value));
}
char _op_plus__arr__char__arr__char___arr__char___lambda0_(ctx* _ctx, _op_plus__arr__char__arr__char___arr__char___lambda0___closure _closure, nat i) {
	return _op_less__bool__nat___nat_(i, _closure.a.size)
		? at__char__arr__char___nat_(_ctx, _closure.a, i)
		: at__char__arr__char___nat_(_ctx, _closure.b, _op_minus__nat__nat___nat_(_ctx, i, _closure.a.size));
}
bool has__q__bool__ptr_dict__arr__char__arr__char___arr__char_(ctx* _ctx, dict__arr__char__arr__char* d, arr__char key) {
	return has__q__bool__opt__arr__char_(get__opt__arr__char__ptr_dict__arr__char__arr__char___arr__char_(_ctx, d, key));
}
dict__arr__char__arr__char* unsafe_as_dict__ptr_dict__arr__char__arr__char__mut_dict__arr__char__arr__char_(ctx* _ctx, mut_dict__arr__char__arr__char m) {
	return _initdict__arr__char__arr__char(alloc__ptr__byte__nat_(_ctx, 32), (dict__arr__char__arr__char) {unsafe_as_arr__arr__arr__char__ptr_mut_arr__arr__char_(m.keys), unsafe_as_arr__arr__arr__char__ptr_mut_arr__arr__char_(m.values)});
}
ptr__char hard_fail__ptr__char__arr__char__id2_() {
	assert(0);
}
opt__ptr_stat_t get_stat__opt__ptr_stat_t__ptr__char_(ctx* _ctx, ptr__char path) {
	stat_t* s;
	int32 err;
	int32 errno;
	return ((s = empty_stat__ptr_stat_t(_ctx)),
	((err = stat(path, s)),
	_op_equal_equal__bool__int32___int32_(err, 0)
		? (opt__ptr_stat_t) { 1, .as_some__ptr_stat_t = some__some__ptr_stat_t__ptr_stat_t_(s) }
		: (assert___void__bool_(_ctx, _op_equal_equal__bool__int32___int32_(err, -1)),
		((errno = get_errno__int32(_ctx)),
		_op_equal_equal__bool__int32___int32_(errno, 2)
			? (opt__ptr_stat_t) _constant__opt__ptr_stat_t__0
			: todo__opt__ptr_stat_t()))));
}
bool todo__bool() {
	return hard_fail__bool__arr__char__id2_();
}
bool _op_equal_equal__bool__nat32___nat32_(nat32 a, nat32 b) {
	comparison matched;
	return (matched = _op_less_equal_greater__comparison__nat32___nat32_(a, b),
		matched.kind == 0
		? 0
		: matched.kind == 1
		? 1
		: matched.kind == 2
		? 0
		: _failbool());
}
bool always_true__bool__arr__char___asLambda_(ctx* _ctx, arr__char a) {
	return always_true__bool__arr__char_(_ctx, a);
}
_void read_dir_recur___void__ptr__byte___ptr_mut_arr__arr__char_(ctx* _ctx, ptr__byte dirp, mut_arr__arr__char* res) {
	dirent* entry;
	cell__ptr_dirent* result;
	int32 err;
	arr__char name;
	return ((entry = _initdirent(alloc__ptr__byte__nat_(_ctx, 280), (dirent) {0ull, 0ll, 0u, '\0', (bytes256) _constant____bytes256__0})),
	((result = new_cell__ptr_cell__ptr_dirent__ptr_dirent_(_ctx, entry)),
	((err = readdir_r(dirp, entry, result)),
	(assert___void__bool_(_ctx, zero__q__bool__int32_(err)),
	null__q__bool__ptr__byte_((ptr__byte) get__ptr_dirent__ptr_cell__ptr_dirent_(result))
		? 0
		: (assert___void__bool_(_ctx, ptr_eq__bool__ptr_dirent___ptr_dirent_(get__ptr_dirent__ptr_cell__ptr_dirent_(result), entry)),
		((name = get_dirent_name__arr__char__ptr_dirent_(entry)),
		((_op_equal_equal__bool__arr__char___arr__char_(name, (arr__char) _constant____arr__char__49) || _op_equal_equal__bool__arr__char___arr__char_(name, (arr__char) _constant____arr__char__50))
			? 0
			: push___void__ptr_mut_arr__arr__char___arr__char_(_ctx, res, get_dirent_name__arr__char__ptr_dirent_(entry)),
		read_dir_recur___void__ptr__byte___ptr_mut_arr__arr__char_(_ctx, dirp, res))))))));
}
arr__arr__char sort__arr__arr__char__arr__arr__char_(ctx* _ctx, arr__arr__char a) {
	mut_arr__arr__char* m;
	return ((m = to_mut_arr__ptr_mut_arr__arr__char__arr__arr__char_(_ctx, a)),
	(sort___void__ptr_mut_arr__arr__char_(_ctx, m),
	freeze__arr__arr__char__ptr_mut_arr__arr__char_(m)));
}
opt__nat last_index_of__opt__nat__arr__char___char_(ctx* _ctx, arr__char s, char c) {
	return empty__q__bool__arr__char_(s)
		? (opt__nat) _constant__opt__nat__0
		: _op_equal_equal__bool__char___char_(last__char__arr__char_(_ctx, s), c)
			? (opt__nat) { 1, .as_some__nat = some__some__nat__nat_(decr__nat__nat_(_ctx, s.size)) }
			: last_index_of__opt__nat__arr__char___char_(_ctx, rtail__arr__char__arr__char_(_ctx, s), c);
}
arr__char slice_after__arr__char__arr__char___nat_(ctx* _ctx, arr__char a, nat before_begin) {
	return slice_starting_at__arr__char__arr__char___nat_(_ctx, a, incr__nat__nat_(_ctx, before_begin));
}
_void each___void__arr__ptr_failure___push_all___void__ptr_mut_arr__ptr_failure___arr__ptr_failure___lambda0___closure__klbpush_all___void__ptr_mut_arr__ptr_failure___arr__ptr_failure___lambda0_(ctx* _ctx, arr__ptr_failure a, push_all___void__ptr_mut_arr__ptr_failure___arr__ptr_failure___lambda0___closure f) {
	return empty__q__bool__arr__ptr_failure_(a)
		? 0
		: (push_all___void__ptr_mut_arr__ptr_failure___arr__ptr_failure___lambda0_(_ctx, f, first__ptr_failure__arr__ptr_failure_(_ctx, a)),
		each___void__arr__ptr_failure___push_all___void__ptr_mut_arr__ptr_failure___arr__ptr_failure___lambda0___closure__klbpush_all___void__ptr_mut_arr__ptr_failure___arr__ptr_failure___lambda0_(_ctx, tail__arr__ptr_failure__arr__ptr_failure_(_ctx, a), f));
}
arr__ptr_failure run_single_compile_error_test__arr__ptr_failure__arr__char___ptr_dict__arr__char__arr__char___arr__char_(ctx* _ctx, arr__char path_to_noze, dict__arr__char__arr__char* env, arr__char path) {
	mut_arr__ptr_failure* failures;
	arr__arr__char arr;
	process_result* result;
	arr__char message;
	arr__char stderr_no_color;
	arr__char stderr_file;
	some__arr__char s;
	arr__char message1;
	opt__arr__char matched;
	return ((failures = new_mut_arr__ptr_mut_arr__ptr_failure(_ctx)),
	((result = spawn_and_wait_result__ptr_process_result__arr__char___arr__arr__char___ptr_dict__arr__char__arr__char_(_ctx, path_to_noze, (arr = (arr__arr__char) { 2, (arr__char*) alloc__ptr__byte__nat_(_ctx, 32) }, arr.data[0] = (arr__char) _constant____arr__char__54, arr.data[1] = path, arr), env)),
	((_op_equal_equal__bool__int32___int32_(result->exit_code, 1)
		? 0
		: ((message = _op_plus__arr__char__arr__char___arr__char_(_ctx, (arr__char) _constant____arr__char__66, to_str__arr__char__int32_(_ctx, result->exit_code))),
		push___void__ptr_mut_arr__ptr_failure___ptr_failure_(_ctx, failures, _initfailure(alloc__ptr__byte__nat_(_ctx, 32), (failure) {path, message}))),
	_op_equal_equal__bool__arr__char___arr__char_(result->stdout, (arr__char) _constant____arr__char__5)
		? 0
		: push___void__ptr_mut_arr__ptr_failure___ptr_failure_(_ctx, failures, _initfailure(alloc__ptr__byte__nat_(_ctx, 32), (failure) {path, _op_plus__arr__char__arr__char___arr__char_(_ctx, (arr__char) _constant____arr__char__67, result->stdout)}))),
	((stderr_no_color = remove_colors__arr__char__arr__char_(_ctx, result->stderr)),
	(_op_equal_equal__bool__arr__char___arr__char_(result->stderr, (arr__char) _constant____arr__char__5)
		? push___void__ptr_mut_arr__ptr_failure___ptr_failure_(_ctx, failures, _initfailure(alloc__ptr__byte__nat_(_ctx, 32), (failure) {path, (arr__char) _constant____arr__char__70}))
		: ((stderr_file = change_extension__arr__char__arr__char___arr__char_(_ctx, path, (arr__char) _constant____arr__char__52)),
		(matched = try_read_file__opt__arr__char__arr__char_(_ctx, stderr_file),
			matched.kind == 0
			? push___void__ptr_mut_arr__ptr_failure___ptr_failure_(_ctx, failures, _initfailure(alloc__ptr__byte__nat_(_ctx, 32), (failure) {path, _op_plus__arr__char__arr__char___arr__char_(_ctx, _op_plus__arr__char__arr__char___arr__char_(_ctx, base_name__arr__char__arr__char_(_ctx, stderr_file), (arr__char) _constant____arr__char__72), stderr_no_color)}))
			: matched.kind == 1
			? (s = matched.as_some__arr__char,
			_op_equal_equal__bool__arr__char___arr__char_(s.value, stderr_no_color)
				? 0
				: ((message1 = _op_plus__arr__char__arr__char___arr__char_(_ctx, (arr__char) _constant____arr__char__73, stderr_no_color)),
				push___void__ptr_mut_arr__ptr_failure___ptr_failure_(_ctx, failures, _initfailure(alloc__ptr__byte__nat_(_ctx, 32), (failure) {path, message1})))
			): _fail_void())),
	freeze__arr__ptr_failure__ptr_mut_arr__ptr_failure_(failures))))));
}
arr__arr__char list_runnable_tests__arr__arr__char__arr__char_(ctx* _ctx, arr__char path) {
	mut_arr__arr__char* res;
	return ((res = new_mut_arr__ptr_mut_arr__arr__char(_ctx)),
	(each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id9___list_runnable_tests__arr__arr__char__arr__char___lambda0___closure__klblist_runnable_tests__arr__arr__char__arr__char___lambda0_(_ctx, path, (list_runnable_tests__arr__arr__char__arr__char___lambda0___closure) {res}),
	freeze__arr__arr__char__ptr_mut_arr__arr__char_(res)));
}
arr__ptr_failure flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure__klbrun_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0_(ctx* _ctx, arr__arr__char a, nat max_size, run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure mapper) {
	mut_arr__ptr_failure* res;
	return ((res = new_mut_arr__ptr_mut_arr__ptr_failure(_ctx)),
	(each___void__arr__arr__char___flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure__klbrun_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___lambda0___closure__klbflat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure__klbrun_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___lambda0_(_ctx, a, (flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure__klbrun_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___lambda0___closure) {res, max_size, mapper}),
	freeze__arr__ptr_failure__ptr_mut_arr__ptr_failure_(res)));
}
arr__arr__char list_lintable_files__arr__arr__char__arr__char_(ctx* _ctx, arr__char path) {
	mut_arr__arr__char* res;
	return ((res = new_mut_arr__ptr_mut_arr__arr__char(_ctx)),
	(each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id11___list_lintable_files__arr__arr__char__arr__char___lambda1___closure__klblist_lintable_files__arr__arr__char__arr__char___lambda1_(_ctx, path, (list_lintable_files__arr__arr__char__arr__char___lambda1___closure) {res}),
	freeze__arr__arr__char__ptr_mut_arr__arr__char_(res)));
}
arr__ptr_failure flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___lint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___closure__klblint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0_(ctx* _ctx, arr__arr__char a, nat max_size, lint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___closure mapper) {
	mut_arr__ptr_failure* res;
	return ((res = new_mut_arr__ptr_mut_arr__ptr_failure(_ctx)),
	(each___void__arr__arr__char___flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___lint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___closure__klblint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___lambda0___closure__klbflat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___lint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___closure__klblint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___lambda0_(_ctx, a, (flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___lint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___closure__klblint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___lambda0___closure) {res, max_size, mapper}),
	freeze__arr__ptr_failure__ptr_mut_arr__ptr_failure_(res)));
}
_void then_void___void__ptr_fut__int32___forward_to___void__ptr_fut__int32___ptr_fut__int32___lambda0___closure__klbforward_to___void__ptr_fut__int32___ptr_fut__int32___lambda0_(ctx* _ctx, fut__int32* f, forward_to___void__ptr_fut__int32___ptr_fut__int32___lambda0___closure cb) {
	fut_state_callbacks__int32 cbs;
	fut_state_resolved__int32 r;
	exception e;
	fut_state__int32 matched;
	return ((acquire_lock___void__ptr_lock_((&(f->lk))),
	(matched = f->state,
		matched.kind == 0
		? (cbs = matched.as_fut_state_callbacks__int32,
		(f->state = (fut_state__int32) { 0, .as_fut_state_callbacks__int32 = (fut_state_callbacks__int32) {(opt__ptr_fut_callback_node__int32) { 1, .as_some__ptr_fut_callback_node__int32 = some__some__ptr_fut_callback_node__int32__ptr_fut_callback_node__int32_(_initfut_callback_node__int32(alloc__ptr__byte__nat_(_ctx, 32), (fut_callback_node__int32) {(fun_mut1___void__result__int32__exception) {
			(fun_ptr3___void__ptr_ctx__ptr__byte__result__int32__exception) forward_to___void__ptr_fut__int32___ptr_fut__int32___lambda0___dynamic, (ptr__byte) _initforward_to___void__ptr_fut__int32___ptr_fut__int32___lambda0___closure(alloc__ptr__byte__nat_(_ctx, 8), cb) }, cbs.head})) }} }), 0
			): matched.kind == 1
			? (r = matched.as_fut_state_resolved__int32,
			forward_to___void__ptr_fut__int32___ptr_fut__int32___lambda0_(_ctx, cb, (result__int32__exception) { 0, .as_ok__int32 = ok__ok__int32__int32_(r.value) })
			): matched.kind == 2
			? (e = matched.as_exception,
			forward_to___void__ptr_fut__int32___ptr_fut__int32___lambda0_(_ctx, cb, (result__int32__exception) { 1, .as_err__exception = err__err__exception__exception_(e) })
			): _fail_void())),
		release_lock___void__ptr_lock_((&(f->lk))));
}
_void call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic(ctx* _ctx, call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0___closure* _closure) {
	return catch___void__call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda0___closure__klbcall__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda0___call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda1___closure__klbcall__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda1_(_ctx, (call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda0___closure) {_closure->f, _closure->p0, _closure->res}, (call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda1___closure) {_closure->res});
}
_void resolve_or_reject___void__ptr_fut__int32___result__int32__exception_(ctx* _ctx, fut__int32* f, result__int32__exception result) {
	fut_state_callbacks__int32 cbs;
	fut_state__int32 matched;
	ok__int32 o;
	err__exception e;
	result__int32__exception matched1;
	return (((acquire_lock___void__ptr_lock_((&(f->lk))),
	(matched = f->state,
		matched.kind == 0
		? (cbs = matched.as_fut_state_callbacks__int32,
		resolve_or_reject_recur___void__opt__ptr_fut_callback_node__int32___result__int32__exception_(_ctx, cbs.head, result)
		): matched.kind == 1
		? hard_fail___void__arr__char__id10_()
		: matched.kind == 2
		? hard_fail___void__arr__char__id10_()
		: _fail_void())),
	(f->state = (matched1 = result,
		matched1.kind == 0
		? (o = matched1.as_ok__int32,
		(fut_state__int32) { 1, .as_fut_state_resolved__int32 = (fut_state_resolved__int32) {o.value} }
		): matched1.kind == 1
		? (e = matched1.as_err__exception,
		(fut_state__int32) { 2, .as_exception = e.value }
		): _failfut_state__int32())), 0),
	release_lock___void__ptr_lock_((&(f->lk))));
}
some__ptr_mut_bag_node__task some__some__ptr_mut_bag_node__task__ptr_mut_bag_node__task_(mut_bag_node__task* t) {
	return (some__ptr_mut_bag_node__task) {t};
}
_void catch_with_exception_ctx___void__ptr_exception_ctx___call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda0___closure__klbcall__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda0___call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda1___closure__klbcall__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda1_(ctx* _ctx, exception_ctx* ec, call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda0___closure try, call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda1___closure catcher) {
	exception old_thrown_exception;
	ptr__jmp_buf_tag old_jmp_buf;
	int32 setjmp_result;
	_void res;
	exception thrown_exception;
	return ((old_thrown_exception = ec->thrown_exception),
	((old_jmp_buf = ec->jmp_buf_ptr),
	((ec->jmp_buf_ptr = (&((jmp_buf_tag) _constant____jmp_buf_tag__0))), 0,
	((setjmp_result = setjmp(ec->jmp_buf_ptr)),
	_op_equal_equal__bool__int32___int32_(setjmp_result, 0)
		? ((res = call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda0(_ctx, try)),
		(((ec->jmp_buf_ptr = old_jmp_buf), 0,
		(ec->thrown_exception = old_thrown_exception), 0),
		res))
		: (assert___void__bool_(_ctx, _op_equal_equal__bool__int32___int32_(setjmp_result, 7)),
		((thrown_exception = ec->thrown_exception),
		(((ec->jmp_buf_ptr = old_jmp_buf), 0,
		(ec->thrown_exception = old_thrown_exception), 0),
		call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda1_(_ctx, catcher, thrown_exception))))))));
}
ptr__arr__char uninitialized_data__ptr__arr__char__nat_(ctx* _ctx, nat size) {
	ptr__byte bptr;
	return ((bptr = alloc__ptr__byte__nat_(_ctx, (size * 16ull))),
	(ptr__arr__char) bptr);
}
_void set_at___void__ptr_mut_arr__arr__char___nat___arr__char_(ctx* _ctx, mut_arr__arr__char* a, nat index, arr__char value) {
	return (assert___void__bool_(_ctx, _op_less__bool__nat___nat_(index, a->size)),
	noctx_set_at___void__ptr_mut_arr__arr__char___nat___arr__char_(a, index, value));
}
arr__char map__arr__arr__char__arr__ptr__char___fun_mut1__arr__char__ptr__char__id1___lambda0_(ctx* _ctx, map__arr__arr__char__arr__ptr__char___fun_mut1__arr__char__ptr__char__id1___lambda0___closure _closure, nat i) {
	return add_first_task__ptr_fut__int32__arr__ptr__char___fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char___lambda0__dynamic__lambda0_(_ctx, at__ptr__char__arr__ptr__char___nat_(_ctx, _closure.a, i));
}
bool contains__q__bool__ptr_mut_arr__nat___nat_(mut_arr__nat* a, nat value) {
	return contains_recur__q__bool__arr__nat___nat___nat_(temp_as_arr__arr__nat__ptr_mut_arr__nat_(a), value, 0ull);
}
_void push_capacity_must_be_sufficient___void__ptr_mut_arr__nat___nat_(mut_arr__nat* a, nat value) {
	nat old_size;
	return (hard_assert___void__bool_(_op_less__bool__nat___nat_(a->size, a->capacity)),
	((old_size = a->size),
	((a->size = noctx_incr__nat__nat_(old_size)), 0,
	noctx_set_at___void__ptr_mut_arr__nat___nat___nat_(a, old_size, value))));
}
some__task_and_nodes some__some__task_and_nodes__task_and_nodes_(task_and_nodes t) {
	return (some__task_and_nodes) {t};
}
bool empty__q__bool__ptr_mut_arr__nat_(mut_arr__nat* a) {
	return zero__q__bool__nat_(a->size);
}
char first__char__arr__char_(ctx* _ctx, arr__char a) {
	return (forbid___void__bool_(_ctx, empty__q__bool__arr__char_(a)),
	at__char__arr__char___nat_(_ctx, a, 0ull));
}
arr__char tail__arr__char__arr__char_(ctx* _ctx, arr__char a) {
	return (forbid___void__bool_(_ctx, empty__q__bool__arr__char_(a)),
	slice_starting_at__arr__char__arr__char___nat_(_ctx, a, 1ull));
}
arr__char throw__arr__char__exception__id1_(ctx* _ctx) {
	exception_ctx* exn_ctx;
	return ((exn_ctx = get_exception_ctx__ptr_exception_ctx(_ctx)),
	(((hard_forbid___void__bool_(_op_equal_equal__bool__ptr__jmp_buf_tag___ptr__jmp_buf_tag_(exn_ctx->jmp_buf_ptr, NULL)),
	(exn_ctx->thrown_exception = (exception) _constant____exception__1), 0),
	(longjmp(exn_ctx->jmp_buf_ptr, 7), 0)),
	todo__arr__char()));
}
opt__arr__arr__char get__opt__arr__arr__char__ptr_dict__arr__char__arr__arr__char___arr__char_(ctx* _ctx, dict__arr__char__arr__arr__char* d, arr__char key) {
	return get_recursive__opt__arr__arr__char__arr__arr__char___arr__arr__arr__char___nat___arr__char_(_ctx, d->keys, d->values, 0ull, key);
}
_void copy_data_from___void__ptr__arr__char___ptr__arr__char___nat_(ctx* _ctx, ptr__arr__char to, ptr__arr__char from, nat len) {
	return zero__q__bool__nat_(len)
		? 0
		: (((*(to) = *(from)), 0),
		copy_data_from___void__ptr__arr__char___ptr__arr__char___nat_(_ctx, incr__ptr__arr__char__ptr__arr__char_(to), incr__ptr__arr__char__ptr__arr__char_(from), decr__nat__nat_(_ctx, len)));
}
nat round_up_to_power_of_two_recur__nat__nat___nat_(ctx* _ctx, nat acc, nat n) {
	return _op_greater_equal__bool__nat___nat_(acc, n)
		? acc
		: round_up_to_power_of_two_recur__nat__nat___nat_(_ctx, _op_times__nat__nat___nat_(_ctx, acc, 2ull), n);
}
ptr__arr__arr__char uninitialized_data__ptr__arr__arr__char__nat_(ctx* _ctx, nat size) {
	ptr__byte bptr;
	return ((bptr = alloc__ptr__byte__nat_(_ctx, (size * 16ull))),
	(ptr__arr__arr__char) bptr);
}
_void copy_data_from___void__ptr__arr__arr__char___ptr__arr__arr__char___nat_(ctx* _ctx, ptr__arr__arr__char to, ptr__arr__arr__char from, nat len) {
	return zero__q__bool__nat_(len)
		? 0
		: (((*(to) = *(from)), 0),
		copy_data_from___void__ptr__arr__arr__char___ptr__arr__arr__char___nat_(_ctx, incr__ptr__arr__arr__char__ptr__arr__arr__char_(to), incr__ptr__arr__arr__char__ptr__arr__arr__char_(from), decr__nat__nat_(_ctx, len)));
}
_void noctx_set_at___void__ptr_mut_arr__char___nat___char_(mut_arr__char* a, nat index, char value) {
	return (hard_assert___void__bool_(_op_less__bool__nat___nat_(index, a->size)),
	((*((a->data + index)) = value), 0));
}
bool has__q__bool__opt__arr__char_(opt__arr__char a) {
	return !(empty__q__bool__opt__arr__char_(a));
}
opt__arr__char get__opt__arr__char__ptr_dict__arr__char__arr__char___arr__char_(ctx* _ctx, dict__arr__char__arr__char* d, arr__char key) {
	return get_recursive__opt__arr__char__arr__arr__char___arr__arr__char___nat___arr__char_(_ctx, d->keys, d->values, 0ull, key);
}
stat_t* empty_stat__ptr_stat_t(ctx* _ctx) {
	return _initstat_t(alloc__ptr__byte__nat_(_ctx, 152), (stat_t) {0ull, 0u, 0ull, 0u, 0u, 0ull, 0ull, 0ull, 0u, 0ll, 0ull, 0ull, 0ull, 0ull, 0ull, 0ull, 0ull, 0ull, 0ull, 0ull});
}
some__ptr_stat_t some__some__ptr_stat_t__ptr_stat_t_(stat_t* t) {
	return (some__ptr_stat_t) {t};
}
opt__ptr_stat_t todo__opt__ptr_stat_t() {
	return hard_fail__opt__ptr_stat_t__arr__char__id2_();
}
bool hard_fail__bool__arr__char__id2_() {
	assert(0);
}
comparison _op_less_equal_greater__comparison__nat32___nat32_(nat32 a, nat32 b) {
	return (a < b)
		? (comparison) { 0, .as_less = (less) { 0 } }
		: (b < a)
			? (comparison) { 2, .as_greater = (greater) { 0 } }
			: (comparison) { 1, .as_equal = (equal) { 0 } };
}
bool always_true__bool__arr__char_(ctx* _ctx, arr__char a) {
	return 1;
}
cell__ptr_dirent* new_cell__ptr_cell__ptr_dirent__ptr_dirent_(ctx* _ctx, dirent* value) {
	return _initcell__ptr_dirent(alloc__ptr__byte__nat_(_ctx, 8), (cell__ptr_dirent) {value});
}
dirent* get__ptr_dirent__ptr_cell__ptr_dirent_(cell__ptr_dirent* c) {
	return c->value;
}
bool ptr_eq__bool__ptr_dirent___ptr_dirent_(dirent* a, dirent* b) {
	return _op_equal_equal__bool__ptr__byte___ptr__byte_((ptr__byte) a, (ptr__byte) b);
}
arr__char get_dirent_name__arr__char__ptr_dirent_(dirent* d) {
	ptr__byte name_ptr;
	return ((name_ptr = ((ptr__byte) d + 19ull)),
	to_str__arr__char__ptr__char_((ptr__char) name_ptr));
}
mut_arr__arr__char* to_mut_arr__ptr_mut_arr__arr__char__arr__arr__char_(ctx* _ctx, arr__arr__char a) {
	return make_mut_arr__ptr_mut_arr__arr__char__nat___to_mut_arr__ptr_mut_arr__arr__char__arr__arr__char___lambda0___closure__klbto_mut_arr__ptr_mut_arr__arr__char__arr__arr__char___lambda0_(_ctx, a.size, (to_mut_arr__ptr_mut_arr__arr__char__arr__arr__char___lambda0___closure) {a});
}
_void sort___void__ptr_mut_arr__arr__char_(ctx* _ctx, mut_arr__arr__char* a) {
	return sort___void__ptr_mut_slice__arr__char_(_ctx, to_mut_slice__ptr_mut_slice__arr__char__ptr_mut_arr__arr__char_(_ctx, a));
}
_void push_all___void__ptr_mut_arr__ptr_failure___arr__ptr_failure___lambda0_(ctx* _ctx, push_all___void__ptr_mut_arr__ptr_failure___arr__ptr_failure___lambda0___closure _closure, failure* it) {
	return push___void__ptr_mut_arr__ptr_failure___ptr_failure_(_ctx, _closure.a, it);
}
process_result* spawn_and_wait_result__ptr_process_result__arr__char___arr__arr__char___ptr_dict__arr__char__arr__char_(ctx* _ctx, arr__char exe, arr__arr__char args, dict__arr__char__arr__char* environ) {
	ptr__char exe_c_str;
	return is_file__q__bool__arr__char_(_ctx, exe)
		? ((exe_c_str = to_c_str__ptr__char__arr__char_(_ctx, exe)),
		spawn_and_wait_result__ptr_process_result__ptr__char___ptr__ptr__char___ptr__ptr__char_(_ctx, exe_c_str, convert_args__ptr__ptr__char__ptr__char___arr__arr__char_(_ctx, exe_c_str, args), convert_environ__ptr__ptr__char__ptr_dict__arr__char__arr__char_(_ctx, environ)))
		: fail__ptr_process_result__arr__char_(_ctx, _op_plus__arr__char__arr__char___arr__char_(_ctx, exe, (arr__char) _constant____arr__char__65));
}
arr__char to_str__arr__char__int32_(ctx* _ctx, int32 i) {
	return to_str__arr__char___int_(_ctx, (_int) i);
}
_void push___void__ptr_mut_arr__ptr_failure___ptr_failure_(ctx* _ctx, mut_arr__ptr_failure* a, failure* value) {
	return ((((_op_equal_equal__bool__nat___nat_(a->size, a->capacity)
		? increase_capacity_to___void__ptr_mut_arr__ptr_failure___nat_(_ctx, a, (zero__q__bool__nat_(a->size) ? 4ull : _op_times__nat__nat___nat_(_ctx, a->size, 2ull)))
		: 0,
	ensure_capacity___void__ptr_mut_arr__ptr_failure___nat_(_ctx, a, round_up_to_power_of_two__nat__nat_(_ctx, incr__nat__nat_(_ctx, a->size)))),
	assert___void__bool_(_ctx, _op_less__bool__nat___nat_(a->size, a->capacity))),
	((*((a->data + a->size)) = value), 0)),
	(a->size = incr__nat__nat_(_ctx, a->size)), 0);
}
arr__char remove_colors__arr__char__arr__char_(ctx* _ctx, arr__char s) {
	mut_arr__char* out;
	return ((out = new_mut_arr__ptr_mut_arr__char(_ctx)),
	(remove_colors_recur___void__arr__char___ptr_mut_arr__char_(_ctx, s, out),
	freeze__arr__char__ptr_mut_arr__char_(out)));
}
arr__char change_extension__arr__char__arr__char___arr__char_(ctx* _ctx, arr__char name, arr__char ext) {
	return add_extension__arr__char__arr__char___arr__char_(_ctx, remove_extension__arr__char__arr__char_(_ctx, name), ext);
}
opt__arr__char try_read_file__opt__arr__char__arr__char_(ctx* _ctx, arr__char path) {
	return try_read_file__opt__arr__char__ptr__char_(_ctx, to_c_str__ptr__char__arr__char_(_ctx, path));
}
_void each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id9___list_runnable_tests__arr__arr__char__arr__char___lambda0___closure__klblist_runnable_tests__arr__arr__char__arr__char___lambda0_(ctx* _ctx, arr__char path, list_runnable_tests__arr__arr__char__arr__char___lambda0___closure f) {
	return is_dir__q__bool__arr__char_(_ctx, path)
		? each___void__arr__arr__char___each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id9___list_runnable_tests__arr__arr__char__arr__char___lambda0___closure__klblist_runnable_tests__arr__arr__char__arr__char___lambda0___lambda0___closure__klbeach_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id9___list_runnable_tests__arr__arr__char__arr__char___lambda0___closure__klblist_runnable_tests__arr__arr__char__arr__char___lambda0___lambda0_(_ctx, read_dir__arr__arr__char__arr__char_(_ctx, path), (each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id9___list_runnable_tests__arr__arr__char__arr__char___lambda0___closure__klblist_runnable_tests__arr__arr__char__arr__char___lambda0___lambda0___closure) {path, f})
		: list_runnable_tests__arr__arr__char__arr__char___lambda0_(_ctx, f, path);
}
_void each___void__arr__arr__char___flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure__klbrun_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___lambda0___closure__klbflat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure__klbrun_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___lambda0_(ctx* _ctx, arr__arr__char a, flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure__klbrun_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___lambda0___closure f) {
	return empty__q__bool__arr__arr__char_(a)
		? 0
		: (flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure__klbrun_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___lambda0_(_ctx, f, first__arr__char__arr__arr__char_(_ctx, a)),
		each___void__arr__arr__char___flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure__klbrun_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___lambda0___closure__klbflat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure__klbrun_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___lambda0_(_ctx, tail__arr__arr__char__arr__arr__char_(_ctx, a), f));
}
_void each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id11___list_lintable_files__arr__arr__char__arr__char___lambda1___closure__klblist_lintable_files__arr__arr__char__arr__char___lambda1_(ctx* _ctx, arr__char path, list_lintable_files__arr__arr__char__arr__char___lambda1___closure f) {
	return is_dir__q__bool__arr__char_(_ctx, path)
		? each___void__arr__arr__char___each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id11___list_lintable_files__arr__arr__char__arr__char___lambda1___closure__klblist_lintable_files__arr__arr__char__arr__char___lambda1___lambda0___closure__klbeach_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id11___list_lintable_files__arr__arr__char__arr__char___lambda1___closure__klblist_lintable_files__arr__arr__char__arr__char___lambda1___lambda0_(_ctx, read_dir__arr__arr__char__arr__char_(_ctx, path), (each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id11___list_lintable_files__arr__arr__char__arr__char___lambda1___closure__klblist_lintable_files__arr__arr__char__arr__char___lambda1___lambda0___closure) {path, f})
		: list_lintable_files__arr__arr__char__arr__char___lambda1_(_ctx, f, path);
}
_void each___void__arr__arr__char___flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___lint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___closure__klblint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___lambda0___closure__klbflat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___lint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___closure__klblint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___lambda0_(ctx* _ctx, arr__arr__char a, flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___lint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___closure__klblint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___lambda0___closure f) {
	return empty__q__bool__arr__arr__char_(a)
		? 0
		: (flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___lint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___closure__klblint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___lambda0_(_ctx, f, first__arr__char__arr__arr__char_(_ctx, a)),
		each___void__arr__arr__char___flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___lint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___closure__klblint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___lambda0___closure__klbflat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___lint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___closure__klblint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___lambda0_(_ctx, tail__arr__arr__char__arr__arr__char_(_ctx, a), f));
}
some__ptr_fut_callback_node__int32 some__some__ptr_fut_callback_node__int32__ptr_fut_callback_node__int32_(fut_callback_node__int32* t) {
	return (some__ptr_fut_callback_node__int32) {t};
}
_void forward_to___void__ptr_fut__int32___ptr_fut__int32___lambda0___dynamic(ctx* _ctx, forward_to___void__ptr_fut__int32___ptr_fut__int32___lambda0___closure* _closure, result__int32__exception it) {
	return resolve_or_reject___void__ptr_fut__int32___result__int32__exception_(_ctx, _closure->to, it);
}
_void forward_to___void__ptr_fut__int32___ptr_fut__int32___lambda0_(ctx* _ctx, forward_to___void__ptr_fut__int32___ptr_fut__int32___lambda0___closure _closure, result__int32__exception it) {
	return resolve_or_reject___void__ptr_fut__int32___result__int32__exception_(_ctx, _closure.to, it);
}
_void catch___void__call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda0___closure__klbcall__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda0___call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda1___closure__klbcall__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda1_(ctx* _ctx, call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda0___closure try, call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda1___closure catcher) {
	return catch_with_exception_ctx___void__ptr_exception_ctx___call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda0___closure__klbcall__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda0___call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda1___closure__klbcall__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda1_(_ctx, get_exception_ctx__ptr_exception_ctx(_ctx), try, catcher);
}
_void resolve_or_reject_recur___void__opt__ptr_fut_callback_node__int32___result__int32__exception_(ctx* _ctx, opt__ptr_fut_callback_node__int32 node, result__int32__exception value) {
	some__ptr_fut_callback_node__int32 s;
	opt__ptr_fut_callback_node__int32 matched;
	return (matched = node,
		matched.kind == 0
		? 0
		: matched.kind == 1
		? (s = matched.as_some__ptr_fut_callback_node__int32,
		(drop___void___void_(call___void__fun_mut1___void__result__int32__exception___result__int32__exception_(_ctx, s.value->cb, value)),
		resolve_or_reject_recur___void__opt__ptr_fut_callback_node__int32___result__int32__exception_(_ctx, s.value->next_node, value))
		): _fail_void());
}
_void hard_fail___void__arr__char__id10_() {
	assert(0);
}
_void call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda0(ctx* _ctx, call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda0___closure _closure) {
	return forward_to___void__ptr_fut__int32___ptr_fut__int32_(_ctx, call__ptr_fut__int32__fun_mut0__ptr_fut__int32_(_ctx, _closure.f.fun), _closure.res);
}
_void call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda1_(ctx* _ctx, call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda1___closure _closure, exception it) {
	return reject___void__ptr_fut__int32___exception_(_ctx, _closure.res, it);
}
_void noctx_set_at___void__ptr_mut_arr__arr__char___nat___arr__char_(mut_arr__arr__char* a, nat index, arr__char value) {
	return (hard_assert___void__bool_(_op_less__bool__nat___nat_(index, a->size)),
	((*((a->data + index)) = value), 0));
}
arr__char add_first_task__ptr_fut__int32__arr__ptr__char___fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char___lambda0__dynamic__lambda0_(ctx* _ctx, ptr__char it) {
	return to_str__arr__char__ptr__char_(it);
}
ptr__char at__ptr__char__arr__ptr__char___nat_(ctx* _ctx, arr__ptr__char a, nat index) {
	return (assert___void__bool_(_ctx, _op_less__bool__nat___nat_(index, a.size)),
	noctx_at__ptr__char__arr__ptr__char___nat_(a, index));
}
bool contains_recur__q__bool__arr__nat___nat___nat_(arr__nat a, nat value, nat i) {
	return _op_equal_equal__bool__nat___nat_(i, a.size)
		? 0
		: (_op_equal_equal__bool__nat___nat_(noctx_at__nat__arr__nat___nat_(a, i), value) || contains_recur__q__bool__arr__nat___nat___nat_(a, value, noctx_incr__nat__nat_(i)));
}
arr__nat temp_as_arr__arr__nat__ptr_mut_arr__nat_(mut_arr__nat* a) {
	return (arr__nat) {a->size, a->data};
}
arr__char todo__arr__char() {
	return hard_fail__arr__char__arr__char__id2_();
}
opt__arr__arr__char get_recursive__opt__arr__arr__char__arr__arr__char___arr__arr__arr__char___nat___arr__char_(ctx* _ctx, arr__arr__char keys, arr__arr__arr__char values, nat idx, arr__char key) {
	return _op_equal_equal__bool__nat___nat_(idx, keys.size)
		? (opt__arr__arr__char) _constant__opt__arr__arr__char__0
		: _op_equal_equal__bool__arr__char___arr__char_(key, at__arr__char__arr__arr__char___nat_(_ctx, keys, idx))
			? (opt__arr__arr__char) { 1, .as_some__arr__arr__char = some__some__arr__arr__char__arr__arr__char_(at__arr__arr__char__arr__arr__arr__char___nat_(_ctx, values, idx)) }
			: get_recursive__opt__arr__arr__char__arr__arr__char___arr__arr__arr__char___nat___arr__char_(_ctx, keys, values, incr__nat__nat_(_ctx, idx), key);
}
ptr__arr__char incr__ptr__arr__char__ptr__arr__char_(ptr__arr__char p) {
	return (p + 1ull);
}
ptr__arr__arr__char incr__ptr__arr__arr__char__ptr__arr__arr__char_(ptr__arr__arr__char p) {
	return (p + 1ull);
}
bool empty__q__bool__opt__arr__char_(opt__arr__char a) {
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
opt__arr__char get_recursive__opt__arr__char__arr__arr__char___arr__arr__char___nat___arr__char_(ctx* _ctx, arr__arr__char keys, arr__arr__char values, nat idx, arr__char key) {
	return _op_equal_equal__bool__nat___nat_(idx, keys.size)
		? (opt__arr__char) _constant__opt__arr__char__0
		: _op_equal_equal__bool__arr__char___arr__char_(key, at__arr__char__arr__arr__char___nat_(_ctx, keys, idx))
			? (opt__arr__char) { 1, .as_some__arr__char = some__some__arr__char__arr__char_(at__arr__char__arr__arr__char___nat_(_ctx, values, idx)) }
			: get_recursive__opt__arr__char__arr__arr__char___arr__arr__char___nat___arr__char_(_ctx, keys, values, incr__nat__nat_(_ctx, idx), key);
}
opt__ptr_stat_t hard_fail__opt__ptr_stat_t__arr__char__id2_() {
	assert(0);
}
arr__char to_str__arr__char__ptr__char_(ptr__char a) {
	return arr_from_begin_end__arr__char__ptr__char___ptr__char_(a, find_cstr_end__ptr__char__ptr__char_(a));
}
mut_arr__arr__char* make_mut_arr__ptr_mut_arr__arr__char__nat___to_mut_arr__ptr_mut_arr__arr__char__arr__arr__char___lambda0___closure__klbto_mut_arr__ptr_mut_arr__arr__char__arr__arr__char___lambda0_(ctx* _ctx, nat size, to_mut_arr__ptr_mut_arr__arr__char__arr__arr__char___lambda0___closure f) {
	mut_arr__arr__char* res;
	return ((res = new_uninitialized_mut_arr__ptr_mut_arr__arr__char__nat_(_ctx, size)),
	(make_mut_arr_worker___void__ptr_mut_arr__arr__char___nat___to_mut_arr__ptr_mut_arr__arr__char__arr__arr__char___lambda0___closure__klbto_mut_arr__ptr_mut_arr__arr__char__arr__arr__char___lambda0_(_ctx, res, 0ull, f),
	res));
}
_void sort___void__ptr_mut_slice__arr__char_(ctx* _ctx, mut_slice__arr__char* a) {
	arr__char pivot;
	nat index_of_first_value_gt_pivot;
	nat new_pivot_index;
	return _op_less_equal__bool__nat___nat_(a->size, 1ull)
		? 0
		: (swap___void__ptr_mut_slice__arr__char___nat___nat_(_ctx, a, 0ull, _op_div__nat__nat___nat_(_ctx, a->size, 2ull)),
		((pivot = at__arr__char__ptr_mut_slice__arr__char___nat_(_ctx, a, 0ull)),
		((index_of_first_value_gt_pivot = partition_recur__nat__ptr_mut_slice__arr__char___arr__char___nat___nat_(_ctx, a, pivot, 1ull, decr__nat__nat_(_ctx, a->size))),
		((new_pivot_index = decr__nat__nat_(_ctx, index_of_first_value_gt_pivot)),
		((swap___void__ptr_mut_slice__arr__char___nat___nat_(_ctx, a, 0ull, new_pivot_index),
		sort___void__ptr_mut_slice__arr__char_(_ctx, slice__ptr_mut_slice__arr__char__ptr_mut_slice__arr__char___nat___nat_(_ctx, a, 0ull, new_pivot_index))),
		sort___void__ptr_mut_slice__arr__char_(_ctx, slice__ptr_mut_slice__arr__char__ptr_mut_slice__arr__char___nat_(_ctx, a, incr__nat__nat_(_ctx, new_pivot_index))))))));
}
mut_slice__arr__char* to_mut_slice__ptr_mut_slice__arr__char__ptr_mut_arr__arr__char_(ctx* _ctx, mut_arr__arr__char* a) {
	return (forbid___void__bool_(_ctx, a->frozen__q),
	_initmut_slice__arr__char(alloc__ptr__byte__nat_(_ctx, 24), (mut_slice__arr__char) {a, a->size, 0ull}));
}
bool is_file__q__bool__arr__char_(ctx* _ctx, arr__char path) {
	return is_file__q__bool__ptr__char_(_ctx, to_c_str__ptr__char__arr__char_(_ctx, path));
}
process_result* spawn_and_wait_result__ptr_process_result__ptr__char___ptr__ptr__char___ptr__ptr__char_(ctx* _ctx, ptr__char exe, ptr__ptr__char args, ptr__ptr__char environ) {
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
	((actions = _initposix_spawn_file_actions_t(alloc__ptr__byte__nat_(_ctx, 80), (posix_spawn_file_actions_t) {0, 0, NULL, (bytes64) _constant____bytes64__0})),
	(((((((check_posix_error___void__int32_(_ctx, posix_spawn_file_actions_init(actions)),
	check_posix_error___void__int32_(_ctx, posix_spawn_file_actions_addclose(actions, stdout_pipes->write_pipe))),
	check_posix_error___void__int32_(_ctx, posix_spawn_file_actions_addclose(actions, stderr_pipes->write_pipe))),
	check_posix_error___void__int32_(_ctx, posix_spawn_file_actions_adddup2(actions, stdout_pipes->read_pipe, 1))),
	check_posix_error___void__int32_(_ctx, posix_spawn_file_actions_adddup2(actions, stderr_pipes->read_pipe, 2))),
	check_posix_error___void__int32_(_ctx, posix_spawn_file_actions_addclose(actions, stdout_pipes->read_pipe))),
	check_posix_error___void__int32_(_ctx, posix_spawn_file_actions_addclose(actions, stderr_pipes->read_pipe))),
	((pid_cell = new_cell__ptr_cell__int32__int32__id0_(_ctx)),
	(check_posix_error___void__int32_(_ctx, posix_spawn(pid_cell, exe, actions, NULL, args, environ)),
	((pid = get__int32__ptr_cell__int32_(pid_cell)),
	((check_posix_error___void__int32_(_ctx, close(stdout_pipes->read_pipe)),
	check_posix_error___void__int32_(_ctx, close(stderr_pipes->read_pipe))),
	((stdout_builder = new_mut_arr__ptr_mut_arr__char(_ctx)),
	((stderr_builder = new_mut_arr__ptr_mut_arr__char(_ctx)),
	(keep_polling___void__int32___int32___ptr_mut_arr__char___ptr_mut_arr__char_(_ctx, stdout_pipes->write_pipe, stderr_pipes->write_pipe, stdout_builder, stderr_builder),
	((exit_code = wait_and_get_exit_code__int32__int32_(_ctx, pid)),
	_initprocess_result(alloc__ptr__byte__nat_(_ctx, 40), (process_result) {exit_code, freeze__arr__char__ptr_mut_arr__char_(stdout_builder), freeze__arr__char__ptr_mut_arr__char_(stderr_builder)})))))))))))));
}
ptr__ptr__char convert_args__ptr__ptr__char__ptr__char___arr__arr__char_(ctx* _ctx, ptr__char exe_c_str, arr__arr__char args) {
	return cons__arr__ptr__char__ptr__char___arr__ptr__char_(_ctx, exe_c_str, rcons__arr__ptr__char__arr__ptr__char___ptr__char_(_ctx, map__arr__ptr__char__arr__arr__char___fun_mut1__ptr__char__arr__char__id10_(_ctx, args), NULL)).data;
}
ptr__ptr__char convert_environ__ptr__ptr__char__ptr_dict__arr__char__arr__char_(ctx* _ctx, dict__arr__char__arr__char* environ) {
	mut_arr__ptr__char* res;
	return ((res = new_mut_arr__ptr_mut_arr__ptr__char(_ctx)),
	((each___void__ptr_dict__arr__char__arr__char___convert_environ__ptr__ptr__char__ptr_dict__arr__char__arr__char___lambda0___closure__klbconvert_environ__ptr__ptr__char__ptr_dict__arr__char__arr__char___lambda0_(_ctx, environ, (convert_environ__ptr__ptr__char__ptr_dict__arr__char__arr__char___lambda0___closure) {res}),
	push___void__ptr_mut_arr__ptr__char___ptr__char_(_ctx, res, NULL)),
	freeze__arr__ptr__char__ptr_mut_arr__ptr__char_(res).data));
}
process_result* fail__ptr_process_result__arr__char_(ctx* _ctx, arr__char reason) {
	return throw__ptr_process_result__exception_(_ctx, (exception) {reason});
}
arr__char to_str__arr__char___int_(ctx* _ctx, _int i) {
	arr__char a;
	return ((a = to_str__arr__char__nat_(_ctx, abs__nat___int_(_ctx, i))),
	(negative__q__bool___int_(_ctx, i) ? _op_plus__arr__char__arr__char___arr__char_(_ctx, (arr__char) _constant____arr__char__41, a) : a));
}
_void increase_capacity_to___void__ptr_mut_arr__ptr_failure___nat_(ctx* _ctx, mut_arr__ptr_failure* a, nat new_capacity) {
	ptr__ptr_failure old_data;
	return (assert___void__bool_(_ctx, _op_greater__bool__nat___nat_(new_capacity, a->capacity)),
	((old_data = a->data),
	(((a->capacity = new_capacity), 0,
	(a->data = uninitialized_data__ptr__ptr_failure__nat_(_ctx, new_capacity)), 0),
	copy_data_from___void__ptr__ptr_failure___ptr__ptr_failure___nat_(_ctx, a->data, old_data, a->size))));
}
_void ensure_capacity___void__ptr_mut_arr__ptr_failure___nat_(ctx* _ctx, mut_arr__ptr_failure* a, nat capacity) {
	return _op_less__bool__nat___nat_(a->capacity, capacity)
		? increase_capacity_to___void__ptr_mut_arr__ptr_failure___nat_(_ctx, a, round_up_to_power_of_two__nat__nat_(_ctx, capacity))
		: 0;
}
mut_arr__char* new_mut_arr__ptr_mut_arr__char(ctx* _ctx) {
	return _initmut_arr__char(alloc__ptr__byte__nat_(_ctx, 32), (mut_arr__char) {0, 0ull, 0ull, NULL});
}
_void remove_colors_recur___void__arr__char___ptr_mut_arr__char_(ctx* _ctx, arr__char s, mut_arr__char* out) {
	return empty__q__bool__arr__char_(s)
		? 0
		: _op_equal_equal__bool__char___char_(first__char__arr__char_(_ctx, s), '\x1b')
			? remove_colors_recur_2___void__arr__char___ptr_mut_arr__char_(_ctx, tail__arr__char__arr__char_(_ctx, s), out)
			: (push___void__ptr_mut_arr__char___char_(_ctx, out, first__char__arr__char_(_ctx, s)),
			remove_colors_recur___void__arr__char___ptr_mut_arr__char_(_ctx, tail__arr__char__arr__char_(_ctx, s), out));
}
arr__char add_extension__arr__char__arr__char___arr__char_(ctx* _ctx, arr__char name, arr__char ext) {
	return _op_plus__arr__char__arr__char___arr__char_(_ctx, _op_plus__arr__char__arr__char___arr__char_(_ctx, name, (arr__char) _constant____arr__char__49), ext);
}
arr__char remove_extension__arr__char__arr__char_(ctx* _ctx, arr__char name) {
	some__nat s;
	opt__nat matched;
	return (matched = last_index_of__opt__nat__arr__char___char_(_ctx, name, '.'),
		matched.kind == 0
		? name
		: matched.kind == 1
		? (s = matched.as_some__nat,
		slice_up_to__arr__char__arr__char___nat_(_ctx, name, s.value)
		): _failarr__char());
}
opt__arr__char try_read_file__opt__arr__char__ptr__char_(ctx* _ctx, ptr__char path) {
	int32 fd;
	int32 errno;
	_int file_size;
	_int off;
	nat file_size_nat;
	mut_arr__char* res;
	_int n_bytes_read;
	return ((fd = open(path, 0)),
	_op_equal_equal__bool__int32___int32_(fd, -1)
		? ((errno = get_errno__int32(_ctx)),
		_op_equal_equal__bool__int32___int32_(errno, 2)
			? (opt__arr__char) _constant__opt__arr__char__0
			: (print_sync___void__arr__char_(_op_plus__arr__char__arr__char___arr__char_(_ctx, (arr__char) _constant____arr__char__71, to_str__arr__char__ptr__char_(path))),
			todo__opt__arr__char()))
		: ((file_size = lseek(fd, 0ll, 2)),
		(((forbid___void__bool_(_ctx, _op_equal_equal__bool___int____int_(file_size, -1ll)),
		assert___void__bool_(_ctx, _op_less__bool___int____int_(file_size, 1000000000ll))),
		forbid___void__bool_(_ctx, zero__q__bool___int_(file_size))),
		((off = lseek(fd, 0ll, 0)),
		(assert___void__bool_(_ctx, _op_equal_equal__bool___int____int_(off, 0ll)),
		((file_size_nat = to_nat__nat___int_(_ctx, file_size)),
		((res = new_uninitialized_mut_arr__ptr_mut_arr__char__nat_(_ctx, file_size_nat)),
		((n_bytes_read = read(fd, (ptr__byte) res->data, file_size_nat)),
		(((forbid___void__bool_(_ctx, _op_equal_equal__bool___int____int_(n_bytes_read, -1ll)),
		assert___void__bool_(_ctx, _op_equal_equal__bool___int____int_(n_bytes_read, file_size))),
		check_posix_error___void__int32_(_ctx, close(fd))),
		(opt__arr__char) { 1, .as_some__arr__char = some__some__arr__char__arr__char_(freeze__arr__char__ptr_mut_arr__char_(res)) })))))))));
}
_void each___void__arr__arr__char___each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id9___list_runnable_tests__arr__arr__char__arr__char___lambda0___closure__klblist_runnable_tests__arr__arr__char__arr__char___lambda0___lambda0___closure__klbeach_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id9___list_runnable_tests__arr__arr__char__arr__char___lambda0___closure__klblist_runnable_tests__arr__arr__char__arr__char___lambda0___lambda0_(ctx* _ctx, arr__arr__char a, each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id9___list_runnable_tests__arr__arr__char__arr__char___lambda0___closure__klblist_runnable_tests__arr__arr__char__arr__char___lambda0___lambda0___closure f) {
	return empty__q__bool__arr__arr__char_(a)
		? 0
		: (each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id9___list_runnable_tests__arr__arr__char__arr__char___lambda0___closure__klblist_runnable_tests__arr__arr__char__arr__char___lambda0___lambda0_(_ctx, f, first__arr__char__arr__arr__char_(_ctx, a)),
		each___void__arr__arr__char___each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id9___list_runnable_tests__arr__arr__char__arr__char___lambda0___closure__klblist_runnable_tests__arr__arr__char__arr__char___lambda0___lambda0___closure__klbeach_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id9___list_runnable_tests__arr__arr__char__arr__char___lambda0___closure__klblist_runnable_tests__arr__arr__char__arr__char___lambda0___lambda0_(_ctx, tail__arr__arr__char__arr__arr__char_(_ctx, a), f));
}
_void list_runnable_tests__arr__arr__char__arr__char___lambda0_(ctx* _ctx, list_runnable_tests__arr__arr__char__arr__char___lambda0___closure _closure, arr__char child) {
	some__arr__char s;
	opt__arr__char matched;
	return (matched = get_extension__opt__arr__char__arr__char_(_ctx, base_name__arr__char__arr__char_(_ctx, child)),
		matched.kind == 0
		? 0
		: matched.kind == 1
		? (s = matched.as_some__arr__char,
		_op_equal_equal__bool__arr__char___arr__char_(s.value, (arr__char) _constant____arr__char__51)
			? push___void__ptr_mut_arr__arr__char___arr__char_(_ctx, _closure.res, child)
			: _op_equal_equal__bool__arr__char___arr__char_(s.value, (arr__char) _constant____arr__char__77)
				? 0
				: todo___void()
		): _fail_void());
}
_void flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure__klbrun_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___lambda0_(ctx* _ctx, flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure__klbrun_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___lambda0___closure _closure, arr__char x) {
	return _op_less__bool__nat___nat_(_closure.res->size, _closure.max_size)
		? (push_all___void__ptr_mut_arr__ptr_failure___arr__ptr_failure_(_ctx, _closure.res, run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0_(_ctx, _closure.mapper, x)),
		reduce_size_if_more_than___void__ptr_mut_arr__ptr_failure___nat_(_ctx, _closure.res, _closure.max_size))
		: 0;
}
_void each___void__arr__arr__char___each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id11___list_lintable_files__arr__arr__char__arr__char___lambda1___closure__klblist_lintable_files__arr__arr__char__arr__char___lambda1___lambda0___closure__klbeach_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id11___list_lintable_files__arr__arr__char__arr__char___lambda1___closure__klblist_lintable_files__arr__arr__char__arr__char___lambda1___lambda0_(ctx* _ctx, arr__arr__char a, each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id11___list_lintable_files__arr__arr__char__arr__char___lambda1___closure__klblist_lintable_files__arr__arr__char__arr__char___lambda1___lambda0___closure f) {
	return empty__q__bool__arr__arr__char_(a)
		? 0
		: (each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id11___list_lintable_files__arr__arr__char__arr__char___lambda1___closure__klblist_lintable_files__arr__arr__char__arr__char___lambda1___lambda0_(_ctx, f, first__arr__char__arr__arr__char_(_ctx, a)),
		each___void__arr__arr__char___each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id11___list_lintable_files__arr__arr__char__arr__char___lambda1___closure__klblist_lintable_files__arr__arr__char__arr__char___lambda1___lambda0___closure__klbeach_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id11___list_lintable_files__arr__arr__char__arr__char___lambda1___closure__klblist_lintable_files__arr__arr__char__arr__char___lambda1___lambda0_(_ctx, tail__arr__arr__char__arr__arr__char_(_ctx, a), f));
}
_void list_lintable_files__arr__arr__char__arr__char___lambda1_(ctx* _ctx, list_lintable_files__arr__arr__char__arr__char___lambda1___closure _closure, arr__char child) {
	return ignore_extension_of_name__bool__arr__char_(_ctx, base_name__arr__char__arr__char_(_ctx, child))
		? 0
		: push___void__ptr_mut_arr__arr__char___arr__char_(_ctx, _closure.res, child);
}
_void flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___lint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___closure__klblint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___lambda0_(ctx* _ctx, flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___lint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___closure__klblint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___lambda0___closure _closure, arr__char x) {
	return _op_less__bool__nat___nat_(_closure.res->size, _closure.max_size)
		? (push_all___void__ptr_mut_arr__ptr_failure___arr__ptr_failure_(_ctx, _closure.res, lint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0_(_ctx, _closure.mapper, x)),
		reduce_size_if_more_than___void__ptr_mut_arr__ptr_failure___nat_(_ctx, _closure.res, _closure.max_size))
		: 0;
}
_void catch_with_exception_ctx___void__ptr_exception_ctx___call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda0___closure__klbcall__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda0___call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda1___closure__klbcall__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda1_(ctx* _ctx, exception_ctx* ec, call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda0___closure try, call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda1___closure catcher) {
	exception old_thrown_exception;
	ptr__jmp_buf_tag old_jmp_buf;
	int32 setjmp_result;
	_void res;
	exception thrown_exception;
	return ((old_thrown_exception = ec->thrown_exception),
	((old_jmp_buf = ec->jmp_buf_ptr),
	((ec->jmp_buf_ptr = (&((jmp_buf_tag) _constant____jmp_buf_tag__0))), 0,
	((setjmp_result = setjmp(ec->jmp_buf_ptr)),
	_op_equal_equal__bool__int32___int32_(setjmp_result, 0)
		? ((res = call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda0(_ctx, try)),
		(((ec->jmp_buf_ptr = old_jmp_buf), 0,
		(ec->thrown_exception = old_thrown_exception), 0),
		res))
		: (assert___void__bool_(_ctx, _op_equal_equal__bool__int32___int32_(setjmp_result, 7)),
		((thrown_exception = ec->thrown_exception),
		(((ec->jmp_buf_ptr = old_jmp_buf), 0,
		(ec->thrown_exception = old_thrown_exception), 0),
		call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda1_(_ctx, catcher, thrown_exception))))))));
}
_void drop___void___void_(_void t) {
	return 0;
}
_void call___void__fun_mut1___void__result__int32__exception___result__int32__exception_(ctx* _ctx, fun_mut1___void__result__int32__exception f, result__int32__exception p0) {
	return call_with_ctx___void__ptr_ctx___fun_mut1___void__result__int32__exception___result__int32__exception_(_ctx, f, p0);
}
fut__int32* call__ptr_fut__int32__fun_mut0__ptr_fut__int32_(ctx* _ctx, fun_mut0__ptr_fut__int32 f) {
	return call_with_ctx__ptr_fut__int32__ptr_ctx___fun_mut0__ptr_fut__int32_(_ctx, f);
}
ptr__char noctx_at__ptr__char__arr__ptr__char___nat_(arr__ptr__char a, nat index) {
	return (hard_assert___void__bool_(_op_less__bool__nat___nat_(index, a.size)),
	*((a.data + index)));
}
nat noctx_at__nat__arr__nat___nat_(arr__nat a, nat index) {
	return (hard_assert___void__bool_(_op_less__bool__nat___nat_(index, a.size)),
	*((a.data + index)));
}
arr__char hard_fail__arr__char__arr__char__id2_() {
	assert(0);
}
_void make_mut_arr_worker___void__ptr_mut_arr__arr__char___nat___to_mut_arr__ptr_mut_arr__arr__char__arr__arr__char___lambda0___closure__klbto_mut_arr__ptr_mut_arr__arr__char__arr__arr__char___lambda0_(ctx* _ctx, mut_arr__arr__char* m, nat i, to_mut_arr__ptr_mut_arr__arr__char__arr__arr__char___lambda0___closure f) {
	return _op_equal_equal__bool__nat___nat_(i, m->size)
		? 0
		: (set_at___void__ptr_mut_arr__arr__char___nat___arr__char_(_ctx, m, i, to_mut_arr__ptr_mut_arr__arr__char__arr__arr__char___lambda0_(_ctx, f, i)),
		make_mut_arr_worker___void__ptr_mut_arr__arr__char___nat___to_mut_arr__ptr_mut_arr__arr__char__arr__arr__char___lambda0___closure__klbto_mut_arr__ptr_mut_arr__arr__char__arr__arr__char___lambda0_(_ctx, m, incr__nat__nat_(_ctx, i), f));
}
_void swap___void__ptr_mut_slice__arr__char___nat___nat_(ctx* _ctx, mut_slice__arr__char* a, nat lo, nat hi) {
	arr__char old_lo;
	return ((old_lo = at__arr__char__ptr_mut_slice__arr__char___nat_(_ctx, a, lo)),
	(set_at___void__ptr_mut_slice__arr__char___nat___arr__char_(_ctx, a, lo, at__arr__char__ptr_mut_slice__arr__char___nat_(_ctx, a, hi)),
	set_at___void__ptr_mut_slice__arr__char___nat___arr__char_(_ctx, a, hi, old_lo)));
}
arr__char at__arr__char__ptr_mut_slice__arr__char___nat_(ctx* _ctx, mut_slice__arr__char* a, nat index) {
	return (assert___void__bool_(_ctx, _op_less__bool__nat___nat_(index, a->size)),
	at__arr__char__ptr_mut_arr__arr__char___nat_(_ctx, a->backing, _op_plus__nat__nat___nat_(_ctx, a->begin, index)));
}
nat partition_recur__nat__ptr_mut_slice__arr__char___arr__char___nat___nat_(ctx* _ctx, mut_slice__arr__char* a, arr__char pivot, nat l, nat r) {
	arr__char em;
	return ((assert___void__bool_(_ctx, _op_less_equal__bool__nat___nat_(l, a->size)),
	assert___void__bool_(_ctx, _op_less__bool__nat___nat_(r, a->size))),
	_op_less_equal__bool__nat___nat_(l, r)
		? ((em = at__arr__char__ptr_mut_slice__arr__char___nat_(_ctx, a, l)),
		_op_less__bool__arr__char___arr__char_(em, pivot)
			? partition_recur__nat__ptr_mut_slice__arr__char___arr__char___nat___nat_(_ctx, a, pivot, incr__nat__nat_(_ctx, l), r)
			: (swap___void__ptr_mut_slice__arr__char___nat___nat_(_ctx, a, l, r),
			partition_recur__nat__ptr_mut_slice__arr__char___arr__char___nat___nat_(_ctx, a, pivot, l, decr__nat__nat_(_ctx, r))))
		: l);
}
mut_slice__arr__char* slice__ptr_mut_slice__arr__char__ptr_mut_slice__arr__char___nat___nat_(ctx* _ctx, mut_slice__arr__char* a, nat lo, nat size) {
	return (assert___void__bool_(_ctx, _op_less_equal__bool__nat___nat_(_op_plus__nat__nat___nat_(_ctx, lo, size), a->size)),
	_initmut_slice__arr__char(alloc__ptr__byte__nat_(_ctx, 24), (mut_slice__arr__char) {a->backing, size, _op_plus__nat__nat___nat_(_ctx, a->begin, lo)}));
}
mut_slice__arr__char* slice__ptr_mut_slice__arr__char__ptr_mut_slice__arr__char___nat_(ctx* _ctx, mut_slice__arr__char* a, nat lo) {
	return (assert___void__bool_(_ctx, _op_less_equal__bool__nat___nat_(lo, a->size)),
	slice__ptr_mut_slice__arr__char__ptr_mut_slice__arr__char___nat___nat_(_ctx, a, lo, _op_minus__nat__nat___nat_(_ctx, a->size, lo)));
}
bool is_file__q__bool__ptr__char_(ctx* _ctx, ptr__char path) {
	some__ptr_stat_t s;
	opt__ptr_stat_t matched;
	return (matched = get_stat__opt__ptr_stat_t__ptr__char_(_ctx, path),
		matched.kind == 0
		? todo__bool()
		: matched.kind == 1
		? (s = matched.as_some__ptr_stat_t,
		_op_equal_equal__bool__nat32___nat32_((s.value->st_mode & 61440u), 32768u)
		): _failbool());
}
pipes* make_pipes__ptr_pipes(ctx* _ctx) {
	pipes* res;
	return ((res = _initpipes(alloc__ptr__byte__nat_(_ctx, 8), (pipes) {0, 0})),
	(check_posix_error___void__int32_(_ctx, pipe(res)),
	res));
}
cell__int32* new_cell__ptr_cell__int32__int32__id0_(ctx* _ctx) {
	return _initcell__int32(alloc__ptr__byte__nat_(_ctx, 4), (cell__int32) {0});
}
int32 get__int32__ptr_cell__int32_(cell__int32* c) {
	return c->value;
}
_void keep_polling___void__int32___int32___ptr_mut_arr__char___ptr_mut_arr__char_(ctx* _ctx, int32 stdout_pipe, int32 stderr_pipe, mut_arr__char* stdout_builder, mut_arr__char* stderr_builder) {
	arr__pollfd arr;
	arr__pollfd poll_fds;
	pollfd* stdout_pollfd;
	pollfd* stderr_pollfd;
	int32 n_pollfds_with_events;
	handle_revents_result a;
	handle_revents_result b;
	return ((poll_fds = (arr = (arr__pollfd) { 2, (pollfd*) alloc__ptr__byte__nat_(_ctx, 16) }, arr.data[0] = (pollfd) {stdout_pipe, 1, 0}, arr.data[1] = (pollfd) {stderr_pipe, 1, 0}, arr)),
	((stdout_pollfd = ref_of_val_at__ptr_pollfd__arr__pollfd___nat_(_ctx, poll_fds, 0ull)),
	((stderr_pollfd = ref_of_val_at__ptr_pollfd__arr__pollfd___nat_(_ctx, poll_fds, 1ull)),
	((n_pollfds_with_events = poll(poll_fds.data, poll_fds.size, -1)),
	zero__q__bool__int32_(n_pollfds_with_events)
		? 0
		: ((a = handle_revents__handle_revents_result__ptr_pollfd___ptr_mut_arr__char_(_ctx, stdout_pollfd, stdout_builder)),
		((b = handle_revents__handle_revents_result__ptr_pollfd___ptr_mut_arr__char_(_ctx, stderr_pollfd, stderr_builder)),
		(assert___void__bool_(_ctx, _op_equal_equal__bool__nat___nat_(_op_plus__nat__nat___nat_(_ctx, to_nat__nat__bool_(_ctx, any__q__bool__handle_revents_result_(_ctx, a)), to_nat__nat__bool_(_ctx, any__q__bool__handle_revents_result_(_ctx, b))), to_nat__nat__int32_(_ctx, n_pollfds_with_events))),
		(a.hung_up__q && b.hung_up__q)
			? 0
			: keep_polling___void__int32___int32___ptr_mut_arr__char___ptr_mut_arr__char_(_ctx, stdout_pipe, stderr_pipe, stdout_builder, stderr_builder))))))));
}
int32 wait_and_get_exit_code__int32__int32_(ctx* _ctx, int32 pid) {
	cell__int32* wait_status_cell;
	int32 res_pid;
	int32 wait_status;
	int32 signal;
	return ((wait_status_cell = new_cell__ptr_cell__int32__int32__id0_(_ctx)),
	((res_pid = waitpid(pid, wait_status_cell, 0)),
	((wait_status = get__int32__ptr_cell__int32_(wait_status_cell)),
	(assert___void__bool_(_ctx, _op_equal_equal__bool__int32___int32_(res_pid, pid)),
	w_if_exited__bool__int32_(_ctx, wait_status)
		? w_exit_status__int32__int32_(_ctx, wait_status)
		: w_if_signaled__bool__int32_(_ctx, wait_status)
			? ((signal = w_term_sig__int32__int32_(_ctx, wait_status)),
			(print_sync___void__arr__char_(_op_plus__arr__char__arr__char___arr__char_(_ctx, (arr__char) _constant____arr__char__55, to_str__arr__char__int32_(_ctx, signal))),
			todo__int32()))
			: w_if_stopped__bool__int32_(_ctx, wait_status)
				? (print_sync___void__arr__char_((arr__char) _constant____arr__char__64),
				todo__int32())
				: w_if_continued__bool__int32_(_ctx, wait_status)
					? todo__int32()
					: todo__int32()))));
}
arr__ptr__char cons__arr__ptr__char__ptr__char___arr__ptr__char_(ctx* _ctx, ptr__char a, arr__ptr__char b) {
	arr__ptr__char arr;
	return _op_plus__arr__ptr__char__arr__ptr__char___arr__ptr__char_(_ctx, (arr = (arr__ptr__char) { 1, (ptr__char*) alloc__ptr__byte__nat_(_ctx, 8) }, arr.data[0] = a, arr), b);
}
arr__ptr__char rcons__arr__ptr__char__arr__ptr__char___ptr__char_(ctx* _ctx, arr__ptr__char a, ptr__char b) {
	arr__ptr__char arr;
	return _op_plus__arr__ptr__char__arr__ptr__char___arr__ptr__char_(_ctx, a, (arr = (arr__ptr__char) { 1, (ptr__char*) alloc__ptr__byte__nat_(_ctx, 8) }, arr.data[0] = b, arr));
}
arr__ptr__char map__arr__ptr__char__arr__arr__char___fun_mut1__ptr__char__arr__char__id10_(ctx* _ctx, arr__arr__char a) {
	return make_arr__arr__ptr__char__nat___map__arr__ptr__char__arr__arr__char___fun_mut1__ptr__char__arr__char__id10___lambda0___closure__klbmap__arr__ptr__char__arr__arr__char___fun_mut1__ptr__char__arr__char__id10___lambda0_(_ctx, a.size, (map__arr__ptr__char__arr__arr__char___fun_mut1__ptr__char__arr__char__id10___lambda0___closure) {a});
}
mut_arr__ptr__char* new_mut_arr__ptr_mut_arr__ptr__char(ctx* _ctx) {
	return _initmut_arr__ptr__char(alloc__ptr__byte__nat_(_ctx, 32), (mut_arr__ptr__char) {0, 0ull, 0ull, NULL});
}
_void each___void__ptr_dict__arr__char__arr__char___convert_environ__ptr__ptr__char__ptr_dict__arr__char__arr__char___lambda0___closure__klbconvert_environ__ptr__ptr__char__ptr_dict__arr__char__arr__char___lambda0_(ctx* _ctx, dict__arr__char__arr__char* d, convert_environ__ptr__ptr__char__ptr_dict__arr__char__arr__char___lambda0___closure f) {
	return empty__q__bool__ptr_dict__arr__char__arr__char_(_ctx, d)
		? 0
		: (convert_environ__ptr__ptr__char__ptr_dict__arr__char__arr__char___lambda0__(_ctx, f, first__arr__char__arr__arr__char_(_ctx, d->keys), first__arr__char__arr__arr__char_(_ctx, d->values)),
		each___void__ptr_dict__arr__char__arr__char___convert_environ__ptr__ptr__char__ptr_dict__arr__char__arr__char___lambda0___closure__klbconvert_environ__ptr__ptr__char__ptr_dict__arr__char__arr__char___lambda0_(_ctx, _initdict__arr__char__arr__char(alloc__ptr__byte__nat_(_ctx, 32), (dict__arr__char__arr__char) {tail__arr__arr__char__arr__arr__char_(_ctx, d->keys), tail__arr__arr__char__arr__arr__char_(_ctx, d->values)}), f));
}
_void push___void__ptr_mut_arr__ptr__char___ptr__char_(ctx* _ctx, mut_arr__ptr__char* a, ptr__char value) {
	return ((((_op_equal_equal__bool__nat___nat_(a->size, a->capacity)
		? increase_capacity_to___void__ptr_mut_arr__ptr__char___nat_(_ctx, a, (zero__q__bool__nat_(a->size) ? 4ull : _op_times__nat__nat___nat_(_ctx, a->size, 2ull)))
		: 0,
	ensure_capacity___void__ptr_mut_arr__ptr__char___nat_(_ctx, a, round_up_to_power_of_two__nat__nat_(_ctx, incr__nat__nat_(_ctx, a->size)))),
	assert___void__bool_(_ctx, _op_less__bool__nat___nat_(a->size, a->capacity))),
	((*((a->data + a->size)) = value), 0)),
	(a->size = incr__nat__nat_(_ctx, a->size)), 0);
}
arr__ptr__char freeze__arr__ptr__char__ptr_mut_arr__ptr__char_(mut_arr__ptr__char* a) {
	return ((a->frozen__q = 1), 0,
	unsafe_as_arr__arr__ptr__char__ptr_mut_arr__ptr__char_(a));
}
process_result* throw__ptr_process_result__exception_(ctx* _ctx, exception e) {
	exception_ctx* exn_ctx;
	return ((exn_ctx = get_exception_ctx__ptr_exception_ctx(_ctx)),
	(((hard_forbid___void__bool_(_op_equal_equal__bool__ptr__jmp_buf_tag___ptr__jmp_buf_tag_(exn_ctx->jmp_buf_ptr, NULL)),
	(exn_ctx->thrown_exception = e), 0),
	(longjmp(exn_ctx->jmp_buf_ptr, 7), 0)),
	todo__ptr_process_result()));
}
nat abs__nat___int_(ctx* _ctx, _int i) {
	_int i_abs;
	return ((i_abs = (negative__q__bool___int_(_ctx, i) ? neg___int___int_(_ctx, i) : i)),
	to_nat__nat___int_(_ctx, i_abs));
}
ptr__ptr_failure uninitialized_data__ptr__ptr_failure__nat_(ctx* _ctx, nat size) {
	ptr__byte bptr;
	return ((bptr = alloc__ptr__byte__nat_(_ctx, (size * 8ull))),
	(ptr__ptr_failure) bptr);
}
_void copy_data_from___void__ptr__ptr_failure___ptr__ptr_failure___nat_(ctx* _ctx, ptr__ptr_failure to, ptr__ptr_failure from, nat len) {
	return zero__q__bool__nat_(len)
		? 0
		: (((*(to) = *(from)), 0),
		copy_data_from___void__ptr__ptr_failure___ptr__ptr_failure___nat_(_ctx, incr__ptr__ptr_failure__ptr__ptr_failure_(to), incr__ptr__ptr_failure__ptr__ptr_failure_(from), decr__nat__nat_(_ctx, len)));
}
_void remove_colors_recur_2___void__arr__char___ptr_mut_arr__char_(ctx* _ctx, arr__char s, mut_arr__char* out) {
	return empty__q__bool__arr__char_(s)
		? 0
		: _op_equal_equal__bool__char___char_(first__char__arr__char_(_ctx, s), 'm')
			? remove_colors_recur___void__arr__char___ptr_mut_arr__char_(_ctx, tail__arr__char__arr__char_(_ctx, s), out)
			: remove_colors_recur_2___void__arr__char___ptr_mut_arr__char_(_ctx, tail__arr__char__arr__char_(_ctx, s), out);
}
_void push___void__ptr_mut_arr__char___char_(ctx* _ctx, mut_arr__char* a, char value) {
	return ((((_op_equal_equal__bool__nat___nat_(a->size, a->capacity)
		? increase_capacity_to___void__ptr_mut_arr__char___nat_(_ctx, a, (zero__q__bool__nat_(a->size) ? 4ull : _op_times__nat__nat___nat_(_ctx, a->size, 2ull)))
		: 0,
	ensure_capacity___void__ptr_mut_arr__char___nat_(_ctx, a, round_up_to_power_of_two__nat__nat_(_ctx, incr__nat__nat_(_ctx, a->size)))),
	assert___void__bool_(_ctx, _op_less__bool__nat___nat_(a->size, a->capacity))),
	((*((a->data + a->size)) = value), 0)),
	(a->size = incr__nat__nat_(_ctx, a->size)), 0);
}
opt__arr__char todo__opt__arr__char() {
	return hard_fail__opt__arr__char__arr__char__id2_();
}
bool zero__q__bool___int_(_int i) {
	return _op_equal_equal__bool___int____int_(i, 0ll);
}
_void each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id9___list_runnable_tests__arr__arr__char__arr__char___lambda0___closure__klblist_runnable_tests__arr__arr__char__arr__char___lambda0___lambda0_(ctx* _ctx, each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id9___list_runnable_tests__arr__arr__char__arr__char___lambda0___closure__klblist_runnable_tests__arr__arr__char__arr__char___lambda0___lambda0___closure _closure, arr__char child_name) {
	return always_true__bool__arr__char___asLambda_(_ctx, child_name)
		? each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id9___list_runnable_tests__arr__arr__char__arr__char___lambda0___closure__klblist_runnable_tests__arr__arr__char__arr__char___lambda0_(_ctx, child_path__arr__char__arr__char___arr__char_(_ctx, _closure.path, child_name), _closure.f)
		: 0;
}
arr__ptr_failure run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0_(ctx* _ctx, run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure _closure, arr__char test) {
	return (_closure.options.print_tests__q
		? print_sync___void__arr__char_(_op_plus__arr__char__arr__char___arr__char_(_ctx, (arr__char) _constant____arr__char__78, test))
		: 0,
	run_single_runnable_test__arr__ptr_failure__arr__char___ptr_dict__arr__char__arr__char___arr__char_(_ctx, _closure.path_to_noze, _closure.env, test));
}
_void each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id11___list_lintable_files__arr__arr__char__arr__char___lambda1___closure__klblist_lintable_files__arr__arr__char__arr__char___lambda1___lambda0_(ctx* _ctx, each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id11___list_lintable_files__arr__arr__char__arr__char___lambda1___closure__klblist_lintable_files__arr__arr__char__arr__char___lambda1___lambda0___closure _closure, arr__char child_name) {
	return list_lintable_files__arr__arr__char__arr__char___lambda0_(_ctx, child_name)
		? each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id11___list_lintable_files__arr__arr__char__arr__char___lambda1___closure__klblist_lintable_files__arr__arr__char__arr__char___lambda1_(_ctx, child_path__arr__char__arr__char___arr__char_(_ctx, _closure.path, child_name), _closure.f)
		: 0;
}
bool ignore_extension_of_name__bool__arr__char_(ctx* _ctx, arr__char name) {
	some__arr__char s;
	opt__arr__char matched;
	return (matched = get_extension__opt__arr__char__arr__char_(_ctx, name),
		matched.kind == 0
		? 1
		: matched.kind == 1
		? (s = matched.as_some__arr__char,
		ignore_extension__bool__arr__char_(_ctx, s.value)
		): _failbool());
}
arr__ptr_failure lint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0_(ctx* _ctx, lint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___closure _closure, arr__char file) {
	return (_closure.options.print_tests__q
		? print_sync___void__arr__char_(_op_plus__arr__char__arr__char___arr__char_(_ctx, (arr__char) _constant____arr__char__90, file))
		: 0,
	lint_file__arr__ptr_failure__arr__char_(_ctx, file));
}
_void call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda0(ctx* _ctx, call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda0___closure _closure) {
	return forward_to___void__ptr_fut__int32___ptr_fut__int32_(_ctx, call__ptr_fut__int32__fun_mut1__ptr_fut__int32___void____void_(_ctx, _closure.f.fun, _closure.p0), _closure.res);
}
_void call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda1_(ctx* _ctx, call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda1___closure _closure, exception it) {
	return reject___void__ptr_fut__int32___exception_(_ctx, _closure.res, it);
}
_void call_with_ctx___void__ptr_ctx___fun_mut1___void__result__int32__exception___result__int32__exception_(ctx* c, fun_mut1___void__result__int32__exception f, result__int32__exception p0) {
	return f.fun_ptr(c, f.closure, p0);
}
fut__int32* call_with_ctx__ptr_fut__int32__ptr_ctx___fun_mut0__ptr_fut__int32_(ctx* c, fun_mut0__ptr_fut__int32 f) {
	return f.fun_ptr(c, f.closure);
}
arr__char to_mut_arr__ptr_mut_arr__arr__char__arr__arr__char___lambda0_(ctx* _ctx, to_mut_arr__ptr_mut_arr__arr__char__arr__arr__char___lambda0___closure _closure, nat i) {
	return at__arr__char__arr__arr__char___nat_(_ctx, _closure.a, i);
}
_void set_at___void__ptr_mut_slice__arr__char___nat___arr__char_(ctx* _ctx, mut_slice__arr__char* a, nat index, arr__char value) {
	return (assert___void__bool_(_ctx, _op_less__bool__nat___nat_(index, a->size)),
	set_at___void__ptr_mut_arr__arr__char___nat___arr__char_(_ctx, a->backing, _op_plus__nat__nat___nat_(_ctx, a->begin, index), value));
}
arr__char at__arr__char__ptr_mut_arr__arr__char___nat_(ctx* _ctx, mut_arr__arr__char* a, nat index) {
	return (assert___void__bool_(_ctx, _op_less__bool__nat___nat_(index, a->size)),
	noctx_at__arr__char__ptr_mut_arr__arr__char___nat_(a, index));
}
bool _op_less__bool__arr__char___arr__char_(arr__char a, arr__char b) {
	comparison matched;
	return (matched = _op_less_equal_greater__comparison__arr__char___arr__char_(a, b),
		matched.kind == 0
		? 1
		: matched.kind == 1
		? 0
		: matched.kind == 2
		? 0
		: _failbool());
}
pollfd* ref_of_val_at__ptr_pollfd__arr__pollfd___nat_(ctx* _ctx, arr__pollfd a, nat index) {
	return (assert___void__bool_(_ctx, _op_less__bool__nat___nat_(index, a.size)),
	ref_of_ptr__ptr_pollfd__ptr__pollfd_((a.data + index)));
}
handle_revents_result handle_revents__handle_revents_result__ptr_pollfd___ptr_mut_arr__char_(ctx* _ctx, pollfd* pollfd, mut_arr__char* builder) {
	int16 revents;
	bool had_pollin__q;
	bool hung_up__q;
	return ((revents = pollfd->revents),
	((had_pollin__q = has_pollin__q__bool__int16_(_ctx, revents)),
	(had_pollin__q
		? read_to_buffer_until_eof___void__int32___ptr_mut_arr__char_(_ctx, pollfd->fd, builder)
		: 0,
	((hung_up__q = has_pollhup__q__bool__int16_(_ctx, revents)),
	((((has_pollpri__q__bool__int16_(_ctx, revents) || has_pollout__q__bool__int16_(_ctx, revents)) || has_pollerr__q__bool__int16_(_ctx, revents)) || has_pollnval__q__bool__int16_(_ctx, revents))
		? todo___void()
		: 0,
	(handle_revents_result) {had_pollin__q, hung_up__q})))));
}
nat to_nat__nat__bool_(ctx* _ctx, bool b) {
	return (b ? 1ull : 0ull);
}
bool any__q__bool__handle_revents_result_(ctx* _ctx, handle_revents_result r) {
	return (r.had_pollin__q || r.hung_up__q);
}
nat to_nat__nat__int32_(ctx* _ctx, int32 i) {
	return to_nat__nat___int_(_ctx, (_int) i);
}
bool w_if_exited__bool__int32_(ctx* _ctx, int32 status) {
	return zero__q__bool__int32_(w_term_sig__int32__int32_(_ctx, status));
}
int32 w_exit_status__int32__int32_(ctx* _ctx, int32 status) {
	return ((status & 65280) >> 8);
}
bool w_if_signaled__bool__int32_(ctx* _ctx, int32 status) {
	int32 ts;
	return ((ts = w_term_sig__int32__int32_(_ctx, status)),
	(_op_bang_equal__bool__int32___int32_(ts, 0) && _op_bang_equal__bool__int32___int32_(ts, 127)));
}
int32 w_term_sig__int32__int32_(ctx* _ctx, int32 status) {
	return (status & 127);
}
int32 todo__int32() {
	return hard_fail__int32__arr__char__id2_();
}
bool w_if_stopped__bool__int32_(ctx* _ctx, int32 status) {
	return _op_equal_equal__bool__int32___int32_((status & 255), 127);
}
bool w_if_continued__bool__int32_(ctx* _ctx, int32 status) {
	return _op_equal_equal__bool__int32___int32_(status, 65535);
}
arr__ptr__char _op_plus__arr__ptr__char__arr__ptr__char___arr__ptr__char_(ctx* _ctx, arr__ptr__char a, arr__ptr__char b) {
	return make_arr__arr__ptr__char__nat____op_plus__arr__ptr__char__arr__ptr__char___arr__ptr__char___lambda0___closure__klb_op_plus__arr__ptr__char__arr__ptr__char___arr__ptr__char___lambda0_(_ctx, _op_plus__nat__nat___nat_(_ctx, a.size, b.size), (_op_plus__arr__ptr__char__arr__ptr__char___arr__ptr__char___lambda0___closure) {a, b});
}
arr__ptr__char make_arr__arr__ptr__char__nat___map__arr__ptr__char__arr__arr__char___fun_mut1__ptr__char__arr__char__id10___lambda0___closure__klbmap__arr__ptr__char__arr__arr__char___fun_mut1__ptr__char__arr__char__id10___lambda0_(ctx* _ctx, nat size, map__arr__ptr__char__arr__arr__char___fun_mut1__ptr__char__arr__char__id10___lambda0___closure f) {
	return freeze__arr__ptr__char__ptr_mut_arr__ptr__char_(make_mut_arr__ptr_mut_arr__ptr__char__nat___map__arr__ptr__char__arr__arr__char___fun_mut1__ptr__char__arr__char__id10___lambda0___closure__klbmap__arr__ptr__char__arr__arr__char___fun_mut1__ptr__char__arr__char__id10___lambda0_(_ctx, size, f));
}
bool empty__q__bool__ptr_dict__arr__char__arr__char_(ctx* _ctx, dict__arr__char__arr__char* d) {
	return empty__q__bool__arr__arr__char_(d->keys);
}
_void convert_environ__ptr__ptr__char__ptr_dict__arr__char__arr__char___lambda0__(ctx* _ctx, convert_environ__ptr__ptr__char__ptr_dict__arr__char__arr__char___lambda0___closure _closure, arr__char key, arr__char value) {
	return push___void__ptr_mut_arr__ptr__char___ptr__char_(_ctx, _closure.res, to_c_str__ptr__char__arr__char_(_ctx, _op_plus__arr__char__arr__char___arr__char_(_ctx, _op_plus__arr__char__arr__char___arr__char_(_ctx, key, (arr__char) _constant____arr__char__47), value)));
}
_void increase_capacity_to___void__ptr_mut_arr__ptr__char___nat_(ctx* _ctx, mut_arr__ptr__char* a, nat new_capacity) {
	ptr__ptr__char old_data;
	return (assert___void__bool_(_ctx, _op_greater__bool__nat___nat_(new_capacity, a->capacity)),
	((old_data = a->data),
	(((a->capacity = new_capacity), 0,
	(a->data = uninitialized_data__ptr__ptr__char__nat_(_ctx, new_capacity)), 0),
	copy_data_from___void__ptr__ptr__char___ptr__ptr__char___nat_(_ctx, a->data, old_data, a->size))));
}
_void ensure_capacity___void__ptr_mut_arr__ptr__char___nat_(ctx* _ctx, mut_arr__ptr__char* a, nat capacity) {
	return _op_less__bool__nat___nat_(a->capacity, capacity)
		? increase_capacity_to___void__ptr_mut_arr__ptr__char___nat_(_ctx, a, round_up_to_power_of_two__nat__nat_(_ctx, capacity))
		: 0;
}
arr__ptr__char unsafe_as_arr__arr__ptr__char__ptr_mut_arr__ptr__char_(mut_arr__ptr__char* a) {
	return (arr__ptr__char) {a->size, a->data};
}
process_result* todo__ptr_process_result() {
	return hard_fail__ptr_process_result__arr__char__id2_();
}
_int neg___int___int_(ctx* _ctx, _int i) {
	return _op_times___int___int____int_(_ctx, i, -1ll);
}
ptr__ptr_failure incr__ptr__ptr_failure__ptr__ptr_failure_(ptr__ptr_failure p) {
	return (p + 1ull);
}
_void increase_capacity_to___void__ptr_mut_arr__char___nat_(ctx* _ctx, mut_arr__char* a, nat new_capacity) {
	ptr__char old_data;
	return (assert___void__bool_(_ctx, _op_greater__bool__nat___nat_(new_capacity, a->capacity)),
	((old_data = a->data),
	(((a->capacity = new_capacity), 0,
	(a->data = uninitialized_data__ptr__char__nat_(_ctx, new_capacity)), 0),
	copy_data_from___void__ptr__char___ptr__char___nat_(_ctx, a->data, old_data, a->size))));
}
_void ensure_capacity___void__ptr_mut_arr__char___nat_(ctx* _ctx, mut_arr__char* a, nat capacity) {
	return _op_less__bool__nat___nat_(a->capacity, capacity)
		? increase_capacity_to___void__ptr_mut_arr__char___nat_(_ctx, a, round_up_to_power_of_two__nat__nat_(_ctx, capacity))
		: 0;
}
opt__arr__char hard_fail__opt__arr__char__arr__char__id2_() {
	assert(0);
}
arr__ptr_failure run_single_runnable_test__arr__ptr_failure__arr__char___ptr_dict__arr__char__arr__char___arr__char_(ctx* _ctx, arr__char path_to_noze, dict__arr__char__arr__char* env, arr__char path) {
	arr__arr__char arr;
	process_result* res;
	arr__char message;
	arr__ptr_failure arr1;
	return ((res = spawn_and_wait_result__ptr_process_result__arr__char___arr__arr__char___ptr_dict__arr__char__arr__char_(_ctx, path_to_noze, (arr = (arr__arr__char) { 2, (arr__char*) alloc__ptr__byte__nat_(_ctx, 32) }, arr.data[0] = (arr__char) _constant____arr__char__79, arr.data[1] = path, arr), env)),
	_op_equal_equal__bool__ptr_process_result___ptr_process_result_(res, &_constant____ptr_process_result__0)
		? (arr__ptr_failure) _constant____arr__ptr_failure__0
		: ((message = _op_plus__arr__char__arr__char___arr__char_(_ctx, _op_plus__arr__char__arr__char___arr__char_(_ctx, _op_plus__arr__char__arr__char___arr__char_(_ctx, _op_plus__arr__char__arr__char___arr__char_(_ctx, _op_plus__arr__char__arr__char___arr__char_(_ctx, (arr__char) _constant____arr__char__80, to_str__arr__char__int32_(_ctx, res->exit_code)), (arr__char) _constant____arr__char__81), res->stdout), (arr__char) _constant____arr__char__82), res->stderr)),
		(arr1 = (arr__ptr_failure) { 1, (failure**) alloc__ptr__byte__nat_(_ctx, 8) }, arr1.data[0] = _initfailure(alloc__ptr__byte__nat_(_ctx, 32), (failure) {path, message}), arr1)));
}
bool list_lintable_files__arr__arr__char__arr__char___lambda0_(ctx* _ctx, arr__char it) {
	return !((_op_equal_equal__bool__char___char_(first__char__arr__char_(_ctx, it), '.') || _op_equal_equal__bool__arr__char___arr__char_(it, (arr__char) _constant____arr__char__85)));
}
bool ignore_extension__bool__arr__char_(ctx* _ctx, arr__char ext) {
	return contains__q__bool__arr__arr__char___arr__char_((arr__arr__char) _constant____arr__arr__char__2, ext);
}
arr__ptr_failure lint_file__arr__ptr_failure__arr__char_(ctx* _ctx, arr__char path) {
	arr__char text;
	mut_arr__ptr_failure* res;
	bool err_file__q;
	return ((text = read_file__arr__char__arr__char_(_ctx, path)),
	((res = new_mut_arr__ptr_mut_arr__ptr_failure(_ctx)),
	((err_file__q = _op_equal_equal__bool__arr__char___arr__char_(force__arr__char__opt__arr__char_(_ctx, get_extension__opt__arr__char__arr__char_(_ctx, path)), (arr__char) _constant____arr__char__52)),
	(each_with_index___void__arr__arr__char___lint_file__arr__ptr_failure__arr__char___lambda0___closure__klblint_file__arr__ptr_failure__arr__char___lambda0_(_ctx, lines__arr__arr__char__arr__char_(_ctx, text), (lint_file__arr__ptr_failure__arr__char___lambda0___closure) {err_file__q, res, path}),
	freeze__arr__ptr_failure__ptr_mut_arr__ptr_failure_(res)))));
}
fut__int32* call__ptr_fut__int32__fun_mut1__ptr_fut__int32___void____void_(ctx* _ctx, fun_mut1__ptr_fut__int32___void f, _void p0) {
	return call_with_ctx__ptr_fut__int32__ptr_ctx___fun_mut1__ptr_fut__int32___void____void_(_ctx, f, p0);
}
arr__char noctx_at__arr__char__ptr_mut_arr__arr__char___nat_(mut_arr__arr__char* a, nat index) {
	return (hard_assert___void__bool_(_op_less__bool__nat___nat_(index, a->size)),
	*((a->data + index)));
}
pollfd* ref_of_ptr__ptr_pollfd__ptr__pollfd_(ptr__pollfd p) {
	return (&(*(p)));
}
bool has_pollin__q__bool__int16_(ctx* _ctx, int16 revents) {
	return bits_intersect__q__bool__int16___int16_(revents, 1);
}
_void read_to_buffer_until_eof___void__int32___ptr_mut_arr__char_(ctx* _ctx, int32 fd, mut_arr__char* buffer) {
	ptr__char add_data_to;
	_int n_bytes_read;
	return (ensure_capacity___void__ptr_mut_arr__char___nat_(_ctx, buffer, _op_plus__nat__nat___nat_(_ctx, buffer->size, 1024ull)),
	((add_data_to = (buffer->data + buffer->size)),
	((n_bytes_read = read(fd, (ptr__byte) add_data_to, 1024ull)),
	_op_equal_equal__bool___int____int_(n_bytes_read, -1ll)
		? todo___void()
		: _op_equal_equal__bool___int____int_(n_bytes_read, 0ll)
			? 0
			: (unsafe_increase_size___void__ptr_mut_arr__char___nat_(_ctx, buffer, to_nat__nat___int_(_ctx, n_bytes_read)),
			read_to_buffer_until_eof___void__int32___ptr_mut_arr__char_(_ctx, fd, buffer)))));
}
bool has_pollhup__q__bool__int16_(ctx* _ctx, int16 revents) {
	return bits_intersect__q__bool__int16___int16_(revents, 16);
}
bool has_pollpri__q__bool__int16_(ctx* _ctx, int16 revents) {
	return bits_intersect__q__bool__int16___int16_(revents, 2);
}
bool has_pollout__q__bool__int16_(ctx* _ctx, int16 revents) {
	return bits_intersect__q__bool__int16___int16_(revents, 4);
}
bool has_pollerr__q__bool__int16_(ctx* _ctx, int16 revents) {
	return bits_intersect__q__bool__int16___int16_(revents, 8);
}
bool has_pollnval__q__bool__int16_(ctx* _ctx, int16 revents) {
	return bits_intersect__q__bool__int16___int16_(revents, 32);
}
bool _op_bang_equal__bool__int32___int32_(int32 a, int32 b) {
	return !(_op_equal_equal__bool__int32___int32_(a, b));
}
int32 hard_fail__int32__arr__char__id2_() {
	assert(0);
}
arr__ptr__char make_arr__arr__ptr__char__nat____op_plus__arr__ptr__char__arr__ptr__char___arr__ptr__char___lambda0___closure__klb_op_plus__arr__ptr__char__arr__ptr__char___arr__ptr__char___lambda0_(ctx* _ctx, nat size, _op_plus__arr__ptr__char__arr__ptr__char___arr__ptr__char___lambda0___closure f) {
	return freeze__arr__ptr__char__ptr_mut_arr__ptr__char_(make_mut_arr__ptr_mut_arr__ptr__char__nat____op_plus__arr__ptr__char__arr__ptr__char___arr__ptr__char___lambda0___closure__klb_op_plus__arr__ptr__char__arr__ptr__char___arr__ptr__char___lambda0_(_ctx, size, f));
}
mut_arr__ptr__char* make_mut_arr__ptr_mut_arr__ptr__char__nat___map__arr__ptr__char__arr__arr__char___fun_mut1__ptr__char__arr__char__id10___lambda0___closure__klbmap__arr__ptr__char__arr__arr__char___fun_mut1__ptr__char__arr__char__id10___lambda0_(ctx* _ctx, nat size, map__arr__ptr__char__arr__arr__char___fun_mut1__ptr__char__arr__char__id10___lambda0___closure f) {
	mut_arr__ptr__char* res;
	return ((res = new_uninitialized_mut_arr__ptr_mut_arr__ptr__char__nat_(_ctx, size)),
	(make_mut_arr_worker___void__ptr_mut_arr__ptr__char___nat___map__arr__ptr__char__arr__arr__char___fun_mut1__ptr__char__arr__char__id10___lambda0___closure__klbmap__arr__ptr__char__arr__arr__char___fun_mut1__ptr__char__arr__char__id10___lambda0_(_ctx, res, 0ull, f),
	res));
}
ptr__ptr__char uninitialized_data__ptr__ptr__char__nat_(ctx* _ctx, nat size) {
	ptr__byte bptr;
	return ((bptr = alloc__ptr__byte__nat_(_ctx, (size * 8ull))),
	(ptr__ptr__char) bptr);
}
_void copy_data_from___void__ptr__ptr__char___ptr__ptr__char___nat_(ctx* _ctx, ptr__ptr__char to, ptr__ptr__char from, nat len) {
	return zero__q__bool__nat_(len)
		? 0
		: (((*(to) = *(from)), 0),
		copy_data_from___void__ptr__ptr__char___ptr__ptr__char___nat_(_ctx, incr__ptr__ptr__char__ptr__ptr__char_(to), incr__ptr__ptr__char__ptr__ptr__char_(from), decr__nat__nat_(_ctx, len)));
}
process_result* hard_fail__ptr_process_result__arr__char__id2_() {
	assert(0);
}
_int _op_times___int___int____int_(ctx* _ctx, _int a, _int b) {
	return ((((assert___void__bool_(_ctx, _op_greater__bool___int____int_(a, -1000000ll)),
	assert___void__bool_(_ctx, _op_less__bool___int____int_(a, 1000000ll))),
	assert___void__bool_(_ctx, _op_greater__bool___int____int_(b, -1000000ll))),
	assert___void__bool_(_ctx, _op_less__bool___int____int_(b, 1000000ll))),
	(a * b));
}
_void copy_data_from___void__ptr__char___ptr__char___nat_(ctx* _ctx, ptr__char to, ptr__char from, nat len) {
	return zero__q__bool__nat_(len)
		? 0
		: (((*(to) = *(from)), 0),
		copy_data_from___void__ptr__char___ptr__char___nat_(_ctx, incr__ptr__char__ptr__char_(to), incr__ptr__char__ptr__char_(from), decr__nat__nat_(_ctx, len)));
}
bool _op_equal_equal__bool__ptr_process_result___ptr_process_result_(process_result* a, process_result* b) {
	comparison matched;
	return (matched = _op_less_equal_greater__comparison__ptr_process_result___ptr_process_result_(a, b),
		matched.kind == 0
		? 0
		: matched.kind == 1
		? 1
		: matched.kind == 2
		? 0
		: _failbool());
}
bool contains__q__bool__arr__arr__char___arr__char_(arr__arr__char a, arr__char value) {
	return contains_recur__q__bool__arr__arr__char___arr__char___nat_(a, value, 0ull);
}
arr__char read_file__arr__char__arr__char_(ctx* _ctx, arr__char path) {
	some__arr__char s;
	opt__arr__char matched;
	return (assert___void__bool_(_ctx, is_file__q__bool__arr__char_(_ctx, path)),
	(matched = try_read_file__opt__arr__char__arr__char_(_ctx, path),
		matched.kind == 0
		? todo__arr__char()
		: matched.kind == 1
		? (s = matched.as_some__arr__char,
		s.value
		): _failarr__char()));
}
_void each_with_index___void__arr__arr__char___lint_file__arr__ptr_failure__arr__char___lambda0___closure__klblint_file__arr__ptr_failure__arr__char___lambda0_(ctx* _ctx, arr__arr__char a, lint_file__arr__ptr_failure__arr__char___lambda0___closure f) {
	return each_with_index_recur___void__arr__arr__char___lint_file__arr__ptr_failure__arr__char___lambda0___closure__klblint_file__arr__ptr_failure__arr__char___lambda0___nat_(_ctx, a, f, 0ull);
}
arr__arr__char lines__arr__arr__char__arr__char_(ctx* _ctx, arr__char s) {
	mut_arr__arr__char* res;
	cell__nat* last_nl;
	return ((res = new_mut_arr__ptr_mut_arr__arr__char(_ctx)),
	((last_nl = new_cell__ptr_cell__nat__nat__id0_(_ctx)),
	((each_with_index___void__arr__char___lines__arr__arr__char__arr__char___lambda0___closure__klblines__arr__arr__char__arr__char___lambda0_(_ctx, s, (lines__arr__arr__char__arr__char___lambda0___closure) {res, s, last_nl}),
	push___void__ptr_mut_arr__arr__char___arr__char_(_ctx, res, slice_from_to__arr__char__arr__char___nat___nat_(_ctx, s, get__nat__ptr_cell__nat_(last_nl), s.size))),
	freeze__arr__arr__char__ptr_mut_arr__arr__char_(res))));
}
fut__int32* call_with_ctx__ptr_fut__int32__ptr_ctx___fun_mut1__ptr_fut__int32___void____void_(ctx* c, fun_mut1__ptr_fut__int32___void f, _void p0) {
	return f.fun_ptr(c, f.closure, p0);
}
bool bits_intersect__q__bool__int16___int16_(int16 a, int16 b) {
	return !(zero__q__bool__int16_((a & b)));
}
_void unsafe_increase_size___void__ptr_mut_arr__char___nat_(ctx* _ctx, mut_arr__char* a, nat increase_by) {
	return unsafe_set_size___void__ptr_mut_arr__char___nat_(_ctx, a, _op_plus__nat__nat___nat_(_ctx, a->size, increase_by));
}
mut_arr__ptr__char* make_mut_arr__ptr_mut_arr__ptr__char__nat____op_plus__arr__ptr__char__arr__ptr__char___arr__ptr__char___lambda0___closure__klb_op_plus__arr__ptr__char__arr__ptr__char___arr__ptr__char___lambda0_(ctx* _ctx, nat size, _op_plus__arr__ptr__char__arr__ptr__char___arr__ptr__char___lambda0___closure f) {
	mut_arr__ptr__char* res;
	return ((res = new_uninitialized_mut_arr__ptr_mut_arr__ptr__char__nat_(_ctx, size)),
	(make_mut_arr_worker___void__ptr_mut_arr__ptr__char___nat____op_plus__arr__ptr__char__arr__ptr__char___arr__ptr__char___lambda0___closure__klb_op_plus__arr__ptr__char__arr__ptr__char___arr__ptr__char___lambda0_(_ctx, res, 0ull, f),
	res));
}
mut_arr__ptr__char* new_uninitialized_mut_arr__ptr_mut_arr__ptr__char__nat_(ctx* _ctx, nat size) {
	return _initmut_arr__ptr__char(alloc__ptr__byte__nat_(_ctx, 32), (mut_arr__ptr__char) {0, size, size, uninitialized_data__ptr__ptr__char__nat_(_ctx, size)});
}
_void make_mut_arr_worker___void__ptr_mut_arr__ptr__char___nat___map__arr__ptr__char__arr__arr__char___fun_mut1__ptr__char__arr__char__id10___lambda0___closure__klbmap__arr__ptr__char__arr__arr__char___fun_mut1__ptr__char__arr__char__id10___lambda0_(ctx* _ctx, mut_arr__ptr__char* m, nat i, map__arr__ptr__char__arr__arr__char___fun_mut1__ptr__char__arr__char__id10___lambda0___closure f) {
	return _op_equal_equal__bool__nat___nat_(i, m->size)
		? 0
		: (set_at___void__ptr_mut_arr__ptr__char___nat___ptr__char_(_ctx, m, i, map__arr__ptr__char__arr__arr__char___fun_mut1__ptr__char__arr__char__id10___lambda0_(_ctx, f, i)),
		make_mut_arr_worker___void__ptr_mut_arr__ptr__char___nat___map__arr__ptr__char__arr__arr__char___fun_mut1__ptr__char__arr__char__id10___lambda0___closure__klbmap__arr__ptr__char__arr__arr__char___fun_mut1__ptr__char__arr__char__id10___lambda0_(_ctx, m, incr__nat__nat_(_ctx, i), f));
}
bool _op_greater__bool___int____int_(_int a, _int b) {
	return !(_op_less_equal__bool___int____int_(a, b));
}
comparison _op_less_equal_greater__comparison__ptr_process_result___ptr_process_result_(process_result* a, process_result* b) {
	comparison _cmpstdout;
	comparison _matchedstdout;
	comparison _cmpstderr;
	comparison _matchedstderr;
	return ((_cmpstderr = ((_cmpstdout = _op_less_equal_greater__comparison__int32___int32_(a->exit_code, b->exit_code)),
	(_matchedstdout = _op_less_equal_greater__comparison__int32___int32_(a->exit_code, b->exit_code),
		_matchedstdout.kind == 0
		? _cmpstdout
		: _matchedstdout.kind == 1
		? _op_less_equal_greater__comparison__arr__char___arr__char_(a->stdout, b->stdout)
		: _matchedstdout.kind == 2
		? _cmpstdout
		: _failcomparison()))),
	(_matchedstderr = ((_cmpstdout = _op_less_equal_greater__comparison__int32___int32_(a->exit_code, b->exit_code)),
	(_matchedstdout = _op_less_equal_greater__comparison__int32___int32_(a->exit_code, b->exit_code),
		_matchedstdout.kind == 0
		? _cmpstdout
		: _matchedstdout.kind == 1
		? _op_less_equal_greater__comparison__arr__char___arr__char_(a->stdout, b->stdout)
		: _matchedstdout.kind == 2
		? _cmpstdout
		: _failcomparison())),
		_matchedstderr.kind == 0
		? _cmpstderr
		: _matchedstderr.kind == 1
		? _op_less_equal_greater__comparison__arr__char___arr__char_(a->stderr, b->stderr)
		: _matchedstderr.kind == 2
		? _cmpstderr
		: _failcomparison()));
}
bool contains_recur__q__bool__arr__arr__char___arr__char___nat_(arr__arr__char a, arr__char value, nat i) {
	return _op_equal_equal__bool__nat___nat_(i, a.size)
		? 0
		: (_op_equal_equal__bool__arr__char___arr__char_(noctx_at__arr__char__arr__arr__char___nat_(a, i), value) || contains_recur__q__bool__arr__arr__char___arr__char___nat_(a, value, noctx_incr__nat__nat_(i)));
}
_void each_with_index_recur___void__arr__arr__char___lint_file__arr__ptr_failure__arr__char___lambda0___closure__klblint_file__arr__ptr_failure__arr__char___lambda0___nat_(ctx* _ctx, arr__arr__char a, lint_file__arr__ptr_failure__arr__char___lambda0___closure f, nat n) {
	return _op_equal_equal__bool__nat___nat_(n, a.size)
		? 0
		: (lint_file__arr__ptr_failure__arr__char___lambda0__(_ctx, f, at__arr__char__arr__arr__char___nat_(_ctx, a, n), n),
		each_with_index_recur___void__arr__arr__char___lint_file__arr__ptr_failure__arr__char___lambda0___closure__klblint_file__arr__ptr_failure__arr__char___lambda0___nat_(_ctx, a, f, incr__nat__nat_(_ctx, n)));
}
cell__nat* new_cell__ptr_cell__nat__nat__id0_(ctx* _ctx) {
	return _initcell__nat(alloc__ptr__byte__nat_(_ctx, 8), (cell__nat) {0ull});
}
_void each_with_index___void__arr__char___lines__arr__arr__char__arr__char___lambda0___closure__klblines__arr__arr__char__arr__char___lambda0_(ctx* _ctx, arr__char a, lines__arr__arr__char__arr__char___lambda0___closure f) {
	return each_with_index_recur___void__arr__char___lines__arr__arr__char__arr__char___lambda0___closure__klblines__arr__arr__char__arr__char___lambda0___nat_(_ctx, a, f, 0ull);
}
arr__char slice_from_to__arr__char__arr__char___nat___nat_(ctx* _ctx, arr__char a, nat begin, nat end) {
	return (assert___void__bool_(_ctx, _op_less_equal__bool__nat___nat_(begin, end)),
	slice__arr__char__arr__char___nat___nat_(_ctx, a, begin, _op_minus__nat__nat___nat_(_ctx, end, begin)));
}
nat get__nat__ptr_cell__nat_(cell__nat* c) {
	return c->value;
}
bool zero__q__bool__int16_(int16 a) {
	return _op_equal_equal__bool__int16___int16_(a, 0);
}
_void unsafe_set_size___void__ptr_mut_arr__char___nat_(ctx* _ctx, mut_arr__char* a, nat new_size) {
	return (assert___void__bool_(_ctx, _op_less__bool__nat___nat_(new_size, a->capacity)),
	(a->size = new_size), 0);
}
_void make_mut_arr_worker___void__ptr_mut_arr__ptr__char___nat____op_plus__arr__ptr__char__arr__ptr__char___arr__ptr__char___lambda0___closure__klb_op_plus__arr__ptr__char__arr__ptr__char___arr__ptr__char___lambda0_(ctx* _ctx, mut_arr__ptr__char* m, nat i, _op_plus__arr__ptr__char__arr__ptr__char___arr__ptr__char___lambda0___closure f) {
	return _op_equal_equal__bool__nat___nat_(i, m->size)
		? 0
		: (set_at___void__ptr_mut_arr__ptr__char___nat___ptr__char_(_ctx, m, i, _op_plus__arr__ptr__char__arr__ptr__char___arr__ptr__char___lambda0_(_ctx, f, i)),
		make_mut_arr_worker___void__ptr_mut_arr__ptr__char___nat____op_plus__arr__ptr__char__arr__ptr__char___arr__ptr__char___lambda0___closure__klb_op_plus__arr__ptr__char__arr__ptr__char___arr__ptr__char___lambda0_(_ctx, m, incr__nat__nat_(_ctx, i), f));
}
_void set_at___void__ptr_mut_arr__ptr__char___nat___ptr__char_(ctx* _ctx, mut_arr__ptr__char* a, nat index, ptr__char value) {
	return (assert___void__bool_(_ctx, _op_less__bool__nat___nat_(index, a->size)),
	noctx_set_at___void__ptr_mut_arr__ptr__char___nat___ptr__char_(a, index, value));
}
ptr__char map__arr__ptr__char__arr__arr__char___fun_mut1__ptr__char__arr__char__id10___lambda0_(ctx* _ctx, map__arr__ptr__char__arr__arr__char___fun_mut1__ptr__char__arr__char__id10___lambda0___closure _closure, nat i) {
	return convert_args__ptr__ptr__char__ptr__char___arr__arr__char___lambda0_(_ctx, at__arr__char__arr__arr__char___nat_(_ctx, _closure.a, i));
}
bool _op_less_equal__bool___int____int_(_int a, _int b) {
	return !(_op_less__bool___int____int_(b, a));
}
_void lint_file__arr__ptr_failure__arr__char___lambda0__(ctx* _ctx, lint_file__arr__ptr_failure__arr__char___lambda0___closure _closure, arr__char line, nat line_num) {
	arr__char ln;
	arr__char message;
	nat width;
	arr__char message1;
	return ((ln = to_str__arr__char__nat_(_ctx, incr__nat__nat_(_ctx, line_num))),
	((!(_closure.err_file__q) && contains_subsequence__q__bool__arr__char___arr__char_(_ctx, lstrip__arr__char__arr__char_(_ctx, line), (arr__char) _constant____arr__char__92))
		? ((message = _op_plus__arr__char__arr__char___arr__char_(_ctx, _op_plus__arr__char__arr__char___arr__char_(_ctx, (arr__char) _constant____arr__char__93, ln), (arr__char) _constant____arr__char__94)),
		push___void__ptr_mut_arr__ptr_failure___ptr_failure_(_ctx, _closure.res, _initfailure(alloc__ptr__byte__nat_(_ctx, 32), (failure) {_closure.path, message})))
		: 0,
	((width = line_len__nat__arr__char_(_ctx, line)),
	_op_greater__bool__nat___nat_(width, 120ull)
		? ((message1 = _op_plus__arr__char__arr__char___arr__char_(_ctx, _op_plus__arr__char__arr__char___arr__char_(_ctx, _op_plus__arr__char__arr__char___arr__char_(_ctx, _op_plus__arr__char__arr__char___arr__char_(_ctx, _op_plus__arr__char__arr__char___arr__char_(_ctx, (arr__char) _constant____arr__char__93, ln), (arr__char) _constant____arr__char__100), to_str__arr__char__nat_(_ctx, width)), (arr__char) _constant____arr__char__101), to_str__arr__char__nat__id120_(_ctx))),
		push___void__ptr_mut_arr__ptr_failure___ptr_failure_(_ctx, _closure.res, _initfailure(alloc__ptr__byte__nat_(_ctx, 32), (failure) {_closure.path, message1})))
		: 0)));
}
_void each_with_index_recur___void__arr__char___lines__arr__arr__char__arr__char___lambda0___closure__klblines__arr__arr__char__arr__char___lambda0___nat_(ctx* _ctx, arr__char a, lines__arr__arr__char__arr__char___lambda0___closure f, nat n) {
	return _op_equal_equal__bool__nat___nat_(n, a.size)
		? 0
		: (lines__arr__arr__char__arr__char___lambda0__(_ctx, f, at__char__arr__char___nat_(_ctx, a, n), n),
		each_with_index_recur___void__arr__char___lines__arr__arr__char__arr__char___lambda0___closure__klblines__arr__arr__char__arr__char___lambda0___nat_(_ctx, a, f, incr__nat__nat_(_ctx, n)));
}
bool _op_equal_equal__bool__int16___int16_(int16 a, int16 b) {
	comparison matched;
	return (matched = _op_less_equal_greater__comparison__int16___int16_(a, b),
		matched.kind == 0
		? 0
		: matched.kind == 1
		? 1
		: matched.kind == 2
		? 0
		: _failbool());
}
ptr__char _op_plus__arr__ptr__char__arr__ptr__char___arr__ptr__char___lambda0_(ctx* _ctx, _op_plus__arr__ptr__char__arr__ptr__char___arr__ptr__char___lambda0___closure _closure, nat i) {
	return _op_less__bool__nat___nat_(i, _closure.a.size)
		? at__ptr__char__arr__ptr__char___nat_(_ctx, _closure.a, i)
		: at__ptr__char__arr__ptr__char___nat_(_ctx, _closure.b, _op_minus__nat__nat___nat_(_ctx, i, _closure.a.size));
}
_void noctx_set_at___void__ptr_mut_arr__ptr__char___nat___ptr__char_(mut_arr__ptr__char* a, nat index, ptr__char value) {
	return (hard_assert___void__bool_(_op_less__bool__nat___nat_(index, a->size)),
	((*((a->data + index)) = value), 0));
}
ptr__char convert_args__ptr__ptr__char__ptr__char___arr__arr__char___lambda0_(ctx* _ctx, arr__char it) {
	return to_c_str__ptr__char__arr__char_(_ctx, it);
}
bool contains_subsequence__q__bool__arr__char___arr__char_(ctx* _ctx, arr__char a, arr__char subseq) {
	return (starts_with__q__bool__arr__char___arr__char_(_ctx, a, subseq) || (has__q__bool__arr__char_(a) && starts_with__q__bool__arr__char___arr__char_(_ctx, tail__arr__char__arr__char_(_ctx, a), subseq)));
}
arr__char lstrip__arr__char__arr__char_(ctx* _ctx, arr__char a) {
	return (has__q__bool__arr__char_(a) && _op_equal_equal__bool__char___char_(first__char__arr__char_(_ctx, a), ' '))
		? lstrip__arr__char__arr__char_(_ctx, tail__arr__char__arr__char_(_ctx, a))
		: a;
}
nat line_len__nat__arr__char_(ctx* _ctx, arr__char line) {
	return _op_plus__nat__nat___nat_(_ctx, _op_times__nat__nat___nat_(_ctx, n_tabs__nat__arr__char_(_ctx, line), 3ull), line.size);
}
arr__char to_str__arr__char__nat__id120_(ctx* _ctx) {
	arr__char hi;
	return ((hi = to_str__arr__char__nat__id12_(_ctx)),
	_op_plus__arr__char__arr__char___arr__char_(_ctx, hi, (arr__char) _constant____arr__char__21));
}
_void lines__arr__arr__char__arr__char___lambda0__(ctx* _ctx, lines__arr__arr__char__arr__char___lambda0___closure _closure, char c, nat index) {
	return _op_equal_equal__bool__char___char_(c, '\n')
		? push___void__ptr_mut_arr__arr__char___arr__char_(_ctx, _closure.res, slice_from_to__arr__char__arr__char___nat___nat_(_ctx, _closure.s, swap__nat__ptr_cell__nat___nat_(_closure.last_nl, incr__nat__nat_(_ctx, index)), index))
		: 0;
}
comparison _op_less_equal_greater__comparison__int16___int16_(int16 a, int16 b) {
	return (a < b)
		? (comparison) { 0, .as_less = (less) { 0 } }
		: (b < a)
			? (comparison) { 2, .as_greater = (greater) { 0 } }
			: (comparison) { 1, .as_equal = (equal) { 0 } };
}
bool has__q__bool__arr__char_(arr__char a) {
	return !(empty__q__bool__arr__char_(a));
}
nat n_tabs__nat__arr__char_(ctx* _ctx, arr__char line) {
	return (!(empty__q__bool__arr__char_(line)) && _op_equal_equal__bool__char___char_(first__char__arr__char_(_ctx, line), '\t'))
		? incr__nat__nat_(_ctx, n_tabs__nat__arr__char_(_ctx, tail__arr__char__arr__char_(_ctx, line)))
		: 0ull;
}
arr__char to_str__arr__char__nat__id12_(ctx* _ctx) {
	return _op_plus__arr__char__arr__char__id23___arr__char__id29_(_ctx);
}
nat swap__nat__ptr_cell__nat___nat_(cell__nat* c, nat v) {
	nat res;
	return ((res = get__nat__ptr_cell__nat_(c)),
	(set___void__ptr_cell__nat___nat_(c, v),
	res));
}
arr__char _op_plus__arr__char__arr__char__id23___arr__char__id29_(ctx* _ctx) {
	return make_arr__arr__char__nat____op_plus__arr__char__arr__char__id23___arr__char__id29___lambda0___closure__klb_op_plus__arr__char__arr__char__id23___arr__char__id29___lambda0_(_ctx, 2ull, (_op_plus__arr__char__arr__char__id23___arr__char__id29___lambda0___closure) {(arr__char) _constant____arr__char__23, (arr__char) _constant____arr__char__29});
}
_void set___void__ptr_cell__nat___nat_(cell__nat* c, nat v) {
	return (c->value = v), 0;
}
arr__char make_arr__arr__char__nat____op_plus__arr__char__arr__char__id23___arr__char__id29___lambda0___closure__klb_op_plus__arr__char__arr__char__id23___arr__char__id29___lambda0_(ctx* _ctx, nat size, _op_plus__arr__char__arr__char__id23___arr__char__id29___lambda0___closure f) {
	return freeze__arr__char__ptr_mut_arr__char_(make_mut_arr__ptr_mut_arr__char__nat____op_plus__arr__char__arr__char__id23___arr__char__id29___lambda0___closure__klb_op_plus__arr__char__arr__char__id23___arr__char__id29___lambda0_(_ctx, size, f));
}
mut_arr__char* make_mut_arr__ptr_mut_arr__char__nat____op_plus__arr__char__arr__char__id23___arr__char__id29___lambda0___closure__klb_op_plus__arr__char__arr__char__id23___arr__char__id29___lambda0_(ctx* _ctx, nat size, _op_plus__arr__char__arr__char__id23___arr__char__id29___lambda0___closure f) {
	mut_arr__char* res;
	return ((res = new_uninitialized_mut_arr__ptr_mut_arr__char__nat_(_ctx, size)),
	(make_mut_arr_worker___void__ptr_mut_arr__char___nat____op_plus__arr__char__arr__char__id23___arr__char__id29___lambda0___closure__klb_op_plus__arr__char__arr__char__id23___arr__char__id29___lambda0_(_ctx, res, 0ull, f),
	res));
}
_void make_mut_arr_worker___void__ptr_mut_arr__char___nat____op_plus__arr__char__arr__char__id23___arr__char__id29___lambda0___closure__klb_op_plus__arr__char__arr__char__id23___arr__char__id29___lambda0_(ctx* _ctx, mut_arr__char* m, nat i, _op_plus__arr__char__arr__char__id23___arr__char__id29___lambda0___closure f) {
	return _op_equal_equal__bool__nat___nat_(i, m->size)
		? 0
		: (set_at___void__ptr_mut_arr__char___nat___char_(_ctx, m, i, _op_plus__arr__char__arr__char__id23___arr__char__id29___lambda0_(_ctx, f, i)),
		make_mut_arr_worker___void__ptr_mut_arr__char___nat____op_plus__arr__char__arr__char__id23___arr__char__id29___lambda0___closure__klb_op_plus__arr__char__arr__char__id23___arr__char__id29___lambda0_(_ctx, m, incr__nat__nat_(_ctx, i), f));
}
char _op_plus__arr__char__arr__char__id23___arr__char__id29___lambda0_(ctx* _ctx, _op_plus__arr__char__arr__char__id23___arr__char__id29___lambda0___closure _closure, nat i) {
	return _op_less__bool__nat___nat_(i, _closure.a.size)
		? at__char__arr__char___nat_(_ctx, _closure.a, i)
		: at__char__arr__char___nat_(_ctx, _closure.b, _op_minus__nat__nat___nat_(_ctx, i, _closure.a.size));
}


int main(int argc, char** argv) {
	assert(sizeof(int32) == 4);
	assert(sizeof(ptr__ptr__char) == 8);
	assert(sizeof(fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char) == 8);
	assert(sizeof(global_ctx) == 56);
	assert(sizeof(vat) == 160);
	assert(sizeof(arr__ptr_vat) == 16);
	assert(sizeof(exception_ctx) == 24);
	assert(sizeof(thread_local_stuff) == 8);
	assert(sizeof(ctx) == 40);
	assert(sizeof(fun2__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char) == 16);
	assert(sizeof(arr__ptr__char) == 16);
	assert(sizeof(fut__int32) == 32);
	assert(sizeof(ok__int32) == 4);
	assert(sizeof(err__exception) == 16);
	assert(sizeof(result__int32__exception) == 24);
	assert(sizeof(ptr__char) == 8);
	assert(sizeof(arr__arr__char) == 16);
	assert(sizeof(lock) == 1);
	assert(sizeof(nat) == 8);
	assert(sizeof(condition) == 16);
	assert(sizeof(bool) == 1);
	assert(sizeof(gc) == 48);
	assert(sizeof(mut_bag__task) == 16);
	assert(sizeof(mut_arr__nat) == 32);
	assert(sizeof(thread_safe_counter) == 16);
	assert(sizeof(fun_mut1___void__exception) == 16);
	assert(sizeof(ptr__ptr_vat) == 8);
	assert(sizeof(ptr__jmp_buf_tag) == 8);
	assert(sizeof(exception) == 16);
	assert(sizeof(ptr__byte) == 8);
	assert(sizeof(fun_ptr4__ptr_fut__int32__ptr_ctx__ptr__byte__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char) == 8);
	assert(sizeof(fut_state__int32) == 24);
	assert(sizeof(char) == 1);
	assert(sizeof(ptr__arr__char) == 8);
	assert(sizeof(_atomic_bool) == 1);
	assert(sizeof(opt__ptr_gc_ctx) == 16);
	assert(sizeof(opt__ptr_mut_bag_node__task) == 16);
	assert(sizeof(ptr__nat) == 8);
	assert(sizeof(fun_ptr3___void__ptr_ctx__ptr__byte__exception) == 8);
	assert(sizeof(jmp_buf_tag) == 200);
	assert(sizeof(arr__char) == 16);
	assert(sizeof(byte) == 1);
	assert(sizeof(fut_state_callbacks__int32) == 16);
	assert(sizeof(fut_state_resolved__int32) == 4);
	assert(sizeof(none) == 1);
	assert(sizeof(some__ptr_gc_ctx) == 8);
	assert(sizeof(some__ptr_mut_bag_node__task) == 8);
	assert(sizeof(_void) == 1);
	assert(sizeof(bytes64) == 64);
	assert(sizeof(bytes128) == 128);
	assert(sizeof(opt__ptr_fut_callback_node__int32) == 16);
	assert(sizeof(gc_ctx) == 24);
	assert(sizeof(mut_bag_node__task) == 40);
	assert(sizeof(bytes32) == 32);
	assert(sizeof(some__ptr_fut_callback_node__int32) == 8);
	assert(sizeof(task) == 24);
	assert(sizeof(bytes16) == 16);
	assert(sizeof(fut_callback_node__int32) == 32);
	assert(sizeof(fun_mut0___void) == 16);
	assert(sizeof(fun_mut1___void__result__int32__exception) == 16);
	assert(sizeof(fun_ptr2___void__ptr_ctx__ptr__byte) == 8);
	assert(sizeof(fun_ptr3___void__ptr_ctx__ptr__byte__result__int32__exception) == 8);
	assert(sizeof(opt__test_options) == 24);
	assert(sizeof(some__test_options) == 16);
	assert(sizeof(test_options) == 16);
	assert(sizeof(_int) == 8);
	assert(sizeof(fun_ptr2___void__nat__ptr_global_ctx) == 8);
	assert(sizeof(ptr__thread_args__ptr_global_ctx) == 8);
	assert(sizeof(thread_args__ptr_global_ctx) == 24);
	assert(sizeof(parsed_cmd_line_args) == 40);
	assert(sizeof(mut_arr__opt__arr__arr__char) == 32);
	assert(sizeof(cell__bool) == 1);
	assert(sizeof(dict__arr__char__arr__arr__char) == 32);
	assert(sizeof(ptr__opt__arr__arr__char) == 8);
	assert(sizeof(arr__arr__arr__char) == 16);
	assert(sizeof(opt__arr__arr__char) == 24);
	assert(sizeof(ptr__arr__arr__char) == 8);
	assert(sizeof(some__arr__arr__char) == 16);
	assert(sizeof(dict__arr__char__arr__char) == 32);
	assert(sizeof(result__arr__char__arr__ptr_failure) == 24);
	assert(sizeof(ok__arr__char) == 16);
	assert(sizeof(err__arr__ptr_failure) == 16);
	assert(sizeof(arr__ptr_failure) == 16);
	assert(sizeof(ptr__ptr_failure) == 8);
	assert(sizeof(failure) == 32);
	assert(sizeof(fun_ref0__int32) == 32);
	assert(sizeof(vat_and_actor_id) == 16);
	assert(sizeof(fun_mut0__ptr_fut__int32) == 16);
	assert(sizeof(fun_ptr2__ptr_fut__int32__ptr_ctx__ptr__byte) == 8);
	assert(sizeof(ok__chosen_task) == 40);
	assert(sizeof(err__no_chosen_task) == 1);
	assert(sizeof(result__chosen_task__no_chosen_task) == 48);
	assert(sizeof(chosen_task) == 40);
	assert(sizeof(no_chosen_task) == 1);
	assert(sizeof(opt__task) == 32);
	assert(sizeof(some__task) == 24);
	assert(sizeof(some__nat) == 8);
	assert(sizeof(opt__nat) == 16);
	assert(sizeof(parse_cmd_line_args__opt__test_options__arr__arr__char___arr__arr__char___fun1__test_options__arr__opt__arr__arr__char__id5___lambda0___closure) == 32);
	assert(sizeof(arr__opt__arr__arr__char) == 16);
	assert(sizeof(mut_dict__arr__char__arr__char) == 16);
	assert(sizeof(mut_arr__arr__char) == 32);
	assert(sizeof(do_test__int32__test_options___lambda0___closure) == 56);
	assert(sizeof(do_test__int32__test_options___lambda1___closure) == 32);
	assert(sizeof(fut___void) == 32);
	assert(sizeof(fun_ref1__int32___void) == 32);
	assert(sizeof(fut_state___void) == 24);
	assert(sizeof(fun_mut1__ptr_fut__int32___void) == 16);
	assert(sizeof(fut_state_callbacks___void) == 16);
	assert(sizeof(fut_state_resolved___void) == 1);
	assert(sizeof(fun_ptr3__ptr_fut__int32__ptr_ctx__ptr__byte___void) == 8);
	assert(sizeof(opt__ptr_fut_callback_node___void) == 16);
	assert(sizeof(some__ptr_fut_callback_node___void) == 8);
	assert(sizeof(fut_callback_node___void) == 32);
	assert(sizeof(fun_mut1___void__result___void__exception) == 16);
	assert(sizeof(fun_ptr3___void__ptr_ctx__ptr__byte__result___void__exception) == 8);
	assert(sizeof(result___void__exception) == 24);
	assert(sizeof(ok___void) == 1);
	assert(sizeof(add_first_task__ptr_fut__int32__arr__ptr__char___fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char___lambda0___closure) == 24);
	assert(sizeof(comparison) == 8);
	assert(sizeof(less) == 1);
	assert(sizeof(equal) == 1);
	assert(sizeof(greater) == 1);
	assert(sizeof(cell__nat) == 8);
	assert(sizeof(fun_ptr1__ptr__byte__ptr__byte) == 8);
	assert(sizeof(cell__ptr__byte) == 8);
	assert(sizeof(some__chosen_task) == 40);
	assert(sizeof(opt__chosen_task) == 48);
	assert(sizeof(mut_dict__arr__char__arr__arr__char) == 16);
	assert(sizeof(mut_arr__arr__arr__char) == 32);
	assert(sizeof(fill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat___opt__arr__arr__char___lambda0___closure) == 24);
	assert(sizeof(some__ptr__byte) == 8);
	assert(sizeof(opt__ptr__byte) == 16);
	assert(sizeof(mut_arr__char) == 32);
	assert(sizeof(run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure) == 40);
	assert(sizeof(mut_arr__ptr_failure) == 32);
	assert(sizeof(first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda0___closure__klbdo_test__int32__test_options___lambda0___lambda0___closure) == 56);
	assert(sizeof(first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda1___closure__klbdo_test__int32__test_options___lambda1___lambda0___closure) == 32);
	assert(sizeof(then2__ptr_fut__int32__ptr_fut___void___fun_ref0__int32___lambda0___closure) == 32);
	assert(sizeof(some__opt__task) == 32);
	assert(sizeof(opt__opt__task) == 40);
	assert(sizeof(r_index_of__opt__nat__arr__char___char___lambda0___closure) == 1);
	assert(sizeof(_op_plus__arr__char__arr__char___arr__char___lambda0___closure) == 32);
	assert(sizeof(key_value_pair__arr__char__arr__char) == 32);
	assert(sizeof(list_compile_error_tests__arr__arr__char__arr__char___lambda0___closure) == 8);
	assert(sizeof(flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure__klbrun_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___lambda0___closure) == 56);
	assert(sizeof(then__ptr_fut__int32__ptr_fut___void___fun_ref1__int32___void___lambda0___closure) == 40);
	assert(sizeof(map__arr__arr__char__arr__ptr__char___fun_mut1__arr__char__ptr__char__id1___lambda0___closure) == 16);
	assert(sizeof(index_of__opt__nat__arr__arr__char___arr__char___lambda0___closure) == 16);
	assert(sizeof(each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id9___list_compile_error_tests__arr__arr__char__arr__char___lambda0___closure__klblist_compile_error_tests__arr__arr__char__arr__char___lambda0___lambda0___closure) == 24);
	assert(sizeof(first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda0___closure__klbdo_test__int32__test_options___lambda0___lambda0___lambda0___closure) == 16);
	assert(sizeof(first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure___do_test__int32__test_options___lambda1___closure__klbdo_test__int32__test_options___lambda1___lambda0___lambda0___closure) == 16);
	assert(sizeof(call__ptr_fut__int32__fun_ref0__int32___lambda0___closure) == 40);
	assert(sizeof(opt__task_and_nodes) == 48);
	assert(sizeof(some__task_and_nodes) == 40);
	assert(sizeof(task_and_nodes) == 40);
	assert(sizeof(opt__arr__char) == 24);
	assert(sizeof(some__arr__char) == 16);
	assert(sizeof(some__ptr_stat_t) == 8);
	assert(sizeof(opt__ptr_stat_t) == 16);
	assert(sizeof(stat_t) == 152);
	assert(sizeof(nat32) == 4);
	assert(sizeof(ptr__bool) == 8);
	assert(sizeof(call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda0___closure) == 40);
	assert(sizeof(call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda1___closure) == 8);
	assert(sizeof(dirent) == 280);
	assert(sizeof(cell__ptr_dirent) == 8);
	assert(sizeof(nat16) == 2);
	assert(sizeof(bytes256) == 256);
	assert(sizeof(push_all___void__ptr_mut_arr__ptr_failure___arr__ptr_failure___lambda0___closure) == 8);
	assert(sizeof(process_result) == 40);
	assert(sizeof(run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure) == 40);
	assert(sizeof(lint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___closure) == 16);
	assert(sizeof(forward_to___void__ptr_fut__int32___ptr_fut__int32___lambda0___closure) == 8);
	assert(sizeof(call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0___closure) == 48);
	assert(sizeof(list_runnable_tests__arr__arr__char__arr__char___lambda0___closure) == 8);
	assert(sizeof(flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___closure__klbrun_runnable_tests__result__arr__char__arr__ptr_failure__arr__char___arr__char___ptr_dict__arr__char__arr__char___test_options___lambda0___lambda0___closure) == 56);
	assert(sizeof(list_lintable_files__arr__arr__char__arr__char___lambda1___closure) == 8);
	assert(sizeof(flat_map_with_max_size__arr__ptr_failure__arr__arr__char___nat___lint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___closure__klblint__result__arr__char__arr__ptr_failure__arr__char___test_options___lambda0___lambda0___closure) == 32);
	assert(sizeof(call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda0___closure) == 48);
	assert(sizeof(call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda1___closure) == 8);
	assert(sizeof(arr__nat) == 16);
	assert(sizeof(to_mut_arr__ptr_mut_arr__arr__char__arr__arr__char___lambda0___closure) == 16);
	assert(sizeof(mut_slice__arr__char) == 24);
	assert(sizeof(pipes) == 8);
	assert(sizeof(posix_spawn_file_actions_t) == 80);
	assert(sizeof(cell__int32) == 4);
	assert(sizeof(mut_arr__ptr__char) == 32);
	assert(sizeof(each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id9___list_runnable_tests__arr__arr__char__arr__char___lambda0___closure__klblist_runnable_tests__arr__arr__char__arr__char___lambda0___lambda0___closure) == 24);
	assert(sizeof(each_child_recursive___void__arr__char___fun_mut1__bool__arr__char__id11___list_lintable_files__arr__arr__char__arr__char___lambda1___closure__klblist_lintable_files__arr__arr__char__arr__char___lambda1___lambda0___closure) == 24);
	assert(sizeof(arr__pollfd) == 16);
	assert(sizeof(pollfd) == 8);
	assert(sizeof(handle_revents_result) == 2);
	assert(sizeof(ptr__pollfd) == 8);
	assert(sizeof(int16) == 2);
	assert(sizeof(convert_environ__ptr__ptr__char__ptr_dict__arr__char__arr__char___lambda0___closure) == 8);
	assert(sizeof(map__arr__ptr__char__arr__arr__char___fun_mut1__ptr__char__arr__char__id10___lambda0___closure) == 16);
	assert(sizeof(_op_plus__arr__ptr__char__arr__ptr__char___arr__ptr__char___lambda0___closure) == 32);
	assert(sizeof(lint_file__arr__ptr_failure__arr__char___lambda0___closure) == 32);
	assert(sizeof(lines__arr__arr__char__arr__char___lambda0___closure) == 32);
	assert(sizeof(_op_plus__arr__char__arr__char__id23___arr__char__id29___lambda0___closure) == 32);

	return rt_main__int32__int32___ptr__ptr__char___fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char_(argc, argv, main__ptr_fut__int32__arr__arr__char_);
}
