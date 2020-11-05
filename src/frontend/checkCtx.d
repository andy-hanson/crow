module frontend.checkCtx;

@safe @nogc pure nothrow:

import diag : Diag, Diagnostic, Diags;

import frontend.programState : ProgramState;
import model : ModuleAndNameReferents;
import util.bools : Bool, not;
import util.collection.arr : Arr;
import util.collection.arrBuilder : add, ArrBuilder, arrBuilderIsEmpty, finishArr;
import util.ptr : Ptr;
import util.sourceRange : FileAndRange, FileIndex, RangeWithinFile;

struct CheckCtx {
	Ptr!ProgramState programState;
	immutable FileIndex fileIndex;
	immutable Arr!ModuleAndNameReferents allFlattenedImports;
	Ptr!(ArrBuilder!Diagnostic) diagsBuilder;
}

immutable(FileAndRange) rangeInFile(ref const CheckCtx ctx, immutable RangeWithinFile range) {
	return immutable FileAndRange(ctx.fileIndex, range);
}

void addDiag(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	immutable FileAndRange range,
	immutable Diag diag,
) {
	add(alloc, ctx.diagsBuilder, immutable Diagnostic(range, diag));
}

void addDiag(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	immutable RangeWithinFile range,
	immutable Diag diag,
) {
	addDiag(alloc, ctx, immutable FileAndRange(ctx.fileIndex, range), diag);
}

