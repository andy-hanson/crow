module frontend.check.checkCtx;

@safe @nogc pure nothrow:

import frontend.programState : ProgramState;
import model.diag : Diag, Diagnostic;
import model.model : Module, ModuleAndNames, NameReferents;
import util.bools : Bool, True;
import util.collection.arr : Arr, at, range, setAt, size;
import util.collection.arrBuilder : add, ArrBuilder;
import util.collection.arrUtil : eachCat, fillArr_mut;
import util.collection.dict : getPtrAt;
import util.memory : allocate;
import util.opt : force, has, none, Opt, some;
import util.ptr : Ptr;
import util.sourceRange : FileAndPos, FileAndRange, FileIndex, Pos, RangeWithinFile;
import util.sym : indexOfSym, Sym;

struct CheckCtx {
	Ptr!ProgramState programState;
	immutable FileIndex fileIndex;
	immutable Arr!ModuleAndNames imports;
	immutable Arr!ModuleAndNames reExports;
	// One entry for a whole-module import, or one entry for each named import
	// Note: This is unnecessary for re-exports as those are never considered unused, but simpler to always have this
	Arr!Bool importsAndReExportsUsed;
	Ptr!(ArrBuilder!Diagnostic) diagsBuilder;
}

Arr!Bool newUsedImportsAndReExports(Alloc)(
	ref Alloc alloc,
	ref immutable Arr!ModuleAndNames imports,
	ref immutable Arr!ModuleAndNames reExports,
) {
	immutable size_t size = eachCat!(size_t, ModuleAndNames)(
		0,
		imports,
		reExports,
		(immutable size_t acc, ref immutable ModuleAndNames it) =>
			acc + (has(it.names) ? size(force(it.names)) : 1));
	return fillArr_mut!(Bool, Alloc)(alloc, size, (immutable size_t) => Bool(false));
}

void checkUnusedImports(Alloc)(ref Alloc alloc, ref CheckCtx ctx) {
	size_t index = 0;
	foreach (ref immutable ModuleAndNames it; range(ctx.imports)) {
		if (has(it.names)) {
			foreach (ref immutable Sym name; range(force(it.names))) {
				if (!at(ctx.importsAndReExportsUsed, index) && has(it.importSource))
					addDiag(alloc, ctx, force(it.importSource), immutable Diag(
						immutable Diag.UnusedImport(it.module_, some(name))));
				index++;
			}
		} else {
			if (!at(ctx.importsAndReExportsUsed, index) && has(it.importSource))
				addDiag(alloc, ctx, force(it.importSource), immutable Diag(
					immutable Diag.UnusedImport(it.module_, none!Sym)));
			index++;
		}
	}
}

// Index of an imported module / name.
// If named imports are used, there's an index per name. Else, a single index for the whole module.
struct ImportIndex {
	immutable size_t index;
}

void markImportUsed(ref CheckCtx ctx, immutable ImportIndex index) {
	setAt(ctx.importsAndReExportsUsed, index.index, True);
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
					index += size(force(m.names));
					return res;
				} else {
					immutable size_t res = index;
					index++;
					return some(res);
				}
			}();
			if (has(importIndex)) {
				immutable Opt!(Ptr!NameReferents) referents = getPtrAt(m.module_.allExportedNames, name);
				if (has(referents))
					return cb(acc, m.module_, immutable ImportIndex(force(importIndex)), force(referents));
			}
			return acc;
		});
}

immutable(FileAndPos) posInFile(ref const CheckCtx ctx, ref immutable Pos pos) {
	return immutable FileAndPos(ctx.fileIndex, pos);
}

immutable(FileAndRange) rangeInFile(ref const CheckCtx ctx, ref immutable RangeWithinFile range) {
	return immutable FileAndRange(ctx.fileIndex, range);
}

void addDiag(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	immutable FileAndRange range,
	immutable Diag diag,
) {
	add(alloc, ctx.diagsBuilder, immutable Diagnostic(range, allocate(alloc, diag)));
}

void addDiag(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	immutable RangeWithinFile range,
	immutable Diag diag,
) {
	addDiag(alloc, ctx, immutable FileAndRange(ctx.fileIndex, range), diag);
}

