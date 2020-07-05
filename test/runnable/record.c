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
typedef int64_t _int;
typedef _void (*fun_ptr2___void__nat__ptr_global_ctx)(nat, global_ctx*);
typedef struct thread_args__ptr_global_ctx thread_args__ptr_global_ctx;
struct thread_args__ptr_global_ctx {
	fun_ptr2___void__nat__ptr_global_ctx fun;
	nat thread_id;
	global_ctx* arg;
};
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
typedef struct some__ptr__byte some__ptr__byte;
typedef struct opt__ptr__byte opt__ptr__byte;
typedef struct then2__ptr_fut__int32__ptr_fut___void___fun_ref0__int32___lambda0___closure then2__ptr_fut__int32__ptr_fut___void___fun_ref0__int32___lambda0___closure;
typedef struct some__opt__task some__opt__task;
typedef struct opt__opt__task opt__opt__task;
typedef struct then__ptr_fut__int32__ptr_fut___void___fun_ref1__int32___void___lambda0___closure then__ptr_fut__int32__ptr_fut___void___fun_ref1__int32___void___lambda0___closure;
typedef struct map__arr__arr__char__arr__ptr__char___fun_mut1__arr__char__ptr__char__id1___lambda0___closure map__arr__arr__char__arr__ptr__char___fun_mut1__arr__char__ptr__char__id1___lambda0___closure;
typedef struct call__ptr_fut__int32__fun_ref0__int32___lambda0___closure call__ptr_fut__int32__fun_ref0__int32___lambda0___closure;
typedef struct mut_arr__arr__char mut_arr__arr__char;
typedef struct opt__task_and_nodes opt__task_and_nodes;
typedef struct some__task_and_nodes some__task_and_nodes;
typedef struct task_and_nodes task_and_nodes;
typedef bool* ptr__bool;
typedef struct call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda0___closure call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda0___closure;
typedef struct call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda1___closure call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda1___closure;
struct call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda1___closure {
	fut__int32* res;
};
typedef struct forward_to___void__ptr_fut__int32___ptr_fut__int32___lambda0___closure forward_to___void__ptr_fut__int32___ptr_fut__int32___lambda0___closure;
struct forward_to___void__ptr_fut__int32___ptr_fut__int32___lambda0___closure {
	fut__int32* to;
};
typedef struct call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0___closure call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0___closure;
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
typedef thread_args__ptr_global_ctx* ptr__thread_args__ptr_global_ctx;
typedef fut__int32* (*fun_ptr2__ptr_fut__int32__ptr_ctx__ptr__byte)(ctx*, ptr__byte);
struct err__no_chosen_task {
	no_chosen_task value;
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
struct fun_mut0__ptr_fut__int32 {
	fun_ptr2__ptr_fut__int32__ptr_ctx__ptr__byte fun_ptr;
	ptr__byte closure;
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
struct mut_arr__arr__char {
	bool frozen__q;
	nat size;
	nat capacity;
	ptr__arr__char data;
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
struct fun_ref0__int32 {
	vat_and_actor_id vat_and_actor;
	fun_mut0__ptr_fut__int32 fun;
};
struct some__task {
	task value;
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
struct chosen_task {
	vat* vat;
	opt__task task_or_gc;
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
#define _constant____arr__char__5 { 0ull, NULL }
#define _constant____exception__0 { _constant____arr__char__5 }
static char _constantArrBacking4[1] = "\n";
#define _constant____arr__char__4 { 1ull, (_constantArrBacking4 + 0) }
#define _constant____fut_state_resolved__int32__0 { 0 }
#define _constant__fut_state__int32__1 { 1, .as_fut_state_resolved__int32 = _constant____fut_state_resolved__int32__0 }
#define _constant____none__0 { 0 }
#define _constant__opt__ptr_gc_ctx__0 { 0, .as_none = _constant____none__0 }
#define _constant__opt__ptr_mut_bag_node__task__0 { 0, .as_none = _constant____none__0 }
static char _constantArrBacking1[20] = "uncaught exception: ";
#define _constant____arr__char__1 { 20ull, (_constantArrBacking1 + 0) }
static char _constantArrBacking3[17] = "<<empty message>>";
#define _constant____arr__char__3 { 17ull, (_constantArrBacking3 + 0) }
#define _constant____fut_state_resolved___void__0 { 0 }
#define _constant__fut_state___void__0 { 1, .as_fut_state_resolved___void = _constant____fut_state_resolved___void__0 }
#define _constant__opt__chosen_task__0 { 0, .as_none = _constant____none__0 }
#define _constant__opt__ptr_fut_callback_node__int32__0 { 0, .as_none = _constant____none__0 }
#define _constant____fut_state_callbacks__int32__0 { _constant__opt__ptr_fut_callback_node__int32__0 }
#define _constant__fut_state__int32__0 { 0, .as_fut_state_callbacks__int32 = _constant____fut_state_callbacks__int32__0 }
static char _constantArrBacking7[13] = "forbid failed";
#define _constant____arr__char__7 { 13ull, (_constantArrBacking7 + 0) }
#define _constant__opt__task__0 { 0, .as_none = _constant____none__0 }
#define _constant____some__opt__task__0 { _constant__opt__task__0 }
#define _constant__opt__opt__task__0 { 1, .as_some__opt__task = _constant____some__opt__task__0 }
#define _constant__opt__opt__task__1 { 0, .as_none = _constant____none__0 }
static char _constantArrBacking8[13] = "assert failed";
#define _constant____arr__char__8 { 13ull, (_constantArrBacking8 + 0) }
#define _constant__opt__task_and_nodes__0 { 0, .as_none = _constant____none__0 }
#define _constant____bytes16__0 { 0ull, 0ull }
#define _constant____bytes32__0 { _constant____bytes16__0, _constant____bytes16__0 }
#define _constant____bytes64__0 { _constant____bytes32__0, _constant____bytes32__0 }
#define _constant____bytes128__0 { _constant____bytes64__0, _constant____bytes64__0 }
#define _constant____jmp_buf_tag__0 { _constant____bytes64__0, 0, _constant____bytes128__0 }

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


call__ptr_fut__int32__fun_ref0__int32___lambda0___closure* _initcall__ptr_fut__int32__fun_ref0__int32___lambda0___closure(byte* out, call__ptr_fut__int32__fun_ref0__int32___lambda0___closure value) {
	call__ptr_fut__int32__fun_ref0__int32___lambda0___closure* res = (call__ptr_fut__int32__fun_ref0__int32___lambda0___closure*) out;
	*res = value;
	return res;
}
call__ptr_fut__int32__fun_ref0__int32___lambda0___closure _failcall__ptr_fut__int32__fun_ref0__int32___lambda0___closure() {
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
fut__int32* resolved__ptr_fut__int32__int32__id0_(ctx* _ctx);
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
ptr__byte alloc__ptr__byte__nat_(ctx* _ctx, nat size);
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
ptr__byte gc_alloc__ptr__byte__ptr_gc___nat_(ctx* _ctx, gc* gc, nat size);
gc* get_gc__ptr_gc(ctx* _ctx);
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
bool zero__q__bool__nat_(nat n);
nat wrap_sub__nat__nat___nat_(nat a, nat b);
vat* noctx_at__ptr_vat__arr__ptr_vat___nat_(arr__ptr_vat a, nat index);
bool empty__q__bool__ptr_mut_bag__task_(mut_bag__task* m);
mut_bag__task* ref_of_val__ptr_mut_bag__task__mut_bag__task_(mut_bag__task b);
_void if___void__bool____void____void_(bool cond, _void if_true, _void if_false);
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
opt__ptr__byte try_gc_alloc__opt__ptr__byte__ptr_gc___nat_(gc* gc, nat size);
ptr__byte todo__ptr__byte();
gc_ctx* get_gc_ctx__ptr_gc_ctx(ctx* _ctx);
global_ctx* as_ref__ptr_global_ctx__ptr__byte_(ptr__byte p);
bool try_acquire_lock__bool__ptr_lock_(lock* l);
_void hard_fail___void__arr__char__id6_();
bool try_unset__bool__ptr__atomic_bool_(_atomic_bool* a);
fut__int32* new_unresolved_fut__ptr_fut__int32(ctx* _ctx);
_void then_void___void__ptr_fut___void___then__ptr_fut__int32__ptr_fut___void___fun_ref1__int32___void___lambda0___closure__klbthen__ptr_fut__int32__ptr_fut___void___fun_ref1__int32___void___lambda0_(ctx* _ctx, fut___void* f, then__ptr_fut__int32__ptr_fut___void___fun_ref1__int32___void___lambda0___closure cb);
fut__int32* call__ptr_fut__int32__fun_ref0__int32_(ctx* _ctx, fun_ref0__int32 f);
_void forbid___void__bool_(ctx* _ctx, bool condition);
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
some__ptr__byte some__some__ptr__byte__ptr__byte_(ptr__byte t);
ptr__byte hard_fail__ptr__byte__arr__char__id2_();
bool try_set__bool__ptr__atomic_bool_(_atomic_bool* a);
bool try_change__bool__ptr__atomic_bool___bool_(_atomic_bool* a, bool old_value);
some__ptr_fut_callback_node___void some__some__ptr_fut_callback_node___void__ptr_fut_callback_node___void_(fut_callback_node___void* t);
_void then__ptr_fut__int32__ptr_fut___void___fun_ref1__int32___void___lambda0___dynamic(ctx* _ctx, then__ptr_fut__int32__ptr_fut___void___fun_ref1__int32___void___lambda0___closure* _closure, result___void__exception result);
_void then__ptr_fut__int32__ptr_fut___void___fun_ref1__int32___void___lambda0_(ctx* _ctx, then__ptr_fut__int32__ptr_fut___void___fun_ref1__int32___void___lambda0___closure _closure, result___void__exception result);
ok___void ok__ok___void___void_(_void t);
vat* get_vat__ptr_vat__nat_(ctx* _ctx, nat vat_id);
_void add_task___void__ptr_vat___task_(ctx* _ctx, vat* v, task t);
_void call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic(ctx* _ctx, call__ptr_fut__int32__fun_ref0__int32___lambda0___closure* _closure);
_void forbid___void__bool___arr__char_(ctx* _ctx, bool condition, arr__char message);
_void assert___void__bool_(ctx* _ctx, bool condition);
arr__ptr__char slice__arr__ptr__char__arr__ptr__char___nat___nat_(ctx* _ctx, arr__ptr__char a, nat begin, nat size);
nat _op_minus__nat__nat___nat_(ctx* _ctx, nat a, nat b);
arr__arr__char freeze__arr__arr__char__ptr_mut_arr__arr__char_(mut_arr__arr__char* a);
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
bool compare_exchange_strong__bool__ptr__bool___ptr__bool___bool_(ptr__bool value_ptr, ptr__bool expected_ptr, bool desired);
ptr__bool ptr_to__ptr__bool__bool_(bool t);
_void forward_to___void__ptr_fut__int32___ptr_fut__int32_(ctx* _ctx, fut__int32* from, fut__int32* to);
fut__int32* call__ptr_fut__int32__fun_ref1__int32___void____void_(ctx* _ctx, fun_ref1__int32___void f, _void p0);
_void reject___void__ptr_fut__int32___exception_(ctx* _ctx, fut__int32* f, exception e);
vat* at__ptr_vat__arr__ptr_vat___nat_(ctx* _ctx, arr__ptr_vat a, nat index);
mut_bag_node__task* new_mut_bag_node__ptr_mut_bag_node__task__task_(ctx* _ctx, task value);
_void add___void__ptr_mut_bag__task___ptr_mut_bag_node__task_(mut_bag__task* bag, mut_bag_node__task* node);
_void catch___void__call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda0___closure__klbcall__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda0___call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda1___closure__klbcall__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda1_(ctx* _ctx, call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda0___closure try, call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda1___closure catcher);
_void fail___void__arr__char_(ctx* _ctx, arr__char reason);
_void assert___void__bool___arr__char_(ctx* _ctx, bool condition, arr__char message);
nat _op_plus__nat__nat___nat_(ctx* _ctx, nat a, nat b);
ptr__ptr__char _op_plus__ptr__ptr__char__ptr__ptr__char___nat_(ptr__ptr__char p, nat offset);
bool _op_greater_equal__bool__nat___nat_(nat a, nat b);
arr__arr__char unsafe_as_arr__arr__arr__char__ptr_mut_arr__arr__char_(mut_arr__arr__char* a);
mut_arr__arr__char* new_uninitialized_mut_arr__ptr_mut_arr__arr__char__nat_(ctx* _ctx, nat size);
_void make_mut_arr_worker___void__ptr_mut_arr__arr__char___nat___map__arr__arr__char__arr__ptr__char___fun_mut1__arr__char__ptr__char__id1___lambda0___closure__klbmap__arr__arr__char__arr__ptr__char___fun_mut1__arr__char__ptr__char__id1___lambda0_(ctx* _ctx, mut_arr__arr__char* m, nat i, map__arr__arr__char__arr__ptr__char___fun_mut1__arr__char__ptr__char__id1___lambda0___closure f);
opt__task_and_nodes find_and_remove_first_doable_task_recur__opt__task_and_nodes__ptr_vat___opt__ptr_mut_bag_node__task_(vat* vat, opt__ptr_mut_bag_node__task opt_node);
_void noctx_set_at___void__ptr_mut_arr__nat___nat___nat_(mut_arr__nat* a, nat index, nat value);
nat noctx_last__nat__ptr_mut_arr__nat_(mut_arr__nat* a);
_void then_void___void__ptr_fut__int32___forward_to___void__ptr_fut__int32___ptr_fut__int32___lambda0___closure__klbforward_to___void__ptr_fut__int32___ptr_fut__int32___lambda0_(ctx* _ctx, fut__int32* f, forward_to___void__ptr_fut__int32___ptr_fut__int32___lambda0___closure cb);
_void call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic(ctx* _ctx, call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0___closure* _closure);
_void resolve_or_reject___void__ptr_fut__int32___result__int32__exception_(ctx* _ctx, fut__int32* f, result__int32__exception result);
some__ptr_mut_bag_node__task some__some__ptr_mut_bag_node__task__ptr_mut_bag_node__task_(mut_bag_node__task* t);
_void catch_with_exception_ctx___void__ptr_exception_ctx___call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda0___closure__klbcall__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda0___call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda1___closure__klbcall__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda1_(ctx* _ctx, exception_ctx* ec, call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda0___closure try, call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda1___closure catcher);
exception_ctx* get_exception_ctx__ptr_exception_ctx(ctx* _ctx);
_void throw___void__exception_(ctx* _ctx, exception e);
bool and__bool__bool___bool_(bool a, bool b);
ptr__arr__char uninitialized_data__ptr__arr__char__nat_(ctx* _ctx, nat size);
_void set_at___void__ptr_mut_arr__arr__char___nat___arr__char_(ctx* _ctx, mut_arr__arr__char* a, nat index, arr__char value);
arr__char map__arr__arr__char__arr__ptr__char___fun_mut1__arr__char__ptr__char__id1___lambda0_(ctx* _ctx, map__arr__arr__char__arr__ptr__char___fun_mut1__arr__char__ptr__char__id1___lambda0___closure _closure, nat i);
nat incr__nat__nat_(ctx* _ctx, nat n);
bool contains__q__bool__ptr_mut_arr__nat___nat_(mut_arr__nat* a, nat value);
_void push_capacity_must_be_sufficient___void__ptr_mut_arr__nat___nat_(mut_arr__nat* a, nat value);
some__task_and_nodes some__some__task_and_nodes__task_and_nodes_(task_and_nodes t);
task_and_nodes as__task_and_nodes__task_and_nodes_(task_and_nodes value);
_void set___void__ptr__nat___nat_(ptr__nat p, nat value);
bool empty__q__bool__ptr_mut_arr__nat_(mut_arr__nat* a);
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
exception_ctx* as_ref__ptr_exception_ctx__ptr__byte_(ptr__byte p);
bool _op_equal_equal__bool__ptr__jmp_buf_tag___ptr__jmp_buf_tag_(ptr__jmp_buf_tag a, ptr__jmp_buf_tag b);
extern void longjmp(ptr__jmp_buf_tag env, int32 val);
ptr__arr__char ptr_cast__ptr__arr__char__ptr__byte_(ptr__byte p);
_void noctx_set_at___void__ptr_mut_arr__arr__char___nat___arr__char_(mut_arr__arr__char* a, nat index, arr__char value);
arr__char add_first_task__ptr_fut__int32__arr__ptr__char___fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char___lambda0__dynamic__lambda0_(ctx* _ctx, ptr__char it);
ptr__char at__ptr__char__arr__ptr__char___nat_(ctx* _ctx, arr__ptr__char a, nat index);
bool contains_recur__q__bool__arr__nat___nat___nat_(arr__nat a, nat value, nat i);
arr__nat temp_as_arr__arr__nat__ptr_mut_arr__nat_(mut_arr__nat* a);
_void catch_with_exception_ctx___void__ptr_exception_ctx___call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda0___closure__klbcall__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda0___call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda1___closure__klbcall__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda1_(ctx* _ctx, exception_ctx* ec, call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda0___closure try, call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda1___closure catcher);
_void drop___void___void_(_void t);
_void call___void__fun_mut1___void__result__int32__exception___result__int32__exception_(ctx* _ctx, fun_mut1___void__result__int32__exception f, result__int32__exception p0);
fut__int32* call__ptr_fut__int32__fun_mut0__ptr_fut__int32_(ctx* _ctx, fun_mut0__ptr_fut__int32 f);
comparison _op_less_equal_greater__comparison__ptr__jmp_buf_tag___ptr__jmp_buf_tag_(ptr__jmp_buf_tag a, ptr__jmp_buf_tag b);
_void set___void__ptr__arr__char___arr__char_(ptr__arr__char p, arr__char value);
ptr__arr__char _op_plus__ptr__arr__char__ptr__arr__char___nat_(ptr__arr__char p, nat offset);
arr__char to_str__arr__char__ptr__char_(ptr__char a);
ptr__char noctx_at__ptr__char__arr__ptr__char___nat_(arr__ptr__char a, nat index);
bool or__bool__bool___bool_(bool a, bool b);
nat noctx_at__nat__arr__nat___nat_(arr__nat a, nat index);
_void call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda0(ctx* _ctx, call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda0___closure _closure);
_void call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda1_(ctx* _ctx, call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda1___closure _closure, exception it);
_void call_with_ctx___void__ptr_ctx___fun_mut1___void__result__int32__exception___result__int32__exception_(ctx* c, fun_mut1___void__result__int32__exception f, result__int32__exception p0);
fut__int32* call_with_ctx__ptr_fut__int32__ptr_ctx___fun_mut0__ptr_fut__int32_(ctx* c, fun_mut0__ptr_fut__int32 f);
arr__char arr_from_begin_end__arr__char__ptr__char___ptr__char_(ptr__char begin, ptr__char end);
ptr__char find_cstr_end__ptr__char__ptr__char_(ptr__char a);
ptr__char deref__ptr__char__ptr__ptr__char_(ptr__ptr__char p);
fut__int32* call__ptr_fut__int32__fun_mut1__ptr_fut__int32___void____void_(ctx* _ctx, fun_mut1__ptr_fut__int32___void f, _void p0);
_void call___void__fun_ptr3___void__ptr_ctx__ptr__byte__result__int32__exception___ptr_ctx___ptr__byte___result__int32__exception_(fun_ptr3___void__ptr_ctx__ptr__byte__result__int32__exception f, ctx* p0, ptr__byte p1, result__int32__exception p2);
fut__int32* call__ptr_fut__int32__fun_ptr2__ptr_fut__int32__ptr_ctx__ptr__byte___ptr_ctx___ptr__byte_(fun_ptr2__ptr_fut__int32__ptr_ctx__ptr__byte f, ctx* p0, ptr__byte p1);
nat _op_minus__nat__ptr__char___ptr__char_(ptr__char a, ptr__char b);
ptr__char find_char_in_cstr__ptr__char__ptr__char___char_(ptr__char a, char c);
fut__int32* call_with_ctx__ptr_fut__int32__ptr_ctx___fun_mut1__ptr_fut__int32___void____void_(ctx* c, fun_mut1__ptr_fut__int32___void f, _void p0);
nat to_nat__nat__ptr__char_(ptr__char p);
ptr__char _op_minus__ptr__char__ptr__char___nat_(ptr__char p, nat offset);
bool _op_equal_equal__bool__char___char_(char a, char b);
char deref__char__ptr__char_(ptr__char p);
ptr__char todo__ptr__char();
ptr__char incr__ptr__char__ptr__char_(ptr__char p);
fut__int32* call__ptr_fut__int32__fun_ptr3__ptr_fut__int32__ptr_ctx__ptr__byte___void___ptr_ctx___ptr__byte____void_(fun_ptr3__ptr_fut__int32__ptr_ctx__ptr__byte___void f, ctx* p0, ptr__byte p1, _void p2);
comparison _op_less_equal_greater__comparison__char___char_(char a, char b);
ptr__char hard_fail__ptr__char__arr__char__id2_();
ptr__char _op_plus__ptr__char__ptr__char___nat_(ptr__char p, nat offset);
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
	return resolved__ptr_fut__int32__int32__id0_(_ctx);
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
fut__int32* resolved__ptr_fut__int32__int32__id0_(ctx* _ctx) {
	return _initfut__int32(alloc__ptr__byte__nat_(_ctx, 32), (fut__int32) {new_lock__lock(), (fut_state__int32) _constant__fut_state__int32__1});
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
ptr__byte alloc__ptr__byte__nat_(ctx* _ctx, nat size) {
	return gc_alloc__ptr__byte__ptr_gc___nat_(_ctx, get_gc__ptr_gc(_ctx), size);
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
bool zero__q__bool__nat_(nat n) {
	return _op_equal_equal__bool__nat___nat_(n, 0ull);
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
opt__ptr__byte try_gc_alloc__opt__ptr__byte__ptr_gc___nat_(gc* gc, nat size) {
	return (opt__ptr__byte) { 1, .as_some__ptr__byte = some__some__ptr__byte__ptr__byte_(unmanaged_alloc_bytes__ptr__byte__nat_(size)) };
}
ptr__byte todo__ptr__byte() {
	return hard_fail__ptr__byte__arr__char__id2_();
}
gc_ctx* get_gc_ctx__ptr_gc_ctx(ctx* _ctx) {
	return (gc_ctx*) _ctx->gc_ctx_ptr;
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
_void forbid___void__bool_(ctx* _ctx, bool condition) {
	return forbid___void__bool___arr__char_(_ctx, condition, (arr__char) _constant____arr__char__7);
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
some__ptr__byte some__some__ptr__byte__ptr__byte_(ptr__byte t) {
	return (some__ptr__byte) {t};
}
ptr__byte hard_fail__ptr__byte__arr__char__id2_() {
	assert(0);
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
_void forbid___void__bool___arr__char_(ctx* _ctx, bool condition, arr__char message) {
	return (condition ? fail___void__arr__char_(_ctx, message) : 0);
}
_void assert___void__bool_(ctx* _ctx, bool condition) {
	return assert___void__bool___arr__char_(_ctx, condition, (arr__char) _constant____arr__char__8);
}
arr__ptr__char slice__arr__ptr__char__arr__ptr__char___nat___nat_(ctx* _ctx, arr__ptr__char a, nat begin, nat size) {
	return (assert___void__bool_(_ctx, _op_less_equal__bool__nat___nat_(_op_plus__nat__nat___nat_(_ctx, begin, size), a.size)),
	(arr__ptr__char) {size, (a.data + begin)});
}
nat _op_minus__nat__nat___nat_(ctx* _ctx, nat a, nat b) {
	return (assert___void__bool_(_ctx, _op_greater_equal__bool__nat___nat_(a, b)),
	(a - b));
}
arr__arr__char freeze__arr__arr__char__ptr_mut_arr__arr__char_(mut_arr__arr__char* a) {
	return ((a->frozen__q = 1), 0,
	unsafe_as_arr__arr__arr__char__ptr_mut_arr__arr__char_(a));
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
_void fail___void__arr__char_(ctx* _ctx, arr__char reason) {
	return throw___void__exception_(_ctx, (exception) {reason});
}
_void assert___void__bool___arr__char_(ctx* _ctx, bool condition, arr__char message) {
	return (condition ? 0 : fail___void__arr__char_(_ctx, message));
}
nat _op_plus__nat__nat___nat_(ctx* _ctx, nat a, nat b) {
	nat res;
	return ((res = (a + b)),
	(assert___void__bool_(_ctx, (_op_greater_equal__bool__nat___nat_(res, a) && _op_greater_equal__bool__nat___nat_(res, b))),
	res));
}
bool _op_greater_equal__bool__nat___nat_(nat a, nat b) {
	return !(_op_less__bool__nat___nat_(a, b));
}
arr__arr__char unsafe_as_arr__arr__arr__char__ptr_mut_arr__arr__char_(mut_arr__arr__char* a) {
	return (arr__arr__char) {a->size, a->data};
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
exception_ctx* get_exception_ctx__ptr_exception_ctx(ctx* _ctx) {
	return (exception_ctx*) _ctx->exception_ctx_ptr;
}
_void throw___void__exception_(ctx* _ctx, exception e) {
	exception_ctx* exn_ctx;
	return ((exn_ctx = get_exception_ctx__ptr_exception_ctx(_ctx)),
	(((hard_forbid___void__bool_(_op_equal_equal__bool__ptr__jmp_buf_tag___ptr__jmp_buf_tag_(exn_ctx->jmp_buf_ptr, NULL)),
	(exn_ctx->thrown_exception = e), 0),
	(longjmp(exn_ctx->jmp_buf_ptr, 7), 0)),
	todo___void()));
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
nat incr__nat__nat_(ctx* _ctx, nat n) {
	return (assert___void__bool_(_ctx, _op_less__bool__nat___nat_(n, 1000000000ull)),
	(n + 1ull));
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
comparison _op_less_equal_greater__comparison__ptr__jmp_buf_tag___ptr__jmp_buf_tag_(ptr__jmp_buf_tag a, ptr__jmp_buf_tag b) {
	return (a < b)
		? (comparison) { 0, .as_less = (less) { 0 } }
		: (b < a)
			? (comparison) { 2, .as_greater = (greater) { 0 } }
			: (comparison) { 1, .as_equal = (equal) { 0 } };
}
arr__char to_str__arr__char__ptr__char_(ptr__char a) {
	return arr_from_begin_end__arr__char__ptr__char___ptr__char_(a, find_cstr_end__ptr__char__ptr__char_(a));
}
ptr__char noctx_at__ptr__char__arr__ptr__char___nat_(arr__ptr__char a, nat index) {
	return (hard_assert___void__bool_(_op_less__bool__nat___nat_(index, a.size)),
	*((a.data + index)));
}
nat noctx_at__nat__arr__nat___nat_(arr__nat a, nat index) {
	return (hard_assert___void__bool_(_op_less__bool__nat___nat_(index, a.size)),
	*((a.data + index)));
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
arr__char arr_from_begin_end__arr__char__ptr__char___ptr__char_(ptr__char begin, ptr__char end) {
	return (arr__char) {_op_minus__nat__ptr__char___ptr__char_(end, begin), begin};
}
ptr__char find_cstr_end__ptr__char__ptr__char_(ptr__char a) {
	return find_char_in_cstr__ptr__char__ptr__char___char_(a, '\0');
}
fut__int32* call__ptr_fut__int32__fun_mut1__ptr_fut__int32___void____void_(ctx* _ctx, fun_mut1__ptr_fut__int32___void f, _void p0) {
	return call_with_ctx__ptr_fut__int32__ptr_ctx___fun_mut1__ptr_fut__int32___void____void_(_ctx, f, p0);
}
nat _op_minus__nat__ptr__char___ptr__char_(ptr__char a, ptr__char b) {
	return (nat) (a - (nat) b);
}
ptr__char find_char_in_cstr__ptr__char__ptr__char___char_(ptr__char a, char c) {
	return _op_equal_equal__bool__char___char_(*(a), c)
		? a
		: _op_equal_equal__bool__char___char_(*(a), '\0')
			? todo__ptr__char()
			: find_char_in_cstr__ptr__char__ptr__char___char_(incr__ptr__char__ptr__char_(a), c);
}
fut__int32* call_with_ctx__ptr_fut__int32__ptr_ctx___fun_mut1__ptr_fut__int32___void____void_(ctx* c, fun_mut1__ptr_fut__int32___void f, _void p0) {
	return f.fun_ptr(c, f.closure, p0);
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
ptr__char todo__ptr__char() {
	return hard_fail__ptr__char__arr__char__id2_();
}
ptr__char incr__ptr__char__ptr__char_(ptr__char p) {
	return (p + 1ull);
}
comparison _op_less_equal_greater__comparison__char___char_(char a, char b) {
	return (a < b)
		? (comparison) { 0, .as_less = (less) { 0 } }
		: (b < a)
			? (comparison) { 2, .as_greater = (greater) { 0 } }
			: (comparison) { 1, .as_equal = (equal) { 0 } };
}
ptr__char hard_fail__ptr__char__arr__char__id2_() {
	assert(0);
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
	assert(sizeof(_int) == 8);
	assert(sizeof(fun_ptr2___void__nat__ptr_global_ctx) == 8);
	assert(sizeof(ptr__thread_args__ptr_global_ctx) == 8);
	assert(sizeof(thread_args__ptr_global_ctx) == 24);
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
	assert(sizeof(some__ptr__byte) == 8);
	assert(sizeof(opt__ptr__byte) == 16);
	assert(sizeof(then2__ptr_fut__int32__ptr_fut___void___fun_ref0__int32___lambda0___closure) == 32);
	assert(sizeof(some__opt__task) == 32);
	assert(sizeof(opt__opt__task) == 40);
	assert(sizeof(then__ptr_fut__int32__ptr_fut___void___fun_ref1__int32___void___lambda0___closure) == 40);
	assert(sizeof(map__arr__arr__char__arr__ptr__char___fun_mut1__arr__char__ptr__char__id1___lambda0___closure) == 16);
	assert(sizeof(call__ptr_fut__int32__fun_ref0__int32___lambda0___closure) == 40);
	assert(sizeof(mut_arr__arr__char) == 32);
	assert(sizeof(opt__task_and_nodes) == 48);
	assert(sizeof(some__task_and_nodes) == 40);
	assert(sizeof(task_and_nodes) == 40);
	assert(sizeof(ptr__bool) == 8);
	assert(sizeof(call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda0___closure) == 40);
	assert(sizeof(call__ptr_fut__int32__fun_ref0__int32___lambda0__dynamic__lambda1___closure) == 8);
	assert(sizeof(forward_to___void__ptr_fut__int32___ptr_fut__int32___lambda0___closure) == 8);
	assert(sizeof(call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0___closure) == 48);
	assert(sizeof(call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda0___closure) == 48);
	assert(sizeof(call__ptr_fut__int32__fun_ref1__int32___void____void___lambda0__dynamic__lambda1___closure) == 8);
	assert(sizeof(arr__nat) == 16);

	return rt_main__int32__int32___ptr__ptr__char___fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char_(argc, argv, main__ptr_fut__int32__arr__arr__char_);
}
