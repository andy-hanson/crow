#include <stdbool.h>
#include <stdint.h>

#ifdef _MSC_VER
#define EXTERN __declspec(dllexport) extern
#else
#define EXTERN extern
#endif

EXTERN void f_void(void f(void)) {
	f();
}

EXTERN bool f_bool(bool a, bool f(bool)) {
	return f(a);
}

EXTERN char f_char8(char a, char f(char)) {
	return f(a);
}

EXTERN int8_t f_int8(int8_t a, int8_t f(int8_t)) {
	return f(a);
}

EXTERN int16_t f_int16(int16_t a, int16_t f(int16_t)) {
	return f(a);
}

EXTERN int32_t f_int32(int32_t a, int32_t f(int32_t)) {
	return f(a);
}

EXTERN int64_t f_int64(int64_t a, int64_t f(int64_t)) {
	return f(a);
}

EXTERN uint8_t f_nat8(uint8_t a, uint8_t f(uint8_t)) {
	return f(a);
}

EXTERN uint16_t f_nat16(uint16_t a, uint16_t f(uint16_t)) {
	return f(a);
}

EXTERN uint32_t f_nat32(uint32_t a, uint32_t f(uint32_t)) {
	return f(a);
}

EXTERN uint64_t f_nat64(uint64_t a, uint64_t f(uint64_t)) {
	return f(a);
}

EXTERN float f_float32(float a, float f(float)) {
	return f(a);
}

EXTERN double f_float64(double a, double f(double)) {
	return f(a);
}

EXTERN uint64_t const* f_nat64_ptr(uint64_t const* a, uint64_t const* f(uint64_t const*)) {
	return f(a);
}

typedef struct struct_a {
	bool b;
	uint64_t n;
} struct_a;

typedef struct struct_b {
	bool b;
	struct_a a;
} struct_b;

EXTERN struct_a f_struct_a(struct_a a, struct_a f(struct_a)) {
	return f(a);
}

EXTERN struct_b f_struct_b(struct_b a, struct_b f(struct_b)) {
	return f(a);
}
