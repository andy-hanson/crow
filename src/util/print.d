module util.print;

@safe @nogc nothrow: // not pure

import core.stdc.stdio : fprintf, printf, stderr;

import util.collection.arr : begin, size;
import util.collection.str : Str;

@trusted void print(immutable Str s) {
	printf("%.*s", cast(int) size(s), begin(s));
}

@trusted void print(immutable char* s) {
	printf("%s", s);
}

@trusted void printErr(immutable char* s) {
	fprintf(stderr, "%s", s);
}
