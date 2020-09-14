//import frontend.parse : parse;

immutable size_t bufferSize = 1024 * 1024;
char[bufferSize] buffer;

extern(C) immutable(size_t) getBufferSize() {
	return bufferSize;
}

extern(C) char* getBuffer() {
	return buffer.ptr;
}

extern(C) void upperCase() {
	upperCaseInPlace(buffer.ptr);
}

void upperCaseInPlace(char* c) {
	if (*c != '\0') {
		if ('a' <= *c && *c <= 'z') {
			*c = cast(char) (*c + 'A' - 'a');
		}
		upperCaseInPlace(c + 1);
	}
}

// seems to be the required entry point
extern(C) void _start() {}
