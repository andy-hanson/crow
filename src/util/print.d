module util.print;

@safe @nogc nothrow: // not pure

@trusted void print(immutable char* s) {
	import core.stdc.stdio : printf;
	printf("%s", s);
}

@trusted void printErr(immutable char* s) {
	import core.stdc.stdio : fprintf, stderr;
	fprintf(stderr, "%s", s);
}
