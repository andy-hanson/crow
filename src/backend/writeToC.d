module backend.writeToC;

@safe @nogc pure nothrow:

import concreteModel :
	asBuiltin,
	asRecord,
	asUnion,
	body_,
	BuiltinFunEmit,
	BuiltinFunInfo,
	BuiltinFunKind,
	BuiltinStructKind,
	ConcreteExpr,
	ConcreteField,
	ConcreteFun,
	ConcreteFunBody,
	ConcreteFunExprBody,
	ConcreteLocal,
	ConcreteParam,
	ConcreteProgram,
	ConcreteStruct,
	ConcreteStructBody,
	ConcreteType,
	isBuiltin,
	isExtern,
	isGlobal,
	mangledName,
	matchConcreteExpr,
	matchConcreteFunBody,
	matchConcreteStructBody,
	matchedUnionMembers,
	mustBePointer,
	paramsExcludingCtxAndClosure,
	returnType,
	sizeBytes;
import util.alloc.stackAlloc : StackAlloc;
import util.bools : Bool, False, True;
import util.collection.arr : Arr, at, empty, first, only, ptrAt, range, size;
import util.collection.arrUtil : every, tail, zipWithIndex;
import util.collection.mutDict : getAt_mut, hasKey_mut, MutDict, setInDict;
import util.collection.str : Str, strEq, strEqLiteral, strLiteral;
import util.opt : force, has, Opt, none, some;
import util.ptr : comparePtr, Ptr, ptrTrustMe_mut;
import util.util : todo;
import util.verify : unreachable;
import util.writer :
	finishWriter,
	decrIndent,
	dedent,
	indent,
	newline,
	writeChar,
	writeEscapedChar,
	writeNat,
	Writer,
	WriterWithIndent,
	writeStatic,
	writeStr,
	writeWithCommas;

immutable(Str) writeToC(Alloc)(
	ref Alloc alloc,
	ref immutable ConcreteProgram program,
) {
	Writer!Alloc writer = Writer!Alloc(ptrTrustMe_mut(alloc));

	writeStatic(writer, "#include <assert.h>\n");
	writeStatic(writer, "#include <errno.h>\n");
	writeStatic(writer, "#include <stdatomic.h>\n");
	writeStatic(writer, "#include <stddef.h>\n"); // for NULL
	writeStatic(writer, "#include <stdint.h>\n");

	writeStructs(writer, program.allStructs);
	writeInitAndFailFuns(writer, program.allStructs);

	foreach (immutable Ptr!ConcreteFun fun; range(program.allFuns))
		writeConcreteFunDeclaration(writer, fun);

	foreach (immutable Ptr!ConcreteFun fun; range(program.allFuns))
		writeConcreteFunDefinition(writer, fun);

	writeMain(writer, program.rtMain, program.userMain, program.allStructs);

	return finishWriter(writer);
}

private:

void writeValueType(Alloc)(ref Writer!Alloc writer, ref immutable ConcreteStruct s) {
	writeStr(writer, s.mangledName);
}

void writeValueType(Alloc)(ref Writer!Alloc writer, ref immutable ConcreteType t) {
	writeValueType(writer, mustBeNonPointer(t));
}

void writeType(Alloc)(ref Writer!Alloc writer, ref immutable ConcreteType t) {
	writeValueType(writer, t.struct_);
	if (t.isPointer)
		writeChar(writer, '*');
}

void writeCastToType(Alloc)(ref Writer!Alloc writer, ref immutable ConcreteType type) {
	writeChar(writer, '(');
	writeType(writer, type);
	writeStatic(writer, ") ");
}

void writeCastToValueType(Alloc)(ref Writer!Alloc writer, ref immutable ConcreteStruct struct_) {
	writeChar(writer, '(');
	writeValueType(writer, struct_);
	writeStatic(writer, ") ");
}

void doWriteParam(Alloc)(ref Writer!Alloc writer, ref immutable ConcreteParam p) {
	writeType(writer, p.type);
	writeChar(writer, ' ');
	writeStr(writer, p.mangledName);
}

void writeJustParams(Alloc)(ref Writer!Alloc writer, immutable Bool wroteFirst, immutable Arr!ConcreteParam params) {
	if (!empty(params)) {
		if (wroteFirst)
			writeStatic(writer, ", ");
		doWriteParam(writer, first(params));
		foreach (ref immutable ConcreteParam p; range(tail(params))) {
			writeStatic(writer, ", ");
			doWriteParam(writer, p);
		}
	}
	writeChar(writer, ')');
}

void writeBuiltinAliasForStruct(Alloc)(
	ref Writer!Alloc writer,
	ref immutable Str name,
	immutable BuiltinStructKind kind,
	immutable Arr!ConcreteType typeArgs,
) {
	switch (kind) {
		case BuiltinStructKind.char_:
			// "char" shares the same name as in C, so no need for an alias.
			break;

		case BuiltinStructKind.funPtrN:
			writeStatic(writer, "typedef ");
			writeType(writer, first(typeArgs));
			writeStatic(writer, " (*");
			writeStr(writer, name);
			writeStatic(writer, ")(");
			foreach (immutable size_t i; 1..size(typeArgs)) {
				if (i != 1)
					writeStatic(writer, ", ");
				writeType(writer, at(typeArgs, i));
			}
			writeStatic(writer, ");\n");
			break;

		case BuiltinStructKind.ptr:
			writeStatic(writer, "typedef ");
			writeType(writer, only(typeArgs));
			writeStatic(writer, "* ");
			writeStr(writer, name);
			writeStatic(writer, ";\n");
			break;

		default:
			writeStatic(writer, "typedef ");
			writeStatic(writer, () {
				final switch (kind) {
					case BuiltinStructKind.bool_:
						return "uint8_t";
					case BuiltinStructKind.byte_:
						return "uint8_t";
					case BuiltinStructKind.float64:
						return "double";
					case BuiltinStructKind.int16:
						return "int16_t";
					case BuiltinStructKind.int32:
						return "int32_t";
					case BuiltinStructKind.int64:
						return "int64_t";
					case BuiltinStructKind.nat16:
						return "uint16_t";
					case BuiltinStructKind.nat32:
						return "uint32_t";
					case BuiltinStructKind.nat64:
						return "uint64_t";
					case BuiltinStructKind.void_:
						return "uint8_t";
					case BuiltinStructKind.char_:
					case BuiltinStructKind.funPtrN:
					case BuiltinStructKind.ptr:
						return unreachable!string;
				}
			}());
			writeChar(writer, ' ');
			writeStr(writer, name);
			writeStatic(writer, ";\n");
	}
}

void writeStructHead(Alloc)(ref Writer!Alloc writer, immutable Str mangledName) {
	writeStatic(writer, "struct ");
	writeStr(writer, mangledName);
	writeStatic(writer, " {");
}

void writeStructEnd(Alloc)(ref Writer!Alloc writer) {
	writeStatic(writer, "\n};\n");
}

void writeFieldsStruct(Alloc)(
	ref Writer!Alloc writer,
	ref immutable Str mangledName,
	ref immutable Arr!ConcreteField fields,
) {
	writeStructHead(writer, mangledName);
	if (empty(fields))
		// An empty structure is undefined behavior in C.
		writeStatic(writer, "\n\tbool __mustBeNonEmpty;\n};\n");
	else {
		foreach (ref immutable ConcreteField field; range(fields)) {
			writeStatic(writer, "\n\t");
			writeType(writer, field.type);
			writeChar(writer, ' ');
			writeStr(writer, field.mangledName);
			writeChar(writer, ';');
		}
		writeStructEnd(writer);
	}
}

void writeUnionStruct(Alloc)(
	ref Writer!Alloc writer,
	ref immutable Str mangledName,
	ref immutable Arr!ConcreteType members,
) {
	writeStructHead(writer, mangledName);
	writeStatic(writer, "\n\tint kind;");
	writeStatic(writer, "\n\tunion {");
	foreach (ref immutable ConcreteType member; range(members)) {
		writeStatic(writer, "\n\t\t");
		writeType(writer, member);
		writeStatic(writer, " as_");
		writeStr(writer, member.struct_.mangledName);
		writeChar(writer, ';');
	}
	writeStatic(writer, "\n\t};");
	writeStructEnd(writer);
}

enum StructState {
	declared,
	defined,
}

alias StructStates = MutDict!(immutable Ptr!ConcreteStruct, immutable StructState, comparePtr!ConcreteStruct);

immutable(Bool) canReferenceType(ref immutable ConcreteType t, ref const StructStates structStates) {
	immutable Opt!(immutable StructState) state = getAt_mut(structStates, t.struct_);
	if (has(state))
		final switch (force(state)) {
			case StructState.declared:
				return t.isPointer;
			case StructState.defined:
				return True;
		}
	else
		return False;
}

void declareStruct(Alloc)(ref Writer!Alloc writer, ref immutable ConcreteStruct struct_) {
	writeStatic(writer, "typedef struct ");
	writeStr(writer, struct_.mangledName);
	writeChar(writer, ' ');
	writeStr(writer, struct_.mangledName);
	writeStatic(writer, ";\n");
}

// Returns any new work it did -- if we declared or defined the struct
immutable(Opt!StructState) writeStructDeclarationOrDefinition(Alloc)(
	ref Writer!Alloc writer,
	immutable Ptr!ConcreteStruct struct_,
	ref const StructStates structStates,
) {
	immutable(Opt!StructState) declare() {
		if (!hasKey_mut(structStates, struct_)) {
			declareStruct(writer, struct_);
			return some(StructState.declared);
		} else
			return none!StructState;
	}
	immutable Opt!StructState defined = some(StructState.defined);

	return matchConcreteStructBody(
		body_(struct_),
		(ref immutable ConcreteStructBody.Builtin b) {
			if (every(b.typeArgs, (ref immutable ConcreteType t) => canReferenceType(t, structStates))) {
				writeBuiltinAliasForStruct(writer, struct_.mangledName, b.info.kind, b.typeArgs);
				return defined;
			} else
				return none!StructState;
		},
		(ref immutable ConcreteStructBody.Record r) {
			if (every(r.fields, (ref immutable ConcreteField f) => canReferenceType(f.type, structStates))) {
				declare();
				writeFieldsStruct(writer, struct_.mangledName, r.fields);
				return defined;
			} else
				return declare();
		},
		(ref immutable ConcreteStructBody.Union u) {
			if (every(u.members, (ref immutable ConcreteType t) => canReferenceType(t, structStates))) {
				declare();
				writeUnionStruct(writer, struct_.mangledName, u.members);
				return defined;
			} else
				return declare();
		});
}

void writeStructs(Alloc)(ref Writer!Alloc writer, ref immutable Arr!(Ptr!ConcreteStruct) allStructs) {
	StackAlloc!("struct-states", 1024 * 1024) tempAlloc;
	StructStates structStates;
	for (;;) {
		Bool madeProgress = False;
		Bool someIncomplete = False;
		foreach (immutable Ptr!ConcreteStruct struct_; range(allStructs)) {
			immutable Opt!(immutable StructState) curState = getAt_mut(structStates, struct_);
			if (!has(curState) || force(curState) != StructState.defined) {
				immutable Opt!StructState didWork = writeStructDeclarationOrDefinition(writer, struct_, structStates);
				if (has(didWork)) {
					setInDict(tempAlloc, structStates, struct_, force(didWork));
					madeProgress = True;
				} else
					someIncomplete = True;
			}
		}
		if (someIncomplete)
			assert(madeProgress);
		else
			break;
	}
	writeChar(writer, '\n');
}

void writeLocalRef(Alloc)(ref Writer!Alloc writer, ref immutable ConcreteLocal local) {
	writeStr(writer, local.mangledName);
}

void writeLocalDeclaration(Alloc)(ref Writer!Alloc writer, ref immutable ConcreteLocal local) {
	writeType(writer, local.type);
	writeChar(writer, ' ');
	writeLocalRef(writer, local);
	writeStatic(writer, ";\n\t");
}

void writeLocalAssignment(Alloc)(ref Writer!Alloc writer, ref immutable ConcreteLocal local) {
	writeLocalRef(writer, local);
	writeStatic(writer, " = ");
}

void writeFailForType(Alloc)(ref Writer!Alloc writer, ref immutable ConcreteType type) {
	writeStatic(writer, "_fail");
	if (type.isPointer)
		writeStatic(writer, "VoidPtr");
	else
		writeStr(writer, type.struct_.mangledName);
	writeStatic(writer, "()");
}

void writeMatch(Alloc)(
	ref WriterWithIndent!Alloc writer,
	ref immutable ConcreteExpr ce,
	ref immutable ConcreteExpr.Match e,
) {
	// matched1 = bar(foo),
	// (matched1.kind == 0 ? 42 : (s = matched1.as_some, s.value))
	immutable Ptr!ConcreteLocal matchedLocal = e.matchedLocal;
	writeChar(writer, '(');
	writeLocalAssignment(writer.writer, matchedLocal);
	writeExpr(writer, e.matchedValue);
	writeChar(writer, ',');
	indent(writer);
	zipWithIndex!(ConcreteType, ConcreteExpr.Match.Case)(
		matchedUnionMembers(e),
		e.cases,
		(ref immutable ConcreteType member, ref immutable ConcreteExpr.Match.Case case_, immutable size_t i) {
			immutable Str memberName = member.struct_.mangledName;
			writeLocalRef(writer.writer, matchedLocal);
			writeStatic(writer, ".kind == ");
			writeNat(writer.writer, i);
			newline(writer);
			writeStatic(writer, "? ");
			if (has(case_.local)) {
				writeChar(writer, '(');
				writeLocalAssignment(writer.writer, force(case_.local));
				writeLocalRef(writer.writer, matchedLocal);
				writeStatic(writer, ".as_");
				writeStr(writer, memberName);
				writeChar(writer, ',');
				newline(writer);
			}
			writeExpr(writer, case_.then);
			newline(writer);
			if (has(case_.local))
				writeChar(writer, ')');
			writeStatic(writer, ": ");
		});
	writeFailForType(writer.writer, ce.type);
	decrIndent(writer);
	writeChar(writer, ')');
}

void writeFieldAccess(Alloc)(
	ref WriterWithIndent!Alloc writer,
	immutable Bool targetIsPointer,
	ref immutable ConcreteExpr target,
	ref immutable ConcreteField field,
) {
	writeExpr(writer, target);
	writeStatic(writer, targetIsPointer ? "->" : ".");
	writeStr(writer, field.mangledName);
}

void writeCallOperator(Alloc)(
	ref WriterWithIndent!Alloc writer,
	ref immutable BuiltinFunInfo bf,
	ref immutable Arr!ConcreteType typeArgs,
	ref immutable ConcreteExpr ce,
	ref immutable ConcreteExpr.Call e,
) {
	void writeArg(immutable size_t index) {
		writeExpr(writer, at(e.args, index));
	}

	void binaryOperatorWorker(immutable Str operator) {
		assert(size(e.args) == 2);
		writeChar(writer, '(');
		writeArg(0);
		writeChar(writer, ' ');
		writeStr(writer, operator);
		writeChar(writer, ' ');
		writeArg(1);
		writeChar(writer, ')');
	}

	void binaryOperator(immutable string s) {
		binaryOperatorWorker(strLiteral(s));
	}

	void unaryOperatorWorker(immutable Str operator) {
		assert(size(e.args) == 1);
		writeStr(writer, operator);
		writeChar(writer, '(');
		writeArg(0);
		writeChar(writer, ')');
	}

	void unaryOperator(immutable string s) {
		unaryOperatorWorker(strLiteral(s));
	}

	switch (bf.kind) {
		case BuiltinFunKind.and:
			binaryOperator("&&");
			break;

		case BuiltinFunKind.as:
		case BuiltinFunKind.asNonConst:
			writeArg(0);
			break;

		case BuiltinFunKind.bitShiftLeftInt32:
			// TODO: does this wrap?
			binaryOperator("<<");
			break;

		case BuiltinFunKind.bitShiftRightInt32:
			// TODO: does this wrap?
			binaryOperator(">>");
			break;

		case BuiltinFunKind.bitwiseAndInt16:
		case BuiltinFunKind.bitwiseAndInt32:
		case BuiltinFunKind.bitwiseAndInt64:
		case BuiltinFunKind.bitwiseAndNat16:
		case BuiltinFunKind.bitwiseAndNat32:
		case BuiltinFunKind.bitwiseAndNat64:
			binaryOperator("&");
			break;

		case BuiltinFunKind.bitwiseOrInt16:
		case BuiltinFunKind.bitwiseOrInt32:
		case BuiltinFunKind.bitwiseOrInt64:
		case BuiltinFunKind.bitwiseOrNat16:
		case BuiltinFunKind.bitwiseOrNat32:
		case BuiltinFunKind.bitwiseOrNat64:
			binaryOperator("|");
			break;

		case BuiltinFunKind.callFunPtr:
			writeArg(0);
			writeChar(writer, '(');
			foreach (immutable size_t i; 1..size(e.args)) {
				if (i != 1)
					writeStatic(writer, ", ");
				writeArg(i);
			}
			writeChar(writer, ')');
			break;

		case BuiltinFunKind.getCtx:
			writeStatic(writer, "_ctx");
			break;

		case BuiltinFunKind.if_:
			writeChar(writer, '(');
			writeArg(0);
			writeStatic(writer, " ? ");
			writeArg(1);
			writeStatic(writer, " : ");
			writeArg(2);
			writeChar(writer, ')');
			break;

		case BuiltinFunKind.not:
			unaryOperator("!");
			break;

		case BuiltinFunKind.null_:
			writeStatic(writer, "NULL");
			break;

		case BuiltinFunKind.or:
			binaryOperator("||");
			break;

		// TODO: int operators don't wrap in c++!
		case BuiltinFunKind.wrapAddInt16:
		case BuiltinFunKind.wrapAddInt32:
		case BuiltinFunKind.wrapAddInt64:
			binaryOperator("+");
			break;
		case BuiltinFunKind.wrapSubInt16:
		case BuiltinFunKind.wrapSubInt32:
		case BuiltinFunKind.wrapSubInt64:
			binaryOperator("-");
			break;
		case BuiltinFunKind.wrapMulInt16:
		case BuiltinFunKind.wrapMulInt32:
		case BuiltinFunKind.wrapMulInt64:
			binaryOperator("*");
			break;

		case BuiltinFunKind.addPtr:
		case BuiltinFunKind.addFloat64:
		case BuiltinFunKind.wrapAddNat16:
		case BuiltinFunKind.wrapAddNat32:
		case BuiltinFunKind.wrapAddNat64:
			binaryOperator("+");
			break;

		case BuiltinFunKind.sizeOf:
			writeStatic(writer, "sizeof(");
			writeType(writer.writer, only(typeArgs));
			writeChar(writer, ')');
			break;

		case BuiltinFunKind.subFloat64:
		case BuiltinFunKind.subPtrNat:
		case BuiltinFunKind.wrapSubNat16:
		case BuiltinFunKind.wrapSubNat32:
		case BuiltinFunKind.wrapSubNat64:
			binaryOperator("-");
			break;

		case BuiltinFunKind.mulFloat64:
		case BuiltinFunKind.wrapMulNat16:
		case BuiltinFunKind.wrapMulNat32:
		case BuiltinFunKind.wrapMulNat64:
			binaryOperator("*");
			break;

		case BuiltinFunKind.asAnyPtr:
		case BuiltinFunKind.asRef:
		case BuiltinFunKind.toIntFromInt16:
		case BuiltinFunKind.toIntFromInt32:
		case BuiltinFunKind.toNatFromNat16:
		case BuiltinFunKind.toNatFromNat32:
		case BuiltinFunKind.toNatFromPtr:
		case BuiltinFunKind.unsafeNat64ToInt64:
		case BuiltinFunKind.unsafeNat64ToNat16:
		case BuiltinFunKind.unsafeNat64ToNat32:
		case BuiltinFunKind.unsafeInt64ToInt16:
		case BuiltinFunKind.unsafeInt64ToInt32:
		case BuiltinFunKind.unsafeInt64ToNat64:
			writeCastToType!Alloc(writer.writer, returnType(e));
			writeArg(0);
			break;

		case BuiltinFunKind.unsafeDivFloat64:
		case BuiltinFunKind.unsafeDivInt64:
		case BuiltinFunKind.unsafeDivNat64:
			binaryOperator("/");
			break;

		case BuiltinFunKind.unsafeModNat64:
			binaryOperator("%");
			break;

		case BuiltinFunKind.deref:
			unaryOperator("*");
			break;

		case BuiltinFunKind.oneInt16:
		case BuiltinFunKind.oneInt32:
		case BuiltinFunKind.oneInt64:
		case BuiltinFunKind.oneNat16:
		case BuiltinFunKind.oneNat32:
		case BuiltinFunKind.oneNat64:
		case BuiltinFunKind.true_:
			writeChar(writer, '1');
			break;

		case BuiltinFunKind.ptrCast:
			writeCastToType(writer.writer, ce.type);
			writeArg(0);
			break;

		case BuiltinFunKind.ptrTo:
		case BuiltinFunKind.refOfVal:
			writeStatic(writer, "(&(");
			writeArg(0);
			writeStatic(writer, "))");
			break;

		case BuiltinFunKind.setPtr:
			// ((*(p) = v), 0)
			writeStatic(writer, "((*(");
			writeArg(0);
			writeStatic(writer, ") = ");
			writeArg(1);
			writeStatic(writer, "), 0)");
			break;


		case BuiltinFunKind.false_:
		case BuiltinFunKind.pass:
		case BuiltinFunKind.zeroInt16:
		case BuiltinFunKind.zeroInt32:
		case BuiltinFunKind.zeroInt64:
		case BuiltinFunKind.zeroNat16:
		case BuiltinFunKind.zeroNat32:
		case BuiltinFunKind.zeroNat64:
			writeChar(writer, '0');
			break;

		default:
			debug {
				import core.stdc.stdio : printf;
				printf("Unhandled BuiltinFunKind: %lu\n", cast(size_t) bf.kind);
			}
			unreachable!void();
			break;
	}
}

void writeArgsWithCtx(Alloc)(ref WriterWithIndent!Alloc writer, ref immutable Arr!ConcreteExpr args) {
	writeStatic(writer, "(_ctx");
	writeWithCommas(writer.writer, args, True, (ref immutable ConcreteExpr e) =>
		writeExpr(writer, e));
	writeChar(writer, ')');
}

void writeArgsNoCtxNoParens(Alloc)(ref WriterWithIndent!Alloc writer, ref immutable Arr!ConcreteExpr args) {
	writeWithCommas(writer.writer, args, False, (ref immutable ConcreteExpr e) =>
		writeExpr(writer, e));
}

void writeArgsNoCtx(Alloc)(ref WriterWithIndent!Alloc writer, ref immutable Arr!ConcreteExpr args) {
	writeChar(writer, '(');
	writeArgsNoCtxNoParens(writer, args);
	writeChar(writer, ')');
}

void writeArgsNoCtxWithBraces(Alloc)(ref WriterWithIndent!Alloc writer, ref immutable Arr!ConcreteExpr args) {
	writeChar(writer, '{');
	writeArgsNoCtxNoParens(writer, args);
	writeChar(writer, '}');
}

void writeArgsWithOptionalCtx(Alloc)(
	ref WriterWithIndent!Alloc writer,
	immutable Bool needsCtx,
	ref immutable Arr!ConcreteExpr args,
) {
	if (needsCtx)
		writeArgsWithCtx(writer, args);
	else
		writeArgsNoCtx(writer, args);
}

immutable(Bool) returnsVoid(ref immutable ConcreteFun fun) {
	// TODO: better way to detect this than looking at the name
	return strEq(returnType(fun).struct_.mangledName, strLiteral("_void"));
}

void writeCall(Alloc)(
	ref WriterWithIndent!Alloc writer,
	ref immutable ConcreteExpr ce,
	ref immutable ConcreteExpr.Call e,
) {
	void call() {
		writeStr(writer, e.called.mangledName);
		writeArgsWithOptionalCtx(writer, e.called.needsCtx, e.args);
	}

	immutable ConcreteFunBody calledBody = body_(e.called);
	if (isBuiltin(calledBody)) {
		immutable ConcreteFunBody.Builtin builtin = asBuiltin(calledBody);
		immutable BuiltinFunInfo bf = builtin.builtinInfo;
		final switch (bf.emit) {
			case BuiltinFunEmit.special:
				call();
				break;
			case BuiltinFunEmit.operator:
				writeCallOperator(writer, bf, builtin.typeArgs, ce, e);
				break;
			case BuiltinFunEmit.generate:
				unreachable!void;
				break;
		}
	} else if (isExtern(e.called)) {
		if (returnsVoid(e.called)) {
			//TODO: make `void foo() global` an error in the frontend
			assert(!isGlobal(e.called));
			// Extern functions really return 'void', we need it to be an expression.
			writeChar(writer, '(');
			call();
			writeStatic(writer, ", 0)");
		} else if (isGlobal(e.called))
			writeStr(writer, mangledName(e.called));
		else
			call();
	} else
		call();
}

void writeAllocNBytes(Alloc)(ref Writer!Alloc writer, ref immutable ConcreteFun alloc, immutable size_t nBytes) {
	assert(alloc.needsCtx);
	writeStr(writer, mangledName(alloc));
	writeStatic(writer, "(_ctx, ");
	writeNat(writer, nBytes);
	writeChar(writer, ')');
}

void writeCreateArr(Alloc)(ref WriterWithIndent!Alloc writer, ref immutable ConcreteExpr.CreateArr e) {
	// (arr = arr_foo{3, _alloc(ctx, 100)},
	//  arr.data[0] = a,
	//  arr.data[1] = b,
	//  arr.data[2] = c,
	//  arr)
	writeChar(writer, '(');
	immutable Ptr!ConcreteLocal local = e.local;
	writeLocalAssignment(writer.writer, local);
	writeCastToValueType(writer.writer, e.arrType);
	writeStatic(writer, "{ ");
	writeNat(writer.writer, size(e.args));
	writeStatic(writer, ", (");
	writeType(writer.writer, e.elementType);
	writeStatic(writer, "*) ");
	writeAllocNBytes(writer.writer, e.alloc, sizeBytes(e));
	writeStatic(writer, " }");
	foreach (immutable size_t i; 0..size(e.args)) {
		writeStatic(writer, ", ");
		writeLocalRef(writer.writer, local);
		writeStatic(writer, ".data[");
		writeNat(writer.writer, i);
		writeStatic(writer, "] =");
		writeExpr(writer, at(e.args, i));
	}
	writeStatic(writer, ", ");
	writeLocalRef(writer.writer, local);
	writeChar(writer, ')');
}

immutable(ConcreteType) getMemberType(
	ref immutable ConcreteExpr ce,
	ref immutable ConcreteExpr.ConvertToUnion e,
) {
	return at(asUnion(body_(ce.type.struct_)).members, e.memberIndex);
}

void writeLambda(Alloc)(
	ref WriterWithIndent!Alloc writer,
	ref immutable ConcreteExpr ce,
	ref immutable ConcreteExpr.Lambda e,
) {
	if (has(e.closure)) {
		// Write out a record.
		immutable ConcreteType type = ce.type;
		immutable Arr!ConcreteField fields = asRecord(body_(type.struct_)).fields;
		assert(size(fields) == 2);
		immutable Ptr!ConcreteField funPtrField = ptrAt(fields, 0);
		immutable Ptr!ConcreteField dataPtrField = ptrAt(fields, 1);

		writeCastToType(writer.writer, type);
		writeChar(writer, '{');
		indent(writer);
		writeCastToType(writer.writer, funPtrField.type);
		writeStr(writer, mangledName(e.fun));
		writeChar(writer, ',');
		newline(writer);
		writeCastToType(writer.writer, dataPtrField.type);
		writeExpr(writer, force(e.closure));
		dedent(writer);
		writeChar(writer, '}');
	} else
		writeStr(writer, mangledName(e.fun));
}

void writeExpr(Alloc)(ref WriterWithIndent!Alloc writer, ref immutable ConcreteExpr ce) {
	immutable ConcreteType type = ce.type;
	matchConcreteExpr!void(
		ce,
		(ref immutable ConcreteExpr.Bogus) {
			unreachable!void();
		},
		(ref immutable ConcreteExpr.Alloc e) {
			writeStatic(writer, "_init");
			writeStr(writer.writer, mustBePointer(type).mangledName);
			writeChar(writer, '(');
			writeAllocNBytes(writer.writer, e.alloc, sizeBytes(mustBePointer(type).deref));
			writeStatic(writer, ", ");
			writeExpr(writer, e.inner);
			writeChar(writer, ')');
		},
		(ref immutable ConcreteExpr.Call e) {
			writeCall(writer, ce, e);
		},
		(ref immutable ConcreteExpr.Cond e) {
			writeExpr(writer, e.cond);
			indent(writer);
			writeStatic(writer, "? ");
			writeExpr(writer, e.then);
			newline(writer);
			writeStatic(writer, ": ");
			writeExpr(writer, e.else_);
			decrIndent(writer);
		},
		(ref immutable ConcreteExpr.CreateArr e) {
			writeCreateArr(writer, e);
		},
		(ref immutable ConcreteExpr.CreateRecord e) {
			writeCastToType(writer.writer, type);
			if (empty(e.args))
				// C forces structs to be non-empty
				writeStatic(writer.writer, "{ 0 }");
			else
				writeArgsNoCtxWithBraces(writer, e.args);
		},
		(ref immutable ConcreteExpr.ConvertToUnion e) {
			writeCastToType(writer.writer, type);
			writeStatic(writer, "{ ");
			writeNat(writer.writer, e.memberIndex);
			writeStatic(writer, ", .as_");
			writeStr(writer, getMemberType(ce, e).struct_.mangledName);
			writeStatic(writer, " = ");
			writeExpr(writer, e.arg);
			writeStatic(writer, " }");
		},
		(ref immutable ConcreteExpr.Lambda e) {
			writeLambda(writer, ce, e);
		},
		(ref immutable ConcreteExpr.Let e) {
			// ((x = value),
			// then)
			writeStatic(writer, "((");
			writeLocalAssignment(writer.writer, e.local);
			writeExpr(writer, e.value);
			writeStatic(writer, "),");
			newline(writer);
			writeExpr(writer, e.then);
			writeStatic(writer, ")");
		},
		(ref immutable ConcreteExpr.LocalRef e) {
			writeLocalRef(writer.writer, e.local);
		},
		(ref immutable ConcreteExpr.Match e) {
			writeMatch(writer, ce, e);
		},
		(ref immutable ConcreteExpr.ParamRef e) {
			writeStr(writer, e.param.mangledName);
		},
		(ref immutable ConcreteExpr.RecordFieldAccess e) {
			writeFieldAccess(writer, e.targetIsPointer, e.target, e.field);
		},
		(ref immutable ConcreteExpr.RecordFieldSet e) {
			// (s.x = v), 0
			writeChar(writer, '(');
			writeFieldAccess(writer, e.targetIsPointer, e.target, e.field);
			writeStatic(writer, " = ");
			writeExpr(writer, e.value);
			writeStatic(writer, "), 0");
		},
		(ref immutable ConcreteExpr.Seq e) {
			writeChar(writer, '(');
			writeExpr(writer, e.first);
			writeChar(writer, ',');
			newline(writer);
			writeExpr(writer, e.then);
			writeChar(writer, ')');
		},
		(ref immutable ConcreteExpr.SpecialConstant e) {
			final switch (e.kind) {
				case ConcreteExpr.SpecialConstant.Kind.one:
					writeChar(writer, '1');
					break;
				case ConcreteExpr.SpecialConstant.Kind.zero:
					writeChar(writer, '0');
					break;
			}
		},
		(ref immutable ConcreteExpr.SpecialUnary e) {
			final switch (e.kind) {
				case ConcreteExpr.SpecialUnary.Kind.deref:
					writeStatic(writer, "*(");
					writeExpr(writer, e.arg);
					writeChar(writer, ')');
					break;
			}
		},
		(ref immutable ConcreteExpr.SpecialBinary e) {
			writeChar(writer, '(');
			writeExpr(writer, e.left);
			writeChar(writer, ' ');
			writeStatic(writer, () {
				final switch (e.kind) {
					case ConcreteExpr.SpecialBinary.Kind.add:
						return "+";
					case ConcreteExpr.SpecialBinary.Kind.eq:
						return "==";
					case ConcreteExpr.SpecialBinary.Kind.less:
						return "<";
					case ConcreteExpr.SpecialBinary.Kind.or:
						return "||";
					case ConcreteExpr.SpecialBinary.Kind.sub:
						return "-";
				}
			}());
			writeChar(writer, ' ');
			writeExpr(writer, e.right);
			writeChar(writer, ')');
		},
		(ref immutable ConcreteExpr.StringLiteral e) {
			writeStringLiteral(writer.writer, e.literal);
		});
}

void writeSigParams(Alloc)(
	ref Writer!Alloc writer,
	immutable Bool needsCtx,
	immutable Opt!ConcreteParam closure,
	immutable Arr!ConcreteParam params,
) {
	writeChar(writer, '(');
	if (needsCtx)
		writeStatic(writer, "ctx* _ctx");
	if (has(closure)) {
		if (needsCtx)
			writeStatic(writer, ", ");
		doWriteParam(writer, force(closure));
	}
	writeJustParams(writer, Bool(needsCtx || has(closure)), params);
}

void writeFunReturnTypeNameAndParams(Alloc)(ref Writer!Alloc writer, ref immutable ConcreteFun fun) {
	if (isExtern(fun) && returnsVoid(fun))
		writeStatic(writer, "void");
	else
		writeType(writer, returnType(fun));
	writeChar(writer, ' ');
	writeStr(writer, mangledName(fun));
	if (!isGlobal(fun))
		writeSigParams(writer, fun.needsCtx, fun.closureParam, fun.paramsExcludingCtxAndClosure);
}

void writeConcreteFunDeclaration(Alloc)(ref Writer!Alloc writer, ref immutable ConcreteFun fun) {
	//TODO:HAX: printf apparently *must* be declared as variadic
	if (strEqLiteral(mangledName(fun), "printf"))
		writeStatic(writer, "int printf(const char* format, ...);\n");
	else {
		if (isExtern(body_(fun)))
			writeStatic(writer, "extern ");
		writeFunReturnTypeNameAndParams(writer, fun);
		writeStatic(writer, ";\n");
	}
}

void writeFunWithBodyWorker(Alloc)(
	ref Writer!Alloc writer,
	ref immutable ConcreteFun fun,
	scope void delegate() @safe @nogc pure nothrow cbWriteBody,
) {
	writeFunReturnTypeNameAndParams(writer, fun);
	writeStatic(writer, " {\n\t");
	cbWriteBody();
	writeStatic(writer, "\n}\n");
}

void declareLocals(Alloc)(ref Writer!Alloc writer, ref immutable Arr!(Ptr!ConcreteLocal) locals) {
	foreach (immutable Ptr!ConcreteLocal local; range(locals))
		writeLocalDeclaration(writer, local);
}

void writeFunWithExprBody(Alloc)(
	ref Writer!Alloc writer,
	ref immutable ConcreteFun fun,
	ref immutable ConcreteFunExprBody body_,
) {
	writeFunWithBodyWorker(writer, fun, () {
		declareLocals(writer, body_.allLocals);
		writeStatic(writer, "return ");
		WriterWithIndent!Alloc writerWithIndent = WriterWithIndent!Alloc(ptrTrustMe_mut(writer), 1);
		writeExpr(writerWithIndent, body_.expr);
		writeChar(writer, ';');
	});
}

void writeSpecialBody(Alloc)(
	ref Writer!Alloc writer,
	ref immutable ConcreteFun fun,
	immutable BuiltinFunKind kind,
) {
	switch (kind) {
		case BuiltinFunKind.compareExchangeStrong: {
			writeStatic(writer, "return atomic_compare_exchange_strong(");
			immutable Arr!ConcreteParam params = paramsExcludingCtxAndClosure(fun);
			assert(size(params) == 3);
			writeStr(writer, at(params, 0).mangledName);
			writeStatic(writer, ", ");
			writeStr(writer, at(params, 1).mangledName);
			writeStatic(writer, ", ");
			writeStr(writer, at(params, 2).mangledName);
			writeStatic(writer, ");");
			break;
		}

		case BuiltinFunKind.getErrno:
			writeStatic(writer, "return errno;");
			break;

		case BuiltinFunKind.hardFail:
			writeStatic(writer, "assert(0);");
			break;

		default:
			unreachable!void();
	}
}

void writeConcreteFunDefinition(Alloc)(ref Writer!Alloc writer, ref immutable ConcreteFun fun) {
	matchConcreteFunBody(
		body_(fun),
		(ref immutable ConcreteFunBody.Bogus) {
			unreachable!void();
		},
		(ref immutable ConcreteFunBody.Builtin builtin) {
			immutable BuiltinFunInfo info = builtin.builtinInfo;
			final switch (info.emit) {
				case BuiltinFunEmit.generate:
					// A 'generate' builtin should have given us a ConcreteExpr body.
					unreachable!void();
					break;
				case BuiltinFunEmit.operator:
					// Will emit it inline, no need to define
					break;
				case BuiltinFunEmit.special:
					writeFunWithBodyWorker(writer, fun, () {
						writeSpecialBody(writer, fun, info.kind);
					});
					break;
			}
		},
		(ref immutable ConcreteFunBody.Extern) {
			// Already declared, nothing more to do
		},
		(ref immutable ConcreteFunExprBody b) {
			writeFunWithExprBody!Alloc(writer, fun, b);
		});
}

void writeInitAndFailFuns(Alloc)(ref Writer!Alloc writer, ref immutable Arr!(Ptr!ConcreteStruct) allStructs) {
	//TODO: only do 'init' for structs that will be allocated
	//TODO: only do 'fail' for structs returned from a match by value
	foreach (immutable ConcreteStruct struct_; range(allStructs)) {
		void writeType() {
			writeValueType(writer, struct_);
		}
		writeChar(writer, '\n');
		writeType();
		writeStatic(writer, "* _init");
		writeStr(writer, struct_.mangledName);
		writeStatic(writer, "(byte* out, ");
		writeType();
		writeStatic(writer, " value) {\n\t");
		writeType();
		writeStatic(writer, "* res = (");
		writeType();
		writeStatic(writer, "*) out; \n\t*res = value;\n\treturn res;\n}\n");

		writeType();
		writeStatic(writer, " _fail");
		writeStr(writer, struct_.mangledName);
		writeStatic(writer, "() {\n\tassert(0);\n}\n\n");
	}

	writeStatic(writer, "void* _failVoidPtr() { assert(0); }\n");
}

void writeMain(Alloc)(
	ref Writer!Alloc writer,
	ref immutable ConcreteFun rtMain,
	ref immutable ConcreteFun userMain,
	ref immutable Arr!(Ptr!ConcreteStruct) allStructs,
) {
	writeStatic(writer, "\n\nint main(int argc, char** argv) {");
	foreach (immutable Ptr!ConcreteStruct struct_; range(allStructs)) {
		writeStatic(writer, "\n\tassert(sizeof(");
		writeStr(writer, struct_.mangledName);
		writeStatic(writer, ") == ");
		writeNat(writer, sizeBytes(struct_));
		writeStatic(writer, ");");
	}

	writeStatic(writer, "\n\n\treturn ");
	writeStr(writer, mangledName(rtMain));
	writeStatic(writer, "(argc, argv, ");
	writeStr(writer, mangledName(userMain));
	writeStatic(writer, ");\n}\n");
}

void writeStringLiteral(Alloc)(ref Writer!Alloc writer, ref immutable Str str) {
	writeStatic(writer, "(arr__char){");
	writeNat(writer, size(str));
	writeStatic(writer, ", ");
	writeQuotedString(writer, str);
	writeChar(writer, '}');
}

void writeQuotedString(Alloc)(ref Writer!Alloc writer, ref immutable Str str) {
	writeChar(writer, '"');
	foreach (immutable char c; range(str))
		writeEscapedChar(writer, c);
	writeChar(writer, '"');
}
