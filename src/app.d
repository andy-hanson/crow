@safe @nogc pure nothrow:

import core.stdc.stdio : printf;

import frontend.ast : match, TypeAst;
import frontend.frontendCompile : frontendCompile;

import util.alloc.mallocator : Mallocator;
import util.collection.str : strLiteral;
import util.sourceRange : Pos, SourceRange;
import util.sym : AllSymbols, getSymFromAlphaIdentifier, Sym;


int foo(immutable TypeAst a) {
	return match!int(a, (immutable ref TypeAst.TypeParam) => 1, (immutable ref TypeAst.InstStruct) => 2);
}

extern(C) int main() {
	AllSymbols!Mallocator symbols = AllSymbols!Mallocator(Mallocator());
	immutable Sym name = symbols.getSymFromAlphaIdentifier(strLiteral("abc"));
	immutable SourceRange range = SourceRange(Pos(0), Pos(0));
	immutable TypeAst a = TypeAst(TypeAst.TypeParam(range, name));
	debug {
		printf("%d", foo(a));
	}
	return 0;
}
