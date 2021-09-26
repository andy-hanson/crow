module backend.writeToC;

@safe @nogc pure nothrow:

import interpret.debugging : writeFunName, writeFunSig;
import lower.lowExprHelpers : boolType, voidType;
import model.concreteModel :
	body_,
	BuiltinStructKind,
	ConcreteFun,
	ConcreteFunSource,
	ConcreteLocal,
	ConcreteLocalSource,
	ConcreteParam,
	ConcreteParamSource,
	ConcreteStruct,
	ConcreteStructBody,
	ConcreteStructSource,
	isExtern,
	matchConcreteFunSource,
	matchConcreteParamSource,
	matchConcreteLocalSource,
	matchConcreteStructBody,
	matchConcreteStructSource,
	TypeSize;
import model.constant : asIntegral, Constant, matchConstant;
import model.lowModel :
	AllConstantsLow,
	ArrTypeAndConstantsLow,
	asPrimitive,
	asPtrGc,
	asRecordType,
	asUnionType,
	isChar,
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
	LowFunSource,
	LowLocal,
	LowLocalSource,
	LowParam,
	LowParamSource,
	LowProgram,
	LowRecord,
	LowType,
	LowUnion,
	matchLowExprKind,
	matchLowFunBody,
	matchLowFunSource,
	matchLowLocalSource,
	matchLowParamSource,
	matchLowTypeCombinePtr,
	name,
	PointerTypeAndConstantsLow,
	PrimitiveType,
	regularParams;
import model.model : EnumValue, FunInst, Local, name, Param;
import model.typeLayout : sizeOfType;
import util.collection.arr : at, empty, emptyArr, first, only, setAt, size, sizeEq;
import util.collection.arrUtil : arrLiteral, every, fillArr_mut, map, tail, zip;
import util.collection.dict : Dict, getAt;
import util.collection.dictBuilder : addToDict, DictBuilder, finishDictShouldBeNoConflict;
import util.collection.fullIndexDict :
	FullIndexDict,
	fullIndexDictEach,
	fullIndexDictEachKey,
	fullIndexDictEachValue,
	fullIndexDictGet,
	fullIndexDictGetPtr,
	fullIndexDictSize;
import util.collection.mutDict : insertOrUpdate, MutDict, setInDict;
import util.opt : force, has, none, Opt, some;
import util.ptr : comparePtr, Ptr, ptrTrustMe, ptrTrustMe_mut;
import util.sym :
	compareSym,
	eachCharInSym,
	Operator,
	operatorForSym,
	shortSymAlphaLiteral,
	shortSymAlphaLiteralValue,
	Sym,
	symEq,
	writeSym;
import util.types : abs, i64OfU64Bits, Nat16;
import util.util : drop, todo, unreachable, verify;
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

immutable(string) writeToC(Alloc, TempAlloc)(
	ref Alloc alloc,
	ref TempAlloc tempAlloc,
	ref immutable LowProgram program,
) {
	Writer!Alloc writer = Writer!Alloc(ptrTrustMe_mut(alloc));

	writeStatic(writer, "#include <stdatomic.h>\n");
	writeStatic(writer, "#include <stddef.h>\n"); // for NULL
	writeStatic(writer, "#include <stdint.h>\n");

	immutable Ctx ctx = immutable Ctx(ptrTrustMe(program), buildMangledNames(alloc, program));

	writeStructs(alloc, writer, ctx);

	writeConstants(writer, ctx, program.allConstants);

	fullIndexDictEach!(LowFunIndex, LowFun)(
		program.allFuns,
		(immutable LowFunIndex funIndex, ref immutable LowFun fun) {
			writeFunDeclaration(writer, ctx, funIndex, fun);
		});

	fullIndexDictEach!(LowFunIndex, LowFun)(
		program.allFuns,
		(immutable LowFunIndex funIndex, ref immutable LowFun fun) {
			writeFunDefinition(writer, tempAlloc, ctx, funIndex, fun);
		});

	return finishWriter(writer);
}

private:

void writeConstants(Alloc)(ref Writer!Alloc writer, ref immutable Ctx ctx, ref immutable AllConstantsLow allConstants) {
	foreach (ref immutable ArrTypeAndConstantsLow a; allConstants.arrs) {
		foreach (immutable size_t i; 0 .. size(a.constants)) {
			declareConstantArrStorage(writer, ctx, a.arrType, a.elementType, i, size(at(a.constants, i)));
			writeStatic(writer, ";\n");
		}
	}

	foreach (ref immutable PointerTypeAndConstantsLow a; allConstants.pointers) {
		foreach (immutable size_t i; 0 .. size(a.constants)) {
			declareConstantPointerStorage(writer, ctx, a.pointeeType, i);
			writeStatic(writer, ";\n");
		}
	}

	foreach (ref immutable ArrTypeAndConstantsLow a; allConstants.arrs) {
		foreach (immutable size_t i; 0 .. size(a.constants)) {
			immutable Constant[] elements = at(a.constants, i);
			declareConstantArrStorage(writer, ctx, a.arrType, a.elementType, i, size(elements));
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
		foreach (immutable size_t i; 0 .. size(a.constants)) {
			declareConstantPointerStorage(writer, ctx, a.pointeeType, i);
			writeStatic(writer, " = ");
			writeConstantRef(writer, ctx, ConstantRefPos.inner, a.pointeeType, at(a.constants, i));
			writeStatic(writer, ";\n");
		}
	}
}

void declareConstantArrStorage(Alloc)(
	ref Writer!Alloc writer,
	ref immutable Ctx ctx,
	immutable LowType.Record arrType,
	immutable LowType elementType,
	immutable size_t index,
	immutable size_t nElements,
) {
	writeType(writer, ctx, elementType);
	writeChar(writer, ' ');
	writeConstantArrStorageName(writer, ctx, arrType, index);
	writeChar(writer, '[');
	writeNat(writer, nElements);
	writeChar(writer, ']');
}

void writeConstantArrStorageName(Alloc)(
	ref Writer!Alloc writer,
	ref immutable Ctx ctx,
	immutable LowType.Record arrType,
	immutable size_t index,
) {
	writeStatic(writer, "constant");
	writeRecordName(writer, ctx, arrType);
	writeChar(writer, '_');
	writeNat(writer, index);
}

void declareConstantPointerStorage(Alloc)(
	ref Writer!Alloc writer,
	ref immutable Ctx ctx,
	immutable LowType pointeeType,
	immutable size_t index,
) {
	//TODO: some day we may support non-record pointee?
	writeRecordType(writer, ctx, asRecordType(pointeeType));
	writeChar(writer, ' ');
	writeConstantPointerStorageName(writer, ctx, pointeeType, index);
}

void writeConstantPointerStorageName(Alloc)(
	ref Writer!Alloc writer,
	ref immutable Ctx ctx,
	immutable LowType pointeeType,
	immutable size_t index,
) {
	writeStatic(writer, "constant");
	writeRecordName(writer, ctx, asRecordType(pointeeType));
	writeChar(writer, '_');
	writeNat(writer, index);
}

struct MangledNames {
	immutable Dict!(Ptr!ConcreteFun, size_t, comparePtr!ConcreteFun) funToNameIndex;
	//TODO:PERF we could use separate FullIndexDict for record, union, etc.
	immutable Dict!(Ptr!ConcreteStruct, size_t, comparePtr!ConcreteStruct) structToNameIndex;
}

struct PrevOrIndex(T) {
	@safe @nogc pure nothrow:

	@trusted immutable this(immutable Ptr!T a) { kind_ = Kind.prev; prev_ = a;}
	immutable this(immutable size_t a) { kind_ = Kind.index; index_ = a; }

	private:
	enum Kind {
		prev,
		index,
	}
	immutable Kind kind_;
	union {
		immutable Ptr!T prev_;
		immutable size_t index_;
	}
}

@trusted T matchPrevOrIndex(T, P)(
	ref immutable PrevOrIndex!P a,
	scope T delegate(immutable Ptr!P) @safe @nogc pure nothrow cbPrev,
	scope T delegate(immutable size_t) @safe @nogc pure nothrow cbIndex,
) {
	final switch (a.kind_) {
		case PrevOrIndex!P.Kind.prev:
			return cbPrev(a.prev_);
		case PrevOrIndex!P.Kind.index:
			return cbIndex(a.index_);
	}
}

immutable(MangledNames) buildMangledNames(Alloc)(ref Alloc alloc, ref immutable LowProgram program) {
	// First time we see a fun with a name, we'll store the fun-ptr here in case it's not overloaded.
	// After that, we'll start putting them in funToNameIndex, and store the next index here.
	MutDict!(immutable Sym, immutable PrevOrIndex!ConcreteFun, compareSym) funNameToIndex;
	// This will not have an entry for non-overloaded funs.
	DictBuilder!(Ptr!ConcreteFun, size_t, comparePtr!ConcreteFun) funToNameIndex;
	// HAX: Ensure "main" has that name.
	setInDict(alloc, funNameToIndex, shortSymAlphaLiteral("main"), immutable PrevOrIndex!ConcreteFun(0));
	fullIndexDictEachValue!(LowFunIndex, LowFun)(program.allFuns, (ref immutable LowFun it) {
		matchLowFunSource!void(
			it.source,
			(immutable Ptr!ConcreteFun cf) {
				matchConcreteFunSource!void(
					cf.source,
					(immutable Ptr!FunInst i) {
						//TODO: use temp alloc
						addToPrevOrIndex!(ConcreteFun, Alloc)(alloc, funNameToIndex, funToNameIndex, cf, name(i));
					},
					(ref immutable ConcreteFunSource.Lambda) {},
					(ref immutable ConcreteFunSource.Test) {});
			},
			(ref immutable LowFunSource.Generated it) {});
	});

	MutDict!(immutable Sym, immutable PrevOrIndex!ConcreteStruct, compareSym) structNameToIndex;
	// This will not have an entry for non-overloaded structs.
	DictBuilder!(Ptr!ConcreteStruct, size_t, comparePtr!ConcreteStruct) structToNameIndex;

	void build(immutable Ptr!ConcreteStruct s) {
		matchConcreteStructSource!void(
			s.source,
			(ref immutable ConcreteStructSource.Inst it) {
				addToPrevOrIndex!(ConcreteStruct, Alloc)(alloc, structNameToIndex, structToNameIndex, s, name(it.inst));
			},
			(ref immutable ConcreteStructSource.Lambda) {});
	}
	fullIndexDictEachValue!(LowType.ExternPtr, LowExternPtrType)(
		program.allExternPtrTypes,
		(ref immutable LowExternPtrType it) {
			build(it.source);
		});
	fullIndexDictEachValue!(LowType.FunPtr, LowFunPtrType)(
		program.allFunPtrTypes,
		(ref immutable LowFunPtrType it) {
			build(it.source);
		});
	fullIndexDictEachValue!(LowType.Record, LowRecord)(
		program.allRecords,
		(ref immutable LowRecord it) {
			build(it.source);
		});
	fullIndexDictEachValue!(LowType.Union, LowUnion)(
		program.allUnions,
		(ref immutable LowUnion it) {
			build(it.source);
		});

	return immutable MangledNames(
		finishDictShouldBeNoConflict(alloc, funToNameIndex),
		finishDictShouldBeNoConflict(alloc, structToNameIndex));
}

void addToPrevOrIndex(T, Alloc)(
	ref Alloc alloc,
	ref MutDict!(immutable Sym, immutable PrevOrIndex!T, compareSym) nameToIndex,
	ref DictBuilder!(Ptr!T, size_t, comparePtr!T) toNameIndex,
	immutable Ptr!T cur,
	immutable Sym name,
) {
	insertOrUpdate!(Alloc, immutable Sym, immutable PrevOrIndex!T, compareSym)(
		alloc,
		nameToIndex,
		name,
		() =>
			immutable PrevOrIndex!T(cur),
		(ref immutable PrevOrIndex!T it) =>
			immutable PrevOrIndex!T(matchPrevOrIndex!(immutable size_t)(
				it,
				(immutable Ptr!T prev) {
					addToDict(alloc, toNameIndex, prev, 0);
					addToDict(alloc, toNameIndex, cur, 1);
					return immutable size_t(2);
				},
				(immutable size_t index) {
					addToDict(alloc, toNameIndex, cur, index);
					return index + 1;
				})));
}

struct Ctx {
	immutable Ptr!LowProgram program;
	immutable MangledNames mangledNames;
}

struct FunBodyCtx {
	immutable Ptr!Ctx ctx;
	immutable bool hasTailRecur;
	immutable LowFunIndex curFun;
	size_t nextTemp;
}

immutable(Temp) getNextTemp(ref FunBodyCtx ctx) {
	immutable Temp temp = immutable Temp(ctx.nextTemp);
	ctx.nextTemp++;
	return temp;
}

void writeType(Alloc)(ref Writer!Alloc writer, ref immutable Ctx ctx, ref immutable LowType t) {
	return matchLowTypeCombinePtr!void(
		t,
		(immutable LowType.ExternPtr it) {
			writeStatic(writer, "struct ");
			writeStructMangledName(writer, ctx, fullIndexDictGet(ctx.program.allExternPtrTypes, it).source);
			writeChar(writer, '*');
		},
		(immutable LowType.FunPtr it) {
			writeStructMangledName(writer, ctx, fullIndexDictGet(ctx.program.allFunPtrTypes, it).source);
		},
		(immutable PrimitiveType it) {
			writePrimitiveType(writer, it);
		},
		(immutable Ptr!LowType pointee) {
			writeType(writer, ctx, pointee);
			writeChar(writer, '*');
		},
		(immutable LowType.Record it) {
			writeRecordType(writer, ctx, it);
		},
		(immutable LowType.Union it) {
			writeStatic(writer, "struct ");
			writeStructMangledName(writer, ctx, fullIndexDictGet(ctx.program.allUnions, it).source);
		});
}

void writeRecordType(Alloc)(ref Writer!Alloc writer, ref immutable Ctx ctx, immutable LowType.Record a) {
	writeStatic(writer, "struct ");
	writeRecordName(writer, ctx, a);
}

void writeRecordName(Alloc)(ref Writer!Alloc writer, ref immutable Ctx ctx, immutable LowType.Record a) {
	writeStructMangledName(writer, ctx, fullIndexDictGet(ctx.program.allRecords, a).source);
}

void writeCastToType(Alloc)(ref Writer!Alloc writer, ref immutable Ctx ctx, ref immutable LowType type) {
	writeChar(writer, '(');
	writeType(writer, ctx, type);
	writeStatic(writer, ") ");
}

void doWriteParam(Alloc)(ref Writer!Alloc writer, ref immutable Ctx ctx, ref immutable LowParam a) {
	writeType(writer, ctx, a.type);
	writeChar(writer, ' ');
	writeLowParamName(writer, a);
}

void writeLowParamName(Alloc)(ref Writer!Alloc writer, ref immutable LowParam a) {
	matchLowParamSource!void(
		a.source,
		(immutable Ptr!ConcreteParam cp) {
			matchConcreteParamSource!void(
				cp.source,
				(ref immutable ConcreteParamSource.Closure) {
					writeStatic(writer, "_closure");
				},
				(immutable Ptr!Param p) {
					if (has(p.name))
						writeMangledName(writer, force(p.name));
					else {
						writeStatic(writer, "_p");
						writeNat(writer, p.index);
					}
				});
		},
		(ref immutable LowParamSource.Generated it) {
			writeMangledName(writer, it.name);
		});
}

void writeStructHead(Alloc)(ref Writer!Alloc writer, ref immutable Ctx ctx, immutable Ptr!ConcreteStruct source) {
	writeStatic(writer, "struct ");
	writeStructMangledName(writer, ctx, source);
	writeStatic(writer, " {");
}

void writeStructEnd(Alloc)(ref Writer!Alloc writer) {
	writeStatic(writer, "\n};\n");
}

void writeRecord(Alloc)(ref Writer!Alloc writer, ref immutable Ctx ctx, ref immutable LowRecord a) {
	writeStructHead(writer, ctx, a.source);
	foreach (ref immutable LowField field; a.fields) {
		writeStatic(writer, "\n\t");
		writeType(writer, ctx, field.type);
		writeChar(writer, ' ');
		writeMangledName(writer, name(field));
		writeChar(writer, ';');
	}
	writeStatic(writer, "\n}");
	if (a.packed)
		writeStatic(writer, " __attribute__ ((__packed__))");
	writeStatic(writer, ";\n");
}

void writeUnion(Alloc)(ref Writer!Alloc writer, ref immutable Ctx ctx, ref immutable LowUnion a) {
	writeStructHead(writer, ctx, a.source);
	writeStatic(writer, "\n\tuint64_t kind;");
	writeStatic(writer, "\n\tunion {");
	foreach (immutable size_t memberIndex; 0 .. size(a.members)) {
		writeStatic(writer, "\n\t\t");
		writeType(writer, ctx, at(a.members, memberIndex));
		writeStatic(writer, " as");
		writeNat(writer, memberIndex);
		writeChar(writer, ';');
	}

	matchConcreteStructBody!void(
		body_(a.source),
		(ref immutable ConcreteStructBody.Builtin it) {
			verify(it.kind == BuiltinStructKind.fun);
			// Fun types must be 16 bytes
			if (every!LowType(a.members, (ref immutable LowType member) =>
				sizeOfType(ctx.program, member).size < immutable Nat16(8))) {
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

enum StructState {
	none,
	declared,
	defined,
}

struct StructStates {
	bool[] funPtrStates; // No need to define, just declared or not
	StructState[] recordStates;
	StructState[] unionStates;
}

immutable(bool) canReferenceTypeAsValue(
	ref immutable Ctx ctx,
	ref const StructStates states,
	ref immutable LowType t,
) {
	return matchLowTypeCombinePtr!(immutable bool)(
		t,
		(immutable LowType.ExternPtr) =>
			// Declared all up front
			true,
		(immutable LowType.FunPtr it) =>
			at(states.funPtrStates, it.index),
		(immutable PrimitiveType) =>
			true,
		(immutable Ptr!LowType pointee) =>
			canReferenceTypeAsPointee(ctx, states, pointee),
		(immutable LowType.Record it) =>
			at(states.recordStates, it.index) == StructState.defined,
		(immutable LowType.Union it) =>
			at(states.unionStates, it.index) == StructState.defined);
}

immutable(bool) canReferenceTypeAsPointee(
	ref immutable Ctx ctx,
	ref const StructStates states,
	ref immutable LowType t,
) {
	return matchLowTypeCombinePtr!(immutable bool)(
		t,
		(immutable LowType.ExternPtr) =>
			// Declared all up front
			true,
		(immutable LowType.FunPtr it) =>
			at(states.funPtrStates, it.index),
		(immutable PrimitiveType) =>
			true,
		(immutable Ptr!LowType pointee) =>
			canReferenceTypeAsPointee(ctx, states, pointee),
		(immutable LowType.Record it) =>
			at(states.recordStates, it.index) != StructState.none,
		(immutable LowType.Union it) =>
			at(states.unionStates, it.index) != StructState.none);
}

void declareStruct(Alloc)(ref Writer!Alloc writer, ref immutable Ctx ctx, immutable Ptr!ConcreteStruct source) {
	writeStatic(writer, "struct ");
	writeStructMangledName(writer, ctx, source);
	writeStatic(writer, ";\n");
}

void staticAssertStructSize(Alloc)(
	ref Writer!Alloc writer,
	ref immutable Ctx ctx,
	ref immutable LowType type,
	immutable TypeSize size,
) {
	writeStatic(writer, "_Static_assert(sizeof(");
	writeType(writer, ctx, type);
	writeStatic(writer, ") == ");
	writeNat(writer, size.size.raw());
	writeStatic(writer, ", \"\");\n");

	writeStatic(writer, "_Static_assert(_Alignof(");
	writeType(writer, ctx, type);
	writeStatic(writer, ") == ");
	writeNat(writer, size.alignment.raw());
	writeStatic(writer, ", \"\");\n");
}

void writeStructMangledName(Alloc)(
	ref Writer!Alloc writer,
	ref immutable Ctx ctx,
	immutable Ptr!ConcreteStruct source,
) {
	matchConcreteStructSource!void(
		source.source,
		(ref immutable ConcreteStructSource.Inst it) {
			writeMangledName(writer, name(it.inst));
			maybeWriteIndexSuffix(writer, getAt(ctx.mangledNames.structToNameIndex, source));
		},
		(ref immutable ConcreteStructSource.Lambda it) {
			writeFunMangledName(writer, ctx, it.containingFun);
			writeStatic(writer, "__lambda");
			writeNat(writer, it.index);
		});
}

void writeLowFunMangledName(Alloc)(
	ref Writer!Alloc writer,
	ref immutable Ctx ctx,
	immutable LowFunIndex funIndex,
	ref immutable LowFun fun,
) {
	matchLowFunSource!void(
		fun.source,
		(immutable Ptr!ConcreteFun it) {
			writeFunMangledName(writer, ctx, it);
		},
		(ref immutable LowFunSource.Generated it) {
			writeMangledName(writer, it.name);
			if (!symEq(it.name, shortSymAlphaLiteral("main"))) {
				writeChar(writer, '_');
				writeNat(writer, funIndex.index);
			}
		});
}

void writeFunMangledName(Alloc)(ref Writer!Alloc writer, ref immutable Ctx ctx, immutable Ptr!ConcreteFun source) {
	matchConcreteFunSource!void(
		source.source,
		(immutable Ptr!FunInst it) {
			if (isExtern(body_(source)))
				writeSym(writer, name(it));
			else {
				writeMangledName(writer, name(it));
				maybeWriteIndexSuffix(writer, getAt(ctx.mangledNames.funToNameIndex, source));
			}
		},
		(ref immutable ConcreteFunSource.Lambda it) {
			writeFunMangledName(writer, ctx, it.containingFun);
			writeStatic(writer, "__lambda");
			writeNat(writer, it.index);
		},
		(ref immutable ConcreteFunSource.Test it) {
			writeStatic(writer, "__test");
			writeNat(writer, it.index);
		});
}

void maybeWriteIndexSuffix(Alloc)(ref Writer!Alloc writer, immutable Opt!size_t index) {
	if (has(index)) {
		writeChar(writer, '_');
		writeNat(writer, force(index));
	}
}

immutable(bool) tryWriteFunPtrDeclaration(Alloc)(
	ref Writer!Alloc writer,
	ref immutable Ctx ctx,
	ref const StructStates structStates,
	immutable LowType.FunPtr funPtrIndex,
) {
	immutable LowFunPtrType funPtr = fullIndexDictGet(ctx.program.allFunPtrTypes, funPtrIndex);
	immutable bool canDeclare =
		canReferenceTypeAsPointee(ctx, structStates, funPtr.returnType) &&
		every!LowType(funPtr.paramTypes, (ref immutable LowType it) =>
			canReferenceTypeAsPointee(ctx, structStates, it));
	if (canDeclare) {
		writeStatic(writer, "typedef ");
		writeType(writer, ctx, funPtr.returnType);
		writeStatic(writer, " (*");
		writeStructMangledName(writer, ctx, funPtr.source);
		writeStatic(writer, ")(");
		writeWithCommas!LowType(writer, funPtr.paramTypes, (ref immutable LowType paramType) {
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
	immutable LowType.Record recordIndex,
) {
	verify(prevState != StructState.defined);
	immutable LowRecord record = fullIndexDictGet(ctx.program.allRecords, recordIndex);
	immutable bool canWriteFields = every!LowField(record.fields, (ref immutable LowField f) =>
		canReferenceTypeAsValue(ctx, structStates, f.type));
	if (canWriteFields) {
		writeRecord(writer, ctx, record);
		return StructState.defined;
	} else {
		declareStruct(writer, ctx, record.source);
		return StructState.declared;
	}
}

immutable(StructState) writeUnionDeclarationOrDefinition(Alloc)(
	ref Writer!Alloc writer,
	ref immutable Ctx ctx,
	ref const StructStates structStates,
	immutable StructState prevState,
	immutable LowType.Union unionIndex,
) {
	verify(prevState != StructState.defined);
	immutable LowUnion union_ = fullIndexDictGet(ctx.program.allUnions, unionIndex);
	if (every!LowType(union_.members, (ref immutable LowType t) => canReferenceTypeAsValue(ctx, structStates, t))) {
		writeUnion(writer, ctx, union_);
		return StructState.defined;
	} else {
		declareStruct(writer, ctx, union_.source);
		return StructState.declared;
	}
}

void writeStructs(Alloc, WriterAlloc)(ref Alloc alloc, ref Writer!WriterAlloc writer, ref immutable Ctx ctx) {
	writeStatic(writer, "\nstruct void_ {};\n");

	// Write extern-ptr types first
	fullIndexDictEachValue!(LowType.ExternPtr, LowExternPtrType)(
		ctx.program.allExternPtrTypes,
		(ref immutable LowExternPtrType it) {
			declareStruct(writer, ctx, it.source);
		});

	StructStates structStates = StructStates(
		fillArr_mut!bool(alloc, fullIndexDictSize(ctx.program.allFunPtrTypes), (immutable size_t) =>
			false),
		fillArr_mut!StructState(alloc, fullIndexDictSize(ctx.program.allRecords), (immutable size_t) =>
			StructState.none),
		fillArr_mut!StructState(alloc, fullIndexDictSize(ctx.program.allUnions), (immutable size_t) =>
			StructState.none));
	for (;;) {
		bool madeProgress = false;
		bool someIncomplete = false;
		fullIndexDictEachKey!(LowType.FunPtr, LowFunPtrType)(
			ctx.program.allFunPtrTypes,
			(immutable LowType.FunPtr funPtrIndex) {
				immutable bool curState = at(structStates.funPtrStates, funPtrIndex.index);
				if (!curState) {
					if (tryWriteFunPtrDeclaration(writer, ctx, structStates, funPtrIndex)) {
						setAt(structStates.funPtrStates, funPtrIndex.index, true);
						madeProgress = true;
					} else
						someIncomplete = true;
				}
			});
		//TODO: each over structStates.recordStates once that's a MutFullIndexDict
		fullIndexDictEachKey!(LowType.Record, LowRecord)(
			ctx.program.allRecords,
			(immutable LowType.Record recordIndex) {
				immutable StructState curState = at(structStates.recordStates, recordIndex.index);
				if (curState != StructState.defined) {
					immutable StructState didWork = writeRecordDeclarationOrDefinition(
						writer, ctx, structStates, curState, recordIndex);
					if (didWork > curState) {
						setAt(structStates.recordStates, recordIndex.index, didWork);
						madeProgress = true;
					} else
						someIncomplete = true;
				}
			});
		//TODO: each over structStates.unionStates once that's a MutFullIndexDict
		fullIndexDictEachKey!(LowType.Union, LowUnion)(ctx.program.allUnions, (immutable LowType.Union unionIndex) {
			immutable StructState curState = at(structStates.unionStates, unionIndex.index);
			if (curState != StructState.defined) {
				immutable StructState didWork = writeUnionDeclarationOrDefinition(
					writer, ctx, structStates, curState, unionIndex);
				if (didWork > curState) {
					setAt(structStates.unionStates, unionIndex.index, didWork);
					madeProgress = true;
				} else
					someIncomplete = true;
			}
		});
		if (someIncomplete)
			verify(madeProgress);
		else
			break;
	}
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

void writeFunReturnTypeNameAndParams(Alloc)(
	ref Writer!Alloc writer,
	ref immutable Ctx ctx,
	immutable LowFunIndex funIndex,
	ref immutable LowFun fun,
) {
	if (isExtern(fun.body_) && isVoid(fun.returnType))
		writeStatic(writer, "void");
	else
		writeType(writer, ctx, fun.returnType);
	writeChar(writer, ' ');
	writeLowFunMangledName(writer, ctx, funIndex, fun);
	if (!isGlobal(fun.body_)) {
		writeChar(writer, '(');
		if (empty(fun.params))
			writeStatic(writer, "void");
		else {
			doWriteParam(writer, ctx, first(fun.params));
			foreach (ref immutable LowParam p; tail(fun.params)) {
				writeStatic(writer, ", ");
				doWriteParam(writer, ctx, p);
			}
		}
		writeChar(writer, ')');
	}
}

void writeFunDeclaration(Alloc)(
	ref Writer!Alloc writer,
	ref immutable Ctx ctx,
	immutable LowFunIndex funIndex,
	ref immutable LowFun fun,
) {
	if (isExtern(fun.body_))
		writeStatic(writer, "extern ");
	writeFunReturnTypeNameAndParams(writer, ctx, funIndex, fun);
	writeStatic(writer, ";\n");
}

void writeFunDefinition(Alloc, TempAlloc)(
	ref Writer!Alloc writer,
	ref TempAlloc tempAlloc,
	ref immutable Ctx ctx,
	immutable LowFunIndex funIndex,
	ref immutable LowFun fun,
) {
	matchLowFunBody!void(
		fun.body_,
		(ref immutable LowFunBody.Extern it) {
			// declaration is enough
		},
		(ref immutable LowFunExprBody it) {
			// TODO: only if a flag is set
			writeStatic(writer, "/* ");
			writeFunName(writer, ctx.program, funIndex);
			writeChar(writer, ' ');
			writeFunSig(writer, ctx.program, fun);
			writeStatic(writer, " */\n");
			writeFunWithExprBody(writer, tempAlloc, ctx, funIndex, fun, it);
		});
}

void writeFunWithExprBody(Alloc, TempAlloc)(
	ref Writer!Alloc writer,
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

void writeTempDeclare(Alloc)(
	ref Writer!Alloc writer,
	ref FunBodyCtx ctx,
	ref immutable LowType type,
	immutable Temp temp,
) {
	writeType(writer, ctx.ctx, type);
	writeChar(writer, ' ');
	writeTempRef(writer, temp);
}

void writeTempRef(Alloc)(ref Writer!Alloc writer, ref immutable Temp a) {
	writeStatic(writer, "_");
	writeNat(writer, a.index);
}

void writeTempOrInline(Alloc, TempAlloc)(
	ref Writer!Alloc writer,
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

void writeTempOrInlines(Alloc, TempAlloc)(
	ref Writer!Alloc writer,
	ref TempAlloc tempAlloc,
	ref FunBodyCtx ctx,
	immutable LowExpr[] exprs,
	immutable WriteExprResult[] args,
) {
	verify(sizeEq(exprs, args));
	writeWithCommas(writer, size(args), (immutable size_t i) {
		writeTempOrInline(writer, tempAlloc, ctx, at(exprs, i), at(args, i));
	});
}

void writeDeclareLocal(Alloc)(
	ref Writer!Alloc writer,
	immutable size_t indent,
	ref FunBodyCtx ctx,
	immutable Ptr!LowLocal local,
) {
	writeNewline(writer, indent);
	writeType(writer, ctx.ctx, local.type);
	writeChar(writer, ' ');
	writeLocalRef(writer, local);
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

immutable(WriteExprResult[]) writeExprsTempOrInline(Alloc, TempAlloc)(
	ref Writer!Alloc writer,
	ref TempAlloc tempAlloc,
	immutable size_t indent,
	ref FunBodyCtx ctx,
	immutable LowExpr[] args,
) {
	return map!(WriteExprResult, LowExpr, TempAlloc)(tempAlloc, args, (ref immutable LowExpr arg) =>
		writeExprTempOrInline(writer, tempAlloc, indent, ctx, arg));
}

immutable(Temp) writeExprTemp(Alloc, TempAlloc)(
	ref Writer!Alloc writer,
	ref TempAlloc tempAlloc,
	immutable size_t indent,
	ref FunBodyCtx ctx,
	ref immutable LowExpr expr,
) {
	immutable WriteKind writeKind = immutable WriteKind(immutable WriteKind.MakeTemp());
	immutable WriteExprResult res = writeExpr(writer, tempAlloc, indent, ctx, writeKind, expr);
	return asTemp(res);
}

immutable(WriteExprResult) writeExprTempOrInline(Alloc, TempAlloc)(
	ref Writer!Alloc writer,
	ref TempAlloc tempAlloc,
	immutable size_t indent,
	ref FunBodyCtx ctx,
	ref immutable LowExpr expr,
) {
	immutable WriteKind writeKind = immutable WriteKind(immutable WriteKind.InlineOrTemp());
	return writeExpr(writer, tempAlloc, indent, ctx, writeKind, expr);
}

immutable(WriteExprResult) writeExpr(Alloc, TempAlloc)(
	ref Writer!Alloc writer,
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

	return matchLowExprKind!(immutable WriteExprResult)(
		expr.kind,
		(ref immutable LowExprKind.Call it) =>
			writeCallExpr(writer, tempAlloc, indent, ctx, writeKind, type, it),
		(ref immutable LowExprKind.CreateRecord it) =>
			inlineable(it.args, (ref immutable WriteExprResult[] args) {
				writeCastToType(writer, ctx.ctx, type);
				writeChar(writer, '{');
				writeTempOrInlines(writer, tempAlloc, ctx, it.args, args);
				writeChar(writer, '}');
			}),
		(ref immutable LowExprKind.ConvertToUnion it) =>
			inlineableSingleArg(it.arg, (ref immutable WriteExprResult arg) {
				writeConvertToUnion(writer, ctx.ctx, ConstantRefPos.outer, type, it.memberIndex, () {
					writeTempOrInline(writer, tempAlloc, ctx, it.arg, arg);
				});
			}),
		(ref immutable LowExprKind.FunPtr it) =>
			inlineableSimple(() {
				writeFunPtr(writer, ctx.ctx, it);
			}),
		(ref immutable LowExprKind.Let it) {
			if (!isInline(writeKind)) {
				writeDeclareLocal(writer, indent, ctx, it.local);
				writeChar(writer, ';');
				immutable WriteKind localWriteKind = immutable WriteKind(it.local);
				drop(writeExpr(writer, tempAlloc, indent, ctx, localWriteKind, it.value));
				writeNewline(writer, indent);
			}
			return writeExpr(writer, tempAlloc, indent, ctx, writeKind, it.then);
		},
		(ref immutable LowExprKind.LocalRef it) =>
			inlineableSimple(() {
				writeLocalRef(writer, it.local);
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
				writeRecordFieldRef!Alloc(writer, ctx, it.targetIsPointer, it.record, it.fieldIndex);
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
		(ref immutable LowExprKind.SpecialTrinary it) =>
			writeSpecialTrinary(writer, tempAlloc, indent, ctx, writeKind, type, it),
		(ref immutable LowExprKind.SpecialNAry it) =>
			writeSpecialNAry(writer, tempAlloc, indent, ctx, writeKind, type, it),
		(ref immutable LowExprKind.Switch0ToN it) =>
			writeSwitch(writer, tempAlloc, indent, ctx, writeKind, type, it.value, it.cases, (immutable size_t i) =>
				immutable EnumValue(i)),
		(ref immutable LowExprKind.SwitchWithValues it) =>
			writeSwitch(writer, tempAlloc, indent, ctx, writeKind, type, it.value, it.cases, (immutable size_t i) =>
				at(it.values, i)),
		(ref immutable LowExprKind.TailRecur it) {
			verify(isReturn(writeKind));
			writeTailRecur(writer, tempAlloc, indent, ctx, it);
			return writeExprDone();
		},
		(ref immutable LowExprKind.Zeroed) =>
			inlineableSimple(() {
				writeZeroedValue(writer, ctx.ctx, type);
			}));
}

immutable(WriteExprResult) writeNonInlineable(Alloc)(
	ref Writer!Alloc writer,
	immutable size_t indent,
	ref FunBodyCtx ctx,
	ref immutable WriteKind writeKind,
	ref immutable LowType type,
	scope void delegate() @safe @nogc pure nothrow cb,
) {
	if (!isInline(writeKind)) writeNewline(writer, indent);
	immutable(WriteExprResult) makeTemp() {
		immutable Temp temp = getNextTemp(ctx);
		writeTempDeclare!Alloc(writer, ctx, type, temp);
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
			writeLocalRef(writer, it);
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

immutable(WriteExprResult) writeInlineable(Alloc, TempAlloc)(
	ref Writer!Alloc writer,
	ref TempAlloc tempAlloc,
	immutable size_t indent,
	ref FunBodyCtx ctx,
	ref immutable WriteKind writeKind,
	ref immutable LowType type,
	immutable LowExpr[] args,
	scope void delegate(ref immutable WriteExprResult[]) @safe @nogc pure nothrow inline,
) {
	immutable(WriteExprResult[]) setup() {
		return writeExprsTempOrInline(writer, tempAlloc, indent, ctx, args);
	}

	if (isInlineOrTemp(writeKind)) {
		return immutable WriteExprResult(immutable WriteExprResult.Done(setup()));
	} else if (isInline(writeKind)) {
		inline(asInline(writeKind).args);
		return writeExprDone();
	} else {
		immutable WriteExprResult[] argTemps = setup();
		return writeNonInlineable!Alloc(writer, indent, ctx, writeKind, type, () {
			inline(argTemps);
		});
	}
}

immutable(WriteExprResult) returnZeroedValue(Alloc, TempAlloc)(
	ref Writer!Alloc writer,
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

immutable(WriteExprResult) writeInlineableSingleArg(Alloc, TempAlloc)(
	ref Writer!Alloc writer,
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

immutable(WriteExprResult) writeInlineableSimple(Alloc, TempAlloc)(
	ref Writer!Alloc writer,
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

immutable(WriteExprResult) writeReturnVoid(Alloc)(
	ref Writer!Alloc writer,
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

immutable(WriteExprResult) writeCallExpr(Alloc, TempAlloc)(
	ref Writer!Alloc writer,
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
		immutable bool isCVoid = isExtern(called.body_) && isVoid(called.returnType);
		if (isCVoid)
			//TODO: this is unnecessary if writeKind is not 'expr'
			writeChar(writer, '(');
		writeLowFunMangledName(writer, ctx.ctx, a.called, called);
		if (!isGlobal(called.body_)) {
			writeChar(writer, '(');
			writeTempOrInlines(writer, tempAlloc, ctx, a.args, args);
			writeChar(writer, ')');
		}
		if (isCVoid)
			writeStatic(writer, ", (struct void_) {})");
	});
}

void writeTailRecur(Alloc, TempAlloc)(
	ref Writer!Alloc writer,
	ref TempAlloc tempAlloc,
	immutable size_t indent,
	ref FunBodyCtx ctx,
	ref immutable LowExprKind.TailRecur a,
) {
	immutable LowParam[] params = regularParams(fullIndexDictGet(ctx.ctx.program.allFuns, ctx.curFun));
	immutable WriteExprResult[] args = writeExprsTempOrInline(writer, tempAlloc, indent, ctx, a.args);
	zip!(LowParam, LowExpr, WriteExprResult)(
		params,
		a.args,
		args,
		(ref immutable LowParam param, ref immutable LowExpr argExpr, ref immutable WriteExprResult arg) {
			writeNewline(writer, indent);
			writeLowParamName(writer, param);
			writeStatic(writer, " = ");
			writeTempOrInline(writer, tempAlloc, ctx, argExpr, arg);
			writeChar(writer, ';');
		});
	writeNewline(writer, indent);
	writeStatic(writer, "goto top;");
}

void writeConvertToUnion(Alloc)(
	ref Writer!Alloc writer,
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

void writeFunPtr(Alloc)(ref Writer!Alloc writer, ref immutable Ctx ctx, ref immutable LowExprKind.FunPtr a) {
	writeLowFunMangledName(writer, ctx, a.fun, fullIndexDictGet(ctx.program.allFuns, a.fun));
}

void writeLocalRef(Alloc)(ref Writer!Alloc writer, ref immutable LowLocal a) {
	matchLowLocalSource!void(
		a.source,
		(immutable Ptr!ConcreteLocal it) {
			matchConcreteLocalSource!void(
				it.source,
				(ref immutable ConcreteLocalSource.Arr) {
					writeStatic(writer, "_arr");
				},
				(immutable Ptr!Local it) {
					writeMangledName(writer, it.name);
				},
				(ref immutable ConcreteLocalSource.Matched) {
					writeStatic(writer, "_matched");
				});
			writeNat(writer, it.index);
		},
		(ref immutable LowLocalSource.Generated it) {
			writeMangledName(writer, it.name);
			writeNat(writer, it.index);
		});
}

void writeParamRef(Alloc)(ref Writer!Alloc writer, ref const FunBodyCtx ctx, ref immutable LowExprKind.ParamRef a) {
	writeLowParamName(writer, at(fullIndexDictGet(ctx.ctx.program.allFuns, ctx.curFun).params, a.index.index));
}

immutable(WriteExprResult) writeMatchUnion(Alloc, TempAlloc)(
	ref Writer!Alloc writer,
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
	foreach (immutable size_t caseIndex; 0 .. size(a.cases)) {
		immutable LowExprKind.MatchUnion.Case case_ = at(a.cases, caseIndex);
		writeNewline(writer, indent + 1);
		writeStatic(writer, "case ");
		writeNat(writer, caseIndex);
		writeStatic(writer, ": {");
		if (has(case_.local)) {
			writeDeclareLocal(writer, indent + 2, ctx, force(case_.local));
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
immutable(WriteExprResult) writeSwitch(Alloc, TempAlloc)(
	ref Writer!Alloc writer,
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
	foreach (immutable size_t caseIndex; 0 .. size(cases)) {
		writeNewline(writer, indent + 1);
		writeStatic(writer, "case ");
		if (isSignedIntegral(value.type)) {
			writeInt(writer, getValue(caseIndex).asSigned());
		} else {
			writeNat(writer, getValue(caseIndex).asUnsigned());
		}
		writeStatic(writer, ": {");
		drop(writeExpr(writer, tempAlloc, indent + 2, ctx, nested.writeKind, at(cases, caseIndex)));
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

void writeRecordFieldRef(Alloc)(
	ref Writer!Alloc writer,
	ref const FunBodyCtx ctx,
	immutable bool targetIsPointer,
	immutable LowType.Record record,
	immutable ubyte fieldIndex,
) {
	writeStatic(writer, targetIsPointer ? "->" : ".");
	writeMangledName(writer, name(at(fullIndexDictGet(ctx.ctx.program.allRecords, record).fields, fieldIndex)));
}

// For some reason, providing a type for a record makes it non-constant.
// But that is mandatory at the outermost level.
enum ConstantRefPos {
	outer,
	inner,
}

void writeConstantRef(Alloc)(
	ref Writer!Alloc writer,
	ref immutable Ctx ctx,
	immutable ConstantRefPos pos,
	ref immutable LowType type,
	ref immutable Constant a,
) {
	matchConstant!void(
		a,
		(ref immutable Constant.ArrConstant it) {
			if (pos == ConstantRefPos.outer) writeCastToType(writer, ctx, type);
			immutable size_t size = size(at(at(ctx.program.allConstants.arrs, it.typeIndex).constants, it.index));
			writeChar(writer, '{');
			writeNat(writer, size);
			writeStatic(writer, ", ");
			if (size == 0)
				writeStatic(writer, "NULL");
			else
				writeConstantArrStorageName(writer, ctx, asRecordType(type), it.index);
			writeChar(writer, '}');
		},
		(immutable Constant.BoolConstant it) {
			writeChar(writer, it.value ? '1' : '0');
		},
		(immutable double it) {
			writeFloatLiteral(writer, it);
		},
		(immutable Constant.Integral it) {
			if (isSignedIntegral(asPrimitive(type))) {
				immutable long i = i64OfU64Bits(it.value);
				if (i == long.min)
					// Can't write this as a literal since the '-' and rest are parsed separately,
					// and the abs of the minimum integer is out of range.
					writeStatic(writer, "INT64_MIN");
				else
					writeInt(writer, i);
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
			writeConstantPointerStorageName(writer, ctx, asPtrGc(type).pointee, it.index);
		},
		(ref immutable Constant.Record it) {
			immutable LowField[] fields = fullIndexDictGet(ctx.program.allRecords, asRecordType(type)).fields;
			verify(sizeEq(fields, it.args));
			if (pos == ConstantRefPos.outer)
				writeCastToType(writer, ctx, type);
			writeChar(writer, '{');
			writeWithCommas(writer, size(it.args), (immutable size_t i) {
				writeConstantRef(writer, ctx, ConstantRefPos.inner, at(fields, i).type, at(it.args, i));
			});
			writeChar(writer, '}');
		},
		(ref immutable Constant.Union it) {
			immutable LowType memberType = at(
				fullIndexDictGet(ctx.program.allUnions, asUnionType(type)).members,
				it.memberIndex);
			writeConvertToUnion(writer, ctx, pos, type, it.memberIndex, () {
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

immutable(WriteExprResult) writeSpecialUnary(Alloc, TempAlloc)(
	ref Writer!Alloc writer,
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

void writeLValue(Alloc)(ref Writer!Alloc writer, ref const FunBodyCtx ctx, ref immutable LowExpr expr) {
	matchLowExprKind(
		expr.kind,
		(ref immutable LowExprKind.Call) => unreachable!void(),
		(ref immutable LowExprKind.CreateRecord) => unreachable!void(),
		(ref immutable LowExprKind.ConvertToUnion) => unreachable!void(),
		(ref immutable LowExprKind.FunPtr) => unreachable!void(),
		(ref immutable LowExprKind.Let) => unreachable!void(),
		(ref immutable LowExprKind.LocalRef it) {
			writeLocalRef(writer, it.local);
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
		(ref immutable LowExprKind.Seq) => todo!void("!"),
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
		(ref immutable LowExprKind.SpecialTrinary) => unreachable!void(),
		(ref immutable LowExprKind.SpecialNAry) => unreachable!void(),
		(ref immutable LowExprKind.Switch0ToN) => unreachable!void(),
		(ref immutable LowExprKind.SwitchWithValues) => unreachable!void(),
		(ref immutable LowExprKind.TailRecur) => unreachable!void(),
		(ref immutable LowExprKind.Zeroed) => unreachable!void());
}

void writeZeroedValue(Alloc)(ref Writer!Alloc writer, ref immutable Ctx ctx, ref immutable LowType type) {
	return matchLowTypeCombinePtr!void(
		type,
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
		(immutable Ptr!LowType) {
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
		});
}

immutable(WriteExprResult) writeSpecialBinary(Alloc, TempAlloc)(
	ref Writer!Alloc writer,
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
				verify(size(args) == 2);
				writeChar(writer, '(');
				writeTempOrInline(writer, tempAlloc, ctx, it.left, at(args, 0));
				writeChar(writer, ' ');
				writeStatic(writer, op);
				writeChar(writer, ' ');
				writeTempOrInline(writer, tempAlloc, ctx, it.right, at(args, 1));
				writeChar(writer, ')');
			});
	}

	final switch (it.kind) {
		case LowExprKind.SpecialBinary.Kind.addFloat32:
		case LowExprKind.SpecialBinary.Kind.addFloat64:
		case LowExprKind.SpecialBinary.Kind.addPtr:
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
		case LowExprKind.SpecialBinary.Kind.subPtrNat:
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
			break;
	}
}

enum LogicalOperator { and, or }

struct WriteExprResultAndNested {
	immutable WriteExprResult result;
	immutable WriteKind writeKind;
}

// If we need to make a temporary, have to do that in an outer scope and write to it in an inner scope
immutable(WriteExprResultAndNested) getNestedWriteKind(Alloc)(
	ref Writer!Alloc writer,
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

immutable(WriteExprResult) writeLogicalOperator(Alloc, TempAlloc)(
	ref Writer!Alloc writer,
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

immutable(WriteExprResult) writeSpecialTrinary(Alloc, TempAlloc)(
	ref Writer!Alloc writer,
	ref TempAlloc tempAlloc,
	immutable size_t indent,
	ref FunBodyCtx ctx,
	immutable WriteKind writeKind,
	ref immutable LowType type,
	ref immutable LowExprKind.SpecialTrinary a,
) {
	immutable(Temp) arg0() {
		// TODO: writeExprTempOrInline
		return writeExprTemp(writer, tempAlloc, indent, ctx, a.p0);
	}
	immutable(Temp) arg1() {
		// TODO: writeExprTempOrInline
		return writeExprTemp(writer, tempAlloc, indent, ctx, a.p1);
	}
	immutable(Temp) arg2() {
		// TODO: writeExprTempOrInline
		return writeExprTemp(writer, tempAlloc, indent, ctx, a.p2);
	}

	final switch (a.kind) {
		case LowExprKind.SpecialTrinary.Kind.if_:
			immutable Temp temp0 = arg0();
			immutable WriteExprResultAndNested nested = getNestedWriteKind(writer, indent, ctx, type, writeKind);
			writeNewline(writer, indent);
			writeStatic(writer, "if (");
			writeTempRef(writer, temp0);
			writeStatic(writer, ") {");
			drop(writeExpr(writer, tempAlloc, indent + 1, ctx, nested.writeKind, a.p1));
			writeNewline(writer, indent);
			writeStatic(writer, "} else {");
			drop(writeExpr(writer, tempAlloc, indent + 1, ctx, nested.writeKind, a.p2));
			writeNewline(writer, indent);
			writeChar(writer, '}');
			return nested.result;
		case LowExprKind.SpecialTrinary.Kind.compareExchangeStrongBool:
			immutable Temp temp0 = arg0();
			immutable Temp temp1 = arg1();
			immutable Temp temp2 = arg2();
			return writeNonInlineable(writer, indent, ctx, writeKind, type, () {
				writeStatic(writer, "atomic_compare_exchange_strong(");
				writeTempRef(writer, temp0);
				writeStatic(writer, ", ");
				writeTempRef(writer, temp1);
				writeStatic(writer, ", ");
				writeTempRef(writer, temp2);
				writeChar(writer, ')');
			});
	}
}

immutable(WriteExprResult) writeSpecialNAry(Alloc, TempAlloc)(
	ref Writer!Alloc writer,
	ref TempAlloc tempAlloc,
	immutable size_t indent,
	ref FunBodyCtx ctx,
	ref immutable WriteKind writeKind,
	ref immutable LowType type,
	ref immutable LowExprKind.SpecialNAry it,
) {
	final switch (it.kind) {
		case LowExprKind.SpecialNAry.Kind.callFunPtr:
			immutable WriteExprResult fn = writeExprTempOrInline(writer, tempAlloc, indent, ctx, first(it.args));
			immutable WriteExprResult[] args = writeExprsTempOrInline(writer, tempAlloc, indent, ctx, tail(it.args));
			return writeNonInlineable(writer, indent, ctx, writeKind, type, () {
				writeTempOrInline(writer, tempAlloc, ctx, first(it.args), fn);
				writeChar(writer, '(');
				writeTempOrInlines(writer, tempAlloc, ctx, tail(it.args), args);
				writeChar(writer, ')');
			});
	}
}

void writePrimitiveType(Alloc)(ref Writer!Alloc writer, immutable PrimitiveType a) {
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

void writeMangledName(Alloc)(ref Writer!Alloc writer, immutable Sym name) {
	immutable Opt!Operator operator = operatorForSym(name);
	if (has(operator)) {
		writeStatic(writer, () {
			final switch (force(operator)) {
				case Operator.concatEquals:
					return "_concatEquals";
				case Operator.or2:
					return "_or2";
				case Operator.and2:
					return "_and2";
				case Operator.equal:
					return "_equal";
				case Operator.notEqual:
					return "_notEqual";
				case Operator.less:
					return "_less";
				case Operator.lessOrEqual:
					return "_lessOrEqual";
				case Operator.greater:
					return "_greater";
				case Operator.greaterOrEqual:
					return "_greaterOrEqual";
				case Operator.compare:
					return "_compare";
				case Operator.or1:
					return "_or";
				case Operator.xor1:
					return "_xor";
				case Operator.and1:
					return "_and";
				case Operator.arrow:
					return "_arrow";
				case Operator.tilde:
					return "_tilde";
				case Operator.shiftLeft:
					return "_shiftLeft";
				case Operator.shiftRight:
					return "_shiftRight";
				case Operator.plus:
					return "_plus";
				case Operator.minus:
					return "_minus";
				case Operator.times:
					return "_times";
				case Operator.divide:
					return "_divide";
				case Operator.exponent:
					return "_exponent";
				case Operator.not:
					return "_not";
			}
		}());
	} else {
		if (conflictsWithCName(name))
			writeChar(writer, '_');
		eachCharInSym(name, (immutable char c) {
			switch (c) {
				case '-':
					writeChar(writer, '_');
					break;
				case '?':
					writeStatic(writer, "__q");
					break;
				case '!':
					writeStatic(writer, "__e");
					break;
				default:
					writeChar(writer, c);
					break;
			}
		});
	}
}

immutable(bool) conflictsWithCName(immutable Sym name) {
	switch (name.value) {
		case shortSymAlphaLiteralValue("atomic-bool"): // avoid conflicting with c's "atomic_bool" type
		case shortSymAlphaLiteralValue("break"):
		case shortSymAlphaLiteralValue("continue"):
		case shortSymAlphaLiteralValue("default"):
		case shortSymAlphaLiteralValue("double"):
		case shortSymAlphaLiteralValue("float"):
		case shortSymAlphaLiteralValue("for"):
		case shortSymAlphaLiteralValue("int"):
		case shortSymAlphaLiteralValue("void"):
		case shortSymAlphaLiteralValue("while"):
			return true;
		default:
			return false;
	}
}
