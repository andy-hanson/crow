#include <math.h> // for e.g. 'sin'
#include <stddef.h> // for NULL
#include <stdint.h>
typedef uint32_t char32_t;

// 'fiberSuspensionSize' in the compiler makes assumptions about this
typedef struct fiber_suspension {
	uint64_t stackPointer;
} fiber_suspension;

__asm__(
	".text\n"
	".align 8\n"
	"switch_fiber_suspension:\n"

	// Save callee-saved register to the stack.
	"push %rbx\n"
	"push %rbp\n"
	"push %r12\n"
	"push %r13\n"
	"push %r14\n"
	"push %r15\n"
	// Write the stack pointer to the first argument.
	"movq %rsp, (%rdi)\n"

	// Get the new stack pointer from the second argument
	"movq (%rsi), %rsp\n"
	// Load the registers it had saved
	"pop %r15\n"
	"pop %r14\n"
	"pop %r13\n"
	"pop %r12\n"
	"pop %rbp\n"
	"pop %rbx\n"
	// The return address also comes from 'to' since we switched to its stack pointer.
	"ret\n"
);
extern void __attribute__((noinline)) switch_fiber_suspension(fiber_suspension* from, const fiber_suspension* to);

static fiber_suspension new_fiber_suspension(uint64_t* stack_top, void (*target)()) {
	stack_top[-2] = (uint64_t) target; // Use -2 because we want it 16-byte aligned
	// It will pop garbage initial values for r15, r14, r13, r12, rbp, rbx, then return to 'target'
	return (fiber_suspension) {(uintptr_t) &stack_top[-8]};
}