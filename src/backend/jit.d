module backend.jit;

@safe @nogc nothrow: // not pure

version (GccJitAvailable) {

import backend.gccTypes :
	assertFieldOffsetsFunctionName,
	AssertFieldOffsetsType,
	ExternTypeInfo,
	ExternTypeArrayInfo,
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
	gcc_jit_context_new_array_constructor,
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
	gcc_jit_lvalue_set_tls_model,
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
	gcc_jit_tls_model,
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
	writeLowVarMangledName;
import frontend.lang : JitOptions, OptimizationLevel;
import model.constant : Constant, constantBool;
import model.lowModel :
	ArrTypeAndConstantsLow,
	ExternLibrary,
	LowExpr,
	LowExprKind,
	LowField,
	LowFun,
	LowFunBody,
	LowFunExprBody,
	LowFunIndex,
	LowLocal,
	LowProgram,
	LowPtrCombine,
	LowVar,
	LowVarIndex,
	LowType,
	lowTypeEqualCombinePtr,
	name,
	PointerTypeAndConstantsLow,
	PrimitiveType,
	targetIsPointer,
	targetRecordType,
	UpdateParam;
import model.model : Program;
import model.typeLayout : typeSizeBytes;
import util.alloc.alloc : Alloc;
import util.col.arr : empty;
import util.col.arrUtil : indexOfPointer, makeArr, map, mapToMut, mapWithIndex, zip;
import util.col.map : mustGetAt;
import util.col.fullIndexMap : FullIndexMap, fullIndexMapZip, mapFullIndexMap_mut;
import util.col.stackMap : StackMap, stackMapAdd, stackMapMustGet, withStackMap;
import util.col.str : CStr, SafeCStr;
import util.conv : safeToInt;
import util.opt : force, has, MutOpt, none, noneMut, Opt, some, someMut;
import util.perf : Perf, PerfMeasure, withMeasure;
import util.ptr : castImmutable, castNonScope, castNonScope_ref, ptrTrustMe;
import util.sourceRange : FileAndRange;
import util.sym : AllSymbols, writeSym;
import util.union_ : Union, UnionMutable;
import util.util : todo, unreachable, verify;
import util.writer : debugLogWithWriter, finishWriterToCStr, Writer;

@trusted int jitAndRun(
	ref Alloc alloc,
	ref Perf perf,
	in AllSymbols allSymbols,
	in LowProgram program,
	in JitOptions options,
	in SafeCStr[] allArgs,
) {
	GccProgram gccProgram = getGccProgram(alloc, perf, allSymbols, program, options);

	//TODO: perf measure this?
	AssertFieldOffsetsType assertFieldOffsets = cast(AssertFieldOffsetsType)
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

	MainType main = withMeasure!(MainType, () @trusted =>
		cast(MainType) gcc_jit_result_get_code(gccProgram.result, "main")
	)(alloc, perf, PerfMeasure.gccJit);
	verify(main != null);
	gcc_jit_context_release(gccProgram.ctx);

	bool fieldOffsetsCorrect = assertFieldOffsets();
	verify(fieldOffsetsCorrect);
	int exitCode = runMain(alloc, perf, allArgs, main);
	gcc_jit_result_release(gccProgram.result);
	return exitCode;
}

private:

int runMain(ref Alloc alloc, ref Perf perf, in SafeCStr[] allArgs, MainType main) =>
	withMeasure!(int, () @trusted =>
		main(cast(int) allArgs.length, cast(CStr*) allArgs.ptr)
	)(alloc, perf, PerfMeasure.run);

pure:


struct GccProgram {
	gcc_jit_context* ctx;
	immutable gcc_jit_result* result;
}

GccProgram getGccProgram(
	ref Alloc alloc,
	ref Perf perf,
	in AllSymbols allSymbols,
	in LowProgram program,
	in JitOptions options,
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

	foreach (ref ExternLibrary x; program.externLibraries) {
		//TODO:NO ALLOC
		Writer writer = Writer(ptrTrustMe(alloc));
		writer ~= "-l";
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
	alias MainType = immutable int function(int, CStr*) @nogc nothrow;
}

void buildGccProgram(ref Alloc alloc, ref gcc_jit_context ctx, in AllSymbols allSymbols, in LowProgram program) {
	scope MangledNames mangledNames = buildMangledNames(alloc, ptrTrustMe(allSymbols), program);
	GccTypes gccTypes = getGccTypes(alloc, ctx, allSymbols, program, mangledNames);

	//TODO:only in debug
	generateAssertFieldOffsetsFunction(alloc, ctx, program, gccTypes);

	GlobalsForConstants globalsForConstants = generateGlobalsForConstants(alloc, ctx, program, gccTypes, mangledNames);
	GccVars gccVars = generateGccVars(alloc, ctx, program, gccTypes, mangledNames);

	immutable gcc_jit_type* crowVoidType = getGccType(gccTypes, LowType(PrimitiveType.void_));
	gcc_jit_rvalue* globalVoid = gcc_jit_lvalue_as_rvalue(
		gcc_jit_context_new_global(
			ctx,
			null,
			gcc_jit_global_kind.GCC_JIT_GLOBAL_INTERNAL,
			crowVoidType,
			"void"));

	//immutable FullIndexMap!(LowFunIndex, LowFun) allFuns;
	FullIndexMap!(LowFunIndex, gcc_jit_function*) gccFuns =
		mapFullIndexMap_mut!(LowFunIndex, gcc_jit_function*, LowFun)(
			alloc,
			program.allFuns,
			(LowFunIndex funIndex, in LowFun fun) =>
				toGccFunctionSignature(alloc, ctx, program, mangledNames, gccTypes, funIndex, fun));

	immutable gcc_jit_type* nat64Type = getGccType(gccTypes, LowType(PrimitiveType.nat64));
	immutable gcc_jit_function* abortFunction = castImmutable(gcc_jit_context_new_function(
		ctx,
		null,
		gcc_jit_function_kind.GCC_JIT_FUNCTION_IMPORTED,
		gcc_jit_context_get_type(ctx, gcc_jit_types.GCC_JIT_TYPE_VOID),
		"abort",
		0,
		null,
		false));
	ConversionFunctions conversionFunctions = generateConversionFunctions(ctx);
	immutable gcc_jit_function* builtinPopcountlFunction =
		gcc_jit_context_get_builtin_function(ctx, "__builtin_popcountl");

	// Now fill in the body of every function.
	fullIndexMapZip!(LowFunIndex, LowFun, gcc_jit_function*)(
		program.allFuns,
		gccFuns,
		(LowFunIndex funIndex, ref LowFun fun, ref gcc_jit_function* curFun) {
		fun.body_.match!void(
			(LowFunBody.Extern it) {},
			(LowFunExprBody expr) {
				gcc_jit_block* entryBlock = gcc_jit_function_new_block(curFun, "entry");
				ExprCtx exprCtx = ExprCtx(
					ptrTrustMe(alloc),
					ptrTrustMe(allSymbols),
					ptrTrustMe(program),
					ptrTrustMe(ctx),
					ptrTrustMe(mangledNames),
					ptrTrustMe(gccTypes),
					ptrTrustMe(globalsForConstants),
					ptrTrustMe(gccVars),
					gccFuns,
					curFun,
					fun.returnType,
					fun.params,
					entryBlock,
					entryBlock,
					nat64Type,
					abortFunction,
					conversionFunctions,
					builtinPopcountlFunction,
					globalVoid);

				if (isStubFunction(funIndex)) {
					debugLogWithWriter((ref Writer writer) {
						import interpret.debugging : writeFunName, writeFunSig;
						writer ~= "Stub ";
						writer ~= funIndex.index;
						writeFunName(writer, allSymbols, todo!Program("!"), program, funIndex);
						writer ~= ' ';
						writeFunSig(writer, allSymbols, todo!Program("!"), program, fun);
					});
					gcc_jit_block_end_with_return(exprCtx.curBlock, null, arbitraryValue(exprCtx, expr.expr.type));
				} else {
					ExprEmit emit = ExprEmit(ExprEmit.Return());
					ExprResult result = withStackMap!(ExprResult, LowLocal*, gcc_jit_lvalue*)((ref Locals locals) =>
						toGccExpr(exprCtx, locals, emit, expr.expr));
					result.match!void(
						(ExprResult.BreakContinueOrReturn) {},
						(ref gcc_jit_rvalue) => unreachable!void,
						(ExprResult.Void) {});
				}

				scope immutable char* err = gcc_jit_context_get_first_error(ctx);
				if (err != null)
					debugLogWithWriter((ref Writer writer) @trusted {
						writer ~= "Error: ";
						writer ~= SafeCStr(err);
					});
				verify(err == null);
			});
	});
}

//TODO:KILL
bool isStubFunction(LowFunIndex _) =>
	false;

immutable struct ConversionFunctions {
	gcc_jit_function* ptrToNat64;
	gcc_jit_function* nat64ToPtr;
}

@trusted ConversionFunctions generateConversionFunctions(ref gcc_jit_context ctx) {
	immutable gcc_jit_type* voidPtrType = gcc_jit_context_get_type(ctx, gcc_jit_types.GCC_JIT_TYPE_VOID_PTR);
	immutable gcc_jit_type* nat64Type = gcc_jit_context_get_type(ctx, gcc_jit_types.GCC_JIT_TYPE_UNSIGNED_LONG);
	immutable gcc_jit_field* ptrField = gcc_jit_context_new_field(ctx, null, voidPtrType, "ptr");
	immutable gcc_jit_field* nat64Field = gcc_jit_context_new_field(ctx, null, nat64Type, "nat64");
	immutable gcc_jit_field*[2] fields = [ptrField, nat64Field];
	immutable gcc_jit_type* unionType =
		gcc_jit_context_new_union_type(ctx, null, "__ptrToNat64Converter", 2, fields.ptr);
	return ConversionFunctions(
		makeConversionFunction(ctx, "__ptrToNat64", unionType, voidPtrType, ptrField, nat64Type, nat64Field),
		makeConversionFunction(ctx, "__nat64ToPtr", unionType, nat64Type, nat64Field, voidPtrType, ptrField));
}

@trusted immutable(gcc_jit_function*) makeConversionFunction(
	ref gcc_jit_context ctx,
	CStr name,
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
	in LowProgram program,
	in GccTypes types,
	in MangledNames mangledNames,
) {
	immutable gcc_jit_rvalue*[][] arrGlobals = map!(immutable gcc_jit_rvalue*[], ArrTypeAndConstantsLow)(
		alloc, program.allConstants.arrs, (ref ArrTypeAndConstantsLow tc) {
			immutable gcc_jit_type* gccElementType = getGccType(types, tc.elementType);
			return mapWithIndex!(immutable gcc_jit_rvalue*, immutable Constant[])(
				alloc,
				tc.constants,
				(size_t index, ref immutable Constant[] values) {
					immutable gcc_jit_type* arrayType = gcc_jit_context_new_array_type(
						ctx,
						null,
						gccElementType,
						cast(int) values.length);
					//TODO:NO ALLOC
					Writer writer = Writer(ptrTrustMe(alloc));
					writeConstantArrStorageName(writer, mangledNames, program, tc.arrType, index);
					CStr name = finishWriterToCStr(writer);
					return gcc_jit_lvalue_as_rvalue(gcc_jit_context_new_global(
						ctx,
						null,
						gcc_jit_global_kind.GCC_JIT_GLOBAL_INTERNAL,
						arrayType,
						name));
				});
		});

	gcc_jit_lvalue*[][] ptrGlobals = mapToMut!(gcc_jit_lvalue*[], PointerTypeAndConstantsLow)(
		alloc, program.allConstants.pointers, (in PointerTypeAndConstantsLow tc) {
			immutable gcc_jit_type* gccPointeeType = getGccType(types, tc.pointeeType);
			return mapWithIndex!(gcc_jit_lvalue*, Constant)(
				alloc,
				tc.constants,
				(size_t index, scope ref Constant) {
					//TODO:NO ALLOC
					Writer writer = Writer(ptrTrustMe(alloc));
					writeConstantPointerStorageName(writer, mangledNames, program, tc.pointeeType, index);
					CStr name = finishWriterToCStr(writer);
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

alias GccVars = FullIndexMap!(LowVarIndex, gcc_jit_lvalue*);

GccVars generateGccVars(
	ref Alloc alloc,
	ref gcc_jit_context ctx,
	in LowProgram program,
	in GccTypes types,
	in MangledNames mangledNames,
) =>
	mapFullIndexMap_mut!(LowVarIndex, gcc_jit_lvalue*, LowVar)(
		alloc, program.vars, (LowVarIndex varIndex, in LowVar var) {
			immutable gcc_jit_type* type = getGccType(types, var.type);
			//TODO:NO ALLOC
			Writer writer = Writer(ptrTrustMe(alloc));
			writeLowVarMangledName(writer, mangledNames, varIndex, var);
			CStr name = finishWriterToCStr(writer);
			gcc_jit_lvalue* res = gcc_jit_context_new_global(
				ctx, null,
				var.isExtern
					? gcc_jit_global_kind.GCC_JIT_GLOBAL_IMPORTED
					: gcc_jit_global_kind.GCC_JIT_GLOBAL_INTERNAL,
				type, name);
			final switch (var.kind) {
				case LowVar.Kind.externGlobal:
				case LowVar.Kind.global:
					break;
				case LowVar.Kind.threadLocal:
					gcc_jit_lvalue_set_tls_model(res, gcc_jit_tls_model.GCC_JIT_TLS_MODEL_LOCAL_DYNAMIC);	
					break;
			}
			return castNonScope(res);
		});

@trusted gcc_jit_function* toGccFunctionSignature(
	ref Alloc alloc,
	ref gcc_jit_context ctx,
	in LowProgram program,
	in MangledNames mangledNames,
	in GccTypes gccTypes,
	LowFunIndex funIndex,
	in LowFun fun,
) {
	gcc_jit_function_kind kind = fun.body_.matchIn!gcc_jit_function_kind(
		(in LowFunBody.Extern x) =>
			gcc_jit_function_kind.GCC_JIT_FUNCTION_IMPORTED,
		(in LowFunExprBody _) =>
			// TODO: A GCC bug breaks functions that return more than 16 bytes.
			funIndex == program.main || typeSizeBytes(program, fun.returnType) > 16
				? gcc_jit_function_kind.GCC_JIT_FUNCTION_EXPORTED
				: gcc_jit_function_kind.GCC_JIT_FUNCTION_INTERNAL);

	immutable gcc_jit_type* returnType = getGccType(gccTypes, fun.returnType);
	//TODO:NO ALLOC
	immutable gcc_jit_param*[] params = map(alloc, fun.params, (ref LowLocal param) {
		//TODO:NO ALLOC
		Writer writer = Writer(ptrTrustMe(alloc));
		writeLowLocalName(writer, mangledNames, param);
		return gcc_jit_context_new_param(ctx, null, getGccType(gccTypes, param.type), finishWriterToCStr(writer));
	});
	//TODO:NO ALLOC
	Writer writer = Writer(ptrTrustMe(alloc));
	writeLowFunMangledName(writer, mangledNames, funIndex, fun);
	CStr name = finishWriterToCStr(writer);
	return gcc_jit_context_new_function(ctx, null, kind, returnType, name, cast(int) params.length, params.ptr, false);
}

struct ExprEmit {
	struct Loop {
		gcc_jit_block* loopBlock;
		MutOpt!(gcc_jit_block*) endBlock;
		ExprEmit breakEmit;
	}
	// Return from the block. Return none.
	immutable struct Return {}
	// Return some.
	immutable struct Value {}
	/**
	Don't return anything. (Don't even return_void).
	This is used for `LowExprKind.SpecialUnary.Kind.drop` even if the expression type is not void.
	**/
	immutable struct Void {}
	// Write to this local. Return none.
	struct WriteTo {
		gcc_jit_lvalue* lvalue;
	}

	mixin UnionMutable!(Loop*, Return, Value, Void, WriteTo);
}
static assert(ExprEmit.sizeof == ulong.sizeof * 2);

bool isLoopOrReturn(in ExprEmit a) =>
	a.isA!(ExprEmit.Loop*) || a.isA!(ExprEmit.Return);

immutable struct ExprResult {
	@safe @nogc pure nothrow:

	// Did some kind of jump
	immutable struct BreakContinueOrReturn {}
	// Did not change control flow
	immutable struct Void {}

	mixin Union!(BreakContinueOrReturn, gcc_jit_rvalue*, Void);

	bool opEquals(in ExprResult b) scope =>
		matchWithPointers!bool(
			(BreakContinueOrReturn _) =>
				b.isA!(ExprResult.BreakContinueOrReturn),
			(gcc_jit_rvalue* x) =>
				b.isA!(gcc_jit_rvalue*) && b.as!(gcc_jit_rvalue*) == x,
			(ExprResult.Void) =>
				b.isA!(ExprResult.Void));
}

ExprResult emitSimpleNoSideEffects(ref ExprCtx ctx, ref ExprEmit emit, gcc_jit_rvalue* value) {
	verify(value != null);
	return emit.match!ExprResult(
		(ExprEmit.Loop*) =>
			unreachable!ExprResult,
		(ExprEmit.Return) {
			gcc_jit_block_end_with_return(ctx.curBlock, null, value);
			return ExprResult(ExprResult.BreakContinueOrReturn());
		},
		(ExprEmit.Value) =>
			ExprResult(value),
		(ExprEmit.Void) {
			gcc_jit_block_add_eval(ctx.curBlock, null, value);
			return ExprResult(ExprResult.Void());
		},
		(ref ExprEmit.WriteTo it) {
			gcc_jit_block_add_assignment(ctx.curBlock, null, it.lvalue, value);
			return ExprResult(ExprResult.Void());
		});
}

// We need to ensure side effects happen in order since GCC seems to evaluate call arguments in reverse.
ExprResult emitSimpleYesSideEffects(ref ExprCtx ctx, ref ExprEmit emit, in LowType type, gcc_jit_rvalue* value) =>
	emit.isA!(ExprEmit.Value)
		? ExprResult(getRValueUsingLocal(ctx, type, (gcc_jit_lvalue* local) {
			gcc_jit_block_add_assignment(ctx.curBlock, null, local, value);
		}))
		: emitSimpleNoSideEffects(ctx, emit, value);

gcc_jit_rvalue* getRValueUsingLocal(
	ref ExprCtx ctx,
	in LowType type,
	in void delegate(gcc_jit_lvalue*) @safe @nogc pure nothrow cb,
) {
	gcc_jit_lvalue* local = gcc_jit_function_new_local(ctx.curFun, null, getGccType(ctx.types, type), "temp");
	cb(local);
	return gcc_jit_lvalue_as_rvalue(local);
}

ExprResult emitWriteToLValue(
	ref ExprCtx ctx,
	ref ExprEmit emit,
	in LowType type,
	in void delegate(gcc_jit_lvalue*) @safe @nogc pure nothrow cb,
) =>
	emit.match!ExprResult(
		(ExprEmit.Loop*) =>
			unreachable!ExprResult,
		(ExprEmit.Return) {
			gcc_jit_rvalue* rvalue = getRValueUsingLocal(ctx, type, cb);
			gcc_jit_block_end_with_return(ctx.curBlock, null, rvalue);
			return ExprResult(ExprResult.BreakContinueOrReturn());
		},
		(ExprEmit.Value) =>
			ExprResult(getRValueUsingLocal(ctx, type, cb)),
		(ExprEmit.Void) {
			// This can happen for a LowExprKind.SpecialUnary.Kind.drop 
			getRValueUsingLocal(ctx, type, cb);
			return ExprResult(ExprResult.Void());
		},
		(ref ExprEmit.WriteTo it) {
			cb(it.lvalue);
			return ExprResult(ExprResult.Void());
		});

ExprResult emitVoid(ref ExprCtx ctx, ref ExprEmit emit) =>
	emit.match!ExprResult(
		(ExprEmit.Loop*) =>
			unreachable!ExprResult,
		(ExprEmit.Return) {
			//TODO: this should be unnecessary, use local void
			gcc_jit_block_end_with_return(ctx.curBlock, null, ctx.globalVoid);
			return ExprResult(ExprResult.BreakContinueOrReturn());
		},
		(ExprEmit.Value) =>
			ExprResult(ctx.globalVoid),
		(ExprEmit.Void) =>
			ExprResult(ExprResult.Void()),
		(ref ExprEmit.WriteTo it) {
			gcc_jit_block_add_assignment(ctx.curBlock, null, it.lvalue, ctx.globalVoid);
			return ExprResult(ExprResult.Void());
		});

ExprResult emitWithBranching(
	ref ExprCtx ctx,
	ref ExprEmit emit,
	in LowType type,
	in CStr endBlockName,
	in void delegate(
		gcc_jit_block* originalBlock,
		MutOpt!(gcc_jit_block*) endBlock,
		MutOpt!(gcc_jit_lvalue*) local,
		ExprResult expectedResult,
	) @safe @nogc pure nothrow cb,
) {
	MutOpt!(gcc_jit_block*) endBlock = isLoopOrReturn(emit)
		? noneMut!(gcc_jit_block*)
		: someMut(gcc_jit_function_new_block(ctx.curFun, endBlockName));
	MutOpt!(gcc_jit_lvalue*) local = emit.isA!(ExprEmit.Value)
		? someMut(gcc_jit_function_new_local(ctx.curFun, null, getGccType(ctx.types, type), "temp"))
		: noneMut!(gcc_jit_lvalue*);
	gcc_jit_block* originalBlock = ctx.curBlock;

	ExprResult expectedResult = emit.matchConst!ExprResult(
		(const ExprEmit.Loop*) =>
			ExprResult(ExprResult.BreakContinueOrReturn()),
		(ExprEmit.Return) =>
			ExprResult(ExprResult.BreakContinueOrReturn()),
		(ExprEmit.Value) {
			verify(has(local));
			return ExprResult(ExprResult.Void());
		},
		(ExprEmit.Void) =>
			ExprResult(ExprResult.Void()),
		(const ExprEmit.WriteTo) =>
			ExprResult(ExprResult.Void()));

	cb(originalBlock, endBlock, local, expectedResult);

	// If no endBlock, curBlock doesn't matter because nothing else will be done.
	ctx.curBlock = has(endBlock) ? force(endBlock) : originalBlock;
	if (has(local)) {
		verify(expectedResult.isA!(ExprResult.Void));
		return ExprResult(gcc_jit_lvalue_as_rvalue(force(local)));
	} else
		return expectedResult;
}

ExprResult emitSwitch(
	ref ExprCtx ctx,
	ref ExprEmit emit,
	in LowType type,
	gcc_jit_rvalue* switchedValue,
	size_t nCases,
	in ExprResult delegate(ref ExprEmit, size_t) @safe @nogc pure nothrow cbCase,
) =>
	emitWithBranching(
		ctx, emit, type, "switchEnd",
		(
			gcc_jit_block* originalBlock,
			MutOpt!(gcc_jit_block*) endBlock,
			MutOpt!(gcc_jit_lvalue*) local,
			ExprResult expectedResult,
		) {
			gcc_jit_block* defaultBlock = gcc_jit_function_new_block(ctx.curFun, "switchDefault");
			gcc_jit_block_add_eval(
				defaultBlock,
				null,
				castImmutable(gcc_jit_context_new_call(ctx.gcc, null, ctx.abortFunction, 0, null)));
			// Gcc requires that every block have an end.
			if (has(endBlock) && !expectedResult.isA!(ExprResult.BreakContinueOrReturn))
				gcc_jit_block_end_with_jump(defaultBlock, null, force(endBlock));
			else
				gcc_jit_block_end_with_return(defaultBlock, null, arbitraryValue(ctx, ctx.curFunReturnType));

			immutable gcc_jit_case*[] cases = makeArr!(immutable gcc_jit_case*)(
				ctx.alloc,
				nCases,
				(size_t i) {
					gcc_jit_block* caseBlock = gcc_jit_function_new_block(ctx.curFun, "switchCase");
					ctx.curBlock = caseBlock;
					ExprResult result = () {
						if (has(local)) {
							emitToLValueCb(force(local), (ref ExprEmit emitLocal) =>
								cbCase(emitLocal, i));
							return ExprResult(ExprResult.Void());
						} else
							return cbCase(emit, i);
					}();
					verify(result == expectedResult);
					if (has(endBlock) && !result.isA!(ExprResult.BreakContinueOrReturn)) {
						// A nested branch may have changed to a new block, so use that instead of 'caseBlock'
						gcc_jit_block_end_with_jump(ctx.curBlock, null, force(endBlock));
					}
					gcc_jit_rvalue* caseValue =
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
				&cases[0]);
		});

alias Locals = StackMap!(LowLocal*, gcc_jit_lvalue*);
alias addLocal = stackMapAdd!(LowLocal*, gcc_jit_lvalue*);
gcc_jit_lvalue* getLocal(ref ExprCtx ctx, ref Locals locals, in LowLocal* local) {
	Opt!size_t paramIndex = indexOfPointer(ctx.curFunParams, local);
	return has(paramIndex)
		? gcc_jit_param_as_lvalue(gcc_jit_function_get_param(ctx.curFun, safeToInt(force(paramIndex))))
		: stackMapMustGet!(LowLocal*, gcc_jit_lvalue*)(locals, local);
}

struct ExprCtx {
	@safe @nogc pure nothrow:

	Alloc* allocPtr;
	const AllSymbols* allSymbolsPtr;
	immutable LowProgram* programPtr;
	gcc_jit_context* gccPtr;
	const MangledNames* mangledNamesPtr;
	immutable GccTypes* typesPtr;
	GlobalsForConstants* globalsForConstantsPtr;
	GccVars* gccVarsPtr;
	FullIndexMap!(LowFunIndex, gcc_jit_function*) gccFuns;
	gcc_jit_function* curFun;
	LowType curFunReturnType;
	LowLocal[] curFunParams;
	gcc_jit_block* entryBlock;
	gcc_jit_block* curBlock;
	immutable gcc_jit_type* nat64Type;
	immutable gcc_jit_function* abortFunction;
	ConversionFunctions conversionFunctions;
	immutable gcc_jit_function* builtinPopcountlFunction;
	immutable gcc_jit_rvalue* globalVoid;

	ref Alloc alloc() return scope =>
		*allocPtr;

	ref LowProgram program() const return scope =>
		*programPtr;

	ref MangledNames mangledNames() const return scope =>
		*mangledNamesPtr;

	ref GccTypes types() const return scope =>
		*typesPtr;

	ref GlobalsForConstants globalsForConstants() return scope =>
		*globalsForConstantsPtr;

	ref GccVars gccVars() return scope =>
		*gccVarsPtr;

	ref gcc_jit_context gcc() return scope =>
		*gccPtr;
}

ExprResult toGccExpr(ref ExprCtx ctx, ref Locals locals, ref ExprEmit emit, in LowExpr a) =>
	a.kind.matchIn!ExprResult(
		(in LowExprKind.Call it) =>
			callToGcc(ctx, locals, emit, a.type, it),
		(in LowExprKind.CallFunPtr it) =>
			callFunPtrToGcc(ctx, locals, emit, a, it),
		(in LowExprKind.CreateRecord it) =>
			createRecordToGcc(ctx, locals, emit, a, it),
		(in LowExprKind.CreateUnion it) =>
			createUnionToGcc(ctx, locals, emit, a, it),
		(in LowExprKind.If it) =>
			ifToGcc(ctx, locals, emit, a.type, it.cond, it.then, it.else_),
		(in LowExprKind.InitConstants) =>
			initConstantsToGcc(ctx, emit),
		(in LowExprKind.Let it) =>
			letToGcc(ctx, locals, emit, it),
		(in LowExprKind.LocalGet it) =>
			localGetToGcc(ctx, locals, emit, it),
		(in LowExprKind.LocalSet it) =>
			localSetToGcc(ctx, locals, emit, it),
		(in LowExprKind.Loop it) =>
			loopToGcc(ctx, locals, emit, a.type, it),
		(in LowExprKind.LoopBreak it) =>
			loopBreakToGcc(ctx, locals, emit, it),
		(in LowExprKind.LoopContinue) =>
			loopContinueToGcc(ctx, locals, emit),
		(in LowExprKind.MatchUnion it) =>
			matchUnionToGcc(ctx, locals, emit, a, it),
		(in LowExprKind.PtrCast it) =>
			ptrCastToGcc(ctx, locals, emit, a, it),
		(in LowExprKind.PtrToField it) =>
			ptrToFieldToGcc(ctx, locals, emit, a, it),
		(in LowExprKind.PtrToLocal it) =>
			ptrToLocalToGcc(ctx, locals, emit, it),
		(in LowExprKind.RecordFieldGet it) =>
			recordFieldGetToGcc(ctx, locals, emit, it),
		(in LowExprKind.RecordFieldSet it) =>
			recordFieldSetToGcc(ctx, locals, emit, it),
		(in LowExprKind.SizeOf it) =>
			sizeOfToGcc(ctx, emit, it),
		(in Constant it) =>
			constantToGcc(ctx, emit, a.type, it),
		(in LowExprKind.SpecialUnary it) =>
			unaryToGcc(ctx, locals, emit, a.type, it),
		(in LowExprKind.SpecialBinary it) =>
			binaryToGcc(ctx, locals, emit, a.type, it),
		(in LowExprKind.SpecialTernary) =>
			unreachable!ExprResult,
		(in LowExprKind.Switch0ToN it) =>
			switch0ToNToGcc(ctx, locals, emit, a.type, it),
		(in LowExprKind.SwitchWithValues) =>
			todo!ExprResult("!"),
		(in LowExprKind.TailRecur it) =>
			tailRecurToGcc(ctx, locals, emit, it),
		(in LowExprKind.VarGet x) =>
			varGetToGcc(ctx, locals, emit, x),
		(in LowExprKind.VarSet x) =>
			varSetToGcc(ctx, locals, emit, x));

gcc_jit_rvalue* emitToRValueCb(
	in ExprResult delegate(ref ExprEmit) @safe @nogc pure nothrow cbEmit,
) {
	ExprEmit emit = ExprEmit(ExprEmit.Value());
	return cbEmit(emit).as!(gcc_jit_rvalue*);
}

immutable(gcc_jit_rvalue*) emitToRValue(ref ExprCtx ctx, ref Locals locals, in LowExpr a) =>
	emitToRValueCb((ref ExprEmit emit) =>
		toGccExpr(ctx, locals, emit, a));

void emitToLValueCb(
	gcc_jit_lvalue* lvalue,
	in ExprResult delegate(ref ExprEmit) @safe @nogc pure nothrow cbEmit,
) {
	ExprEmit emit = ExprEmit(ExprEmit.WriteTo(lvalue));
	ExprResult result = cbEmit(emit);
	verify(result.isA!(ExprResult.Void));
}

void emitToLValue(ref ExprCtx ctx, ref Locals locals, gcc_jit_lvalue* lvalue, in LowExpr a) {
	emitToLValueCb(lvalue, (ref ExprEmit emitArg) @safe =>
		toGccExpr(ctx, locals, emitArg, a));
}

void emitToVoid(ref ExprCtx ctx, ref Locals locals, in LowExpr a) {
	ExprEmit emitVoid = ExprEmit(ExprEmit.Void());
	ExprResult result = toGccExpr(ctx, locals, emitVoid, a);
	verify(result.isA!(ExprResult.Void));
}

@trusted ExprResult callToGcc(
	ref ExprCtx ctx,
	ref Locals locals,
	ref ExprEmit emit,
	in LowType type,
	in LowExprKind.Call a,
) {
	const gcc_jit_function* called = ctx.gccFuns[a.called];
	//TODO:NO ALLOC
	immutable gcc_jit_rvalue*[] argsGcc =
		map(ctx.alloc, a.args, (ref LowExpr arg) => emitToRValue(ctx, locals, arg));
	return emitSimpleYesSideEffects(ctx, emit, type, castImmutable(
		gcc_jit_context_new_call(ctx.gcc, null, called, cast(int) argsGcc.length, argsGcc.ptr)));
}

@trusted ExprResult callFunPtrToGcc(
	ref ExprCtx ctx,
	ref Locals locals,
	ref ExprEmit emit,
	in LowExpr expr,
	in LowExprKind.CallFunPtr a,
) {
	gcc_jit_rvalue* funPtrGcc = emitToRValue(ctx, locals, a.funPtr);
	//TODO:NO ALLOC
	immutable gcc_jit_rvalue*[] argsGcc =
		map(ctx.alloc, a.args, (ref LowExpr arg) => emitToRValue(ctx, locals, arg));
	return emitSimpleYesSideEffects(ctx, emit, expr.type, gcc_jit_context_new_call_through_ptr(
		ctx.gcc,
		null,
		funPtrGcc,
		cast(int) argsGcc.length,
		argsGcc.ptr));
}

@trusted ExprResult tailRecurToGcc(
	ref ExprCtx ctx,
	ref Locals locals,
	ref ExprEmit emit,
	in LowExprKind.TailRecur a,
) {
	verify(emit.isA!(ExprEmit.Return));

	// We need to be sure to generate all the new parameter values before overwriting any,
	gcc_jit_lvalue*[] updateParamLocals =
		mapToMut!(gcc_jit_lvalue*, UpdateParam)(ctx.alloc, a.updateParams, (in UpdateParam updateParam) {
			gcc_jit_lvalue* local =
				gcc_jit_function_new_local(ctx.curFun, null, getGccType(ctx.types, updateParam.newValue.type), "temp");
			emitToLValue(ctx, locals, castNonScope(local), updateParam.newValue);
			return castNonScope(local);
		});
	zip!(gcc_jit_lvalue*, UpdateParam)(
		updateParamLocals,
		a.updateParams,
		(ref gcc_jit_lvalue* local, ref UpdateParam updateParam) {
			gcc_jit_block_add_assignment(
				ctx.curBlock,
				null,
				getLocal(ctx, locals, updateParam.param),
				gcc_jit_lvalue_as_rvalue(local));
		});
	gcc_jit_block_end_with_jump(ctx.curBlock, null, ctx.entryBlock);
	return ExprResult(ExprResult.BreakContinueOrReturn());
}

ExprResult varGetToGcc(ref ExprCtx ctx, ref Locals locals, ref ExprEmit emit, in LowExprKind.VarGet a) {
	return emitSimpleNoSideEffects(ctx, emit, gcc_jit_lvalue_as_rvalue(ctx.gccVars[a.varIndex]));
}
ExprResult varSetToGcc(ref ExprCtx ctx, ref Locals locals, ref ExprEmit emit, in LowExprKind.VarSet a) {
	emitToLValue(ctx, locals, ctx.gccVars[a.varIndex], *a.value);
	return emitVoid(ctx, emit);
}

ExprResult emitRecordCb(
	ref ExprCtx ctx,
	ref ExprEmit emit,
	in LowType type,
	in ExprResult delegate(size_t, ref ExprEmit) @safe @nogc pure nothrow cbEmitArg,
) =>
	emitWriteToLValue(ctx, emit, type, (gcc_jit_lvalue* lvalue) {
		immutable gcc_jit_field*[] fields = ctx.types.recordFields[type.as!(LowType.Record)];
		foreach (size_t i, immutable gcc_jit_field* field; fields) {
			gcc_jit_rvalue* value = emitToRValueCb((ref ExprEmit emitArg) =>
				cbEmitArg(i, emitArg));
			gcc_jit_block_add_assignment(ctx.curBlock, null, gcc_jit_lvalue_access_field(lvalue, null, field), value);
		}
	});

ExprResult emitRecordCbWithArgs(T)(
	ref ExprCtx ctx,
	ref ExprEmit emit,
	in LowType type,
	in T[] args,
	in ExprResult delegate(size_t, ref ExprEmit, in T) @safe @nogc pure nothrow cbEmitArg,
) =>
	emitRecordCb(ctx, emit, type, (size_t argIndex, ref ExprEmit emitArg) =>
		cbEmitArg(argIndex, emitArg, args[argIndex]));

ExprResult createRecordToGcc(
	ref ExprCtx ctx,
	ref Locals locals,
	ref ExprEmit emit,
	in LowExpr expr,
	in LowExprKind.CreateRecord a,
) =>
	emitRecordCbWithArgs!LowExpr(ctx, emit, expr.type, a.args, (size_t _, ref ExprEmit emitArg, in LowExpr arg) =>
		toGccExpr(ctx, locals, emitArg, arg));

ExprResult emitUnion(
	ref ExprCtx ctx,
	ref ExprEmit emit,
	in LowType type,
	size_t memberIndex,
	in ExprResult delegate(ref ExprEmit) @safe @nogc pure nothrow cbEmitArg,
) =>
	emitWriteToLValue(ctx, emit, type, (gcc_jit_lvalue* lvalue) {
		UnionFields unionFields = ctx.types.unionFields[type.as!(LowType.Union)];
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

ExprResult createUnionToGcc(
	ref ExprCtx ctx,
	ref Locals locals,
	ref ExprEmit emit,
	in LowExpr expr,
	in LowExprKind.CreateUnion a,
) =>
	emitUnion(ctx, emit, expr.type, a.memberIndex, (ref ExprEmit emitArg) =>
		toGccExpr(ctx, locals, emitArg, a.arg));

ExprResult letToGcc(ref ExprCtx ctx, ref Locals locals, ref ExprEmit emit, in LowExprKind.Let a) =>
	emitWithLocal(ctx, locals, emit, a.local, a.then, (ref ExprEmit valueEmit) =>
		toGccExpr(ctx, locals, valueEmit, a.value));

ExprResult emitWithLocal(
	ref ExprCtx ctx,
	ref Locals locals,
	ref ExprEmit emit,
	in LowLocal* lowLocal,
	in LowExpr then,
	in ExprResult delegate(ref ExprEmit) @safe @nogc pure nothrow cbValue,
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
	return toGccExpr(ctx, castNonScope_ref(newLocals), emit, then);
}

ExprResult localGetToGcc(ref ExprCtx ctx, ref Locals locals, ref ExprEmit emit, in LowExprKind.LocalGet a) =>
	emitSimpleNoSideEffects(ctx, emit, gcc_jit_lvalue_as_rvalue(getLocal(ctx, locals, a.local)));

ExprResult localSetToGcc(ref ExprCtx ctx, ref Locals locals, ref ExprEmit emit, in LowExprKind.LocalSet a) {
	emitToLValue(ctx, locals, getLocal(ctx, locals, a.local), a.value);
	return emitVoid(ctx, emit);
}

ExprResult loopToGcc(ref ExprCtx ctx, ref Locals locals, ref ExprEmit emit, in LowType type, in LowExprKind.Loop a) =>
	emitWithBranching(
		ctx, emit, type, "loopEnd",
		(
			gcc_jit_block* originalBlock,
			MutOpt!(gcc_jit_block*) endBlock,
			MutOpt!(gcc_jit_lvalue*) local,
			ExprResult _,
		) {
			gcc_jit_block* loopBlock = gcc_jit_function_new_block(ctx.curFun, "loop");
			gcc_jit_block_end_with_jump(originalBlock, null, loopBlock);
			ctx.curBlock = loopBlock;
			ExprEmit.Loop info = ExprEmit.Loop(
				loopBlock,
				endBlock, // TODO:UNUSED
				has(local) ? ExprEmit(ExprEmit.WriteTo(force(local))) : emit);
			ExprEmit innerEmit = ExprEmit(ptrTrustMe(info));
			ExprResult innerResult = toGccExpr(ctx, locals, innerEmit, a.body_);
			verify(innerResult.isA!(ExprResult.BreakContinueOrReturn));
		});

ExprResult loopBreakToGcc(ref ExprCtx ctx, ref Locals locals, ref ExprEmit emit, in LowExprKind.LoopBreak a) {
	ExprEmit.Loop loop = *emit.as!(ExprEmit.Loop*);
	// Give 'breakEmit' to the inner expr, so it does whatever is needed by the loop
	ExprResult result = toGccExpr(ctx, locals, loop.breakEmit, a.value);
	result.match!void(
		(ExprResult.BreakContinueOrReturn) {},
		(ref gcc_jit_rvalue) { unreachable!void(); },
		(ExprResult.Void) {
			gcc_jit_block_end_with_jump(ctx.curBlock, null, force(loop.endBlock));
		});
	return ExprResult(ExprResult.BreakContinueOrReturn());
}

ExprResult loopContinueToGcc(ref ExprCtx ctx, ref Locals locals, ref ExprEmit emit) {
	gcc_jit_block_end_with_jump(ctx.curBlock, null, emit.as!(ExprEmit.Loop*).loopBlock);
	return ExprResult(ExprResult.BreakContinueOrReturn());
}

ExprResult matchUnionToGcc(
	ref ExprCtx ctx,
	ref Locals locals,
	ref ExprEmit emit,
	in LowExpr expr,
	in LowExprKind.MatchUnion a,
) {
	// We need to create a local for the matchedValue.
	gcc_jit_lvalue* matchedLocal = gcc_jit_function_new_local(
		ctx.curFun,
		null,
		getGccType(ctx.types, a.matchedValue.type),
		"matched");
	emitToLValue(ctx, locals, matchedLocal, a.matchedValue);

	UnionFields unionFields = ctx.types.unionFields[a.matchedValue.type.as!(LowType.Union)];

	gcc_jit_rvalue* matchedValueKind = gcc_jit_rvalue_access_field(
		gcc_jit_lvalue_as_rvalue(matchedLocal),
		null,
		unionFields.kindField);

	return emitSwitch(
		ctx,
		emit,
		expr.type,
		matchedValueKind,
		a.cases.length,
		(ref ExprEmit caseEmit, size_t caseIndex) {
			LowExprKind.MatchUnion.Case case_ = a.cases[caseIndex];
			return has(case_.local)
				? emitWithLocal(ctx, locals, caseEmit, force(case_.local), case_.then, (ref ExprEmit valueEmit) {
					// The value is the nth value in the union..
					gcc_jit_rvalue* matchedValueInner = gcc_jit_rvalue_access_field(
						gcc_jit_lvalue_as_rvalue(matchedLocal),
						null,
						unionFields.innerField);
					return emitSimpleNoSideEffects(ctx, valueEmit, gcc_jit_rvalue_access_field(
						matchedValueInner,
						null,
						unionFields.memberFields[caseIndex]));
				})
			: toGccExpr(ctx, locals, caseEmit, case_.then);
		});
}

ExprResult ptrCastToGcc(
	ref ExprCtx ctx,
	ref Locals locals,
	ref ExprEmit emit,
	in LowExpr expr,
	in LowExprKind.PtrCast a,
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

ExprResult ptrToFieldToGcc(
	ref ExprCtx ctx,
	ref Locals locals,
	ref ExprEmit emit,
	in LowExpr expr,
	in LowExprKind.PtrToField a,
) {
	immutable gcc_jit_field* field = ctx.types.recordFields[targetRecordType(a)][a.fieldIndex];
	return emitSimpleYesSideEffects(
		ctx, emit, expr.type,
		gcc_jit_lvalue_get_address(
			gcc_jit_rvalue_dereference_field(emitToRValue(ctx, locals, a.target), null, field),
			null));
}

ExprResult ptrToLocalToGcc(ref ExprCtx ctx, ref Locals locals, ref ExprEmit emit, in LowExprKind.PtrToLocal a) =>
	emitSimpleNoSideEffects(ctx, emit, gcc_jit_lvalue_get_address(getLocal(ctx, locals, a.local), null));

ExprResult recordFieldGetToGcc(
	ref ExprCtx ctx,
	ref Locals locals,
	ref ExprEmit emit,
	in LowExprKind.RecordFieldGet a,
) {
	gcc_jit_rvalue* target = emitToRValue(ctx, locals, a.target);
	immutable gcc_jit_field* field = ctx.types.recordFields[targetRecordType(a)][a.fieldIndex];
	return emitSimpleNoSideEffects(ctx, emit, targetIsPointer(a)
		? gcc_jit_lvalue_as_rvalue(gcc_jit_rvalue_dereference_field(target, null, field))
		: gcc_jit_rvalue_access_field(target, null, field));
}

ExprResult recordFieldSetToGcc(
	ref ExprCtx ctx,
	ref Locals locals,
	ref ExprEmit emit,
	in LowExprKind.RecordFieldSet a,
) {
	gcc_jit_rvalue* target = emitToRValue(ctx, locals, a.target);
	immutable gcc_jit_field* field = ctx.types.recordFields[targetRecordType(a)][a.fieldIndex];
	verify(targetIsPointer(a)); // TODO: make if this is always true, don't have it...
	gcc_jit_rvalue* value = emitToRValue(ctx, locals, a.value);
	gcc_jit_block_add_assignment(ctx.curBlock, null, gcc_jit_rvalue_dereference_field(target, null, field), value);
	return emitVoid(ctx, emit);
}

ExprResult sizeOfToGcc(ref ExprCtx ctx, ref ExprEmit emit, in LowExprKind.SizeOf a) =>
	emitSimpleNoSideEffects(
		ctx,
		emit,
		gcc_jit_context_new_rvalue_from_long(ctx.gcc, ctx.nat64Type, typeSizeBytes(ctx.program, a.type)));

ExprResult constantToGcc(ref ExprCtx ctx, ref ExprEmit emit, in LowType type, in Constant a) =>
	a.matchIn!ExprResult(
		(in Constant.ArrConstant it) {
			size_t arrSize = ctx.program.allConstants.arrs[it.typeIndex].constants[it.index].length;
			gcc_jit_rvalue* storage = ctx.globalsForConstants.arrs[it.typeIndex][it.index];
			gcc_jit_rvalue* arrPtr = gcc_jit_lvalue_get_address(
				gcc_jit_context_new_array_access(ctx.gcc, null, storage, gcc_jit_context_zero(ctx.gcc, ctx.nat64Type)),
				null);
			immutable gcc_jit_field*[] fields = ctx.types.recordFields[type.as!(LowType.Record)];
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
		(in Constant.CString it) =>
			emitSimpleNoSideEffects(ctx, emit, gcc_jit_context_new_string_literal(
				ctx.gcc,
				ctx.program.allConstants.cStrings[it.index].ptr)),
		(in Constant.Float it) =>
			emitSimpleNoSideEffects(
				ctx,
				emit,
				gcc_jit_context_new_rvalue_from_double(ctx.gcc, getGccType(ctx.types, type), it.value)),
		(in Constant.FunPtr it) {
			gcc_jit_rvalue* value = gcc_jit_function_get_address(
				ctx.gccFuns[mustGetAt(ctx.program.concreteFunToLowFunIndex, it.fun)],
				null);
			gcc_jit_rvalue* castValue = () {
				if (type.isA!(LowType.PtrRawConst))
					// We need to cast function pointer to any-ptr for 'all-funs'
					return gcc_jit_context_new_cast(ctx.gcc, null, value, getGccType(ctx.types, type));
				else {
					verify(type.isA!(LowType.FunPtr));
					return value;
				}
			}();
			return emitSimpleNoSideEffects(ctx, emit, castValue);
		},
		(in Constant.Integral it) =>
			emitSimpleNoSideEffects(
				ctx,
				emit,
				gcc_jit_context_new_rvalue_from_long(ctx.gcc, getGccType(ctx.types, type), it.value)),
		(in Constant.Pointer it) {
			gcc_jit_lvalue* storage = ctx.globalsForConstants.pointers[it.typeIndex][it.index];
			return emitSimpleNoSideEffects(ctx, emit, gcc_jit_lvalue_get_address(storage, null));
		},
		(in Constant.Record it) {
			LowField[] fields = ctx.program.allRecords[type.as!(LowType.Record)].fields;
			return emitRecordCbWithArgs!Constant(
				ctx, emit, type, it.args,
				(size_t argIndex, ref ExprEmit emitArg, in Constant arg) =>
					constantToGcc(ctx, emitArg, fields[argIndex].type, arg));
		},
		(in Constant.Union it) {
			LowType argType = ctx.program.allUnions[type.as!(LowType.Union)].members[it.memberIndex];
			return emitUnion(ctx, emit, type, it.memberIndex, (ref ExprEmit emitArg) =>
				constantToGcc(ctx, emit, argType, it.arg));
		},
		(in Constant.Zero) =>
			zeroedToGcc(ctx, emit, type));

@trusted ExprResult unaryToGcc(
	ref ExprCtx ctx,
	ref Locals locals,
	ref ExprEmit emit,
	in LowType type,
	in LowExprKind.SpecialUnary a,
) {
	final switch (a.kind) {
		case LowExprKind.SpecialUnary.Kind.acosFloat64:
		case LowExprKind.SpecialUnary.Kind.acoshFloat64:
		case LowExprKind.SpecialUnary.Kind.asinFloat64:
		case LowExprKind.SpecialUnary.Kind.asinhFloat64:
		case LowExprKind.SpecialUnary.Kind.atanFloat64:
		case LowExprKind.SpecialUnary.Kind.atanhFloat64:
		case LowExprKind.SpecialUnary.Kind.cosFloat64:
		case LowExprKind.SpecialUnary.Kind.coshFloat64:
		case LowExprKind.SpecialUnary.Kind.sinFloat64:
		case LowExprKind.SpecialUnary.Kind.sinhFloat64:
		case LowExprKind.SpecialUnary.Kind.tanFloat64:
		case LowExprKind.SpecialUnary.Kind.tanhFloat64:
		case LowExprKind.SpecialUnary.Kind.roundFloat64:
		case LowExprKind.SpecialUnary.Kind.sqrtFloat64:
			return todo!ExprResult("!!!");
		case LowExprKind.SpecialUnary.Kind.bitwiseNotNat8:
		case LowExprKind.SpecialUnary.Kind.bitwiseNotNat16:
		case LowExprKind.SpecialUnary.Kind.bitwiseNotNat32:
		case LowExprKind.SpecialUnary.Kind.bitwiseNotNat64:
			return emitSimpleNoSideEffects(ctx, emit, gcc_jit_context_new_unary_op(
				ctx.gcc,
				null,
				gcc_jit_unary_op.GCC_JIT_UNARY_OP_BITWISE_NEGATE,
				getGccType(ctx.types, type),
				emitToRValue(ctx, locals, a.arg)));
		case LowExprKind.SpecialUnary.Kind.countOnesNat64:
			return countOnesToGcc(ctx, locals, emit, a.arg);
		case LowExprKind.SpecialUnary.Kind.deref:
			return emitSimpleNoSideEffects(ctx, emit, gcc_jit_lvalue_as_rvalue(
				gcc_jit_rvalue_dereference(emitToRValue(ctx, locals, a.arg), null)));
		case LowExprKind.SpecialUnary.Kind.drop:
			emitToVoid(ctx, locals, a.arg);
			return emitVoid(ctx, emit);
		case LowExprKind.SpecialUnary.Kind.asAnyPtr:
		case LowExprKind.SpecialUnary.Kind.enumToIntegral:
		case LowExprKind.SpecialUnary.Kind.toChar8FromNat8:
		case LowExprKind.SpecialUnary.Kind.toFloat32FromFloat64:
		case LowExprKind.SpecialUnary.Kind.toFloat64FromFloat32:
		case LowExprKind.SpecialUnary.Kind.toFloat64FromInt64:
		case LowExprKind.SpecialUnary.Kind.toFloat64FromNat64:
		case LowExprKind.SpecialUnary.Kind.toInt64FromInt8:
		case LowExprKind.SpecialUnary.Kind.toInt64FromInt16:
		case LowExprKind.SpecialUnary.Kind.toInt64FromInt32:
		case LowExprKind.SpecialUnary.Kind.toNat8FromChar8:
		case LowExprKind.SpecialUnary.Kind.toNat64FromNat8:
		case LowExprKind.SpecialUnary.Kind.toNat64FromNat16:
		case LowExprKind.SpecialUnary.Kind.toNat64FromNat32:
		case LowExprKind.SpecialUnary.Kind.truncateToInt64FromFloat64:
		case LowExprKind.SpecialUnary.Kind.unsafeToInt8FromInt64:
		case LowExprKind.SpecialUnary.Kind.unsafeToInt16FromInt64:
		case LowExprKind.SpecialUnary.Kind.unsafeToInt32FromInt64:
		case LowExprKind.SpecialUnary.Kind.unsafeToInt64FromNat64:
		case LowExprKind.SpecialUnary.Kind.unsafeToNat8FromNat64:
		case LowExprKind.SpecialUnary.Kind.unsafeToNat16FromNat64:
		case LowExprKind.SpecialUnary.Kind.unsafeToNat32FromInt32:
		case LowExprKind.SpecialUnary.Kind.unsafeToNat32FromNat64:
		case LowExprKind.SpecialUnary.Kind.unsafeToNat64FromInt64:
			return emitSimpleNoSideEffects(ctx, emit, gcc_jit_context_new_cast(
				ctx.gcc,
				null,
				emitToRValue(ctx, locals, a.arg),
				getGccType(ctx.types, type)));
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
				getGccType(ctx.types, type)));
	}
}

ExprResult countOnesToGcc(ref ExprCtx ctx, ref Locals locals, ref ExprEmit emit, in LowExpr arg) {
	immutable gcc_jit_rvalue* argGcc = emitToRValue(ctx, locals, arg);
	gcc_jit_rvalue* call = castImmutable(gcc_jit_context_new_call(
		ctx.gcc,
		null,
		ctx.builtinPopcountlFunction,
		1,
		&argGcc));
	return emitSimpleNoSideEffects(ctx, emit, gcc_jit_context_new_cast(ctx.gcc, null, call, ctx.nat64Type));
}

ExprResult binaryToGcc(
	ref ExprCtx ctx,
	ref Locals locals,
	ref ExprEmit emit,
	in LowType type,
	in LowExprKind.SpecialBinary a,
) {
	LowExpr left = a.args[0], right = a.args[1];
	ExprResult operator(gcc_jit_binary_op op) {
		return binaryOperator(ctx, locals, emit, type, op, left, right);
	}
	ExprResult comparison(gcc_jit_comparison cmp) {
		return emitSimpleNoSideEffects(ctx, emit, gcc_jit_context_new_comparison(
			ctx.gcc,
			null,
			cmp,
			emitToRValue(ctx, locals, left),
			emitToRValue(ctx, locals, right)));
	}

	final switch (a.kind) {
		case LowExprKind.SpecialBinary.Kind.atan2Float64:
			return todo!ExprResult("!!!");
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
			return ptrArithmeticToGcc(ctx, locals, emit, PtrArith.addNat, left, right);
		case LowExprKind.SpecialBinary.Kind.and:
			return logicalOperatorToGcc(ctx, locals, emit, LogicalOperator.and, left, right);
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
		case LowExprKind.SpecialBinary.Kind.lessChar8:
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
			return logicalOperatorToGcc(ctx, locals, emit, LogicalOperator.or, left, right);
		case LowExprKind.SpecialBinary.Kind.seq:
			emitToVoid(ctx, locals, left);
			return toGccExpr(ctx, locals, emit, right);
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
			return ptrArithmeticToGcc(ctx, locals, emit, PtrArith.subtractNat, left, right);
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
			gcc_jit_rvalue* gccLeft = emitToRValue(ctx, locals, left);
			gcc_jit_rvalue* gccRight = emitToRValue(ctx, locals, right);
			gcc_jit_block_add_assignment(ctx.curBlock, null, gcc_jit_rvalue_dereference(gccLeft, null), gccRight);
			return emitVoid(ctx, emit);
	}
}

ExprResult binaryOperator(
	ref ExprCtx ctx,
	ref Locals locals,
	ref ExprEmit emit,
	in LowType type,
	gcc_jit_binary_op op,
	in LowExpr left,
	in LowExpr right,
) =>
	operatorForLhsRhs(ctx, emit, type, op, emitToRValue(ctx, locals, left), emitToRValue(ctx, locals, right));

ExprResult operatorForLhsRhs(
	ref ExprCtx ctx,
	ref ExprEmit emit,
	in LowType type,
	gcc_jit_binary_op op,
	gcc_jit_rvalue* lhs,
	gcc_jit_rvalue* rhs,
) =>
	emitSimpleNoSideEffects(ctx, emit, gcc_jit_context_new_binary_op(
		ctx.gcc,
		null,
		op,
		getGccType(ctx.types, type),
		lhs,
		rhs));

enum LogicalOperator { and, or }

ExprResult logicalOperatorToGcc(
	ref ExprCtx ctx,
	ref Locals locals,
	ref ExprEmit emit,
	LogicalOperator operator,
	in LowExpr left,
	in LowExpr right,
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
		gcc_jit_binary_op op = () {
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

LowType boolType() =>
	LowType(PrimitiveType.bool_);

LowExpr boolExpr(bool value) =>
	LowExpr(boolType, FileAndRange.empty, LowExprKind(constantBool(value)));

enum PtrArith { addNat, subtractNat }

ExprResult ptrArithmeticToGcc(
	ref ExprCtx ctx,
	ref Locals locals,
	ref ExprEmit emit,
	PtrArith op,
	in LowExpr left,
	in LowExpr right,
) {
	// `ptr + nat` is `&ptr[nat]`
	// `ptr - nat` is `&ptr[-(int) nat]`
	gcc_jit_rvalue* rightRValue = emitToRValue(ctx, locals, right);
	gcc_jit_rvalue* rightWithSign = () {
		final switch (op) {
			case PtrArith.addNat:
				return rightRValue;
			case PtrArith.subtractNat:
				immutable gcc_jit_type* int64Type = getGccType(ctx.types, LowType(PrimitiveType.int64));
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

ExprResult ifToGcc(
	ref ExprCtx ctx,
	ref Locals locals,
	ref ExprEmit emit,
	in LowType type,
	in LowExpr cond,
	in LowExpr then,
	in LowExpr else_,
) {
	gcc_jit_rvalue* condValue = emitToRValue(ctx, locals, cond);
	return emitWithBranching(
		ctx, emit, type, "ifEnd",
		(
			gcc_jit_block* originalBlock,
			MutOpt!(gcc_jit_block*) endBlock,
			MutOpt!(gcc_jit_lvalue*) local,
			ExprResult expectedResult,
		) {
			gcc_jit_block* thenBlock = gcc_jit_function_new_block(ctx.curFun, "then");
			gcc_jit_block* elseBlock = gcc_jit_function_new_block(ctx.curFun, "else");
			gcc_jit_block_end_with_conditional(originalBlock, null, condValue, thenBlock, elseBlock);
			void branch(gcc_jit_block* block, in LowExpr blockExpr) {
				ctx.curBlock = block;
				ExprResult result = {
					if (has(local)) {
						emitToLValue(ctx, locals, force(local), blockExpr);
						return ExprResult(ExprResult.Void());
					}	else
						return toGccExpr(ctx, locals, emit, blockExpr);
				}();
				if (has(endBlock) && !result.isA!(ExprResult.BreakContinueOrReturn)) {
					// A nested if may have changed the block, so use 'curBlock' and not just 'block'
					gcc_jit_block_end_with_jump(ctx.curBlock, null, force(endBlock));
				}
				verify(result == expectedResult);
			}
			branch(thenBlock, then);
			branch(elseBlock, else_);
		});
}

ExprResult switch0ToNToGcc(
	ref ExprCtx ctx,
	ref Locals locals,
	ref ExprEmit emit,
	in LowType type,
	in LowExprKind.Switch0ToN a,
) =>
	emitSwitch(
		ctx, emit, type, emitToRValue(ctx, locals, a.value), a.cases.length,
		(ref ExprEmit caseEmit, size_t caseIndex) =>
			toGccExpr(ctx, locals, caseEmit, a.cases[caseIndex]));

ExprResult zeroedToGcc(ref ExprCtx ctx, ref ExprEmit emit, in LowType type) {
	immutable gcc_jit_type* gccType = getGccType(ctx.types, type);
	return type.combinePointer.matchIn!ExprResult(
		(in LowType.Extern x) =>
			externZeroedToGcc(ctx, emit, x),
		(in LowType.FunPtr) =>
			emitSimpleNoSideEffects(ctx, emit, gcc_jit_context_null(ctx.gcc, gccType)),
		(in PrimitiveType x) =>
			x == PrimitiveType.void_
				? emitVoid(ctx, emit)
				: emitSimpleNoSideEffects(ctx, emit, zeroForPrimitiveType(ctx, x)),
		(in LowPtrCombine _) =>
			emitSimpleNoSideEffects(ctx, emit, gcc_jit_context_null(ctx.gcc, gccType)),
		(in LowType.Record record) {
			LowField[] fields = ctx.program.allRecords[record].fields;
			return emitRecordCb(ctx, emit, type, (size_t argIndex, ref ExprEmit emitArg) =>
				zeroedToGcc(ctx, emitArg, fields[argIndex].type));
		},
		(in LowType.Union union_) =>
			emitUnion(ctx, emit, type, 0, (ref ExprEmit emitArg) =>
				zeroedToGcc(ctx, emitArg, ctx.program.allUnions[union_].members[0])));
}

ExprResult externZeroedToGcc(ref ExprCtx ctx, ref ExprEmit emit, LowType.Extern type) =>
	emitWriteToLValue(ctx, emit, LowType(type), (gcc_jit_lvalue* lvalue) {
		ExternTypeInfo info = ctx.types.extern_[type];
		if (has(info.array)) {
			ExternTypeArrayInfo array = force(info.array);
			gcc_jit_rvalue* elementValue = zeroForPrimitiveType(ctx, array.elementAndCount.elementType);
			//TODO: no alloc
			immutable gcc_jit_rvalue*[] elementValues = makeArr!(immutable gcc_jit_rvalue*)(
				ctx.alloc, array.elementAndCount.count, (ulong _) => elementValue);
			gcc_jit_rvalue* arrayValue = gcc_jit_context_new_array_constructor(
				ctx.gcc,
				null,
				array.gccArrayType,
				elementValues.length,
				&elementValues[0]);
			gcc_jit_block_add_assignment(
				ctx.curBlock,
				null,
				gcc_jit_lvalue_access_field(lvalue, null, array.field),
				arrayValue);
		}
	});

gcc_jit_rvalue* zeroForPrimitiveType(ref ExprCtx ctx, PrimitiveType a) {
	immutable gcc_jit_type* gccType = getGccType(ctx.types, LowType(a));
	final switch (a) {
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
			return gcc_jit_context_new_rvalue_from_long(ctx.gcc, gccType, 0);
		case PrimitiveType.float32:
		case PrimitiveType.float64:
			return gcc_jit_context_new_rvalue_from_double(ctx.gcc, gccType, 0);
		case PrimitiveType.void_:
			return unreachable!(gcc_jit_rvalue*);
	}
}

gcc_jit_rvalue* arbitraryValue(ref ExprCtx ctx, LowType type) {
	gcc_jit_rvalue* nullValue() {
		return gcc_jit_context_null(ctx.gcc, getGccType(ctx.types, type));
	}
	return type.combinePointer.matchIn!(gcc_jit_rvalue*)(
		(in LowType.Extern) =>
			todo!(gcc_jit_rvalue*)("!"),
		(in LowType.FunPtr) =>
			nullValue(),
		(in PrimitiveType _) =>
			emitToRValueCb((ref ExprEmit emit) =>
				zeroedToGcc(ctx, emit, type)),
		(in LowPtrCombine) =>
			nullValue(),
		(in LowType.Record) =>
			getRValueUsingLocal(ctx, type, (gcc_jit_lvalue*) {}),
		(in LowType.Union) =>
			getRValueUsingLocal(ctx, type, (gcc_jit_lvalue*) {}));
}

ExprResult initConstantsToGcc(ref ExprCtx ctx, ref ExprEmit emit) {
	zip!(immutable gcc_jit_rvalue*[], ArrTypeAndConstantsLow)(
		ctx.globalsForConstants.arrs,
		ctx.program.allConstants.arrs,
		(ref immutable gcc_jit_rvalue*[] globals, ref ArrTypeAndConstantsLow tc) {
			zip!(immutable gcc_jit_rvalue*, immutable Constant[])(
				globals,
				tc.constants,
				(ref immutable gcc_jit_rvalue* global, ref Constant[] elements) {
					verify(!empty(elements)); // Not sure how GCC would handle an empty global
					foreach (size_t index, Constant elementValue; elements) {
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
	zip!(gcc_jit_lvalue*[], PointerTypeAndConstantsLow)(
		ctx.globalsForConstants.pointers,
		ctx.program.allConstants.pointers,
		(ref gcc_jit_lvalue*[] globals, ref PointerTypeAndConstantsLow tc) {
			zip!(gcc_jit_lvalue*, Constant)(
				globals,
				tc.constants,
				(ref gcc_jit_lvalue* global, ref Constant value) {
					emitToLValueCb(global, (ref ExprEmit emitPointee) =>
						constantToGcc(ctx, emitPointee, tc.pointeeType, value));
				});
		});
	return emitVoid(ctx, emit);
}

} // GccJitAvailable
