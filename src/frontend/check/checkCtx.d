module frontend.check.checkCtx;

@safe @nogc pure nothrow:

import frontend.check.dicts :
	ModuleLocalAliasIndex,
	ModuleLocalSpecIndex,
	ModuleLocalStructIndex,
	StructOrAliasAndIndex;
import frontend.diagnosticsBuilder : addDiagnostic, DiagnosticsBuilder;
import frontend.programState : ProgramState;
import model.diag : Diag;
import model.model :
	ImportOrExport,
	ImportOrExportKind,
	matchStructOrAlias,
	matchImportOrExportKind,
	NameReferents,
	SpecDecl,
	StructAlias,
	StructDecl,
	Visibility;
import util.alloc.alloc : Alloc;
import util.col.arrUtil : sum;
import util.col.fullIndexDict :
	FullIndexDict, fullIndexDictCastImmutable, fullIndexDictOfArr, fullIndexDictZipPtrs, makeFullIndexDict_mut;
import util.opt : force, has, none, Opt, some;
import util.perf : Perf;
import util.sourceRange : FileAndPos, FileAndRange, FileIndex, Pos, RangeWithinFile;
import util.sym : AllSymbols, indexOfSym, Sym;

struct CheckCtx {
	@safe @nogc pure nothrow:

	private:

	Alloc* allocPtr;
	Perf* perfPtr;
	ProgramState* programStatePtr;
	AllSymbols* allSymbolsPtr;
	public immutable FileIndex fileIndex;
	immutable ImportOrExport[] imports;
	immutable ImportOrExport[] reExports;
	// One entry for a whole-module import, or one entry for each named import
	// Note: This is unnecessary for re-exports as those are never considered unused, but simpler to always have this
	FullIndexDict!(ImportIndex, bool) importsAndReExportsUsed;
	FullIndexDict!(ModuleLocalAliasIndex, bool) structAliasesUsed;
	FullIndexDict!(ModuleLocalStructIndex, bool) structsUsed;
	FullIndexDict!(ModuleLocalSpecIndex, bool) specsUsed;
	DiagnosticsBuilder* diagsBuilderPtr;

	public:

	@trusted ref Alloc alloc() return scope =>
		*allocPtr;

	ref const(AllSymbols) allSymbols() return scope const =>
		*allSymbolsPtr;
	ref AllSymbols allSymbols() return scope =>
		*allSymbolsPtr;

	ref Perf perf() return scope =>
		*perfPtr;

	@trusted ref ProgramState programState() return scope =>
		*programStatePtr;

	ref DiagnosticsBuilder diagsBuilder() return scope =>
		*diagsBuilderPtr;
}

FullIndexDict!(ImportIndex, bool) newUsedImportsAndReExports(
	ref Alloc alloc,
	immutable ImportOrExport[] imports,
	immutable ImportOrExport[] reExports,
) =>
	makeFullIndexDict_mut!(ImportIndex, bool)(
		alloc,
		sum(imports, (ref immutable ImportOrExport x) => countImportsForUsed(x)) +
			sum(reExports, (ref immutable ImportOrExport x) => countImportsForUsed(x)),
		(immutable(ImportIndex)) => false);

private immutable(size_t) countImportsForUsed(scope ref immutable ImportOrExport a) =>
	matchImportOrExportKind!(immutable size_t)(
		a.kind,
		(immutable(ImportOrExportKind.ModuleWhole)) => 1,
		(immutable ImportOrExportKind.ModuleNamed m) => m.names.length);

void checkForUnused(
	ref CheckCtx ctx,
	immutable StructAlias[] structAliases,
	immutable StructDecl[] structDecls,
	immutable SpecDecl[] specDecls,
) {
	checkUnusedImports(ctx);

	fullIndexDictZipPtrs!(ModuleLocalAliasIndex, StructAlias, bool)(
		fullIndexDictOfArr!(ModuleLocalAliasIndex, StructAlias)(structAliases),
		fullIndexDictCastImmutable(ctx.structAliasesUsed),
		(immutable(ModuleLocalAliasIndex), immutable StructAlias* alias_, immutable bool* used) {
			final switch (alias_.visibility) {
				case Visibility.public_:
					break;
				case Visibility.private_:
					if (!*used)
						addDiag(ctx, alias_.range, immutable Diag(
							immutable Diag.UnusedPrivateStructAlias(alias_)));
			}
		});

	fullIndexDictZipPtrs!(ModuleLocalStructIndex, StructDecl, bool)(
		fullIndexDictOfArr!(ModuleLocalStructIndex, StructDecl)(structDecls),
		fullIndexDictCastImmutable(ctx.structsUsed),
		(immutable(ModuleLocalStructIndex), immutable StructDecl* struct_, immutable bool* used) {
			final switch (struct_.visibility) {
				case Visibility.public_:
					break;
				case Visibility.private_:
					if (!*used)
						addDiag(ctx, struct_.range, immutable Diag(
							immutable Diag.UnusedPrivateStruct(struct_)));
			}
		});

	fullIndexDictZipPtrs!(ModuleLocalSpecIndex, SpecDecl, bool)(
		fullIndexDictOfArr!(ModuleLocalSpecIndex, SpecDecl)(specDecls),
		fullIndexDictCastImmutable(ctx.specsUsed),
		(immutable(ModuleLocalSpecIndex), immutable SpecDecl* spec, immutable bool* used) {
			final switch (spec.visibility) {
				case Visibility.public_:
					break;
				case Visibility.private_:
					if (!*used)
						addDiag(ctx, spec.range, immutable Diag(immutable Diag.UnusedPrivateSpec(spec)));
			}
		});
}

private void checkUnusedImports(ref CheckCtx ctx) {
	size_t index = 0;
	foreach (ref immutable ImportOrExport x; ctx.imports) {
		matchImportOrExportKind!void(
			x.kind,
			(immutable ImportOrExportKind.ModuleWhole m) {
				if (!ctx.importsAndReExportsUsed[immutable ImportIndex(index)] && has(x.importSource))
					addDiag(ctx, force(x.importSource), immutable Diag(
						immutable Diag.UnusedImport(m.modulePtr, none!Sym)));
				index++;
			},
			(immutable ImportOrExportKind.ModuleNamed m) {
				foreach (immutable Sym name; m.names) {
					if (!ctx.importsAndReExportsUsed[immutable ImportIndex(index)] && has(x.importSource))
						addDiag(ctx, force(x.importSource), immutable Diag(
							immutable Diag.UnusedImport(m.modulePtr, some(name))));
					index++;
				}
			});
	}
}

// Index of an imported module / name.
// If named imports are used, there's an index per name. Else, a single index for the whole module.
struct ImportIndex {
	immutable size_t index;
}

void markUsedStructOrAlias(ref CheckCtx ctx, ref immutable StructOrAliasAndIndex a) {
	matchStructOrAlias!void(
		a.structOrAlias,
		(ref immutable StructAlias) {
			ctx.structAliasesUsed[a.index.asAlias] = true;
		},
		(ref immutable StructDecl) {
			ctx.structsUsed[a.index.asStruct] = true;
		});
}

void markUsedSpec(ref CheckCtx ctx, immutable ModuleLocalSpecIndex a) {
	ctx.specsUsed[a] = true;
}

void markUsedImport(ref CheckCtx ctx, immutable ImportIndex index) {
	ctx.importsAndReExportsUsed[index] = true;
}

void eachImportAndReExport(
	scope ref const CheckCtx ctx,
	immutable Sym name,
	scope void delegate(immutable ImportIndex index, ref immutable NameReferents) @safe @nogc pure nothrow cb,
) {
	size_t index = 0;
	void inner(ref immutable ImportOrExport m) {
		immutable size_t startIndex = index;
		immutable Opt!ImportIndexAndReferents importIndexAndReferents = matchImportOrExportKind(
			m.kind,
			(immutable ImportOrExportKind.ModuleWhole m) {
				index++;
				immutable Opt!NameReferents referents = m.module_.allExportedNames[name];
				return has(referents)
					? some(immutable ImportIndexAndReferents(immutable ImportIndex(startIndex), force(referents)))
					: none!ImportIndexAndReferents;
			},
			(immutable ImportOrExportKind.ModuleNamed m) {
				index += m.names.length;
				immutable Opt!size_t symIndex = indexOfSym(m.names, name);
				if (has(symIndex)) {
					immutable Opt!NameReferents referents = m.module_.allExportedNames[name];
					return has(referents)
						? some(immutable ImportIndexAndReferents(
							immutable ImportIndex(startIndex + force(symIndex)),
							force(referents)))
						: none!ImportIndexAndReferents;
				} else
					return none!ImportIndexAndReferents;
			});
		if (has(importIndexAndReferents)) {
			immutable ImportIndexAndReferents ir = force(importIndexAndReferents);
			cb(ir.importIndex, ir.referents);
		}
	}
	foreach (ref immutable ImportOrExport m; ctx.imports)
		inner(m);
	foreach (ref immutable ImportOrExport m; ctx.reExports)
		inner(m);

}

private struct ImportIndexAndReferents {
	immutable ImportIndex importIndex;
	immutable NameReferents referents;
}

immutable(FileAndPos) posInFile(scope ref const CheckCtx ctx, ref immutable Pos pos) =>
	immutable FileAndPos(ctx.fileIndex, pos);

immutable(FileAndRange) rangeInFile(scope ref const CheckCtx ctx, immutable RangeWithinFile range) =>
	immutable FileAndRange(ctx.fileIndex, range);

void addDiag(ref CheckCtx ctx, immutable FileAndRange range, immutable Diag diag) {
	addDiagnostic(ctx.alloc, ctx.diagsBuilder, range, diag);
}

void addDiag(ref CheckCtx ctx, immutable RangeWithinFile range, immutable Diag diag) {
	addDiag(ctx, immutable FileAndRange(ctx.fileIndex, range), diag);
}

