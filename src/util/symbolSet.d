module util.symbolSet;

@safe @nogc nothrow:

import util.alloc.alloc : Alloc, AllocKind, MetaAlloc, newAlloc;
import util.col.array : append, contains, emptySmallArray, every, fold, isEmpty, MutSmallArray, only, SmallArray;
import util.opt : Opt, optIf;
import util.symbol : Symbol;

struct MutSymbolSet {
	@safe @nogc pure nothrow:

	MutSmallArray!Symbol symbols;

	Opt!Symbol asSingle() scope const =>
		optIf(symbols.length == 1, () => only(symbols));
	bool isEmpty() scope const =>
		.isEmpty(symbols);
	
	bool opBinaryRight(string op)(Symbol x) const if (op == "in") =>
		contains(symbols, x);
	bool opBinaryRight(string op)(SymbolSet b) const if (op == "in") =>
		// TODO:PERF: Use the fact that they are both sorted! --------------------------------------------------------------------------
		every!Symbol(b.symbols, (in Symbol x) =>
			x in this);
	SymbolSet opBinary(string op)(Symbol x) const if (op == "|") =>
		addSymbol(this, x);
	SymbolSet opBinary(string op)(in Symbol[] x) const if (op == "|") =>
		addSymbols(this, x);
}
alias SymbolSet = immutable MutSymbolSet;

private __gshared Alloc* symbolSetAlloc;
// private __gshared MutSet!SymbolSet cache; -----------------------------------------------------------------------------------------

@trusted void initSymbolSets(MetaAlloc* metaAlloc) {
	symbolSetAlloc = newAlloc(AllocKind.symbolSet, metaAlloc);
}

pure SymbolSet emptySymbolSet() =>
	SymbolSet(emptySmallArray!Symbol);

pure SymbolSet symbolSet(Symbol a) =>
	addSymbol(emptySymbolSet, a);

private pure SymbolSet addSymbols(SymbolSet a, in Symbol[] xs) =>
	fold!(SymbolSet, Symbol)(a, xs, (SymbolSet acc, in Symbol x) =>
		addSymbol(acc, x));

private @trusted pure SymbolSet addSymbol(SymbolSet a, Symbol b) {
	assert(b !in a);
	return (cast(SymbolSet function(SymbolSet, Symbol) @safe @nogc pure nothrow) &addSymbolImpure)(a, b);
}
private @system SymbolSet addSymbolImpure(SymbolSet a, Symbol b) =>
	// TODO: MEMOIZE ------------------------------------------------------------------------------------------------------------------
	SymbolSet(append!Symbol(*symbolSetAlloc, a.symbols, b));

// TODO: unit test this module ------------------------------------------------------------------------------------------------
