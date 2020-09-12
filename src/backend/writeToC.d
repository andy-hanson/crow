module backend.writeToC;

@safe @nogc pure nothrow:

import lowModel :
	isExtern,
	isGlobal,
	isVoid,
	LowExpr,
	LowExprKind,
	LowExternPtrType,
	LowField,
	LowFun,
	LowFunBody,
	LowFunExprBody,
	LowFunIndex,
	LowFunPtrType,
	LowLocal,
	LowParam,
	LowProgram,
	LowRecord,
	LowType,
	LowUnion,
	matchLowExprKind,
	matchLowFunBody,
	matchLowType,
	matchSpecialConstant,
	PrimitiveType;

import util.alloc.stackAlloc : StackAlloc;
import util.bools : Bool, False, True;
import util.collection.arr : Arr, at, empty, first, range, setAt, size;
import util.collection.arrUtil : every, exists, fillArr_mut, tail;
import util.collection.str : Str, strEq, strLiteral;
import util.opt : force, has;
import util.ptr : Ptr, ptrTrustMe, ptrTrustMe_mut;
import util.util : unreachable;
import util.writer :
	finishWriter,
	newline,
	writeChar,
	writeEscapedChar,
	writeNat,
	Writer,
	writeStatic,
	writeStr,
	writeWithCommas;

immutable(Str) writeToC(Alloc)(
	ref Alloc alloc,
	ref immutable LowProgram program,
) {
	Writer!Alloc writer = Writer!Alloc(ptrTrustMe_mut(alloc));

	writeStatic(writer, "#include <assert.h>\n");
	writeStatic(writer, "#include <errno.h>\n");
	writeStatic(writer, "#include <stdatomic.h>\n");
	writeStatic(writer, "#include <stddef.h>\n"); // for NULL
	writeStatic(writer, "#include <stdint.h>\n");

	immutable Ctx ctx = immutable Ctx(ptrTrustMe(program));

	writeStructs(writer, ctx);

	foreach (ref immutable LowFun fun; range(program.allFuns))
		writeFunDeclaration(writer, ctx, fun);

	foreach (immutable size_t funIndex; 0..size(program.allFuns)) {
		immutable FunBodyCtx funBodyCtx = immutable FunBodyCtx(ptrTrustMe(ctx), immutable LowFunIndex(funIndex));
		writeFunDefinition(writer, funBodyCtx, immutable LowFunIndex(funIndex), at(program.allFuns, funIndex));
	}

	immutable LowFunIndex mainIndex = immutable LowFunIndex(size(program.allFuns));
	immutable FunBodyCtx mainFunBodyCtx = immutable FunBodyCtx(ptrTrustMe(ctx), mainIndex);
	writeFunDefinition(writer, mainFunBodyCtx, mainIndex, program.main);

	return finishWriter(writer);
}

struct Ctx {
	immutable Ptr!LowProgram program;
}

struct FunBodyCtx {
	immutable Ptr!Ctx ctx;
	immutable LowFunIndex curFun;
}

void writeType(Alloc)(ref Writer!Alloc writer, ref immutable Ctx ctx, ref immutable LowType t) {
	return matchLowType!void(
		t,
		(immutable LowType.ExternPtr it) {
			writeStatic(writer, "struct ");
			writeStr(writer, at(ctx.program.allExternPtrTypes, it.index).mangledName);
			writeChar(writer, '*');
		},
		(immutable LowType.FunPtr it) {
			writeStr(writer, at(ctx.program.allFunPtrTypes, it.index).mangledName);
		},
		(immutable LowType.NonFunPtr it) {
			writeType(writer, ctx, it.pointee);
			writeChar(writer, '*');
		},
		(immutable PrimitiveType it) {
			writePrimitiveType(writer, it);
		},
		(immutable LowType.Record it) {
			writeStatic(writer, "struct ");
			writeStr(writer, at(ctx.program.allRecords, it.index).mangledName);
		},
		(immutable LowType.Union it) {
			writeStatic(writer, "struct ");
			writeStr(writer, at(ctx.program.allUnions, it.index).mangledName);
		});
}

void writeCastToType(Alloc)(ref Writer!Alloc writer, ref immutable Ctx ctx, ref immutable LowType type) {
	writeChar(writer, '(');
	writeType(writer, ctx, type);
	writeStatic(writer, ") ");
}

void doWriteParam(Alloc)(ref Writer!Alloc writer, ref immutable Ctx ctx, ref immutable LowParam a) {
	writeType(writer, ctx, a.type);
	writeChar(writer, ' ');
	writeStr(writer, a.mangledName);
}

void writeStructHead(Alloc)(ref Writer!Alloc writer, immutable Str mangledName) {
	writeStatic(writer, "struct ");
	writeStr(writer, mangledName);
	writeStatic(writer, " {");
}

void writeStructEnd(Alloc)(ref Writer!Alloc writer) {
	writeStatic(writer, "\n};\n");
}

void writeRecord(Alloc)(ref Writer!Alloc writer, ref immutable Ctx ctx, ref immutable LowRecord a) {
	writeStructHead(writer, a.mangledName);
	if (empty(a.fields))
		// An empty structure is undefined behavior in C.
		writeStatic(writer, "\n\tuint8_t __mustBeNonEmpty;\n};\n");
	else {
		foreach (ref immutable LowField field; range(a.fields)) {
			writeStatic(writer, "\n\t");
			writeType(writer, ctx, field.type);
			writeChar(writer, ' ');
			writeStr(writer, field.mangledName);
			writeChar(writer, ';');
		}
		writeStructEnd(writer);
	}
}

void writeUnion(Alloc)(ref Writer!Alloc writer, ref immutable Ctx ctx, ref immutable LowUnion a) {
	writeStructHead(writer, a.mangledName);
	writeStatic(writer, "\n\tint kind;");
	writeStatic(writer, "\n\tunion {");
	foreach (immutable size_t memberIndex; 0..size(a.members)) {
		writeStatic(writer, "\n\t\t");
		writeType(writer, ctx, at(a.members, memberIndex));
		writeStatic(writer, " as");
		writeNat(writer, memberIndex);
		writeChar(writer, ';');
	}
	writeStatic(writer, "\n\t};");
	writeStructEnd(writer);
}

enum StructState {
	none,
	declared,
	defined,
}

struct StructStates {
	Arr!Bool funPtrStates; // No need to define, just declared or not
	Arr!StructState recordStates;
	Arr!StructState unionStates;
}

immutable(Bool) canReferenceTypeAsValue(
	ref immutable Ctx ctx,
	ref const StructStates states,
	ref immutable LowType t,
) {
	return matchLowType!(immutable Bool)(
		t,
		(immutable LowType.ExternPtr it) =>
			// Declared all up front
			True,
		(immutable LowType.FunPtr it) =>
			immutable Bool(at(states.funPtrStates, it.index)),
		(immutable LowType.NonFunPtr it) =>
			canReferenceTypeAsPointee(ctx, states, it.pointee),
		(immutable PrimitiveType) =>
			True,
		(immutable LowType.Record it) =>
			immutable Bool(at(states.recordStates, it.index) == StructState.defined),
		(immutable LowType.Union it) =>
			immutable Bool(at(states.unionStates, it.index) == StructState.defined));
}

immutable(Bool) canReferenceTypeAsPointee(
	ref immutable Ctx ctx,
	ref const StructStates states,
	ref immutable LowType t,
) {
	return matchLowType!(immutable Bool)(
		t,
		(immutable LowType.ExternPtr it) =>
			// Declared all up front
			True,
		(immutable LowType.FunPtr it) =>
			immutable Bool(at(states.funPtrStates, it.index)),
		(immutable LowType.NonFunPtr it) =>
			canReferenceTypeAsPointee(ctx, states, it.pointee),
		(immutable PrimitiveType) =>
			True,
		(immutable LowType.Record it) =>
			immutable Bool(at(states.recordStates, it.index) != StructState.none),
		(immutable LowType.Union it) =>
			immutable Bool(at(states.unionStates, it.index) != StructState.none));
}

void declareStruct(Alloc)(ref Writer!Alloc writer, ref immutable Str mangledName) {
	writeStatic(writer, "struct ");
	writeStr(writer, mangledName);
	writeStatic(writer, ";\n");
}

immutable(Bool) tryWriteFunPtrDeclaration(Alloc)(
	ref Writer!Alloc writer,
	ref immutable Ctx ctx,
	ref const StructStates structStates,
	immutable size_t funPtrIndex,
) {
	immutable LowFunPtrType funPtr = at(ctx.program.allFunPtrTypes, funPtrIndex);
	immutable Bool canDeclare = immutable Bool(
		canReferenceTypeAsPointee(ctx, structStates, funPtr.returnType) &&
		every!LowType(funPtr.paramTypes, (ref immutable LowType it) =>
			canReferenceTypeAsPointee(ctx, structStates, it)));
	if (canDeclare) {
		writeStatic(writer, "typedef ");
		writeType(writer, ctx, funPtr.returnType);
		writeStatic(writer, " (*");
		writeStr(writer, funPtr.mangledName);
		writeStatic(writer, ")(");
		writeWithCommas(writer, funPtr.paramTypes, (ref immutable LowType paramType) {
			writeType(writer, ctx, paramType);
		});
		writeStatic(writer, ");\n");
	}
	return canDeclare;
}

immutable(StructState) writeRecordDeclarationOrDefinition(Alloc)(
	ref Writer!Alloc writer,
	ref immutable Ctx ctx,
	ref const StructStates structStates,
	immutable StructState prevState,
	immutable size_t recordIndex,
) {
	assert(prevState != StructState.defined);
	immutable LowRecord record = at(ctx.program.allRecords, recordIndex);
	if (every(record.fields, (ref immutable LowField f) => canReferenceTypeAsValue(ctx, structStates, f.type))) {
		writeRecord(writer, ctx, record);
		return StructState.defined;
	} else {
		declareStruct(writer, record.mangledName);
		return StructState.declared;
	}
}

immutable(StructState) writeUnionDeclarationOrDefinition(Alloc)(
	ref Writer!Alloc writer,
	ref immutable Ctx ctx,
	ref const StructStates structStates,
	immutable StructState prevState,
	immutable size_t unionIndex,
) {
	assert(prevState != StructState.defined);
	immutable LowUnion union_ = at(ctx.program.allUnions, unionIndex);
	if (every(union_.members, (ref immutable LowType t) => canReferenceTypeAsValue(ctx, structStates, t))) {
		writeUnion(writer, ctx, union_);
		return StructState.defined;
	} else {
		declareStruct(writer, union_.mangledName);
		return StructState.declared;
	}
}

void writeStructs(Alloc)(ref Writer!Alloc writer, ref immutable Ctx ctx) {
	alias TempAlloc = StackAlloc!("struct-states", 1024 * 1024);
	TempAlloc tempAlloc;
	// Write extern-ptr types first
	foreach (ref immutable LowExternPtrType it; range(ctx.program.allExternPtrTypes)) {
		declareStruct(writer, it.mangledName);
	}

	StructStates structStates = StructStates(
		fillArr_mut!(Bool, TempAlloc)(tempAlloc, size(ctx.program.allFunPtrTypes), (immutable size_t) => Bool(false)),
		fillArr_mut!StructState(tempAlloc, size(ctx.program.allRecords), (immutable size_t) => StructState.none),
		fillArr_mut!StructState(tempAlloc, size(ctx.program.allUnions), (immutable size_t) => StructState.none));
	for (;;) {
		Bool madeProgress = False;
		Bool someIncomplete = False;
		foreach (immutable size_t funPtrIndex; 0..size(ctx.program.allFunPtrTypes)) {
			immutable Bool curState = at(structStates.funPtrStates, funPtrIndex);
			if (!curState) {
				if (tryWriteFunPtrDeclaration(writer, ctx, structStates, funPtrIndex)) {
					setAt(structStates.funPtrStates, funPtrIndex, True);
					madeProgress = true;
				} else
					someIncomplete = true;
			}
		}
		foreach (immutable size_t recordIndex; 0..size(ctx.program.allRecords)) {
			immutable StructState curState = at(structStates.recordStates, recordIndex);
			if (curState != StructState.defined) {
				immutable StructState didWork = writeRecordDeclarationOrDefinition(
					writer, ctx, structStates, curState, recordIndex);
				if (didWork > curState) {
					setAt(structStates.recordStates, recordIndex, didWork);
					madeProgress = true;
				} else
					someIncomplete = true;
			}
		}
		foreach (immutable size_t unionIndex; 0..size(ctx.program.allUnions)) {
			immutable StructState curState = at(structStates.unionStates, unionIndex);
			if (curState != StructState.defined) {
				immutable StructState didWork = writeUnionDeclarationOrDefinition(
					writer, ctx, structStates, curState, unionIndex);
				if (didWork > curState) {
					setAt(structStates.unionStates, unionIndex, didWork);
					madeProgress = true;
				} else
					someIncomplete = true;
			}
		}
		if (someIncomplete)
			assert(madeProgress);
		else
			break;
	}
	writeChar(writer, '\n');
}

void writeFunReturnTypeNameAndParams(Alloc)(ref Writer!Alloc writer, ref immutable Ctx ctx, ref immutable LowFun fun) {
	if (isExtern(fun.body_) && isVoid(fun.returnType))
		writeStatic(writer, "void");
	else
		writeType(writer, ctx, fun.returnType);
	writeChar(writer, ' ');
	writeStr(writer, fun.mangledName);
	if (!isGlobal(fun.body_)) {
		writeChar(writer, '(');
		if (!empty(fun.params)) {
			doWriteParam(writer, ctx, first(fun.params));
			foreach (ref immutable LowParam p; range(tail(fun.params))) {
				writeStatic(writer, ", ");
				doWriteParam(writer, ctx, p);
			}
		}
		writeChar(writer, ')');
	}
}

void writeFunDeclaration(Alloc)(ref Writer!Alloc writer, ref immutable Ctx ctx, ref immutable LowFun fun) {
	//TODO:HAX: printf apparently *must* be declared as variadic
	if (strEq(fun.mangledName, strLiteral("printf")))
		writeStatic(writer, "int printf(const char* format, ...);\n");
	else {
		if (isExtern(fun.body_))
			writeStatic(writer, "extern ");
		writeFunReturnTypeNameAndParams(writer, ctx, fun);
		writeStatic(writer, ";\n");
	}
}

void writeFunDefinition(Alloc)(
	ref Writer!Alloc writer,
	ref immutable FunBodyCtx ctx,
	immutable LowFunIndex funIndex,
	ref immutable LowFun fun,
) {
	matchLowFunBody!void(
		fun.body_,
		(ref immutable LowFunBody.Extern it) {
			// declaration is enough
		},
		(ref immutable LowFunExprBody it) {
			writeFunWithExprBody(writer, ctx, funIndex, fun, it);
		});
}

immutable(Bool) hasTailCalls(immutable LowFunIndex curFun, ref immutable LowExpr a) {
	return matchLowExprKind!(immutable Bool)(
		a.kind,
		(ref immutable LowExprKind.Call it) =>
			immutable Bool(it.called == curFun),
		(ref immutable LowExprKind.CreateRecord) =>
			False,
		(ref immutable LowExprKind.ConvertToUnion) =>
			False,
		(ref immutable LowExprKind.FunPtr) =>
			False,
		(ref immutable LowExprKind.Let it) =>
			hasTailCalls(curFun, it.then),
		(ref immutable LowExprKind.LocalRef) =>
			False,
		(ref immutable LowExprKind.Match it) =>
			exists(it.cases, (ref immutable LowExprKind.Match.Case case_) =>
				hasTailCalls(curFun, case_.then)),
		(ref immutable LowExprKind.ParamRef) =>
			False,
		(ref immutable LowExprKind.PtrCast) =>
			False,
		(ref immutable LowExprKind.RecordFieldAccess) =>
			False,
		(ref immutable LowExprKind.RecordFieldSet) =>
			False,
		(ref immutable LowExprKind.Seq it) =>
			hasTailCalls(curFun, it.then),
		(ref immutable LowExprKind.SizeOf) =>
			False,
		(ref immutable LowExprKind.SpecialConstant) =>
			False,
		(ref immutable LowExprKind.Special0Ary) =>
			False,
		(ref immutable LowExprKind.SpecialUnary) =>
			False,
		(ref immutable LowExprKind.SpecialBinary it) {
			switch (it.kind) {
				case LowExprKind.SpecialBinary.Kind.and:
				case LowExprKind.SpecialBinary.Kind.or:
					return hasTailCalls(curFun, it.right);
				default:
					return False;
			}
		},
		(ref immutable LowExprKind.SpecialTrinary it) =>
			immutable Bool(
				it.kind == LowExprKind.SpecialTrinary.Kind.if_ &&
				(hasTailCalls(curFun, it.p1) || hasTailCalls(curFun, it.p2))),
		(ref immutable LowExprKind.SpecialNAry) =>
			False,
		(ref immutable LowExprKind.StringLiteral) =>
			False);
}

void writeFunWithExprBody(Alloc)(
	ref Writer!Alloc writer,
	ref immutable FunBodyCtx ctx,
	immutable LowFunIndex funIndex,
	ref immutable LowFun fun,
	ref immutable LowFunExprBody body_,
) {
	writeFunReturnTypeNameAndParams(writer, ctx.ctx, fun);
	writeStatic(writer, " {\n\t");
	declareLocals(writer, ctx.ctx, body_.allLocals);
	if (hasTailCalls(funIndex, body_.expr)) {
		declareTailCallLocals(writer, ctx.ctx, fun.params);
		writeStatic(writer, "top:\n\t");
	}
	writeExpr(writer, 1, ctx, WriteKind.returnStatement, body_.expr);
	writeStatic(writer, "\n}\n");
}

void declareLocals(Alloc)(ref Writer!Alloc writer, ref immutable Ctx ctx, ref immutable Arr!(Ptr!LowLocal) locals) {
	foreach (immutable Ptr!LowLocal local; range(locals)) {
		writeType(writer, ctx, local.type);
		writeChar(writer, ' ');
		writeLocalRef(writer, local);
		writeStatic(writer, ";\n\t");
	}
}

void declareTailCallLocals(Alloc)(ref Writer!Alloc writer, ref immutable Ctx ctx, ref immutable Arr!LowParam params) {
	foreach (ref immutable LowParam param; range(params)) {
		writeType(writer, ctx, param.type);
		writeStatic(writer, " _tailCall");
		writeStr(writer, param.mangledName);
		writeStatic(writer, ";\n\t");
	}
}

enum WriteKind {
	expr,
	statement,
	returnStatement,
}

void writeExprExpr(Alloc)(
	ref Writer!Alloc writer,
	immutable size_t indent,
	ref immutable FunBodyCtx ctx,
	ref immutable LowExpr expr,
) {
	writeExpr(writer, indent, ctx, WriteKind.expr, expr);
}

void writeExpr(Alloc)(
	ref Writer!Alloc writer,
	immutable size_t indent,
	ref immutable FunBodyCtx ctx,
	immutable WriteKind writeKind,
	ref immutable LowExpr expr,
) {
	void return_(scope void delegate() @safe @nogc pure nothrow cb) {
		writeReturn(writer, writeKind, cb);
	}
	immutable LowType type = expr.type;
	return matchLowExprKind!void(
		expr.kind,
		(ref immutable LowExprKind.Call it) {
			writeCallExpr(writer, indent, ctx, writeKind, it);
		},
		(ref immutable LowExprKind.CreateRecord it) {
			return_(() { writeCreateRecord(writer, indent, ctx, type, it); });
		},
		(ref immutable LowExprKind.ConvertToUnion it) {
			return_(() { writeConvertToUnion(writer, indent, ctx, type, it); });
		},
		(ref immutable LowExprKind.FunPtr it) {
			return_(() { writeFunPtr(writer, ctx.ctx, it); });
		},
		(ref immutable LowExprKind.Let it) {
			if (writeKind == WriteKind.expr)
				writeChar(writer, '(');
			writeAssignLocal(writer, indent, ctx, it.local, it.value);
			if (writeKind == WriteKind.expr)
				writeStatic(writer, ", ");
			else {
				writeChar(writer, ';');
				newline(writer, indent);
			}
			writeExpr(writer, indent, ctx, writeKind, it.then);
			if (writeKind == WriteKind.expr)
				writeChar(writer, ')');
		},
		(ref immutable LowExprKind.LocalRef it) {
			return_(() { writeLocalRef(writer, it.local); });
		},
		(ref immutable LowExprKind.Match it) {
			writeMatch(writer, indent, ctx, writeKind, type, it);
		},
		(ref immutable LowExprKind.ParamRef it) {
			return_(() { writeParamRef(writer, it); });
		},
		(ref immutable LowExprKind.PtrCast it) {
			return_(() { writePtrCast(writer, indent, ctx, type, it); });
		},
		(ref immutable LowExprKind.RecordFieldAccess it) {
			return_(() { writeRecordFieldAccess(writer, indent, ctx, it); });
		},
		(ref immutable LowExprKind.RecordFieldSet it) {
			return_(() { writeRecordFieldSet(writer, indent, ctx, it); });
		},
		(ref immutable LowExprKind.Seq it) {
			if (writeKind == WriteKind.expr) {
				writeChar(writer, '(');
				writeExprExpr(writer, indent, ctx, it.first);
				writeStatic(writer, ", ");
				writeExprExpr(writer, indent, ctx, it.then);
				writeChar(writer, ')');
			} else {
				writeExpr(writer, indent, ctx, WriteKind.statement, it.first);
				newline(writer, indent);
				writeExpr(writer, indent, ctx, writeKind, it.then);
			}
		},
		(ref immutable LowExprKind.SizeOf it) {
			return_(() {
				writeStatic(writer, "sizeof(");
				writeType(writer, ctx.ctx, it.type);
				writeChar(writer, ')');
			});
		},
		(ref immutable LowExprKind.SpecialConstant it) {
			return_(() { writeSpecialConstant(writer, it); });
		},
		(ref immutable LowExprKind.Special0Ary it) {
			return_(() { writeSpecial0Ary(writer, it.kind); });
		},
		(ref immutable LowExprKind.SpecialUnary it) {
			return_(() { writeSpecialUnary(writer, indent, ctx, type, it); });
		},
		(ref immutable LowExprKind.SpecialBinary it) {
			writeSpecialBinary(writer, indent, ctx, writeKind, it);
		},
		(ref immutable LowExprKind.SpecialTrinary it) {
			writeSpecialTrinary(writer, indent, ctx, writeKind, it);
		},
		(ref immutable LowExprKind.SpecialNAry it) {
			return_(() { writeSpecialNAry(writer, indent, ctx, it); });
		},
		(ref immutable LowExprKind.StringLiteral it) {
			return_(() {
				writeCastToType(writer, ctx.ctx, type);
				writeChar(writer, '{');
				writeNat(writer, size(it.literal));
				writeStatic(writer, ", ");
				writeQuotedString(writer, it.literal);
				writeChar(writer, '}');
			});
		});
}

void writeReturn(Alloc)(
	ref Writer!Alloc writer,
	immutable WriteKind writeKind,
	scope void delegate() @safe @nogc pure nothrow cb,
) {
	if (writeKind == WriteKind.returnStatement)
		writeStatic(writer, "return ");
	cb();
	if (writeKind != WriteKind.expr)
		writeChar(writer, ';');
}

void writeFunName(Alloc)(ref Writer!Alloc writer, ref immutable Ctx ctx, immutable LowFunIndex fun) {
	writeStr(writer, at(ctx.program.allFuns, fun.index).mangledName);
}

void writeCallExpr(Alloc)(
	ref Writer!Alloc writer,
	immutable size_t indent,
	ref immutable FunBodyCtx ctx,
	immutable WriteKind writeKind,
	ref immutable LowExprKind.Call a,
) {
	if (writeKind == WriteKind.returnStatement && a.called == ctx.curFun) {
		writeTailCall(writer, indent, ctx, a);
	} else {
		writeReturn(writer, writeKind, () {
			immutable LowFun called = at(ctx.ctx.program.allFuns, a.called.index);
			immutable Bool isCVoid = isExtern(called.body_) && isVoid(called.returnType);
			if (isCVoid)
				//TODO: this is unnecessary if writeKind is not 'expr'
				writeChar(writer, '(');
			writeStr(writer, called.mangledName);
			if (!isGlobal(called.body_)) {
				writeChar(writer, '(');
				writeArgs(writer, indent, ctx, a.args);
				writeChar(writer, ')');
			}
			if (isCVoid)
				writeStatic(writer, ", 0)");
		});
	}
}

void writeTailCall(Alloc)(
	ref Writer!Alloc writer,
	immutable size_t indent,
	ref immutable FunBodyCtx ctx,
	ref immutable LowExprKind.Call a,
) {
	immutable Arr!LowParam params = at(ctx.ctx.program.allFuns, ctx.curFun.index).params;
	// For each arg: Make a 'new' version. Then assign them.
	foreach (immutable size_t argIndex; 0..size(a.args)) {
		immutable LowExpr arg = at(a.args, argIndex);
		writeStatic(writer, "_tailCall");
		writeStr(writer, at(params, argIndex).mangledName);
		writeStatic(writer, " = ");
		writeExprExpr(writer, indent, ctx, arg);
		writeChar(writer, ';');
		newline(writer, indent);
	}
	foreach (immutable size_t argIndex; 0..size(a.args)) {
		writeStr(writer, at(params, argIndex).mangledName);
		writeStatic(writer, " = _tailCall");
		writeStr(writer, at(params, argIndex).mangledName);
		writeChar(writer, ';');
		newline(writer, indent);
	}
	writeStatic(writer, "goto top;");
}

void writeCreateRecord(Alloc)(
	ref Writer!Alloc writer,
	immutable size_t indent,
	ref immutable FunBodyCtx ctx,
	ref immutable LowType type,
	ref immutable LowExprKind.CreateRecord a,
) {
	writeCastToType(writer, ctx.ctx, type);
	writeChar(writer, '{');
	if (empty(a.args))
		// C forces structs to be non-empty
		writeChar(writer, '0');
	else
		writeArgs(writer, indent, ctx, a.args);
	writeChar(writer, '}');
}

void writeConvertToUnion(Alloc)(
	ref Writer!Alloc writer,
	immutable size_t indent,
	ref immutable FunBodyCtx ctx,
	ref immutable LowType type,
	ref immutable LowExprKind.ConvertToUnion a,
) {
	writeCastToType(writer, ctx.ctx, type);
	writeChar(writer, '{');
	writeNat(writer, a.memberIndex);
	writeStatic(writer, ", .as");
	writeNat(writer, a.memberIndex);
	writeStatic(writer, " = ");
	writeExprExpr(writer, indent, ctx, a.arg);
	writeChar(writer, '}');
}

void writeFunPtr(Alloc)(ref Writer!Alloc writer, ref immutable Ctx ctx, ref immutable LowExprKind.FunPtr a) {
	writeStr(writer, at(ctx.program.allFuns, a.fun.index).mangledName);
}

void writeLocalRef(Alloc)(ref Writer!Alloc writer, immutable Ptr!LowLocal a) {
	writeStr(writer, a.mangledName);
}

void writeMatch(Alloc)(
	ref Writer!Alloc writer,
	immutable size_t indent,
	ref immutable FunBodyCtx ctx,
	immutable WriteKind writeKind,
	ref immutable LowType type,
	ref immutable LowExprKind.Match a,
) {
	void assignCaseLocal(immutable Ptr!LowLocal local, immutable size_t caseIndex) {
		writeLocalRef(writer, local);
		writeStatic(writer, " = ");
		writeLocalRef(writer, a.matchedLocal);
		writeStatic(writer, ".as");
		writeNat(writer, caseIndex);
	}

	if (writeKind == WriteKind.expr) {
		writeChar(writer, '(');
		writeAssignLocal(writer, indent, ctx, a.matchedLocal, a.matchedValue);
		writeStatic(writer, ", ");
		// Use nested conditionals
		foreach (immutable size_t caseIndex; 0..size(a.cases)) {
			immutable LowExprKind.Match.Case case_ = at(a.cases, caseIndex);
			writeLocalRef(writer, a.matchedLocal);
			writeStatic(writer, ".kind == ");
			writeNat(writer, caseIndex);
			writeStatic(writer, " ? ");
			if (has(case_.local)) {
				writeChar(writer, '(');
				assignCaseLocal(force(case_.local), caseIndex);
				writeStatic(writer, ", ");
			}
			writeExprExpr(writer, indent, ctx, case_.then);
			if (has(case_.local))
				writeChar(writer, ')');
			writeStatic(writer, " : ");
		}
		writeHardFail(writer, ctx.ctx, type);
		writeChar(writer, ')');
	} else {
		writeAssignLocal(writer, indent, ctx, a.matchedLocal, a.matchedValue);
		writeChar(writer, ';');
		newline(writer, indent);
		writeStatic(writer, "switch (");
		writeLocalRef(writer, a.matchedLocal);
		writeStatic(writer, ".kind) {");
		foreach (immutable size_t caseIndex; 0..size(a.cases)) {
			immutable LowExprKind.Match.Case case_ = at(a.cases, caseIndex);
			newline(writer, indent + 1);
			writeStatic(writer, "case ");
			writeNat(writer, caseIndex);
			writeChar(writer, ':');
			newline(writer, indent + 2);
			if (has(case_.local)) {
				assignCaseLocal(force(case_.local), caseIndex);
				writeChar(writer, ';');
				newline(writer, indent + 2);
			}
			writeExpr(writer, indent + 2, ctx, writeKind, case_.then);
			if (writeKind == WriteKind.statement) {
				newline(writer, indent + 2);
				writeStatic(writer, "break;");
			}
		}
		newline(writer, indent + 1);
		writeStatic(writer, "default:");
		newline(writer, indent + 2);
		if (writeKind == WriteKind.returnStatement)
			writeStatic(writer, "return ");
		writeHardFail(writer, ctx.ctx, type);
		writeChar(writer, ';');
		newline(writer, indent);
		writeChar(writer, '}');
	}
}

void writeAssignLocal(Alloc)(
	ref Writer!Alloc writer,
	immutable size_t indent,
	ref immutable FunBodyCtx ctx,
	immutable Ptr!LowLocal local,
	ref immutable LowExpr value,
) {
	writeLocalRef(writer, local);
	writeStatic(writer, " = ");
	writeExprExpr(writer, indent, ctx, value);
}

void writeParamRef(Alloc)(ref Writer!Alloc writer, ref immutable LowExprKind.ParamRef a) {
	writeStr(writer, a.param.mangledName);
}

void writePtrCast(Alloc)(
	ref Writer!Alloc writer,
	immutable size_t indent,
	ref immutable FunBodyCtx ctx,
	ref immutable LowType type,
	ref immutable LowExprKind.PtrCast a,
) {
	writeCastToType(writer, ctx.ctx, type);
	writeExprExpr(writer, indent, ctx, a.target);
}

void writeRecordFieldAccess(Alloc)(
	ref Writer!Alloc writer,
	immutable size_t indent,
	ref immutable FunBodyCtx ctx,
	ref immutable LowExprKind.RecordFieldAccess a,
) {
	writeRecordFieldAccess(writer, indent, ctx, a.target, a.targetIsPointer, a.field);
}

void writeRecordFieldAccess(Alloc)(
	ref Writer!Alloc writer,
	immutable size_t indent,
	ref immutable FunBodyCtx ctx,
	ref immutable LowExpr target,
	immutable Bool targetIsPointer,
	ref immutable LowField field,
) {
	writeExprExpr(writer, indent, ctx, target);
	writeStatic(writer, targetIsPointer ? "->" : ".");
	writeStr(writer, field.mangledName);
}

void writeRecordFieldSet(Alloc)(
	ref Writer!Alloc writer,
	immutable size_t indent,
	ref immutable FunBodyCtx ctx,
	ref immutable LowExprKind.RecordFieldSet a,
) {
	writeChar(writer, '(');
	writeRecordFieldAccess(writer, indent, ctx, a.target, a.targetIsPointer, a.field);
	writeStatic(writer, " = ");
	writeExprExpr(writer, indent, ctx, a.value);
	writeStatic(writer, ", 0)");
}

void writeArgs(Alloc)(
	ref Writer!Alloc writer,
	immutable size_t indent,
	ref immutable FunBodyCtx ctx,
	immutable Arr!LowExpr args,
) {
	writeWithCommas(writer, args, (ref immutable LowExpr it) {
		writeExprExpr(writer, indent, ctx, it);
	});
}

void writeSpecialConstant(Alloc)(
	ref Writer!Alloc writer,
	immutable LowExprKind.SpecialConstant a,
) {
	matchSpecialConstant(
		a,
		(immutable LowExprKind.SpecialConstant.BoolConstant it) {
			writeChar(writer, it.value ? '1' : '0');
		},
		(immutable LowExprKind.SpecialConstant.Integral it) {
			writeNat(writer, it.value);
		},
		(immutable LowExprKind.SpecialConstant.Null) {
			writeStatic(writer, "NULL");
		},
		(immutable LowExprKind.SpecialConstant.Void) {
			writeChar(writer, '0');
		});
}

void writeSpecial0Ary(Alloc)(
	ref Writer!Alloc writer,
	immutable LowExprKind.Special0Ary.Kind it,
) {
	final switch (it) {
		case LowExprKind.Special0Ary.Kind.getErrno:
			writeStatic(writer, "errno");
			break;
	}
}

void writeSpecialUnary(Alloc)(
	ref Writer!Alloc writer,
	immutable size_t indent,
	ref immutable FunBodyCtx ctx,
	ref immutable LowType type,
	immutable LowExprKind.SpecialUnary it,
) {
	void arg() {
		writeExprExpr(writer, indent, ctx, it.arg);
	}
	void prefix(string prefix) {
		writeStatic(writer, prefix);
		arg();
	}
	void prefixParenthesized(string prefix) {
		writeChar(writer, '(');
		writeStatic(writer, prefix);
		writeChar(writer, '(');
		arg();
		writeStatic(writer, "))");
	}
	final switch (it.kind) {
		case LowExprKind.SpecialUnary.Kind.asAnyPtr:
			prefix("(uint8_t*) ");
			break;
		case LowExprKind.SpecialUnary.Kind.asRef:
		case LowExprKind.SpecialUnary.Kind.toNatFromPtr:
			writeCastToType(writer, ctx.ctx, type);
			arg();
			break;
		case LowExprKind.SpecialUnary.Kind.deref:
			prefixParenthesized("*");
			break;
		case LowExprKind.SpecialUnary.Kind.hardFail:
			writeHardFail(writer, ctx.ctx, type);
			break;
		case LowExprKind.SpecialUnary.Kind.not:
			prefix("!");
			break;
		case LowExprKind.SpecialUnary.Kind.ptrTo:
		case LowExprKind.SpecialUnary.Kind.refOfVal:
			prefixParenthesized("&");
			break;
		case LowExprKind.SpecialUnary.Kind.toFloat64FromInt64:
		case LowExprKind.SpecialUnary.Kind.toFloat64FromNat64:
		case LowExprKind.SpecialUnary.Kind.toIntFromInt16:
		case LowExprKind.SpecialUnary.Kind.toIntFromInt32:
		case LowExprKind.SpecialUnary.Kind.toNatFromNat16:
		case LowExprKind.SpecialUnary.Kind.toNatFromNat32:
		case LowExprKind.SpecialUnary.Kind.truncateToInt64FromFloat64:
		case LowExprKind.SpecialUnary.Kind.unsafeInt64ToInt8:
		case LowExprKind.SpecialUnary.Kind.unsafeInt64ToInt16:
		case LowExprKind.SpecialUnary.Kind.unsafeInt64ToInt32:
		case LowExprKind.SpecialUnary.Kind.unsafeInt64ToNat64:
		case LowExprKind.SpecialUnary.Kind.unsafeNat64ToInt64:
		case LowExprKind.SpecialUnary.Kind.unsafeNat64ToNat8:
		case LowExprKind.SpecialUnary.Kind.unsafeNat64ToNat16:
		case LowExprKind.SpecialUnary.Kind.unsafeNat64ToNat32:
			// C will implicitly cast
			arg();
			break;
	}
}

void writeHardFail(Alloc)(ref Writer!Alloc writer, ref immutable Ctx ctx, ref immutable LowType type) {
	//TODO: this doesn't use the message we gave it..
	//TODO: this won't work for non-integral types
	writeStatic(writer, "(assert(0),");
	writeEmptyValue(writer, ctx, type);
	writeChar(writer, ')');
}

void writeEmptyValue(Alloc)(ref Writer!Alloc writer, ref immutable Ctx ctx, ref immutable LowType type) {
	return matchLowType!void(
		type,
		(immutable LowType.ExternPtr) {
			writeStatic(writer, "NULL");
		},
		(immutable LowType.FunPtr) {
			writeStatic(writer, "NULL");
		},
		(immutable LowType.NonFunPtr) {
			writeStatic(writer, "NULL");
		},
		(immutable PrimitiveType) {
			writeChar(writer, '0');
		},
		(immutable LowType.Record it) {
			writeCastToType(writer, ctx, type);
			writeChar(writer, '{');
			immutable Arr!LowField fields =  at(ctx.program.allRecords, it.index).fields;
			if (empty(fields)) {
				writeChar(writer, '0');
			} else {
				writeWithCommas(writer, fields, (ref immutable LowField field) {
					writeEmptyValue(writer, ctx, field.type);
				});
			}
			writeChar(writer, '}');
		},
		(immutable LowType.Union) {
			writeCastToType(writer, ctx, type);
			writeStatic(writer, "{0}");
		});
}

void writeBinaryOperator(Alloc)(
	ref Writer!Alloc writer,
	immutable size_t indent,
	ref immutable FunBodyCtx ctx,
	ref immutable LowExpr left,
	immutable string op,
	ref immutable LowExpr right,
) {
	writeChar(writer, '(');
	writeExprExpr(writer, indent, ctx, left);
	writeChar(writer, ' ');
	writeStatic(writer, op);
	writeChar(writer, ' ');
	writeExprExpr(writer, indent, ctx, right);
	writeChar(writer, ')');
}

void writeSpecialBinary(Alloc)(
	ref Writer!Alloc writer,
	immutable size_t indent,
	ref immutable FunBodyCtx ctx,
	immutable WriteKind writeKind,
	ref immutable LowExprKind.SpecialBinary it,
) {
	void arg0() {
		writeExprExpr(writer, indent, ctx, it.left);
	}
	void arg1() {
		writeExprExpr(writer, indent, ctx, it.right);
	}

	void operator(string op) {
		writeReturn(writer, writeKind, () {
			writeBinaryOperator(writer, indent, ctx, it.left, op, it.right);
		});
	}

	final switch (it.kind) {
		case LowExprKind.SpecialBinary.Kind.addFloat64:
		case LowExprKind.SpecialBinary.Kind.addPtr:
		case LowExprKind.SpecialBinary.Kind.wrapAddInt16:
		case LowExprKind.SpecialBinary.Kind.wrapAddInt32:
		case LowExprKind.SpecialBinary.Kind.wrapAddInt64:
		case LowExprKind.SpecialBinary.Kind.wrapAddNat16:
		case LowExprKind.SpecialBinary.Kind.wrapAddNat32:
		case LowExprKind.SpecialBinary.Kind.wrapAddNat64:
			operator("+");
			break;
		case LowExprKind.SpecialBinary.Kind.and:
			writeLogicalOperator(writer, indent, ctx, writeKind, LogicalOperator.and, it.left, it.right);
			break;
		case LowExprKind.SpecialBinary.Kind.bitShiftLeftInt32:
		case LowExprKind.SpecialBinary.Kind.bitShiftLeftNat32:
			operator("<<");
			break;
		case LowExprKind.SpecialBinary.Kind.bitShiftRightInt32:
		case LowExprKind.SpecialBinary.Kind.bitShiftRightNat32:
			operator(">>");
			break;
		case LowExprKind.SpecialBinary.Kind.bitwiseAndInt8:
		case LowExprKind.SpecialBinary.Kind.bitwiseAndInt16:
		case LowExprKind.SpecialBinary.Kind.bitwiseAndInt32:
		case LowExprKind.SpecialBinary.Kind.bitwiseAndInt64:
		case LowExprKind.SpecialBinary.Kind.bitwiseAndNat8:
		case LowExprKind.SpecialBinary.Kind.bitwiseAndNat16:
		case LowExprKind.SpecialBinary.Kind.bitwiseAndNat32:
		case LowExprKind.SpecialBinary.Kind.bitwiseAndNat64:
			operator("&");
			break;
		case LowExprKind.SpecialBinary.Kind.bitwiseOrInt8:
		case LowExprKind.SpecialBinary.Kind.bitwiseOrInt16:
		case LowExprKind.SpecialBinary.Kind.bitwiseOrInt32:
		case LowExprKind.SpecialBinary.Kind.bitwiseOrInt64:
		case LowExprKind.SpecialBinary.Kind.bitwiseOrNat8:
		case LowExprKind.SpecialBinary.Kind.bitwiseOrNat16:
		case LowExprKind.SpecialBinary.Kind.bitwiseOrNat32:
		case LowExprKind.SpecialBinary.Kind.bitwiseOrNat64:
			operator("|");
			break;
		case LowExprKind.SpecialBinary.Kind.eqNat64:
			operator("==");
			break;
		case LowExprKind.SpecialBinary.Kind.less:
			operator("<");
			break;
		case LowExprKind.SpecialBinary.Kind.mulFloat64:
		case LowExprKind.SpecialBinary.Kind.wrapMulInt16:
		case LowExprKind.SpecialBinary.Kind.wrapMulInt32:
		case LowExprKind.SpecialBinary.Kind.wrapMulInt64:
		case LowExprKind.SpecialBinary.Kind.wrapMulNat16:
		case LowExprKind.SpecialBinary.Kind.wrapMulNat32:
		case LowExprKind.SpecialBinary.Kind.wrapMulNat64:
			operator("*");
			break;
		case LowExprKind.SpecialBinary.Kind.or:
			writeLogicalOperator(writer, indent, ctx, writeKind, LogicalOperator.or, it.left, it.right);
			break;
		case LowExprKind.SpecialBinary.Kind.subFloat64:
		case LowExprKind.SpecialBinary.Kind.subPtrNat:
		case LowExprKind.SpecialBinary.Kind.wrapSubInt16:
		case LowExprKind.SpecialBinary.Kind.wrapSubInt32:
		case LowExprKind.SpecialBinary.Kind.wrapSubInt64:
		case LowExprKind.SpecialBinary.Kind.wrapSubNat16:
		case LowExprKind.SpecialBinary.Kind.wrapSubNat32:
		case LowExprKind.SpecialBinary.Kind.wrapSubNat64:
			operator("-");
			break;
		case LowExprKind.SpecialBinary.Kind.unsafeDivFloat64:
		case LowExprKind.SpecialBinary.Kind.unsafeDivInt64:
		case LowExprKind.SpecialBinary.Kind.unsafeDivNat64:
			operator("/");
			break;
		case LowExprKind.SpecialBinary.Kind.unsafeModNat64:
			operator("%");
			break;
		case LowExprKind.SpecialBinary.Kind.writeToPtr:
			// TODO: be neater about this. If not returning don't need the comma expression.
			writeReturn(writer, writeKind, () {
				writeStatic(writer, "(*(");
				arg0();
				writeStatic(writer, ") = ");
				arg1();
				writeStatic(writer, ", 0)");
			});
			break;
	}
}

enum LogicalOperator { and, or }

void writeLogicalOperator(Alloc)(
	ref Writer!Alloc writer,
	immutable size_t indent,
	ref immutable FunBodyCtx ctx,
	immutable WriteKind writeKind,
	immutable LogicalOperator operator,
	ref immutable LowExpr left,
	ref immutable LowExpr right,
) {
	if (writeKind == WriteKind.returnStatement && hasTailCalls(ctx.curFun, right)) {
		/*
		Ensure a tail call of RHS.
		`a && b` ==> `if (a) { return b; } else { return 0; }`
		`a || b` ==> `if (a) { return 1; } else { return b; }`
		*/
		writeStatic(writer, "if (");
		writeExprExpr(writer, indent, ctx, left);
		writeStatic(writer, ") {");
		newline(writer, indent + 1);
		final switch (operator) {
			case LogicalOperator.and:
				writeExpr(writer, indent + 1, ctx, WriteKind.returnStatement, right);
				break;
			case LogicalOperator.or:
				writeStatic(writer, "return 1;");
				break;
		}
		newline(writer, indent);
		writeStatic(writer, "} else {");
		newline(writer, indent + 1);
		final switch (operator) {
			case LogicalOperator.and:
				writeStatic(writer, "return 0;");
				break;
			case LogicalOperator.or:
				writeExpr(writer, indent + 1, ctx, WriteKind.returnStatement, right);
				break;
		}
		newline(writer, indent);
		writeChar(writer, '}');
	} else
		writeReturn(writer, writeKind, () {
			immutable string op = () {
				final switch (operator) {
					case LogicalOperator.and:
						return "&&";
					case LogicalOperator.or:
						return "||";
				}
			}();
			writeBinaryOperator(writer, indent, ctx, left, op, right);
		});
}

void writeSpecialTrinary(Alloc)(
	ref Writer!Alloc writer,
	immutable size_t indent,
	ref immutable FunBodyCtx ctx,
	immutable WriteKind writeKind,
	ref immutable LowExprKind.SpecialTrinary a,
) {
	void arg0() {
		writeExprExpr(writer, indent, ctx, a.p0);
	}
	void arg1() {
		writeExprExpr(writer, indent, ctx, a.p1);
	}
	void arg2() {
		writeExprExpr(writer, indent, ctx, a.p2);
	}

	final switch (a.kind) {
		case LowExprKind.SpecialTrinary.Kind.if_:
			if (writeKind == WriteKind.expr) {
				writeChar(writer, '(');
				arg0();
				writeStatic(writer, " ? ");
				arg1();
				writeStatic(writer, " : ");
				arg2();
				writeChar(writer, ')');
			} else {
				writeStatic(writer, "if (");
				arg0();
				writeStatic(writer, ") {");
				newline(writer, indent + 1);
				writeExpr(writer, indent + 1, ctx, writeKind, a.p1);
				newline(writer, indent);
				writeStatic(writer, "} else {");
				newline(writer, indent + 1);
				writeExpr(writer, indent + 1, ctx, writeKind, a.p2);
				newline(writer, indent);
				writeChar(writer, '}');
			}
			break;
		case LowExprKind.SpecialTrinary.Kind.compareExchangeStrong:
			writeReturn(writer, writeKind, () {
				writeStatic(writer, "atomic_compare_exchange_strong(");
				arg0();
				writeStatic(writer, ", ");
				arg1();
				writeStatic(writer, ", ");
				arg2();
				writeChar(writer, ')');
			});
			break;
	}
}

void writeSpecialNAry(Alloc)(
	ref Writer!Alloc writer,
	immutable size_t indent,
	ref immutable FunBodyCtx ctx,
	ref immutable LowExprKind.SpecialNAry it,
) {
	final switch (it.kind) {
		case LowExprKind.SpecialNAry.Kind.callFunPtr:
			writeExprExpr(writer, indent, ctx, first(it.args));
			writeChar(writer, '(');
			writeArgs(writer, indent, ctx, tail(it.args));
			writeChar(writer, ')');
			break;
	}
}

void writeQuotedString(Alloc)(ref Writer!Alloc writer, ref immutable Str str) {
	writeChar(writer, '"');
	foreach (immutable char c; range(str))
		writeEscapedChar(writer, c);
	writeChar(writer, '"');
}

void writePrimitiveType(Alloc)(ref Writer!Alloc writer, immutable PrimitiveType a) {
	writeStatic(writer, () {
		final switch (a) {
			case PrimitiveType.bool_:
				return "uint8_t";
			case PrimitiveType.char_:
				return "char";
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
				return "uint8_t";
		}
	}());
}
