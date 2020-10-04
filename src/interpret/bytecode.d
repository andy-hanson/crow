module interpret.bytecode;

@safe @nogc pure nothrow:

import lowModel :
	LowField,
	LowFun,
	LowFunExprBody,
	LowFunIndex,
	LowLocal,
	LowProgram,
	LowType,
	LowUnion,
	matchLowExprKind,
	matchLowFunBody,
	matchLowType;

import util.alloc.stackAlloc : StackAlloc;
import util.collection.arr : Arr, at, range, size;
import util.collection.arrUtil : arrMax, mapWithIndex, sum;
import util.collection.mutIndexDict;
import util.collection.mutArr : moveToArr, MutArr, mutArrSize, push, setAt;
import util.collection.mutDict : addToMutDict, getAt_mut, MutDict;
import util.collection.mutIndexDict : MutIndexDict;
import util.collection.mutIndexMultiDict :
	MutIndexMultiDict,
	mutIndexMultiDictAdd,
	mutIndexMultiDictMustGetAt,
	newMutIndexMultiDict;
import util.comparison : Comparison;
import util.ptr : comparePtr, Ptr, ptrTrustMe_mut;
import util.types : bottomU8OfU32, safeSizeTToU32, u8, u32;
import util.util : todo;

struct ByteCode {
	// NOTE: not every entry is an opcode
	immutable Arr!OpCode byteCode;
	immutable ByteCodeIndex main;
}

enum OpCode : u8 {
	return_,
}

immutable(ByteCode) generateBytecode(Alloc)(ref Alloc codeAlloc, ref immutable LowProgram program) {
	MutArr!(immutable OpCode) code;

	alias TempAlloc = StackAlloc!("generateBytecode", 1024 * 1024);
	TempAlloc tempAlloc;

	MutIndexMultiDict!(LowFunIndex, ByteCodeIndex) funToReferences =
		newMutIndexMultiDict!(LowFunIndex, ByteCodeIndex)(tempAlloc, size(program.allFuns));

	immutable Arr!ByteCodeIndex funToDefinition = mapWithIndex!(ByteCodeIndex, LowFun, TempAlloc)(
		tempAlloc,
		program.allFuns,
		(immutable size_t index, ref immutable LowFun fun) {
			immutable size_t start = mutArrSize(code);

			todo!void("write the function!");

			return immutable ByteCodeIndex(safeSizeTToU32(start));
	});

	/*
 	NOTE: We'll start with a mutable array for bytecodes.
		That way we can leave function indices to fill in later.
		We'll have a map from a function index to all the places to write its bytecode index.


	PLAN:
	* Map from a LowFunIndex to bytecode locations for that fn.
	*/


	foreach (immutable size_t idx; 0..size(funToDefinition)) {
		immutable LowFunIndex index = LowFunIndex(idx);
		immutable ByteCodeIndex definition = at(funToDefinition, idx);
		foreach (immutable ByteCodeIndex reference; range(mutIndexMultiDictMustGetAt(funToReferences, index))) {
			writeU32(code, reference.index, definition.index);
		}
	}

	immutable ByteCodeIndex mainIndex = todo!(immutable ByteCodeIndex)("mainIndex");

	return immutable ByteCode(moveToArr(codeAlloc, code), mainIndex);
}

private:

// NOTE: we should lay out structs so that no primitive field straddles multiple stack entries.

immutable(size_t) nStackEntriesForType(ref immutable LowProgram program, ref immutable LowType t) {
	return matchLowType!(immutable size_t)(
		t,
		(immutable LowType.ExternPtr) => immutable size_t(1),
		(immutable LowType.FunPtr) => immutable size_t(1),
		(immutable LowType.NonFunPtr) => immutable size_t(1),
		(immutable PrimitiveType) => immutable size_t(1),
		(immutable LowType.Record record) =>
			// TODO: for perf, would be better if record fields could share stack entries.
			sum(at(program.allRecords, record.index).fields, (ref immutable LowField field) =>
				nStackEntriesForType(program, field.type)),
		(immutable LowType.Union it) =>
			// Union kind takes up an entire stack entry
			1 + arrMax(0, at(program.allUnions, it.index).members, (ref immutable LowType t) =>
				nStackEntriesForType(program, t)));
}

void generateBytecodeForFun(Alloc)(
	ref Alloc codeAlloc,
	ref MutArr!(immutable u8) code,
	ref MutIndexMultiDict!(LowFunIndex, ByteCodeIndex) funToReferences,
	ref immutable LowFun fun,
) {
	matchLowFunBody!void(
		fun.body_,
		(ref immutable LowFunBody.Extern body_) {
			generateExternCall(body_);
		},
		(ref immutable LowFunExprBody body_) {
			uint stackEntry = 0;
			immutable Arr!StackEntries parameters = map(fun.params, (ref immutable LowParam it) {
				immutable uint start = stackEntry;
				immutable uint n = nStackEntriesForType(it.type);
				stackEntry += n;
				return immutable StackEntry(start, n);
			});
			// Note: not doing it for locals because they might be unrelated and occupy the same stack entry
			ExprCtx ctx = ExprCtx(ptrTrustMe_mut(code), parameters, stackEntry);
			generateExpr(codeAlloc, ctx, body_.expr);
			push(codeAlloc, code, ByteCode.return_);
		});
}

struct ExprCtx {
	immutable Ptr!LowProgram program;
	Ptr!(MutArr!(immutable u8)) code;
	immutable Arr!(immutable StackEntries) parameterEntries;
	// Note: Stack is immutable and grows downward only.
	uint curStackEntry;
	MutDict!(Ptr!LowLocal, immutable StackEntries, comparePtr!LowLocal) localEntries;
}

struct StackEntries {
	uint start; // Index of first entry
	uint size; // Number of entries
}

void generateExpr(Alloc)(
	ref Alloc codeAlloc,
	ref ExprCtx ctx,
	ref immutable LowExpr expr,
) {
	return matchLowExprKind(
		expr.kind,
		(ref immutable LowExprKind.Call) {
			todo!void("");
		},
		(ref immutable LowExprKind.CreateRecord) {
			todo!void("create-record");
		},
		(ref immutable LowExprKind.ConvertToUnion) {
			todo!void("convert-to-union");
		},
		(ref immutable LowExprKind.FunPtr) {
			todo!void("fun-ptr");
		},
		(ref immutable LowExprKind.Let it) {
			generateExpr(codeAlloc, ctx, it.first);
			immutable uint nEntries = nEntriesForType(ctx.program, it.local.type);
			addToMutDict(
				alloc,
				ctx.localEntries,
				it.local,
				immutable StackEntries(ctx.curStackEntry - nEntries, nEntries));
			generateExpr(codeAlloc, ctx, it.then);
		},
		(ref immutable LowExprKind.LocalRef it) {
			immutable StackEntry entry = getAt_mut(ctx.localPositions, it.local);
			writeGetEntry(codeAlloc, ctx.code, entry);
			ctx.curStackEntry += entry.size;
		},
		(ref immutable LowExprKind.Match) {
			todo!void("match");
		},
		(ref immutable LowExprKind.ParamRef it) {
			immutable StackEntry entry = at(ctx.parameterEntries, it.index);
			writeGetEntry(codeAlloc, ctx.code, entry);
			ctx.curStackEntry += entry.size;
			todo!void("param");
		},
		(ref immutable LowExprKind.PtrCast) {
			// Do nothing
		},
		(ref immutable LowExprKind.RecordFieldAccess) {
			todo!void("field-access");
		},
		(ref immutable LowExprKind.RecordFieldSet) {
			todo!void("field-set");
		},
		(ref immutable LowExprKind.Seq it) {
			generateExpr(codeAlloc, ctx, it.first);
			generateExpr(codeAlloc, ctx, it.then);
		},
		(ref immutable LowExprKind.SizeOf) {
			todo!void("size-of");
		},
		(ref immutable LowExprKind.SpecialConstant) {
			todo!void("special-constant");
		},
		(ref immutable LowExprKind.Special0Ary) {
			todo!void("special-0ary");
		},
		(ref immutable LowExprKind.SpecialUnary) {
			todo!void("unary");
		},
		(ref immutable LowExprKind.SpecialBinary) {
			// Remember to treat 'or' and 'and' specially
			todo!void("binary");
		},
		(ref immutable LowExprKind.SpecialTrinary) {
			//Remember to treat 'if' specially
			todo!void("trinary");
		},
		(ref immutable LowExprKind.SpecialNAry) {
			todo!void("nary");
		},
		(ref immutable LowExprKind.StringLiteral) {
			todo!void("literal");
		});
}

void writeGetEntry(Alloc)(ref Alloc alloc, ref MutArr!OpCode byteCode, immutable Entry entry) {
	foreach (immutable uint i; 0..entry.size)
		writeGetSingle(codeAlloc, ctx.code, entry.start + i);
}

void writeGetSingle(Alloc)(ref Alloc alloc, ref MutArr!OpCode byteCode, immutable uint entry) {
	todo!void("writeGet");
}

void writeU32(ref MutArr!(immutable OpCode) code, immutable size_t index, immutable u32 value) {
	assert(index + 4 <= mutArrSize(code));
	setAt(code, index, cast(immutable OpCode) bottomU8OfU32(value >> 24));
	setAt(code, index + 1, cast(immutable OpCode) bottomU8OfU32(value >> 16));
	setAt(code, index + 2, cast(immutable OpCode) bottomU8OfU32(value >> 8));
	setAt(code, index + 3, cast(immutable OpCode) bottomU8OfU32(value));
}

struct ByteCodeIndex {
	immutable u32 index;
}
