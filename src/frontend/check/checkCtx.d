module frontend.check.checkCtx;

@safe @nogc pure nothrow:

import frontend.programState : ProgramState;
import model.diag : Diag, Diagnostic;
import model.model : ModuleAndNameReferents;
import util.collection.arr : Arr;
import util.collection.arrBuilder : add, ArrBuilder;
import util.memory : allocate;
import util.ptr : Ptr;
import util.sourceRange : FileAndPos, FileAndRange, FileIndex, Pos, RangeWithinFile;

struct CheckCtx {
	Ptr!ProgramState programState;
	immutable FileIndex fileIndex;
	immutable Arr!ModuleAndNameReferents allFlattenedImports;
	Ptr!(ArrBuilder!Diagnostic) diagsBuilder;
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

