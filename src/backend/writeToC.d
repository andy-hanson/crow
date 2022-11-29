module backend.writeToC;

@safe @nogc pure nothrow:

import backend.mangle :
	buildMangledNames,
	MangledNames,
	writeConstantArrStorageName,
	writeConstantPointerStorageName,
	writeLowFunMangledName,
	writeLowLocalName,
	writeLowParamName,
	writeLowThreadLocalMangledName,
	writeMangledName,
	writeRecordName,
	writeStructMangledName;
import backend.writeTypes : ElementAndCount, TypeWriters, writeTypes;
import interpret.debugging : writeFunName, writeFunSig;
import lower.lowExprHelpers : boolType;
import model.concreteModel : body_, BuiltinStructKind, ConcreteStruct, ConcreteStructBody, TypeSize;
import model.constant : Constant;
import model.lowModel :
	AllConstantsLow,
	ArrTypeAndConstantsLow,
	asPtrGcPointee,
	debugName,
	isChar8,
	isGlobal,
	isVoid,
	LowExpr,
	LowExprKind,
	LowField,
	LowFun,
	LowFunBody,
	LowFunExprBody,
	LowFunIndex,
	LowFunPtrType,
	LowLocal,
	LowParam,
	LowParamIndex,
	LowPtrCombine,
	LowProgram,
	LowRecord,
	LowThreadLocal,
	LowThreadLocalIndex,
	LowType,
	LowUnion,
	PointerTypeAndConstantsLow,
	PrimitiveType,
	targetIsPointer,
	targetRecordType,
	UpdateParam;
import model.model : EnumValue, name;
import model.typeLayout : sizeOfType, typeSizeBytes;
import util.alloc.alloc : Alloc, TempAlloc;
import util.col.arr : empty, only, sizeEq;
import util.col.arrUtil : every, exists, map, zip;
import util.col.dict : mustGetAt;
import util.col.fullIndexDict : FullIndexDict, fullIndexDictEach, fullIndexDictEachKey, fullIndexDictEachValue;
import util.col.stackDict : StackDict, stackDictAdd, stackDictLastAdded, stackDictMustGet;
import util.col.str : eachChar, SafeCStr;
import util.opt : force, has, Opt, some;
import util.ptr : castNonScope, castNonScope_ref, ptrTrustMe;
import util.sym : AllSymbols;
import util.union_ : Union;
import util.util : abs, drop, unreachable, verify;
import util.writer :
	finishWriterToSafeCStr,
	writeEscapedChar_inner,
	writeFloatLiteral,
	writeNewline,
	Writer,
	writeWithCommas,
	writeWithCommasZip;

immutable(SafeCStr) writeToC(
	ref Alloc alloc,
	ref TempAlloc tempAlloc,
	ref immutable AllSymbols allSymbols,
	ref immutable LowProgram program,
) {
	Writer writer = Writer(ptrTrustMe(alloc));

	writer ~= "#include <stddef.h>\n"; // for NULL
	writer ~= "#include <stdint.h>\n";
	version (Windows) {
		writer ~= "unsigned short __popcnt16(unsigned short value);\n";
		writer ~= "unsigned int __popcnt(unsigned int value);\n";
		writer ~= "unsigned __int64 __popcnt64(unsigned __int64 value);\n";
	}

	immutable Ctx ctx = immutable Ctx(ptrTrustMe(program), buildMangledNames(alloc, ptrTrustMe(allSymbols), program));

	writeStructs(alloc, writer, ctx);

	fullIndexDictEach!(LowFunIndex, LowFun)(
		program.allFuns,
		(immutable LowFunIndex funIndex, ref immutable LowFun fun) {
			writeFunDeclaration(writer, ctx, funIndex, fun);
		});

	writeConstants(writer, ctx, program.allConstants);
	writeThreadLocals(writer, ctx, program.threadLocals);

	fullIndexDictEach!(LowFunIndex, LowFun)(
		program.allFuns,
		(immutable LowFunIndex funIndex, ref immutable LowFun fun) {
			writeFunDefinition(writer, tempAlloc, ctx, funIndex, fun);
		});

	return finishWriterToSafeCStr(writer);
}

private:

void writeConstants(
	scope ref Writer writer,
	scope ref immutable Ctx ctx,
	scope ref immutable AllConstantsLow allConstants,
) {
	foreach (ref immutable ArrTypeAndConstantsLow a; allConstants.arrs) {
		foreach (immutable size_t i, immutable Constant[] elements; a.constants) {
			declareConstantArrStorage(writer, ctx, a.arrType, a.elementType, i, elements.length);
			writer ~= ";\n";
		}
	}

	foreach (ref immutable PointerTypeAndConstantsLow a; allConstants.pointers) {
		foreach (immutable size_t i; 0 .. a.constants.length) {
			declareConstantPointerStorage(writer, ctx, a.pointeeType, i);
			writer ~= ";\n";
		}
	}

	foreach (ref immutable ArrTypeAndConstantsLow a; allConstants.arrs) {
		foreach (immutable size_t i, immutable Constant[] elements; a.constants) {
			declareConstantArrStorage(writer, ctx, a.arrType, a.elementType, i, elements.length);
			writer ~= " = ";
			if (isChar8(a.elementType)) {
				writer ~= '"';
				foreach (immutable Constant element; elements) {
					immutable char x = cast(immutable char) element.as!(Constant.Integral).value;
					if (x == '?')
						// avoid trigraphs
						writer ~= "\\?";
					else
						writeEscapedChar_inner(writer, x);
				}
				writer ~= '"';
			} else {
				writer ~= '{';
				writeWithCommas!Constant(writer, elements, (scope ref immutable Constant element) {
					writeConstantRef(writer, ctx, ConstantRefPos.inner, a.elementType, element);
				});
				writer ~= '}';
			}
			writer ~= ";\n";
		}
	}

	foreach (ref immutable PointerTypeAndConstantsLow a; allConstants.pointers) {
		foreach (immutable size_t i, immutable Constant pointee; a.constants) {
			declareConstantPointerStorage(writer, ctx, a.pointeeType, i);
			writer ~= " = ";
			writeConstantRef(writer, ctx, ConstantRefPos.inner, a.pointeeType, pointee);
			writer ~= ";\n";
		}
	}
}

void writeThreadLocals(
	scope ref Writer writer,
	scope ref immutable Ctx ctx,
	scope immutable FullIndexDict!(LowThreadLocalIndex, LowThreadLocal) threadLocals,
) {
	fullIndexDictEachValue!(LowThreadLocalIndex, LowThreadLocal)(threadLocals, (ref immutable LowThreadLocal x) {
		writer ~= "static _Thread_local ";
		writeType(writer, ctx, x.type);
		writer ~= ' ';
		writeLowThreadLocalMangledName(writer, ctx.mangledNames, x);
		writer ~= ";\n";
	});
}

void declareConstantArrStorage(
	scope ref Writer writer,
	scope ref immutable Ctx ctx,
	immutable LowType.Record arrType,
	immutable LowType elementType,
	immutable size_t index,
	immutable size_t nElements,
) {
	writeType(writer, ctx, elementType);
	writer ~= ' ';
	writeConstantArrStorageName(writer, ctx.mangledNames, ctx.program, arrType, index);
	writer ~= '[';
	writer ~= nElements;
	writer ~= ']';
}

void declareConstantPointerStorage(
	scope ref Writer writer,
	scope ref immutable Ctx ctx,
	immutable LowType pointeeType,
	immutable size_t index,
) {
	//TODO: some day we may support non-record pointee?
	writeRecordType(writer, ctx, pointeeType.as!(LowType.Record));
	writer ~= ' ';
	writeConstantPointerStorageName(writer, ctx.mangledNames, ctx.program, pointeeType, index);
}

struct Ctx {
	@safe @nogc pure nothrow:

	immutable LowProgram* programPtr;
	immutable MangledNames mangledNames;

	ref immutable(LowProgram) program() return scope immutable =>
		*programPtr;
	ref immutable(AllSymbols) allSymbols() return scope immutable =>
		*mangledNames.allSymbols;
}

struct FunBodyCtx {
	@safe @nogc pure nothrow:

	TempAlloc* tempAllocPtr;
	immutable Ctx* ctxPtr;
	immutable bool hasTailRecur;
	immutable LowFunIndex curFun;
	size_t nextTemp;

	ref TempAlloc tempAlloc() scope =>
		*castNonScope(tempAllocPtr);

	ref immutable(Ctx) ctx() return scope const =>
		*ctxPtr;

	ref immutable(LowProgram) program() return scope const =>
		ctx.program;

	ref immutable(MangledNames) mangledNames() return scope const =>
		ctx.mangledNames;
}

immutable(Temp) getNextTemp(ref FunBodyCtx ctx) {
	immutable Temp temp = immutable Temp(ctx.nextTemp);
	ctx.nextTemp++;
	return temp;
}

void writeType(scope ref Writer writer, scope ref immutable Ctx ctx, scope immutable LowType t) {
	t.combinePointer.match!void(
		(immutable LowType.Extern it) {
			writer ~= "struct ";
			writeStructMangledName(writer, ctx.mangledNames, ctx.program.allExternTypes[it].source);
		},
		(immutable LowType.FunPtr it) {
			writeStructMangledName(writer, ctx.mangledNames, ctx.program.allFunPtrTypes[it].source);
		},
		(immutable PrimitiveType it) {
			writePrimitiveType(writer, it);
		},
		(immutable LowPtrCombine it) {
			writeType(writer, ctx, it.pointee);
			writer ~= '*';
		},
		(immutable LowType.Record it) {
			writeRecordType(writer, ctx, it);
		},
		(immutable LowType.Union it) {
			writer ~= "struct ";
			writeStructMangledName(writer, ctx.mangledNames, ctx.program.allUnions[it].source);
		});
}

void writeRecordType(scope ref Writer writer, scope ref immutable Ctx ctx, immutable LowType.Record a) {
	writer ~= "struct ";
	writeRecordName(writer, ctx.mangledNames, ctx.program, a);
}

void writeCastToType(scope ref Writer writer, scope ref immutable Ctx ctx, scope immutable LowType type) {
	writer ~= '(';
	writeType(writer, ctx, type);
	writer ~= ") ";
}

void writeParamDecl(scope ref Writer writer, scope ref immutable Ctx ctx, scope ref immutable LowParam a) {
	writeType(writer, ctx, a.type);
	writer ~= ' ';
	writeLowParamName(writer, ctx.mangledNames, a);
}

void writeStructHead(scope ref Writer writer, scope ref immutable Ctx ctx, scope immutable ConcreteStruct* source) {
	writer ~= "struct ";
	writeStructMangledName(writer, ctx.mangledNames, source);
	writer ~= " {";
}

void writeStructEnd(scope ref Writer writer) {
	writer ~= "\n};\n";
}

void writeRecord(scope ref Writer writer, scope ref immutable Ctx ctx, scope ref immutable LowRecord a) {
	if (a.packed) {
		version (Windows) {
			writer ~= "__pragma(pack(push, 1))\n";
		}
	}
	writeStructHead(writer, ctx, a.source);
	foreach (ref immutable LowField field; a.fields) {
		if (!isVoid(field.type)) {
			writer ~= "\n\t";
			writeType(writer, ctx, field.type);
			writer ~= ' ';
			writeMangledName(writer, ctx.mangledNames, debugName(field));
			writer ~= ';';
		}
	}
	writer ~= "\n}";
	if (a.packed) {
		version (Windows) {
			writer ~= "__pragma(pack(pop))";
		} else {
			writer ~= " __attribute__ ((__packed__))";
		}
	}
	writer ~= ";\n";
}

void writeUnion(scope ref Writer writer, scope ref immutable Ctx ctx, scope ref immutable LowUnion a) {
	writeStructHead(writer, ctx, a.source);
	writer ~= "\n\tuint64_t kind;";
	immutable bool isBuiltin = body_(*a.source).isA!(ConcreteStructBody.Builtin);
	if (isBuiltin) verify(body_(*a.source).as!(ConcreteStructBody.Builtin).kind == BuiltinStructKind.fun);
	if (isBuiltin || exists!(immutable LowType)(a.members, (ref immutable LowType member) => !isVoid(member))) {
		writer ~= "\n\tunion {";
		foreach (immutable size_t memberIndex, immutable LowType member; a.members) {
			if (!isVoid(member)) {
				writer ~= "\n\t\t";
				writeType(writer, ctx, member);
				writer ~= " as";
				writer ~= memberIndex;
				writer ~= ';';
			}
		}
		// Fun types must be 16 bytes
		if (isBuiltin &&
			every!LowType(a.members, (ref immutable LowType member) => typeSizeBytes(ctx.program, member) < 8))
			writer ~= "\n\t\tuint64_t __ensureSizeIs16;";
		writer ~= "\n\t};";
	}
	writeStructEnd(writer);
}

void declareStruct(scope ref Writer writer, scope ref immutable Ctx ctx, scope immutable ConcreteStruct* source) {
	writer ~= "struct ";
	writeStructMangledName(writer, ctx.mangledNames, source);
	writer ~= ";\n";
}

void staticAssertStructSize(
	scope ref Writer writer,
	scope ref immutable Ctx ctx,
	scope immutable LowType type,
	immutable TypeSize size,
) {
	writer ~= "_Static_assert(sizeof(";
	writeType(writer, ctx, type);
	writer ~= ") == ";
	writer ~= size.sizeBytes;
	writer ~= ", \"\");\n";

	writer ~= "_Static_assert(_Alignof(";
	writeType(writer, ctx, type);
	writer ~= ") == ";
	writer ~= size.alignmentBytes;
	writer ~= ", \"\");\n";
}

void writeStructs(ref Alloc alloc, scope ref Writer writer, scope ref immutable Ctx ctx) {
	scope immutable TypeWriters writers = immutable TypeWriters(
		(immutable ConcreteStruct* it) {
			declareStruct(writer, ctx, it);
		},
		(immutable ConcreteStruct* source, immutable Opt!ElementAndCount ec) {
			writer ~= "struct ";
			writeStructMangledName(writer, ctx.mangledNames, source);
			if (has(ec)) {
				writer ~= " { ";
				writePrimitiveType(writer, force(ec).elementType);
				writer ~= " __sizer[";
				writer ~= force(ec).count;
				writer ~= "]; }";
			}
			writer ~= ";\n";
		},
		(immutable LowType.FunPtr, ref immutable LowFunPtrType funPtr) {
			writer ~= "typedef ";
			if (isVoid(funPtr.returnType))
				writer ~= "void";
			else
				writeType(writer, ctx, funPtr.returnType);
			writer ~= " (*";
			writeStructMangledName(writer, ctx.mangledNames, funPtr.source);
			writer ~= ")(";
			if (empty(funPtr.paramTypes))
				writer ~= "void";
			else
				writeWithCommas!LowType(
					writer,
					funPtr.paramTypes,
					(scope ref immutable LowType paramType) =>
						!isVoid(paramType),
					(scope ref immutable LowType paramType) {
						writeType(writer, ctx, paramType);
					});
			writer ~= ");\n";
		},
		(immutable LowType.Record, ref immutable LowRecord record) {
			writeRecord(writer, ctx, record);
		},
		(immutable LowType.Union, ref immutable LowUnion union_) {
			writeUnion(writer, ctx, union_);
		});
	writeTypes(alloc, ctx.program, writers);

	writer ~= '\n';

	void assertSize(immutable LowType t) {
		staticAssertStructSize(writer, ctx, t, sizeOfType(ctx.program, t));
	}

	//TODO: use a temp alloc
	fullIndexDictEachKey!(LowType.Record, LowRecord)(ctx.program.allRecords, (immutable LowType.Record it) {
		assertSize(immutable LowType(it));
	});
	fullIndexDictEachKey!(LowType.Union, LowUnion)(ctx.program.allUnions, (immutable LowType.Union it) {
		assertSize(immutable LowType(it));
	});
}

void writeFunReturnTypeNameAndParams(
	scope ref Writer writer,
	scope ref immutable Ctx ctx,
	immutable LowFunIndex funIndex,
	scope ref immutable LowFun fun,
) {
	if (isVoid(fun.returnType))
		writer ~= "void";
	else
		writeType(writer, ctx, fun.returnType);
	writer ~= ' ';
	writeLowFunMangledName(writer, ctx.mangledNames, funIndex, fun);
	if (!isGlobal(fun.body_)) {
		writer ~= '(';
		if (every!(immutable LowParam)(fun.params, (ref immutable LowParam x) => isVoid(x.type)))
			writer ~= "void";
		else
			writeWithCommas!LowParam(
				writer,
				fun.params,
				(scope ref immutable LowParam x) =>
					!isVoid(x.type),
				(scope ref immutable LowParam x) {
					writeParamDecl(writer, ctx, x);
				});
		writer ~= ')';
	}
}

void writeFunDeclaration(
	scope ref Writer writer,
	scope ref immutable Ctx ctx,
	immutable LowFunIndex funIndex,
	scope ref immutable LowFun fun,
) {
	if (fun.body_.isA!(LowFunBody.Extern))
		writer ~= "extern ";
	writeFunReturnTypeNameAndParams(writer, ctx, funIndex, fun);
	writer ~= ";\n";
}

void writeFunDefinition(
	scope ref Writer writer,
	ref TempAlloc tempAlloc,
	scope ref immutable Ctx ctx,
	immutable LowFunIndex funIndex,
	scope ref immutable LowFun fun,
) {
	fun.body_.match!void(
		(immutable LowFunBody.Extern) {
			// declaration is enough
		},
		(immutable LowFunExprBody x) {
			// TODO: only if a flag is set
			writer ~= "/* ";
			writeFunName(writer, ctx.allSymbols, ctx.program, funIndex);
			writer ~= ' ';
			writeFunSig(writer, ctx.allSymbols, ctx.program, fun);
			writer ~= " */\n";
			writeFunWithExprBody(writer, tempAlloc, ctx, funIndex, fun, x);
		});
}

//TODO: not @trusted
@trusted void writeFunWithExprBody(
	scope ref Writer writer,
	ref TempAlloc tempAlloc,
	scope ref immutable Ctx ctx,
	immutable LowFunIndex funIndex,
	scope ref immutable LowFun fun,
	ref immutable LowFunExprBody body_,
) {
	writeFunReturnTypeNameAndParams(writer, ctx, funIndex, fun);
	writer ~= " {";
	if (body_.hasTailRecur)
		writer ~= "\n\ttop:;"; // Need ';' so it labels a statement
	FunBodyCtx bodyCtx = FunBodyCtx(ptrTrustMe(tempAlloc), ptrTrustMe(ctx), body_.hasTailRecur, funIndex, 0);
	immutable WriteKind writeKind = immutable WriteKind(immutable WriteKind.Return());
	immutable Locals locals;
	drop(writeExpr(writer, 1, bodyCtx, locals, writeKind, body_.expr));
	writer ~= "\n}\n";
}

struct Temp {
	immutable size_t index;
}

// If expr, we refused to write to a temp because this can be written inline
struct WriteExprResult {
	// Meaning depends on the WriteKind
	// If the write kind was TempOrInline, this indicates that it should be done inline.
	struct Done {
		// Args (not written inline) prepared for writing inline.
		immutable WriteExprResult[] args;
	}

	mixin Union!(immutable Done, immutable Temp);
}

immutable(WriteExprResult) writeExprDone() =>
	immutable WriteExprResult(immutable WriteExprResult.Done([]));

void writeTempDeclare(
	scope ref Writer writer,
	scope ref FunBodyCtx ctx,
	scope immutable LowType type,
	immutable Temp temp,
) {
	writeType(writer, ctx.ctx, type);
	writer ~= ' ';
	writeTempRef(writer, temp);
}

void writeTempRef(ref Writer writer, ref immutable Temp a) {
	writer ~= "_";
	writer ~= a.index;
}

void writeTempOrInline(
	scope ref Writer writer,
	scope ref FunBodyCtx ctx,
	scope ref immutable Locals locals,
	scope ref immutable LowExpr e,
	scope ref immutable WriteExprResult a,
) {
	a.match!void(
		(immutable WriteExprResult.Done it) {
			immutable WriteKind writeKind = immutable WriteKind(immutable WriteKind.Inline(it.args));
			immutable WriteExprResult res = writeExpr(writer, 0, ctx, locals, writeKind, e);
			verify(empty(res.as!(WriteExprResult.Done).args));
		},
		(immutable Temp it) {
			writeTempRef(writer, it);
		});
}

void writeTempOrInlines(
	scope ref Writer writer,
	scope ref FunBodyCtx ctx,
	scope ref immutable Locals locals,
	scope immutable LowExpr[] exprs,
	scope immutable WriteExprResult[] args,
) {
	verify(sizeEq(exprs, args));
	writeWithCommasZip!(LowExpr, WriteExprResult)(
		writer,
		exprs,
		args,
		(scope ref immutable LowExpr expr, scope ref immutable WriteExprResult) =>
			!isVoid(expr.type),
		(scope ref immutable LowExpr expr, scope ref immutable WriteExprResult arg) {
			writeTempOrInline(writer, ctx, locals, expr, arg);
		});
}

void writeDeclareLocal(
	scope ref Writer writer,
	immutable size_t indent,
	scope ref FunBodyCtx ctx,
	scope ref immutable LowLocal local,
) {
	writeNewline(writer, indent);
	writeType(writer, ctx.ctx, local.type);
	writer ~= ' ';
	writeLowLocalName(writer, ctx.mangledNames, local);
}

struct WriteKind {
	@safe @nogc pure nothrow:

	struct Inline {
		immutable WriteExprResult[] args;
	}
	// May write a temp now, or delay and write inline when needed.
	struct InlineOrTemp {}
	struct MakeTemp {}
	struct Return {}
	struct UseTemp {
		immutable Temp temp;
	}
	// Simple statement, don't return anything
	struct Void {}

	mixin Union!(
		immutable Inline,
		immutable InlineOrTemp,
		immutable LowLocal*,
		immutable MakeTemp,
		immutable Return,
		immutable UseTemp,
		immutable Void);
}
static assert(WriteKind.sizeof == size_t.sizeof * 3);

immutable(WriteExprResult[]) writeExprsTempOrInline(
	scope ref Writer writer,
	immutable size_t indent,
	scope ref FunBodyCtx ctx,
	scope ref immutable Locals locals,
	scope immutable LowExpr[] args,
) =>
	map(ctx.tempAlloc, args, (ref immutable LowExpr arg) =>
		writeExprTempOrInline(writer, indent, ctx, locals, arg));

immutable(Temp) writeExprTemp(
	scope ref Writer writer,
	immutable size_t indent,
	scope ref FunBodyCtx ctx,
	scope ref immutable Locals locals,
	scope ref immutable LowExpr expr,
) {
	immutable WriteKind writeKind = immutable WriteKind(immutable WriteKind.MakeTemp());
	return writeExpr(writer, indent, ctx, locals, writeKind, expr).as!Temp;
}

void writeExprVoid(
	scope ref Writer writer,
	immutable size_t indent,
	scope ref FunBodyCtx ctx,
	scope ref immutable Locals locals,
	scope ref immutable LowExpr expr,
) {
	immutable WriteKind writeKind = immutable WriteKind(immutable WriteKind.Void());
	drop(writeExpr(writer, indent, ctx, locals, writeKind, expr));
}

immutable(WriteExprResult) writeExprTempOrInline(
	scope ref Writer writer,
	immutable size_t indent,
	scope ref FunBodyCtx ctx,
	scope ref immutable Locals locals,
	scope ref immutable LowExpr expr,
) {
	immutable WriteKind writeKind = immutable WriteKind(immutable WriteKind.InlineOrTemp());
	return writeExpr(writer, indent, ctx, locals, writeKind, expr);
}

struct LoopInfo {
	immutable uint index;
	immutable WriteKind writeKind;
}

// Currently only needed to map loop to a unique (within the function) identifier
alias Locals = StackDict!(LowExprKind.Loop*, LoopInfo*);
alias addLoop = stackDictAdd!(LowExprKind.Loop*, LoopInfo*);
alias getLoop = stackDictMustGet!(LowExprKind.Loop*, LoopInfo*);
immutable(uint) nextLoopIndex(scope ref immutable Locals locals) {
	immutable Opt!(LoopInfo*) last = stackDictLastAdded(locals);
	return has(last) ? force(last).index + 1 : 0;
}

immutable(WriteExprResult) writeExpr(
	scope ref Writer writer,
	immutable size_t indent,
	scope ref FunBodyCtx ctx,
	scope ref immutable Locals locals,
	scope ref immutable WriteKind writeKind,
	scope ref immutable LowExpr expr,
) {
	immutable LowType type = expr.type;
	immutable(WriteExprResult) nonInlineable(scope void delegate() @safe @nogc pure nothrow cb) =>
		writeNonInlineable(writer, indent, ctx, writeKind, type, cb);
	immutable(WriteExprResult) inlineable(
		ref immutable LowExpr[] args,
		scope void delegate(scope immutable WriteExprResult[]) @safe @nogc pure nothrow inline,
	) @safe =>
		writeInlineable(writer, indent, ctx, locals, writeKind, type, args, inline);
	immutable(WriteExprResult) inlineableSingleArg(
		ref immutable LowExpr arg,
		scope void delegate(ref immutable WriteExprResult) @safe @nogc pure nothrow inline,
	) @safe =>
		writeInlineableSingleArg(writer, indent, ctx, locals, writeKind, type, arg, inline);
	immutable(WriteExprResult) inlineableSimple(scope void delegate() @safe @nogc pure nothrow inline) =>
		writeInlineableSimple(writer, indent, ctx, locals, writeKind, type, inline);

	return castNonScope_ref(expr).kind.match!(immutable WriteExprResult)(
		(immutable LowExprKind.Call it) @safe =>
			writeCallExpr(writer, indent, ctx, locals, writeKind, type, it),
		(ref immutable LowExprKind.CallFunPtr it) =>
			writeCallFunPtr(writer, indent, ctx, locals, writeKind, type, it),
		(immutable LowExprKind.CreateRecord it) @safe =>
			inlineable(it.args, (scope immutable WriteExprResult[] args) {
				writeCastToType(writer, ctx.ctx, type);
				writer ~= '{';
				writeTempOrInlines(writer, ctx, locals, it.args, args);
				writer ~= '}';
			}),
		(ref immutable LowExprKind.CreateUnion it) @safe =>
			inlineableSingleArg(it.arg, (scope ref immutable WriteExprResult arg) {
				writeCreateUnion(writer, ctx.ctx, ConstantRefPos.outer, type, it.memberIndex, () {
					writeTempOrInline(writer, ctx, locals, it.arg, arg);
				});
			}),
		(ref immutable LowExprKind.If it) =>
			writeIf(writer, indent, ctx, locals, writeKind, type, it),
		(immutable LowExprKind.InitConstants) =>
			// writeToC doesn't need to do anything in 'init-constants'
			writeReturnVoid(writer, indent, ctx, writeKind),
		(ref immutable LowExprKind.Let it) =>
			writeLet(writer, indent, ctx, locals, writeKind, it),
		(immutable LowExprKind.LocalGet it) =>
			inlineableSimple(() {
				writeLowLocalName(writer, ctx.mangledNames, *it.local);
			}),
		(ref immutable LowExprKind.LocalSet it) =>
			writeLocalSet(writer, indent, ctx, locals, writeKind, it),
		(ref immutable LowExprKind.Loop it) =>
			writeLoop(writer, indent, ctx, locals, writeKind, type, it),
		(ref immutable LowExprKind.LoopBreak it) =>
			writeLoopBreak(writer, indent, ctx, locals, writeKind, it),
		(immutable LowExprKind.LoopContinue it) {
			// Do nothing, continuing the loop is implicit in C
			verify(writeKind.isA!(WriteKind.Void));
			return immutable WriteExprResult(immutable WriteExprResult.Done());
		},
		(ref immutable LowExprKind.MatchUnion it) =>
			writeMatchUnion(writer, indent, ctx, locals, writeKind, type, it),
		(immutable LowExprKind.ParamGet it) =>
			inlineableSimple(() {
				writeParamGet(writer, ctx, it.index);
			}),
		(ref immutable LowExprKind.PtrCast it) =>
			inlineableSingleArg(it.target, (ref immutable WriteExprResult arg) {
				writer ~= '(';
				writeCastToType(writer, ctx.ctx, type);
				writeTempOrInline(writer, ctx, locals, it.target, arg);
				writer ~= ')';
			}),
		(ref immutable LowExprKind.PtrToField it) =>
			writePtrToField(writer, indent, ctx, locals, writeKind, type, it),
		(immutable LowExprKind.PtrToLocal it) =>
			inlineableSimple(() {
				writer ~= '&';
				writeLowLocalName(writer, ctx.mangledNames, *it.local);
			}),
		(immutable LowExprKind.PtrToParam it) =>
			inlineableSimple(() {
				writer ~= '&';
				writeParamGet(writer, ctx, it.index);
			}),
		(ref immutable LowExprKind.RecordFieldGet it) =>
			writeRecordFieldGet(writer, indent, ctx, locals, writeKind, type, it),
		(ref immutable LowExprKind.RecordFieldSet it) @safe {
			immutable WriteExprResult recordValue =
				writeExprTempOrInline(writer, indent, ctx, locals, it.target);
			immutable WriteExprResult fieldValue =
				writeExprTempOrInline(writer, indent, ctx, locals, it.value);
			return writeReturnVoid(writer, indent, ctx, writeKind, () {
				writeTempOrInline(writer, ctx, locals, it.target, recordValue);
				writeRecordFieldRef(writer, ctx, targetIsPointer(it), targetRecordType(it), it.fieldIndex);
				writer ~= " = ";
				writeTempOrInline(writer, ctx, locals, it.value, fieldValue);
			});
		},
		(ref immutable LowExprKind.Seq it) @safe {
			if (!writeKind.isA!(WriteKind.Inline))
				writeExprVoid(writer, indent, ctx, locals, it.first);
			return writeExpr(writer, indent, ctx, locals, writeKind, it.then);
		},
		(immutable LowExprKind.SizeOf it) =>
			inlineableSimple(() {
				writer ~= "sizeof(";
				writeType(writer, ctx.ctx, it.type);
				writer ~= ')';
			}),
		(immutable Constant it) =>
			inlineableSimple(() {
				writeConstantRef(writer, ctx.ctx, ConstantRefPos.outer, type, it);
			}),
		(ref immutable LowExprKind.SpecialUnary it) =>
			writeSpecialUnary(writer, indent, ctx, locals, writeKind, type, it),
		(ref immutable LowExprKind.SpecialBinary it) =>
			writeSpecialBinary(writer, indent, ctx, locals, writeKind, type, it),
		(ref immutable LowExprKind.SpecialTernary) =>
			unreachable!(immutable WriteExprResult),
		(ref immutable LowExprKind.Switch0ToN it) =>
			writeSwitch(
				writer, indent, ctx, locals, writeKind, type, it.value, it.cases,
				(immutable size_t i) => immutable EnumValue(i)),
		(ref immutable LowExprKind.SwitchWithValues it) =>
			writeSwitch(
				writer, indent, ctx, locals, writeKind, type, it.value, it.cases,
				(immutable size_t i) => it.values[i]),
		(immutable LowExprKind.TailRecur it) {
			verify(writeKind.isA!(WriteKind.Return));
			writeTailRecur(writer, indent, ctx, locals, it);
			return writeExprDone();
		},
		(immutable LowExprKind.ThreadLocalPtr x) =>
			inlineableSimple(() {
				writer ~= '&';
				writeLowThreadLocalMangledName(writer, ctx.mangledNames, ctx.program.threadLocals[x.threadLocalIndex]);
			}));
}

immutable(WriteExprResult) writeNonInlineable(
	scope ref Writer writer,
	immutable size_t indent,
	scope ref FunBodyCtx ctx,
	scope ref immutable WriteKind writeKind,
	scope immutable LowType type,
	scope void delegate() @safe @nogc pure nothrow cb,
) {
	if (!writeKind.isA!(WriteKind.Inline))
		writeNewline(writer, indent);
	immutable(WriteExprResult) makeTemp() {
		immutable Temp temp = getNextTemp(ctx);
		if (!isVoid(type)) {
			writeTempDeclare(writer, ctx, type, temp);
			writer ~= " = ";
		}
		return immutable WriteExprResult(temp);
	}
	immutable WriteExprResult res = castNonScope_ref(writeKind).match!(immutable WriteExprResult)(
		(immutable WriteKind.Inline) =>
			writeExprDone(),
		(immutable WriteKind.InlineOrTemp) =>
			makeTemp(),
		(ref immutable LowLocal x) {
			writeLowLocalName(writer, ctx.mangledNames, x);
			writer ~= " = ";
			return writeExprDone();
		},
		(immutable MakeTemp) =>
			makeTemp(),
		(immutable WriteKind.Return) {
			writer ~= "return ";
			return writeExprDone();
		},
		(immutable WriteKind.UseTemp x) {
			writeTempRef(writer, x.temp);
			writer ~= " = ";
			return writeExprDone();
		},
		(immutable WriteKind.Void) =>
			writeExprDone());
	cb();
	if (!writeKind.isA!(WriteKind.Inline))
		writer ~= ';';
	return res;
}

immutable(WriteExprResult) writeInlineable(
	scope ref Writer writer,
	immutable size_t indent,
	scope ref FunBodyCtx ctx,
	scope ref immutable Locals locals,
	scope ref immutable WriteKind writeKind,
	scope immutable LowType type,
	scope immutable LowExpr[] args,
	scope void delegate(scope immutable WriteExprResult[]) @safe @nogc pure nothrow inline,
) {
	if (writeKind.isA!(WriteKind.InlineOrTemp))
		return immutable WriteExprResult(immutable WriteExprResult.Done(
			writeExprsTempOrInline(writer, indent, ctx, locals, args)));
	else if (writeKind.isA!(WriteKind.Inline)) {
		inline(writeKind.as!(WriteKind.Inline).args);
		return writeExprDone();
	} else {
		immutable WriteExprResult[] argTemps = writeExprsTempOrInline(writer, indent, ctx, locals,args);
		return writeNonInlineable(writer, indent, ctx, writeKind, type, () {
			inline(argTemps);
		});
	}
}

immutable(WriteExprResult) writeInlineableSingleArg(
	scope ref Writer writer,
	immutable size_t indent,
	scope ref FunBodyCtx ctx,
	scope ref immutable Locals locals,
	scope ref immutable WriteKind writeKind,
	scope immutable LowType type,
	scope ref immutable LowExpr arg,
	scope void delegate(ref immutable WriteExprResult) @safe @nogc pure nothrow inline,
) =>
	writeInlineable(
		writer, indent, ctx, locals, writeKind, type, [castNonScope_ref(arg)],
		(scope immutable WriteExprResult[] args) {
			inline(only(args));
		});

immutable(WriteExprResult) writeInlineableSimple(
	scope ref Writer writer,
	immutable size_t indent,
	scope ref FunBodyCtx ctx,
	scope ref immutable Locals locals,
	scope ref immutable WriteKind writeKind,
	scope immutable LowType type,
	scope void delegate() @safe @nogc pure nothrow inline,
) =>
	writeInlineable(writer, indent, ctx, locals, writeKind, type, [], (scope immutable WriteExprResult[]) {
		if (!isVoid(type))
			inline();
	});

immutable(WriteExprResult) writeReturnVoid(
	scope ref Writer writer,
	immutable size_t indent,
	scope ref FunBodyCtx ctx,
	scope ref immutable WriteKind writeKind,
) =>
	writeReturnVoid(writer, indent, ctx, writeKind, null);

immutable(WriteExprResult) writeReturnVoid(
	scope ref Writer writer,
	immutable size_t indent,
	scope ref FunBodyCtx ctx,
	scope ref immutable WriteKind writeKind,
	scope void delegate() @safe @nogc pure nothrow cb,
) =>
	castNonScope_ref(writeKind).match!(immutable WriteExprResult)(
		(immutable WriteKind.Inline) =>
			unreachable!(immutable WriteExprResult),
		(immutable WriteKind.InlineOrTemp) =>
			unreachable!(immutable WriteExprResult),
		(ref immutable LowLocal) =>
			unreachable!(immutable WriteExprResult),
		(immutable WriteKind.MakeTemp) =>
			unreachable!(immutable WriteExprResult),
		(immutable WriteKind.Return) {
			if (cb != null) {
				writeNewline(writer, indent);
				cb();
			}
			writer ~= ';';
			writeNewline(writer, indent);
			writer ~= "return;";
			return writeExprDone();
		},
		(immutable WriteKind.UseTemp) =>
			unreachable!(immutable WriteExprResult),
		(immutable WriteKind.Void) {
			if (cb != null) {
				writeNewline(writer, indent);
				cb();
				writer ~= ';';
			}
			return writeExprDone();
		});

immutable(WriteExprResult) writeCallExpr(
	scope ref Writer writer,
	immutable size_t indent,
	scope ref FunBodyCtx ctx,
	scope ref immutable Locals locals,
	scope ref immutable WriteKind writeKind,
	scope immutable LowType type,
	ref immutable LowExprKind.Call a,
) {
	immutable WriteExprResult[] args = writeExprsTempOrInline(writer, indent, ctx, locals, a.args);
	return writeNonInlineable(writer, indent, ctx, writeKind, type, () {
		immutable LowFun* called = &ctx.program.allFuns[a.called];
		writeLowFunMangledName(writer, ctx.mangledNames, a.called, *called);
		if (!isGlobal(called.body_)) {
			writer ~= '(';
			writeTempOrInlines(writer, ctx, locals, a.args, args);
			writer ~= ')';
		}
	});
}

void writeTailRecur(
	scope ref Writer writer,
	immutable size_t indent,
	scope ref FunBodyCtx ctx,
	scope ref immutable Locals locals,
	scope ref immutable LowExprKind.TailRecur a,
) {
	immutable LowParam[] params = ctx.program.allFuns[ctx.curFun].params;
	immutable WriteExprResult[] newValues =
		map(ctx.tempAlloc, a.updateParams, (ref immutable UpdateParam updateParam) =>
			writeExprTempOrInline(writer, indent, ctx, locals, updateParam.newValue));
	zip!(immutable UpdateParam, immutable WriteExprResult)(
		a.updateParams,
		newValues,
		(ref immutable UpdateParam updateParam, ref immutable WriteExprResult newValue) {
			immutable LowParam param = params[updateParam.param.index];
			if (!isVoid(param.type)) {
				writeNewline(writer, indent);
				writeLowParamName(writer, ctx.mangledNames, param);
				writer ~= " = ";
				writeTempOrInline(writer, ctx, locals, updateParam.newValue, newValue);
				writer ~= ';';
			}
		});
	writeNewline(writer, indent);
	writer ~= "goto top;";
}

void writeCreateUnion(
	scope ref Writer writer,
	scope ref immutable Ctx ctx,
	immutable ConstantRefPos pos,
	scope immutable LowType type,
	immutable size_t memberIndex,
	scope void delegate() @safe @nogc pure nothrow cbWriteMember,
) {
	if (pos == ConstantRefPos.outer) writeCastToType(writer, ctx, type);
	writer ~= '{';
	writer ~= memberIndex;
	immutable LowUnion union_ = ctx.program.allUnions[type.as!(LowType.Union)];
	immutable LowType memberType = union_.members[memberIndex];
	if (!isVoid(memberType)) {
		writer ~= ", .as";
		writer ~= memberIndex;
		writer ~= " = ";
		cbWriteMember();
	}
	writer ~= '}';
}

void writeFunPtr(scope ref Writer writer, scope ref immutable Ctx ctx, immutable LowFunIndex a) {
	writeLowFunMangledName(writer, ctx.mangledNames, a, ctx.program.allFuns[a]);
}

void writeParamGet(scope ref Writer writer, scope ref const FunBodyCtx ctx, immutable LowParamIndex a) {
	writeLowParamName(writer, ctx.mangledNames, ctx.program.allFuns[ctx.curFun].params[a.index]);
}

immutable(WriteExprResult) writeMatchUnion(
	scope ref Writer writer,
	immutable size_t indent,
	scope ref FunBodyCtx ctx,
	scope ref immutable Locals locals,
	scope ref immutable WriteKind writeKind,
	scope immutable LowType type,
	scope ref immutable LowExprKind.MatchUnion a,
) {
	immutable Temp matchedValue = writeExprTemp(writer, indent, ctx, locals, a.matchedValue);
	immutable WriteExprResultAndNested nested =
		getNestedWriteKind(writer, indent, ctx, type, castNonScope_ref(writeKind));
	writeNewline(writer, indent);
	writer ~= "switch (";
	writeTempRef(writer, matchedValue);
	writer ~= ".kind) {";
	foreach (immutable size_t caseIndex, ref immutable LowExprKind.MatchUnion.Case case_; a.cases) {
		writeNewline(writer, indent + 1);
		writer ~= "case ";
		writer ~= caseIndex;
		writer ~= ": {";
		if (has(case_.local) && !isVoid(force(case_.local).type)) {
			writeDeclareLocal(writer, indent + 2, ctx, *force(case_.local));
			writer ~= " = ";
			writeTempRef(writer, matchedValue);
			writer ~= ".as";
			writer ~= caseIndex;
			writer ~= ';';
			writeNewline(writer, indent + 2);
		}
		drop(writeExpr(writer, indent + 2, ctx, locals, nested.writeKind, case_.then));
		if (!nested.writeKind.isA!(WriteKind.Return)) {
			writeNewline(writer, indent + 2);
			writer ~= "break;";
		}
		writeNewline(writer, indent + 1);
		writer ~= '}';
	}
	writeDefaultAbort(writer, indent, ctx, locals, nested.writeKind, type);
	writeNewline(writer, indent);
	writer ~= '}';
	return nested.result;
}

void writeDefaultAbort(
	scope ref Writer writer,
	immutable size_t indent,
	scope ref FunBodyCtx ctx,
	scope ref immutable Locals locals,
	scope ref immutable WriteKind writeKind,
	scope immutable LowType type,
) {
	writeNewline(writer, indent + 1);
	writer ~= "default:";
	writeNewline(writer, indent + 2);
	writer ~= "abort();";
	version (Windows) {
		if (!isVoid(type)) {
			drop(writeInlineableSimple(writer, indent, ctx, locals, writeKind, type, () {
				writeZeroedValue(writer, ctx.ctx, type);
			}));
			writer ~= ';';
		}
	}
}

//TODO: share code with writeMatchUnion
immutable(WriteExprResult) writeSwitch(
	scope ref Writer writer,
	immutable size_t indent,
	scope ref FunBodyCtx ctx,
	scope ref immutable Locals locals,
	scope ref immutable WriteKind writeKind,
	scope immutable LowType type, // type returned by the switch
	scope ref immutable LowExpr value,
	scope immutable LowExpr[] cases,
	scope immutable(EnumValue) delegate(immutable size_t) @safe @nogc pure nothrow getValue,
) {
	immutable WriteExprResult valueResult = writeExprTempOrInline(writer, indent, ctx, locals, value);
	immutable WriteExprResultAndNested nested =
		getNestedWriteKind(writer, indent, ctx, type, castNonScope_ref(writeKind));
	writer ~= "switch (";
	writeTempOrInline(writer, ctx, locals, value, valueResult);
	writer ~= ") {";
	foreach (immutable size_t caseIndex, ref immutable LowExpr case_; cases) {
		writeNewline(writer, indent + 1);
		writer ~= "case ";
		if (isSignedIntegral(value.type.as!PrimitiveType))
			writer ~= getValue(caseIndex).asSigned();
		else
			writer ~= getValue(caseIndex).asUnsigned();
		writer ~= ": {";
		drop(writeExpr(writer, indent + 2, ctx, locals, nested.writeKind, case_));
		if (!nested.writeKind.isA!(WriteKind.Return)) {
			writeNewline(writer, indent + 2);
			writer ~= "break;";
		}
		writeNewline(writer, indent + 1);
		writer ~= '}';
	}
	writeDefaultAbort(writer, indent, ctx, locals, writeKind, type);
	writeNewline(writer, indent);
	writer ~= '}';
	return nested.result;
}

immutable(bool) isSignedIntegral(immutable PrimitiveType a) {
	final switch (a) {
		case PrimitiveType.float32:
		case PrimitiveType.float64:
		case PrimitiveType.void_:
			return unreachable!(immutable bool);
		case PrimitiveType.int8:
		case PrimitiveType.int16:
		case PrimitiveType.int32:
		case PrimitiveType.int64:
			return true;
		case PrimitiveType.bool_:
		case PrimitiveType.char8:
		case PrimitiveType.nat8:
		case PrimitiveType.nat16:
		case PrimitiveType.nat32:
		case PrimitiveType.nat64:
			return false;
	}
}

void writeRecordFieldRef(
	scope ref Writer writer,
	scope ref const FunBodyCtx ctx,
	immutable bool targetIsPointer,
	immutable LowType.Record record,
	immutable size_t fieldIndex,
) {
	writer ~= targetIsPointer ? "->" : ".";
	writeMangledName(
		writer,
		ctx.mangledNames,
		debugName(ctx.program.allRecords[record].fields[fieldIndex]));
}

// For some reason, providing a type for a record makes it non-constant.
// But that is mandatory at the outermost level.
enum ConstantRefPos {
	outer,
	inner,
}

void writeConstantRef(
	scope ref Writer writer,
	scope ref immutable Ctx ctx,
	immutable ConstantRefPos pos,
	scope immutable LowType type,
	scope immutable Constant a,
) {
	a.match!void(
		(immutable Constant.ArrConstant it) {
			if (pos == ConstantRefPos.outer) writeCastToType(writer, ctx, type);
			immutable size_t size = ctx.program.allConstants.arrs[it.typeIndex].constants[it.index].length;
			writer ~= '{';
			writer ~= size;
			writer ~= ", ";
			if (size == 0)
				writer ~= "NULL";
			else
				writeConstantArrStorageName(writer, ctx.mangledNames, ctx.program, type.as!(LowType.Record), it.index);
			writer ~= '}';
		},
		(immutable Constant.CString it) {
			writer ~= '"';
			eachChar(ctx.program.allConstants.cStrings[it.index], (immutable char c) {
				writeEscapedChar_inner(writer, c);
			});
			writer ~= '"';
		},
		(immutable Constant.Float it) {
			switch (type.as!PrimitiveType) {
				case PrimitiveType.float32:
					writeCastToType(writer, ctx, type);
					break;
				case PrimitiveType.float64:
					break;
				default:
					unreachable!void();
			}
			writeFloatLiteral(writer, it.value);
		},
		(immutable Constant.FunPtr it) {
			immutable bool isRawPtr = type.match!(immutable bool)(
				(immutable LowType.Extern) => unreachable!bool,
				(immutable LowType.FunPtr) => false,
				(immutable PrimitiveType) => unreachable!bool,
				(immutable LowType.PtrGc) => unreachable!bool,
				(immutable LowType.PtrRawConst) => true,
				(immutable LowType.PtrRawMut) => true,
				(immutable LowType.Record) => unreachable!bool,
				(immutable LowType.Union) => unreachable!bool);
			if (isRawPtr)
				writer ~= "((uint8_t*)";
			writeFunPtr(writer, ctx, mustGetAt(ctx.program.concreteFunToLowFunIndex, it.fun));
			if (isRawPtr)
				writer ~= ')';
		},
		(immutable Constant.Integral it) {
			if (isSignedIntegral(type.as!PrimitiveType)) {
				if (it.value == int.min)
					writer ~= "INT32_MIN";
				else if (it.value == long.min)
					// Can't write this as a literal since the '-' and rest are parsed separately,
					// and the abs of the minimum integer is out of range.
					writer ~= "INT64_MIN";
				else
					writer ~= it.value;
			} else {
				writer ~= cast(immutable ulong) it.value;
				writer ~= 'u';
			}
		},
		(immutable Constant.Pointer it) {
			writer ~= '&';
			writeConstantPointerStorageName(writer, ctx.mangledNames, ctx.program, asPtrGcPointee(type), it.index);
		},
		(immutable Constant.Record it) {
			immutable LowField[] fields = ctx.program.allRecords[type.as!(LowType.Record)].fields;
			verify(sizeEq(fields, it.args));
			if (pos == ConstantRefPos.outer)
				writeCastToType(writer, ctx, type);
			writer ~= '{';
			writeWithCommasZip!(LowField, Constant)(
				writer,
				fields,
				it.args,
				(ref immutable LowField field, ref immutable Constant arg) =>
					!isVoid(field.type),
				(ref immutable LowField field, ref immutable Constant arg) {
					writeConstantRef(writer, ctx, ConstantRefPos.inner, field.type, arg);
				});
			writer ~= '}';
		},
		(ref immutable Constant.Union it) {
			immutable LowType memberType = ctx.program.allUnions[type.as!(LowType.Union)].members[it.memberIndex];
			writeCreateUnion(writer, ctx, pos, type, it.memberIndex, () {
				writeConstantRef(writer, ctx, ConstantRefPos.inner, memberType, it.arg);
			});
		},
		(immutable Constant.Zero) {
			writeZeroedValue(writer, ctx, type);
		});
}

immutable(WriteExprResult) writePtrToField(
	scope ref Writer writer,
	immutable size_t indent,
	scope ref FunBodyCtx ctx,
	scope ref immutable Locals locals,
	scope ref immutable WriteKind writeKind,
	scope immutable LowType type,
	scope ref immutable LowExprKind.PtrToField a,
) =>
	writeInlineableSingleArg(
		writer, indent, ctx, locals, writeKind, type, a.target,
		(scope ref immutable WriteExprResult recordValue) @safe {
			writer ~= "(&";
			writeTempOrInline(writer, ctx, locals, a.target, recordValue);
			writeRecordFieldRef(writer, ctx, true, targetRecordType(a), a.fieldIndex);
			writer ~= ')';
		});

immutable(WriteExprResult) writeRecordFieldGet(
	scope ref Writer writer,
	immutable size_t indent,
	scope ref FunBodyCtx ctx,
	scope ref immutable Locals locals,
	scope ref immutable WriteKind writeKind,
	scope immutable LowType type,
	ref immutable LowExprKind.RecordFieldGet a,
) =>
	writeInlineableSingleArg(
		writer, indent, ctx, locals, writeKind, type, a.target,
		(scope ref immutable WriteExprResult recordValue) @safe {
			if (!isVoid(type)) {
				writeTempOrInline(writer, ctx, locals, a.target, recordValue);
				writeRecordFieldRef(writer, ctx, targetIsPointer(a), targetRecordType(a), a.fieldIndex);
			}
		});

immutable(WriteExprResult) writeSpecialUnary(
	scope ref Writer writer,
	immutable size_t indent,
	scope ref FunBodyCtx ctx,
	scope ref immutable Locals locals,
	scope ref immutable WriteKind writeKind,
	scope immutable LowType type,
	ref immutable LowExprKind.SpecialUnary a,
) {
	immutable(WriteExprResult) prefix(immutable string prefix) =>
		writeInlineableSingleArg(
			writer, indent, ctx, locals, writeKind, type, a.arg,
			(ref immutable WriteExprResult temp) {
				writer ~= '(';
				writer ~= prefix;
				writeTempOrInline(writer, ctx, locals, a.arg, temp);
				writer ~= ')';
			});

	immutable(WriteExprResult) specialCall(immutable string name) =>
		writeInlineableSingleArg(
			writer, indent, ctx, locals, writeKind, type, a.arg,
			(ref immutable WriteExprResult temp) {
				writer ~= name;
				writer ~= '(';
				writeTempOrInline(writer, ctx, locals, a.arg, temp);
				writer ~= ')';
			});

	final switch (a.kind) {
		case LowExprKind.SpecialUnary.Kind.asAnyPtr:
			return prefix("(uint8_t*) ");
		case LowExprKind.SpecialUnary.Kind.asRef:
		case LowExprKind.SpecialUnary.Kind.enumToIntegral:
		case LowExprKind.SpecialUnary.Kind.toChar8FromNat8:
		case LowExprKind.SpecialUnary.Kind.toFloat32FromFloat64:
		case LowExprKind.SpecialUnary.Kind.toFloat64FromFloat32:
		case LowExprKind.SpecialUnary.Kind.toFloat64FromInt64:
		case LowExprKind.SpecialUnary.Kind.toFloat64FromNat64:
		case LowExprKind.SpecialUnary.Kind.toInt64FromInt16:
		case LowExprKind.SpecialUnary.Kind.toInt64FromInt32:
		case LowExprKind.SpecialUnary.Kind.toNat8FromChar8:
		case LowExprKind.SpecialUnary.Kind.toNat64FromNat8:
		case LowExprKind.SpecialUnary.Kind.toNat64FromNat16:
		case LowExprKind.SpecialUnary.Kind.toNat64FromNat32:
		case LowExprKind.SpecialUnary.Kind.toNat64FromPtr:
		case LowExprKind.SpecialUnary.Kind.toPtrFromNat64:
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
			return writeInlineableSingleArg(
				writer, indent, ctx, locals, writeKind, type, a.arg,
				(ref immutable WriteExprResult temp) {
					writer ~= '(';
					writeCastToType(writer, ctx.ctx, type);
					writeTempOrInline(writer, ctx, locals, a.arg, temp);
					writer ~= ')';
				});
		case LowExprKind.SpecialUnary.Kind.bitwiseNotNat8:
		case LowExprKind.SpecialUnary.Kind.bitwiseNotNat16:
		case LowExprKind.SpecialUnary.Kind.bitwiseNotNat32:
		case LowExprKind.SpecialUnary.Kind.bitwiseNotNat64:
			return prefix("~");
		case LowExprKind.SpecialUnary.Kind.countOnesNat64:
			version (Windows) {
				return specialCall("__popcnt64");
			} else {
				return specialCall("__builtin_popcountl");
			}
		case LowExprKind.SpecialUnary.Kind.deref:
			return prefix("*");
	}
}

void writeZeroedValue(scope ref Writer writer, scope ref immutable Ctx ctx, scope immutable LowType type) {
	type.combinePointer.match!void(
		(immutable LowType.Extern x) {
			writeExternZeroed(writer, ctx, x);
		},
		(immutable LowType.FunPtr) {
			writer ~= "NULL";
		},
		(immutable PrimitiveType it) {
			verify(it != PrimitiveType.void_);
			writer ~= '0';
		},
		(immutable LowPtrCombine) {
			writer ~= "NULL";
		},
		(immutable LowType.Record it) {
			writeCastToType(writer, ctx, type);
			writer ~= '{';
			immutable LowField[] fields = ctx.program.allRecords[it].fields;
			writeWithCommas!LowField(
				writer,
				fields,
				(ref immutable LowField field) =>
					!isVoid(field.type),
				(ref immutable LowField field) {
					writeZeroedValue(writer, ctx, field.type);
				});
			writer ~= '}';
		},
		(immutable LowType.Union) {
			writeCastToType(writer, ctx, type);
			writer ~= "{0}";
		});
}

void writeExternZeroed(
	ref Writer writer,
	scope ref immutable Ctx ctx,
	immutable LowType.Extern type,
) {
	writeCastToType(writer, ctx, immutable LowType(type));
	writer ~= "{{0}}";
}

immutable(WriteExprResult) writeSpecialBinary(
	scope ref Writer writer,
	immutable size_t indent,
	scope ref FunBodyCtx ctx,
	scope ref immutable Locals locals,
	scope ref immutable WriteKind writeKind,
	scope immutable LowType type,
	scope ref immutable LowExprKind.SpecialBinary it,
) {
	immutable(WriteExprResult) arg0() =>
		writeExprTempOrInline(writer, indent, ctx, locals, it.left);
	immutable(WriteExprResult) arg1() =>
		writeExprTempOrInline(writer, indent, ctx, locals, it.right);

	immutable(WriteExprResult) operator(string op) @safe =>
		writeInlineable(
			writer, indent, ctx, locals, writeKind, type, [castNonScope_ref(it).left, castNonScope_ref(it).right],
			(scope immutable WriteExprResult[] args) {
				verify(args.length == 2);
				writer ~= '(';
				writeTempOrInline(writer, ctx, locals, it.left, args[0]);
				writer ~= ' ';
				writer ~= op;
				writer ~= ' ';
				writeTempOrInline(writer, ctx, locals, it.right, args[1]);
				writer ~= ')';
			});

	final switch (it.kind) {
		case LowExprKind.SpecialBinary.Kind.addFloat32:
		case LowExprKind.SpecialBinary.Kind.addFloat64:
		case LowExprKind.SpecialBinary.Kind.addPtrAndNat64:
		case LowExprKind.SpecialBinary.Kind.unsafeAddInt8:
		case LowExprKind.SpecialBinary.Kind.unsafeAddInt16:
		case LowExprKind.SpecialBinary.Kind.unsafeAddInt32:
		case LowExprKind.SpecialBinary.Kind.unsafeAddInt64:
		case LowExprKind.SpecialBinary.Kind.wrapAddNat8:
		case LowExprKind.SpecialBinary.Kind.wrapAddNat16:
		case LowExprKind.SpecialBinary.Kind.wrapAddNat32:
		case LowExprKind.SpecialBinary.Kind.wrapAddNat64:
			return operator("+");
		case LowExprKind.SpecialBinary.Kind.and:
			return writeLogicalOperator(
				writer,
				indent,
				ctx,
				locals,
				writeKind,
				LogicalOperator.and,
				it.left,
				it.right);
		case LowExprKind.SpecialBinary.Kind.bitwiseAndInt8:
		case LowExprKind.SpecialBinary.Kind.bitwiseAndInt16:
		case LowExprKind.SpecialBinary.Kind.bitwiseAndInt32:
		case LowExprKind.SpecialBinary.Kind.bitwiseAndInt64:
		case LowExprKind.SpecialBinary.Kind.bitwiseAndNat8:
		case LowExprKind.SpecialBinary.Kind.bitwiseAndNat16:
		case LowExprKind.SpecialBinary.Kind.bitwiseAndNat32:
		case LowExprKind.SpecialBinary.Kind.bitwiseAndNat64:
			return operator("&");
		case LowExprKind.SpecialBinary.Kind.bitwiseOrInt8:
		case LowExprKind.SpecialBinary.Kind.bitwiseOrInt16:
		case LowExprKind.SpecialBinary.Kind.bitwiseOrInt32:
		case LowExprKind.SpecialBinary.Kind.bitwiseOrInt64:
		case LowExprKind.SpecialBinary.Kind.bitwiseOrNat8:
		case LowExprKind.SpecialBinary.Kind.bitwiseOrNat16:
		case LowExprKind.SpecialBinary.Kind.bitwiseOrNat32:
		case LowExprKind.SpecialBinary.Kind.bitwiseOrNat64:
			return operator("|");
		case LowExprKind.SpecialBinary.Kind.bitwiseXorInt8:
		case LowExprKind.SpecialBinary.Kind.bitwiseXorInt16:
		case LowExprKind.SpecialBinary.Kind.bitwiseXorInt32:
		case LowExprKind.SpecialBinary.Kind.bitwiseXorInt64:
		case LowExprKind.SpecialBinary.Kind.bitwiseXorNat8:
		case LowExprKind.SpecialBinary.Kind.bitwiseXorNat16:
		case LowExprKind.SpecialBinary.Kind.bitwiseXorNat32:
		case LowExprKind.SpecialBinary.Kind.bitwiseXorNat64:
			return operator("^");
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
			return operator("==");
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
			return operator("<");
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
			return operator("*");
		case LowExprKind.SpecialBinary.Kind.orBool:
			return writeLogicalOperator(
				writer,
				indent,
				ctx,
				locals,
				writeKind,
				LogicalOperator.or,
				it.left,
				it.right);
		case LowExprKind.SpecialBinary.Kind.subFloat32:
		case LowExprKind.SpecialBinary.Kind.subFloat64:
		case LowExprKind.SpecialBinary.Kind.subPtrAndNat64:
		case LowExprKind.SpecialBinary.Kind.unsafeSubInt8:
		case LowExprKind.SpecialBinary.Kind.unsafeSubInt16:
		case LowExprKind.SpecialBinary.Kind.unsafeSubInt32:
		case LowExprKind.SpecialBinary.Kind.unsafeSubInt64:
		case LowExprKind.SpecialBinary.Kind.wrapSubNat8:
		case LowExprKind.SpecialBinary.Kind.wrapSubNat16:
		case LowExprKind.SpecialBinary.Kind.wrapSubNat32:
		case LowExprKind.SpecialBinary.Kind.wrapSubNat64:
			return operator("-");
		case LowExprKind.SpecialBinary.Kind.unsafeBitShiftLeftNat64:
			return operator("<<");
		case LowExprKind.SpecialBinary.Kind.unsafeBitShiftRightNat64:
			return operator(">>");
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
			return operator("/");
		case LowExprKind.SpecialBinary.Kind.unsafeModNat64:
			return operator("%");
		case LowExprKind.SpecialBinary.Kind.writeToPtr:
			immutable WriteExprResult temp0 = arg0();
			immutable WriteExprResult temp1 = arg1();
			return writeReturnVoid(writer, indent, ctx, writeKind, () {
				if (!isVoid(it.right.type)) {
					writer ~= "*";
					writeTempOrInline(writer, ctx, locals, it.left, temp0);
					writer ~= " = ";
					writeTempOrInline(writer, ctx, locals, it.right, temp1);
				}
			});
	}
}

enum LogicalOperator { and, or }

struct WriteExprResultAndNested {
	immutable WriteExprResult result;
	immutable WriteKind writeKind;
}

// If we need to make a temporary, have to do that in an outer scope and write to it in an inner scope
immutable(WriteExprResultAndNested) getNestedWriteKind(
	scope ref Writer writer,
	immutable size_t indent,
	scope ref FunBodyCtx ctx,
	scope immutable LowType type,
	return scope ref immutable WriteKind writeKind,
) {
	if (isVoid(type)) {
		verify(writeKind.isA!(WriteKind.Void) || writeKind.isA!(WriteKind.Return));
		return immutable WriteExprResultAndNested(writeExprDone(), writeKind);
	} if (writeKind.isA!(WriteKind.MakeTemp) || writeKind.isA!(WriteKind.InlineOrTemp)) {
		immutable Temp temp = getNextTemp(ctx);
		writeTempDeclare(writer, ctx, type, temp);
		writer ~= ';';
		writeNewline(writer, indent);
		return immutable WriteExprResultAndNested(
			immutable WriteExprResult(temp),
			immutable WriteKind(immutable WriteKind.UseTemp(temp)));
	} else
		return immutable WriteExprResultAndNested(writeExprDone(), writeKind);
}

immutable(WriteExprResult) writeLogicalOperator(
	scope ref Writer writer,
	immutable size_t indent,
	scope ref FunBodyCtx ctx,
	scope ref immutable Locals locals,
	scope ref immutable WriteKind writeKind,
	immutable LogicalOperator operator,
	scope ref immutable LowExpr left,
	scope ref immutable LowExpr right,
) {
	/*
	`a && b` ==> `if (a) { return b; } else { return 0; }`
	`a || b` ==> `if (a) { return 1; } else { return b; }`
	*/
	immutable WriteExprResult cond = writeExprTempOrInline(writer, indent, ctx, locals, left);
	immutable WriteExprResultAndNested nested =
		getNestedWriteKind(writer, indent, ctx, boolType, castNonScope_ref(writeKind));
	writeNewline(writer, indent);
	writer ~= "if (";
	writeTempOrInline(writer, ctx, locals, left, cond);
	writer ~= ") {";
	final switch (operator) {
		case LogicalOperator.and:
			drop(writeExpr(writer, indent + 1, ctx, locals, nested.writeKind, right));
			break;
		case LogicalOperator.or:
			drop(writeNonInlineable(writer, indent + 1, ctx, nested.writeKind, boolType, () {
				writer ~= '1';
			}));
			break;
	}
	writeNewline(writer, indent);
	writer ~= "} else {";
	final switch (operator) {
		case LogicalOperator.and:
			drop(writeNonInlineable(writer, indent + 1, ctx, nested.writeKind, boolType, () {
				writer ~= '0';
			}));
			break;
		case LogicalOperator.or:
			drop(writeExpr(writer, indent + 1, ctx, locals, nested.writeKind, right));
			break;
	}
	writeNewline(writer, indent);
	writer ~= '}';
	return nested.result;
}

immutable(WriteExprResult) writeIf(
	scope ref Writer writer,
	immutable size_t indent,
	scope ref FunBodyCtx ctx,
	scope ref immutable Locals locals,
	scope ref immutable WriteKind writeKind,
	scope immutable LowType type,
	scope ref immutable LowExprKind.If a,
) {
	// TODO: writeExprTempOrInline
	immutable Temp temp0 = writeExprTemp(writer, indent, ctx, locals, a.cond);
	immutable WriteExprResultAndNested nested =
		getNestedWriteKind(writer, indent, ctx, type, castNonScope_ref(writeKind));
	writeNewline(writer, indent);
	writer ~= "if (";
	writeTempRef(writer, temp0);
	writer ~= ") {";
	drop(writeExpr(writer, indent + 1, ctx, locals, nested.writeKind, a.then));
	writeNewline(writer, indent);
	writer ~= "} else {";
	drop(writeExpr(writer, indent + 1, ctx, locals, nested.writeKind, a.else_));
	writeNewline(writer, indent);
	writer ~= '}';
	return nested.result;
}

immutable(WriteExprResult) writeCallFunPtr(
	scope ref Writer writer,
	immutable size_t indent,
	scope ref FunBodyCtx ctx,
	scope ref immutable Locals locals,
	scope ref immutable WriteKind writeKind,
	scope immutable LowType type,
	scope ref immutable LowExprKind.CallFunPtr a,
) {
	immutable WriteExprResult fn = writeExprTempOrInline(writer, indent, ctx, locals, a.funPtr);
	immutable WriteExprResult[] args = writeExprsTempOrInline(writer, indent, ctx, locals, a.args);
	return writeNonInlineable(writer, indent, ctx, writeKind, type, () {
		writeTempOrInline(writer, ctx, locals, a.funPtr, fn);
		writer ~= '(';
		writeTempOrInlines(writer, ctx, locals, a.args, args);
		writer ~= ')';
	});
}

immutable(WriteExprResult) writeLet(
	scope ref Writer writer,
	immutable size_t indent,
	scope ref FunBodyCtx ctx,
	scope ref immutable Locals locals,
	scope ref immutable WriteKind writeKind,
	scope ref immutable LowExprKind.Let a,
) {
	if (!writeKind.isA!(WriteKind.Inline)) {
		if (isVoid(a.local.type))
			writeExprVoid(writer, indent, ctx, locals, a.value);
		else {
			writeDeclareLocal(writer, indent, ctx, *a.local);
			writer ~= ';';
			immutable WriteKind localWriteKind = immutable WriteKind(a.local);
			drop(writeExpr(writer, indent, ctx, locals, localWriteKind, a.value));
			writeNewline(writer, indent);
		}
	}
	return writeExpr(writer, indent, ctx, locals, writeKind, a.then);
}

immutable(WriteExprResult) writeLocalSet(
	scope ref Writer writer,
	immutable size_t indent,
	scope ref FunBodyCtx ctx,
	scope ref immutable Locals locals,
	scope ref immutable WriteKind writeKind,
	scope ref immutable LowExprKind.LocalSet a,
) {
	if (isVoid(a.local.type))
		writeExprVoid(writer, indent, ctx, locals, a.value);
	else {
		immutable WriteKind localWriteKind = immutable WriteKind(a.local);
		drop(writeExpr(writer, indent, ctx, locals, localWriteKind, a.value));
	}
	return writeReturnVoid(writer, indent, ctx, writeKind);
}

immutable(WriteExprResult) writeLoop(
	scope ref Writer writer,
	immutable size_t indent,
	scope ref FunBodyCtx ctx,
	scope ref immutable Locals locals,
	scope ref immutable WriteKind writeKind,
	scope immutable LowType type,
	scope ref immutable LowExprKind.Loop a,
) {
	immutable WriteExprResultAndNested nested =
		getNestedWriteKind(writer, indent, ctx, type, castNonScope_ref(writeKind));

	immutable uint index = nextLoopIndex(locals);
	immutable LoopInfo loopInfo = immutable LoopInfo(index, nested.writeKind);
	immutable Locals innerLocals = addLoop(castNonScope_ref(locals), ptrTrustMe(a), &loopInfo);

	writeNewline(writer, indent);
	writer ~= "for (;;) {";
	writeNewline(writer, indent + 1);

	writeExprVoid(writer, indent + 1, ctx, innerLocals, a.body_);

	writeNewline(writer, indent);
	writer ~= '}';

	if (!nested.writeKind.isA!(WriteKind.Return)) {
		writeNewline(writer, indent);
		writer ~= "__break";
		writer ~= index;
		writer ~= ":";
	}

	return nested.result;
}

immutable(WriteExprResult) writeLoopBreak(
	scope ref Writer writer,
	immutable size_t indent,
	scope ref FunBodyCtx ctx,
	scope ref immutable Locals locals,
	scope ref immutable WriteKind writeKind,
	scope ref immutable LowExprKind.LoopBreak a,
) {
	verify(writeKind.isA!(WriteKind.Void));
	immutable LoopInfo* info = getLoop(locals, a.loop);
	drop(writeExpr(writer, indent, ctx, locals, info.writeKind, a.value));
	if (!info.writeKind.isA!(WriteKind.Return)) {
		writeNewline(writer, indent);
		writer ~= "goto __break";
		writer ~= info.index;
		writer ~= ';';
	}
	return immutable WriteExprResult(immutable WriteExprResult.Done());
}

void writePrimitiveType(scope ref Writer writer, immutable PrimitiveType a) {
	writer ~= () {
		final switch (a) {
			case PrimitiveType.bool_:
				return "uint8_t";
			case PrimitiveType.char8:
				return "char";
			case PrimitiveType.float32:
				return "float";
			case PrimitiveType.float64:
				return "double";
			case PrimitiveType.int8:
				return "int8_t";
			case PrimitiveType.int16:
				return "int16_t";
			case PrimitiveType.int32:
				return "int32_t";
			case PrimitiveType.int64:
				return "int64_t";
			case PrimitiveType.nat8:
				return "uint8_t";
			case PrimitiveType.nat16:
				return "uint16_t";
			case PrimitiveType.nat32:
				return "uint32_t";
			case PrimitiveType.nat64:
				return "uint64_t";
			case PrimitiveType.void_:
				return "void";
		}
	}();
}
