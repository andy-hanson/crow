#include <assert.h>
#include <errno.h>
#include <stdatomic.h>
#include <stddef.h>
#include <stdint.h>
typedef uint8_t* (*fun_ptr1__ptr__nat8__ptr__nat8)(uint8_t*);
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
struct some__ptr__nat8 {
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
struct cell__ptr__nat8 {
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
struct my_record {
	uint64_t x;
	uint64_t y;
};
struct my_byref_record {
	uint64_t x;
	uint64_t y;
};
struct my_other_record {
	uint8_t __mustBeNonEmpty;
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
struct opt__ptr__nat8 {
	int kind;
	union {
		struct none as0;
		struct some__ptr__nat8 as1;
	};
};
struct opt__task;
struct result__chosen_task__no_chosen_task;
struct opt__chosen_task;
struct opt__opt__task;
struct opt__task_and_nodes;
struct my_union {
	int kind;
	union {
		struct my_record as0;
		struct my_other_record as1;
	};
};
typedef uint8_t (*fun_ptr3___void__ptr_ctx__ptr__nat8__result__int32__exception)(struct ctx*, uint8_t*, struct result__int32__exception);
typedef struct fut__int32* (*fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char)(struct ctx*, struct arr__arr__char);
typedef uint8_t (*fun_ptr2___void__ptr_ctx__ptr__nat8)(struct ctx*, uint8_t*);
typedef uint8_t (*fun_ptr3___void__ptr_ctx__ptr__nat8__exception)(struct ctx*, uint8_t*, struct exception);
typedef struct fut__int32* (*fun_ptr4__ptr_fut__int32__ptr_ctx__ptr__nat8__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char)(struct ctx*, uint8_t*, struct arr__ptr__char, fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char);
typedef uint8_t (*fun_ptr3___void__ptr_ctx__ptr__nat8__result___void__exception)(struct ctx*, uint8_t*, struct result___void__exception);
typedef struct fut__int32* (*fun_ptr2__ptr_fut__int32__ptr_ctx__ptr__nat8)(struct ctx*, uint8_t*);
typedef struct fut__int32* (*fun_ptr3__ptr_fut__int32__ptr_ctx__ptr__nat8___void)(struct ctx*, uint8_t*, uint8_t);
typedef struct arr__char (*fun_ptr3__arr__char__ptr_ctx__ptr__nat8__ptr__char)(struct ctx*, uint8_t*, char*);
typedef struct arr__char (*fun_ptr3__arr__char__ptr_ctx__ptr__nat8__nat)(struct ctx*, uint8_t*, uint64_t);
typedef uint8_t (*fun_ptr2___void__nat__ptr_global_ctx)(uint64_t, struct global_ctx*);
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
	fun_ptr3___void__ptr_ctx__ptr__nat8__result__int32__exception fun_ptr;
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
	fun_ptr2___void__ptr_ctx__ptr__nat8 fun_ptr;
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
	fun_ptr3___void__ptr_ctx__ptr__nat8__exception fun_ptr;
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
	fun_ptr4__ptr_fut__int32__ptr_ctx__ptr__nat8__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char fun_ptr;
	uint8_t* closure;
};
struct fut___void;
struct fut_state_callbacks___void {
	struct opt__ptr_fut_callback_node___void head;
};
struct fut_callback_node___void;
struct fun_mut1___void__result___void__exception {
	fun_ptr3___void__ptr_ctx__ptr__nat8__result___void__exception fun_ptr;
	uint8_t* closure;
};
struct fun_ref0__int32;
struct fun_mut0__ptr_fut__int32 {
	fun_ptr2__ptr_fut__int32__ptr_ctx__ptr__nat8 fun_ptr;
	uint8_t* closure;
};
struct fun_ref1__int32___void;
struct fun_mut1__ptr_fut__int32___void {
	fun_ptr3__ptr_fut__int32__ptr_ctx__ptr__nat8___void fun_ptr;
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
	fun_ptr3__arr__char__ptr_ctx__ptr__nat8__ptr__char fun_ptr;
	uint8_t* closure;
};
struct fun_mut1__arr__char__nat {
	fun_ptr3__arr__char__ptr_ctx__ptr__nat8__nat fun_ptr;
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
uint8_t* unmanaged_alloc_bytes__ptr__nat8__nat(uint64_t size);
extern uint8_t* malloc(uint64_t size);
uint8_t hard_forbid___void__bool(uint8_t condition);
uint8_t hard_assert___void__bool(uint8_t condition);
uint8_t null__q__bool__ptr__nat8(uint8_t* a);
uint8_t _op_equal_equal__bool__nat__nat(uint64_t a, uint64_t b);
struct comparison compare16(uint64_t a, uint64_t b);
struct gc new_gc__gc();
struct none none__none();
struct mut_bag__task new_mut_bag__mut_bag__task();
struct thread_safe_counter new_thread_safe_counter__thread_safe_counter();
struct thread_safe_counter new_thread_safe_counter__thread_safe_counter__nat(uint64_t init);
uint8_t default_exception_handler___void__exception(struct ctx* ctx, struct exception e);
uint8_t print_err_sync_no_newline___void__arr__char(struct arr__char s);
uint8_t write_sync_no_newline___void__int32__arr__char(int32_t fd, struct arr__char s);
extern int64_t write(int32_t fd, uint8_t* buff, uint64_t n_bytes);
uint8_t _op_equal_equal__bool___int___int(int64_t a, int64_t b);
struct comparison compare27(int64_t a, int64_t b);
uint8_t todo___void();
int32_t stderr_fd__int32();
int32_t two__int32();
int32_t wrap_incr__int32__int32(int32_t a);
uint8_t print_err_sync___void__arr__char(struct arr__char s);
uint8_t empty__q__bool__arr__char(struct arr__char a);
uint8_t zero__q__bool__nat(uint64_t n);
struct global_ctx* get_gctx__ptr_global_ctx(struct ctx* ctx);
uint8_t new_vat__vat__ptr_global_ctx__nat__nat__lambda0(struct ctx* ctx, uint8_t* _closure, struct exception it);
struct fut__int32* do_main__ptr_fut__int32__ptr_global_ctx__ptr_vat__int32__ptr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char(struct global_ctx* gctx, struct vat* vat, int32_t argc, char** argv, fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char main_ptr);
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
struct comparison compare61(int32_t a, int32_t b);
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
uint8_t* alloc__ptr__nat8__nat(struct ctx* ctx, uint64_t size);
uint8_t* gc_alloc__ptr__nat8__ptr_gc__nat(struct ctx* ctx, struct gc* gc, uint64_t size);
struct opt__ptr__nat8 try_gc_alloc__opt__ptr__nat8__ptr_gc__nat(struct gc* gc, uint64_t size);
struct some__ptr__nat8 some__some__ptr__nat8__ptr__nat8(uint8_t* t);
uint8_t* todo__ptr__nat8();
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
uint8_t null__q__bool__ptr__jmp_buf_tag(struct jmp_buf_tag* a);
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
struct comparison compare179(char a, char b);
char literal__char__arr__char(struct arr__char a);
char noctx_at__char__arr__char__nat(struct arr__char a, uint64_t index);
char* todo__ptr__char();
char* incr__ptr__char__ptr__char(char* p);
struct arr__char add_first_task__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__lambda0__lambda0(struct ctx* ctx, uint8_t* _closure, char* it);
struct fut__int32* add_first_task__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__lambda0(struct ctx* ctx, struct add_first_task__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__lambda0___closure* _closure);
struct fut__int32* do_main__ptr_fut__int32__ptr_global_ctx__ptr_vat__int32__ptr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__lambda0(struct ctx* ctx, uint8_t* _closure, struct arr__ptr__char all_args, fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char main_ptr);
struct fut__int32* call_with_ctx__ptr_fut__int32__ptr_ctx__fun2__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char(struct ctx* c, struct fun2__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char f, struct arr__ptr__char p0, fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char p1);
uint8_t run_threads___void__nat__ptr_global_ctx__fun_ptr2___void__nat__ptr_global_ctx(uint64_t n_threads, struct global_ctx* arg, fun_ptr2___void__nat__ptr_global_ctx fun);
struct thread_args__ptr_global_ctx* unmanaged_alloc_elements__ptr__thread_args__ptr_global_ctx__nat(uint64_t size_elements);
uint8_t run_threads_recur___void__nat__nat__ptr__nat__ptr__thread_args__ptr_global_ctx__ptr_global_ctx__fun_ptr2___void__nat__ptr_global_ctx(uint64_t i, uint64_t n_threads, uint64_t* threads, struct thread_args__ptr_global_ctx* thread_args, struct global_ctx* arg, fun_ptr2___void__nat__ptr_global_ctx fun);
uint8_t* thread_fun__ptr__nat8__ptr__nat8(uint8_t* args_ptr);
uint8_t* run_threads_recur___void__nat__nat__ptr__nat__ptr__thread_args__ptr_global_ctx__ptr_global_ctx__fun_ptr2___void__nat__ptr_global_ctx__lambda0(uint8_t* args_ptr);
extern int32_t pthread_create(struct cell__nat* thread, uint8_t* attr, fun_ptr1__ptr__nat8__ptr__nat8 start_routine, uint8_t* arg);
struct cell__nat* as_cell__ptr_cell__nat__ptr__nat(uint64_t* p);
int32_t eagain__int32();
int32_t ten__int32();
uint8_t join_threads_recur___void__nat__nat__ptr__nat(uint64_t i, uint64_t n_threads, uint64_t* threads);
uint8_t join_one_thread___void__nat(uint64_t tid);
extern int32_t pthread_join(uint64_t thread, struct cell__ptr__nat8* thread_return);
int32_t einval__int32();
int32_t esrch__int32();
uint8_t* get__ptr__nat8__ptr_cell__ptr__nat8(struct cell__ptr__nat8* c);
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
uint8_t rt_main__int32__int32__ptr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__lambda0(uint64_t thread_id, struct global_ctx* gctx);
struct result__int32__exception must_be_resolved__result__int32__exception__ptr_fut__int32(struct fut__int32* f);
struct result__int32__exception hard_unreachable__result__int32__exception();
struct fut__int32* main__ptr_fut__int32__arr__arr__char(struct ctx* ctx, struct arr__arr__char args);
uint8_t test_compare_records___void(struct ctx* ctx);
uint64_t literal__nat__arr__char(struct ctx* ctx, struct arr__char s);
struct arr__char rtail__arr__char__arr__char(struct ctx* ctx, struct arr__char a);
struct arr__char slice__arr__char__arr__char__nat__nat(struct ctx* ctx, struct arr__char a, uint64_t begin, uint64_t size);
uint64_t decr__nat__nat(struct ctx* ctx, uint64_t a);
uint64_t wrap_decr__nat__nat(uint64_t a);
uint64_t _op_times__nat__nat__nat(struct ctx* ctx, uint64_t a, uint64_t b);
uint64_t _op_div__nat__nat__nat(struct ctx* ctx, uint64_t a, uint64_t b);
uint64_t char_to_nat__nat__char(char c);
uint64_t todo__nat();
char last__char__arr__char(struct ctx* ctx, struct arr__char a);
char at__char__arr__char__nat(struct ctx* ctx, struct arr__char a, uint64_t index);
uint8_t print_sync___void__arr__char(struct arr__char s);
uint8_t print_sync_no_newline___void__arr__char(struct arr__char s);
int32_t stdout_fd__int32();
struct arr__char to_str__arr__char__comparison(struct ctx* ctx, struct comparison c);
struct comparison compare264(struct my_record a, struct my_record b);
uint8_t test_compare_byref_records___void(struct ctx* ctx);
struct comparison compare266(struct my_byref_record* a, struct my_byref_record* b);
uint8_t test_compare_unions___void(struct ctx* ctx);
struct comparison compare268(struct my_union a, struct my_union b);
struct comparison compare269(struct my_other_record a, struct my_other_record b);
struct fut__int32* resolved__ptr_fut__int32__int32(struct ctx* ctx, int32_t value);
int32_t literal__int32__arr__char(struct ctx* ctx, struct arr__char s);
int64_t literal___int__arr__char(struct ctx* ctx, struct arr__char s);
struct arr__char tail__arr__char__arr__char(struct ctx* ctx, struct arr__char a);
struct arr__char slice_starting_at__arr__char__arr__char__nat(struct ctx* ctx, struct arr__char a, uint64_t begin);
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
int32_t main(int32_t argc, char** argv);
int32_t rt_main__int32__int32__ptr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char(int32_t argc, char** argv, fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char main_ptr) {
	uint64_t n_threads;
	struct global_ctx gctx_by_val;
	struct global_ctx* gctx;
	struct vat vat_by_val;
	struct vat* vat;
	struct fut__int32* main_fut;
	struct ok__int32 o;
	struct err__exception e;
	struct result__int32__exception matched;
	n_threads = two__nat();
	gctx_by_val = (struct global_ctx) {new_lock__lock(), empty_arr__arr__ptr_vat(), n_threads, new_condition__condition(), 0, 0};
	gctx = (&(gctx_by_val));
	vat_by_val = new_vat__vat__ptr_global_ctx__nat__nat(gctx, 0, n_threads);
	vat = (&(vat_by_val));
	(gctx->vats = (struct arr__ptr_vat) {1, (&(vat))}, 0);
	main_fut = do_main__ptr_fut__int32__ptr_global_ctx__ptr_vat__int32__ptr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char(gctx, vat, argc, argv, main_ptr);
	run_threads___void__nat__ptr_global_ctx__fun_ptr2___void__nat__ptr_global_ctx(n_threads, gctx, rt_main__int32__int32__ptr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__lambda0);
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
	return (struct vat) {gctx, id, new_gc__gc(), new_lock__lock(), new_mut_bag__mut_bag__task(), actors, 0, new_thread_safe_counter__thread_safe_counter(), (struct fun_mut1___void__exception) {(fun_ptr3___void__ptr_ctx__ptr__nat8__exception) new_vat__vat__ptr_global_ctx__nat__nat__lambda0, (uint8_t*) NULL}};
}
struct mut_arr__nat new_mut_arr_by_val_with_capacity_from_unmanaged_memory__mut_arr__nat__nat(uint64_t capacity) {
	return (struct mut_arr__nat) {0, 0, capacity, unmanaged_alloc_elements__ptr__nat__nat(capacity)};
}
uint64_t* unmanaged_alloc_elements__ptr__nat__nat(uint64_t size_elements) {
	uint8_t* bytes;
	bytes = unmanaged_alloc_bytes__ptr__nat8__nat((size_elements * sizeof(uint64_t)));
	return (uint64_t*) bytes;
}
uint8_t* unmanaged_alloc_bytes__ptr__nat8__nat(uint64_t size) {
	uint8_t* res;
	res = malloc(size);
	hard_forbid___void__bool(null__q__bool__ptr__nat8(res));
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
uint8_t null__q__bool__ptr__nat8(uint8_t* a) {
	return _op_equal_equal__bool__nat__nat((uint64_t) a, (uint64_t) NULL);
}
uint8_t _op_equal_equal__bool__nat__nat(uint64_t a, uint64_t b) {
	struct comparison matched;
	matched = compare16(a, b);
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
struct comparison compare16(uint64_t a, uint64_t b) {
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
uint8_t _op_equal_equal__bool___int___int(int64_t a, int64_t b) {
	struct comparison matched;
	matched = compare27(a, b);
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
struct comparison compare27(int64_t a, int64_t b) {
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
struct fut__int32* do_main__ptr_fut__int32__ptr_global_ctx__ptr_vat__int32__ptr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char(struct global_ctx* gctx, struct vat* vat, int32_t argc, char** argv, fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char main_ptr) {
	struct exception_ctx ectx;
	struct thread_local_stuff tls;
	struct ctx ctx_by_val;
	struct ctx* ctx;
	struct fun2__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char add;
	struct arr__ptr__char all_args;
	ectx = new_exception_ctx__exception_ctx();
	tls = (struct thread_local_stuff) {(&(ectx))};
	ctx_by_val = new_ctx__ctx__ptr_global_ctx__ptr_thread_local_stuff__ptr_vat__nat(gctx, (&(tls)), vat, 0);
	ctx = (&(ctx_by_val));
	add = (struct fun2__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char) {(fun_ptr4__ptr_fut__int32__ptr_ctx__ptr__nat8__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char) do_main__ptr_fut__int32__ptr_global_ctx__ptr_vat__int32__ptr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__lambda0, (uint8_t*) NULL};
	all_args = (struct arr__ptr__char) {argc, argv};
	return call_with_ctx__ptr_fut__int32__ptr_ctx__fun2__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char(ctx, add, all_args, main_ptr);
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
	matched = compare61(a, b);
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
struct comparison compare61(int32_t a, int32_t b) {
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
	matched = compare16(a, b);
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
	return then2__ptr_fut__int32__ptr_fut___void__fun_ref0__int32(ctx, resolved__ptr_fut___void___void(ctx, 0), (struct fun_ref0__int32) {cur_actor__vat_and_actor_id(ctx), (struct fun_mut0__ptr_fut__int32) {(fun_ptr2__ptr_fut__int32__ptr_ctx__ptr__nat8) add_first_task__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__lambda0, (uint8_t*) (temp0 = (struct add_first_task__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__lambda0___closure*) alloc__ptr__nat8__nat(ctx, sizeof(struct add_first_task__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__lambda0___closure)), ((*(temp0) = (struct add_first_task__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__lambda0___closure) {all_args, main_ptr}, 0), temp0))}});
}
struct fut__int32* then2__ptr_fut__int32__ptr_fut___void__fun_ref0__int32(struct ctx* ctx, struct fut___void* f, struct fun_ref0__int32 cb) {
	struct then2__ptr_fut__int32__ptr_fut___void__fun_ref0__int32__lambda0___closure* temp0;
	return then__ptr_fut__int32__ptr_fut___void__fun_ref1__int32___void(ctx, f, (struct fun_ref1__int32___void) {cur_actor__vat_and_actor_id(ctx), (struct fun_mut1__ptr_fut__int32___void) {(fun_ptr3__ptr_fut__int32__ptr_ctx__ptr__nat8___void) then2__ptr_fut__int32__ptr_fut___void__fun_ref0__int32__lambda0, (uint8_t*) (temp0 = (struct then2__ptr_fut__int32__ptr_fut___void__fun_ref0__int32__lambda0___closure*) alloc__ptr__nat8__nat(ctx, sizeof(struct then2__ptr_fut__int32__ptr_fut___void__fun_ref0__int32__lambda0___closure)), ((*(temp0) = (struct then2__ptr_fut__int32__ptr_fut___void__fun_ref0__int32__lambda0___closure) {cb}, 0), temp0))}});
}
struct fut__int32* then__ptr_fut__int32__ptr_fut___void__fun_ref1__int32___void(struct ctx* ctx, struct fut___void* f, struct fun_ref1__int32___void cb) {
	struct fut__int32* res;
	struct then__ptr_fut__int32__ptr_fut___void__fun_ref1__int32___void__lambda0___closure* temp0;
	res = new_unresolved_fut__ptr_fut__int32(ctx);
	then_void___void__ptr_fut___void__fun_mut1___void__result___void__exception(ctx, f, (struct fun_mut1___void__result___void__exception) {(fun_ptr3___void__ptr_ctx__ptr__nat8__result___void__exception) then__ptr_fut__int32__ptr_fut___void__fun_ref1__int32___void__lambda0, (uint8_t*) (temp0 = (struct then__ptr_fut__int32__ptr_fut___void__fun_ref1__int32___void__lambda0___closure*) alloc__ptr__nat8__nat(ctx, sizeof(struct then__ptr_fut__int32__ptr_fut___void__fun_ref1__int32___void__lambda0___closure)), ((*(temp0) = (struct then__ptr_fut__int32__ptr_fut___void__fun_ref1__int32___void__lambda0___closure) {cb, res}, 0), temp0))});
	return res;
}
struct fut__int32* new_unresolved_fut__ptr_fut__int32(struct ctx* ctx) {
	struct fut__int32* temp0;
	temp0 = (struct fut__int32*) alloc__ptr__nat8__nat(ctx, sizeof(struct fut__int32));
	(*(temp0) = (struct fut__int32) {new_lock__lock(), (struct fut_state__int32) {0, .as0 = (struct fut_state_callbacks__int32) {(struct opt__ptr_fut_callback_node__int32) {0, .as0 = none__none()}}}}, 0);
	return temp0;
}
uint8_t* alloc__ptr__nat8__nat(struct ctx* ctx, uint64_t size) {
	return gc_alloc__ptr__nat8__ptr_gc__nat(ctx, get_gc__ptr_gc(ctx), size);
}
uint8_t* gc_alloc__ptr__nat8__ptr_gc__nat(struct ctx* ctx, struct gc* gc, uint64_t size) {
	struct some__ptr__nat8 s;
	struct opt__ptr__nat8 matched;
	matched = try_gc_alloc__opt__ptr__nat8__ptr_gc__nat(gc, size);
	switch (matched.kind) {
		case 0:
			return todo__ptr__nat8();
		case 1:
			s = matched.as1;
			return s.value;
		default:
			return (assert(0),NULL);
	}
}
struct opt__ptr__nat8 try_gc_alloc__opt__ptr__nat8__ptr_gc__nat(struct gc* gc, uint64_t size) {
	return (struct opt__ptr__nat8) {1, .as1 = some__some__ptr__nat8__ptr__nat8(unmanaged_alloc_bytes__ptr__nat8__nat(size))};
}
struct some__ptr__nat8 some__some__ptr__nat8__ptr__nat8(uint8_t* t) {
	return (struct some__ptr__nat8) {t};
}
uint8_t* todo__ptr__nat8() {
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
			(f->state = (struct fut_state___void) {0, .as0 = (struct fut_state_callbacks___void) {(struct opt__ptr_fut_callback_node___void) {1, .as1 = some__some__ptr_fut_callback_node___void__ptr_fut_callback_node___void((temp0 = (struct fut_callback_node___void*) alloc__ptr__nat8__nat(ctx, sizeof(struct fut_callback_node___void)), ((*(temp0) = (struct fut_callback_node___void) {cb, cbs.head}, 0), temp0)))}}}, 0);
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
	return then_void___void__ptr_fut__int32__fun_mut1___void__result__int32__exception(ctx, from, (struct fun_mut1___void__result__int32__exception) {(fun_ptr3___void__ptr_ctx__ptr__nat8__result__int32__exception) forward_to___void__ptr_fut__int32__ptr_fut__int32__lambda0, (uint8_t*) (temp0 = (struct forward_to___void__ptr_fut__int32__ptr_fut__int32__lambda0___closure*) alloc__ptr__nat8__nat(ctx, sizeof(struct forward_to___void__ptr_fut__int32__ptr_fut__int32__lambda0___closure)), ((*(temp0) = (struct forward_to___void__ptr_fut__int32__ptr_fut__int32__lambda0___closure) {to}, 0), temp0))});
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
			(f->state = (struct fut_state__int32) {0, .as0 = (struct fut_state_callbacks__int32) {(struct opt__ptr_fut_callback_node__int32) {1, .as1 = some__some__ptr_fut_callback_node__int32__ptr_fut_callback_node__int32((temp0 = (struct fut_callback_node__int32*) alloc__ptr__nat8__nat(ctx, sizeof(struct fut_callback_node__int32)), ((*(temp0) = (struct fut_callback_node__int32) {cb, cbs.head}, 0), temp0)))}}}, 0);
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
	add_task___void__ptr_vat__task(ctx, vat, (struct task) {f.vat_and_actor.actor, (struct fun_mut0___void) {(fun_ptr2___void__ptr_ctx__ptr__nat8) call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0, (uint8_t*) (temp0 = (struct call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0___closure*) alloc__ptr__nat8__nat(ctx, sizeof(struct call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0___closure)), ((*(temp0) = (struct call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0___closure) {f, p0, res}, 0), temp0))}});
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
	hard_forbid___void__bool(null__q__bool__ptr__jmp_buf_tag(exn_ctx->jmp_buf_ptr));
	(exn_ctx->thrown_exception = e, 0);
	(longjmp(exn_ctx->jmp_buf_ptr, number_to_throw__int32(ctx)), 0);
	return todo___void();
}
struct exception_ctx* get_exception_ctx__ptr_exception_ctx(struct ctx* ctx) {
	return (struct exception_ctx*) ctx->exception_ctx_ptr;
}
uint8_t null__q__bool__ptr__jmp_buf_tag(struct jmp_buf_tag* a) {
	return _op_equal_equal__bool__nat__nat((uint64_t) a, (uint64_t) NULL);
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
	temp0 = (struct mut_bag_node__task*) alloc__ptr__nat8__nat(ctx, sizeof(struct mut_bag_node__task));
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
	return catch___void__fun_mut0___void__fun_mut1___void__exception(ctx, (struct fun_mut0___void) {(fun_ptr2___void__ptr_ctx__ptr__nat8) call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0__lambda0, (uint8_t*) (temp0 = (struct call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0__lambda0___closure*) alloc__ptr__nat8__nat(ctx, sizeof(struct call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0__lambda0___closure)), ((*(temp0) = (struct call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0__lambda0___closure) {_closure->f, _closure->p0, _closure->res}, 0), temp0))}, (struct fun_mut1___void__exception) {(fun_ptr3___void__ptr_ctx__ptr__nat8__exception) call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0__lambda1, (uint8_t*) (temp1 = (struct call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0__lambda1___closure*) alloc__ptr__nat8__nat(ctx, sizeof(struct call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0__lambda1___closure)), ((*(temp1) = (struct call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0__lambda1___closure) {_closure->res}, 0), temp1))});
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
	add_task___void__ptr_vat__task(ctx, vat, (struct task) {f.vat_and_actor.actor, (struct fun_mut0___void) {(fun_ptr2___void__ptr_ctx__ptr__nat8) call__ptr_fut__int32__fun_ref0__int32__lambda0, (uint8_t*) (temp0 = (struct call__ptr_fut__int32__fun_ref0__int32__lambda0___closure*) alloc__ptr__nat8__nat(ctx, sizeof(struct call__ptr_fut__int32__fun_ref0__int32__lambda0___closure)), ((*(temp0) = (struct call__ptr_fut__int32__fun_ref0__int32__lambda0___closure) {f, res}, 0), temp0))}});
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
	return catch___void__fun_mut0___void__fun_mut1___void__exception(ctx, (struct fun_mut0___void) {(fun_ptr2___void__ptr_ctx__ptr__nat8) call__ptr_fut__int32__fun_ref0__int32__lambda0__lambda0, (uint8_t*) (temp0 = (struct call__ptr_fut__int32__fun_ref0__int32__lambda0__lambda0___closure*) alloc__ptr__nat8__nat(ctx, sizeof(struct call__ptr_fut__int32__fun_ref0__int32__lambda0__lambda0___closure)), ((*(temp0) = (struct call__ptr_fut__int32__fun_ref0__int32__lambda0__lambda0___closure) {_closure->f, _closure->res}, 0), temp0))}, (struct fun_mut1___void__exception) {(fun_ptr3___void__ptr_ctx__ptr__nat8__exception) call__ptr_fut__int32__fun_ref0__int32__lambda0__lambda1, (uint8_t*) (temp1 = (struct call__ptr_fut__int32__fun_ref0__int32__lambda0__lambda1___closure*) alloc__ptr__nat8__nat(ctx, sizeof(struct call__ptr_fut__int32__fun_ref0__int32__lambda0__lambda1___closure)), ((*(temp1) = (struct call__ptr_fut__int32__fun_ref0__int32__lambda0__lambda1___closure) {_closure->res}, 0), temp1))});
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
	temp0 = (struct fut___void*) alloc__ptr__nat8__nat(ctx, sizeof(struct fut___void));
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
	return make_arr__arr__arr__char__nat__fun_mut1__arr__char__nat(ctx, a.size, (struct fun_mut1__arr__char__nat) {(fun_ptr3__arr__char__ptr_ctx__ptr__nat8__nat) map__arr__arr__char__arr__ptr__char__fun_mut1__arr__char__ptr__char__lambda0, (uint8_t*) (temp0 = (struct map__arr__arr__char__arr__ptr__char__fun_mut1__arr__char__ptr__char__lambda0___closure*) alloc__ptr__nat8__nat(ctx, sizeof(struct map__arr__arr__char__arr__ptr__char__fun_mut1__arr__char__ptr__char__lambda0___closure)), ((*(temp0) = (struct map__arr__arr__char__arr__ptr__char__fun_mut1__arr__char__ptr__char__lambda0___closure) {mapper, a}, 0), temp0))});
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
	temp0 = (struct mut_arr__arr__char*) alloc__ptr__nat8__nat(ctx, sizeof(struct mut_arr__arr__char));
	(*(temp0) = (struct mut_arr__arr__char) {0, size, size, uninitialized_data__ptr__arr__char__nat(ctx, size)}, 0);
	return temp0;
}
struct arr__char* uninitialized_data__ptr__arr__char__nat(struct ctx* ctx, uint64_t size) {
	uint8_t* bptr;
	bptr = alloc__ptr__nat8__nat(ctx, (size * sizeof(struct arr__char)));
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
	return (uint64_t) (a - (uint64_t) b);
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
	matched = compare179(a, b);
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
struct comparison compare179(char a, char b) {
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
	return _closure->main_ptr(ctx, map__arr__arr__char__arr__ptr__char__fun_mut1__arr__char__ptr__char(ctx, args, (struct fun_mut1__arr__char__ptr__char) {(fun_ptr3__arr__char__ptr_ctx__ptr__nat8__ptr__char) add_first_task__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__lambda0__lambda0, (uint8_t*) NULL}));
}
struct fut__int32* do_main__ptr_fut__int32__ptr_global_ctx__ptr_vat__int32__ptr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__lambda0(struct ctx* ctx, uint8_t* _closure, struct arr__ptr__char all_args, fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char main_ptr) {
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
	bytes = unmanaged_alloc_bytes__ptr__nat8__nat((size_elements * sizeof(struct thread_args__ptr_global_ctx)));
	return (struct thread_args__ptr_global_ctx*) bytes;
}
uint8_t run_threads_recur___void__nat__nat__ptr__nat__ptr__thread_args__ptr_global_ctx__ptr_global_ctx__fun_ptr2___void__nat__ptr_global_ctx(uint64_t i, uint64_t n_threads, uint64_t* threads, struct thread_args__ptr_global_ctx* thread_args, struct global_ctx* arg, fun_ptr2___void__nat__ptr_global_ctx fun) {
	struct thread_args__ptr_global_ctx* thread_arg_ptr;
	uint64_t* thread_ptr;
	fun_ptr1__ptr__nat8__ptr__nat8 fn;
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
uint8_t* thread_fun__ptr__nat8__ptr__nat8(uint8_t* args_ptr) {
	struct thread_args__ptr_global_ctx* args;
	args = (struct thread_args__ptr_global_ctx*) args_ptr;
	args->fun(args->thread_id, args->arg);
	return NULL;
}
uint8_t* run_threads_recur___void__nat__nat__ptr__nat__ptr__thread_args__ptr_global_ctx__ptr_global_ctx__fun_ptr2___void__nat__ptr_global_ctx__lambda0(uint8_t* args_ptr) {
	return thread_fun__ptr__nat8__ptr__nat8(args_ptr);
}
struct cell__nat* as_cell__ptr_cell__nat__ptr__nat(uint64_t* p) {
	return (struct cell__nat*) (uint8_t*) p;
}
int32_t eagain__int32() {
	return (ten__int32() + 1);
}
int32_t ten__int32() {
	return (five__int32() + five__int32());
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
	struct cell__ptr__nat8 thread_return;
	int32_t err;
	thread_return = (struct cell__ptr__nat8) {NULL};
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
	return hard_assert___void__bool(null__q__bool__ptr__nat8(get__ptr__nat8__ptr_cell__ptr__nat8((&(thread_return)))));
}
int32_t einval__int32() {
	return ((ten__int32() + ten__int32()) + two__int32());
}
int32_t esrch__int32() {
	return three__int32();
}
uint8_t* get__ptr__nat8__ptr_cell__ptr__nat8(struct cell__ptr__nat8* c) {
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
uint8_t rt_main__int32__int32__ptr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__lambda0(uint64_t thread_id, struct global_ctx* gctx) {
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
	test_compare_records___void(ctx);
	test_compare_byref_records___void(ctx);
	test_compare_unions___void(ctx);
	return resolved__ptr_fut__int32__int32(ctx, literal__int32__arr__char(ctx, (struct arr__char) {1, "0"}));
}
uint8_t test_compare_records___void(struct ctx* ctx) {
	struct my_record a;
	struct my_record b;
	struct my_record c;
	struct my_record d;
	a = (struct my_record) {literal__nat__arr__char(ctx, (struct arr__char) {1, "1"}), literal__nat__arr__char(ctx, (struct arr__char) {1, "2"})};
	b = (struct my_record) {literal__nat__arr__char(ctx, (struct arr__char) {1, "1"}), literal__nat__arr__char(ctx, (struct arr__char) {1, "3"})};
	c = (struct my_record) {literal__nat__arr__char(ctx, (struct arr__char) {1, "1"}), literal__nat__arr__char(ctx, (struct arr__char) {1, "2"})};
	d = (struct my_record) {literal__nat__arr__char(ctx, (struct arr__char) {1, "0"}), literal__nat__arr__char(ctx, (struct arr__char) {1, "3"})};
	print_sync___void__arr__char(to_str__arr__char__comparison(ctx, compare264(a, b)));
	print_sync___void__arr__char(to_str__arr__char__comparison(ctx, compare264(a, c)));
	return print_sync___void__arr__char(to_str__arr__char__comparison(ctx, compare264(a, d)));
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
struct arr__char slice__arr__char__arr__char__nat__nat(struct ctx* ctx, struct arr__char a, uint64_t begin, uint64_t size) {
	assert___void__bool(ctx, _op_less_equal__bool__nat__nat(_op_plus__nat__nat__nat(ctx, begin, size), a.size));
	return (struct arr__char) {size, (a.data + begin)};
}
uint64_t decr__nat__nat(struct ctx* ctx, uint64_t a) {
	forbid___void__bool(ctx, zero__q__bool__nat(a));
	return wrap_decr__nat__nat(a);
}
uint64_t wrap_decr__nat__nat(uint64_t a) {
	return (a - 1);
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
uint64_t _op_div__nat__nat__nat(struct ctx* ctx, uint64_t a, uint64_t b) {
	forbid___void__bool(ctx, zero__q__bool__nat(b));
	return (a / b);
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
char at__char__arr__char__nat(struct ctx* ctx, struct arr__char a, uint64_t index) {
	assert___void__bool(ctx, _op_less__bool__nat__nat(index, a.size));
	return noctx_at__char__arr__char__nat(a, index);
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
struct arr__char to_str__arr__char__comparison(struct ctx* ctx, struct comparison c) {
	struct comparison matched;
	matched = c;
	switch (matched.kind) {
		case 0:
			return (struct arr__char) {4, "less"};
		case 1:
			return (struct arr__char) {5, "equal"};
		case 2:
			return (struct arr__char) {7, "greater"};
		default:
			return (assert(0),(struct arr__char) {0, NULL});
	}
}
struct comparison compare264(struct my_record a, struct my_record b) {
	struct comparison temp1;
	struct comparison temp0;
	temp0 = compare16(a.x, b.x);
	switch (temp0.kind) {
		case 0:
			return (struct comparison) {0, .as0 = (struct less) {0}};
		case 1:
			temp1 = compare16(a.y, b.y);
			switch (temp1.kind) {
				case 0:
					return (struct comparison) {0, .as0 = (struct less) {0}};
				case 1:
					return (struct comparison) {1, .as1 = (struct equal) {0}};
				case 2:
					return (struct comparison) {2, .as2 = (struct greater) {0}};
				default:
					return (assert(0),(struct comparison) {0});
			}
		case 2:
			return (struct comparison) {2, .as2 = (struct greater) {0}};
		default:
			return (assert(0),(struct comparison) {0});
	}
}
uint8_t test_compare_byref_records___void(struct ctx* ctx) {
	struct my_byref_record* a;
	struct my_byref_record* b;
	struct my_byref_record* c;
	struct my_byref_record* d;
	struct my_byref_record* temp0;
	struct my_byref_record* temp1;
	struct my_byref_record* temp2;
	struct my_byref_record* temp3;
	a = (temp0 = (struct my_byref_record*) alloc__ptr__nat8__nat(ctx, sizeof(struct my_byref_record)), ((*(temp0) = (struct my_byref_record) {literal__nat__arr__char(ctx, (struct arr__char) {1, "1"}), literal__nat__arr__char(ctx, (struct arr__char) {1, "2"})}, 0), temp0));
	b = (temp1 = (struct my_byref_record*) alloc__ptr__nat8__nat(ctx, sizeof(struct my_byref_record)), ((*(temp1) = (struct my_byref_record) {literal__nat__arr__char(ctx, (struct arr__char) {1, "1"}), literal__nat__arr__char(ctx, (struct arr__char) {1, "3"})}, 0), temp1));
	c = (temp2 = (struct my_byref_record*) alloc__ptr__nat8__nat(ctx, sizeof(struct my_byref_record)), ((*(temp2) = (struct my_byref_record) {literal__nat__arr__char(ctx, (struct arr__char) {1, "1"}), literal__nat__arr__char(ctx, (struct arr__char) {1, "2"})}, 0), temp2));
	d = (temp3 = (struct my_byref_record*) alloc__ptr__nat8__nat(ctx, sizeof(struct my_byref_record)), ((*(temp3) = (struct my_byref_record) {literal__nat__arr__char(ctx, (struct arr__char) {1, "0"}), literal__nat__arr__char(ctx, (struct arr__char) {1, "3"})}, 0), temp3));
	print_sync___void__arr__char(to_str__arr__char__comparison(ctx, compare266(a, b)));
	print_sync___void__arr__char(to_str__arr__char__comparison(ctx, compare266(a, c)));
	return print_sync___void__arr__char(to_str__arr__char__comparison(ctx, compare266(a, d)));
}
struct comparison compare266(struct my_byref_record* a, struct my_byref_record* b) {
	struct comparison temp1;
	struct comparison temp0;
	temp0 = compare16(a->x, b->x);
	switch (temp0.kind) {
		case 0:
			return (struct comparison) {0, .as0 = (struct less) {0}};
		case 1:
			temp1 = compare16(a->y, b->y);
			switch (temp1.kind) {
				case 0:
					return (struct comparison) {0, .as0 = (struct less) {0}};
				case 1:
					return (struct comparison) {1, .as1 = (struct equal) {0}};
				case 2:
					return (struct comparison) {2, .as2 = (struct greater) {0}};
				default:
					return (assert(0),(struct comparison) {0});
			}
		case 2:
			return (struct comparison) {2, .as2 = (struct greater) {0}};
		default:
			return (assert(0),(struct comparison) {0});
	}
}
uint8_t test_compare_unions___void(struct ctx* ctx) {
	struct my_union a;
	struct my_union b;
	struct my_union c;
	struct my_union d;
	a = (struct my_union) {0, .as0 = (struct my_record) {literal__nat__arr__char(ctx, (struct arr__char) {1, "1"}), literal__nat__arr__char(ctx, (struct arr__char) {1, "2"})}};
	b = (struct my_union) {1, .as1 = (struct my_other_record) {0}};
	c = (struct my_union) {0, .as0 = (struct my_record) {literal__nat__arr__char(ctx, (struct arr__char) {1, "1"}), literal__nat__arr__char(ctx, (struct arr__char) {1, "2"})}};
	d = (struct my_union) {0, .as0 = (struct my_record) {literal__nat__arr__char(ctx, (struct arr__char) {1, "1"}), literal__nat__arr__char(ctx, (struct arr__char) {1, "1"})}};
	print_sync___void__arr__char(to_str__arr__char__comparison(ctx, compare268(a, b)));
	print_sync___void__arr__char(to_str__arr__char__comparison(ctx, compare268(a, c)));
	return print_sync___void__arr__char(to_str__arr__char__comparison(ctx, compare268(a, d)));
}
struct comparison compare268(struct my_union a, struct my_union b) {
	struct my_union match_a0;
	struct my_record a0;
	struct my_record b0;
	struct my_union match_b0;
	struct my_other_record a1;
	struct my_other_record b1;
	struct my_union match_b1;
	match_a0 = a;
	switch (match_a0.kind) {
		case 0:
			a0 = match_a0.as0;
			match_b0 = b;
			switch (match_b0.kind) {
				case 0:
					b0 = match_b0.as0;
					return compare264(a0, b0);
				case 1:
					return (struct comparison) {0, .as0 = (struct less) {0}};
				default:
					return (assert(0),(struct comparison) {0});
			}
		case 1:
			a1 = match_a0.as1;
			match_b1 = b;
			switch (match_b1.kind) {
				case 0:
					return (struct comparison) {2, .as2 = (struct greater) {0}};
				case 1:
					b1 = match_b1.as1;
					return compare269(a1, b1);
				default:
					return (assert(0),(struct comparison) {0});
			}
		default:
			return (assert(0),(struct comparison) {0});
	}
}
struct comparison compare269(struct my_other_record a, struct my_other_record b) {
	return (struct comparison) {1, .as1 = (struct equal) {0}};
}
struct fut__int32* resolved__ptr_fut__int32__int32(struct ctx* ctx, int32_t value) {
	struct fut__int32* temp0;
	temp0 = (struct fut__int32*) alloc__ptr__nat8__nat(ctx, sizeof(struct fut__int32));
	(*(temp0) = (struct fut__int32) {new_lock__lock(), (struct fut_state__int32) {1, .as1 = (struct fut_state_resolved__int32) {value}}}, 0);
	return temp0;
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
struct arr__char tail__arr__char__arr__char(struct ctx* ctx, struct arr__char a) {
	forbid___void__bool(ctx, empty__q__bool__arr__char(a));
	return slice_starting_at__arr__char__arr__char__nat(ctx, a, 1);
}
struct arr__char slice_starting_at__arr__char__arr__char__nat(struct ctx* ctx, struct arr__char a, uint64_t begin) {
	assert___void__bool(ctx, _op_less_equal__bool__nat__nat(begin, a.size));
	return slice__arr__char__arr__char__nat__nat(ctx, a, begin, _op_minus__nat__nat__nat(ctx, a.size, begin));
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
	matched = compare27(a, b);
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
int32_t main(int32_t argc, char** argv) {
	return rt_main__int32__int32__ptr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char(argc, argv, main__ptr_fut__int32__arr__arr__char);
}
