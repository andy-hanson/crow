module frontend.check.checkCtx;

@safe @nogc pure nothrow:

import frontend.check.dicts : ModuleLocalSpecIndex, StructOrAliasAndIndex;
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
import util.col.arr : castImmutable, setAt;
import util.col.arrUtil : eachCat, fillArr_mut, zipPtrFirst;
import util.col.dict : getAt;
import util.opt : force, has, none, Opt, some;
import util.perf : Perf;
import util.ptr : Ptr;
import util.sourceRange : FileAndPos, FileAndRange, FileIndex, Pos, RangeWithinFile;
import util.sym : AllSymbols, indexOfSym, Sym;

struct CheckCtx {
	@safe @nogc pure nothrow:

	Ptr!Perf perfPtr;
	Ptr!ProgramState programStatePtr;
	Ptr!AllSymbols allSymbolsPtr;
	immutable FileIndex fileIndex;
	immutable ModuleAndNames[] imports;
	immutable ModuleAndNames[] reExports;
	// One entry for a whole-module import, or one entry for each named import
	// Note: This is unnecessary for re-exports as those are never considered unused, but simpler to always have this
	bool[] importsAndReExportsUsed;
	bool[] structAliasesUsed;
	bool[] structsUsed;
	bool[] specsUsed;
	Ptr!DiagnosticsBuilder diagsBuilderPtr;

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

bool[] newUsedImportsAndReExports(
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
	return fillArr_mut!bool(alloc, size, (immutable size_t) => false);
}

void checkForUnused(
	ref Alloc alloc,
	ref CheckCtx ctx,
	immutable StructAlias[] structAliases,
	immutable StructDecl[] structDecls,
	immutable SpecDecl[] specDecls,
) {
	checkUnusedImports(alloc, ctx);

	zipPtrFirst!(StructAlias, bool)(
		structAliases,
		castImmutable(ctx.structAliasesUsed),
		(immutable Ptr!StructAlias alias_, ref immutable bool used) {
			final switch (alias_.deref().visibility) {
				case Visibility.public_:
					break;
				case Visibility.private_:
					if (!used)
						addDiag(alloc, ctx, alias_.deref().range, immutable Diag(
							immutable Diag.UnusedPrivateStructAlias(alias_)));
			}
		});

	zipPtrFirst!(StructDecl, bool)(
		structDecls,
		castImmutable(ctx.structsUsed),
		(immutable Ptr!StructDecl struct_, ref immutable bool used) {
			final switch (struct_.deref().visibility) {
				case Visibility.public_:
					break;
				case Visibility.private_:
					if (!used)
						addDiag(alloc, ctx, struct_.deref().range, immutable Diag(
							immutable Diag.UnusedPrivateStruct(struct_)));
			}
		});

	zipPtrFirst!(SpecDecl, bool)(
		specDecls,
		castImmutable(ctx.specsUsed),
		(immutable Ptr!SpecDecl spec, ref immutable bool used) {
			final switch (spec.deref().visibility) {
				case Visibility.public_:
					break;
				case Visibility.private_:
					if (!used)
						addDiag(alloc, ctx, spec.deref().range, immutable Diag(immutable Diag.UnusedPrivateSpec(spec)));
			}
		});
}

private void checkUnusedImports(ref Alloc alloc, ref CheckCtx ctx) {
	size_t index = 0;
	foreach (ref immutable ModuleAndNames it; ctx.imports) {
		if (has(it.names)) {
			foreach (ref immutable Sym name; force(it.names)) {
				if (!ctx.importsAndReExportsUsed[index] && has(it.importSource))
					addDiag(alloc, ctx, force(it.importSource), immutable Diag(
						immutable Diag.UnusedImport(it.modulePtr, some(name))));
				index++;
			}
		} else {
			if (!ctx.importsAndReExportsUsed[index] && has(it.importSource))
				addDiag(alloc, ctx, force(it.importSource), immutable Diag(
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
			setAt(ctx.structAliasesUsed, a.index.index, true);
		},
		(ref immutable StructDecl) {
			setAt(ctx.structsUsed, a.index.index, true);
		});
}

void markUsedSpec(ref CheckCtx ctx, immutable ModuleLocalSpecIndex a) {
	setAt(ctx.specsUsed, a.index, true);
}

void markUsedImport(ref CheckCtx ctx, immutable ImportIndex index) {
	setAt(ctx.importsAndReExportsUsed, index.index, true);
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
				immutable Opt!NameReferents referents = getAt(m.module_.allExportedNames, name);
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

void addDiag(ref Alloc alloc, ref CheckCtx ctx, immutable FileAndRange range, immutable Diag diag) {
	addDiagnostic(alloc, ctx.diagsBuilder, range, diag);
}

void addDiag(ref Alloc alloc, ref CheckCtx ctx, immutable RangeWithinFile range, immutable Diag diag) {
	addDiag(alloc, ctx, immutable FileAndRange(ctx.fileIndex, range), diag);
}

