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
	writeMangledName,
	writeRecordName,
	writeStructMangledName;
import backend.writeTypes : TypeWriters, writeTypes;
import interpret.debugging : writeFunName, writeFunSig;
import lower.lowExprHelpers : boolType, voidType;
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
	isChar,
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
	LowType,
	LowUnion,
	matchLowExprKind,
	matchLowFunBody,
	matchLowType,
	matchLowTypeCombinePtr,
	name,
	PointerTypeAndConstantsLow,
	PrimitiveType,
	UpdateParam;
import model.model : EnumValue, name;
import model.typeLayout : sizeOfType;
import util.alloc.alloc : Alloc, TempAlloc;
import util.col.arr : empty, emptyArr, only, sizeEq;
import util.col.arrUtil : arrLiteral, every, map, zip;
import util.col.dict : mustGetAt;
import util.col.fullIndexDict : fullIndexDictEach, fullIndexDictEachKey, fullIndexDictGet, fullIndexDictGetPtr;
import util.opt : force, has, some;
import util.ptr : Ptr, ptrTrustMe, ptrTrustMe_mut;
import util.sym : AllSymbols;
import util.util : abs, drop, todo, unreachable, verify;
import util.writer :
	finishWriter,
	writeChar,
	writeEscapedChar_inner,
	writeFloatLiteral,
	writeInt,
	writeNat,
	writeNewline,
	Writer,
	writeStatic,
	writeWithCommas;

immutable(string) writeToC(
	ref Alloc alloc,
	ref TempAlloc tempAlloc,
	ref immutable AllSymbols allSymbols,
	ref immutable LowProgram program,
) {
	Writer writer = Writer(ptrTrustMe_mut(alloc));

	writeStatic(writer, "#include <stdatomic.h>\n");
	writeStatic(writer, "#include <stddef.h>\n"); // for NULL
	writeStatic(writer, "#include <stdint.h>\n");

	immutable Ctx ctx = immutable Ctx(ptrTrustMe(program), buildMangledNames(alloc, ptrTrustMe(allSymbols), program));

	writeStructs(alloc, writer, ctx);

	fullIndexDictEach!(LowFunIndex, LowFun)(
		program.allFuns,
		(immutable LowFunIndex funIndex, ref immutable LowFun fun) {
			writeFunDeclaration(writer, ctx, funIndex, fun);
		});

	writeConstants(writer, ctx, program.allConstants);

	fullIndexDictEach!(LowFunIndex, LowFun)(
		program.allFuns,
		(immutable LowFunIndex funIndex, ref immutable LowFun fun) {
			writeFunDefinition(writer, tempAlloc, ctx, funIndex, fun);
		});

	return finishWriter(writer);
}

private:

void writeConstants(ref Writer writer, ref immutable Ctx ctx, ref immutable AllConstantsLow allConstants) {
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
			if (isChar(a.elementType)) {
				writeChar(writer, '"');
				foreach (immutable Constant element; elements)
					writeEscapedChar_inner(writer, cast(immutable char) asIntegral(element).value);
				writeChar(writer, '"');
			} else {
				writeChar(writer, '{');
				writeWithCommas!Constant(writer, elements, (ref immutable Constant element) {
					writeConstantRef(writer, ctx, ConstantRefPos.inner, a.elementType, element);
				});
				writeChar(writer, '}');
			}
			writeStatic(writer, ";\n");
		}
	}

	foreach (ref immutable PointerTypeAndConstantsLow a; allConstants.pointers) {
		foreach (immutable size_t i, immutable Ptr!Constant pointee; a.constants) {
			declareConstantPointerStorage(writer, ctx, a.pointeeType, i);
			writeStatic(writer, " = ");
			writeConstantRef(writer, ctx, ConstantRefPos.inner, a.pointeeType, pointee.deref());
			writeStatic(writer, ";\n");
		}
	}
}

void declareConstantArrStorage(
	ref Writer writer,
	ref immutable Ctx ctx,
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
	ref Writer writer,
	ref immutable Ctx ctx,
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

	immutable Ptr!LowProgram programPtr;
	immutable MangledNames mangledNames;

	ref immutable(LowProgram) program() return scope immutable {
		return programPtr.deref();
	}
	ref immutable(AllSymbols) allSymbols() return scope immutable {
		return mangledNames.allSymbols.deref();
	}
}

struct FunBodyCtx {
	@safe @nogc pure nothrow:

	immutable Ptr!Ctx ctxPtr;
	immutable bool hasTailRecur;
	immutable LowFunIndex curFun;
	size_t nextTemp;

	ref immutable(Ctx) ctx() return scope const {
		return ctxPtr.deref();
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

void writeType(ref Writer writer, ref immutable Ctx ctx, ref immutable LowType t) {
	return matchLowTypeCombinePtr!(
		void,
		(immutable LowType.ExternPtr it) {
			writeStatic(writer, "struct ");
			writeStructMangledName(
				writer,
				ctx.mangledNames,
				fullIndexDictGet(ctx.program.allExternPtrTypes, it).source);
			writeChar(writer, '*');
		},
		(immutable LowType.FunPtr it) {
			writeStructMangledName(writer, ctx.mangledNames, fullIndexDictGet(ctx.program.allFunPtrTypes, it).source);
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
			writeStructMangledName(writer, ctx.mangledNames, fullIndexDictGet(ctx.program.allUnions, it).source);
		},
	)(t);
}

void writeRecordType(ref Writer writer, ref immutable Ctx ctx, immutable LowType.Record a) {
	writeStatic(writer, "struct ");
	writeRecordName(writer, ctx.mangledNames, ctx.program, a);
}

void writeCastToType(ref Writer writer, ref immutable Ctx ctx, ref immutable LowType type) {
	writeChar(writer, '(');
	writeType(writer, ctx, type);
	writeStatic(writer, ") ");
}

void doWriteParam(ref Writer writer, ref immutable Ctx ctx, ref immutable LowParam a) {
	writeType(writer, ctx, a.type);
	writeChar(writer, ' ');
	writeLowParamName(writer, ctx.mangledNames,a);
}

void writeStructHead(ref Writer writer, ref immutable Ctx ctx, immutable Ptr!ConcreteStruct source) {
	writeStatic(writer, "struct ");
	writeStructMangledName(writer, ctx.mangledNames, source);
	writeStatic(writer, " {");
}

void writeStructEnd(ref Writer writer) {
	writeStatic(writer, "\n};\n");
}

void writeRecord(ref Writer writer, ref immutable Ctx ctx, ref immutable LowRecord a) {
	writeStructHead(writer, ctx, a.source);
	foreach (ref immutable LowField field; a.fields) {
		writeStatic(writer, "\n\t");
		writeType(writer, ctx, field.type);
		writeChar(writer, ' ');
		writeMangledName(writer, ctx.mangledNames, name(field));
		writeChar(writer, ';');
	}
	writeStatic(writer, "\n}");
	if (a.packed)
		writeStatic(writer, " __attribute__ ((__packed__))");
	writeStatic(writer, ";\n");
}

void writeUnion(ref Writer writer, ref immutable Ctx ctx, ref immutable LowUnion a) {
	writeStructHead(writer, ctx, a.source);
	writeStatic(writer, "\n\tuint64_t kind;");
	writeStatic(writer, "\n\tunion {");
	foreach (immutable size_t memberIndex, immutable LowType member; a.members) {
		writeStatic(writer, "\n\t\t");
		writeType(writer, ctx, member);
		writeStatic(writer, " as");
		writeNat(writer, memberIndex);
		writeChar(writer, ';');
	}

	matchConcreteStructBody!void(
		body_(a.source.deref()),
		(ref immutable ConcreteStructBody.Builtin it) {
			verify(it.kind == BuiltinStructKind.fun);
			// Fun types must be 16 bytes
			if (every!LowType(a.members, (ref immutable LowType member) =>
				sizeOfType(ctx.program, member).size < 8)) {
				writeStatic(writer, "\n\t\tuint64_t __ensureSizeIs16;");
			}
		},
		(ref immutable(ConcreteStructBody.Enum)) {},
		(ref immutable(ConcreteStructBody.Flags)) {},
		(ref immutable(ConcreteStructBody.ExternPtr)) {},
		(ref immutable(ConcreteStructBody.Record)) {},
		(ref immutable(ConcreteStructBody.Union)) {});

	writeStatic(writer, "\n\t};");
	writeStructEnd(writer);
}

void declareStruct(ref Writer writer, ref immutable Ctx ctx, immutable Ptr!ConcreteStruct source) {
	writeStatic(writer, "struct ");
	writeStructMangledName(writer, ctx.mangledNames, source);
	writeStatic(writer, ";\n");
}

void staticAssertStructSize(
	ref Writer writer,
	ref immutable Ctx ctx,
	ref immutable LowType type,
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

void writeStructs(ref Alloc alloc, ref Writer writer, ref immutable Ctx ctx) {
	writeStatic(writer, "\nstruct void_ {};\n");

	scope immutable TypeWriters writers = immutable TypeWriters(
		(immutable Ptr!ConcreteStruct it) {
			declareStruct(writer, ctx, it);
		},
		(immutable LowType.FunPtr, ref immutable LowFunPtrType funPtr) {
			writeStatic(writer, "typedef ");
			writeType(writer, ctx, funPtr.returnType);
			writeStatic(writer, " (*");
			writeStructMangledName(writer, ctx.mangledNames, funPtr.source);
			writeStatic(writer, ")(");
			writeWithCommas!LowType(writer, funPtr.paramTypes, (ref immutable LowType paramType) {
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
	ref Writer writer,
	ref immutable Ctx ctx,
	immutable LowFunIndex funIndex,
	ref immutable LowFun fun,
) {
	if (isExtern(fun.body_) && isVoid(fun.returnType))
		writeStatic(writer, "void");
	else
		writeType(writer, ctx, fun.returnType);
	writeChar(writer, ' ');
	writeLowFunMangledName(writer, ctx.mangledNames, funIndex, fun);
	if (!isGlobal(fun.body_)) {
		writeChar(writer, '(');
		if (empty(fun.params))
			writeStatic(writer, "void");
		else {
			doWriteParam(writer, ctx, fun.params[0]);
			foreach (ref immutable LowParam p; fun.params[1 .. $]) {
				writeStatic(writer, ", ");
				doWriteParam(writer, ctx, p);
			}
		}
		writeChar(writer, ')');
	}
}

void writeFunDeclaration(
	ref Writer writer,
	ref immutable Ctx ctx,
	immutable LowFunIndex funIndex,
	ref immutable LowFun fun,
) {
	if (isExtern(fun.body_))
		writeStatic(writer, "extern ");
	writeFunReturnTypeNameAndParams(writer, ctx, funIndex, fun);
	writeStatic(writer, ";\n");
}

void writeFunDefinition(
	ref Writer writer,
	ref TempAlloc tempAlloc,
	ref immutable Ctx ctx,
	immutable LowFunIndex funIndex,
	ref immutable LowFun fun,
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

void writeFunWithExprBody(
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
	drop(writeExpr(writer, tempAlloc, 1, bodyCtx, writeKind, body_.expr));
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
	return immutable WriteExprResult(immutable WriteExprResult.Done(emptyArr!WriteExprResult()));
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
	ref Writer writer,
	ref FunBodyCtx ctx,
	ref immutable LowType type,
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
	ref Writer writer,
	ref TempAlloc tempAlloc,
	ref FunBodyCtx ctx,
	ref immutable LowExpr e,
	ref immutable WriteExprResult a,
) {
	matchWriteExprResult!void(
		a,
		(ref immutable WriteExprResult.Done it) {
			immutable WriteKind writeKind = immutable WriteKind(immutable WriteKind.Inline(it.args));
			immutable WriteExprResult res = writeExpr(writer, tempAlloc, 0, ctx, writeKind, e);
			verify(isDone(res) && empty(asDone(res).args));
		},
		(immutable Temp it) {
			writeTempRef(writer, it);
		});
}

void writeTempOrInlines(
	ref Writer writer,
	ref TempAlloc tempAlloc,
	ref FunBodyCtx ctx,
	immutable LowExpr[] exprs,
	immutable WriteExprResult[] args,
) {
	verify(sizeEq(exprs, args));
	writeWithCommas(writer, args.length, (immutable size_t i) {
		writeTempOrInline(writer, tempAlloc, ctx, exprs[i], args[i]);
	});
}

void writeDeclareLocal(
	ref Writer writer,
	immutable size_t indent,
	ref FunBodyCtx ctx,
	ref immutable LowLocal local,
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
	struct Void {}

	@trusted immutable this(immutable Inline a) { kind = Kind.inline; inline = a; }
	immutable this(immutable InlineOrTemp a) { kind = Kind.inlineOrTemp; inlineOrTemp = a; }
	@trusted immutable this(immutable Ptr!LowLocal a) { kind = Kind.local; local = a; }
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
		immutable Ptr!LowLocal local;
		immutable MakeTemp makeTemp;
		immutable Return return_;
		immutable UseTemp useTemp;
		immutable Void void_;
	}
}

immutable(bool) isInline(ref immutable WriteKind a) {
	return a.kind == WriteKind.Kind.inline;
}

@trusted immutable(WriteKind.Inline) asInline(ref immutable WriteKind a) {
	verify(isInline(a));
	return a.inline;
}

immutable(bool) isInlineOrTemp(ref immutable WriteKind a) {
	return a.kind == WriteKind.Kind.inlineOrTemp;
}

immutable(bool) isMakeTemp(ref immutable WriteKind a) {
	return a.kind == WriteKind.Kind.makeTemp;
}

immutable(bool) isReturn(ref immutable WriteKind a) {
	return a.kind == WriteKind.Kind.return_;
}

immutable(bool) isVoid(ref immutable WriteKind a) {
	return a.kind == WriteKind.Kind.void_;
}

@trusted T matchWriteKind(T)(
	ref immutable WriteKind a,
	scope T delegate(ref immutable WriteKind.Inline) @safe @nogc pure nothrow cbInline,
	scope T delegate(ref immutable WriteKind.InlineOrTemp) @safe @nogc pure nothrow cbInlineOrTemp,
	scope T delegate(immutable Ptr!LowLocal) @safe @nogc pure nothrow cbLocal,
	scope T delegate(ref immutable WriteKind.MakeTemp) @safe @nogc pure nothrow cbMakeTemp,
	scope T delegate(ref immutable WriteKind.Return) @safe @nogc pure nothrow cbReturn,
	scope T delegate(ref immutable WriteKind.UseTemp) @safe @nogc pure nothrow cbUseTemp,
	scope T delegate(ref immutable WriteKind.Void) @safe @nogc pure nothrow cbVoid,
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
	ref Writer writer,
	ref TempAlloc tempAlloc,
	immutable size_t indent,
	ref FunBodyCtx ctx,
	scope immutable LowExpr[] args,
) {
	return map!WriteExprResult(tempAlloc, args, (ref immutable LowExpr arg) =>
		writeExprTempOrInline(writer, tempAlloc, indent, ctx, arg));
}

immutable(Temp) writeExprTemp(
	ref Writer writer,
	ref TempAlloc tempAlloc,
	immutable size_t indent,
	ref FunBodyCtx ctx,
	ref immutable LowExpr expr,
) {
	immutable WriteKind writeKind = immutable WriteKind(immutable WriteKind.MakeTemp());
	immutable WriteExprResult res = writeExpr(writer, tempAlloc, indent, ctx, writeKind, expr);
	return asTemp(res);
}

immutable(WriteExprResult) writeExprTempOrInline(
	ref Writer writer,
	ref TempAlloc tempAlloc,
	immutable size_t indent,
	ref FunBodyCtx ctx,
	ref immutable LowExpr expr,
) {
	immutable WriteKind writeKind = immutable WriteKind(immutable WriteKind.InlineOrTemp());
	return writeExpr(writer, tempAlloc, indent, ctx, writeKind, expr);
}

immutable(WriteExprResult) writeExpr(
	ref Writer writer,
	ref TempAlloc tempAlloc,
	immutable size_t indent,
	ref FunBodyCtx ctx,
	ref immutable WriteKind writeKind,
	ref immutable LowExpr expr,
) {
	immutable LowType type = expr.type;
	immutable(WriteExprResult) nonInlineable(scope void delegate() @safe @nogc pure nothrow cb) {
		return writeNonInlineable(writer, indent, ctx, writeKind, type, cb);
	}
	immutable(WriteExprResult) inlineable(
		ref immutable LowExpr[] args,
		scope void delegate(ref immutable WriteExprResult[]) @safe @nogc pure nothrow inline,
	) {
		return writeInlineable(writer, tempAlloc, indent, ctx, writeKind, type, args, inline);
	}
	immutable(WriteExprResult) inlineableSingleArg(
		ref immutable LowExpr arg,
		scope void delegate(ref immutable WriteExprResult) @safe @nogc pure nothrow inline,
	) {
		return writeInlineableSingleArg(writer, tempAlloc, indent, ctx, writeKind, type, arg, inline);
	}
	immutable(WriteExprResult) inlineableSimple(scope void delegate() @safe @nogc pure nothrow inline) {
		return writeInlineableSimple(writer, tempAlloc, indent, ctx, writeKind, type, inline);
	}

	return matchLowExprKind!(
		immutable WriteExprResult,
		(ref immutable LowExprKind.Call it) =>
			writeCallExpr(writer, tempAlloc, indent, ctx, writeKind, type, it),
		(ref immutable LowExprKind.CallFunPtr it) =>
			writeCallFunPtr(writer, tempAlloc, indent, ctx, writeKind, type, it),
		(ref immutable LowExprKind.CreateRecord it) =>
			inlineable(it.args, (ref immutable WriteExprResult[] args) {
				writeCastToType(writer, ctx.ctx, type);
				writeChar(writer, '{');
				writeTempOrInlines(writer, tempAlloc, ctx, it.args, args);
				writeChar(writer, '}');
			}),
		(ref immutable LowExprKind.CreateUnion it) =>
			inlineableSingleArg(it.arg, (ref immutable WriteExprResult arg) {
				writeCreateUnion(writer, ctx.ctx, ConstantRefPos.outer, type, it.memberIndex, () {
					writeTempOrInline(writer, tempAlloc, ctx, it.arg, arg);
				});
			}),
		(ref immutable LowExprKind.If it) =>
			writeIf(writer, tempAlloc, indent, ctx, writeKind, type, it),
		(ref immutable LowExprKind.InitConstants) =>
			writeReturnVoid(writer, indent, ctx, writeKind, () {
				// writeToC doesn't need to do anything in 'init-constants'
				writeChar(writer, '0');
			}),
		(ref immutable LowExprKind.Let it) {
			if (!isInline(writeKind)) {
				writeDeclareLocal(writer, indent, ctx, it.local.deref());
				writeChar(writer, ';');
				immutable WriteKind localWriteKind = immutable WriteKind(it.local);
				drop(writeExpr(writer, tempAlloc, indent, ctx, localWriteKind, it.value));
				writeNewline(writer, indent);
			}
			return writeExpr(writer, tempAlloc, indent, ctx, writeKind, it.then);
		},
		(ref immutable LowExprKind.LocalRef it) =>
			inlineableSimple(() {
				writeLowLocalName(writer, ctx.mangledNames, it.local.deref());
			}),
		(ref immutable LowExprKind.MatchUnion it) =>
			writeMatchUnion(writer, tempAlloc, indent, ctx, writeKind, type, it),
		(ref immutable LowExprKind.ParamRef it) =>
			inlineableSimple(() {
				writeParamRef(writer, ctx, it);
			}),
		(ref immutable LowExprKind.PtrCast it) {
			return inlineableSingleArg(it.target, (ref immutable WriteExprResult arg) {
				writeChar(writer, '(');
				writeCastToType(writer, ctx.ctx, type);
				writeTempOrInline(writer, tempAlloc, ctx, it.target, arg);
				writeChar(writer, ')');
			});
		},
		(ref immutable LowExprKind.RecordFieldGet it) =>
			inlineableSingleArg(it.target, (ref immutable WriteExprResult recordValue) {
				writeTempOrInline(writer, tempAlloc, ctx, it.target, recordValue);
				writeRecordFieldRef(writer, ctx, it.targetIsPointer, it.record, it.fieldIndex);
			}),
		(ref immutable LowExprKind.RecordFieldSet it) {
			immutable WriteExprResult recordValue = writeExprTempOrInline(writer, tempAlloc, indent, ctx, it.target);
			immutable WriteExprResult fieldValue = writeExprTempOrInline(writer, tempAlloc, indent, ctx, it.value);
			return writeReturnVoid(writer, indent, ctx, writeKind, () {
				writeTempOrInline(writer, tempAlloc, ctx, it.target, recordValue);
				writeRecordFieldRef(writer, ctx, it.targetIsPointer, it.record, it.fieldIndex);
				writeStatic(writer, " = ");
				writeTempOrInline(writer, tempAlloc, ctx, it.value, fieldValue);
			});
		},
		(ref immutable LowExprKind.Seq it) {
			if (!isInline(writeKind)) {
				immutable WriteKind writeKindVoid = immutable WriteKind(immutable WriteKind.Void());
				drop(writeExpr(writer, tempAlloc, indent, ctx, writeKindVoid, it.first));
			}
			return writeExpr(writer, tempAlloc, indent, ctx, writeKind, it.then);
		},
		(ref immutable LowExprKind.SizeOf it) =>
			inlineableSimple(() {
				writeStatic(writer, "sizeof(");
				writeType(writer, ctx.ctx, it.type);
				writeChar(writer, ')');
			}),
		(ref immutable Constant it) =>
			inlineableSimple(() {
				writeConstantRef(writer, ctx.ctx, ConstantRefPos.outer, type, it);
			}),
		(ref immutable LowExprKind.SpecialUnary it) =>
			writeSpecialUnary(writer, tempAlloc, indent, ctx, writeKind, type, it),
		(ref immutable LowExprKind.SpecialBinary it) =>
			writeSpecialBinary(writer, tempAlloc, indent, ctx, writeKind, type, it),
		(ref immutable LowExprKind.Switch0ToN it) =>
			writeSwitch(writer, tempAlloc, indent, ctx, writeKind, type, it.value, it.cases, (immutable size_t i) =>
				immutable EnumValue(i)),
		(ref immutable LowExprKind.SwitchWithValues it) =>
			writeSwitch(writer, tempAlloc, indent, ctx, writeKind, type, it.value, it.cases, (immutable size_t i) =>
				it.values[i]),
		(ref immutable LowExprKind.TailRecur it) {
			verify(isReturn(writeKind));
			writeTailRecur(writer, tempAlloc, indent, ctx, it);
			return writeExprDone();
		},
		(ref immutable LowExprKind.Zeroed) =>
			inlineableSimple(() {
				writeZeroedValue(writer, ctx.ctx, type);
			}),
	)(expr.kind);
}

immutable(WriteExprResult) writeNonInlineable(
	ref Writer writer,
	immutable size_t indent,
	ref FunBodyCtx ctx,
	ref immutable WriteKind writeKind,
	ref immutable LowType type,
	scope void delegate() @safe @nogc pure nothrow cb,
) {
	if (!isInline(writeKind)) writeNewline(writer, indent);
	immutable(WriteExprResult) makeTemp() {
		immutable Temp temp = getNextTemp(ctx);
		writeTempDeclare(writer, ctx, type, temp);
		writeStatic(writer, " = ");
		return immutable WriteExprResult(temp);
	}
	immutable WriteExprResult res = matchWriteKind!(immutable WriteExprResult)(
		writeKind,
		(ref immutable WriteKind.Inline) =>
			writeExprDone(),
		(ref immutable WriteKind.InlineOrTemp) =>
			makeTemp(),
		(immutable Ptr!LowLocal it) {
			writeLowLocalName(writer, ctx.mangledNames, it.deref());
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
	ref immutable WriteKind writeKind,
	ref immutable LowType type,
	scope immutable LowExpr[] args,
	scope void delegate(ref immutable WriteExprResult[]) @safe @nogc pure nothrow inline,
) {
	if (isInlineOrTemp(writeKind))
		return immutable WriteExprResult(immutable WriteExprResult.Done(
			writeExprsTempOrInline(writer, tempAlloc, indent, ctx, args)));
	else if (isInline(writeKind)) {
		inline(asInline(writeKind).args);
		return writeExprDone();
	} else {
		immutable WriteExprResult[] argTemps = writeExprsTempOrInline(writer, tempAlloc, indent, ctx, args);
		return writeNonInlineable(writer, indent, ctx, writeKind, type, () {
			inline(argTemps);
		});
	}
}

immutable(WriteExprResult) returnZeroedValue(
	ref Writer writer,
	ref TempAlloc tempAlloc,
	immutable size_t indent,
	ref FunBodyCtx ctx,
	ref immutable WriteKind writeKind,
	ref immutable LowType type,
) {
	return writeInlineable(
		writer,
		tempAlloc,
		indent,
		ctx,
		writeKind,
		type,
		[],
		(ref immutable WriteExprResult[]) {
			writeZeroedValue(writer, ctx.ctx, type);
		});
}

immutable(WriteExprResult) writeInlineableSingleArg(
	ref Writer writer,
	ref TempAlloc tempAlloc,
	immutable size_t indent,
	ref FunBodyCtx ctx,
	ref immutable WriteKind writeKind,
	ref immutable LowType type,
	ref immutable LowExpr arg,
	scope void delegate(ref immutable WriteExprResult) @safe @nogc pure nothrow inline,
) {
	return writeInlineable(
		writer,
		tempAlloc,
		indent,
		ctx,
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
	ref immutable WriteKind writeKind,
	ref immutable LowType type,
	scope void delegate() @safe @nogc pure nothrow inline,
) {
	return writeInlineable(
		writer,
		tempAlloc,
		indent,
		ctx,
		writeKind,
		type,
		emptyArr!LowExpr,
		(ref immutable WriteExprResult[]) {
			inline();
		});
}

immutable(WriteExprResult) writeReturnVoid(
	ref Writer writer,
	immutable size_t indent,
	ref FunBodyCtx ctx,
	ref immutable WriteKind writeKind,
	scope void delegate() @safe @nogc pure nothrow cb,
) {
	if (isVoid(writeKind)) {
		writeNewline(writer, indent);
		cb();
		writeChar(writer, ';');
		return writeExprDone();
	} else
		return writeNonInlineable(writer, indent, ctx, writeKind, voidType, () {
			writeChar(writer, '(');
			cb();
			writeStatic(writer, ", (struct void_) {})");
		});
}

immutable(WriteExprResult) writeCallExpr(
	ref Writer writer,
	ref TempAlloc tempAlloc,
	immutable size_t indent,
	ref FunBodyCtx ctx,
	ref immutable WriteKind writeKind,
	ref immutable LowType type,
	ref immutable LowExprKind.Call a,
) {
	immutable WriteExprResult[] args = writeExprsTempOrInline(writer, tempAlloc, indent, ctx, a.args);
	return writeNonInlineable(writer, indent, ctx, writeKind, type, () {
		immutable Ptr!LowFun called = fullIndexDictGetPtr(ctx.ctx.program.allFuns, a.called);
		immutable bool isCVoid = isExtern(called.deref().body_) && isVoid(called.deref().returnType);
		if (isCVoid)
			//TODO: this is unnecessary if writeKind is not 'expr'
			writeChar(writer, '(');
		writeLowFunMangledName(writer, ctx.mangledNames, a.called, called.deref());
		if (!isGlobal(called.deref().body_)) {
			writeChar(writer, '(');
			writeTempOrInlines(writer, tempAlloc, ctx, a.args, args);
			writeChar(writer, ')');
		}
		if (isCVoid)
			writeStatic(writer, ", (struct void_) {})");
	});
}

void writeTailRecur(
	ref Writer writer,
	ref TempAlloc tempAlloc,
	immutable size_t indent,
	ref FunBodyCtx ctx,
	ref immutable LowExprKind.TailRecur a,
) {
	immutable LowParam[] params = fullIndexDictGet(ctx.ctx.program.allFuns, ctx.curFun).params;
	immutable WriteExprResult[] newValues =
		map!WriteExprResult(tempAlloc, a.updateParams, (ref immutable UpdateParam updateParam) =>
			writeExprTempOrInline(writer, tempAlloc, indent, ctx, updateParam.newValue));
	zip!(UpdateParam, WriteExprResult)(
		a.updateParams,
		newValues,
		(ref immutable UpdateParam updateParam, ref immutable WriteExprResult newValue) {
			writeNewline(writer, indent);
			writeLowParamName(writer, ctx.mangledNames, params[updateParam.param.index]);
			writeStatic(writer, " = ");
			writeTempOrInline(writer, tempAlloc, ctx, updateParam.newValue, newValue);
			writeChar(writer, ';');
		});
	writeNewline(writer, indent);
	writeStatic(writer, "goto top;");
}

void writeCreateUnion(
	ref Writer writer,
	ref immutable Ctx ctx,
	immutable ConstantRefPos pos,
	ref immutable LowType type,
	immutable size_t memberIndex,
	scope void delegate() @safe @nogc pure nothrow cbWriteMember,
) {
	if (pos == ConstantRefPos.outer) writeCastToType(writer, ctx, type);
	writeChar(writer, '{');
	writeNat(writer, memberIndex);
	writeStatic(writer, ", .as");
	writeNat(writer, memberIndex);
	writeStatic(writer, " = ");
	cbWriteMember();
	writeChar(writer, '}');
}

void writeFunPtr(ref Writer writer, ref immutable Ctx ctx, immutable LowFunIndex a) {
	writeLowFunMangledName(writer, ctx.mangledNames, a, fullIndexDictGet(ctx.program.allFuns, a));
}

void writeParamRef(ref Writer writer, ref const FunBodyCtx ctx, ref immutable LowExprKind.ParamRef a) {
	writeLowParamName(
		writer,
		ctx.mangledNames,
		fullIndexDictGet(ctx.ctx.program.allFuns, ctx.curFun).params[a.index.index]);
}

immutable(WriteExprResult) writeMatchUnion(
	ref Writer writer,
	ref TempAlloc tempAlloc,
	immutable size_t indent,
	ref FunBodyCtx ctx,
	ref immutable WriteKind writeKind,
	ref immutable LowType type,
	ref immutable LowExprKind.MatchUnion a,
) {
	immutable Temp matchedValue = writeExprTemp(writer, tempAlloc, indent, ctx, a.matchedValue);
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
		if (has(case_.local)) {
			writeDeclareLocal(writer, indent + 2, ctx, force(case_.local).deref());
			writeStatic(writer, " = ");
			writeTempRef(writer, matchedValue);
			writeStatic(writer, ".as");
			writeNat(writer, caseIndex);
			writeChar(writer, ';');
			writeNewline(writer, indent + 2);
		}
		drop(writeExpr(writer, tempAlloc, indent + 2, ctx, nested.writeKind, case_.then));
		if (!isReturn(nested.writeKind)) {
			writeNewline(writer, indent + 2);
			writeStatic(writer, "break;");
		}
		writeNewline(writer, indent + 1);
		writeChar(writer, '}');
	}
	writeNewline(writer, indent + 1);
	writeStatic(writer, "default:");
	writeNewline(writer, indent + 2);
	drop(returnZeroedValue(writer, tempAlloc, indent, ctx, nested.writeKind, type));
	writeChar(writer, ';');
	writeNewline(writer, indent);
	writeChar(writer, '}');
	return nested.result;
}

//TODO: share code with writeMatchUnion
immutable(WriteExprResult) writeSwitch(
	ref Writer writer,
	ref TempAlloc tempAlloc,
	immutable size_t indent,
	ref FunBodyCtx ctx,
	immutable WriteKind writeKind,
	ref immutable LowType type, // type returned by the switch
	ref immutable LowExpr value,
	immutable LowExpr[] cases,
	scope immutable(EnumValue) delegate(immutable size_t) @safe @nogc pure nothrow getValue,
) {
	immutable WriteExprResult valueResult = writeExprTempOrInline(writer, tempAlloc, indent, ctx, value);
	immutable WriteExprResultAndNested nested = getNestedWriteKind(writer, indent, ctx, type, writeKind);
	writeStatic(writer, "switch (");
	writeTempOrInline(writer, tempAlloc, ctx, value, valueResult);
	writeStatic(writer, ") {");
	foreach (immutable size_t caseIndex, ref immutable LowExpr case_; cases) {
		writeNewline(writer, indent + 1);
		writeStatic(writer, "case ");
		if (isSignedIntegral(value.type)) {
			writeInt(writer, getValue(caseIndex).asSigned());
		} else {
			writeNat(writer, getValue(caseIndex).asUnsigned());
		}
		writeStatic(writer, ": {");
		drop(writeExpr(writer, tempAlloc, indent + 2, ctx, nested.writeKind, case_));
		if (!isReturn(nested.writeKind)) {
			writeNewline(writer, indent + 2);
			writeStatic(writer, "break;");
		}
		writeNewline(writer, indent + 1);
		writeChar(writer, '}');
	}
	writeNewline(writer, indent + 1);
	writeStatic(writer, "default:");
	writeNewline(writer, indent + 2);
	if (isReturn(nested.writeKind))
		writeStatic(writer, "return ");
	writeZeroedValue(writer, ctx.ctx, type);
	writeChar(writer, ';');
	writeNewline(writer, indent);
	writeChar(writer, '}');
	return nested.result;
}

immutable(bool) isSignedIntegral(ref immutable LowType a) {
	final switch (asPrimitive(a)) {
		case PrimitiveType.bool_:
		case PrimitiveType.char_:
		case PrimitiveType.float32:
		case PrimitiveType.float64:
		case PrimitiveType.void_:
			return unreachable!(immutable bool);
		case PrimitiveType.int8:
		case PrimitiveType.int16:
		case PrimitiveType.int32:
		case PrimitiveType.int64:
			return true;
		case PrimitiveType.nat8:
		case PrimitiveType.nat16:
		case PrimitiveType.nat32:
		case PrimitiveType.nat64:
			return false;
	}
}

void writeRecordFieldRef(
	ref Writer writer,
	ref const FunBodyCtx ctx,
	immutable bool targetIsPointer,
	immutable LowType.Record record,
	immutable size_t fieldIndex,
) {
	writeStatic(writer, targetIsPointer ? "->" : ".");
	writeMangledName(
		writer,
		ctx.mangledNames,
		name(fullIndexDictGet(ctx.ctx.program.allRecords, record).fields[fieldIndex]));
}

// For some reason, providing a type for a record makes it non-constant.
// But that is mandatory at the outermost level.
enum ConstantRefPos {
	outer,
	inner,
}

void writeConstantRef(
	ref Writer writer,
	ref immutable Ctx ctx,
	immutable ConstantRefPos pos,
	ref immutable LowType type,
	ref immutable Constant a,
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
			foreach (immutable char c; ctx.program.allConstants.cStrings[it.index])
				writeEscapedChar_inner(writer, c);
			writeChar(writer, '"');
		},
		(immutable double it) {
			writeFloatLiteral(writer, it);
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
				if (it.value == long.min)
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
			immutable LowField[] fields = fullIndexDictGet(ctx.program.allRecords, asRecordType(type)).fields;
			verify(sizeEq(fields, it.args));
			if (pos == ConstantRefPos.outer)
				writeCastToType(writer, ctx, type);
			writeChar(writer, '{');
			writeWithCommas(writer, it.args.length, (immutable size_t i) {
				writeConstantRef(writer, ctx, ConstantRefPos.inner, fields[i].type, it.args[i]);
			});
			writeChar(writer, '}');
		},
		(ref immutable Constant.Union it) {
			immutable LowType memberType =
				fullIndexDictGet(ctx.program.allUnions, asUnionType(type)).members[it.memberIndex];
			writeCreateUnion(writer, ctx, pos, type, it.memberIndex, () {
				writeConstantRef(writer, ctx, ConstantRefPos.inner, memberType, it.arg);
			});
		},
		(immutable Constant.Void) {
			writeStatic(writer, pos == ConstantRefPos.outer ? "(struct void_) {}" : "{}");
		});
}

immutable(bool) isSignedIntegral(immutable PrimitiveType a) {
	switch (a) {
		case PrimitiveType.int8:
		case PrimitiveType.int16:
		case PrimitiveType.int32:
		case PrimitiveType.int64:
			return true;
		case PrimitiveType.bool_:
		case PrimitiveType.char_:
		case PrimitiveType.nat8:
		case PrimitiveType.nat16:
		case PrimitiveType.nat32:
		case PrimitiveType.nat64:
			return false;
		default:
			return unreachable!(immutable bool);
	}
}

immutable(WriteExprResult) writeSpecialUnary(
	ref Writer writer,
	ref TempAlloc tempAlloc,
	immutable size_t indent,
	ref FunBodyCtx ctx,
	immutable WriteKind writeKind,
	ref immutable LowType type,
	ref immutable LowExprKind.SpecialUnary a,
) {
	immutable(WriteExprResult) prefix(immutable string prefix) {
		return writeInlineableSingleArg(
			writer,
			tempAlloc,
			indent,
			ctx,
			writeKind,
			type,
			a.arg,
			(ref immutable WriteExprResult temp) {
				writeChar(writer, '(');
				writeStatic(writer, prefix);
				writeTempOrInline(writer, tempAlloc, ctx, a.arg, temp);
				writeChar(writer, ')');
			});
	}

	immutable(WriteExprResult) specialCall(immutable string name) {
		return writeInlineableSingleArg(
			writer,
			tempAlloc,
			indent,
			ctx,
			writeKind,
			type,
			a.arg,
			(ref immutable WriteExprResult temp) {
				writeStatic(writer, name);
				writeChar(writer, '(');
				writeTempOrInline(writer, tempAlloc, ctx, a.arg, temp);
				writeChar(writer, ')');
			});
	}

	final switch (a.kind) {
		case LowExprKind.SpecialUnary.Kind.asAnyPtr:
			return prefix("(uint8_t*) ");
		case LowExprKind.SpecialUnary.Kind.asRef:
		case LowExprKind.SpecialUnary.Kind.enumToIntegral:
		case LowExprKind.SpecialUnary.Kind.toCharFromNat8:
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
				writeKind,
				type,
				a.arg,
				(ref immutable WriteExprResult temp) {
					writeChar(writer, '(');
					writeCastToType(writer, ctx.ctx, type);
					writeTempOrInline(writer, tempAlloc, ctx, a.arg, temp);
					writeChar(writer, ')');
				});
		case LowExprKind.SpecialUnary.Kind.bitwiseNotNat8:
		case LowExprKind.SpecialUnary.Kind.bitwiseNotNat16:
		case LowExprKind.SpecialUnary.Kind.bitwiseNotNat32:
		case LowExprKind.SpecialUnary.Kind.bitwiseNotNat64:
			return prefix("~");
		case LowExprKind.SpecialUnary.Kind.countOnesNat64:
			return specialCall("__builtin_popcountl");
		case LowExprKind.SpecialUnary.Kind.deref:
			return prefix("*");
		case LowExprKind.SpecialUnary.Kind.isNanFloat32:
		case LowExprKind.SpecialUnary.Kind.isNanFloat64:
			return specialCall("__builtin_isnan");
		case LowExprKind.SpecialUnary.Kind.ptrTo:
		case LowExprKind.SpecialUnary.Kind.refOfVal:
			return writeInlineableSimple(writer, tempAlloc, indent, ctx, writeKind, type, () {
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
			writeLowLocalName(writer, ctx.mangledNames, it.local.deref());
		},
		(ref immutable LowExprKind.MatchUnion) => unreachable!void(),
		(ref immutable LowExprKind.ParamRef it) {
			writeParamRef(writer, ctx, it);
		},
		(ref immutable LowExprKind.PtrCast) => todo!void("!"),
		(ref immutable LowExprKind.RecordFieldGet it) {
			writeLValue(writer, ctx, it.target);
			writeRecordFieldRef(writer, ctx, it.targetIsPointer, it.record, it.fieldIndex);
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
		(ref immutable LowExprKind.Switch0ToN) => unreachable!void(),
		(ref immutable LowExprKind.SwitchWithValues) => unreachable!void(),
		(ref immutable LowExprKind.TailRecur) => unreachable!void(),
		(ref immutable LowExprKind.Zeroed) => unreachable!void(),
	)(expr.kind);
}

void writeZeroedValue(ref Writer writer, ref immutable Ctx ctx, ref immutable LowType type) {
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
				writeStatic(writer, "(struct void_) {}");
			else
				writeChar(writer, '0');
		},
		(immutable LowPtrCombine) {
			writeStatic(writer, "NULL");
		},
		(immutable LowType.Record it) {
			writeCastToType(writer, ctx, type);
			writeChar(writer, '{');
			immutable LowField[] fields = fullIndexDictGet(ctx.program.allRecords, it).fields;
			writeWithCommas!LowField(writer, fields, (ref immutable LowField field) {
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
	immutable WriteKind writeKind,
	ref immutable LowType type,
	ref immutable LowExprKind.SpecialBinary it,
) {
	immutable(WriteExprResult) arg0() {
		return writeExprTempOrInline(writer, tempAlloc, indent, ctx, it.left);
	}
	immutable(WriteExprResult) arg1() {
		return writeExprTempOrInline(writer, tempAlloc, indent, ctx, it.right);
	}

	immutable(WriteExprResult) operator(string op) {
		return writeInlineable(
			writer,
			tempAlloc,
			indent,
			ctx,
			writeKind,
			type,
			arrLiteral!LowExpr(tempAlloc, [it.left, it.right]),
			(ref immutable WriteExprResult[] args) {
				verify(args.length == 2);
				writeChar(writer, '(');
				writeTempOrInline(writer, tempAlloc, ctx, it.left, args[0]);
				writeChar(writer, ' ');
				writeStatic(writer, op);
				writeChar(writer, ' ');
				writeTempOrInline(writer, tempAlloc, ctx, it.right, args[1]);
				writeChar(writer, ')');
			});
	}

	final switch (it.kind) {
		case LowExprKind.SpecialBinary.Kind.addFloat32:
		case LowExprKind.SpecialBinary.Kind.addFloat64:
		case LowExprKind.SpecialBinary.Kind.addPtrAndNat64:
		case LowExprKind.SpecialBinary.Kind.wrapAddInt16:
		case LowExprKind.SpecialBinary.Kind.wrapAddInt32:
		case LowExprKind.SpecialBinary.Kind.wrapAddInt64:
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
		case LowExprKind.SpecialBinary.Kind.mulFloat64:
		case LowExprKind.SpecialBinary.Kind.wrapMulInt16:
		case LowExprKind.SpecialBinary.Kind.wrapMulInt32:
		case LowExprKind.SpecialBinary.Kind.wrapMulInt64:
		case LowExprKind.SpecialBinary.Kind.wrapMulNat16:
		case LowExprKind.SpecialBinary.Kind.wrapMulNat32:
		case LowExprKind.SpecialBinary.Kind.wrapMulNat64:
			return operator("*");
		case LowExprKind.SpecialBinary.Kind.or:
			return writeLogicalOperator(
				writer,
				tempAlloc,
				indent,
				ctx,
				writeKind,
				LogicalOperator.or,
				it.left,
				it.right);
		case LowExprKind.SpecialBinary.Kind.subFloat64:
		case LowExprKind.SpecialBinary.Kind.subPtrAndNat64:
		case LowExprKind.SpecialBinary.Kind.wrapSubInt16:
		case LowExprKind.SpecialBinary.Kind.wrapSubInt32:
		case LowExprKind.SpecialBinary.Kind.wrapSubInt64:
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
		case LowExprKind.SpecialBinary.Kind.unsafeDivInt64:
		case LowExprKind.SpecialBinary.Kind.unsafeDivNat64:
			return operator("/");
		case LowExprKind.SpecialBinary.Kind.unsafeModNat64:
			return operator("%");
		case LowExprKind.SpecialBinary.Kind.writeToPtr:
			immutable WriteExprResult temp0 = arg0();
			immutable WriteExprResult temp1 = arg1();
			return writeReturnVoid(writer, indent, ctx, writeKind, () {
				writeStatic(writer, "*");
				writeTempOrInline(writer, tempAlloc, ctx, it.left, temp0);
				writeStatic(writer, " = ");
				writeTempOrInline(writer, tempAlloc, ctx, it.right, temp1);
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
	ref Writer writer,
	immutable size_t indent,
	ref FunBodyCtx ctx,
	ref immutable LowType type,
	ref immutable WriteKind writeKind,
) {
	if (isMakeTemp(writeKind) || isInlineOrTemp(writeKind)) {
		immutable Temp temp = getNextTemp(ctx);
		writeTempDeclare(writer, ctx, type, temp);
		writeChar(writer, ';');
		writeNewline(writer, indent);
		return immutable WriteExprResultAndNested(
			immutable WriteExprResult(temp),
			immutable WriteKind(immutable WriteKind.UseTemp(temp)));
	} else
		return immutable WriteExprResultAndNested(
			writeExprDone(),
			writeKind);
}

immutable(WriteExprResult) writeLogicalOperator(
	ref Writer writer,
	ref TempAlloc tempAlloc,
	immutable size_t indent,
	ref FunBodyCtx ctx,
	immutable WriteKind writeKind,
	immutable LogicalOperator operator,
	ref immutable LowExpr left,
	ref immutable LowExpr right,
) {
	/*
	`a && b` ==> `if (a) { return b; } else { return 0; }`
	`a || b` ==> `if (a) { return 1; } else { return b; }`
	*/
	immutable WriteExprResult cond = writeExprTempOrInline(writer, tempAlloc, indent, ctx, left);
	immutable WriteExprResultAndNested nested = getNestedWriteKind(writer, indent, ctx, boolType, writeKind);
	writeNewline(writer, indent);
	writeStatic(writer, "if (");
	writeTempOrInline(writer, tempAlloc, ctx, left, cond);
	writeStatic(writer, ") {");
	final switch (operator) {
		case LogicalOperator.and:
			drop(writeExpr(writer, tempAlloc, indent + 1, ctx, nested.writeKind, right));
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
			drop(writeExpr(writer, tempAlloc, indent + 1, ctx, nested.writeKind, right));
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
	immutable WriteKind writeKind,
	ref immutable LowType type,
	ref immutable LowExprKind.If a,
) {
	// TODO: writeExprTempOrInline
	immutable Temp temp0 = writeExprTemp(writer, tempAlloc, indent, ctx, a.cond);
	immutable WriteExprResultAndNested nested = getNestedWriteKind(writer, indent, ctx, type, writeKind);
	writeNewline(writer, indent);
	writeStatic(writer, "if (");
	writeTempRef(writer, temp0);
	writeStatic(writer, ") {");
	drop(writeExpr(writer, tempAlloc, indent + 1, ctx, nested.writeKind, a.then));
	writeNewline(writer, indent);
	writeStatic(writer, "} else {");
	drop(writeExpr(writer, tempAlloc, indent + 1, ctx, nested.writeKind, a.else_));
	writeNewline(writer, indent);
	writeChar(writer, '}');
	return nested.result;
}

immutable(WriteExprResult) writeCallFunPtr(
	ref Writer writer,
	ref TempAlloc tempAlloc,
	immutable size_t indent,
	ref FunBodyCtx ctx,
	ref immutable WriteKind writeKind,
	ref immutable LowType type,
	ref immutable LowExprKind.CallFunPtr a,
) {
	immutable WriteExprResult fn = writeExprTempOrInline(writer, tempAlloc, indent, ctx, a.funPtr);
	immutable WriteExprResult[] args = writeExprsTempOrInline(writer, tempAlloc, indent, ctx, a.args);
	return writeNonInlineable(writer, indent, ctx, writeKind, type, () {
		writeTempOrInline(writer, tempAlloc, ctx, a.funPtr, fn);
		writeChar(writer, '(');
		writeTempOrInlines(writer, tempAlloc, ctx, a.args, args);
		writeChar(writer, ')');
	});
}

void writePrimitiveType(ref Writer writer, immutable PrimitiveType a) {
	writeStatic(writer, () {
		final switch (a) {
			case PrimitiveType.bool_:
				return "uint8_t";
			case PrimitiveType.char_:
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
				return "struct void_";
		}
	}());
}
