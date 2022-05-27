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
import backend.writeTypes : TypeWriters, writeTypes;
import interpret.debugging : writeFunName, writeFunSig;
import lower.lowExprHelpers : boolType;
import model.concreteModel :
	body_,
	BuiltinStructKind,
	ConcreteStruct,
	ConcreteStructBody,
	isExtern,
	matchConcreteStructBody,
	TypeSize;
import model.constant : asIntegral, Constant, matchConstant;
import model.lowModel :
	AllConstantsLow,
	ArrTypeAndConstantsLow,
	asPrimitive,
	asPtrGcPointee,
	asRecordType,
	asUnionType,
	debugName,
	isChar8,
	isExtern,
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
	LowPtrCombine,
	LowProgram,
	LowRecord,
	LowThreadLocal,
	LowThreadLocalIndex,
	LowType,
	LowUnion,
	matchLowExprKind,
	matchLowFunBody,
	matchLowType,
	matchLowTypeCombinePtr,
	PointerTypeAndConstantsLow,
	PrimitiveType,
	targetIsPointer,
	targetRecordType,
	UpdateParam;
import model.model : EnumValue, name;
import model.typeLayout : sizeOfType;
import util.alloc.alloc : Alloc, TempAlloc;
import util.col.arr : empty, only, sizeEq;
import util.col.arrUtil : arrLiteral, every, exists, map, zip;
import util.col.dict : mustGetAt;
import util.col.fullIndexDict : FullIndexDict, fullIndexDictEach, fullIndexDictEachKey, fullIndexDictEachValue;
import util.col.stackDict : StackDict, stackDictAdd, stackDictLastAdded, stackDictMustGet;
import util.col.str : eachChar, SafeCStr;
import util.opt : force, has, Opt, some;
import util.ptr : ptrTrustMe, ptrTrustMe_mut;
import util.sym : AllSymbols;
import util.util : abs, drop, todo, unreachable, verify;
import util.writer :
	finishWriterToSafeCStr,
	writeChar,
	writeEscapedChar_inner,
	writeFloatLiteral,
	writeInt,
	writeNat,
	writeNewline,
	Writer,
	writeStatic,
	writeWithCommas,
	writeWithCommasZip;

immutable(SafeCStr) writeToC(
	ref Alloc alloc,
	ref TempAlloc tempAlloc,
	ref immutable AllSymbols allSymbols,
	ref immutable LowProgram program,
) {
	Writer writer = Writer(ptrTrustMe_mut(alloc));

	writeStatic(writer, "#include <stddef.h>\n"); // for NULL
	writeStatic(writer, "#include <stdint.h>\n");
	version (Windows) {
		writeStatic(writer, "unsigned short __popcnt16(unsigned short value);\n");
		writeStatic(writer, "unsigned int __popcnt(unsigned int value);\n");
		writeStatic(writer, "unsigned __int64 __popcnt64(unsigned __int64 value);\n");
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
			writeStatic(writer, ";\n");
		}
	}

	foreach (ref immutable PointerTypeAndConstantsLow a; allConstants.pointers) {
		foreach (immutable size_t i; 0 .. a.constants.length) {
			declareConstantPointerStorage(writer, ctx, a.pointeeType, i);
			writeStatic(writer, ";\n");
		}
	}

	foreach (ref immutable ArrTypeAndConstantsLow a; allConstants.arrs) {
		foreach (immutable size_t i, immutable Constant[] elements; a.constants) {
			declareConstantArrStorage(writer, ctx, a.arrType, a.elementType, i, elements.length);
			writeStatic(writer, " = ");
			if (isChar8(a.elementType)) {
				writeChar(writer, '"');
				foreach (immutable Constant element; elements) {
					immutable char x = cast(immutable char) asIntegral(element).value;
					if (x == '?')
						// avoid trigraphs
						writeStatic(writer, "\\?");
					else
						writeEscapedChar_inner(writer, x);
				}
				writeChar(writer, '"');
			} else {
				writeChar(writer, '{');
				writeWithCommas!Constant(writer, elements, (scope ref immutable Constant element) {
					writeConstantRef(writer, ctx, ConstantRefPos.inner, a.elementType, element);
				});
				writeChar(writer, '}');
			}
			writeStatic(writer, ";\n");
		}
	}

	foreach (ref immutable PointerTypeAndConstantsLow a; allConstants.pointers) {
		foreach (immutable size_t i, immutable Constant pointee; a.constants) {
			declareConstantPointerStorage(writer, ctx, a.pointeeType, i);
			writeStatic(writer, " = ");
			writeConstantRef(writer, ctx, ConstantRefPos.inner, a.pointeeType, pointee);
			writeStatic(writer, ";\n");
		}
	}
}

void writeThreadLocals(
	scope ref Writer writer,
	scope ref immutable Ctx ctx,
	scope immutable FullIndexDict!(LowThreadLocalIndex, LowThreadLocal) threadLocals,
) {
	fullIndexDictEachValue!(LowThreadLocalIndex, LowThreadLocal)(threadLocals, (ref immutable LowThreadLocal x) {
		writeStatic(writer, "static _Thread_local ");
		writeType(writer, ctx, x.type);
		writeChar(writer, ' ');
		writeLowThreadLocalMangledName(writer, ctx.mangledNames, x);
		writeStatic(writer, ";\n");
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
	writeChar(writer, ' ');
	writeConstantArrStorageName(writer, ctx.mangledNames, ctx.program, arrType, index);
	writeChar(writer, '[');
	writeNat(writer, nElements);
	writeChar(writer, ']');
}

void declareConstantPointerStorage(
	scope ref Writer writer,
	scope ref immutable Ctx ctx,
	immutable LowType pointeeType,
	immutable size_t index,
) {
	//TODO: some day we may support non-record pointee?
	writeRecordType(writer, ctx, asRecordType(pointeeType));
	writeChar(writer, ' ');
	writeConstantPointerStorageName(writer, ctx.mangledNames, ctx.program, pointeeType, index);
}

struct Ctx {
	@safe @nogc pure nothrow:

	immutable LowProgram* programPtr;
	immutable MangledNames mangledNames;

	ref immutable(LowProgram) program() return scope immutable {
		return *programPtr;
	}
	ref immutable(AllSymbols) allSymbols() return scope immutable {
		return *mangledNames.allSymbols;
	}
}

struct FunBodyCtx {
	@safe @nogc pure nothrow:

	immutable Ctx* ctxPtr;
	immutable bool hasTailRecur;
	immutable LowFunIndex curFun;
	size_t nextTemp;

	ref immutable(Ctx) ctx() return scope const {
		return *ctxPtr;
	}

	ref immutable(LowProgram) program() return scope const {
		return ctx.program;
	}

	ref immutable(MangledNames) mangledNames() return scope const {
		return ctx.mangledNames;
	}
}

immutable(Temp) getNextTemp(ref FunBodyCtx ctx) {
	immutable Temp temp = immutable Temp(ctx.nextTemp);
	ctx.nextTemp++;
	return temp;
}

void writeType(scope ref Writer writer, scope ref immutable Ctx ctx, scope immutable LowType t) {
	return matchLowTypeCombinePtr!(
		void,
		(immutable LowType.ExternPtr it) {
			writeStatic(writer, "struct ");
			writeStructMangledName(writer, ctx.mangledNames, ctx.program.allExternPtrTypes[it].source);
			writeChar(writer, '*');
		},
		(immutable LowType.FunPtr it) {
			writeStructMangledName(writer, ctx.mangledNames, ctx.program.allFunPtrTypes[it].source);
		},
		(immutable PrimitiveType it) {
			writePrimitiveType(writer, it);
		},
		(immutable LowPtrCombine it) {
			writeType(writer, ctx, it.pointee);
			writeChar(writer, '*');
		},
		(immutable LowType.Record it) {
			writeRecordType(writer, ctx, it);
		},
		(immutable LowType.Union it) {
			writeStatic(writer, "struct ");
			writeStructMangledName(writer, ctx.mangledNames, ctx.program.allUnions[it].source);
		},
	)(t);
}

void writeRecordType(scope ref Writer writer, scope ref immutable Ctx ctx, immutable LowType.Record a) {
	writeStatic(writer, "struct ");
	writeRecordName(writer, ctx.mangledNames, ctx.program, a);
}

void writeCastToType(scope ref Writer writer, scope ref immutable Ctx ctx, scope immutable LowType type) {
	writeChar(writer, '(');
	writeType(writer, ctx, type);
	writeStatic(writer, ") ");
}

void writeParamDecl(scope ref Writer writer, scope ref immutable Ctx ctx, scope ref immutable LowParam a) {
	writeType(writer, ctx, a.type);
	writeChar(writer, ' ');
	writeLowParamName(writer, ctx.mangledNames, a);
}

void writeStructHead(scope ref Writer writer, scope ref immutable Ctx ctx, scope immutable ConcreteStruct* source) {
	writeStatic(writer, "struct ");
	writeStructMangledName(writer, ctx.mangledNames, source);
	writeStatic(writer, " {");
}

void writeStructEnd(scope ref Writer writer) {
	writeStatic(writer, "\n};\n");
}

void writeRecord(scope ref Writer writer, scope ref immutable Ctx ctx, scope ref immutable LowRecord a) {
	if (a.packed) {
		version (Windows) {
			writeStatic(writer, "__pragma(pack(push, 1))\n");
		}
	}
	writeStructHead(writer, ctx, a.source);
	foreach (ref immutable LowField field; a.fields) {
		if (!isVoid(field.type)) {
			writeStatic(writer, "\n\t");
			writeType(writer, ctx, field.type);
			writeChar(writer, ' ');
			writeMangledName(writer, ctx.mangledNames, debugName(field));
			writeChar(writer, ';');
		}
	}
	writeStatic(writer, "\n}");
	if (a.packed) {
		version (Windows) {
			writeStatic(writer, "__pragma(pack(pop))");
		} else {
			writeStatic(writer, " __attribute__ ((__packed__))");
		}
	}
	writeStatic(writer, ";\n");
}

void writeUnion(scope ref Writer writer, scope ref immutable Ctx ctx, scope ref immutable LowUnion a) {
	writeStructHead(writer, ctx, a.source);
	writeStatic(writer, "\n\tuint64_t kind;");
	immutable bool isBuiltin = matchConcreteStructBody!(immutable bool)(
		body_(*a.source),
		(ref immutable ConcreteStructBody.Builtin it) {
			verify(it.kind == BuiltinStructKind.fun);
			return true;
		},
		(ref immutable(ConcreteStructBody.Enum)) => false,
		(ref immutable(ConcreteStructBody.Flags)) => false,
		(ref immutable(ConcreteStructBody.ExternPtr)) => false,
		(ref immutable(ConcreteStructBody.Record)) => false,
		(ref immutable(ConcreteStructBody.Union)) => false);
	if (exists!(immutable LowType)(a.members, (ref immutable LowType member) => !isVoid(member)) || isBuiltin) {
		writeStatic(writer, "\n\tunion {");
		foreach (immutable size_t memberIndex, immutable LowType member; a.members) {
			if (!isVoid(member)) {
				writeStatic(writer, "\n\t\t");
				writeType(writer, ctx, member);
				writeStatic(writer, " as");
				writeNat(writer, memberIndex);
				writeChar(writer, ';');
			}
		}
		// Fun types must be 16 bytes
		if (isBuiltin &&
			every!LowType(a.members, (ref immutable LowType member) => sizeOfType(ctx.program, member).size < 8))
			writeStatic(writer, "\n\t\tuint64_t __ensureSizeIs16;");
		writeStatic(writer, "\n\t};");
	}
	writeStructEnd(writer);
}

void declareStruct(scope ref Writer writer, scope ref immutable Ctx ctx, scope immutable ConcreteStruct* source) {
	writeStatic(writer, "struct ");
	writeStructMangledName(writer, ctx.mangledNames, source);
	writeStatic(writer, ";\n");
}

void staticAssertStructSize(
	scope ref Writer writer,
	scope ref immutable Ctx ctx,
	scope immutable LowType type,
	immutable TypeSize size,
) {
	writeStatic(writer, "_Static_assert(sizeof(");
	writeType(writer, ctx, type);
	writeStatic(writer, ") == ");
	writeNat(writer, size.size);
	writeStatic(writer, ", \"\");\n");

	writeStatic(writer, "_Static_assert(_Alignof(");
	writeType(writer, ctx, type);
	writeStatic(writer, ") == ");
	writeNat(writer, size.alignment);
	writeStatic(writer, ", \"\");\n");
}

void writeStructs(ref Alloc alloc, scope ref Writer writer, scope ref immutable Ctx ctx) {
	scope immutable TypeWriters writers = immutable TypeWriters(
		(immutable ConcreteStruct* it) {
			declareStruct(writer, ctx, it);
		},
		(immutable LowType.FunPtr, ref immutable LowFunPtrType funPtr) {
			writeStatic(writer, "typedef ");
			if (isVoid(funPtr.returnType))
				writeStatic(writer, "void");
			else
				writeType(writer, ctx, funPtr.returnType);
			writeStatic(writer, " (*");
			writeStructMangledName(writer, ctx.mangledNames, funPtr.source);
			writeStatic(writer, ")(");
			if (empty(funPtr.paramTypes))
				writeStatic(writer, "void");
			else
				writeWithCommas!LowType(
					writer,
					funPtr.paramTypes,
					(scope ref immutable LowType paramType) =>
						!isVoid(paramType),
					(scope ref immutable LowType paramType) {
						writeType(writer, ctx, paramType);
					});
			writeStatic(writer, ");\n");
		},
		(immutable LowType.Record, ref immutable LowRecord record) {
			writeRecord(writer, ctx, record);
		},
		(immutable LowType.Union, ref immutable LowUnion union_) {
			writeUnion(writer, ctx, union_);
		});
	writeTypes(alloc, ctx.program, writers);

	writeChar(writer, '\n');

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
		writeStatic(writer, "void");
	else
		writeType(writer, ctx, fun.returnType);
	writeChar(writer, ' ');
	writeLowFunMangledName(writer, ctx.mangledNames, funIndex, fun);
	if (!isGlobal(fun.body_)) {
		writeChar(writer, '(');
		if (every!(immutable LowParam)(fun.params, (ref immutable LowParam x) => isVoid(x.type)))
			writeStatic(writer, "void");
		else
			writeWithCommas!LowParam(
				writer,
				fun.params,
				(scope ref immutable LowParam x) =>
					!isVoid(x.type),
				(scope ref immutable LowParam x) {
					writeParamDecl(writer, ctx, x);
				});
		writeChar(writer, ')');
	}
}

void writeFunDeclaration(
	scope ref Writer writer,
	scope ref immutable Ctx ctx,
	immutable LowFunIndex funIndex,
	scope ref immutable LowFun fun,
) {
	if (isExtern(fun.body_))
		writeStatic(writer, "extern ");
	writeFunReturnTypeNameAndParams(writer, ctx, funIndex, fun);
	writeStatic(writer, ";\n");
}

void writeFunDefinition(
	scope ref Writer writer,
	ref TempAlloc tempAlloc,
	scope ref immutable Ctx ctx,
	immutable LowFunIndex funIndex,
	scope ref immutable LowFun fun,
) {
	matchLowFunBody!(
		void,
		(ref immutable LowFunBody.Extern it) {
			// declaration is enough
		},
		(ref immutable LowFunExprBody it) {
			// TODO: only if a flag is set
			writeStatic(writer, "/* ");
			writeFunName(writer, ctx.allSymbols, ctx.program, funIndex);
			writeChar(writer, ' ');
			writeFunSig(writer, ctx.allSymbols, ctx.program, fun);
			writeStatic(writer, " */\n");
			writeFunWithExprBody(writer, tempAlloc, ctx, funIndex, fun, it);
		},
	)(fun.body_);
}

//TODO: not @trusted
@trusted void writeFunWithExprBody(
	ref Writer writer,
	ref TempAlloc tempAlloc,
	ref immutable Ctx ctx,
	immutable LowFunIndex funIndex,
	ref immutable LowFun fun,
	ref immutable LowFunExprBody body_,
) {
	writeFunReturnTypeNameAndParams(writer, ctx, funIndex, fun);
	writeStatic(writer, " {");
	if (body_.hasTailRecur)
		writeStatic(writer, "\n\ttop:;"); // Need ';' so it labels a statement
	FunBodyCtx bodyCtx = FunBodyCtx(ptrTrustMe(ctx), body_.hasTailRecur, funIndex, 0);
	immutable WriteKind writeKind = immutable WriteKind(immutable WriteKind.Return());
	immutable Locals locals;
	drop(writeExpr(writer, tempAlloc, 1, bodyCtx, locals, writeKind, body_.expr));
	writeStatic(writer, "\n}\n");
}

struct Temp {
	immutable size_t index;
}

// If expr, we refused to write to a temp because this can be written inline
struct WriteExprResult {
	@safe @nogc pure nothrow:

	// Meaning depends on the WriteKind
	// If the write kind was TempOrInline, this indicates that it should be done inline.
	struct Done {
		// Args (not written inline) prepared for writing inline.
		immutable WriteExprResult[] args;
	}

	@trusted immutable this(immutable Done a) { kind = Kind.done; done = a; }
	immutable this(immutable Temp a) { kind = Kind.temp; temp = a; }

	private:
	enum Kind {
		done,
		temp,
	}
	immutable Kind kind;
	union {
		immutable Done done;
		immutable Temp temp;
	}
}

immutable(WriteExprResult) writeExprDone() {
	return immutable WriteExprResult(immutable WriteExprResult.Done([]));
}

immutable(bool) isDone(ref immutable WriteExprResult a) {
	return a.kind == WriteExprResult.Kind.done;
}

@trusted immutable(WriteExprResult.Done) asDone(ref immutable WriteExprResult a) {
	verify(isDone(a));
	return a.done;
}

immutable(Temp) asTemp(ref immutable WriteExprResult a) {
	verify(a.kind == WriteExprResult.Kind.temp);
	return a.temp;
}

@trusted T matchWriteExprResult(T)(
	ref immutable WriteExprResult a,
	scope T delegate(ref immutable WriteExprResult.Done) @safe @nogc pure nothrow cbDone,
	scope T delegate(immutable Temp) @safe @nogc pure nothrow cbTemp,
) {
	final switch (a.kind) {
		case WriteExprResult.Kind.done:
			return cbDone(a.done);
		case WriteExprResult.Kind.temp:
			return cbTemp(a.temp);
	}
}

void writeTempDeclare(
	scope ref Writer writer,
	scope ref FunBodyCtx ctx,
	scope immutable LowType type,
	immutable Temp temp,
) {
	writeType(writer, ctx.ctx, type);
	writeChar(writer, ' ');
	writeTempRef(writer, temp);
}

void writeTempRef(ref Writer writer, ref immutable Temp a) {
	writeStatic(writer, "_");
	writeNat(writer, a.index);
}

void writeTempOrInline(
	scope ref Writer writer,
	scope ref TempAlloc tempAlloc,
	scope ref FunBodyCtx ctx,
	scope ref immutable Locals locals,
	scope ref immutable LowExpr e,
	scope ref immutable WriteExprResult a,
) {
	matchWriteExprResult!void(
		a,
		(ref immutable WriteExprResult.Done it) {
			immutable WriteKind writeKind = immutable WriteKind(immutable WriteKind.Inline(it.args));
			immutable WriteExprResult res = writeExpr(writer, tempAlloc, 0, ctx, locals, writeKind, e);
			verify(isDone(res) && empty(asDone(res).args));
		},
		(immutable Temp it) {
			writeTempRef(writer, it);
		});
}

void writeTempOrInlines(
	scope ref Writer writer,
	scope ref TempAlloc tempAlloc,
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
			writeTempOrInline(writer, tempAlloc, ctx, locals, expr, arg);
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
	writeChar(writer, ' ');
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

	@trusted immutable this(immutable Inline a) { kind = Kind.inline; inline = a; }
	immutable this(immutable InlineOrTemp a) { kind = Kind.inlineOrTemp; inlineOrTemp = a; }
	@trusted immutable this(immutable LowLocal* a) { kind = Kind.local; local = a; }
	immutable this(immutable MakeTemp a) { kind = Kind.makeTemp; makeTemp = a; }
	immutable this(immutable Return a) { kind = Kind.return_; return_ = a; }
	immutable this(immutable UseTemp a) { kind = Kind.useTemp; useTemp = a; }
	immutable this(immutable Void a) { kind = Kind.void_; void_ = a; }

	private:
	enum Kind {
		inline,
		inlineOrTemp,
		local,
		makeTemp,
		return_,
		useTemp,
		void_,
	}
	immutable Kind kind;
	union {
		immutable Inline inline;
		immutable InlineOrTemp inlineOrTemp;
		immutable LowLocal* local;
		immutable MakeTemp makeTemp;
		immutable Return return_;
		immutable UseTemp useTemp;
		immutable Void void_;
	}
}

immutable(bool) isInline(scope ref immutable WriteKind a) {
	return a.kind == WriteKind.Kind.inline;
}

@trusted immutable(WriteKind.Inline) asInline(scope ref immutable WriteKind a) {
	verify(isInline(a));
	return a.inline;
}

immutable(bool) isInlineOrTemp(scope ref immutable WriteKind a) {
	return a.kind == WriteKind.Kind.inlineOrTemp;
}

immutable(bool) isMakeTemp(scope ref immutable WriteKind a) {
	return a.kind == WriteKind.Kind.makeTemp;
}

immutable(bool) isReturn(scope ref immutable WriteKind a) {
	return a.kind == WriteKind.Kind.return_;
}

immutable(bool) isVoid(scope ref immutable WriteKind a) {
	return a.kind == WriteKind.Kind.void_;
}

@trusted T matchWriteKind(T)(
	scope ref immutable WriteKind a,
	scope T delegate(scope ref immutable WriteKind.Inline) @safe @nogc pure nothrow cbInline,
	scope T delegate(scope ref immutable WriteKind.InlineOrTemp) @safe @nogc pure nothrow cbInlineOrTemp,
	scope T delegate(scope immutable LowLocal*) @safe @nogc pure nothrow cbLocal,
	scope T delegate(scope ref immutable WriteKind.MakeTemp) @safe @nogc pure nothrow cbMakeTemp,
	scope T delegate(scope ref immutable WriteKind.Return) @safe @nogc pure nothrow cbReturn,
	scope T delegate(scope ref immutable WriteKind.UseTemp) @safe @nogc pure nothrow cbUseTemp,
	scope T delegate(scope ref immutable WriteKind.Void) @safe @nogc pure nothrow cbVoid,
) {
	final switch (a.kind) {
		case WriteKind.Kind.inline:
			return cbInline(a.inline);
		case WriteKind.Kind.inlineOrTemp:
			return cbInlineOrTemp(a.inlineOrTemp);
		case WriteKind.Kind.local:
			return cbLocal(a.local);
		case WriteKind.Kind.makeTemp:
			return cbMakeTemp(a.makeTemp);
		case WriteKind.Kind.return_:
			return cbReturn(a.return_);
		case WriteKind.Kind.useTemp:
			return cbUseTemp(a.useTemp);
		case WriteKind.Kind.void_:
			return cbVoid(a.void_);
	}
}

immutable(WriteExprResult[]) writeExprsTempOrInline(
	scope ref Writer writer,
	ref TempAlloc tempAlloc,
	immutable size_t indent,
	scope ref FunBodyCtx ctx,
	scope ref immutable Locals locals,
	scope immutable LowExpr[] args,
) {
	return map!WriteExprResult(tempAlloc, args, (ref immutable LowExpr arg) =>
		writeExprTempOrInline(writer, tempAlloc, indent, ctx, locals, arg));
}

immutable(Temp) writeExprTemp(
	scope ref Writer writer,
	scope ref TempAlloc tempAlloc,
	immutable size_t indent,
	scope ref FunBodyCtx ctx,
	scope ref immutable Locals locals,
	scope ref immutable LowExpr expr,
) {
	immutable WriteKind writeKind = immutable WriteKind(immutable WriteKind.MakeTemp());
	immutable WriteExprResult res = writeExpr(writer, tempAlloc, indent, ctx, locals, writeKind, expr);
	return asTemp(res);
}

void writeExprVoid(
	scope ref Writer writer,
	scope ref TempAlloc tempAlloc,
	immutable size_t indent,
	scope ref FunBodyCtx ctx,
	scope ref immutable Locals locals,
	scope ref immutable LowExpr expr,
) {
	immutable WriteKind writeKind = immutable WriteKind(immutable WriteKind.Void());
	drop(writeExpr(writer, tempAlloc, indent, ctx, locals, writeKind, expr));
}

immutable(WriteExprResult) writeExprTempOrInline(
	scope ref Writer writer,
	scope ref TempAlloc tempAlloc,
	immutable size_t indent,
	scope ref FunBodyCtx ctx,
	scope ref immutable Locals locals,
	scope ref immutable LowExpr expr,
) {
	immutable WriteKind writeKind = immutable WriteKind(immutable WriteKind.InlineOrTemp());
	return writeExpr(writer, tempAlloc, indent, ctx, locals, writeKind, expr);
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
	scope ref TempAlloc tempAlloc,
	immutable size_t indent,
	scope ref FunBodyCtx ctx,
	scope ref immutable Locals locals,
	scope ref immutable WriteKind writeKind,
	scope ref immutable LowExpr expr,
) {
	immutable LowType type = expr.type;
	immutable(WriteExprResult) nonInlineable(scope void delegate() @safe @nogc pure nothrow cb) {
		return writeNonInlineable(writer, indent, ctx, writeKind, type, cb);
	}
	immutable(WriteExprResult) inlineable(
		ref immutable LowExpr[] args,
		scope void delegate(ref immutable WriteExprResult[]) @safe @nogc pure nothrow inline,
	) {
		return writeInlineable(writer, tempAlloc, indent, ctx, locals, writeKind, type, args, inline);
	}
	immutable(WriteExprResult) inlineableSingleArg(
		ref immutable LowExpr arg,
		scope void delegate(ref immutable WriteExprResult) @safe @nogc pure nothrow inline,
	) {
		return writeInlineableSingleArg(writer, tempAlloc, indent, ctx, locals, writeKind, type, arg, inline);
	}
	immutable(WriteExprResult) inlineableSimple(scope void delegate() @safe @nogc pure nothrow inline) {
		return writeInlineableSimple(writer, tempAlloc, indent, ctx, locals, writeKind, type, inline);
	}

	return matchLowExprKind!(
		immutable WriteExprResult,
		(scope ref immutable LowExprKind.Call it) =>
			writeCallExpr(writer, tempAlloc, indent, ctx, locals, writeKind, type, it),
		(scope ref immutable LowExprKind.CallFunPtr it) =>
			writeCallFunPtr(writer, tempAlloc, indent, ctx, locals, writeKind, type, it),
		(scope ref immutable LowExprKind.CreateRecord it) =>
			inlineable(it.args, (scope ref immutable WriteExprResult[] args) {
				writeCastToType(writer, ctx.ctx, type);
				writeChar(writer, '{');
				writeTempOrInlines(writer, tempAlloc, ctx, locals, it.args, args);
				writeChar(writer, '}');
			}),
		(scope ref immutable LowExprKind.CreateUnion it) =>
			inlineableSingleArg(it.arg, (scope ref immutable WriteExprResult arg) {
				writeCreateUnion(writer, ctx.ctx, ConstantRefPos.outer, type, it.memberIndex, () {
					writeTempOrInline(writer, tempAlloc, ctx, locals, it.arg, arg);
				});
			}),
		(scope ref immutable LowExprKind.If it) =>
			writeIf(writer, tempAlloc, indent, ctx, locals, writeKind, type, it),
		(scope ref immutable LowExprKind.InitConstants) =>
			// writeToC doesn't need to do anything in 'init-constants'
			writeReturnVoid(writer, indent, ctx, writeKind),
		(scope ref immutable LowExprKind.Let it) =>
			writeLet(writer, tempAlloc, indent, ctx, locals, writeKind, it),
		(scope ref immutable LowExprKind.LocalRef it) =>
			inlineableSimple(() {
				writeLowLocalName(writer, ctx.mangledNames, *it.local);
			}),
		(scope ref immutable LowExprKind.LocalSet it) =>
			writeLocalSet(writer, tempAlloc, indent, ctx, locals, writeKind, it),
		(scope ref immutable LowExprKind.Loop it) =>
			writeLoop(writer, tempAlloc, indent, ctx, locals, writeKind, type, it),
		(scope ref immutable LowExprKind.LoopBreak it) =>
			writeLoopBreak(writer, tempAlloc, indent, ctx, locals, writeKind, it),
		(scope ref immutable LowExprKind.LoopContinue it) {
			// Do nothing, continuing the loop is implicit in C
			verify(isVoid(writeKind));
			return immutable WriteExprResult(immutable WriteExprResult.Done());
		},
		(scope ref immutable LowExprKind.MatchUnion it) =>
			writeMatchUnion(writer, tempAlloc, indent, ctx, locals, writeKind, type, it),
		(scope ref immutable LowExprKind.ParamRef it) =>
			inlineableSimple(() {
				writeParamRef(writer, ctx, it);
			}),
		(scope ref immutable LowExprKind.PtrCast it) {
			return inlineableSingleArg(it.target, (ref immutable WriteExprResult arg) {
				writeChar(writer, '(');
				writeCastToType(writer, ctx.ctx, type);
				writeTempOrInline(writer, tempAlloc, ctx, locals, it.target, arg);
				writeChar(writer, ')');
			});
		},
		(scope ref immutable LowExprKind.RecordFieldGet it) =>
			inlineableSingleArg(it.target, (scope ref immutable WriteExprResult recordValue) @safe {
				if (!isVoid(expr.type)) {
					writeTempOrInline(writer, tempAlloc, ctx, locals, it.target, recordValue);
					writeRecordFieldRef(writer, ctx, targetIsPointer(it), targetRecordType(it), it.fieldIndex);
				}
			}),
		(scope ref immutable LowExprKind.RecordFieldSet it) {
			immutable WriteExprResult recordValue =
				writeExprTempOrInline(writer, tempAlloc, indent, ctx, locals, it.target);
			immutable WriteExprResult fieldValue =
				writeExprTempOrInline(writer, tempAlloc, indent, ctx, locals, it.value);
			return writeReturnVoid(writer, indent, ctx, writeKind, () {
				writeTempOrInline(writer, tempAlloc, ctx, locals, it.target, recordValue);
				writeRecordFieldRef(writer, ctx, targetIsPointer(it), targetRecordType(it), it.fieldIndex);
				writeStatic(writer, " = ");
				writeTempOrInline(writer, tempAlloc, ctx, locals, it.value, fieldValue);
			});
		},
		(scope ref immutable LowExprKind.Seq it) {
			if (!isInline(writeKind))
				writeExprVoid(writer, tempAlloc, indent, ctx, locals, it.first);
			return writeExpr(writer, tempAlloc, indent, ctx, locals, writeKind, it.then);
		},
		(scope ref immutable LowExprKind.SizeOf it) =>
			inlineableSimple(() {
				writeStatic(writer, "sizeof(");
				writeType(writer, ctx.ctx, it.type);
				writeChar(writer, ')');
			}),
		(scope ref immutable Constant it) =>
			inlineableSimple(() {
				writeConstantRef(writer, ctx.ctx, ConstantRefPos.outer, type, it);
			}),
		(scope ref immutable LowExprKind.SpecialUnary it) =>
			writeSpecialUnary(writer, tempAlloc, indent, ctx, locals, writeKind, type, it),
		(scope ref immutable LowExprKind.SpecialBinary it) =>
			writeSpecialBinary(writer, tempAlloc, indent, ctx, locals, writeKind, type, it),
		(scope ref immutable LowExprKind.SpecialTernary) =>
			unreachable!(immutable WriteExprResult),
		(scope ref immutable LowExprKind.Switch0ToN it) =>
			writeSwitch(
				writer, tempAlloc, indent, ctx, locals, writeKind, type, it.value, it.cases,
				(immutable size_t i) => immutable EnumValue(i)),
		(scope ref immutable LowExprKind.SwitchWithValues it) =>
			writeSwitch(
				writer, tempAlloc, indent, ctx, locals, writeKind, type, it.value, it.cases,
				(immutable size_t i) => it.values[i]),
		(scope ref immutable LowExprKind.TailRecur it) {
			verify(isReturn(writeKind));
			writeTailRecur(writer, tempAlloc, indent, ctx, locals, it);
			return writeExprDone();
		},
		(scope ref immutable LowExprKind.ThreadLocalPtr x) =>
			inlineableSimple(() {
				writeChar(writer, '&');
				writeLowThreadLocalMangledName(writer, ctx.mangledNames, ctx.program.threadLocals[x.threadLocalIndex]);
			}),
		(scope ref immutable LowExprKind.Zeroed) =>
			inlineableSimple(() {
				writeZeroedValue(writer, ctx.ctx, type);
			}),
	)(expr.kind);
}

immutable(WriteExprResult) writeNonInlineable(
	scope ref Writer writer,
	immutable size_t indent,
	scope ref FunBodyCtx ctx,
	scope ref immutable WriteKind writeKind,
	immutable LowType type,
	scope void delegate() @safe @nogc pure nothrow cb,
) {
	if (!isInline(writeKind)) writeNewline(writer, indent);
	immutable(WriteExprResult) makeTemp() {
		immutable Temp temp = getNextTemp(ctx);
		if (!isVoid(type)) {
			writeTempDeclare(writer, ctx, type, temp);
			writeStatic(writer, " = ");
		}
		return immutable WriteExprResult(temp);
	}
	immutable WriteExprResult res = matchWriteKind!(immutable WriteExprResult)(
		writeKind,
		(ref immutable WriteKind.Inline) =>
			writeExprDone(),
		(ref immutable WriteKind.InlineOrTemp) =>
			makeTemp(),
		(immutable LowLocal* it) {
			writeLowLocalName(writer, ctx.mangledNames, *it);
			writeStatic(writer, " = ");
			return writeExprDone();
		},
		(ref immutable MakeTemp) =>
			makeTemp(),
		(ref immutable WriteKind.Return) {
			writeStatic(writer, "return ");
			return writeExprDone();
		},
		(ref immutable WriteKind.UseTemp it) {
			writeTempRef(writer, it.temp);
			writeStatic(writer, " = ");
			return writeExprDone();
		},
		(ref immutable WriteKind.Void) =>
			writeExprDone());
	cb();
	if (!isInline(writeKind)) writeChar(writer, ';');
	return res;
}

immutable(WriteExprResult) writeInlineable(
	ref Writer writer,
	ref TempAlloc tempAlloc,
	immutable size_t indent,
	ref FunBodyCtx ctx,
	scope ref immutable Locals locals,
	ref immutable WriteKind writeKind,
	immutable LowType type,
	scope immutable LowExpr[] args,
	scope void delegate(ref immutable WriteExprResult[]) @safe @nogc pure nothrow inline,
) {
	if (isInlineOrTemp(writeKind))
		return immutable WriteExprResult(immutable WriteExprResult.Done(
			writeExprsTempOrInline(writer, tempAlloc, indent, ctx, locals, args)));
	else if (isInline(writeKind)) {
		inline(asInline(writeKind).args);
		return writeExprDone();
	} else {
		immutable WriteExprResult[] argTemps = writeExprsTempOrInline(writer, tempAlloc, indent, ctx, locals,args);
		return writeNonInlineable(writer, indent, ctx, writeKind, type, () {
			inline(argTemps);
		});
	}
}

immutable(WriteExprResult) writeInlineableSingleArg(
	ref Writer writer,
	ref TempAlloc tempAlloc,
	immutable size_t indent,
	ref FunBodyCtx ctx,
	scope ref immutable Locals locals,
	ref immutable WriteKind writeKind,
	immutable LowType type,
	ref immutable LowExpr arg,
	scope void delegate(ref immutable WriteExprResult) @safe @nogc pure nothrow inline,
) {
	return writeInlineable(
		writer,
		tempAlloc,
		indent,
		ctx,
		locals,
		writeKind,
		type,
		arrLiteral!LowExpr(tempAlloc, [arg]),
		(ref immutable WriteExprResult[] args) {
			inline(only(args));
		});
}

immutable(WriteExprResult) writeInlineableSimple(
	ref Writer writer,
	ref TempAlloc tempAlloc,
	immutable size_t indent,
	ref FunBodyCtx ctx,
	scope ref immutable Locals locals,
	ref immutable WriteKind writeKind,
	immutable LowType type,
	scope void delegate() @safe @nogc pure nothrow inline,
) {
	return writeInlineable(
		writer,
		tempAlloc,
		indent,
		ctx,
		locals,
		writeKind,
		type,
		[],
		(ref immutable WriteExprResult[]) {
			if (!isVoid(type))
				inline();
		});
}

immutable(WriteExprResult) writeReturnVoid(
	ref Writer writer,
	immutable size_t indent,
	ref FunBodyCtx ctx,
	ref immutable WriteKind writeKind,
) {
	return writeReturnVoid(writer, indent, ctx, writeKind, null);
}

immutable(WriteExprResult) writeReturnVoid(
	ref Writer writer,
	immutable size_t indent,
	ref FunBodyCtx ctx,
	ref immutable WriteKind writeKind,
	scope void delegate() @safe @nogc pure nothrow cb,
) {
	return matchWriteKind!(immutable WriteExprResult)(
		writeKind,
		(ref immutable WriteKind.Inline) => unreachable!(immutable WriteExprResult),
		(ref immutable WriteKind.InlineOrTemp) => unreachable!(immutable WriteExprResult),
		(immutable LowLocal*) => unreachable!(immutable WriteExprResult),
		(ref immutable WriteKind.MakeTemp) => unreachable!(immutable WriteExprResult),
		(ref immutable WriteKind.Return) {
			if (cb != null) {
				writeNewline(writer, indent);
				cb();
			}
			writeChar(writer, ';');
			writeNewline(writer, indent);
			writeStatic(writer, "return;");
			return writeExprDone();
		},
		(ref immutable WriteKind.UseTemp) => unreachable!(immutable WriteExprResult),
		(ref immutable WriteKind.Void) {
			if (cb != null) {
				writeNewline(writer, indent);
				cb();
				writeChar(writer, ';');
			}
			return writeExprDone();
		});
}

immutable(WriteExprResult) writeCallExpr(
	ref Writer writer,
	ref TempAlloc tempAlloc,
	immutable size_t indent,
	ref FunBodyCtx ctx,
	scope ref immutable Locals locals,
	ref immutable WriteKind writeKind,
	immutable LowType type,
	ref immutable LowExprKind.Call a,
) {
	immutable WriteExprResult[] args = writeExprsTempOrInline(writer, tempAlloc, indent, ctx, locals, a.args);
	return writeNonInlineable(writer, indent, ctx, writeKind, type, () {
		immutable LowFun* called = &ctx.program.allFuns[a.called];
		writeLowFunMangledName(writer, ctx.mangledNames, a.called, *called);
		if (!isGlobal(called.body_)) {
			writeChar(writer, '(');
			writeTempOrInlines(writer, tempAlloc, ctx, locals, a.args, args);
			writeChar(writer, ')');
		}
	});
}

void writeTailRecur(
	ref Writer writer,
	ref TempAlloc tempAlloc,
	immutable size_t indent,
	ref FunBodyCtx ctx,
	scope ref immutable Locals locals,
	ref immutable LowExprKind.TailRecur a,
) {
	immutable LowParam[] params = ctx.program.allFuns[ctx.curFun].params;
	immutable WriteExprResult[] newValues =
		map!WriteExprResult(tempAlloc, a.updateParams, (ref immutable UpdateParam updateParam) =>
			writeExprTempOrInline(writer, tempAlloc, indent, ctx, locals, updateParam.newValue));
	zip!(UpdateParam, WriteExprResult)(
		a.updateParams,
		newValues,
		(ref immutable UpdateParam updateParam, ref immutable WriteExprResult newValue) {
			immutable LowParam param = params[updateParam.param.index];
			if (!isVoid(param.type)) {
				writeNewline(writer, indent);
				writeLowParamName(writer, ctx.mangledNames, param);
				writeStatic(writer, " = ");
				writeTempOrInline(writer, tempAlloc, ctx, locals, updateParam.newValue, newValue);
				writeChar(writer, ';');
			}
		});
	writeNewline(writer, indent);
	writeStatic(writer, "goto top;");
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
	writeChar(writer, '{');
	writeNat(writer, memberIndex);
	immutable LowUnion union_ = ctx.program.allUnions[asUnionType(type)];
	immutable LowType memberType = union_.members[memberIndex];
	if (!isVoid(memberType)) {
		writeStatic(writer, ", .as");
		writeNat(writer, memberIndex);
		writeStatic(writer, " = ");
		cbWriteMember();
	}
	writeChar(writer, '}');
}

void writeFunPtr(scope ref Writer writer, scope ref immutable Ctx ctx, immutable LowFunIndex a) {
	writeLowFunMangledName(writer, ctx.mangledNames, a, ctx.program.allFuns[a]);
}

void writeParamRef(scope ref Writer writer, scope ref const FunBodyCtx ctx, ref immutable LowExprKind.ParamRef a) {
	writeLowParamName(writer, ctx.mangledNames, ctx.program.allFuns[ctx.curFun].params[a.index.index]);
}

immutable(WriteExprResult) writeMatchUnion(
	scope ref Writer writer,
	ref TempAlloc tempAlloc,
	immutable size_t indent,
	scope ref FunBodyCtx ctx,
	scope ref immutable Locals locals,
	ref immutable WriteKind writeKind,
	immutable LowType type,
	scope ref immutable LowExprKind.MatchUnion a,
) {
	immutable Temp matchedValue = writeExprTemp(writer, tempAlloc, indent, ctx, locals, a.matchedValue);
	immutable WriteExprResultAndNested nested = getNestedWriteKind(writer, indent, ctx, type, writeKind);
	writeNewline(writer, indent);
	writeStatic(writer, "switch (");
	writeTempRef(writer, matchedValue);
	writeStatic(writer, ".kind) {");
	foreach (immutable size_t caseIndex, ref immutable LowExprKind.MatchUnion.Case case_; a.cases) {
		writeNewline(writer, indent + 1);
		writeStatic(writer, "case ");
		writeNat(writer, caseIndex);
		writeStatic(writer, ": {");
		if (has(case_.local) && !isVoid(force(case_.local).type)) {
			writeDeclareLocal(writer, indent + 2, ctx, *force(case_.local));
			writeStatic(writer, " = ");
			writeTempRef(writer, matchedValue);
			writeStatic(writer, ".as");
			writeNat(writer, caseIndex);
			writeChar(writer, ';');
			writeNewline(writer, indent + 2);
		}
		drop(writeExpr(writer, tempAlloc, indent + 2, ctx, locals, nested.writeKind, case_.then));
		if (!isReturn(nested.writeKind)) {
			writeNewline(writer, indent + 2);
			writeStatic(writer, "break;");
		}
		writeNewline(writer, indent + 1);
		writeChar(writer, '}');
	}
	writeDefaultAbort(writer, tempAlloc, indent, ctx, locals, nested.writeKind, type);
	writeNewline(writer, indent);
	writeChar(writer, '}');
	return nested.result;
}

void writeDefaultAbort(
	scope ref Writer writer,
	ref TempAlloc tempAlloc,
	immutable size_t indent,
	scope ref FunBodyCtx ctx,
	scope ref immutable Locals locals,
	scope ref immutable WriteKind writeKind,
	immutable LowType type,
) {
	writeNewline(writer, indent + 1);
	writeStatic(writer, "default:");
	writeNewline(writer, indent + 2);
	writeStatic(writer, "abort();");
	version (Windows) {
		if (!isVoid(type)) {
			drop(writeInlineableSimple(
				writer,
				tempAlloc,
				indent,
				ctx,
				locals,
				writeKind,
				type,
				() {
					writeZeroedValue(writer, ctx.ctx, type);
				}));
			writeChar(writer, ';');
		}
	}
}

//TODO: share code with writeMatchUnion
immutable(WriteExprResult) writeSwitch(
	ref Writer writer,
	ref TempAlloc tempAlloc,
	immutable size_t indent,
	ref FunBodyCtx ctx,
	scope ref immutable Locals locals,
	immutable WriteKind writeKind,
	immutable LowType type, // type returned by the switch
	ref immutable LowExpr value,
	immutable LowExpr[] cases,
	scope immutable(EnumValue) delegate(immutable size_t) @safe @nogc pure nothrow getValue,
) {
	immutable WriteExprResult valueResult = writeExprTempOrInline(writer, tempAlloc, indent, ctx, locals, value);
	immutable WriteExprResultAndNested nested = getNestedWriteKind(writer, indent, ctx, type, writeKind);
	writeStatic(writer, "switch (");
	writeTempOrInline(writer, tempAlloc, ctx, locals, value, valueResult);
	writeStatic(writer, ") {");
	foreach (immutable size_t caseIndex, ref immutable LowExpr case_; cases) {
		writeNewline(writer, indent + 1);
		writeStatic(writer, "case ");
		if (isSignedIntegral(asPrimitive(value.type)))
			writeInt(writer, getValue(caseIndex).asSigned());
		else
			writeNat(writer, getValue(caseIndex).asUnsigned());
		writeStatic(writer, ": {");
		drop(writeExpr(writer, tempAlloc, indent + 2, ctx, locals, nested.writeKind, case_));
		if (!isReturn(nested.writeKind)) {
			writeNewline(writer, indent + 2);
			writeStatic(writer, "break;");
		}
		writeNewline(writer, indent + 1);
		writeChar(writer, '}');
	}
	writeDefaultAbort(writer, tempAlloc, indent, ctx, locals, writeKind, type);
	writeNewline(writer, indent);
	writeChar(writer, '}');
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
	writeStatic(writer, targetIsPointer ? "->" : ".");
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
	matchConstant!void(
		a,
		(ref immutable Constant.ArrConstant it) {
			if (pos == ConstantRefPos.outer) writeCastToType(writer, ctx, type);
			immutable size_t size = ctx.program.allConstants.arrs[it.typeIndex].constants[it.index].length;
			writeChar(writer, '{');
			writeNat(writer, size);
			writeStatic(writer, ", ");
			if (size == 0)
				writeStatic(writer, "NULL");
			else
				writeConstantArrStorageName(writer, ctx.mangledNames, ctx.program, asRecordType(type), it.index);
			writeChar(writer, '}');
		},
		(immutable Constant.BoolConstant it) {
			writeChar(writer, it.value ? '1' : '0');
		},
		(ref immutable Constant.CString it) {
			writeChar(writer, '"');
			eachChar(ctx.program.allConstants.cStrings[it.index], (immutable char c) {
				writeEscapedChar_inner(writer, c);
			});
			writeChar(writer, '"');
		},
		(immutable Constant.Float it) {
			switch (asPrimitive(type)) {
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
			immutable bool isRawPtr = matchLowType!(
				immutable bool,
				(immutable LowType.ExternPtr) => unreachable!bool,
				(immutable LowType.FunPtr) => false,
				(immutable PrimitiveType) => unreachable!bool,
				(immutable LowType.PtrGc) => unreachable!bool,
				(immutable LowType.PtrRawConst) => true,
				(immutable LowType.PtrRawMut) => true,
				(immutable LowType.Record) => unreachable!bool,
				(immutable LowType.Union) => unreachable!bool,
			)(type);
			if (isRawPtr) writeStatic(writer, "((uint8_t*)");
			writeFunPtr(writer, ctx, mustGetAt(ctx.program.concreteFunToLowFunIndex, it.fun));
			if (isRawPtr) writeChar(writer, ')');
		},
		(immutable Constant.Integral it) {
			if (isSignedIntegral(asPrimitive(type))) {
				if (it.value == int.min)
					writeStatic(writer, "INT32_MIN");
				else if (it.value == long.min)
					// Can't write this as a literal since the '-' and rest are parsed separately,
					// and the abs of the minimum integer is out of range.
					writeStatic(writer, "INT64_MIN");
				else
					writeInt(writer, it.value);
			} else {
				writeNat(writer, it.value);
				writeChar(writer, 'u');
			}
		},
		(immutable Constant.Null) {
			writeStatic(writer, "NULL");
		},
		(immutable Constant.Pointer it) {
			writeChar(writer, '&');
			writeConstantPointerStorageName(writer, ctx.mangledNames, ctx.program, asPtrGcPointee(type), it.index);
		},
		(ref immutable Constant.Record it) {
			immutable LowField[] fields = ctx.program.allRecords[asRecordType(type)].fields;
			verify(sizeEq(fields, it.args));
			if (pos == ConstantRefPos.outer)
				writeCastToType(writer, ctx, type);
			writeChar(writer, '{');
			writeWithCommasZip!(LowField, Constant)(
				writer,
				fields,
				it.args,
				(ref immutable LowField field, ref immutable Constant arg) =>
					!isVoid(field.type),
				(ref immutable LowField field, ref immutable Constant arg) {
					writeConstantRef(writer, ctx, ConstantRefPos.inner, field.type, arg);
				});
			writeChar(writer, '}');
		},
		(ref immutable Constant.Union it) {
			immutable LowType memberType = ctx.program.allUnions[asUnionType(type)].members[it.memberIndex];
			writeCreateUnion(writer, ctx, pos, type, it.memberIndex, () {
				writeConstantRef(writer, ctx, ConstantRefPos.inner, memberType, it.arg);
			});
		},
		(immutable Constant.Void) {
			unreachable!void();
		});
}

immutable(WriteExprResult) writeSpecialUnary(
	ref Writer writer,
	ref TempAlloc tempAlloc,
	immutable size_t indent,
	ref FunBodyCtx ctx,
	scope ref immutable Locals locals,
	immutable WriteKind writeKind,
	immutable LowType type,
	ref immutable LowExprKind.SpecialUnary a,
) {
	immutable(WriteExprResult) prefix(immutable string prefix) {
		return writeInlineableSingleArg(
			writer,
			tempAlloc,
			indent,
			ctx,
			locals,
			writeKind,
			type,
			a.arg,
			(ref immutable WriteExprResult temp) {
				writeChar(writer, '(');
				writeStatic(writer, prefix);
				writeTempOrInline(writer, tempAlloc, ctx, locals, a.arg, temp);
				writeChar(writer, ')');
			});
	}

	immutable(WriteExprResult) specialCall(immutable string name) {
		return writeInlineableSingleArg(
			writer,
			tempAlloc,
			indent,
			ctx,
			locals,
			writeKind,
			type,
			a.arg,
			(ref immutable WriteExprResult temp) {
				writeStatic(writer, name);
				writeChar(writer, '(');
				writeTempOrInline(writer, tempAlloc, ctx, locals, a.arg, temp);
				writeChar(writer, ')');
			});
	}

	final switch (a.kind) {
		case LowExprKind.SpecialUnary.Kind.asAnyPtr:
			return prefix("(uint8_t*) ");
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
				writer,
				tempAlloc,
				indent,
				ctx,
				locals,
				writeKind,
				type,
				a.arg,
				(ref immutable WriteExprResult temp) {
					writeChar(writer, '(');
					writeCastToType(writer, ctx.ctx, type);
					writeTempOrInline(writer, tempAlloc, ctx, locals, a.arg, temp);
					writeChar(writer, ')');
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
		case LowExprKind.SpecialUnary.Kind.ptrTo:
		case LowExprKind.SpecialUnary.Kind.refOfVal:
			return writeInlineableSimple(writer, tempAlloc, indent, ctx, locals, writeKind, type, () {
				writeStatic(writer, "(&");
				writeLValue(writer, ctx, a.arg);
				writeChar(writer, ')');
			});
	}
}

void writeLValue(ref Writer writer, ref const FunBodyCtx ctx, ref immutable LowExpr expr) {
	matchLowExprKind!(
		void,
		(ref immutable LowExprKind.Call) => unreachable!void(),
		(ref immutable LowExprKind.CallFunPtr) => unreachable!void(),
		(ref immutable LowExprKind.CreateRecord) => unreachable!void(),
		(ref immutable LowExprKind.CreateUnion) => unreachable!void(),
		(ref immutable LowExprKind.If) => unreachable!void(),
		(ref immutable LowExprKind.InitConstants) => unreachable!void(),
		(ref immutable LowExprKind.Let) => unreachable!void(),
		(ref immutable LowExprKind.LocalRef it) {
			writeLowLocalName(writer, ctx.mangledNames, *it.local);
		},
		(ref immutable LowExprKind.LocalSet) => unreachable!void(),
		(ref immutable LowExprKind.Loop) => unreachable!void(),
		(ref immutable LowExprKind.LoopBreak) => unreachable!void(),
		(ref immutable LowExprKind.LoopContinue) => unreachable!void(),
		(ref immutable LowExprKind.MatchUnion) => unreachable!void(),
		(ref immutable LowExprKind.ParamRef it) {
			writeParamRef(writer, ctx, it);
		},
		(ref immutable LowExprKind.PtrCast) => todo!void("!"),
		(ref immutable LowExprKind.RecordFieldGet it) {
			writeLValue(writer, ctx, it.target);
			writeRecordFieldRef(writer, ctx, targetIsPointer(it), targetRecordType(it), it.fieldIndex);
		},
		(ref immutable LowExprKind.RecordFieldSet) => unreachable!void(),
		(ref immutable LowExprKind.Seq) => unreachable!void(),
		(ref immutable LowExprKind.SizeOf) => unreachable!void(),
		(ref immutable Constant) => unreachable!void(),
		(ref immutable LowExprKind.SpecialUnary it) {
			switch (it.kind) {
				case LowExprKind.SpecialUnary.Kind.ptrTo:
				case LowExprKind.SpecialUnary.Kind.refOfVal:
					writeStatic(writer, "(&");
					writeLValue(writer, ctx, it.arg);
					writeChar(writer, ')');
					break;
				case LowExprKind.SpecialUnary.Kind.deref:
					writeStatic(writer, "(*");
					writeLValue(writer, ctx, it.arg);
					writeChar(writer, ')');
					break;
				default:
					todo!void("!");
			}
		},
		(ref immutable LowExprKind.SpecialBinary) => unreachable!void(),
		(ref immutable LowExprKind.SpecialTernary) => unreachable!void(),
		(ref immutable LowExprKind.Switch0ToN) => unreachable!void(),
		(ref immutable LowExprKind.SwitchWithValues) => unreachable!void(),
		(ref immutable LowExprKind.TailRecur) => unreachable!void(),
		(ref immutable LowExprKind.ThreadLocalPtr) => unreachable!void(),
		(ref immutable LowExprKind.Zeroed) => unreachable!void(),
	)(expr.kind);
}

void writeZeroedValue(scope ref Writer writer, scope ref immutable Ctx ctx, scope immutable LowType type) {
	return matchLowTypeCombinePtr!(
		void,
		(immutable LowType.ExternPtr) {
			writeStatic(writer, "NULL");
		},
		(immutable LowType.FunPtr) {
			writeStatic(writer, "NULL");
		},
		(immutable PrimitiveType it) {
			if (it == PrimitiveType.void_)
				unreachable!void();
			else
				writeChar(writer, '0');
		},
		(immutable LowPtrCombine) {
			writeStatic(writer, "NULL");
		},
		(immutable LowType.Record it) {
			writeCastToType(writer, ctx, type);
			writeChar(writer, '{');
			immutable LowField[] fields = ctx.program.allRecords[it].fields;
			writeWithCommas!LowField(
				writer,
				fields,
				(ref immutable LowField field) =>
					!isVoid(field.type),
				(ref immutable LowField field) {
					writeZeroedValue(writer, ctx, field.type);
				});
			writeChar(writer, '}');
		},
		(immutable LowType.Union) {
			writeCastToType(writer, ctx, type);
			writeStatic(writer, "{0}");
		},
	)(type);
}

immutable(WriteExprResult) writeSpecialBinary(
	ref Writer writer,
	ref TempAlloc tempAlloc,
	immutable size_t indent,
	ref FunBodyCtx ctx,
	scope ref immutable Locals locals,
	immutable WriteKind writeKind,
	immutable LowType type,
	ref immutable LowExprKind.SpecialBinary it,
) {
	immutable(WriteExprResult) arg0() {
		return writeExprTempOrInline(writer, tempAlloc, indent, ctx, locals, it.left);
	}
	immutable(WriteExprResult) arg1() {
		return writeExprTempOrInline(writer, tempAlloc, indent, ctx, locals, it.right);
	}

	immutable(WriteExprResult) operator(string op) {
		return writeInlineable(
			writer,
			tempAlloc,
			indent,
			ctx,
			locals,
			writeKind,
			type,
			arrLiteral!LowExpr(tempAlloc, [it.left, it.right]),
			(ref immutable WriteExprResult[] args) {
				verify(args.length == 2);
				writeChar(writer, '(');
				writeTempOrInline(writer, tempAlloc, ctx, locals, it.left, args[0]);
				writeChar(writer, ' ');
				writeStatic(writer, op);
				writeChar(writer, ' ');
				writeTempOrInline(writer, tempAlloc, ctx, locals, it.right, args[1]);
				writeChar(writer, ')');
			});
	}

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
				tempAlloc,
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
				tempAlloc,
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
				writeStatic(writer, "*");
				writeTempOrInline(writer, tempAlloc, ctx, locals, it.left, temp0);
				writeStatic(writer, " = ");
				writeTempOrInline(writer, tempAlloc, ctx, locals, it.right, temp1);
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
	ref immutable WriteKind writeKind,
) {
	if (isVoid(type)) {
		verify(isVoid(writeKind) || isReturn(writeKind));
		return immutable WriteExprResultAndNested(writeExprDone(), writeKind);
	} if (isMakeTemp(writeKind) || isInlineOrTemp(writeKind)) {
		immutable Temp temp = getNextTemp(ctx);
		writeTempDeclare(writer, ctx, type, temp);
		writeChar(writer, ';');
		writeNewline(writer, indent);
		return immutable WriteExprResultAndNested(
			immutable WriteExprResult(temp),
			immutable WriteKind(immutable WriteKind.UseTemp(temp)));
	} else
		return immutable WriteExprResultAndNested(writeExprDone(), writeKind);
}

immutable(WriteExprResult) writeLogicalOperator(
	scope ref Writer writer,
	ref TempAlloc tempAlloc,
	immutable size_t indent,
	scope ref FunBodyCtx ctx,
	scope ref immutable Locals locals,
	immutable WriteKind writeKind,
	immutable LogicalOperator operator,
	scope ref immutable LowExpr left,
	scope ref immutable LowExpr right,
) {
	/*
	`a && b` ==> `if (a) { return b; } else { return 0; }`
	`a || b` ==> `if (a) { return 1; } else { return b; }`
	*/
	immutable WriteExprResult cond = writeExprTempOrInline(writer, tempAlloc, indent, ctx, locals, left);
	immutable WriteExprResultAndNested nested = getNestedWriteKind(writer, indent, ctx, boolType, writeKind);
	writeNewline(writer, indent);
	writeStatic(writer, "if (");
	writeTempOrInline(writer, tempAlloc, ctx, locals, left, cond);
	writeStatic(writer, ") {");
	final switch (operator) {
		case LogicalOperator.and:
			drop(writeExpr(writer, tempAlloc, indent + 1, ctx, locals, nested.writeKind, right));
			break;
		case LogicalOperator.or:
			drop(writeNonInlineable(writer, indent + 1, ctx, nested.writeKind, boolType, () {
				writeChar(writer, '1');
			}));
			break;
	}
	writeNewline(writer, indent);
	writeStatic(writer, "} else {");
	final switch (operator) {
		case LogicalOperator.and:
			drop(writeNonInlineable(writer, indent + 1, ctx, nested.writeKind, boolType, () {
				writeChar(writer, '0');
			}));
			break;
		case LogicalOperator.or:
			drop(writeExpr(writer, tempAlloc, indent + 1, ctx, locals, nested.writeKind, right));
			break;
	}
	writeNewline(writer, indent);
	writeChar(writer, '}');
	return nested.result;
}

immutable(WriteExprResult) writeIf(
	ref Writer writer,
	ref TempAlloc tempAlloc,
	immutable size_t indent,
	ref FunBodyCtx ctx,
	scope ref immutable Locals locals,
	immutable WriteKind writeKind,
	immutable LowType type,
	ref immutable LowExprKind.If a,
) {
	// TODO: writeExprTempOrInline
	immutable Temp temp0 = writeExprTemp(writer, tempAlloc, indent, ctx, locals, a.cond);
	immutable WriteExprResultAndNested nested = getNestedWriteKind(writer, indent, ctx, type, writeKind);
	writeNewline(writer, indent);
	writeStatic(writer, "if (");
	writeTempRef(writer, temp0);
	writeStatic(writer, ") {");
	drop(writeExpr(writer, tempAlloc, indent + 1, ctx, locals, nested.writeKind, a.then));
	writeNewline(writer, indent);
	writeStatic(writer, "} else {");
	drop(writeExpr(writer, tempAlloc, indent + 1, ctx, locals, nested.writeKind, a.else_));
	writeNewline(writer, indent);
	writeChar(writer, '}');
	return nested.result;
}

immutable(WriteExprResult) writeCallFunPtr(
	ref Writer writer,
	ref TempAlloc tempAlloc,
	immutable size_t indent,
	ref FunBodyCtx ctx,
	scope ref immutable Locals locals,
	ref immutable WriteKind writeKind,
	immutable LowType type,
	ref immutable LowExprKind.CallFunPtr a,
) {
	immutable WriteExprResult fn = writeExprTempOrInline(writer, tempAlloc, indent, ctx, locals, a.funPtr);
	immutable WriteExprResult[] args = writeExprsTempOrInline(writer, tempAlloc, indent, ctx, locals, a.args);
	return writeNonInlineable(writer, indent, ctx, writeKind, type, () {
		writeTempOrInline(writer, tempAlloc, ctx, locals, a.funPtr, fn);
		writeChar(writer, '(');
		writeTempOrInlines(writer, tempAlloc, ctx, locals, a.args, args);
		writeChar(writer, ')');
	});
}

immutable(WriteExprResult) writeLet(
	ref Writer writer,
	ref TempAlloc tempAlloc,
	immutable size_t indent,
	ref FunBodyCtx ctx,
	scope ref immutable Locals locals,
	ref immutable WriteKind writeKind,
	ref immutable LowExprKind.Let a,
) {
	if (!isInline(writeKind)) {
		if (isVoid(a.local.type))
			writeExprVoid(writer, tempAlloc, indent, ctx, locals, a.value);
		else {
			writeDeclareLocal(writer, indent, ctx, *a.local);
			writeChar(writer, ';');
			immutable WriteKind localWriteKind = immutable WriteKind(a.local);
			drop(writeExpr(writer, tempAlloc, indent, ctx, locals, localWriteKind, a.value));
			writeNewline(writer, indent);
		}
	}
	return writeExpr(writer, tempAlloc, indent, ctx, locals, writeKind, a.then);
}

immutable(WriteExprResult) writeLocalSet(
	ref Writer writer,
	ref TempAlloc tempAlloc,
	immutable size_t indent,
	ref FunBodyCtx ctx,
	scope ref immutable Locals locals,
	ref immutable WriteKind writeKind,
	ref immutable LowExprKind.LocalSet a,
) {
	if (isVoid(a.local.type))
		writeExprVoid(writer, tempAlloc, indent, ctx, locals, a.value);
	else {
		immutable WriteKind localWriteKind = immutable WriteKind(a.local);
		drop(writeExpr(writer, tempAlloc, indent, ctx, locals, localWriteKind, a.value));
	}
	return writeReturnVoid(writer, indent, ctx, writeKind);
}

immutable(WriteExprResult) writeLoop(
	ref Writer writer,
	ref TempAlloc tempAlloc,
	immutable size_t indent,
	ref FunBodyCtx ctx,
	scope ref immutable Locals locals,
	ref immutable WriteKind writeKind,
	immutable LowType type,
	ref immutable LowExprKind.Loop a,
) {
	immutable WriteExprResultAndNested nested = getNestedWriteKind(writer, indent, ctx, type, writeKind);

	immutable uint index = nextLoopIndex(locals);
	immutable LoopInfo loopInfo = immutable LoopInfo(index, nested.writeKind);
	immutable Locals innerLocals = addLoop(locals, &a, &loopInfo);

	writeNewline(writer, indent);
	writeStatic(writer, "for (;;) {");
	writeNewline(writer, indent + 1);

	writeExprVoid(writer, tempAlloc, indent + 1, ctx, innerLocals, a.body_);

	writeNewline(writer, indent);
	writeStatic(writer, "}");

	if (!isReturn(nested.writeKind)) {
		writeNewline(writer, indent);
		writeStatic(writer, "__break");
		writeNat(writer, index);
		writeStatic(writer, ":");
	}

	return nested.result;
}

immutable(WriteExprResult) writeLoopBreak(
	ref Writer writer,
	ref TempAlloc tempAlloc,
	immutable size_t indent,
	ref FunBodyCtx ctx,
	scope ref immutable Locals locals,
	ref immutable WriteKind writeKind,
	ref immutable LowExprKind.LoopBreak a,
) {
	verify(isVoid(writeKind));
	immutable LoopInfo* info = getLoop(locals, a.loop);
	drop(writeExpr(writer, tempAlloc, indent, ctx, locals, info.writeKind, a.value));
	if (!isReturn(info.writeKind)) {
		writeNewline(writer, indent);
		writeStatic(writer, "goto __break");
		writeNat(writer, info.index);
		writeChar(writer, ';');
	}
	return immutable WriteExprResult(immutable WriteExprResult.Done());
}

void writePrimitiveType(ref Writer writer, immutable PrimitiveType a) {
	writeStatic(writer, () {
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
	}());
}
