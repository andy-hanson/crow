/*@safe*/ @nogc nothrow: // not pure

import core.stdc.stdio : printf;

import frontend.ast : TypeAst;
import frontend.frontendCompile : frontendCompile;

import util.alloc.mallocator : Mallocator;
import util.alloc.stackAlloc : StackAlloc;
import util.collection.str : strLiteral;
import util.sourceRange : Pos, SourceRange;
import util.sym : AllSymbols, getSymFromAlphaIdentifier, Sym;

import compiler : build;
import cli : cli;

import util.opt : has, Opt, some;

extern(C) int main(immutable size_t argc, immutable char** argv) {
	return cli(argc, argv);
}

pure:
