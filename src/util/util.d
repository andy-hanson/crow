module util.util;

@safe @nogc pure nothrow:

T todo(T)(immutable char* message) {
	printf("TODO: %s\n", message);
	assert(0);
}
