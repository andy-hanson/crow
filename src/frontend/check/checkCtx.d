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
	matchStructOrAlias,
	Module,
	ModuleAndNames,
	NameReferents,
	SpecDecl,
	StructAlias,
	StructDecl,
	Visibility;
import util.alloc.alloc : Alloc;
import util.col.arrUtil : eachCat;
import util.col.fullIndexDict :
	FullIndexDict, fullIndexDictCastImmutable, fullIndexDictOfArr, fullIndexDictZipPtrs, makeFullIndexDict_mut;
import util.opt : force, has, none, Opt, some;
import util.perf : Perf;
import util.ptr : Ptr;
import util.sourceRange : FileAndPos, FileAndRange, FileIndex, Pos, RangeWithinFile;
import util.sym : AllSymbols, indexOfSym, Sym;

struct CheckCtx {
	@safe @nogc pure nothrow:

	private:

	Ptr!Alloc allocPtr;
	Ptr!Perf perfPtr;
	Ptr!ProgramState programStatePtr;
	Ptr!AllSymbols allSymbolsPtr;
	public immutable FileIndex fileIndex;
	immutable ModuleAndNames[] imports;
	immutable ModuleAndNames[] reExports;
	// One entry for a whole-module import, or one entry for each named import
	// Note: This is unnecessary for re-exports as those are never considered unused, but simpler to always have this
	FullIndexDict!(ImportIndex, bool) importsAndReExportsUsed;
	FullIndexDict!(ModuleLocalAliasIndex, bool) structAliasesUsed;
	FullIndexDict!(ModuleLocalStructIndex, bool) structsUsed;
	FullIndexDict!(ModuleLocalSpecIndex, bool) specsUsed;
	Ptr!DiagnosticsBuilder diagsBuilderPtr;

	public:

	ref Alloc alloc() return scope {
		return allocPtr.deref();
	}

	ref const(AllSymbols) allSymbols() return scope const {
		return allSymbolsPtr.deref();
	}
	ref AllSymbols allSymbols() return scope {
		return allSymbolsPtr.deref();
	}

	ref Perf perf() return scope {
		return perfPtr.deref();
	}

	ref ProgramState programState() return scope {
		return programStatePtr.deref();
	}

	ref DiagnosticsBuilder diagsBuilder() return scope {
		return diagsBuilderPtr.deref();
	}
}

FullIndexDict!(ImportIndex, bool) newUsedImportsAndReExports(
	ref Alloc alloc,
	ref immutable ModuleAndNames[] imports,
	ref immutable ModuleAndNames[] reExports,
) {
	immutable size_t size = eachCat!(size_t, ModuleAndNames)(
		0,
		imports,
		reExports,
		(immutable size_t acc, ref immutable ModuleAndNames it) =>
			acc + (has(it.names) ? force(it.names).length : 1));
	return makeFullIndexDict_mut!(ImportIndex, bool)(alloc, size, (immutable(ImportIndex)) => false);
}

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
		(immutable(ModuleLocalAliasIndex), immutable Ptr!StructAlias alias_, immutable Ptr!bool used) {
			final switch (alias_.deref().visibility) {
				case Visibility.public_:
					break;
				case Visibility.private_:
					if (!used.deref())
						addDiag(ctx, alias_.deref().range, immutable Diag(
							immutable Diag.UnusedPrivateStructAlias(alias_)));
			}
		});

	fullIndexDictZipPtrs!(ModuleLocalStructIndex, StructDecl, bool)(
		fullIndexDictOfArr!(ModuleLocalStructIndex, StructDecl)(structDecls),
		fullIndexDictCastImmutable(ctx.structsUsed),
		(immutable(ModuleLocalStructIndex), immutable Ptr!StructDecl struct_, immutable Ptr!bool used) {
			final switch (struct_.deref().visibility) {
				case Visibility.public_:
					break;
				case Visibility.private_:
					if (!used.deref())
						addDiag(ctx, struct_.deref().range, immutable Diag(
							immutable Diag.UnusedPrivateStruct(struct_)));
			}
		});

	fullIndexDictZipPtrs!(ModuleLocalSpecIndex, SpecDecl, bool)(
		fullIndexDictOfArr!(ModuleLocalSpecIndex, SpecDecl)(specDecls),
		fullIndexDictCastImmutable(ctx.specsUsed),
		(immutable(ModuleLocalSpecIndex), immutable Ptr!SpecDecl spec, immutable Ptr!bool used) {
			final switch (spec.deref().visibility) {
				case Visibility.public_:
					break;
				case Visibility.private_:
					if (!used.deref())
						addDiag(ctx, spec.deref().range, immutable Diag(immutable Diag.UnusedPrivateSpec(spec)));
			}
		});
}

private void checkUnusedImports(ref CheckCtx ctx) {
	size_t index = 0;
	foreach (ref immutable ModuleAndNames it; ctx.imports) {
		if (has(it.names)) {
			foreach (ref immutable Sym name; force(it.names)) {
				if (!ctx.importsAndReExportsUsed[immutable ImportIndex(index)] && has(it.importSource))
					addDiag(ctx, force(it.importSource), immutable Diag(
						immutable Diag.UnusedImport(it.modulePtr, some(name))));
				index++;
			}
		} else {
			if (!ctx.importsAndReExportsUsed[immutable ImportIndex(index)] && has(it.importSource))
				addDiag(ctx, force(it.importSource), immutable Diag(
					immutable Diag.UnusedImport(it.modulePtr, none!Sym)));
			index++;
		}
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

immutable(Acc) eachImportAndReExport(Acc)(
	ref const CheckCtx ctx,
	immutable Sym name,
	immutable Acc acc,
	scope immutable(Acc) delegate(
		immutable Acc,
		immutable Ptr!Module,
		immutable ImportIndex index,
		ref immutable NameReferents,
	) @safe @nogc pure nothrow cb,
) {
	size_t index = 0;
	return eachCat!(Acc, ModuleAndNames)(
		acc,
		ctx.imports,
		ctx.reExports,
		(immutable Acc acc, ref immutable ModuleAndNames m) {
			immutable Opt!size_t importIndex = () {
				if (has(m.names)) {
					immutable Opt!size_t symIndex = indexOfSym(force(m.names), name);
					immutable Opt!size_t res = has(symIndex) ? some(index + force(symIndex)) : none!size_t;
					index += force(m.names).length;
					return res;
				} else {
					immutable size_t res = index;
					index++;
					return some(res);
				}
			}();
			if (has(importIndex)) {
				immutable Opt!NameReferents referents = m.module_.allExportedNames[name];
				if (has(referents))
					return cb(acc, m.modulePtr, immutable ImportIndex(force(importIndex)), force(referents));
			}
			return acc;
		});
}

immutable(FileAndPos) posInFile(ref const CheckCtx ctx, ref immutable Pos pos) {
	return immutable FileAndPos(ctx.fileIndex, pos);
}

immutable(FileAndRange) rangeInFile(ref const CheckCtx ctx, immutable RangeWithinFile range) {
	return immutable FileAndRange(ctx.fileIndex, range);
}

void addDiag(ref CheckCtx ctx, immutable FileAndRange range, immutable Diag diag) {
	addDiagnostic(ctx.alloc, ctx.diagsBuilder, range, diag);
}

void addDiag(ref CheckCtx ctx, immutable RangeWithinFile range, immutable Diag diag) {
	addDiag(ctx, immutable FileAndRange(ctx.fileIndex, range), diag);
}

