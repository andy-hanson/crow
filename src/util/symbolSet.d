module util.symbolSet;

@safe @nogc nothrow:

import util.alloc.alloc : Alloc, AllocKind, MetaAlloc, newAlloc;
import util.col.array : append, contains, emptySmallArray, isEmpty, MutSmallArray, only, SmallArray;
import util.opt : Opt, optIf;
import util.symbol : Symbol;

struct MutSymbolSet {
	@safe @nogc pure nothrow:

	private MutSmallArray!Symbol symbols;

	Opt!Symbol asSingle() scope const =>
		optIf(symbols.length == 1, () => only(symbols));
	bool isEmpty() scope const =>
		.isEmpty(symbols);
	bool has(Symbol x) scope const =>
		contains(symbols, x);

	SymbolSet add(Symbol x) =>
		addSymbol(this, x);
}
alias SymbolSet = immutable MutSymbolSet;

private __gshared Alloc* symbolSetAlloc;
// private __gshared MutSet!SymbolSet cache; -----------------------------------------------------------------------------------------

@trusted void initSymbolSets(MetaAlloc* metaAlloc) {
	symbolSetAlloc = newAlloc(AllocKind.symbolSet, metaAlloc);
}

pure SymbolSet emptySymbolSet() =>
	SymbolSet(emptySmallArray!Symbol);

private @trusted pure SymbolSet addSymbol(SymbolSet a, Symbol b) =>
	(cast(SymbolSet function(SymbolSet, Symbol) @safe @nogc pure nothrow) &addSymbolImpure)(a, b);

private @system SymbolSet addSymbolImpure(SymbolSet a, Symbol b) =>
	// TODO: MEMOIZE ------------------------------------------------------------------------------------------------------------------
	SymbolSet(append!Symbol(*symbolSetAlloc, a.symbols, b));
