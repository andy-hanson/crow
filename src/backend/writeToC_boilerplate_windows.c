#include <math.h> // for e.g. 'sin'
#include <stddef.h> // for NULL
#include <stdint.h>
typedef uint32_t char32_t;

#pragma section(".text")
__declspec(allocate(".text"))
static unsigned char switch_fiber_code[] = {
	// 'from' is rcx, 'to' is rdx
	0x53, // push rbx
	0x55, // push rbp
	0x41, 0x54, // push r12
	0x41, 0x55, // push r13
	0x41, 0x56, // push r14
	0x41, 0x57, // push r15
	// MASM moves from the second argument to the first argument
	0x48, 0x89, 0x21, // mov [rcx], rsp

	0x48, 0x8b, 0xe2, // mov rsp, rdx
	0x41, 0x5f, // pop r15
	0x41, 0x5e, // pop r14
	0x41, 0x5d, // pop r13
	0x41, 0x5c, // pop r12
	0x5d, // pop rbp
	0x5b, // pop rbx
	0xc3, // ret
};
void switch_fiber(uint64_t** from, uint64_t* to) {
	((void (*)(uint64_t**, uint64_t*)) switch_fiber_code)(from, to);
}

// This should match 'makeInitStackFunction' in 'jit.d'
static uint64_t* init_stack(uint64_t* stack_low, uint64_t* stack_top, void (*target)()) {
	stack_top[-2] = (uint64_t) target; // Use -2 because we want it 16-byte aligned
	// It will pop garbage initial values for r15, r14, r13, r12, rbp, rbx, then return to 'target'
	return stack_top - 8;
}
