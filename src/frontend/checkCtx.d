module frontend.checkCtx;

@safe @nogc pure nothrow:

import diag : Diag, Diagnostic, Diags, PathAndStorageKindAndRange;

import frontend.programState : ProgramState;

import model : Module;

import util.bools : Bool, not;
import util.collection.arr : Arr;
import util.collection.arrBuilder : add, ArrBuilder, arrBuilderIsEmpty, finishArr;
import util.path : PathAndStorageKind;
import util.ptr : Ptr;
import util.sourceRange : SourceRange;

struct CheckCtx {
	Ptr!ProgramState programState;
	immutable PathAndStorageKind path;
	immutable Arr!(Ptr!Module) allFlattenedImports;
	ArrBuilder!Diagnostic diagsBuilder;
}

void addDiag(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	immutable SourceRange range,
	immutable Diag diag,
) {
	add(alloc, ctx.diagsBuilder, immutable Diagnostic(PathAndStorageKindAndRange(ctx.path, range), diag));
}

immutable(Bool) hasDiags(ref const CheckCtx ctx) {
	return not(arrBuilderIsEmpty(ctx.diagsBuilder));
}

immutable(Diags) diags(Alloc)(ref Alloc alloc, ref CheckCtx ctx) {
	return finishArr(alloc, ctx.diagsBuilder);
}

