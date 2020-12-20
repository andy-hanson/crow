module frontend.check.checkCtx;

@safe @nogc pure nothrow:

import frontend.programState : ProgramState;
import model.diag : Diag, Diagnostic;
import model.model : Module, ModuleAndNames, NameReferents;
import util.collection.arr : Arr;
import util.collection.arrBuilder : add, ArrBuilder;
import util.collection.arrUtil : eachCat;
import util.collection.dict : getPtrAt;
import util.memory : allocate;
import util.opt : force, has, Opt;
import util.ptr : Ptr;
import util.sourceRange : FileAndPos, FileAndRange, FileIndex, Pos, RangeWithinFile;
import util.sym : containsSym, Sym;

struct CheckCtx {
	Ptr!ProgramState programState;
	immutable FileIndex fileIndex;
	immutable Arr!ModuleAndNames imports;
	immutable Arr!ModuleAndNames reExports;
	Ptr!(ArrBuilder!Diagnostic) diagsBuilder;
}

immutable(Acc) eachImportAndReExport(Acc)(
	ref const CheckCtx ctx,
	immutable Sym name,
	immutable Acc acc,
	scope immutable(Acc) delegate(
		immutable Acc,
		immutable Ptr!Module,
		ref immutable NameReferents,
	) @safe @nogc pure nothrow cb,
) {
	return eachCat!(Acc, ModuleAndNames)(
		acc,
		ctx.imports,
		ctx.reExports,
		(immutable Acc acc, ref immutable ModuleAndNames m) {
			if (!has(m.names) || containsSym(force(m.names), name)) {
				immutable Opt!(Ptr!NameReferents) referents = getPtrAt(m.module_.allExportedNames, name);
				if (has(referents))
					return cb(acc, m.module_, force(referents));
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

