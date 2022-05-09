module backend.jit;

@safe @nogc nothrow: // not pure

import backend.gccTypes :
	assertFieldOffsetsFunctionName,
	AssertFieldOffsetsType,
	GccTypes,
	generateAssertFieldOffsetsFunction,
	getGccType,
	getGccTypes,
	UnionFields;
import backend.libgccjit :
	gcc_jit_binary_op,
	gcc_jit_block,
	gcc_jit_block_add_assignment,
	gcc_jit_block_add_eval,
	gcc_jit_block_end_with_conditional,
	gcc_jit_block_end_with_jump,
	gcc_jit_block_end_with_return,
	gcc_jit_block_end_with_switch,
	gcc_jit_bool_option,
	gcc_jit_case,
	gcc_jit_comparison,
	gcc_jit_context,
	gcc_jit_context_acquire,
	gcc_jit_context_add_driver_option,
	gcc_jit_context_compile,
	gcc_jit_context_compile_to_file,
	gcc_jit_context_get_first_error,
	gcc_jit_context_get_type,
	gcc_jit_context_new_array_access,
	gcc_jit_context_new_array_type,
	gcc_jit_context_new_binary_op,
	gcc_jit_context_get_builtin_function,
	gcc_jit_context_new_comparison,
	gcc_jit_context_new_call,
	gcc_jit_context_new_call_through_ptr,
	gcc_jit_context_new_case,
	gcc_jit_context_new_cast,
	gcc_jit_context_new_field,
	gcc_jit_context_new_function,
	gcc_jit_context_new_global,
	gcc_jit_context_new_param,
	gcc_jit_context_new_rvalue_from_double,
	gcc_jit_context_new_rvalue_from_long,
	gcc_jit_context_new_string_literal,
	gcc_jit_context_new_unary_op,
	gcc_jit_context_new_union_type,
	gcc_jit_context_null,
	gcc_jit_context_release,
	gcc_jit_context_set_bool_option,
	gcc_jit_context_set_int_option,
	gcc_jit_context_zero,
	gcc_jit_field,
	gcc_jit_function,
	gcc_jit_function_get_address,
	gcc_jit_function_get_param,
	gcc_jit_function_kind,
	gcc_jit_function_new_block,
	gcc_jit_function_new_local,
	gcc_jit_global_kind,
	gcc_jit_int_option,
	gcc_jit_lvalue,
	gcc_jit_lvalue_access_field,
	gcc_jit_lvalue_as_rvalue,
	gcc_jit_lvalue_get_address,
	gcc_jit_output_kind,
	gcc_jit_param,
	gcc_jit_param_as_lvalue,
	gcc_jit_param_as_rvalue,
	gcc_jit_result,
	gcc_jit_result_get_code,
	gcc_jit_result_release,
	gcc_jit_rvalue,
	gcc_jit_rvalue_access_field,
	gcc_jit_rvalue_dereference,
	gcc_jit_rvalue_dereference_field,
	gcc_jit_type,
	gcc_jit_types,
	gcc_jit_unary_op;
import backend.mangle :
	buildMangledNames,
	MangledNames,
	writeConstantArrStorageName,
	writeConstantPointerStorageName,
	writeLowLocalName,
	writeLowFunMangledName,
	writeLowParamName;
import frontend.lang : JitOptions, OptimizationLevel;
import model.constant : Constant, matchConstant;
import model.lowModel :
	ArrTypeAndConstantsLow,
	asRecordType,
	asUnionType,
	ExternLibrary,
	isFunPtrType,
	isGlobal,
	isPtrRawConst,
	LowExpr,
	LowExprKind,
	LowField,
	LowFun,
	LowFunBody,
	LowFunExprBody,
	LowFunIndex,
	LowLocal,
	LowParam,
	LowProgram,
	LowPtrCombine,
	LowType,
	lowTypeEqualCombinePtr,
	matchLowExprKind,
	matchLowFunBody,
	matchLowTypeCombinePtr,
	name,
	PointerTypeAndConstantsLow,
	PrimitiveType,
	UpdateParam;
import model.typeLayout : sizeOfType;
import util.alloc.alloc : Alloc;
import util.col.arr : empty;
import util.col.arrUtil : makeArr, map, mapToMut, mapWithIndex, mapWithIndex_mut, zip, zipFirstMut;
import util.col.dict : mustGetAt;
import util.col.fullIndexDict : FullIndexDict, fullIndexDictZip, mapFullIndexDict_mut;
import util.col.stackDict : MutStackDict, mutStackDictAdd, mutStackDictMustGet;
import util.col.str : CStr, SafeCStr;
import util.opt : force, has, none, noneMut, Opt, some, someMut;
import util.perf : Perf, PerfMeasure, withMeasure;
import util.ptr : castImmutable, ptrTrustMe, ptrTrustMe_mut;
import util.sourceRange : FileAndRange;
import util.sym : AllSymbols, writeSym;
import util.util : todo, unreachable, verify;
import util.writer : finishWriterToCStr, writeChar, Writer, writeStatic;

@trusted immutable(int) jitAndRun(
	ref Alloc alloc,
	ref Perf perf,
	ref immutable AllSymbols allSymbols,
	ref immutable LowProgram program,
	ref immutable JitOptions options,
	immutable SafeCStr[] allArgs,
) {
	GccProgram gccProgram = getGccProgram(alloc, perf, allSymbols, program, options);

	//TODO: perf measure this?
	immutable AssertFieldOffsetsType assertFieldOffsets = cast(immutable AssertFieldOffsetsType)
		gcc_jit_result_get_code(gccProgram.result, assertFieldOffsetsFunctionName);
	verify(assertFieldOffsets != null);

	//TODO
	if (false) {
		gcc_jit_context_compile_to_file(
			*gccProgram.ctx,
			gcc_jit_output_kind.GCC_JIT_OUTPUT_KIND_EXECUTABLE,
			"GCCJITOUT");
		return 0;
	}

	immutable MainType main = withMeasure!(immutable MainType, () @trusted =>
		cast(immutable MainType) gcc_jit_result_get_code(gccProgram.result, "main")
	)(alloc, perf, PerfMeasure.gccJit);
	verify(main != null);
	gcc_jit_context_release(gccProgram.ctx);

	immutable bool fieldOffsetsCorrect = assertFieldOffsets();
	verify(fieldOffsetsCorrect);

	immutable int exitCode = runMain(alloc, perf, allArgs, main);

	gcc_jit_result_release(gccProgram.result);
	return exitCode;
}

private:

immutable(int) runMain(ref Alloc alloc, ref Perf perf, immutable SafeCStr[] allArgs, immutable MainType main) {
	return withMeasure!(immutable int, () @trusted =>
		main(cast(int) allArgs.length, cast(immutable CStr*) allArgs.ptr)
	)(alloc, perf, PerfMeasure.run);
}

pure:


struct GccProgram {
	gcc_jit_context* ctx;
	immutable gcc_jit_result* result;
}

GccProgram getGccProgram(
	ref Alloc alloc,
	ref Perf perf,
	ref immutable AllSymbols allSymbols,
	ref immutable LowProgram program,
	ref immutable JitOptions options,
) {
	gcc_jit_context* ctx = gcc_jit_context_acquire();
	verify(ctx != null);

	gcc_jit_context_set_bool_option(*ctx, gcc_jit_bool_option.GCC_JIT_BOOL_OPTION_DEBUGINFO, true);
	final switch (options.optimization) {
		case OptimizationLevel.none:
			break;
		case OptimizationLevel.o2:
			gcc_jit_context_set_int_option(*ctx, gcc_jit_int_option.GCC_JIT_INT_OPTION_OPTIMIZATION_LEVEL, 2);
			break;
	}
	//gcc_jit_context_set_bool_option(*ctx, gcc_jit_bool_option.GCC_JIT_BOOL_OPTION_DUMP_INITIAL_GIMPLE, true);
	//gcc_jit_context_set_bool_option(*ctx, gcc_jit_bool_option.GCC_JIT_BOOL_OPTION_DUMP_GENERATED_CODE, true);

	foreach (ref immutable ExternLibrary x; program.externLibraries) {
		//TODO:NO ALLOC
		Writer writer = Writer(ptrTrustMe_mut(alloc));
		writeStatic(writer, "-l");
		writeSym(writer, allSymbols, x.libraryName);
		gcc_jit_context_add_driver_option(*ctx, finishWriterToCStr(writer));
	}

	withMeasure!(void, () {
		buildGccProgram(alloc, *ctx, allSymbols, program);
	})(alloc, perf, PerfMeasure.gccCreateProgram);

	verify(gcc_jit_context_get_first_error(*ctx) == null);

	immutable gcc_jit_result* result = withMeasure!(immutable gcc_jit_result*, () =>
		gcc_jit_context_compile(*ctx)
	)(alloc, perf, PerfMeasure.gccCompile);
	verify(result != null);
	return GccProgram(ctx, result);
}

extern(C) {
	alias MainType = int function(immutable int, immutable CStr*) @nogc nothrow;
}

@trusted void buildGccProgram(
	ref Alloc alloc,
	ref gcc_jit_context ctx,
	ref immutable AllSymbols allSymbols,
	ref immutable LowProgram program,
) {
	scope immutable MangledNames mangledNames = buildMangledNames(alloc, ptrTrustMe(allSymbols), program);
	immutable GccTypes gccTypes = getGccTypes(alloc, ctx, allSymbols, program, mangledNames);

	//TODO:only in debug
	generateAssertFieldOffsetsFunction(alloc, ctx, program, gccTypes);

	GlobalsForConstants globalsForConstants = generateGlobalsForConstants(alloc, ctx, program, gccTypes, mangledNames);

	immutable gcc_jit_type* crowVoidType = getGccType(gccTypes, immutable LowType(PrimitiveType.void_));
	immutable gcc_jit_rvalue* globalVoid = gcc_jit_lvalue_as_rvalue(
		gcc_jit_context_new_global(
			ctx,
			null,
			gcc_jit_global_kind.GCC_JIT_GLOBAL_INTERNAL,
			crowVoidType,
			"void"));

	//immutable FullIndexDict!(LowFunIndex, LowFun) allFuns;
	FullIndexDict!(LowFunIndex, gcc_jit_function*) gccFuns =
		mapFullIndexDict_mut!(LowFunIndex, gcc_jit_function*, LowFun)(
			alloc,
			program.allFuns,
			(immutable LowFunIndex funIndex, scope ref immutable LowFun fun) =>
				toGccFunctionSignature(alloc, ctx, program, mangledNames, gccTypes, funIndex, fun));

	immutable gcc_jit_type* nat64Type = getGccType(gccTypes, immutable LowType(PrimitiveType.nat64));
	immutable gcc_jit_function* abortFunction = castImmutable(gcc_jit_context_new_function(
		ctx,
		null,
		gcc_jit_function_kind.GCC_JIT_FUNCTION_IMPORTED,
		gcc_jit_context_get_type(ctx, gcc_jit_types.GCC_JIT_TYPE_VOID),
		"abort",
		0,
		null,
		false));
	immutable ConversionFunctions conversionFunctions = generateConversionFunctions(ctx);
	immutable gcc_jit_function* builtinPopcountlFunction =
		gcc_jit_context_get_builtin_function(ctx, "__builtin_popcountl");

	// Now fill in the body of every function.
	fullIndexDictZip!(LowFunIndex, LowFun, gcc_jit_function*)(
		program.allFuns,
		gccFuns,
		(immutable LowFunIndex funIndex, ref immutable LowFun fun, ref gcc_jit_function* curFun) {
		matchLowFunBody!(
			void,
			(ref immutable LowFunBody.Extern it) {},
			(ref immutable LowFunExprBody expr) {
				gcc_jit_block* entryBlock = gcc_jit_function_new_block(curFun, "entry");
				ExprCtx exprCtx = ExprCtx(
					ptrTrustMe_mut(alloc),
					ptrTrustMe(program),
					ptrTrustMe_mut(ctx),
					ptrTrustMe(mangledNames),
					ptrTrustMe(gccTypes),
					ptrTrustMe_mut(globalsForConstants),
					gccFuns,
					curFun,
					fun.returnType,
					entryBlock,
					entryBlock,
					nat64Type,
					abortFunction,
					conversionFunctions,
					builtinPopcountlFunction,
					globalVoid);

				if (isStubFunction(funIndex)) {
					debug {
						import core.stdc.stdio : printf;
						import interpret.debugging : writeFunName, writeFunSig;
						Writer writer = Writer(ptrTrustMe_mut(alloc));
						writeFunName(writer, allSymbols, program, funIndex);
						writeChar(writer, ' ');
						writeFunSig(writer, allSymbols, program, fun);
						printf("Stub %llu %s\n", funIndex.index, finishWriterToCStr(writer));
					}
					gcc_jit_block_end_with_return(exprCtx.curBlock, null, arbitraryValue(exprCtx, expr.expr.type));
				} else {
					debug {
						if (false) {
							import core.stdc.stdio : printf;
							import interpret.debugging : writeFunName, writeFunSig;
							Writer writer = Writer(ptrTrustMe_mut(alloc));
							writeFunName(writer, allSymbols, program, funIndex);
							writeChar(writer, ' ');
							writeFunSig(writer, allSymbols, program, fun);
							printf("Generate %llu %s\n", funIndex.index, finishWriterToCStr(writer));
						}
					}
					ExprEmit emit = ExprEmit(immutable ExprEmit.Return());
					Locals locals;
					immutable ExprResult result = toGccExpr(exprCtx, locals, emit, expr.expr);
					matchExprResult!void(
						result,
						(immutable ExprResult.BreakContinueOrReturn) {},
						(immutable gcc_jit_rvalue*) => unreachable!void,
						(immutable ExprResult.Void) {});
				}

				const char* err = gcc_jit_context_get_first_error(ctx);
				debug {
					import core.stdc.stdio : printf;
					if (err != null) {
						printf("Error: %s\n", err);
					}
				}
				verify(err == null);
			},
		)(fun.body_);
	});
}

//TODO:KILL
immutable(bool) isStubFunction(immutable(LowFunIndex)) {
	return false;
}

struct ConversionFunctions {
	immutable gcc_jit_function* ptrToNat64;
	immutable gcc_jit_function* nat64ToPtr;
}

@trusted immutable(ConversionFunctions) generateConversionFunctions(ref gcc_jit_context ctx) {
	immutable gcc_jit_type* voidPtrType = gcc_jit_context_get_type(ctx, gcc_jit_types.GCC_JIT_TYPE_VOID_PTR);
	immutable gcc_jit_type* nat64Type = gcc_jit_context_get_type(ctx, gcc_jit_types.GCC_JIT_TYPE_UNSIGNED_LONG);
	immutable gcc_jit_field* ptrField = gcc_jit_context_new_field(ctx, null, voidPtrType, "ptr");
	immutable gcc_jit_field* nat64Field = gcc_jit_context_new_field(ctx, null, nat64Type, "nat64");
	immutable gcc_jit_field*[2] fields = [ptrField, nat64Field];
	immutable gcc_jit_type* unionType =
		gcc_jit_context_new_union_type(ctx, null, "__ptrToNat64Converter", 2, fields.ptr);
	return immutable ConversionFunctions(
		makeConversionFunction(ctx, "__ptrToNat64", unionType, voidPtrType, ptrField, nat64Type, nat64Field),
		makeConversionFunction(ctx, "__nat64ToPtr", unionType, nat64Type, nat64Field, voidPtrType, ptrField));
}

@trusted immutable(gcc_jit_function*) makeConversionFunction(
	ref gcc_jit_context ctx,
	immutable CStr name,
	immutable gcc_jit_type* converterType,
	immutable gcc_jit_type* inType,
	immutable gcc_jit_field* inField,
	immutable gcc_jit_type* outType,
	immutable gcc_jit_field* outField,
) {
	immutable gcc_jit_param* param = gcc_jit_context_new_param(ctx, null, inType, "in");
	gcc_jit_function* res = gcc_jit_context_new_function(
		ctx,
		null,
		gcc_jit_function_kind.GCC_JIT_FUNCTION_INTERNAL,
		outType,
		name,
		1,
		&param,
		false);
	gcc_jit_block* block = gcc_jit_function_new_block(res, "entry");
	gcc_jit_lvalue* local = gcc_jit_function_new_local(res, null, converterType, "converter");
	gcc_jit_block_add_assignment(
		block,
		null,
		gcc_jit_lvalue_access_field(local, null, inField),
		gcc_jit_param_as_rvalue(param));
	gcc_jit_block_end_with_return(
		block,
		null,
		gcc_jit_rvalue_access_field(gcc_jit_lvalue_as_rvalue(local), null, outField));
	return castImmutable(res);
}

struct GlobalsForConstants {
	// This mirrors the structure of 'AllConstants'.
	// Ignoring program.allConstants.cStrings because gcc supports those directly.

	// WARN: This is the *storage* for the constant. It needs to be converted.
	immutable gcc_jit_rvalue*[][] arrs;
	gcc_jit_lvalue*[][] pointers;
}

GlobalsForConstants generateGlobalsForConstants(
	ref Alloc alloc,
	ref gcc_jit_context ctx,
	ref immutable LowProgram program,
	ref immutable GccTypes types,
	ref immutable MangledNames mangledNames,
) {
	immutable gcc_jit_rvalue*[][] arrGlobals = map!(gcc_jit_rvalue*[], ArrTypeAndConstantsLow)(
		alloc,
		program.allConstants.arrs,
		(ref immutable ArrTypeAndConstantsLow tc) {
			immutable gcc_jit_type* gccElementType = getGccType(types, tc.elementType);
			return mapWithIndex!(gcc_jit_rvalue*, Constant[])(
				alloc,
				tc.constants,
				(immutable size_t index, ref immutable Constant[] values) {
					immutable gcc_jit_type* arrayType = gcc_jit_context_new_array_type(
						ctx,
						null,
						gccElementType,
						cast(int) values.length);
					//TODO:NO ALLOC
					Writer writer = Writer(ptrTrustMe_mut(alloc));
					writeConstantArrStorageName(writer, mangledNames, program, tc.arrType, index);
					immutable CStr name = finishWriterToCStr(writer);
					return gcc_jit_lvalue_as_rvalue(gcc_jit_context_new_global(
						ctx,
						null,
						gcc_jit_global_kind.GCC_JIT_GLOBAL_INTERNAL,
						arrayType,
						name));
				});
		});

	gcc_jit_lvalue*[][] ptrGlobals = mapToMut!(gcc_jit_lvalue*[])(
		alloc,
		program.allConstants.pointers,
		(scope ref immutable PointerTypeAndConstantsLow tc) {
			immutable gcc_jit_type* gccPointeeType = getGccType(types, tc.pointeeType);
			return mapWithIndex_mut!(gcc_jit_lvalue*, Constant)(
				alloc,
				tc.constants,
				(immutable size_t index, scope ref immutable Constant) {
					//TODO:NO ALLOC
					Writer writer = Writer(ptrTrustMe_mut(alloc));
					writeConstantPointerStorageName(writer, mangledNames, program, tc.pointeeType, index);
					immutable CStr name = finishWriterToCStr(writer);
					return gcc_jit_context_new_global(
						ctx,
						null,
						gcc_jit_global_kind.GCC_JIT_GLOBAL_INTERNAL,
						gccPointeeType,
						name);
				});
		});

	return GlobalsForConstants(arrGlobals, ptrGlobals);
}

@trusted gcc_jit_function* toGccFunctionSignature(
	ref Alloc alloc,
	ref gcc_jit_context ctx,
	ref immutable LowProgram program,
	scope ref immutable MangledNames mangledNames,
	ref immutable GccTypes gccTypes,
	immutable LowFunIndex funIndex,
	scope ref immutable LowFun fun,
) {
	immutable gcc_jit_function_kind kind = matchLowFunBody!(
		immutable gcc_jit_function_kind,
		(ref immutable LowFunBody.Extern it) => it.isGlobal
			? gcc_jit_function_kind.GCC_JIT_FUNCTION_INTERNAL
			: gcc_jit_function_kind.GCC_JIT_FUNCTION_IMPORTED,
		(ref immutable(LowFunExprBody)) {
			// TODO: A GCC but breaks functions that return more than 16 bytes.
			return funIndex == program.main || sizeOfType(program, fun.returnType).size > 16
			? gcc_jit_function_kind.GCC_JIT_FUNCTION_EXPORTED
			: gcc_jit_function_kind.GCC_JIT_FUNCTION_INTERNAL;
		},
	)(fun.body_);

	immutable gcc_jit_type* returnType = getGccType(gccTypes, fun.returnType);
	//TODO:NO ALLOC
	immutable gcc_jit_param*[] params = map!(immutable gcc_jit_param*, LowParam)(
		alloc,
		fun.params,
		(ref immutable LowParam param) {
			//TODO:NO ALLOC
			Writer writer = Writer(ptrTrustMe_mut(alloc));
			writeLowParamName(writer, mangledNames, param);
			return gcc_jit_context_new_param(
				ctx,
				null,
				getGccType(gccTypes, param.type),
				finishWriterToCStr(writer));
		});
	//TODO:NO ALLOC
	Writer writer = Writer(ptrTrustMe_mut(alloc));
	writeLowFunMangledName(writer, mangledNames, funIndex, fun);
	if (isGlobal(fun.body_))
		// The function name needs to be different from the global name, else libgccjit gets confused.
		writeStatic(writer, "__getter");
	immutable CStr name = finishWriterToCStr(writer);
	gcc_jit_function* res =
		gcc_jit_context_new_function(ctx, null, kind, returnType, name, cast(int) params.length, params.ptr, false);

	matchLowFunBody!(
		void,
		(ref immutable LowFunBody.Extern it) {
			if (it.isGlobal) {
				Writer globalWriter = Writer(ptrTrustMe_mut(alloc));
				writeLowFunMangledName(globalWriter, mangledNames, funIndex, fun);
				immutable CStr globalName = finishWriterToCStr(globalWriter);
				gcc_jit_lvalue* global = gcc_jit_context_new_global(
					ctx,
					null,
					gcc_jit_global_kind.GCC_JIT_GLOBAL_IMPORTED,
					returnType,
					globalName);
				gcc_jit_block* block = gcc_jit_function_new_block(res, null);
				gcc_jit_block_end_with_return(block, null, gcc_jit_lvalue_as_rvalue(global));
			}
		},
		(ref immutable(LowFunExprBody)) {},
	)(fun.body_);

	return res;
}

struct ExprEmit {
	@safe @nogc pure nothrow:

	struct Loop {
		gcc_jit_block* loopBlock;
		Opt!(gcc_jit_block*) endBlock;
		ExprEmit breakEmit;
	}
	// Return from the block. Return none.
	struct Return {}
	// Return some.
	struct Value {}
	// Don't return anything. (Don't even return_void).
	// Only used for the first part of a Seq.
	struct Void {}
	// Write to this local. Return none.
	struct WriteTo {
		gcc_jit_lvalue* lvalue;
	}

	this(Loop* a) { kind = Kind.loop; loop = a; }
	this(immutable Return a) { kind = Kind.return_; return_ = a; }
	this(immutable Value a) { kind = kind.value; value = a; }
	this(immutable Void a) { kind = Kind.void_; void_ = a; }
	this(WriteTo a) { kind = Kind.writeTo; writeTo = a; }

	private:
	enum Kind {
		loop,
		return_,
		value,
		void_,
		writeTo,
	}
	immutable Kind kind;
	union {
		Loop* loop;
		immutable Return return_;
		immutable Value value;
		immutable Void void_;
		WriteTo writeTo;
	}
}

@trusted ExprEmit.Loop asLoop(ref ExprEmit a) {
	verify(a.kind == ExprEmit.Kind.loop);
	return *a.loop;
}

@trusted immutable(T) matchExprEmit(T)(
	ref ExprEmit a,
	scope T delegate(ExprEmit.Loop) @safe @nogc pure nothrow cbLoop,
	scope T delegate(ref immutable ExprEmit.Return) @safe @nogc pure nothrow cbReturn,
	scope T delegate(ref immutable ExprEmit.Value) @safe @nogc pure nothrow cbValue,
	scope T delegate(ref immutable ExprEmit.Void) @safe @nogc pure nothrow cbVoid,
	scope T delegate(ref ExprEmit.WriteTo) @safe @nogc pure nothrow cbWriteTo,
) {
	final switch (a.kind) {
		case ExprEmit.Kind.loop:
			return cbLoop(*a.loop);
		case ExprEmit.Kind.return_:
			return cbReturn(a.return_);
		case ExprEmit.Kind.value:
			return cbValue(a.value);
		case ExprEmit.Kind.void_:
			return cbVoid(a.void_);
		case ExprEmit.Kind.writeTo:
			return cbWriteTo(a.writeTo);
	}
}

immutable(bool) isValue(ref ExprEmit a) {
	return a.kind == ExprEmit.Kind.value;
}

immutable(bool) isVoid(ref const ExprEmit a) {
	return a.kind == ExprEmit.Kind.void_;
}

immutable(bool) isReturn(ref const ExprEmit a) {
	return a.kind == ExprEmit.Kind.return_;
}

immutable(bool) isLoopOrReturn(ref const ExprEmit a) {
	final switch (a.kind) {
		case ExprEmit.Kind.loop:
		case ExprEmit.Kind.return_:
			return true;
		case ExprEmit.Kind.value:
		case ExprEmit.Kind.void_:
		case ExprEmit.Kind.writeTo:
			return false;
	}
}

struct ExprResult {
	@safe @nogc pure nothrow:

	// Did some kind of jump
	struct BreakContinueOrReturn {}
	// Did not change control flow
	struct Void {}

	immutable this(immutable BreakContinueOrReturn a) { kind = Kind.breakContinueOrReturn; breakContinueOrReturn = a; }
	immutable this(immutable gcc_jit_rvalue* a) { kind = Kind.rvalue; rvalue = a; }
	immutable this(immutable Void a) { kind = Kind.void_; void_ = a; }

	immutable(bool) opEquals(scope immutable ExprResult b) scope immutable {
		return kind == b.kind && matchExprResult!(immutable bool)(
			this,
			(immutable ExprResult.BreakContinueOrReturn) =>
				true,
			(immutable gcc_jit_rvalue* x) =>
				b.rvalue == x,
			(immutable ExprResult.Void) =>
				true);
	}

	private:
	enum Kind { breakContinueOrReturn, rvalue, void_ }
	immutable Kind kind;
	union {
		immutable BreakContinueOrReturn breakContinueOrReturn;
		immutable gcc_jit_rvalue* rvalue;
		immutable Void void_;
	}
}

immutable(bool) isBreakContinueOrReturn(immutable ExprResult a) {
	return a.kind == ExprResult.Kind.breakContinueOrReturn;
}

immutable(bool) isVoid(immutable ExprResult a) {
	return a.kind == ExprResult.Kind.void_;
}

@trusted immutable(gcc_jit_rvalue*) asRValue(immutable ExprResult a) {
	verify(a.kind == ExprResult.Kind.rvalue);
	return a.rvalue;
}

@trusted immutable(T) matchExprResult(T)(
	immutable ExprResult a,
	scope immutable(T) delegate(
		immutable ExprResult.BreakContinueOrReturn
	) @safe @nogc pure nothrow cbBreakContinueOrReturn,
	scope immutable(T) delegate(immutable gcc_jit_rvalue*) @safe @nogc pure nothrow cbRvalue,
	scope immutable(T) delegate(immutable ExprResult.Void) @safe @nogc pure nothrow cbVoid,
) {
	final switch (a.kind) {
		case ExprResult.Kind.breakContinueOrReturn:
			return cbBreakContinueOrReturn(a.breakContinueOrReturn);
		case ExprResult.Kind.rvalue:
			return cbRvalue(a.rvalue);
		case ExprResult.Kind.void_:
			return cbVoid(a.void_);
	}
}

immutable(ExprResult) emitSimpleNoSideEffects(
	ref ExprCtx ctx,
	ref ExprEmit emit,
	immutable gcc_jit_rvalue* value,
) {
	verify(value != null);
	return matchExprEmit!(immutable ExprResult)(
		emit,
		(ExprEmit.Loop) =>
			unreachable!(immutable ExprResult),
		(ref immutable ExprEmit.Return) {
			gcc_jit_block_end_with_return(ctx.curBlock, null, value);
			return immutable ExprResult(immutable ExprResult.BreakContinueOrReturn());
		},
		(ref immutable ExprEmit.Value) =>
			immutable ExprResult(value),
		(ref immutable ExprEmit.Void) {
			gcc_jit_block_add_eval(ctx.curBlock, null, value);
			return immutable ExprResult(immutable ExprResult.Void());
		},
		(ref ExprEmit.WriteTo it) {
			gcc_jit_block_add_assignment(ctx.curBlock, null, it.lvalue, value);
			return immutable ExprResult(immutable ExprResult.Void());
		});
}

// We need to ensure side effects happen in order since GCC seems to evaluate call arguments in reverse.
immutable(ExprResult) emitSimpleYesSideEffects(
	ref ExprCtx ctx,
	ref ExprEmit emit,
	immutable LowType type,
	immutable gcc_jit_rvalue* value,
) {
	return isValue(emit)
		? immutable ExprResult(getRValueUsingLocal(ctx, type, (gcc_jit_lvalue* local) {
			gcc_jit_block_add_assignment(ctx.curBlock, null, local, value);
		}))
		: emitSimpleNoSideEffects(ctx, emit, value);
}

immutable(gcc_jit_rvalue*) getRValueUsingLocal(
	ref ExprCtx ctx,
	immutable LowType type,
	scope void delegate(gcc_jit_lvalue*) @safe @nogc pure nothrow cb,
) {
	gcc_jit_lvalue* local = gcc_jit_function_new_local(ctx.curFun, null, getGccType(ctx.types, type), "temp");
	cb(local);
	return gcc_jit_lvalue_as_rvalue(local);
}

immutable(ExprResult) emitWriteToLValue(
	ref ExprCtx ctx,
	ref ExprEmit emit,
	immutable LowType type,
	scope void delegate(gcc_jit_lvalue*) @safe @nogc pure nothrow cb,
) {
	return matchExprEmit!(immutable ExprResult)(
		emit,
		(ExprEmit.Loop) =>
			unreachable!(immutable ExprResult),
		(ref immutable ExprEmit.Return) {
			immutable gcc_jit_rvalue* rvalue = getRValueUsingLocal(ctx, type, cb);
			gcc_jit_block_end_with_return(ctx.curBlock, null, rvalue);
			return immutable ExprResult(immutable ExprResult.BreakContinueOrReturn());
		},
		(ref immutable ExprEmit.Value) =>
			immutable ExprResult(getRValueUsingLocal(ctx, type, cb)),
		(ref immutable ExprEmit.Void) =>
			unreachable!(immutable ExprResult)(),
		(ref ExprEmit.WriteTo it) {
			cb(it.lvalue);
			return immutable ExprResult(immutable ExprResult.Void());
		});
}

immutable(ExprResult) emitVoid(
	ref ExprCtx ctx,
	ref ExprEmit emit,
) {
	return matchExprEmit!(immutable ExprResult)(
		emit,
		(ExprEmit.Loop) =>
			unreachable!(immutable ExprResult),
		(ref immutable ExprEmit.Return) {
			//TODO: this should be unnecessary, use local void
			gcc_jit_block_end_with_return(ctx.curBlock, null, ctx.globalVoid);
			return immutable ExprResult(immutable ExprResult.BreakContinueOrReturn());
		},
		(ref immutable ExprEmit.Value) =>
			immutable ExprResult(ctx.globalVoid),
		(ref immutable ExprEmit.Void) =>
			immutable ExprResult(immutable ExprResult.Void()),
		(ref ExprEmit.WriteTo it) {
			gcc_jit_block_add_assignment(ctx.curBlock, null, it.lvalue, ctx.globalVoid);
			return immutable ExprResult(immutable ExprResult.Void());
		});
}

immutable(ExprResult) emitWithBranching(
	ref ExprCtx ctx,
	ref ExprEmit emit,
	immutable LowType type,
	immutable char* endBlockName,
	scope void delegate(
		gcc_jit_block* originalBlock,
		Opt!(gcc_jit_block*) endBlock,
		Opt!(gcc_jit_lvalue*) local,
		immutable ExprResult expectedResult,
	) @safe @nogc pure nothrow cb,
) {
	Opt!(gcc_jit_block*) endBlock = isLoopOrReturn(emit)
		? noneMut!(gcc_jit_block*)
		: someMut(gcc_jit_function_new_block(ctx.curFun, endBlockName));
	Opt!(gcc_jit_lvalue*) local = isValue(emit)
		? someMut(gcc_jit_function_new_local(ctx.curFun, null, getGccType(ctx.types, type), "temp"))
		: noneMut!(gcc_jit_lvalue*);
	gcc_jit_block* originalBlock = ctx.curBlock;

	immutable(ExprResult) expectedResult = matchExprEmit!(immutable ExprResult)(
		emit,
		(ExprEmit.Loop) =>
			immutable ExprResult(immutable ExprResult.BreakContinueOrReturn()),
		(ref immutable ExprEmit.Return) =>
			immutable ExprResult(immutable ExprResult.BreakContinueOrReturn()),
		(ref immutable ExprEmit.Value) {
			verify(has(local));
			return immutable ExprResult(immutable ExprResult.Void());
		},
		(ref immutable ExprEmit.Void) =>
			immutable ExprResult(immutable ExprResult.Void()),
		(ref ExprEmit.WriteTo) =>
			immutable ExprResult(immutable ExprResult.Void()));

	cb(originalBlock, endBlock, local, expectedResult);

	// If no endBlock, curBlock doesn't matter because nothing else will be done.
	ctx.curBlock = has(endBlock) ? force(endBlock) : originalBlock;
	if (has(local)) {
		verify(isVoid(expectedResult));
		return immutable ExprResult(gcc_jit_lvalue_as_rvalue(force(local)));
	} else
		return expectedResult;
}

immutable(ExprResult) emitSwitch(
	ref ExprCtx ctx,
	ref ExprEmit emit,
	immutable LowType type,
	immutable gcc_jit_rvalue* switchedValue,
	immutable size_t nCases,
	scope immutable(ExprResult) delegate(ref ExprEmit, immutable size_t) @safe @nogc pure nothrow cbCase,
) {
	return emitWithBranching(
		ctx, emit, type, "switchEnd",
		(
			gcc_jit_block* originalBlock,
			Opt!(gcc_jit_block*) endBlock,
			Opt!(gcc_jit_lvalue*) local,
			immutable ExprResult expectedResult,
		) @trusted {
			gcc_jit_block* defaultBlock = gcc_jit_function_new_block(ctx.curFun, "switchDefault");
			gcc_jit_block_add_eval(
				defaultBlock,
				null,
				castImmutable(gcc_jit_context_new_call(ctx.gcc, null, ctx.abortFunction, 0, null)));
			// Gcc requires that every block have an end.
			if (has(endBlock) && !isBreakContinueOrReturn(expectedResult))
				gcc_jit_block_end_with_jump(defaultBlock, null, force(endBlock));
			else
				gcc_jit_block_end_with_return(defaultBlock, null, arbitraryValue(ctx, ctx.curFunReturnType));

			immutable gcc_jit_case*[] cases = makeArr!(gcc_jit_case*)(
				ctx.alloc,
				nCases,
				(immutable size_t i) {
					gcc_jit_block* caseBlock = gcc_jit_function_new_block(ctx.curFun, "switchCase");
					ctx.curBlock = caseBlock;
					immutable ExprResult result = () {
						if (has(local)) {
							emitToLValueCb(force(local), (ref ExprEmit emitLocal) =>
								cbCase(emitLocal, i));
							return immutable ExprResult(immutable ExprResult.Void());
						} else
							return cbCase(emit, i);
					}();
					verify(result == expectedResult);
					if (has(endBlock) && !isBreakContinueOrReturn(result)) {
						// A nested branch may have changed to a new block, so use that instead of 'caseBlock'
						gcc_jit_block_end_with_jump(ctx.curBlock, null, force(endBlock));
					}
					immutable gcc_jit_rvalue* caseValue =
						//TODO:PERF cache these?
						gcc_jit_context_new_rvalue_from_long(ctx.gcc, ctx.nat64Type, i);
					return gcc_jit_context_new_case(ctx.gcc, caseValue, caseValue, caseBlock);
				});
			gcc_jit_block_end_with_switch(
				originalBlock,
				null,
				// TODO: use cases of appropriate type?
				gcc_jit_context_new_cast(ctx.gcc, null, switchedValue, ctx.nat64Type),
				defaultBlock,
				cast(int) cases.length,
				cases.ptr);
		});
}

alias Locals = MutStackDict!(immutable LowLocal*, gcc_jit_lvalue*);
alias addLocal = mutStackDictAdd!(immutable LowLocal*, gcc_jit_lvalue*);
alias getLocal = mutStackDictMustGet!(immutable LowLocal*, gcc_jit_lvalue*);

struct ExprCtx {
	@safe @nogc pure nothrow:

	Alloc* allocPtr;
	immutable LowProgram* programPtr;
	gcc_jit_context* gccPtr;
	immutable MangledNames* mangledNamesPtr;
	immutable GccTypes* typesPtr;
	GlobalsForConstants* globalsForConstantsPtr;
	FullIndexDict!(LowFunIndex, gcc_jit_function*) gccFuns;
	gcc_jit_function* curFun;
	immutable LowType curFunReturnType;
	gcc_jit_block* entryBlock;
	gcc_jit_block* curBlock;
	immutable gcc_jit_type* nat64Type;
	immutable gcc_jit_function* abortFunction;
	immutable ConversionFunctions conversionFunctions;
	immutable gcc_jit_function* builtinPopcountlFunction;
	immutable gcc_jit_rvalue* globalVoid;

	ref Alloc alloc() return scope {
		return *allocPtr;
	}

	ref immutable(LowProgram) program() const return scope {
		return *programPtr;
	}

	ref immutable(MangledNames) mangledNames() const return scope {
		return *mangledNamesPtr;
	}

	ref immutable(GccTypes) types() const return scope {
		return *typesPtr;
	}

	ref GlobalsForConstants globalsForConstants() return scope {
		return *globalsForConstantsPtr;
	}

	ref gcc_jit_context gcc() return scope {
		return *gccPtr;
	}
}

// NOTE: For ExprEmit
immutable(ExprResult) toGccExpr(
	ref ExprCtx ctx,
	ref Locals locals,
	ref ExprEmit emit,
	scope ref immutable LowExpr a,
) {
	return matchLowExprKind!(
		immutable ExprResult,
		(ref immutable LowExprKind.Call it) =>
			callToGcc(ctx, locals, emit, a.type, it),
		(ref immutable LowExprKind.CallFunPtr it) =>
			callFunPtrToGcc(ctx, locals, emit, a, it),
		(ref immutable LowExprKind.CreateRecord it) =>
			createRecordToGcc(ctx, locals, emit, a, it),
		(ref immutable LowExprKind.CreateUnion it) =>
			createUnionToGcc(ctx, locals, emit, a, it),
		(ref immutable LowExprKind.If it) =>
			ifToGcc(ctx, locals, emit, a.type, it.cond, it.then, it.else_),
		(ref immutable LowExprKind.InitConstants) =>
			initConstantsToGcc(ctx, emit),
		(ref immutable LowExprKind.Let it) =>
			letToGcc(ctx, locals, emit, it),
		(ref immutable LowExprKind.LocalRef it) =>
			localRefToGcc(ctx, locals, emit, it),
		(ref immutable LowExprKind.LocalSet it) =>
			localSetToGcc(ctx, locals, emit, it),
		(ref immutable LowExprKind.Loop it) =>
			loopToGcc(ctx, locals, emit, a.type, it),
		(ref immutable LowExprKind.LoopBreak it) =>
			loopBreakToGcc(ctx, locals, emit, it),
		(ref immutable LowExprKind.LoopContinue it) =>
			loopContinueToGcc(ctx, locals, emit, it),
		(ref immutable LowExprKind.MatchUnion it) =>
			matchUnionToGcc(ctx, locals, emit, a, it),
		(ref immutable LowExprKind.ParamRef it) =>
			paramRefToGcc(ctx, emit, it),
		(ref immutable LowExprKind.PtrCast it) =>
			ptrCastToGcc(ctx, locals, emit, a, it),
		(ref immutable LowExprKind.RecordFieldGet it) =>
			recordFieldGetToGcc(ctx, locals, emit, it),
		(ref immutable LowExprKind.RecordFieldSet it) =>
			recordFieldSetToGcc(ctx, locals, emit, it),
		(ref immutable LowExprKind.Seq it) =>
			seqToGcc(ctx, locals, emit, it),
		(ref immutable LowExprKind.SizeOf it) =>
			sizeOfToGcc(ctx, emit, it),
		(ref immutable Constant it) =>
			constantToGcc(ctx, emit, a.type, it),
		(ref immutable LowExprKind.SpecialUnary it) =>
			unaryToGcc(ctx, locals, emit, a, it),
		(ref immutable LowExprKind.SpecialBinary it) =>
			binaryToGcc(ctx, locals, emit, a, it),
		(ref immutable LowExprKind.SpecialTernary) =>
			unreachable!ExprResult,
		(ref immutable LowExprKind.Switch0ToN it) =>
			switch0ToNToGcc(ctx, locals, emit, a, it),
		(ref immutable LowExprKind.SwitchWithValues) =>
			todo!(immutable ExprResult)("!"),
		(ref immutable LowExprKind.TailRecur it) =>
			tailRecurToGcc(ctx, locals, emit, it),
		(ref immutable LowExprKind.Zeroed) =>
			zeroedToGcc(ctx, emit, a.type),
	)(a.kind);
}

immutable(gcc_jit_rvalue*) emitToRValueCb(
	scope immutable(ExprResult) delegate(ref ExprEmit) @safe @nogc pure nothrow cbEmit,
) {
	ExprEmit emit = ExprEmit(immutable ExprEmit.Value());
	immutable ExprResult res = cbEmit(emit);
	return asRValue(res);
}

immutable(gcc_jit_rvalue*) emitToRValue(ref ExprCtx ctx, ref Locals locals, ref immutable LowExpr a) {
	return emitToRValueCb((ref ExprEmit emit) =>
		toGccExpr(ctx, locals, emit, a));
}

void emitToLValueCb(
	gcc_jit_lvalue* lvalue,
	scope immutable(ExprResult) delegate(ref ExprEmit) @safe @nogc pure nothrow cbEmit,
) {
	ExprEmit emit = ExprEmit(ExprEmit.WriteTo(lvalue));
	immutable ExprResult result = cbEmit(emit);
	verify(isVoid(result));
}

void emitToLValue(ref ExprCtx ctx, ref Locals locals, gcc_jit_lvalue* lvalue, scope ref immutable LowExpr a) {
	emitToLValueCb(lvalue, (ref ExprEmit emitArg) =>
		toGccExpr(ctx, locals, emitArg, a));
}

@trusted immutable(ExprResult) callToGcc(
	ref ExprCtx ctx,
	ref Locals locals,
	ref ExprEmit emit,
	immutable LowType type,
	ref immutable LowExprKind.Call a,
) {
	const gcc_jit_function* called = ctx.gccFuns[a.called];
	//TODO:NO ALLOC
	immutable gcc_jit_rvalue*[] argsGcc =
		map!(gcc_jit_rvalue*, LowExpr)(ctx.alloc, a.args, (ref immutable LowExpr arg) =>
			emitToRValue(ctx, locals, arg));
	return emitSimpleYesSideEffects(ctx, emit, type, castImmutable(
		gcc_jit_context_new_call(ctx.gcc, null, called, cast(int) argsGcc.length, argsGcc.ptr)));
}

@trusted immutable(ExprResult) callFunPtrToGcc(
	ref ExprCtx ctx,
	ref Locals locals,
	ref ExprEmit emit,
	ref immutable LowExpr expr,
	ref immutable LowExprKind.CallFunPtr a,
) {
	immutable gcc_jit_rvalue* funPtrGcc = emitToRValue(ctx, locals, a.funPtr);
	//TODO:NO ALLOC
	immutable gcc_jit_rvalue*[] argsGcc =
		map!(gcc_jit_rvalue*, LowExpr)(ctx.alloc, a.args, (ref immutable LowExpr arg) =>
			emitToRValue(ctx, locals, arg));
	return emitSimpleYesSideEffects(ctx, emit, expr.type, gcc_jit_context_new_call_through_ptr(
		ctx.gcc,
		null,
		funPtrGcc,
		cast(int) argsGcc.length,
		argsGcc.ptr));
}

@trusted immutable(ExprResult) tailRecurToGcc(
	ref ExprCtx ctx,
	ref Locals locals,
	ref ExprEmit emit,
	ref immutable LowExprKind.TailRecur a,
) {
	verify(isReturn(emit));

	// We need to be sure to generate all the new parameter values before overwriting any,
	gcc_jit_lvalue*[] updateParamLocals =
		mapToMut!(gcc_jit_lvalue*)(ctx.alloc, a.updateParams, (scope ref immutable UpdateParam updateParam) {
			gcc_jit_lvalue* local =
				gcc_jit_function_new_local(ctx.curFun, null, getGccType(ctx.types, updateParam.newValue.type), "temp");
			emitToLValue(ctx, locals, local, updateParam.newValue);
			return local;
		});
	zipFirstMut!(gcc_jit_lvalue*, UpdateParam)(
		updateParamLocals,
		a.updateParams,
		(ref gcc_jit_lvalue* local, ref immutable UpdateParam updateParam) {
			gcc_jit_param* param = getParam(ctx, immutable LowExprKind.ParamRef(updateParam.param));
			gcc_jit_block_add_assignment(
				ctx.curBlock,
				null,
				gcc_jit_param_as_lvalue(param),
				gcc_jit_lvalue_as_rvalue(local));
		});
	gcc_jit_block_end_with_jump(ctx.curBlock, null, ctx.entryBlock);
	return immutable ExprResult(immutable ExprResult.BreakContinueOrReturn());
}

immutable(ExprResult) emitRecordCb(
	ref ExprCtx ctx,
	ref ExprEmit emit,
	immutable LowType type,
	scope immutable(ExprResult) delegate(immutable size_t, ref ExprEmit) @safe @nogc pure nothrow cbEmitArg,
) {
	return emitWriteToLValue(ctx, emit, type, (gcc_jit_lvalue* lvalue) {
		immutable gcc_jit_field*[] fields = ctx.types.recordFields[asRecordType(type)];
		foreach (immutable size_t i, immutable gcc_jit_field* field; fields) {
			immutable gcc_jit_rvalue* value = emitToRValueCb((ref ExprEmit emitArg) =>
				cbEmitArg(i, emitArg));
			gcc_jit_block_add_assignment(ctx.curBlock, null, gcc_jit_lvalue_access_field(lvalue, null, field), value);
		}
	});
}

immutable(ExprResult) emitRecordCbWithArgs(T)(
	ref ExprCtx ctx,
	ref ExprEmit emit,
	immutable LowType type,
	immutable T[] args,
	scope immutable(ExprResult) delegate(
		immutable size_t,
		ref ExprEmit,
		ref immutable T,
	) @safe @nogc pure nothrow cbEmitArg,
) {
	return emitRecordCb(ctx, emit, type, (immutable size_t argIndex, ref ExprEmit emitArg) =>
		cbEmitArg(argIndex, emitArg, args[argIndex]));
}

immutable(ExprResult) createRecordToGcc(
	ref ExprCtx ctx,
	ref Locals locals,
	ref ExprEmit emit,
	ref immutable LowExpr expr,
	ref immutable LowExprKind.CreateRecord a,
) {
	return emitRecordCbWithArgs(
		ctx, emit, expr.type, a.args,
		(immutable(size_t), ref ExprEmit emitArg, ref immutable LowExpr arg) =>
			toGccExpr(ctx, locals, emitArg, arg));
}

immutable(ExprResult) emitUnion(
	ref ExprCtx ctx,
	ref ExprEmit emit,
	immutable LowType type,
	immutable size_t memberIndex,
	scope immutable(ExprResult) delegate(ref ExprEmit) @safe @nogc pure nothrow cbEmitArg,
) {
	return emitWriteToLValue(ctx, emit, type, (gcc_jit_lvalue* lvalue) {
		immutable UnionFields unionFields = ctx.types.unionFields[asUnionType(type)];
		gcc_jit_block_add_assignment(
			ctx.curBlock,
			null,
			gcc_jit_lvalue_access_field(lvalue, null, unionFields.kindField),
			gcc_jit_context_new_rvalue_from_long(ctx.gcc, ctx.nat64Type, memberIndex));
		gcc_jit_lvalue* memberLValue = gcc_jit_lvalue_access_field(
			gcc_jit_lvalue_access_field(lvalue, null, unionFields.innerField),
			null,
			unionFields.memberFields[memberIndex]);
		emitToLValueCb(memberLValue, cbEmitArg);
	});

}

immutable(ExprResult) createUnionToGcc(
	ref ExprCtx ctx,
	ref Locals locals,
	ref ExprEmit emit,
	ref immutable LowExpr expr,
	ref immutable LowExprKind.CreateUnion a,
) {
	return emitUnion(ctx, emit, expr.type, a.memberIndex, (ref ExprEmit emitArg) =>
		toGccExpr(ctx, locals, emitArg, a.arg));
}

immutable(ExprResult) letToGcc(ref ExprCtx ctx, ref Locals locals, ref ExprEmit emit, ref immutable LowExprKind.Let a) {
	return emitWithLocal(
		ctx,
		locals,
		emit,
		a.local,
		(ref ExprEmit valueEmit) =>
			toGccExpr(ctx, locals, valueEmit, a.value),
		a.then);
}

immutable(ExprResult) emitWithLocal(
	ref ExprCtx ctx,
	ref Locals locals,
	ref ExprEmit emit,
	immutable LowLocal* lowLocal,
	scope immutable(ExprResult) delegate(ref ExprEmit) @safe @nogc pure nothrow cbValue,
	immutable LowExpr then,
) {
	//TODO:NO ALLOC
	Writer writer = Writer(ctx.allocPtr);
	writeLowLocalName(writer, ctx.mangledNames, *lowLocal);
	gcc_jit_lvalue* gccLocal = gcc_jit_function_new_local(
		ctx.curFun,
		null,
		getGccType(ctx.types, lowLocal.type),
		finishWriterToCStr(writer));
	emitToLValueCb(gccLocal, (ref ExprEmit valueEmit) =>
		cbValue(valueEmit));
	Locals newLocals = addLocal(locals, lowLocal, gccLocal);
	return toGccExpr(ctx, newLocals, emit, then);
}

immutable(ExprResult) localRefToGcc(
	ref ExprCtx ctx,
	ref Locals locals,
	ref ExprEmit emit,
	ref immutable LowExprKind.LocalRef a,
) {
	return emitSimpleNoSideEffects(ctx, emit, gcc_jit_lvalue_as_rvalue(getLocal(locals, a.local)));
}

immutable(ExprResult) localSetToGcc(
	ref ExprCtx ctx,
	ref Locals locals,
	ref ExprEmit emit,
	ref immutable LowExprKind.LocalSet a,
) {
	emitToLValue(ctx, locals, getLocal(locals, a.local), a.value);
	return emitVoid(ctx, emit);
}

immutable(ExprResult) loopToGcc(
	ref ExprCtx ctx,
	ref Locals locals,
	ref ExprEmit emit,
	immutable LowType type,
	ref immutable LowExprKind.Loop a,
) {
	return emitWithBranching(
		ctx, emit, type, "loopEnd",
		(
			gcc_jit_block* originalBlock,
			Opt!(gcc_jit_block*) endBlock,
			Opt!(gcc_jit_lvalue*) local,
			immutable(ExprResult),
		) @trusted {
			gcc_jit_block* loopBlock = gcc_jit_function_new_block(ctx.curFun, "loop");
			gcc_jit_block_end_with_jump(originalBlock, null, loopBlock);
			ctx.curBlock = loopBlock;
			ExprEmit.Loop info = ExprEmit.Loop(
				loopBlock,
				endBlock, // TODO:UNUSED
				has(local) ? ExprEmit(ExprEmit.WriteTo(force(local))) : emit);
			ExprEmit innerEmit = ExprEmit(&info);
			immutable ExprResult innerResult = toGccExpr(ctx, locals, innerEmit, a.body_);
			verify(isBreakContinueOrReturn(innerResult));
		});
}

immutable(ExprResult) loopBreakToGcc(
	ref ExprCtx ctx,
	ref Locals locals,
	ref ExprEmit emit,
	ref immutable LowExprKind.LoopBreak a,
) {
	ExprEmit.Loop loop = asLoop(emit);
	// Give 'breakEmit' to the inner expr, so it does whatever is needed by the loop
	immutable ExprResult result = toGccExpr(ctx, locals, loop.breakEmit, a.value);
	matchExprResult!void(
		result,
		(immutable ExprResult.BreakContinueOrReturn) {},
		(immutable gcc_jit_rvalue*) { unreachable!void(); },
		(immutable ExprResult.Void) {
			gcc_jit_block_end_with_jump(ctx.curBlock, null, force(loop.endBlock));
		});
	return immutable ExprResult(immutable ExprResult.BreakContinueOrReturn());
}

immutable(ExprResult) loopContinueToGcc(
	ref ExprCtx ctx,
	ref Locals locals,
	ref ExprEmit emit,
	ref immutable LowExprKind.LoopContinue a,
) {
	gcc_jit_block_end_with_jump(ctx.curBlock, null, asLoop(emit).loopBlock);
	return immutable ExprResult(immutable ExprResult.BreakContinueOrReturn());
}

immutable(ExprResult) matchUnionToGcc(
	ref ExprCtx ctx,
	ref Locals locals,
	ref ExprEmit emit,
	ref immutable LowExpr expr,
	ref immutable LowExprKind.MatchUnion a,
) {
	// We need to create a local for the matchedValue.
	gcc_jit_lvalue* matchedLocal = gcc_jit_function_new_local(
		ctx.curFun,
		null,
		getGccType(ctx.types, a.matchedValue.type),
		"matched");
	emitToLValue(ctx, locals, matchedLocal, a.matchedValue);

	immutable UnionFields unionFields = ctx.types.unionFields[asUnionType(a.matchedValue.type)];

	immutable gcc_jit_rvalue* matchedValueKind = gcc_jit_rvalue_access_field(
		gcc_jit_lvalue_as_rvalue(matchedLocal),
		null,
		unionFields.kindField);

	return emitSwitch(
		ctx,
		emit,
		expr.type,
		matchedValueKind,
		a.cases.length,
		(ref ExprEmit caseEmit, immutable size_t caseIndex) {
			immutable LowExprKind.MatchUnion.Case case_ = a.cases[caseIndex];
			return has(case_.local)
				? emitWithLocal(
					ctx,
					locals,
					caseEmit,
					force(case_.local),
					(ref ExprEmit valueEmit) {
						// The value is the nth value in the union..
						immutable gcc_jit_rvalue* matchedValueInner = gcc_jit_rvalue_access_field(
							gcc_jit_lvalue_as_rvalue(matchedLocal),
							null,
							unionFields.innerField);
						return emitSimpleNoSideEffects(ctx, valueEmit, gcc_jit_rvalue_access_field(
							matchedValueInner,
							null,
							unionFields.memberFields[caseIndex]));
					},
					case_.then)
			: toGccExpr(ctx, locals, caseEmit, case_.then);
		});
}

immutable(ExprResult) paramRefToGcc(
	ref ExprCtx ctx,
	ref ExprEmit emit,
	ref immutable LowExprKind.ParamRef a,
) {
	return emitSimpleNoSideEffects(ctx, emit, gcc_jit_param_as_rvalue(getParam(ctx, a)));
}

gcc_jit_param* getParam(ref ExprCtx ctx, immutable LowExprKind.ParamRef a) {
	return gcc_jit_function_get_param(ctx.curFun, cast(int) a.index.index);
}

immutable(ExprResult) ptrCastToGcc(
	ref ExprCtx ctx,
	ref Locals locals,
	ref ExprEmit emit,
	ref immutable LowExpr expr,
	ref immutable LowExprKind.PtrCast a,
) {
	if (lowTypeEqualCombinePtr(expr.type, a.target.type))
		// We don't have 'const' at low-level, so some casts are unnecessary.
		return toGccExpr(ctx, locals, emit, a.target);
	else
		return emitSimpleNoSideEffects(ctx, emit, gcc_jit_context_new_cast(
			ctx.gcc,
			null,
			emitToRValue(ctx, locals, a.target),
			getGccType(ctx.types, expr.type)));
}

immutable(ExprResult) recordFieldGetToGcc(
	ref ExprCtx ctx,
	ref Locals locals,
	ref ExprEmit emit,
	ref immutable LowExprKind.RecordFieldGet a,
) {
	immutable gcc_jit_rvalue* target = emitToRValue(ctx, locals, a.target);
	immutable gcc_jit_field* field = ctx.types.recordFields[a.record][a.fieldIndex];
	return emitSimpleNoSideEffects(ctx, emit, a.targetIsPointer
		? gcc_jit_lvalue_as_rvalue(gcc_jit_rvalue_dereference_field(target, null, field))
		: gcc_jit_rvalue_access_field(target, null, field));
}

gcc_jit_lvalue* recordFieldGetToLValue(
	ref ExprCtx ctx,
	ref Locals locals,
	ref immutable LowExprKind.RecordFieldGet a,
) {
	immutable gcc_jit_field* field = ctx.types.recordFields[a.record][a.fieldIndex];
	return a.targetIsPointer
		? gcc_jit_rvalue_dereference_field(emitToRValue(ctx, locals, a.target), null, field)
		: gcc_jit_lvalue_access_field(getLValue(ctx, locals, a.target), null, field);
}

immutable(ExprResult) recordFieldSetToGcc(
	ref ExprCtx ctx,
	ref Locals locals,
	ref ExprEmit emit,
	ref immutable LowExprKind.RecordFieldSet a,
) {
	immutable gcc_jit_rvalue* target = emitToRValue(ctx, locals, a.target);
	immutable gcc_jit_field* field = ctx.types.recordFields[a.record][a.fieldIndex];
	verify(a.targetIsPointer); // TODO: make if this is always true, don't have it...
	immutable gcc_jit_rvalue* value = emitToRValue(ctx, locals, a.value);
	gcc_jit_block_add_assignment(ctx.curBlock, null, gcc_jit_rvalue_dereference_field(target, null, field), value);
	return emitVoid(ctx, emit);
}

immutable(ExprResult) seqToGcc(
	ref ExprCtx ctx,
	ref Locals locals,
	ref ExprEmit emit,
	ref immutable LowExprKind.Seq a,
) {
	ExprEmit emitVoid = ExprEmit(immutable ExprEmit.Void());
	immutable ExprResult result = toGccExpr(ctx, locals, emitVoid, a.first);
	verify(isVoid(result));
	return toGccExpr(ctx, locals, emit, a.then);
}

immutable(ExprResult) sizeOfToGcc(
	ref ExprCtx ctx,
	ref ExprEmit emit,
	ref immutable LowExprKind.SizeOf a,
) {
	return emitSimpleNoSideEffects(
		ctx,
		emit,
		gcc_jit_context_new_rvalue_from_long(ctx.gcc, ctx.nat64Type, sizeOfType(ctx.program, a.type).size));
}

immutable(ExprResult) constantToGcc(
	ref ExprCtx ctx,
	ref ExprEmit emit,
	immutable LowType type,
	ref immutable Constant a,
) {
	return matchConstant!(immutable ExprResult)(
		a,
		(ref immutable Constant.ArrConstant it) {
			immutable size_t arrSize = ctx.program.allConstants.arrs[it.typeIndex].constants[it.index].length;
			immutable gcc_jit_rvalue* storage = ctx.globalsForConstants.arrs[it.typeIndex][it.index];
			immutable gcc_jit_rvalue* arrPtr = gcc_jit_lvalue_get_address(
				gcc_jit_context_new_array_access(ctx.gcc, null, storage, gcc_jit_context_zero(ctx.gcc, ctx.nat64Type)),
				null);
			immutable gcc_jit_field*[] fields = ctx.types.recordFields[asRecordType(type)];
			verify(fields.length == 2);
			immutable gcc_jit_field* sizeField = fields[0];
			immutable gcc_jit_field* ptrField = fields[1];
			return emitWriteToLValue(ctx, emit, type, (gcc_jit_lvalue* local) {
				gcc_jit_block_add_assignment(
					ctx.curBlock,
					null,
					gcc_jit_lvalue_access_field(local, null, ptrField),
					arrPtr);
				gcc_jit_block_add_assignment(
					ctx.curBlock,
					null,
					gcc_jit_lvalue_access_field(local, null, sizeField),
					gcc_jit_context_new_rvalue_from_long(ctx.gcc, ctx.nat64Type, arrSize));
			});
		},
		(immutable Constant.BoolConstant it) =>
			emitSimpleNoSideEffects(ctx, emit, gcc_jit_context_new_rvalue_from_long(
				ctx.gcc,
				getGccType(ctx.types, type),
				it.value ? 1 : 0)),
		(ref immutable Constant.CString it) =>
			emitSimpleNoSideEffects(ctx, emit, gcc_jit_context_new_string_literal(
				ctx.gcc,
				ctx.program.allConstants.cStrings[it.index].ptr)),
		(immutable Constant.Float it) =>
			emitSimpleNoSideEffects(
				ctx,
				emit,
				gcc_jit_context_new_rvalue_from_double(ctx.gcc, getGccType(ctx.types, type), it.value)),
		(immutable Constant.FunPtr it) {
			immutable gcc_jit_rvalue* value = gcc_jit_function_get_address(
				ctx.gccFuns[mustGetAt(ctx.program.concreteFunToLowFunIndex, it.fun)],
				null);
			immutable gcc_jit_rvalue* castValue = () {
				if (isPtrRawConst(type)) {
					// We need to cast function pointer to any-ptr for 'all-funs'
					return gcc_jit_context_new_cast(ctx.gcc, null, value, getGccType(ctx.types, type));
				} else {
					verify(isFunPtrType(type));
					return value;
				}
			}();
			return emitSimpleNoSideEffects(ctx, emit, castValue);
		},
		(immutable Constant.Integral it) =>
			emitSimpleNoSideEffects(
				ctx,
				emit,
				gcc_jit_context_new_rvalue_from_long(ctx.gcc, getGccType(ctx.types, type), it.value)),
		(immutable Constant.Null) =>
			emitSimpleNoSideEffects(ctx, emit, gcc_jit_context_null(ctx.gcc, getGccType(ctx.types, type))),
		(immutable Constant.Pointer it) {
			gcc_jit_lvalue* storage = ctx.globalsForConstants.pointers[it.typeIndex][it.index];
			return emitSimpleNoSideEffects(ctx, emit, gcc_jit_lvalue_get_address(storage, null));
		},
		(ref immutable Constant.Record it) {
			immutable LowField[] fields = ctx.program.allRecords[asRecordType(type)].fields;
			return emitRecordCbWithArgs(
				ctx,
				emit,
				type,
				it.args,
				(immutable size_t argIndex, ref ExprEmit emitArg, ref immutable Constant arg) =>
					constantToGcc(ctx, emitArg, fields[argIndex].type, arg));
		},
		(ref immutable Constant.Union it) {
			immutable LowType argType = ctx.program.allUnions[asUnionType(type)].members[it.memberIndex];
			return emitUnion(ctx, emit, type, it.memberIndex, (ref ExprEmit emitArg) =>
				constantToGcc(ctx, emit, argType, it.arg));
		},
		(immutable Constant.Void) =>
			emitVoid(ctx, emit));
}

@trusted immutable(ExprResult) unaryToGcc(
	ref ExprCtx ctx,
	ref Locals locals,
	ref ExprEmit emit,
	ref immutable LowExpr expr,
	ref immutable LowExprKind.SpecialUnary a,
) {
	final switch (a.kind) {
		case LowExprKind.SpecialUnary.Kind.bitwiseNotNat8:
		case LowExprKind.SpecialUnary.Kind.bitwiseNotNat16:
		case LowExprKind.SpecialUnary.Kind.bitwiseNotNat32:
		case LowExprKind.SpecialUnary.Kind.bitwiseNotNat64:
			return emitSimpleNoSideEffects(ctx, emit, gcc_jit_context_new_unary_op(
				ctx.gcc,
				null,
				gcc_jit_unary_op.GCC_JIT_UNARY_OP_BITWISE_NEGATE,
				getGccType(ctx.types, expr.type),
				emitToRValue(ctx, locals, a.arg)));
		case LowExprKind.SpecialUnary.Kind.countOnesNat64:
			return countOnesToGcc(ctx, locals, emit, a.arg);
		case LowExprKind.SpecialUnary.Kind.deref:
			return emitSimpleNoSideEffects(ctx, emit, gcc_jit_lvalue_as_rvalue(
				gcc_jit_rvalue_dereference(emitToRValue(ctx, locals, a.arg), null)));
		case LowExprKind.SpecialUnary.Kind.ptrTo:
		case LowExprKind.SpecialUnary.Kind.refOfVal:
			return emitSimpleNoSideEffects(ctx, emit, gcc_jit_lvalue_get_address(getLValue(ctx, locals, a.arg), null));
		case LowExprKind.SpecialUnary.Kind.asAnyPtr:
		case LowExprKind.SpecialUnary.Kind.asRef:
		case LowExprKind.SpecialUnary.Kind.enumToIntegral:
		case LowExprKind.SpecialUnary.Kind.toCharFromNat8:
		case LowExprKind.SpecialUnary.Kind.toFloat32FromFloat64:
		case LowExprKind.SpecialUnary.Kind.toFloat64FromFloat32:
		case LowExprKind.SpecialUnary.Kind.toFloat64FromInt64:
		case LowExprKind.SpecialUnary.Kind.toFloat64FromNat64:
		case LowExprKind.SpecialUnary.Kind.toInt64FromInt16:
		case LowExprKind.SpecialUnary.Kind.toInt64FromInt32:
		case LowExprKind.SpecialUnary.Kind.toNat8FromChar:
		case LowExprKind.SpecialUnary.Kind.toNat64FromNat8:
		case LowExprKind.SpecialUnary.Kind.toNat64FromNat16:
		case LowExprKind.SpecialUnary.Kind.toNat64FromNat32:
		case LowExprKind.SpecialUnary.Kind.truncateToInt64FromFloat64:
		case LowExprKind.SpecialUnary.Kind.unsafeInt32ToNat32:
		case LowExprKind.SpecialUnary.Kind.unsafeInt64ToInt8:
		case LowExprKind.SpecialUnary.Kind.unsafeInt64ToInt16:
		case LowExprKind.SpecialUnary.Kind.unsafeInt64ToInt32:
		case LowExprKind.SpecialUnary.Kind.unsafeInt64ToNat64:
		case LowExprKind.SpecialUnary.Kind.unsafeNat64ToInt64:
		case LowExprKind.SpecialUnary.Kind.unsafeNat64ToNat8:
		case LowExprKind.SpecialUnary.Kind.unsafeNat64ToNat16:
		case LowExprKind.SpecialUnary.Kind.unsafeNat64ToNat32:
			return emitSimpleNoSideEffects(ctx, emit, gcc_jit_context_new_cast(
				ctx.gcc,
				null,
				emitToRValue(ctx, locals, a.arg),
				getGccType(ctx.types, expr.type)));
		case LowExprKind.SpecialUnary.Kind.toNat64FromPtr:
			immutable gcc_jit_rvalue* arg = emitToRValue(ctx, locals, a.arg);
			return emitSimpleNoSideEffects(ctx, emit, castImmutable(
				gcc_jit_context_new_call(ctx.gcc, null, ctx.conversionFunctions.ptrToNat64, 1, &arg)));
		case LowExprKind.SpecialUnary.Kind.toPtrFromNat64:
			immutable gcc_jit_rvalue* arg = emitToRValue(ctx, locals, a.arg);
			return emitSimpleNoSideEffects(ctx, emit, gcc_jit_context_new_cast(
				ctx.gcc,
				null,
				castImmutable(gcc_jit_context_new_call(ctx.gcc, null, ctx.conversionFunctions.nat64ToPtr, 1, &arg)),
				getGccType(ctx.types, expr.type)));
	}
}

@trusted immutable(ExprResult) countOnesToGcc(
	ref ExprCtx ctx,
	ref Locals locals,
	ref ExprEmit emit,
	ref immutable LowExpr arg,
) {
	immutable gcc_jit_rvalue* argGcc = emitToRValue(ctx, locals, arg);
	immutable gcc_jit_rvalue* call = castImmutable(gcc_jit_context_new_call(
		ctx.gcc,
		null,
		ctx.builtinPopcountlFunction,
		1,
		&argGcc));
	return emitSimpleNoSideEffects(ctx, emit, gcc_jit_context_new_cast(ctx.gcc, null, call, ctx.nat64Type));
}

immutable(ExprResult) binaryToGcc(
	ref ExprCtx ctx,
	ref Locals locals,
	ref ExprEmit emit,
	ref immutable LowExpr expr,
	ref immutable LowExprKind.SpecialBinary a,
) {
	immutable(ExprResult) operator(immutable gcc_jit_binary_op op) {
		return binaryOperator(ctx, locals, emit, expr.type, op, a.left, a.right);
	}

	immutable(ExprResult) comparison(immutable gcc_jit_comparison cmp) {
		return emitSimpleNoSideEffects(ctx, emit, gcc_jit_context_new_comparison(
			ctx.gcc,
			null,
			cmp,
			emitToRValue(ctx, locals, a.left),
			emitToRValue(ctx, locals, a.right)));
	}

	final switch (a.kind) {
		case LowExprKind.SpecialBinary.Kind.addFloat32:
		case LowExprKind.SpecialBinary.Kind.addFloat64:
		case LowExprKind.SpecialBinary.Kind.unsafeAddInt8:
		case LowExprKind.SpecialBinary.Kind.unsafeAddInt16:
		case LowExprKind.SpecialBinary.Kind.unsafeAddInt32:
		case LowExprKind.SpecialBinary.Kind.unsafeAddInt64:
		case LowExprKind.SpecialBinary.Kind.wrapAddNat8:
		case LowExprKind.SpecialBinary.Kind.wrapAddNat16:
		case LowExprKind.SpecialBinary.Kind.wrapAddNat32:
		case LowExprKind.SpecialBinary.Kind.wrapAddNat64:
			// TODO: does this handle wrapping?
			return operator(gcc_jit_binary_op.GCC_JIT_BINARY_OP_PLUS);
		case LowExprKind.SpecialBinary.Kind.addPtrAndNat64:
			return ptrArithmeticToGcc(ctx, locals, emit, PtrArith.addNat, a.left, a.right);
		case LowExprKind.SpecialBinary.Kind.and:
			return logicalOperatorToGcc(ctx, locals, emit, LogicalOperator.and, a.left, a.right);
		case LowExprKind.SpecialBinary.Kind.bitwiseAndInt8:
		case LowExprKind.SpecialBinary.Kind.bitwiseAndInt16:
		case LowExprKind.SpecialBinary.Kind.bitwiseAndInt32:
		case LowExprKind.SpecialBinary.Kind.bitwiseAndInt64:
		case LowExprKind.SpecialBinary.Kind.bitwiseAndNat8:
		case LowExprKind.SpecialBinary.Kind.bitwiseAndNat16:
		case LowExprKind.SpecialBinary.Kind.bitwiseAndNat32:
		case LowExprKind.SpecialBinary.Kind.bitwiseAndNat64:
			return operator(gcc_jit_binary_op.GCC_JIT_BINARY_OP_BITWISE_AND);
		case LowExprKind.SpecialBinary.Kind.bitwiseOrInt8:
		case LowExprKind.SpecialBinary.Kind.bitwiseOrInt16:
		case LowExprKind.SpecialBinary.Kind.bitwiseOrInt32:
		case LowExprKind.SpecialBinary.Kind.bitwiseOrInt64:
		case LowExprKind.SpecialBinary.Kind.bitwiseOrNat8:
		case LowExprKind.SpecialBinary.Kind.bitwiseOrNat16:
		case LowExprKind.SpecialBinary.Kind.bitwiseOrNat32:
		case LowExprKind.SpecialBinary.Kind.bitwiseOrNat64:
			return operator(gcc_jit_binary_op.GCC_JIT_BINARY_OP_BITWISE_OR);
		case LowExprKind.SpecialBinary.Kind.bitwiseXorInt8:
		case LowExprKind.SpecialBinary.Kind.bitwiseXorInt16:
		case LowExprKind.SpecialBinary.Kind.bitwiseXorInt32:
		case LowExprKind.SpecialBinary.Kind.bitwiseXorInt64:
		case LowExprKind.SpecialBinary.Kind.bitwiseXorNat8:
		case LowExprKind.SpecialBinary.Kind.bitwiseXorNat16:
		case LowExprKind.SpecialBinary.Kind.bitwiseXorNat32:
		case LowExprKind.SpecialBinary.Kind.bitwiseXorNat64:
			return operator(gcc_jit_binary_op.GCC_JIT_BINARY_OP_BITWISE_XOR);
		case LowExprKind.SpecialBinary.Kind.eqFloat32:
		case LowExprKind.SpecialBinary.Kind.eqFloat64:
		case LowExprKind.SpecialBinary.Kind.eqInt8:
		case LowExprKind.SpecialBinary.Kind.eqInt16:
		case LowExprKind.SpecialBinary.Kind.eqInt32:
		case LowExprKind.SpecialBinary.Kind.eqInt64:
		case LowExprKind.SpecialBinary.Kind.eqNat8:
		case LowExprKind.SpecialBinary.Kind.eqNat16:
		case LowExprKind.SpecialBinary.Kind.eqNat32:
		case LowExprKind.SpecialBinary.Kind.eqNat64:
		case LowExprKind.SpecialBinary.Kind.eqPtr:
			return comparison(gcc_jit_comparison.GCC_JIT_COMPARISON_EQ);
		case LowExprKind.SpecialBinary.Kind.lessBool:
		case LowExprKind.SpecialBinary.Kind.lessChar:
		case LowExprKind.SpecialBinary.Kind.lessFloat32:
		case LowExprKind.SpecialBinary.Kind.lessFloat64:
		case LowExprKind.SpecialBinary.Kind.lessInt8:
		case LowExprKind.SpecialBinary.Kind.lessInt16:
		case LowExprKind.SpecialBinary.Kind.lessInt32:
		case LowExprKind.SpecialBinary.Kind.lessInt64:
		case LowExprKind.SpecialBinary.Kind.lessNat8:
		case LowExprKind.SpecialBinary.Kind.lessNat16:
		case LowExprKind.SpecialBinary.Kind.lessNat32:
		case LowExprKind.SpecialBinary.Kind.lessNat64:
		case LowExprKind.SpecialBinary.Kind.lessPtr:
			return comparison(gcc_jit_comparison.GCC_JIT_COMPARISON_LT);
		case LowExprKind.SpecialBinary.Kind.mulFloat32:
		case LowExprKind.SpecialBinary.Kind.mulFloat64:
		case LowExprKind.SpecialBinary.Kind.unsafeMulInt8:
		case LowExprKind.SpecialBinary.Kind.unsafeMulInt16:
		case LowExprKind.SpecialBinary.Kind.unsafeMulInt32:
		case LowExprKind.SpecialBinary.Kind.unsafeMulInt64:
		case LowExprKind.SpecialBinary.Kind.wrapMulNat8:
		case LowExprKind.SpecialBinary.Kind.wrapMulNat16:
		case LowExprKind.SpecialBinary.Kind.wrapMulNat32:
		case LowExprKind.SpecialBinary.Kind.wrapMulNat64:
			// TODO: does this handle wrapping?
			return operator(gcc_jit_binary_op.GCC_JIT_BINARY_OP_MULT);
		case LowExprKind.SpecialBinary.Kind.orBool:
			return logicalOperatorToGcc(ctx, locals, emit, LogicalOperator.or, a.left, a.right);
		case LowExprKind.SpecialBinary.Kind.subFloat32:
		case LowExprKind.SpecialBinary.Kind.subFloat64:
		case LowExprKind.SpecialBinary.Kind.unsafeSubInt8:
		case LowExprKind.SpecialBinary.Kind.unsafeSubInt16:
		case LowExprKind.SpecialBinary.Kind.unsafeSubInt32:
		case LowExprKind.SpecialBinary.Kind.unsafeSubInt64:
		case LowExprKind.SpecialBinary.Kind.wrapSubNat8:
		case LowExprKind.SpecialBinary.Kind.wrapSubNat16:
		case LowExprKind.SpecialBinary.Kind.wrapSubNat32:
		case LowExprKind.SpecialBinary.Kind.wrapSubNat64:
			// TODO: does this handle wrapping?
			return operator(gcc_jit_binary_op.GCC_JIT_BINARY_OP_MINUS);
		case LowExprKind.SpecialBinary.Kind.subPtrAndNat64:
			return ptrArithmeticToGcc(ctx, locals, emit, PtrArith.subtractNat, a.left, a.right);
		case LowExprKind.SpecialBinary.Kind.unsafeBitShiftLeftNat64:
			return operator(gcc_jit_binary_op.GCC_JIT_BINARY_OP_LSHIFT);
		case LowExprKind.SpecialBinary.Kind.unsafeBitShiftRightNat64:
			return operator(gcc_jit_binary_op.GCC_JIT_BINARY_OP_RSHIFT);
		case LowExprKind.SpecialBinary.Kind.unsafeDivFloat32:
		case LowExprKind.SpecialBinary.Kind.unsafeDivFloat64:
		case LowExprKind.SpecialBinary.Kind.unsafeDivInt8:
		case LowExprKind.SpecialBinary.Kind.unsafeDivInt16:
		case LowExprKind.SpecialBinary.Kind.unsafeDivInt32:
		case LowExprKind.SpecialBinary.Kind.unsafeDivInt64:
		case LowExprKind.SpecialBinary.Kind.unsafeDivNat8:
		case LowExprKind.SpecialBinary.Kind.unsafeDivNat16:
		case LowExprKind.SpecialBinary.Kind.unsafeDivNat32:
		case LowExprKind.SpecialBinary.Kind.unsafeDivNat64:
			return operator(gcc_jit_binary_op.GCC_JIT_BINARY_OP_DIVIDE);
		case LowExprKind.SpecialBinary.Kind.unsafeModNat64:
			return operator(gcc_jit_binary_op.GCC_JIT_BINARY_OP_MODULO);
		case LowExprKind.SpecialBinary.Kind.writeToPtr:
			immutable gcc_jit_rvalue* left = emitToRValue(ctx, locals, a.left);
			immutable gcc_jit_rvalue* right = emitToRValue(ctx, locals, a.right);
			gcc_jit_block_add_assignment(ctx.curBlock, null, gcc_jit_rvalue_dereference(left, null), right);
			return emitVoid(ctx, emit);
	}
}

immutable(ExprResult) binaryOperator(
	ref ExprCtx ctx,
	ref Locals locals,
	ref ExprEmit emit,
	immutable LowType type,
	immutable gcc_jit_binary_op op,
	ref immutable LowExpr left,
	ref immutable LowExpr right,
) {
	return operatorForLhsRhs(ctx, emit, type, op, emitToRValue(ctx, locals, left), emitToRValue(ctx, locals, right));
}

immutable(ExprResult) operatorForLhsRhs(
	ref ExprCtx ctx,
	ref ExprEmit emit,
	immutable LowType type,
	immutable gcc_jit_binary_op op,
	immutable gcc_jit_rvalue* lhs,
	immutable gcc_jit_rvalue* rhs,
) {
	return emitSimpleNoSideEffects(ctx, emit, gcc_jit_context_new_binary_op(
		ctx.gcc,
		null,
		op,
		getGccType(ctx.types, type),
		lhs,
		rhs));
}

enum LogicalOperator { and, or }

immutable(ExprResult) logicalOperatorToGcc(
	ref ExprCtx ctx,
	ref Locals locals,
	ref ExprEmit emit,
	immutable LogicalOperator operator,
	ref immutable LowExpr left,
	ref immutable LowExpr right,
) {
	if (true) {//isReturn(emit)) {
		final switch (operator) {
			case LogicalOperator.and:
				// if (left) return right; else return false;
				return ifToGcc(ctx, locals, emit, boolType, left, right, boolExpr(false));
			case LogicalOperator.or:
				// if (left) return true; else return right;
				return ifToGcc(ctx, locals, emit, boolType, left, boolExpr(true), right);
		}
	} else {
		// TODO:KILL
		// This only works if left and right sides have no side effects.
		// Else 'emitSimpleYesSideEffects' will cause 'right' to evaluate anyway.
		immutable gcc_jit_binary_op op = () {
			final switch (operator) {
				case LogicalOperator.and:
					return gcc_jit_binary_op.GCC_JIT_BINARY_OP_LOGICAL_AND;
				case LogicalOperator.or:
					return gcc_jit_binary_op.GCC_JIT_BINARY_OP_LOGICAL_OR;
			}
		}();
		return binaryOperator(ctx, locals, emit, boolType, op, left, right);
	}
}

immutable(LowType) boolType() {
	return immutable LowType(PrimitiveType.bool_);
}

immutable(LowExpr) boolExpr(immutable bool value) {
	return immutable LowExpr(
		boolType(),
		FileAndRange.empty,
		immutable LowExprKind(immutable Constant(immutable Constant.BoolConstant(value))));
}

enum PtrArith { addNat, subtractNat }

immutable(ExprResult) ptrArithmeticToGcc(
	ref ExprCtx ctx,
	ref Locals locals,
	ref ExprEmit emit,
	immutable PtrArith op,
	ref immutable LowExpr left,
	ref immutable LowExpr right,
) {
	// `ptr + nat` is `&ptr[nat]`
	// `ptr - nat` is `&ptr[-(int) nat]`
	immutable gcc_jit_rvalue* rightRValue = emitToRValue(ctx, locals, right);
	immutable gcc_jit_rvalue* rightWithSign = () {
		final switch (op) {
			case PtrArith.addNat:
				return rightRValue;
			case PtrArith.subtractNat:
				immutable gcc_jit_type* int64Type = getGccType(ctx.types, immutable LowType(PrimitiveType.int64));
				return gcc_jit_context_new_unary_op(
					ctx.gcc,
					null,
					gcc_jit_unary_op.GCC_JIT_UNARY_OP_MINUS,
					int64Type,
					gcc_jit_context_new_cast(
						ctx.gcc,
						null,
						rightRValue,
						int64Type));
		}
	}();
	return emitSimpleNoSideEffects(ctx, emit, gcc_jit_lvalue_get_address(
		gcc_jit_context_new_array_access(
			ctx.gcc,
			null,
			emitToRValue(ctx, locals, left),
			rightWithSign),
		null));
}

immutable(ExprResult) ifToGcc(
	ref ExprCtx ctx,
	ref Locals locals,
	ref ExprEmit emit,
	immutable LowType type,
	immutable LowExpr cond,
	immutable LowExpr then,
	immutable LowExpr else_,
) {
	immutable gcc_jit_rvalue* condValue = emitToRValue(ctx, locals, cond);
	return emitWithBranching(
		ctx, emit, type, "ifEnd",
		(
			gcc_jit_block* originalBlock,
			Opt!(gcc_jit_block*) endBlock,
			Opt!(gcc_jit_lvalue*) local,
			immutable ExprResult expectedResult,
		) {
			gcc_jit_block* thenBlock = gcc_jit_function_new_block(ctx.curFun, "then");
			gcc_jit_block* elseBlock = gcc_jit_function_new_block(ctx.curFun, "else");
			gcc_jit_block_end_with_conditional(originalBlock, null, condValue, thenBlock, elseBlock);
			void branch(gcc_jit_block* block, ref immutable LowExpr blockExpr) {
				ctx.curBlock = block;
				immutable ExprResult result = {
					if (has(local)) {
						emitToLValue(ctx, locals, force(local), blockExpr);
						return immutable ExprResult(ExprResult.Void());
					}	else
						return toGccExpr(ctx, locals, emit, blockExpr);
				}();
				if (has(endBlock) && !isBreakContinueOrReturn(result)) {
					// A nested if may have changed the block, so use 'curBlock' and not just 'block'
					gcc_jit_block_end_with_jump(ctx.curBlock, null, force(endBlock));
				}
				verify(result == expectedResult);
			}
			branch(thenBlock, then);
			branch(elseBlock, else_);
		});
}

immutable(ExprResult) switch0ToNToGcc(
	ref ExprCtx ctx,
	ref Locals locals,
	ref ExprEmit emit,
	ref immutable LowExpr expr,
	ref immutable LowExprKind.Switch0ToN a,
) {
	return emitSwitch(
		ctx,
		emit,
		expr.type,
		emitToRValue(ctx, locals, a.value),
		a.cases.length,
		(ref ExprEmit caseEmit, immutable size_t caseIndex) =>
			toGccExpr(ctx, locals, caseEmit, a.cases[caseIndex]));
}

immutable(ExprResult) zeroedToGcc(
	ref ExprCtx ctx,
	ref ExprEmit emit,
	immutable LowType type,
) {
	immutable gcc_jit_type* gccType = getGccType(ctx.types, type);
	return matchLowTypeCombinePtr!(
		immutable ExprResult,
		(immutable LowType.ExternPtr) =>
			emitSimpleNoSideEffects(ctx, emit, gcc_jit_context_null(ctx.gcc, gccType)),
		(immutable LowType.FunPtr) =>
			emitSimpleNoSideEffects(ctx, emit, gcc_jit_context_null(ctx.gcc, gccType)),
		(immutable PrimitiveType it) {
			final switch (it) {
				case PrimitiveType.bool_:
				case PrimitiveType.char8:
				case PrimitiveType.int8:
				case PrimitiveType.int16:
				case PrimitiveType.int32:
				case PrimitiveType.int64:
				case PrimitiveType.nat8:
				case PrimitiveType.nat16:
				case PrimitiveType.nat32:
				case PrimitiveType.nat64:
					return emitSimpleNoSideEffects(
						ctx,
						emit,
						gcc_jit_context_new_rvalue_from_long(ctx.gcc, gccType, 0));
				case PrimitiveType.float32:
				case PrimitiveType.float64:
					return emitSimpleNoSideEffects(
						ctx,
						emit,
						gcc_jit_context_new_rvalue_from_double(ctx.gcc, gccType, 0));
				case PrimitiveType.void_:
					return emitWriteToLValue(ctx, emit, type, (gcc_jit_lvalue*) {
						// empty type, nothing to write to
					});
			}
		},
		(immutable(LowPtrCombine)) =>
			emitSimpleNoSideEffects(ctx, emit, gcc_jit_context_null(ctx.gcc, gccType)),
		(immutable LowType.Record record) {
			immutable LowField[] fields = ctx.program.allRecords[record].fields;
			return emitRecordCb(ctx, emit, type, (immutable size_t argIndex, ref ExprEmit emitArg) =>
				zeroedToGcc(ctx, emitArg, fields[argIndex].type));
		},
		(immutable LowType.Union union_) =>
			emitUnion(ctx, emit, type, 0, (ref ExprEmit emitArg) =>
				zeroedToGcc(ctx, emitArg, ctx.program.allUnions[union_].members[0])),
	)(type);
}

immutable(gcc_jit_rvalue*) arbitraryValue(ref ExprCtx ctx, immutable LowType type) {
	immutable(gcc_jit_rvalue*) nullValue() {
		return gcc_jit_context_null(ctx.gcc, getGccType(ctx.types, type));
	}
	return matchLowTypeCombinePtr!(
		immutable gcc_jit_rvalue*,
		(immutable LowType.ExternPtr) =>
			nullValue(),
		(immutable LowType.FunPtr) =>
			nullValue(),
		(immutable(PrimitiveType)) =>
			emitToRValueCb((ref ExprEmit emit) =>
				zeroedToGcc(ctx, emit, type)),
		(immutable(LowPtrCombine)) =>
			nullValue(),
		(immutable LowType.Record) =>
			getRValueUsingLocal(ctx, type, (gcc_jit_lvalue*) {}),
		(immutable LowType.Union) =>
			getRValueUsingLocal(ctx, type, (gcc_jit_lvalue*) {}),
	)(type);
}

gcc_jit_lvalue* getLValue(ref ExprCtx ctx, ref Locals locals, ref immutable LowExpr expr) {
	return matchLowExprKind!(
		gcc_jit_lvalue*,
		(ref immutable LowExprKind.Call) => unreachable!(gcc_jit_lvalue*)(),
		(ref immutable LowExprKind.CallFunPtr) => unreachable!(gcc_jit_lvalue*)(),
		(ref immutable LowExprKind.CreateRecord) => unreachable!(gcc_jit_lvalue*)(),
		(ref immutable LowExprKind.CreateUnion) => unreachable!(gcc_jit_lvalue*)(),
		(ref immutable LowExprKind.If) => unreachable!(gcc_jit_lvalue*)(),
		(ref immutable LowExprKind.InitConstants) => unreachable!(gcc_jit_lvalue*)(),
		(ref immutable LowExprKind.Let) => unreachable!(gcc_jit_lvalue*)(),
		(ref immutable LowExprKind.LocalRef it) =>
			getLocal(locals, it.local),
		(ref immutable LowExprKind.LocalSet) => unreachable!(gcc_jit_lvalue*)(),
		(ref immutable LowExprKind.Loop) => unreachable!(gcc_jit_lvalue*)(),
		(ref immutable LowExprKind.LoopBreak) => unreachable!(gcc_jit_lvalue*)(),
		(ref immutable LowExprKind.LoopContinue) => unreachable!(gcc_jit_lvalue*)(),
		(ref immutable LowExprKind.MatchUnion) => unreachable!(gcc_jit_lvalue*)(),
		(ref immutable LowExprKind.ParamRef it) =>
			gcc_jit_param_as_lvalue(getParam(ctx, it)),
		(ref immutable LowExprKind.PtrCast) => todo!(gcc_jit_lvalue*)("!"),
		(ref immutable LowExprKind.RecordFieldGet it) =>
			recordFieldGetToLValue(ctx, locals, it),
		(ref immutable LowExprKind.RecordFieldSet) => unreachable!(gcc_jit_lvalue*)(),
		(ref immutable LowExprKind.Seq) => unreachable!(gcc_jit_lvalue*)(),
		(ref immutable LowExprKind.SizeOf) => unreachable!(gcc_jit_lvalue*)(),
		(ref immutable Constant) => unreachable!(gcc_jit_lvalue*)(),
		(ref immutable LowExprKind.SpecialUnary it) =>
			it.kind == LowExprKind.SpecialUnary.Kind.deref
				? gcc_jit_rvalue_dereference(emitToRValue(ctx, locals, it.arg), null)
				: todo!(gcc_jit_lvalue*)("!"),
		(ref immutable LowExprKind.SpecialBinary) => unreachable!(gcc_jit_lvalue*)(),
		(ref immutable LowExprKind.SpecialTernary) => unreachable!(gcc_jit_lvalue*)(),
		(ref immutable LowExprKind.Switch0ToN) => unreachable!(gcc_jit_lvalue*)(),
		(ref immutable LowExprKind.SwitchWithValues) => unreachable!(gcc_jit_lvalue*)(),
		(ref immutable LowExprKind.TailRecur) => unreachable!(gcc_jit_lvalue*)(),
		(ref immutable LowExprKind.Zeroed) => unreachable!(gcc_jit_lvalue*)(),
	)(expr.kind);
}

immutable(ExprResult) initConstantsToGcc(ref ExprCtx ctx, ref ExprEmit emit) {
	zip!(gcc_jit_rvalue*[], ArrTypeAndConstantsLow)(
		ctx.globalsForConstants.arrs,
		ctx.program.allConstants.arrs,
		(ref immutable gcc_jit_rvalue*[] globals, ref immutable ArrTypeAndConstantsLow tc) {
			zip!(gcc_jit_rvalue*, Constant[])(
				globals,
				tc.constants,
				(ref immutable gcc_jit_rvalue* global, ref immutable Constant[] elements) {
					verify(!empty(elements)); // Not sure how GCC would handle an empty global
					foreach (immutable size_t index, immutable Constant elementValue; elements) {
						gcc_jit_lvalue* elementLValue = gcc_jit_context_new_array_access(
							ctx.gcc,
							null,
							global,
							//TODO: maybe cache these values?
							gcc_jit_context_new_rvalue_from_long(ctx.gcc, ctx.nat64Type, index));
						emitToLValueCb(elementLValue, (ref ExprEmit emitElement) =>
							constantToGcc(ctx, emitElement, tc.elementType, elementValue));
					}
				});
		});
	zipFirstMut!(gcc_jit_lvalue*[], PointerTypeAndConstantsLow)(
		ctx.globalsForConstants.pointers,
		ctx.program.allConstants.pointers,
		(ref gcc_jit_lvalue*[] globals, ref immutable PointerTypeAndConstantsLow tc) {
			zipFirstMut!(gcc_jit_lvalue*, Constant)(
				globals,
				tc.constants,
				(ref gcc_jit_lvalue* global, ref immutable Constant value) {
					emitToLValueCb(global, (ref ExprEmit emitPointee) =>
						constantToGcc(ctx, emitPointee, tc.pointeeType, value));
				});
		});
	return emitVoid(ctx, emit);
}
