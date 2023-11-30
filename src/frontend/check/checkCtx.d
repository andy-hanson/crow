module frontend.check.checkCtx;

@safe @nogc pure nothrow:

import frontend.parse.ast : pathRange;
import frontend.programState : ProgramState;
import model.diag : Diag, Diagnostic;
import model.model :
	FunDecl,
	ImportOrExport,
	ImportOrExportKind,
	Module,
	NameReferents,
	okIfUnused,
	range,
	SpecDecl,
	StructAlias,
	StructDecl,
	StructOrAlias,
	Visibility;
import util.alloc.alloc : Alloc;
import util.col.arr : ptrsRange;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.col.arrUtil : contains, exists;
import util.col.map : existsInMap;
import util.col.mutSet : mayAddToMutSet, MutSet, mutSetHas;
import util.opt : force, has, none, Opt, some;
import util.perf : Perf;
import util.sourceRange : Range, UriAndRange;
import util.sym : AllSymbols, Sym;
import util.uri : AllUris, Uri;

struct CheckCtx {
	@safe @nogc pure nothrow:

	private:

	public Alloc* allocPtr;
	Perf* perfPtr;
	public ProgramState* programStatePtr;
	AllSymbols* allSymbolsPtr;
	const AllUris* allUrisPtr;
	public immutable Uri curUri;
	public ImportAndReExportModules importsAndReExports;
	ArrBuilder!Diagnostic* diagnosticsBuilder;
	UsedSet used;

	public:

	@trusted ref Alloc alloc() return scope =>
		*allocPtr;

	ref inout(AllSymbols) allSymbols() return scope inout =>
		*allSymbolsPtr;

	ref const(AllUris) allUris() return scope const =>
		*allUrisPtr;

	ref Perf perf() return scope =>
		*perfPtr;

	@trusted ref ProgramState programState() return scope =>
		*programStatePtr;
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
			addDiag(ctx, range(*decl), Diag(Diag.Unused(Diag.Unused.Kind(Diag.Unused.Kind.PrivateDecl(decl.name)))));
	}
	foreach (StructAlias* alias_; ptrsRange(aliases))
		checkUnusedDecl(alias_);
	foreach (StructDecl* struct_; ptrsRange(structs))
		checkUnusedDecl(struct_);
	foreach (SpecDecl* spec; ptrsRange(specs))
		checkUnusedDecl(spec);
	foreach (FunDecl* fun; ptrsRange(funs))
		if (!okIfUnused(*fun))
			checkUnusedDecl(fun);
}

private void checkUnusedImports(ref CheckCtx ctx) {
	foreach (ref ImportOrExport x; ctx.importsAndReExports.imports) {
		void addDiagUnused(Module* module_, Opt!Sym name) {
			addDiag(
				ctx,
				pathRange(ctx.allUris, *force(x.source)),
				Diag(Diag.Unused(Diag.Unused.Kind(Diag.Unused.Kind.Import(module_, name)))));
		}
		x.kind.match!void(
			(ImportOrExportKind.ModuleWhole m) {
				if (!isUsedModuleWhole(ctx, m.module_) && has(x.source))
					addDiagUnused(m.modulePtr, none!Sym);
			},
			(ImportOrExportKind.ModuleNamed m) {
				foreach (Sym name; m.names)
					if (!isUsedNamedImport(ctx, m.module_, name))
						addDiagUnused(m.modulePtr, some(name));
			});
	}
}

private bool isUsedModuleWhole(in CheckCtx ctx, in Module module_) =>
	existsInMap!(Sym, NameReferents)(
		module_.allExportedNames, (in Sym _, in NameReferents x) =>
			containsUsed(x, ctx.used));

private bool isUsedNamedImport(in CheckCtx ctx, in Module module_, Sym name) {
	Opt!NameReferents opt = module_.allExportedNames[name];
	return has(opt) && containsUsed(force(opt), ctx.used);
}

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
	Sym name,
	in void delegate(in NameReferents) @safe @nogc pure nothrow cb,
) {
	void inner(ref ImportOrExport m) {
		Opt!NameReferents imported = m.kind.match!(Opt!NameReferents)(
			(ImportOrExportKind.ModuleWhole m) =>
				m.module_.allExportedNames[name],
			(ImportOrExportKind.ModuleNamed m) =>
				contains(m.names, name) ? m.module_.allExportedNames[name] : none!NameReferents);
		if (has(imported))
			cb(force(imported));
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
	add(ctx.alloc, *ctx.diagnosticsBuilder, Diagnostic(range, diag));
}

Diagnostic[] finishDiagnostics(ref CheckCtx ctx) =>
	finishArr(ctx.alloc, *ctx.diagnosticsBuilder);
