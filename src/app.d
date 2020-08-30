@safe @nogc nothrow: // not pure

import cli : cli;

extern(C) int main(immutable size_t argc, immutable char** argv) {
	return cli(argc, argv);
}
