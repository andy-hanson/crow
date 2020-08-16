@safe @nogc nothrow: // not pure

import core.stdc.stdio : printf;

import frontend.ast : TypeAst;
import frontend.frontendCompile : frontendCompile;

import util.alloc.mallocator : Mallocator;
import util.alloc.stackAlloc : StackAlloc;
import util.bools : False, True;
import util.collection.arr : Arr, at, size;
import util.collection.arrUtil : arrLiteral;
import util.collection.str : strLiteral;
import util.sourceRange : Pos, SourceRange;
import util.sym : AllSymbols, getSymFromAlphaIdentifier, Sym;

import compiler : build;
import cli : cli;

import util.opt : has, Opt, some;

extern(C) int main(immutable size_t argc, immutable char** argv) {
	//test(); return 0;
	return cli(argc, argv);
}

pure:

void test() {
	StackAlloc!("foo", 1024 * 1024) alloc;
	everyPairWithIndex!int(arrLiteral!int(alloc, 5, 8, 13), (ref immutable int a, ref immutable int b, immutable size_t c, immutable size_t d) {
		debug {
			printf("?? %d %d %lu %lu\n", a, b, c, d);
		}
	});
}

//TODO:MOVE
void everyPairWithIndex(T)(
	immutable Arr!T a,
	scope void delegate(ref immutable T, ref immutable T, immutable size_t, immutable size_t) @safe @nogc pure nothrow cb,
) {
	foreach (immutable size_t i; 0..size(a))
		foreach (immutable size_t j; 0..i)
			cb(at(a, j), at(a, i), j, i);
}
