module frontend.check.checkCtx;

@safe @nogc pure nothrow:

import frontend.check.instantiate : InstantiateCtx;
import model.ast : pathRange;
import model.diag : Diag, Diagnostic;
import model.model :
	FunDecl,
	ImportOrExport,
	ImportOrExportKind,
	Module,
	nameFromNameReferents,
	NameReferents,
	SpecDecl,
	StructAlias,
	StructDecl,
	StructOrAlias,
	Visibility;
import util.alloc.alloc : Alloc;
import util.col.array : exists, ptrsRange;
import util.col.arrayBuilder : add, ArrayBuilder, finish;
import util.col.hashTable : existsInHashTable;
import util.col.mutSet : mayAddToMutSet, MutSet, mutSetHas;
import util.opt : force, has, none, Opt, some;
import util.perf : Perf;
import util.sourceRange : Range, UriAndRange;
import util.symbol : AllSymbols, Symbol;
import util.uri : AllUris, Uri;

struct CheckCtx {
	@safe @nogc pure nothrow:

	private:

	public Alloc* allocPtr;
	public InstantiateCtx instantiateCtx;
	AllSymbols* allSymbolsPtr;
	const AllUris* allUrisPtr;
	public immutable Uri curUri;
	public ImportAndReExportModules importsAndReExports;
	ArrayBuilder!Diagnostic* diagnosticsBuilderPtr;
	UsedSet used;

	public:

	ref Perf perf() return scope =>
		instantiateCtx.perf;

	@trusted ref Alloc alloc() return scope =>
		*allocPtr;

	ref inout(AllSymbols) allSymbols() return scope inout =>
		*allSymbolsPtr;

	ref const(AllUris) allUris() return scope const =>
		*allUrisPtr;

	ref ArrayBuilder!Diagnostic diagnosticsBuilder() return scope =>
		*diagnosticsBuilderPtr;
}

private struct UsedSet {
	private MutSet!(immutable void*) used;
}

private bool isUsed(in UsedSet a, in immutable void* value) =>
	mutSetHas(a.used, value);

private void markUsed(ref Alloc alloc, scope ref UsedSet a, immutable void* value) {
	mayAddToMutSet(alloc, a.used, value);
}

void markUsed(ref CheckCtx ctx, immutable void* a) {
	markUsed(ctx.alloc, ctx.used, a);
}
void markUsed(ref CheckCtx ctx, StructOrAlias a) {
	markUsed(ctx, a.asVoidPointer());
}

void checkForUnused(ref CheckCtx ctx, StructAlias[] aliases, StructDecl[] structs, SpecDecl[] specs, FunDecl[] funs) {
	checkUnusedImports(ctx);
	void checkUnusedDecl(T)(T* decl) {
		if (decl.visibility == Visibility.private_ && !isUsed(ctx.used, decl))
			addDiag(ctx, decl.range, Diag(Diag.Unused(Diag.Unused.Kind(Diag.Unused.Kind.PrivateDecl(decl.name)))));
	}
	foreach (StructAlias* alias_; ptrsRange(aliases))
		checkUnusedDecl(alias_);
	foreach (StructDecl* struct_; ptrsRange(structs))
		checkUnusedDecl(struct_);
	foreach (SpecDecl* spec; ptrsRange(specs))
		checkUnusedDecl(spec);
	foreach (FunDecl* fun; ptrsRange(funs))
		if (!fun.okIfUnused)
			checkUnusedDecl(fun);
}

private void checkUnusedImports(ref CheckCtx ctx) {
	foreach (ref ImportOrExport import_; ctx.importsAndReExports.imports) {
		void addDiagUnused(Module* module_, Opt!Symbol name) {
			addDiag(
				ctx,
				pathRange(ctx.allUris, *force(import_.source)),
				Diag(Diag.Unused(Diag.Unused.Kind(Diag.Unused.Kind.Import(module_, name)))));
		}
		import_.kind.match!void(
			(ImportOrExportKind.ModuleWhole) {
				if (!isUsedModuleWhole(ctx, import_.module_) && has(import_.source))
					addDiagUnused(import_.modulePtr, none!Symbol);
			},
			(Opt!(NameReferents*)[] referents) {
				foreach (Opt!(NameReferents*) x; referents)
					if (has(x) && !containsUsed(*force(x), ctx.used))
						addDiagUnused(import_.modulePtr, some(force(x).name));
			});
	}
}

private bool isUsedModuleWhole(in CheckCtx ctx, in Module module_) =>
	existsInHashTable!(NameReferents, Symbol, nameFromNameReferents)(module_.allExportedNames, (in NameReferents x) =>
		containsUsed(x, ctx.used));

private bool containsUsed(in NameReferents a, in UsedSet used) =>
	(has(a.structOrAlias) && isUsed(used, force(a.structOrAlias).asVoidPointer())) ||
	(has(a.spec) && isUsed(used, force(a.spec))) ||
	exists!(immutable FunDecl*)(a.funs, (in FunDecl* x) =>
		isUsed(used, x));

immutable struct ImportAndReExportModules {
	immutable ImportOrExport[] imports;
	immutable ImportOrExport[] reExports;
}

void eachImportAndReExport(
	in ImportAndReExportModules a,
	Symbol name,
	in void delegate(in NameReferents) @safe @nogc pure nothrow cb,
) {
	void inner(ref ImportOrExport import_) {
		import_.kind.match!void(
			(ImportOrExportKind.ModuleWhole) {
				Opt!NameReferents x = import_.module_.allExportedNames[name];
				if (has(x)) cb(force(x));
			},
			(Opt!(NameReferents*)[] referents) {
				foreach (Opt!(NameReferents*) x; referents)
					if (has(x) && force(x).name == name)
						cb(*force(x));
			});
	}
	foreach (ref ImportOrExport m; a.imports)
		inner(m);
	foreach (ref ImportOrExport m; a.reExports)
		inner(m);
}

UriAndRange rangeInFile(in CheckCtx ctx, in Range range) =>
	UriAndRange(ctx.curUri, range);

void addDiag(ref CheckCtx ctx, in UriAndRange range, Diag diag) {
	assert(range.uri == ctx.curUri);
	addDiag(ctx, range.range, diag);
}

void addDiag(ref CheckCtx ctx, in Range range, Diag diag) {
	add(ctx.alloc, ctx.diagnosticsBuilder, Diagnostic(range, diag));
}

Diagnostic[] finishDiagnostics(ref CheckCtx ctx) =>
	finish(ctx.alloc, ctx.diagnosticsBuilder);
