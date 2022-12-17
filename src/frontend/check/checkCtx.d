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
import model.model : ImportOrExport, ImportOrExportKind, NameReferents, SpecDecl, StructAlias, StructDecl, Visibility;
import util.alloc.alloc : Alloc;
import util.col.arrUtil : indexOf, sum;
import util.col.fullIndexDict : FullIndexDict, fullIndexDictOfArr, fullIndexDictZipPtrFirst, makeFullIndexDict_mut;
import util.opt : force, has, none, Opt, some;
import util.perf : Perf;
import util.sourceRange : FileAndPos, FileAndRange, FileIndex, Pos, RangeWithinFile;
import util.sym : AllSymbols, Sym;

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

	ref inout(AllSymbols) allSymbols() return scope inout =>
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
	ImportOrExport[] imports,
	ImportOrExport[] reExports,
) =>
	makeFullIndexDict_mut!(ImportIndex, bool)(
		alloc,
		sum!ImportOrExport(imports, (in ImportOrExport x) => countImportsForUsed(x)) +
			sum!ImportOrExport(reExports, (in ImportOrExport x) => countImportsForUsed(x)),
		(ImportIndex _) => false);

private size_t countImportsForUsed(in ImportOrExport a) =>
	a.kind.matchIn!size_t(
		(in ImportOrExportKind.ModuleWhole) =>
			1,
		(in ImportOrExportKind.ModuleNamed m) =>
			m.names.length);

void checkForUnused(ref CheckCtx ctx, StructAlias[] structAliases, StructDecl[] structDecls, SpecDecl[] specDecls) {
	checkUnusedImports(ctx);

	fullIndexDictZipPtrFirst!(ModuleLocalAliasIndex, StructAlias, bool)(
		fullIndexDictOfArr!(ModuleLocalAliasIndex, StructAlias)(structAliases),
		ctx.structAliasesUsed,
		(ModuleLocalAliasIndex _, StructAlias* alias_, in bool used) {
			final switch (alias_.visibility) {
				case Visibility.private_:
					if (!used)
						addDiag(ctx, alias_.range, Diag(Diag.UnusedPrivateStructAlias(alias_)));
					break;
				case Visibility.internal:
				case Visibility.public_:
					break;
			}
		});

	fullIndexDictZipPtrFirst!(ModuleLocalStructIndex, StructDecl, bool)(
		fullIndexDictOfArr!(ModuleLocalStructIndex, StructDecl)(structDecls),
		ctx.structsUsed,
		(ModuleLocalStructIndex _, StructDecl* struct_, in bool used) {
			final switch (struct_.visibility) {
				case Visibility.private_:
					if (!used)
						addDiag(ctx, struct_.range, Diag(Diag.UnusedPrivateStruct(struct_)));
					break;
				case Visibility.internal:
				case Visibility.public_:
					break;
			}
		});

	fullIndexDictZipPtrFirst!(ModuleLocalSpecIndex, SpecDecl, bool)(
		fullIndexDictOfArr!(ModuleLocalSpecIndex, SpecDecl)(specDecls),
		ctx.specsUsed,
		(ModuleLocalSpecIndex _, SpecDecl* spec, in bool used) {
			final switch (spec.visibility) {
				case Visibility.private_:
					if (!used)
						addDiag(ctx, spec.range, Diag(Diag.UnusedPrivateSpec(spec)));
					break;
				case Visibility.internal:
				case Visibility.public_:
					break;
			}
		});
}

private void checkUnusedImports(ref CheckCtx ctx) {
	size_t index = 0;
	foreach (ref ImportOrExport x; ctx.imports)
		x.kind.match!void(
			(ImportOrExportKind.ModuleWhole m) {
				if (!ctx.importsAndReExportsUsed[ImportIndex(index)] && has(x.importSource))
					addDiag(ctx, force(x.importSource), Diag(Diag.UnusedImport(m.modulePtr, none!Sym)));
				index++;
			},
			(ImportOrExportKind.ModuleNamed m) {
				foreach (Sym name; m.names) {
					if (!ctx.importsAndReExportsUsed[ImportIndex(index)] && has(x.importSource))
						addDiag(ctx, force(x.importSource), Diag(Diag.UnusedImport(m.modulePtr, some(name))));
					index++;
				}
			});
}

// Index of an imported module / name.
// If named imports are used, there's an index per name. Else, a single index for the whole module.
immutable struct ImportIndex {
	size_t index;
}

void markUsedStructOrAlias(ref CheckCtx ctx, in StructOrAliasAndIndex a) {
	a.structOrAlias.matchIn!void(
		(in StructAlias) {
			ctx.structAliasesUsed[a.index.asAlias] = true;
		},
		(in StructDecl) {
			ctx.structsUsed[a.index.asStruct] = true;
		});
}

void markUsedSpec(ref CheckCtx ctx, ModuleLocalSpecIndex a) {
	ctx.specsUsed[a] = true;
}

void markUsedImport(ref CheckCtx ctx, ImportIndex index) {
	ctx.importsAndReExportsUsed[index] = true;
}

void eachImportAndReExport(
	in CheckCtx ctx,
	Sym name,
	in void delegate(ImportIndex index, in NameReferents) @safe @nogc pure nothrow cb,
) {
	size_t index = 0;
	void inner(ref ImportOrExport m) {
		size_t startIndex = index;
		Opt!ImportIndexAndReferents imported = m.kind.match!(Opt!ImportIndexAndReferents)(
			(ImportOrExportKind.ModuleWhole m) {
				index++;
				Opt!NameReferents referents = m.module_.allExportedNames[name];
				return has(referents)
					? some(ImportIndexAndReferents(ImportIndex(startIndex), force(referents)))
					: none!ImportIndexAndReferents;
			},
			(ImportOrExportKind.ModuleNamed m) {
				index += m.names.length;
				Opt!size_t symIndex = indexOf(m.names, name);
				if (has(symIndex)) {
					Opt!NameReferents referents = m.module_.allExportedNames[name];
					return has(referents)
						? some(ImportIndexAndReferents(ImportIndex(startIndex + force(symIndex)), force(referents)))
						: none!ImportIndexAndReferents;
				} else
					return none!ImportIndexAndReferents;
			});
		if (has(imported)) {
			ImportIndexAndReferents ir = force(imported);
			cb(ir.importIndex, ir.referents);
		}
	}
	foreach (ref ImportOrExport m; ctx.imports)
		inner(m);
	foreach (ref ImportOrExport m; ctx.reExports)
		inner(m);
}

private immutable struct ImportIndexAndReferents {
	ImportIndex importIndex;
	NameReferents referents;
}

FileAndPos posInFile(in CheckCtx ctx, Pos pos) =>
	FileAndPos(ctx.fileIndex, pos);

FileAndRange rangeInFile(in CheckCtx ctx, RangeWithinFile range) =>
	FileAndRange(ctx.fileIndex, range);

void addDiag(ref CheckCtx ctx, FileAndRange range, Diag diag) {
	addDiagnostic(ctx.alloc, ctx.diagsBuilder, range, diag);
}

void addDiag(ref CheckCtx ctx, RangeWithinFile range, Diag diag) {
	addDiag(ctx, FileAndRange(ctx.fileIndex, range), diag);
}

