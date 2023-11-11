module frontend.check.checkCtx;

@safe @nogc pure nothrow:

import frontend.diagnosticsBuilder : addDiagnostic, DiagnosticsBuilder;
import frontend.programState : ProgramState;
import model.diag : Diag;
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
import util.col.arrUtil : contains, exists;
import util.col.map : existsInMap;
import util.col.mutMap : hasKey_mut, MutMap, setInMap;
import util.opt : force, has, none, Opt, some;
import util.perf : Perf;
import util.sourceRange : UriAndRange, RangeWithinFile;
import util.sym : AllSymbols, Sym;
import util.uri : Uri;

struct CheckCtx {
	@safe @nogc pure nothrow:

	private:

	public Alloc* allocPtr;
	Perf* perfPtr;
	public ProgramState* programStatePtr;
	AllSymbols* allSymbolsPtr;
	public immutable Uri curUri;
	public ImportsAndReExports importsAndReExports;
	DiagnosticsBuilder* diagsBuilderPtr;
	UsedSet used;

	public:

	@trusted ref Alloc alloc() return scope =>
		*allocPtr;

	ref inout(AllSymbols) allSymbols() return scope inout =>
		*allSymbolsPtr;

	ref Perf perf() return scope =>
		*perfPtr;

	@trusted ref ProgramState programState() return scope =>
		*programStatePtr;

	ref DiagnosticsBuilder diagsBuilder() return scope =>
		*diagsBuilderPtr;
}

private struct UsedSet {
	private MutMap!(immutable void*, immutable void[0]) used;
}

private bool isUsed(in UsedSet a, in immutable void* value) =>
	hasKey_mut!(immutable void*, immutable void[0])(a.used, value);

private void markUsed(ref Alloc alloc, scope ref UsedSet a, immutable void* value) {
	setInMap!(immutable void*, immutable void[0])(alloc, a.used, value, []);
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
		if (!okIfUnused(*fun))
			checkUnusedDecl(fun);
}

private void checkUnusedImports(ref CheckCtx ctx) {
	foreach (ref ImportOrExport x; ctx.importsAndReExports.imports)
		x.kind.match!void(
			(ImportOrExportKind.ModuleWhole m) {
				if (!isUsedModuleWhole(ctx, m.module_) && has(x.importSource))
					addDiag(ctx, force(x.importSource), Diag(
						Diag.Unused(Diag.Unused.Kind(Diag.Unused.Kind.Import(m.modulePtr, none!Sym)))));
			},
			(ImportOrExportKind.ModuleNamed m) {
				foreach (Sym name; m.names) {
					if (!isUsedNamedImport(ctx, m.module_, name))
						addDiag(ctx, force(x.importSource), Diag(
							Diag.Unused(Diag.Unused.Kind(Diag.Unused.Kind.Import(m.modulePtr, some(name))))));
				}
			});
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

immutable struct ImportsAndReExports {
	immutable ImportOrExport[] imports;
	immutable ImportOrExport[] reExports;
}

void eachImportAndReExport(
	in ImportsAndReExports a,
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

UriAndRange rangeInFile(in CheckCtx ctx, RangeWithinFile range) =>
	UriAndRange(ctx.curUri, range);

void addDiag(ref CheckCtx ctx, UriAndRange range, Diag diag) {
	addDiagnostic(ctx.diagsBuilder, range, diag);
}

void addDiag(ref CheckCtx ctx, RangeWithinFile range, Diag diag) {
	addDiag(ctx, UriAndRange(ctx.curUri, range), diag);
}

