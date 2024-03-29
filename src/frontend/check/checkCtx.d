module frontend.check.checkCtx;

@safe @nogc pure nothrow:

import frontend.check.instantiate : InstantiateCtx;
import model.ast : NameAndRange, typeParamsRange, VisibilityAndRange;
import model.diag : DeclKind, Diag, Diagnostic;
import model.model :
	ExportVisibility,
	FunDecl,
	importCanSee,
	ImportOrExport,
	ImportOrExportKind,
	Module,
	nameFromNameReferents,
	NameReferents,
	SpecDecl,
	StructAlias,
	StructDecl,
	StructOrAlias,
	TypeParams,
	Visibility;
import util.alloc.alloc : Alloc;
import util.col.array : exists, isEmpty, SmallArray;
import util.col.arrayBuilder : add, ArrayBuilder, smallFinish;
import util.col.enumMap : EnumMap;
import util.col.hashTable : existsInHashTable;
import util.col.mutSet : mayAddToMutSet, MutSet, mutSetHas;
import util.opt : force, has, none, Opt, some;
import util.perf : Perf;
import util.sourceRange : Range, UriAndRange;
import util.symbol : Symbol;
import util.uri : Uri;

struct CheckCtx {
	@safe @nogc pure nothrow:

	Alloc* allocPtr;
	InstantiateCtx instantiateCtx;
	immutable CommonUris* commonUrisPtr;
	immutable Uri curUri;
	immutable ImportAndReExportModules importsAndReExports;
	ArrayBuilder!Diagnostic* diagnosticsBuilderPtr;
	UsedSet used;

	ref Perf perf() return scope =>
		instantiateCtx.perf;

	@trusted ref Alloc alloc() return scope =>
		*allocPtr;

	ref CommonUris commonUris() return scope const =>
		*commonUrisPtr;

	ref ArrayBuilder!Diagnostic diagnosticsBuilder() return scope =>
		*diagnosticsBuilderPtr;
}

enum CommonModule {
	bootstrap,
	alloc,
	boolLowLevel,
	compare,
	exceptionLowLevel,
	funUtil,
	future,
	json,
	list,
	misc,
	numberLowLevel,
	std,
	string_,
	symbolLowLevel,
	runtimeMain,
}
alias CommonUris = immutable EnumMap!(CommonModule, Uri);

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
	markUsed(ctx, a.asVoidPointer);
}

void checkForUnused(ref CheckCtx ctx, StructAlias[] aliases, StructDecl[] structs, SpecDecl[] specs, FunDecl[] funs) {
	checkUnusedImports(ctx);
	void checkUnusedDecl(T)(T* decl) {
		if (decl.visibility == Visibility.private_ && !isUsed(ctx.used, decl))
			addDiagAssertSameUri(ctx, decl.nameRange, Diag(
				Diag.Unused(Diag.Unused.Kind(Diag.Unused.Kind.PrivateDecl(decl.name)))));
	}
	foreach (ref StructAlias alias_; aliases)
		checkUnusedDecl(&alias_);
	foreach (ref StructDecl struct_; structs)
		checkUnusedDecl(&struct_);
	foreach (ref SpecDecl spec; specs)
		checkUnusedDecl(&spec);
	foreach (ref FunDecl fun; funs)
		if (!fun.okIfUnused)
			checkUnusedDecl(&fun);
}

private void checkUnusedImports(ref CheckCtx ctx) {
	foreach (ref ImportOrExport import_; ctx.importsAndReExports.imports) {
		void addDiagUnused(Range range, Opt!Symbol name) {
			addDiag(ctx, range, Diag(Diag.Unused(Diag.Unused.Kind(Diag.Unused.Kind.Import(import_.modulePtr, name)))));
		}
		import_.kind.match!void(
			(ImportOrExportKind.ModuleWhole) {
				if (!isUsedModuleWhole(ctx, import_.module_, import_.importVisibility) && has(import_.source))
					addDiagUnused(force(import_.source).pathRange, none!Symbol);
			},
			(Opt!(NameReferents*)[] referents) {
				foreach (size_t index, Opt!(NameReferents*) x; referents)
					if (has(x) && !containsUsed(*force(x), import_.importVisibility, ctx.used)) {
						NameAndRange nr = force(import_.source).kind.as!(NameAndRange[])[index];
						assert(nr.name == force(x).name);
						addDiagUnused(nr.range, some(force(x).name));
					}
			});
	}
}

private bool isUsedModuleWhole(in CheckCtx ctx, in Module module_, ExportVisibility importVisibility) =>
	existsInHashTable!(NameReferents, Symbol, nameFromNameReferents)(module_.exports, (in NameReferents x) =>
		containsUsed(x, importVisibility, ctx.used));

private bool containsUsed(in NameReferents a, ExportVisibility importVisibility, in UsedSet used) =>
	(has(a.structOrAlias) &&
		importCanSee(importVisibility, force(a.structOrAlias).visibility) &&
		isUsed(used, force(a.structOrAlias).asVoidPointer)) ||
	(has(a.spec) && importCanSee(importVisibility, force(a.spec).visibility) && isUsed(used, force(a.spec))) ||
	exists!(immutable FunDecl*)(a.funs, (in FunDecl* x) =>
		importCanSee(importVisibility, x.visibility) && isUsed(used, x));

immutable struct ImportAndReExportModules {
	immutable ImportOrExport[] imports;
	immutable ImportOrExport[] reExports;
}

void eachImportAndReExport(
	in ImportAndReExportModules a,
	Symbol name,
	// Caller is responsible for filtering by visibility
	in void delegate(ExportVisibility, in NameReferents) @safe @nogc pure nothrow cb,
) {
	void inner(ref ImportOrExport import_) {
		import_.kind.match!void(
			(ImportOrExportKind.ModuleWhole) {
				Opt!NameReferents x = import_.module_.exports[name];
				if (has(x)) cb(import_.importVisibility, force(x));
			},
			(Opt!(NameReferents*)[] referents) {
				foreach (Opt!(NameReferents*) x; referents)
					if (has(x) && force(x).name == name)
						cb(import_.importVisibility, *force(x));
			});
	}
	foreach (ref ImportOrExport m; a.imports)
		inner(m);
	foreach (ref ImportOrExport m; a.reExports)
		inner(m);
}

void addDiagAssertSameUri(ref CheckCtx ctx, in UriAndRange range, Diag diag) {
	assert(range.uri == ctx.curUri);
	addDiag(ctx, range.range, diag);
}

void addDiag(ref CheckCtx ctx, in Range range, Diag diag) {
	add(ctx.alloc, ctx.diagnosticsBuilder, Diagnostic(range, diag));
}

SmallArray!Diagnostic finishDiagnostics(ref CheckCtx ctx) =>
	smallFinish(ctx.alloc, ctx.diagnosticsBuilder);

Visibility visibilityFromDefaultWithDiag(
	scope ref CheckCtx ctx,
	Visibility default_,
	in Opt!VisibilityAndRange explicit,
	Diag.VisibilityWarning.Kind kind,
) {
	if (has(explicit)) {
		Visibility actual = force(explicit).visibility;
		if (actual < default_)
			return actual;
		else {
			addDiag(ctx, force(explicit).range, Diag(Diag.VisibilityWarning(kind, default_, actual)));
			return default_;
		}
	} else
		return default_;
}

Visibility visibilityFromExplicitTopLevel(Opt!VisibilityAndRange a) =>
	has(a)
		? force(a).visibility
		: Visibility.internal;

void checkNoTypeParams(ref CheckCtx ctx, in TypeParams typeParams, DeclKind declKind) {
	if (!isEmpty(typeParams))
		addDiag(ctx, typeParamsRange(typeParams), Diag(Diag.TypeParamsUnsupported(declKind)));
}
