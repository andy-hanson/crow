module backend.writeToC;

@safe @nogc pure nothrow:

import backend.mangle :
	buildMangledNames,
	MangledNames,
	writeConstantArrStorageName,
	writeConstantPointerStorageName,
	writeLowFunMangledName,
	writeLowLocalName,
	writeLowVarMangledName,
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
	isGeneratedMain,
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
	LowPtrCombine,
	LowProgram,
	LowRecord,
	LowVar,
	LowVarIndex,
	LowType,
	LowUnion,
	PointerTypeAndConstantsLow,
	PrimitiveType,
	targetIsPointer,
	targetRecordType,
	UpdateParam;
import model.model : EnumValue, name, Program;
import model.typeLayout : sizeOfType, typeSizeBytes;
import util.alloc.alloc : Alloc, TempAlloc;
import util.col.arr : empty, only, sizeEq;
import util.col.arrUtil : every, exists, map, zip;
import util.col.map : mustGetAt;
import util.col.fullIndexMap : FullIndexMap, fullIndexMapEach, fullIndexMapEachKey;
import util.col.stackMap : StackMap, stackMapAdd, stackMapMustGet;
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

SafeCStr writeToC(
	ref Alloc alloc,
	ref TempAlloc tempAlloc,
	in AllSymbols allSymbols,
	in Program modelProgram,
	in LowProgram program,
) {
	Writer writer = Writer(ptrTrustMe(alloc));

	writer ~= "#include <tgmath.h>\n"; // Implements functions in 'tgmath.crow'
	writer ~= "#include <stddef.h>\n"; // for NULL
	writer ~= "#include <stdint.h>\n";
	version (Windows) {
		writer ~= "unsigned short __popcnt16(unsigned short value);\n";
		writer ~= "unsigned int __popcnt(unsigned int value);\n";
		writer ~= "unsigned __int64 __popcnt64(unsigned __int64 value);\n";
	}

	Ctx ctx = Ctx(
		ptrTrustMe(modelProgram), ptrTrustMe(program), buildMangledNames(alloc, ptrTrustMe(allSymbols), program));

	writeStructs(alloc, writer, ctx);

	fullIndexMapEach!(LowFunIndex, LowFun)(program.allFuns, (LowFunIndex funIndex, ref LowFun fun) {
		writeFunDeclaration(writer, ctx, funIndex, fun);
	});

	writeConstants(writer, ctx, program.allConstants);
	writeVars(writer, ctx, program.vars);

	fullIndexMapEach!(LowFunIndex, LowFun)(
		program.allFuns,
		(LowFunIndex funIndex, ref LowFun fun) {
			writeFunDefinition(writer, tempAlloc, ctx, funIndex, fun);
		});

	return finishWriterToSafeCStr(writer);
}

private:

void writeConstants(scope ref Writer writer, in Ctx ctx, in AllConstantsLow allConstants) {
	foreach (ref ArrTypeAndConstantsLow a; allConstants.arrs) {
		foreach (size_t i, Constant[] elements; a.constants) {
			declareConstantArrStorage(writer, ctx, a.arrType, a.elementType, i, elements.length);
			writer ~= ";\n";
		}
	}

	foreach (ref PointerTypeAndConstantsLow a; allConstants.pointers) {
		foreach (size_t i; 0 .. a.constants.length) {
			declareConstantPointerStorage(writer, ctx, a.pointeeType, i);
			writer ~= ";\n";
		}
	}

	foreach (ref ArrTypeAndConstantsLow a; allConstants.arrs) {
		foreach (size_t i, Constant[] elements; a.constants) {
			declareConstantArrStorage(writer, ctx, a.arrType, a.elementType, i, elements.length);
			writer ~= " = ";
			if (isChar8(a.elementType)) {
				writer ~= '"';
				foreach (Constant element; elements) {
					char x = cast(char) element.as!(Constant.Integral).value;
					if (x == '?')
						// avoid trigraphs
						writer ~= "\\?";
					else
						writeEscapedChar_inner(writer, x);
				}
				writer ~= '"';
			} else {
				writer ~= '{';
				writeWithCommas!Constant(writer, elements, (in Constant element) {
					writeConstantRef(writer, ctx, ConstantRefPos.inner, a.elementType, element);
				});
				writer ~= '}';
			}
			writer ~= ";\n";
		}
	}

	foreach (ref PointerTypeAndConstantsLow a; allConstants.pointers) {
		foreach (size_t i, Constant pointee; a.constants) {
			declareConstantPointerStorage(writer, ctx, a.pointeeType, i);
			writer ~= " = ";
			writeConstantRef(writer, ctx, ConstantRefPos.inner, a.pointeeType, pointee);
			writer ~= ";\n";
		}
	}
}

void writeVars(scope ref Writer writer, in Ctx ctx, in FullIndexMap!(LowVarIndex, LowVar) vars) {
	fullIndexMapEach!(LowVarIndex, LowVar)(vars, (LowVarIndex varIndex, ref LowVar var) {
		writer ~= () {
			final switch (var.kind) {
				case LowVar.Kind.externGlobal:
					return "extern ";
				case LowVar.Kind.global:
					return "static ";
				case LowVar.Kind.threadLocal:
					return "static _Thread_local ";
			}
		}();
		writeType(writer, ctx, var.type);
		writer ~= ' ';
		writeLowVarMangledName(writer, ctx.mangledNames, varIndex, var);
		writer ~= ";\n";
	});
}

void declareConstantArrStorage(
	scope ref Writer writer,
	in Ctx ctx,
	LowType.Record arrType,
	in LowType elementType,
	size_t index,
	size_t nElements,
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
	in Ctx ctx,
	in LowType pointeeType,
	size_t index,
) {
	//TODO: some day we may support non-record pointee?
	writeRecordType(writer, ctx, pointeeType.as!(LowType.Record));
	writer ~= ' ';
	writeConstantPointerStorageName(writer, ctx.mangledNames, ctx.program, pointeeType, index);
}

const struct Ctx {
	@safe @nogc pure nothrow:

	Program* modelProgramPtr;
	LowProgram* programPtr;
	MangledNames mangledNames;

	ref Program modelProgram() return scope =>
		*modelProgramPtr;
	ref LowProgram program() return scope =>
		*programPtr;
	ref const(AllSymbols) allSymbols() return scope =>
		*mangledNames.allSymbols;
}

struct FunBodyCtx {
	@safe @nogc pure nothrow:

	TempAlloc* tempAllocPtr;
	const Ctx* ctxPtr;
	immutable bool hasTailRecur;
	immutable LowFunIndex curFun;
	size_t nextTemp;

	ref TempAlloc tempAlloc() scope =>
		*castNonScope(tempAllocPtr);

	ref Ctx ctx() return scope const =>
		*ctxPtr;

	ref LowProgram program() return scope const =>
		ctx.program;

	ref MangledNames mangledNames() return scope const =>
		ctx.mangledNames;
}

size_t nextLoopIndex(ref FunBodyCtx ctx) {
	size_t res = ctx.nextTemp;
	ctx.nextTemp++;
	return res;
}

Temp getNextTemp(ref FunBodyCtx ctx) {
	Temp temp = Temp(ctx.nextTemp);
	ctx.nextTemp++;
	return temp;
}

void writeType(scope ref Writer writer, in Ctx ctx, in LowType t) {
	t.combinePointer.matchIn!void(
		(in LowType.Extern it) {
			writer ~= "struct ";
			writeStructMangledName(writer, ctx.mangledNames, ctx.program.allExternTypes[it].source);
		},
		(in LowType.FunPtr it) {
			writeStructMangledName(writer, ctx.mangledNames, ctx.program.allFunPtrTypes[it].source);
		},
		(in PrimitiveType it) {
			writePrimitiveType(writer, it);
		},
		(in LowPtrCombine it) {
			writeType(writer, ctx, it.pointee);
			writer ~= '*';
		},
		(in LowType.Record it) {
			writeRecordType(writer, ctx, it);
		},
		(in LowType.Union it) {
			writer ~= "struct ";
			writeStructMangledName(writer, ctx.mangledNames, ctx.program.allUnions[it].source);
		});
}

void writeRecordType(scope ref Writer writer, in Ctx ctx, LowType.Record a) {
	writer ~= "struct ";
	writeRecordName(writer, ctx.mangledNames, ctx.program, a);
}

void writeCastToType(scope ref Writer writer, in Ctx ctx, in LowType type) {
	writer ~= '(';
	writeType(writer, ctx, type);
	writer ~= ") ";
}

void writeParamDecl(scope ref Writer writer, in Ctx ctx, in LowLocal a) {
	writeType(writer, ctx, a.type);
	writer ~= ' ';
	writeLowLocalName(writer, ctx.mangledNames, a);
}

void writeStructHead(scope ref Writer writer, in Ctx ctx, in ConcreteStruct* source) {
	writer ~= "struct ";
	writeStructMangledName(writer, ctx.mangledNames, source);
	writer ~= " {";
}

void writeStructEnd(scope ref Writer writer) {
	writer ~= "\n};\n";
}

void writeRecord(scope ref Writer writer, in Ctx ctx, in LowRecord a) {
	if (a.packed) {
		version (Windows) {
			writer ~= "__pragma(pack(push, 1))\n";
		}
	}
	writeStructHead(writer, ctx, a.source);
	foreach (ref LowField field; a.fields) {
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

void writeUnion(scope ref Writer writer, in Ctx ctx, in LowUnion a) {
	writeStructHead(writer, ctx, a.source);
	writer ~= "\n\tuint64_t kind;";
	bool isBuiltin = body_(*a.source).isA!(ConcreteStructBody.Builtin);
	if (isBuiltin) verify(body_(*a.source).as!(ConcreteStructBody.Builtin).kind == BuiltinStructKind.fun);
	if (isBuiltin || exists!LowType(a.members, (in LowType member) => !isVoid(member))) {
		writer ~= "\n\tunion {";
		foreach (size_t memberIndex, LowType member; a.members) {
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
			every!LowType(a.members, (in LowType member) => typeSizeBytes(ctx.program, member) < 8))
			writer ~= "\n\t\tuint64_t __ensureSizeIs16;";
		writer ~= "\n\t};";
	}
	writeStructEnd(writer);
}

void declareStruct(scope ref Writer writer, in Ctx ctx, in ConcreteStruct* source) {
	writer ~= "struct ";
	writeStructMangledName(writer, ctx.mangledNames, source);
	writer ~= ";\n";
}

void staticAssertStructSize(scope ref Writer writer, in Ctx ctx, in LowType type, TypeSize size) {
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

void writeStructs(ref Alloc alloc, scope ref Writer writer, in Ctx ctx) {
	scope TypeWriters writers = TypeWriters(
		(ConcreteStruct* it) {
			declareStruct(writer, ctx, it);
		},
		(ConcreteStruct* source, in Opt!ElementAndCount ec) {
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
		(LowType.FunPtr, in LowFunPtrType funPtr) {
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
					(in LowType paramType) =>
						!isVoid(paramType),
					(in LowType paramType) {
						writeType(writer, ctx, paramType);
					});
			writer ~= ");\n";
		},
		(LowType.Record, in LowRecord record) {
			writeRecord(writer, ctx, record);
		},
		(LowType.Union, in LowUnion union_) {
			writeUnion(writer, ctx, union_);
		});
	writeTypes(alloc, ctx.program, writers);

	writer ~= '\n';

	void assertSize(LowType t) {
		staticAssertStructSize(writer, ctx, t, sizeOfType(ctx.program, t));
	}

	//TODO: use a temp alloc
	fullIndexMapEachKey!(LowType.Record, LowRecord)(ctx.program.allRecords, (LowType.Record it) {
		assertSize(LowType(it));
	});
	fullIndexMapEachKey!(LowType.Union, LowUnion)(ctx.program.allUnions, (LowType.Union it) {
		assertSize(LowType(it));
	});
}

void writeFunReturnTypeNameAndParams(scope ref Writer writer, in Ctx ctx, LowFunIndex funIndex, in LowFun fun) {
	if (isVoid(fun.returnType))
		writer ~= "void";
	else
		writeType(writer, ctx, fun.returnType);
	writer ~= ' ';
	writeLowFunMangledName(writer, ctx.mangledNames, funIndex, fun);
	writer ~= '(';
	if (every!LowLocal(fun.params, (in LowLocal x) => isVoid(x.type)))
		writer ~= "void";
	else
		writeWithCommas!LowLocal(
			writer,
			fun.params,
			(in LowLocal x) =>
				!isVoid(x.type),
			(in LowLocal x) {
				writeParamDecl(writer, ctx, x);
			});
	writer ~= ')';
}

void writeFunDeclaration(scope ref Writer writer, in Ctx ctx, LowFunIndex funIndex, in LowFun fun) {
	if (fun.body_.isA!(LowFunBody.Extern))
		writer ~= "extern ";
	else if (!isGeneratedMain(fun))
		writer ~= "static ";
	writeFunReturnTypeNameAndParams(writer, ctx, funIndex, fun);
	writer ~= ";\n";
}

void writeFunDefinition(
	scope ref Writer writer,
	ref TempAlloc tempAlloc,
	in Ctx ctx,
	LowFunIndex funIndex,
	in LowFun fun,
) {
	fun.body_.matchIn!void(
		(in LowFunBody.Extern) {
			// declaration is enough
		},
		(in LowFunExprBody x) {
			// TODO: only if a flag is set
			writer ~= "/* ";
			writeFunName(writer, ctx.allSymbols, ctx.modelProgram, ctx.program, funIndex);
			writer ~= ' ';
			writeFunSig(writer, ctx.allSymbols, ctx.modelProgram, ctx.program, fun);
			writer ~= " */\n";
			writeFunWithExprBody(writer, tempAlloc, ctx, funIndex, fun, x);
		});
}

//TODO: not @trusted
@trusted void writeFunWithExprBody(
	scope ref Writer writer,
	ref TempAlloc tempAlloc,
	in Ctx ctx,
	LowFunIndex funIndex,
	in LowFun fun,
	in LowFunExprBody body_,
) {
	if (!isGeneratedMain(fun)) writer ~= "static ";
	writeFunReturnTypeNameAndParams(writer, ctx, funIndex, fun);
	writer ~= " {";
	if (body_.hasTailRecur)
		writer ~= "\n\ttop:;"; // Need ';' so it labels a statement
	FunBodyCtx bodyCtx = FunBodyCtx(ptrTrustMe(tempAlloc), ptrTrustMe(ctx), body_.hasTailRecur, funIndex, 0);
	WriteKind writeKind = WriteKind(WriteKind.Return());
	Locals locals;
	drop(writeExpr(writer, 1, bodyCtx, locals, writeKind, body_.expr));
	writer ~= "\n}\n";
}

immutable struct Temp {
	size_t index;
}

// If expr, we refused to write to a temp because this can be written inline
immutable struct WriteExprResult {
	// Meaning depends on the WriteKind
	// If the write kind was TempOrInline, this indicates that it should be done inline.
	immutable struct Done {
		// Args (not written inline) prepared for writing inline.
		WriteExprResult[] args;
	}

	mixin Union!(Done, Temp);
}

WriteExprResult writeExprDone() =>
	WriteExprResult(WriteExprResult.Done([]));

void writeTempDeclare(
	scope ref Writer writer,
	scope ref FunBodyCtx ctx,
	in LowType type,
	Temp temp,
) {
	writeType(writer, ctx.ctx, type);
	writer ~= ' ';
	writeTempRef(writer, temp);
}

void writeTempRef(scope ref Writer writer, in Temp a) {
	writer ~= "_";
	writer ~= a.index;
}

void writeTempOrInline(
	scope ref Writer writer,
	scope ref FunBodyCtx ctx,
	in Locals locals,
	in LowExpr e,
	in WriteExprResult a,
) {
	a.matchIn!void(
		(in WriteExprResult.Done it) {
			WriteKind writeKind = WriteKind(WriteKind.Inline(it.args));
			WriteExprResult res = writeExpr(writer, 0, ctx, locals, writeKind, e);
			verify(empty(res.as!(WriteExprResult.Done).args));
		},
		(in Temp it) {
			writeTempRef(writer, it);
		});
}

void writeTempOrInlines(
	scope ref Writer writer,
	scope ref FunBodyCtx ctx,
	in Locals locals,
	in LowExpr[] exprs,
	in WriteExprResult[] args,
) {
	verify(sizeEq(exprs, args));
	writeWithCommasZip!(LowExpr, WriteExprResult)(
		writer,
		exprs,
		args,
		(in LowExpr expr, in WriteExprResult) =>
			!isVoid(expr.type),
		(in expr, in WriteExprResult arg) {
			writeTempOrInline(writer, ctx, locals, expr, arg);
		});
}

void writeDeclareLocal(scope ref Writer writer, size_t indent, scope ref FunBodyCtx ctx, in LowLocal local) {
	writeNewline(writer, indent);
	writeType(writer, ctx.ctx, local.type);
	writer ~= ' ';
	writeLowLocalName(writer, ctx.mangledNames, local);
}

immutable struct WriteKind {
	immutable struct Inline {
		WriteExprResult[] args;
	}
	// May write a temp now, or delay and write inline when needed.
	immutable struct InlineOrTemp {}
	immutable struct MakeTemp {}
	immutable struct Return {}
	immutable struct UseTemp {
		Temp temp;
	}
	// Simple statement, don't return anything
	immutable struct Void {}

	mixin Union!(Inline, InlineOrTemp, LowLocal*, LowVarIndex, MakeTemp, Return, UseTemp, Void);
}
static assert(WriteKind.sizeof == size_t.sizeof * 3);

WriteExprResult[] writeExprsTempOrInline(
	scope ref Writer writer,
	size_t indent,
	scope ref FunBodyCtx ctx,
	in Locals locals,
	in LowExpr[] args,
) =>
	map(ctx.tempAlloc, args, (ref LowExpr arg) =>
		writeExprTempOrInline(writer, indent, ctx, locals, arg));

Temp writeExprTemp(
	scope ref Writer writer,
	size_t indent,
	scope ref FunBodyCtx ctx,
	in Locals locals,
	in LowExpr expr,
) {
	WriteKind writeKind = WriteKind(WriteKind.MakeTemp());
	return writeExpr(writer, indent, ctx, locals, writeKind, expr).as!Temp;
}

void writeExprVoid(
	scope ref Writer writer,
	size_t indent,
	scope ref FunBodyCtx ctx,
	in Locals locals,
	in LowExpr expr,
) {
	WriteKind writeKind = WriteKind(WriteKind.Void());
	drop(writeExpr(writer, indent, ctx, locals, writeKind, expr));
}

WriteExprResult writeExprTempOrInline(
	scope ref Writer writer,
	size_t indent,
	scope ref FunBodyCtx ctx,
	in Locals locals,
	in LowExpr expr,
) {
	WriteKind writeKind = WriteKind(WriteKind.InlineOrTemp());
	return writeExpr(writer, indent, ctx, locals, writeKind, expr);
}

immutable struct LoopInfo {
	size_t index;
	WriteKind writeKind;
}

// Currently only needed to map loop to a unique (within the function) identifier
alias Locals = StackMap!(LowExprKind.Loop*, LoopInfo*);
alias addLoop = stackMapAdd!(LowExprKind.Loop*, LoopInfo*);
alias getLoop = stackMapMustGet!(LowExprKind.Loop*, LoopInfo*);

WriteExprResult writeExpr(
	scope ref Writer writer,
	size_t indent,
	scope ref FunBodyCtx ctx,
	in Locals locals,
	in WriteKind writeKind,
	in LowExpr expr,
) {
	LowType type = expr.type;
	WriteExprResult nonInlineable(in void delegate() @safe @nogc pure nothrow cb) {
		return writeNonInlineable(writer, indent, ctx, writeKind, type, cb);
	}
	WriteExprResult inlineable(
		in LowExpr[] args,
		in void delegate(in WriteExprResult[]) @safe @nogc pure nothrow inline,
	) {
		return writeInlineable(writer, indent, ctx, locals, writeKind, type, args, inline);
	}
	WriteExprResult inlineableSingleArg(
		in LowExpr arg,
		in void delegate(in WriteExprResult) @safe @nogc pure nothrow inline,
	) {
		return writeInlineableSingleArg(writer, indent, ctx, locals, writeKind, type, arg, inline);
	}
	WriteExprResult inlineableSimple(in void delegate() @safe @nogc pure nothrow inline) {
		return writeInlineableSimple(writer, indent, ctx, locals, writeKind, type, inline);
	}

	return expr.kind.matchIn!WriteExprResult(
		(in LowExprKind.Call it) =>
			writeCallExpr(writer, indent, ctx, locals, writeKind, type, it),
		(in LowExprKind.CallFunPtr it) =>
			writeCallFunPtr(writer, indent, ctx, locals, writeKind, type, it),
		(in LowExprKind.CreateRecord it) =>
			inlineable(it.args, (in WriteExprResult[] args) {
				writeCastToType(writer, ctx.ctx, type);
				writer ~= '{';
				writeTempOrInlines(writer, ctx, locals, it.args, args);
				writer ~= '}';
			}),
		(in LowExprKind.CreateUnion it) =>
			inlineableSingleArg(it.arg, (in WriteExprResult arg) {
				writeCreateUnion(writer, ctx.ctx, ConstantRefPos.outer, type, it.memberIndex, () {
					writeTempOrInline(writer, ctx, locals, it.arg, arg);
				});
			}),
		(in LowExprKind.If it) =>
			writeIf(writer, indent, ctx, locals, writeKind, type, it),
		(in LowExprKind.InitConstants) =>
			// writeToC doesn't need to do anything in 'init-constants'
			writeReturnVoid(writer, indent, ctx, writeKind),
		(in LowExprKind.Let it) =>
			writeLet(writer, indent, ctx, locals, writeKind, it),
		(in LowExprKind.LocalGet it) =>
			inlineableSimple(() {
				writeLowLocalName(writer, ctx.mangledNames, *it.local);
			}),
		(in LowExprKind.LocalSet it) =>
			writeLocalSet(writer, indent, ctx, locals, writeKind, it),
		(in LowExprKind.Loop it) =>
			writeLoop(writer, indent, ctx, locals, writeKind, type, it),
		(in LowExprKind.LoopBreak it) =>
			writeLoopBreak(writer, indent, ctx, locals, writeKind, it),
		(in LowExprKind.LoopContinue it) {
			// Do nothing, continuing the loop is implicit in C
			verify(writeKind.isA!(WriteKind.Void));
			return WriteExprResult(WriteExprResult.Done());
		},
		(in LowExprKind.MatchUnion it) =>
			writeMatchUnion(writer, indent, ctx, locals, writeKind, type, it),
		(in LowExprKind.PtrCast it) =>
			inlineableSingleArg(it.target, (in WriteExprResult arg) {
				writer ~= '(';
				writeCastToType(writer, ctx.ctx, type);
				writeTempOrInline(writer, ctx, locals, it.target, arg);
				writer ~= ')';
			}),
		(in LowExprKind.PtrToField it) =>
			writePtrToField(writer, indent, ctx, locals, writeKind, type, it),
		(in LowExprKind.PtrToLocal it) =>
			inlineableSimple(() {
				writer ~= '&';
				writeLowLocalName(writer, ctx.mangledNames, *it.local);
			}),
		(in LowExprKind.RecordFieldGet it) =>
			writeRecordFieldGet(writer, indent, ctx, locals, writeKind, type, it),
		(in LowExprKind.RecordFieldSet it) {
			WriteExprResult recordValue = writeExprTempOrInline(writer, indent, ctx, locals, it.target);
			WriteExprResult fieldValue = writeExprTempOrInline(writer, indent, ctx, locals, it.value);
			return writeReturnVoid(writer, indent, ctx, writeKind, () {
				writeTempOrInline(writer, ctx, locals, it.target, recordValue);
				writeRecordFieldRef(writer, ctx, targetIsPointer(it), targetRecordType(it), it.fieldIndex);
				writer ~= " = ";
				writeTempOrInline(writer, ctx, locals, it.value, fieldValue);
			});
		},
		(in LowExprKind.SizeOf it) =>
			inlineableSimple(() {
				writer ~= "sizeof(";
				writeType(writer, ctx.ctx, it.type);
				writer ~= ')';
			}),
		(in Constant it) =>
			inlineableSimple(() {
				writeConstantRef(writer, ctx.ctx, ConstantRefPos.outer, type, it);
			}),
		(in LowExprKind.SpecialUnary it) =>
			writeSpecialUnary(writer, indent, ctx, locals, writeKind, type, it),
		(in LowExprKind.SpecialBinary it) =>
			writeSpecialBinary(writer, indent, ctx, locals, writeKind, type, it),
		(in LowExprKind.SpecialTernary) =>
			unreachable!WriteExprResult,
		(in LowExprKind.Switch0ToN it) =>
			writeSwitch(
				writer, indent, ctx, locals, writeKind, type, it.value, it.cases,
				(size_t i) => EnumValue(i)),
		(in LowExprKind.SwitchWithValues it) =>
			writeSwitch(
				writer, indent, ctx, locals, writeKind, type, it.value, it.cases,
				(size_t i) => it.values[i]),
		(in LowExprKind.TailRecur it) {
			verify(writeKind.isA!(WriteKind.Return));
			writeTailRecur(writer, indent, ctx, locals, it);
			return writeExprDone();
		},
		(in LowExprKind.VarGet x) =>
			inlineableSimple(() {
				writeLowVarMangledName(writer, ctx.mangledNames, x.varIndex, ctx.program.vars[x.varIndex]);
			}),
		(in LowExprKind.VarSet x) {
			WriteKind varWriteKind = WriteKind(x.varIndex);
			drop(writeExpr(writer, indent, ctx, locals, varWriteKind, *x.value));
			return writeReturnVoid(writer, indent, ctx, writeKind);
		});
}

WriteExprResult writeNonInlineable(
	scope ref Writer writer,
	size_t indent,
	scope ref FunBodyCtx ctx,
	in WriteKind writeKind,
	in LowType type,
	in void delegate() @safe @nogc pure nothrow cb,
) {
	if (!writeKind.isA!(WriteKind.Inline))
		writeNewline(writer, indent);
	WriteExprResult makeTemp() {
		Temp temp = getNextTemp(ctx);
		if (!isVoid(type)) {
			writeTempDeclare(writer, ctx, type, temp);
			writer ~= " = ";
		}
		return WriteExprResult(temp);
	}
	WriteExprResult res = castNonScope_ref(writeKind).matchIn!WriteExprResult(
		(in WriteKind.Inline) =>
			writeExprDone(),
		(in WriteKind.InlineOrTemp) =>
			makeTemp(),
		(in LowLocal x) {
			writeLowLocalName(writer, ctx.mangledNames, x);
			writer ~= " = ";
			return writeExprDone();
		},
		(in LowVarIndex x) {
			writeLowVarMangledName(writer, ctx.mangledNames, x, ctx.program.vars[x]);
			writer ~= " = ";
			return writeExprDone();
		},
		(in MakeTemp) =>
			makeTemp(),
		(in WriteKind.Return) {
			writer ~= "return ";
			return writeExprDone();
		},
		(in WriteKind.UseTemp x) {
			writeTempRef(writer, x.temp);
			writer ~= " = ";
			return writeExprDone();
		},
		(in WriteKind.Void) =>
			writeExprDone());
	cb();
	if (!writeKind.isA!(WriteKind.Inline))
		writer ~= ';';
	return res;
}

WriteExprResult writeInlineable(
	scope ref Writer writer,
	size_t indent,
	scope ref FunBodyCtx ctx,
	in Locals locals,
	in WriteKind writeKind,
	in LowType type,
	in LowExpr[] args,
	in void delegate(in WriteExprResult[]) @safe @nogc pure nothrow inline,
) {
	if (writeKind.isA!(WriteKind.InlineOrTemp))
		return WriteExprResult(WriteExprResult.Done(writeExprsTempOrInline(writer, indent, ctx, locals, args)));
	else if (writeKind.isA!(WriteKind.Inline)) {
		inline(writeKind.as!(WriteKind.Inline).args);
		return writeExprDone();
	} else {
		WriteExprResult[] argTemps = writeExprsTempOrInline(writer, indent, ctx, locals,args);
		return writeNonInlineable(writer, indent, ctx, writeKind, type, () {
			inline(argTemps);
		});
	}
}

WriteExprResult writeInlineableSingleArg(
	scope ref Writer writer,
	size_t indent,
	scope ref FunBodyCtx ctx,
	in Locals locals,
	in WriteKind writeKind,
	in LowType type,
	in LowExpr arg,
	in void delegate(in WriteExprResult) @safe @nogc pure nothrow inline,
) =>
	writeInlineable(
		writer, indent, ctx, locals, writeKind, type, [castNonScope_ref(arg)],
		(in WriteExprResult[] args) {
			inline(only(args));
		});

WriteExprResult writeInlineableSimple(
	scope ref Writer writer,
	size_t indent,
	scope ref FunBodyCtx ctx,
	in Locals locals,
	in WriteKind writeKind,
	in LowType type,
	in void delegate() @safe @nogc pure nothrow inline,
) =>
	writeInlineable(writer, indent, ctx, locals, writeKind, type, [], (in WriteExprResult[]) {
		if (!isVoid(type))
			inline();
	});

WriteExprResult writeReturnVoid(
	scope ref Writer writer,
	size_t indent,
	scope ref FunBodyCtx ctx,
	in WriteKind writeKind,
) =>
	writeReturnVoid(writer, indent, ctx, writeKind, null);

WriteExprResult writeReturnVoid(
	scope ref Writer writer,
	size_t indent,
	scope ref FunBodyCtx ctx,
	in WriteKind writeKind,
	in void delegate() @safe @nogc pure nothrow cb,
) =>
	castNonScope_ref(writeKind).matchIn!WriteExprResult(
		(in WriteKind.Inline) =>
			unreachable!WriteExprResult,
		(in WriteKind.InlineOrTemp) =>
			unreachable!WriteExprResult,
		(in LowLocal) =>
			unreachable!WriteExprResult,
		(in LowVarIndex) =>
			unreachable!WriteExprResult,
		(in WriteKind.MakeTemp) =>
			unreachable!WriteExprResult,
		(in WriteKind.Return) {
			if (cb != null) {
				writeNewline(writer, indent);
				cb();
			}
			writer ~= ';';
			writeNewline(writer, indent);
			writer ~= "return;";
			return writeExprDone();
		},
		(in WriteKind.UseTemp) =>
			unreachable!WriteExprResult,
		(in WriteKind.Void) {
			if (cb != null) {
				writeNewline(writer, indent);
				cb();
				writer ~= ';';
			}
			return writeExprDone();
		});

WriteExprResult writeCallExpr(
	scope ref Writer writer,
	size_t indent,
	scope ref FunBodyCtx ctx,
	in Locals locals,
	in WriteKind writeKind,
	in LowType type,
	in LowExprKind.Call a,
) {
	WriteExprResult[] args = writeExprsTempOrInline(writer, indent, ctx, locals, a.args);
	return writeNonInlineable(writer, indent, ctx, writeKind, type, () {
		writeLowFunMangledName(writer, ctx.mangledNames, a.called, ctx.program.allFuns[a.called]);
		writer ~= '(';
		writeTempOrInlines(writer, ctx, locals, a.args, args);
		writer ~= ')';
	});
}

void writeTailRecur(
	scope ref Writer writer,
	size_t indent,
	scope ref FunBodyCtx ctx,
	in Locals locals,
	in LowExprKind.TailRecur a,
) {
	WriteExprResult[] newValues =
		map(ctx.tempAlloc, a.updateParams, (ref UpdateParam updateParam) =>
			writeExprTempOrInline(writer, indent, ctx, locals, updateParam.newValue));
	zip!(UpdateParam, WriteExprResult)(
		a.updateParams,
		newValues,
		(ref UpdateParam updateParam, ref WriteExprResult newValue) {
			if (!isVoid(updateParam.param.type)) {
				writeNewline(writer, indent);
				writeLowLocalName(writer, ctx.mangledNames, *updateParam.param);
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
	in Ctx ctx,
	ConstantRefPos pos,
	in LowType type,
	size_t memberIndex,
	in void delegate() @safe @nogc pure nothrow cbWriteMember,
) {
	if (pos == ConstantRefPos.outer) writeCastToType(writer, ctx, type);
	writer ~= '{';
	writer ~= memberIndex;
	LowType memberType = ctx.program.allUnions[type.as!(LowType.Union)].members[memberIndex];
	if (!isVoid(memberType)) {
		writer ~= ", .as";
		writer ~= memberIndex;
		writer ~= " = ";
		cbWriteMember();
	}
	writer ~= '}';
}

void writeFunPtr(scope ref Writer writer, in Ctx ctx, LowFunIndex a) {
	writeLowFunMangledName(writer, ctx.mangledNames, a, ctx.program.allFuns[a]);
}

WriteExprResult writeMatchUnion(
	scope ref Writer writer,
	size_t indent,
	scope ref FunBodyCtx ctx,
	in Locals locals,
	in WriteKind writeKind,
	in LowType type,
	in LowExprKind.MatchUnion a,
) {
	Temp matchedValue = writeExprTemp(writer, indent, ctx, locals, a.matchedValue);
	WriteExprResultAndNested nested = getNestedWriteKind(writer, indent, ctx, type, castNonScope_ref(writeKind));
	writeNewline(writer, indent);
	writer ~= "switch (";
	writeTempRef(writer, matchedValue);
	writer ~= ".kind) {";
	foreach (size_t caseIndex, ref LowExprKind.MatchUnion.Case case_; a.cases) {
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
	size_t indent,
	scope ref FunBodyCtx ctx,
	in Locals locals,
	in WriteKind writeKind,
	in LowType type,
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
WriteExprResult writeSwitch(
	scope ref Writer writer,
	size_t indent,
	scope ref FunBodyCtx ctx,
	in Locals locals,
	in WriteKind writeKind,
	in LowType type, // type returned by the switch
	in LowExpr value,
	in LowExpr[] cases,
	in EnumValue delegate(size_t) @safe @nogc pure nothrow getValue,
) {
	WriteExprResult valueResult = writeExprTempOrInline(writer, indent, ctx, locals, value);
	WriteExprResultAndNested nested = getNestedWriteKind(writer, indent, ctx, type, castNonScope_ref(writeKind));
	writer ~= "switch (";
	writeTempOrInline(writer, ctx, locals, value, valueResult);
	writer ~= ") {";
	foreach (size_t caseIndex, ref LowExpr case_; cases) {
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

bool isSignedIntegral(PrimitiveType a) {
	final switch (a) {
		case PrimitiveType.float32:
		case PrimitiveType.float64:
		case PrimitiveType.void_:
			return unreachable!bool;
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
	in FunBodyCtx ctx,
	bool targetIsPointer,
	LowType.Record record,
	size_t fieldIndex,
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
	in Ctx ctx,
	ConstantRefPos pos,
	in LowType type,
	in Constant a,
) {
	a.matchIn!void(
		(in Constant.ArrConstant it) {
			if (pos == ConstantRefPos.outer) writeCastToType(writer, ctx, type);
			size_t size = ctx.program.allConstants.arrs[it.typeIndex].constants[it.index].length;
			writer ~= '{';
			writer ~= size;
			writer ~= ", ";
			if (size == 0)
				writer ~= "NULL";
			else
				writeConstantArrStorageName(writer, ctx.mangledNames, ctx.program, type.as!(LowType.Record), it.index);
			writer ~= '}';
		},
		(in Constant.CString it) {
			writer ~= '"';
			eachChar(ctx.program.allConstants.cStrings[it.index], (char c) {
				writeEscapedChar_inner(writer, c);
			});
			writer ~= '"';
		},
		(in Constant.Float it) {
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
		(in Constant.FunPtr it) {
			bool isRawPtr = type.match!bool(
				(LowType.Extern) => unreachable!bool,
				(LowType.FunPtr) => false,
				(PrimitiveType _) => unreachable!bool,
				(LowType.PtrGc) => unreachable!bool,
				(LowType.PtrRawConst) => true,
				(LowType.PtrRawMut) => true,
				(LowType.Record) => unreachable!bool,
				(LowType.Union) => unreachable!bool);
			if (isRawPtr)
				writer ~= "((uint8_t*)";
			writeFunPtr(writer, ctx, mustGetAt(ctx.program.concreteFunToLowFunIndex, it.fun));
			if (isRawPtr)
				writer ~= ')';
		},
		(in Constant.Integral it) {
			PrimitiveType primitive = type.as!PrimitiveType;
			if (isSignedIntegral(primitive)) {
				if (it.value == int.min)
					writer ~= "INT32_MIN";
				else if (it.value == long.min)
					// Can't write this as a literal since the '-' and rest are parsed separately,
					// and the abs of the minimum integer is out of range.
					writer ~= "INT64_MIN";
				else {
					writer ~= it.value;
					if (primitive == PrimitiveType.int64)
						writer ~= 'l';
				}
			} else {
				writer ~= cast(ulong) it.value;
				writer ~= 'u';
				if (primitive == PrimitiveType.nat64)
					writer ~= 'l';
			}
		},
		(in Constant.Pointer it) {
			writer ~= '&';
			writeConstantPointerStorageName(writer, ctx.mangledNames, ctx.program, asPtrGcPointee(type), it.index);
		},
		(in Constant.Record it) {
			LowField[] fields = ctx.program.allRecords[type.as!(LowType.Record)].fields;
			verify(sizeEq(fields, it.args));
			if (pos == ConstantRefPos.outer)
				writeCastToType(writer, ctx, type);
			writer ~= '{';
			writeWithCommasZip!(LowField, Constant)(
				writer,
				fields,
				it.args,
				(in LowField field, in Constant arg) =>
					!isVoid(field.type),
				(in LowField field, in Constant arg) {
					writeConstantRef(writer, ctx, ConstantRefPos.inner, field.type, arg);
				});
			writer ~= '}';
		},
		(in Constant.Union it) {
			LowType memberType = ctx.program.allUnions[type.as!(LowType.Union)].members[it.memberIndex];
			writeCreateUnion(writer, ctx, pos, type, it.memberIndex, () {
				writeConstantRef(writer, ctx, ConstantRefPos.inner, memberType, it.arg);
			});
		},
		(in Constant.Zero) {
			writeZeroedValue(writer, ctx, type);
		});
}

WriteExprResult writePtrToField(
	scope ref Writer writer,
	size_t indent,
	scope ref FunBodyCtx ctx,
	in Locals locals,
	in WriteKind writeKind,
	in LowType type,
	in LowExprKind.PtrToField a,
) =>
	writeInlineableSingleArg(writer, indent, ctx, locals, writeKind, type, a.target, (in WriteExprResult recordValue) {
		writer ~= "(&";
		writeTempOrInline(writer, ctx, locals, a.target, recordValue);
		writeRecordFieldRef(writer, ctx, true, targetRecordType(a), a.fieldIndex);
		writer ~= ')';
	});

WriteExprResult writeRecordFieldGet(
	scope ref Writer writer,
	size_t indent,
	scope ref FunBodyCtx ctx,
	in Locals locals,
	in WriteKind writeKind,
	in LowType type,
	in LowExprKind.RecordFieldGet a,
) =>
	writeInlineableSingleArg(writer, indent, ctx, locals, writeKind, type, a.target, (in WriteExprResult recordValue) {
		if (!isVoid(type)) {
			writeTempOrInline(writer, ctx, locals, a.target, recordValue);
			writeRecordFieldRef(writer, ctx, targetIsPointer(a), targetRecordType(a), a.fieldIndex);
		}
	});



WriteExprResult writeSpecialUnary(
	scope ref Writer writer,
	size_t indent,
	scope ref FunBodyCtx ctx,
	in Locals locals,
	in WriteKind writeKind,
	in LowType type,
	in LowExprKind.SpecialUnary a,
) {
	WriteExprResult prefix(string prefix) {
		return writeInlineableSingleArg(
			writer, indent, ctx, locals, writeKind, type, a.arg,
			(in WriteExprResult temp) {
				writer ~= '(';
				writer ~= prefix;
				writeTempOrInline(writer, ctx, locals, a.arg, temp);
				writer ~= ')';
			});
	}

	WriteExprResult specialCall(string name) {
		return writeInlineableSingleArg(
			writer, indent, ctx, locals, writeKind, type, a.arg,
			(in WriteExprResult temp) {
				writer ~= name;
				writer ~= '(';
				writeTempOrInline(writer, ctx, locals, a.arg, temp);
				writer ~= ')';
			});
	}

	final switch (a.kind) {
		case LowExprKind.SpecialUnary.Kind.acosFloat64:
			return specialCall("acos");
		case LowExprKind.SpecialUnary.Kind.acoshFloat64:
			return specialCall("acosh");
		case LowExprKind.SpecialUnary.Kind.asinFloat64:
			return specialCall("asin");
		case LowExprKind.SpecialUnary.Kind.asinhFloat64:
			return specialCall("asinh");
		case LowExprKind.SpecialUnary.Kind.atanFloat64:
			return specialCall("atan");
		case LowExprKind.SpecialUnary.Kind.atanhFloat64:
			return specialCall("atanh");
		case LowExprKind.SpecialUnary.Kind.asAnyPtr:
			return prefix("(uint8_t*) ");
		case LowExprKind.SpecialUnary.Kind.cosFloat64:
			return specialCall("cos");
		case LowExprKind.SpecialUnary.Kind.coshFloat64:
			return specialCall("cosh");
		case LowExprKind.SpecialUnary.Kind.drop:
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
		case LowExprKind.SpecialUnary.Kind.toNat64FromPtr:
		case LowExprKind.SpecialUnary.Kind.toPtrFromNat64:
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
			return writeInlineableSingleArg(
				writer, indent, ctx, locals, writeKind, type, a.arg,
				(in WriteExprResult temp) {
					writer ~= '(';
					writeCastToType(writer, ctx.ctx, type);
					writeTempOrInline(writer, ctx, locals, a.arg, temp);
					writer ~= ')';
				});
		case LowExprKind.SpecialUnary.Kind.sinFloat64:
			return specialCall("sin");
		case LowExprKind.SpecialUnary.Kind.sinhFloat64:
			return specialCall("sinh");
		case LowExprKind.SpecialUnary.Kind.tanFloat64:
			return specialCall("tan");
		case LowExprKind.SpecialUnary.Kind.tanhFloat64:
			return specialCall("tanh");
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
		case LowExprKind.SpecialUnary.Kind.roundFloat64:
			return specialCall("round");
		case LowExprKind.SpecialUnary.Kind.sqrtFloat64:
			return specialCall("sqrt");
	}
}

void writeZeroedValue(scope ref Writer writer, in Ctx ctx, in LowType type) {
	type.combinePointer.matchIn!void(
		(in LowType.Extern x) {
			writeExternZeroed(writer, ctx, x);
		},
		(in LowType.FunPtr) {
			writer ~= "NULL";
		},
		(in PrimitiveType it) {
			verify(it != PrimitiveType.void_);
			writer ~= '0';
		},
		(in LowPtrCombine _) {
			writer ~= "NULL";
		},
		(in LowType.Record it) {
			writeCastToType(writer, ctx, type);
			writer ~= '{';
			LowField[] fields = ctx.program.allRecords[it].fields;
			writeWithCommas!LowField(
				writer,
				fields,
				(in LowField field) =>
					!isVoid(field.type),
				(in LowField field) {
					writeZeroedValue(writer, ctx, field.type);
				});
			writer ~= '}';
		},
		(in LowType.Union) {
			writeCastToType(writer, ctx, type);
			writer ~= "{0}";
		});
}

void writeExternZeroed(ref Writer writer, in Ctx ctx, LowType.Extern type) {
	writeCastToType(writer, ctx, LowType(type));
	writer ~= "{{0}}";
}

WriteExprResult writeSpecialBinary(
	scope ref Writer writer,
	size_t indent,
	scope ref FunBodyCtx ctx,
	in Locals locals,
	in WriteKind writeKind,
	in LowType type,
	in LowExprKind.SpecialBinary a,
) {
	LowExpr left = a.args[0], right = a.args[1];
	WriteExprResult arg0() {
		return writeExprTempOrInline(writer, indent, ctx, locals, left);
	}
	WriteExprResult arg1() {
		return writeExprTempOrInline(writer, indent, ctx, locals, right);
	}

	WriteExprResult operator(string op) {
		return writeInlineable(
			writer, indent, ctx, locals, writeKind, type, [castNonScope_ref(left), castNonScope_ref(right)],
			(in WriteExprResult[] args) {
				verify(args.length == 2);
				writer ~= '(';
				writeTempOrInline(writer, ctx, locals, left, args[0]);
				writer ~= ' ';
				writer ~= op;
				writer ~= ' ';
				writeTempOrInline(writer, ctx, locals, right, args[1]);
				writer ~= ')';
			});
	}

	WriteExprResult specialCall(string name) {
		return writeInlineable(
			writer, indent, ctx, locals, writeKind, type, castNonScope_ref(a).args,
			(in WriteExprResult[] temps) {
				writer ~= name;
				writer ~= '(';
				writeTempOrInlines(writer, ctx, locals, castNonScope_ref(a).args, temps);
				writer ~= ')';
			});
	}

	final switch (a.kind) {
		case LowExprKind.SpecialBinary.Kind.atan2Float64:
			return specialCall("atan2");
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
				left,
				right);
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
				left,
				right);
		case LowExprKind.SpecialBinary.Kind.seq:
			if (!writeKind.isA!(WriteKind.Inline))
				writeExprVoid(writer, indent, ctx, locals, left);
			return writeExpr(writer, indent, ctx, locals, writeKind, right);
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
			WriteExprResult temp0 = arg0();
			WriteExprResult temp1 = arg1();
			return writeReturnVoid(writer, indent, ctx, writeKind, () {
				if (!isVoid(right.type)) {
					writer ~= "*";
					writeTempOrInline(writer, ctx, locals, left, temp0);
					writer ~= " = ";
					writeTempOrInline(writer, ctx, locals, right, temp1);
				}
			});
	}
}

enum LogicalOperator { and, or }

immutable struct WriteExprResultAndNested {
	WriteExprResult result;
	WriteKind writeKind;
}

// If we need to make a temporary, have to do that in an outer scope and write to it in an inner scope
WriteExprResultAndNested getNestedWriteKind(
	scope ref Writer writer,
	size_t indent,
	scope ref FunBodyCtx ctx,
	in LowType type,
	return scope ref WriteKind writeKind,
) {
	if (isVoid(type)) {
		verify(writeKind.isA!(WriteKind.Void) || writeKind.isA!(WriteKind.Return));
		return WriteExprResultAndNested(writeExprDone(), writeKind);
	} if (writeKind.isA!(WriteKind.MakeTemp) || writeKind.isA!(WriteKind.InlineOrTemp)) {
		Temp temp = getNextTemp(ctx);
		writeTempDeclare(writer, ctx, type, temp);
		writer ~= ';';
		writeNewline(writer, indent);
		return WriteExprResultAndNested(WriteExprResult(temp), WriteKind(WriteKind.UseTemp(temp)));
	} else
		return WriteExprResultAndNested(writeExprDone(), writeKind);
}

WriteExprResult writeLogicalOperator(
	scope ref Writer writer,
	size_t indent,
	scope ref FunBodyCtx ctx,
	in Locals locals,
	in WriteKind writeKind,
	LogicalOperator operator,
	in LowExpr left,
	in LowExpr right,
) {
	/*
	`a && b` ==> `if (a) { return b; } else { return 0; }`
	`a || b` ==> `if (a) { return 1; } else { return b; }`
	*/
	WriteExprResult cond = writeExprTempOrInline(writer, indent, ctx, locals, left);
	WriteExprResultAndNested nested = getNestedWriteKind(writer, indent, ctx, boolType, castNonScope_ref(writeKind));
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

WriteExprResult writeIf(
	scope ref Writer writer,
	size_t indent,
	scope ref FunBodyCtx ctx,
	in Locals locals,
	in WriteKind writeKind,
	in LowType type,
	in LowExprKind.If a,
) {
	// TODO: writeExprTempOrInline
	Temp temp0 = writeExprTemp(writer, indent, ctx, locals, a.cond);
	WriteExprResultAndNested nested = getNestedWriteKind(writer, indent, ctx, type, castNonScope_ref(writeKind));
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

WriteExprResult writeCallFunPtr(
	scope ref Writer writer,
	size_t indent,
	scope ref FunBodyCtx ctx,
	in Locals locals,
	in WriteKind writeKind,
	in LowType type,
	in LowExprKind.CallFunPtr a,
) {
	WriteExprResult fn = writeExprTempOrInline(writer, indent, ctx, locals, a.funPtr);
	WriteExprResult[] args = writeExprsTempOrInline(writer, indent, ctx, locals, a.args);
	return writeNonInlineable(writer, indent, ctx, writeKind, type, () {
		writeTempOrInline(writer, ctx, locals, a.funPtr, fn);
		writer ~= '(';
		writeTempOrInlines(writer, ctx, locals, a.args, args);
		writer ~= ')';
	});
}

WriteExprResult writeLet(
	scope ref Writer writer,
	size_t indent,
	scope ref FunBodyCtx ctx,
	in Locals locals,
	in WriteKind writeKind,
	in LowExprKind.Let a,
) {
	if (!writeKind.isA!(WriteKind.Inline)) {
		if (isVoid(a.local.type))
			writeExprVoid(writer, indent, ctx, locals, a.value);
		else {
			writeDeclareLocal(writer, indent, ctx, *a.local);
			writer ~= ';';
			WriteKind localWriteKind = WriteKind(a.local);
			drop(writeExpr(writer, indent, ctx, locals, localWriteKind, a.value));
			writeNewline(writer, indent);
		}
	}
	return writeExpr(writer, indent, ctx, locals, writeKind, a.then);
}

WriteExprResult writeLocalSet(
	scope ref Writer writer,
	size_t indent,
	scope ref FunBodyCtx ctx,
	in Locals locals,
	in WriteKind writeKind,
	in LowExprKind.LocalSet a,
) {
	if (isVoid(a.local.type))
		writeExprVoid(writer, indent, ctx, locals, a.value);
	else {
		WriteKind localWriteKind = WriteKind(a.local);
		drop(writeExpr(writer, indent, ctx, locals, localWriteKind, a.value));
	}
	return writeReturnVoid(writer, indent, ctx, writeKind);
}

WriteExprResult writeLoop(
	scope ref Writer writer,
	size_t indent,
	scope ref FunBodyCtx ctx,
	in Locals locals,
	in WriteKind writeKind,
	in LowType type,
	in LowExprKind.Loop a,
) {
	WriteExprResultAndNested nested = getNestedWriteKind(writer, indent, ctx, type, castNonScope_ref(writeKind));

	size_t index = nextLoopIndex(ctx);
	LoopInfo loopInfo = LoopInfo(index, nested.writeKind);

	writeNewline(writer, indent);
	writer ~= "for (;;) {";
	writeNewline(writer, indent + 1);

	writeExprVoid(writer, indent + 1, ctx, addLoop(locals, ptrTrustMe(a), &loopInfo), a.body_);

	writeNewline(writer, indent);
	writer ~= '}';

	if (!nested.writeKind.isA!(WriteKind.Return)) {
		writeNewline(writer, indent);
		writer ~= "__break";
		writer ~= index;
		// Semicolon to avoid error "a label can only be part of a statement and a declaration is not a statement"
		writer ~= ":;";
	}

	return nested.result;
}

WriteExprResult writeLoopBreak(
	scope ref Writer writer,
	size_t indent,
	scope ref FunBodyCtx ctx,
	in Locals locals,
	in WriteKind writeKind,
	in LowExprKind.LoopBreak a,
) {
	verify(writeKind.isA!(WriteKind.Void));
	LoopInfo* info = getLoop(locals, a.loop);
	drop(writeExpr(writer, indent, ctx, locals, info.writeKind, a.value));
	if (!info.writeKind.isA!(WriteKind.Return)) {
		writeNewline(writer, indent);
		writer ~= "goto __break";
		writer ~= info.index;
		writer ~= ';';
	}
	return WriteExprResult(WriteExprResult.Done());
}

void writePrimitiveType(scope ref Writer writer, PrimitiveType a) {
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
