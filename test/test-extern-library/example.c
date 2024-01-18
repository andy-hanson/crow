#include <stdbool.h>
#include <stdint.h>

extern bool f_bool(bool a, bool f(bool)) {
	return f(a);
}

extern char f_char8(char a, char f(char)) {
	return f(a);
}

extern int8_t f_int8(int8_t a, int8_t f(int8_t)) {
	return f(a);
}

extern int16_t f_int16(int16_t a, int16_t f(int16_t)) {
	return f(a);
}

extern int32_t f_int32(int32_t a, int32_t f(int32_t)) {
	return f(a);
}

extern int64_t f_int64(int64_t a, int64_t f(int64_t)) {
	return f(a);
}

extern uint8_t f_nat8(uint8_t a, uint8_t f(uint8_t)) {
	return f(a);
}

extern uint16_t f_nat16(uint16_t a, uint16_t f(uint16_t)) {
	return f(a);
}

extern uint32_t f_nat32(uint32_t a, uint32_t f(uint32_t)) {
	return f(a);
}

extern uint64_t f_nat64(uint64_t a, uint64_t f(uint64_t)) {
	return f(a);
}

extern float f_float32(float a, float f(float)) {
	return f(a);
}

extern double f_float64(double a, double f(double)) {
	return f(a);
}

extern uint64_t const* f_nat64_ptr(uint64_t const* a, uint64_t const* f(uint64_t const*)) {
	return f(a);
}

struct ExampleStruct {
	bool b;
	uint64_t n;
};

extern struct ExampleStruct f_struct(struct ExampleStruct a, struct ExampleStruct f(struct ExampleStruct)) {
	return f(a);
}

/* TODO: still need to test pointers and structs ------------------------------------------------------------------------------------------- */
