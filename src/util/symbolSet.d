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
	bool has(Symbol x) scope const =>
		contains(symbols, x);

	bool containsAll(in SymbolSet b) scope const =>
		// TODO:PERF: Use the fact that they are both sorted! --------------------------------------------------------------------------
		every!Symbol(b.symbols, (in Symbol x) =>
			has(x));

	SymbolSet add(Symbol x) const =>
		addSymbol(this, x);
	SymbolSet addAll(in Symbol[] xs) const =>
		fold!(SymbolSet, Symbol)(this, xs, (SymbolSet acc, in Symbol x) =>
			acc.add(x));
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
	emptySymbolSet.add(a);

private @trusted pure SymbolSet addSymbol(SymbolSet a, Symbol b) {
	assert(!a.has(b));
	return (cast(SymbolSet function(SymbolSet, Symbol) @safe @nogc pure nothrow) &addSymbolImpure)(a, b);
}

private @system SymbolSet addSymbolImpure(SymbolSet a, Symbol b) =>
	// TODO: MEMOIZE ------------------------------------------------------------------------------------------------------------------
	SymbolSet(append!Symbol(*symbolSetAlloc, a.symbols, b));

// TODO: unit test this module ------------------------------------------------------------------------------------------------