#include <math.h> // for e.g. 'sin'
#include <stddef.h> // for NULL
#include <stdint.h>
typedef uint32_t char32_t;

typedef struct fiber_suspension {
	// callee-saved registers
	uint64_t rbx;
	uint64_t rbp;
	uint64_t r12;
	uint64_t r13;
	uint64_t r14;
	uint64_t r15;

	// parameter registers
	uint64_t rdi;

	// stack and instruction registers
	uint64_t rsp;
	uint64_t rip;
} fiber_suspension;

// TODO: CLEAN UP ----------------------------------------------------------------------------------------------------------------------
__asm__(
	".text\n"
	".align 4\n"
	"switch_fiber_suspension:\n"
		// Save context 'from'

		// Store callee-preserved registers
	"movq        %rbx, 0x00(%rdi)\n" /* FIBER_REG_RBX */
	"movq        %rbp, 0x08(%rdi)\n" /* FIBER_REG_RBP */
	"movq        %r12, 0x10(%rdi)\n" /* FIBER_REG_R12 */
	"movq        %r13, 0x18(%rdi)\n" /* FIBER_REG_R13 */
	"movq        %r14, 0x20(%rdi)\n" /* FIBER_REG_R14 */
	"movq        %r15, 0x28(%rdi)\n" /* FIBER_REG_R15 */

	/* call stores the return address on the stack before jumping */
	"movq        (%rsp), %rcx\n"
	"movq        %rcx, 0x40(%rdi)\n" /* FIBER_REG_RIP */
	
	/* skip the pushed return address */
	"leaq        8(%rsp), %rcx\n"
	"movq        %rcx, 0x38(%rdi)\n" /* FIBER_REG_RSP */

	// Load context 'to'
	"movq        %rsi, %r8\n"

	// Load callee-preserved registers
	"movq        0x00(%r8), %rbx\n" /* FIBER_REG_RBX */
	"movq        0x08(%r8), %rbp\n" /* FIBER_REG_RBP */
	"movq        0x10(%r8), %r12\n" /* FIBER_REG_R12 */
	"movq        0x18(%r8), %r13\n" /* FIBER_REG_R13 */
	"movq        0x20(%r8), %r14\n" /* FIBER_REG_R14 */
	"movq        0x28(%r8), %r15\n" /* FIBER_REG_R15 */

	// Load first parameter, this is only used for the first time a fiber gains control
	"movq        0x30(%r8), %rdi\n" /* FIBER_REG_RDI */

	// Load stack pointer
	"movq        0x38(%r8), %rsp\n" /* FIBER_REG_RSP */

	// Load instruction pointer, and jump
	"movq        0x40(%r8), %rcx\n" /* FIBER_REG_RIP */
	"jmp         *%rcx\n"
);
extern void __attribute__((noinline)) switch_fiber_suspension(fiber_suspension* from, const fiber_suspension* to);

static fiber_suspension new_fiber_suspension(uint64_t* stack_top, void (*target)(uint8_t*), void* arg) {
	fiber_suspension res;
	res.rip = (uintptr_t) target;
	res.rdi = (uintptr_t) arg;
	res.rsp = (uintptr_t) &stack_top[-3];
	stack_top[-2] = 0;
	return res;
}
