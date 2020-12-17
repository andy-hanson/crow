module backend.writeToC;

@safe @nogc pure nothrow:

import interpret.debugging : writeFunName, writeFunSig;
import interpret.typeLayout : layOutTypes, sizeOfType, TypeLayout;
import lower.lowExprHelpers : boolType, voidType;
import model.concreteModel :
	asExtern,
	body_,
	ConcreteFun,
	ConcreteFunSource,
	ConcreteLocal,
	ConcreteLocalSource,
	ConcreteParam,
	ConcreteParamSource,
	ConcreteStruct,
	ConcreteStructSource,
	isExtern,
	matchConcreteFunSource,
	matchConcreteParamSource,
	matchConcreteLocalSource,
	matchConcreteStructSource;
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
import model.model : FunInst, Local, name, Param;
import util.bools : Bool, False, True;
import util.collection.arr : Arr, at, empty, first, range, setAt, size, sizeEq;
import util.collection.arrUtil : every, fillArr_mut, map, tail, zip;
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
import util.collection.str : Str;
import util.opt : force, has, none, Opt, some;
import util.ptr : comparePtr, Ptr, ptrTrustMe, ptrTrustMe_mut;
import util.sym :
	compareSym,
	eachCharInSym,
	isSymOperator,
	shortSymAlphaLiteral,
	shortSymAlphaLiteralValue,
	Sym,
	symEq;
import util.types : i64OfU64Bits, u8;
import util.util : drop, todo, unreachable, verify;
import util.writer :
	finishWriter,
	writeChar,
	writeEscapedChar_inner,
	writeInt,
	writeNat,
	writeNewline,
	Writer,
	writeStatic,
	writeStr,
	writeWithCommas;

immutable(Str) writeToC(Alloc, TempAlloc)(
	ref Alloc alloc,
	ref TempAlloc tempAlloc,
	ref immutable LowProgram program,
) {
	Writer!Alloc writer = Writer!Alloc(ptrTrustMe_mut(alloc));

	writeStatic(writer, "#include <assert.h>\n");
	writeStatic(writer, "#include <errno.h>\n");
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
	foreach (ref immutable ArrTypeAndConstantsLow a; range(allConstants.arrs)) {
		foreach (immutable size_t i; 0..size(a.constants)) {
			declareConstantArrStorage(writer, ctx, a.arrType, a.elementType, i, size(at(a.constants, i)));
			writeStatic(writer, ";\n");
		}
	}

	foreach (ref immutable PointerTypeAndConstantsLow a; range(allConstants.pointers)) {
		foreach (immutable size_t i; 0..size(a.constants)) {
			declareConstantPointerStorage(writer, ctx, a.pointeeType, i);
			writeStatic(writer, ";\n");
		}
	}

	foreach (ref immutable ArrTypeAndConstantsLow a; range(allConstants.arrs)) {
		foreach (immutable size_t i; 0..size(a.constants)) {
			immutable Arr!Constant elements = at(a.constants, i);
			declareConstantArrStorage(writer, ctx, a.arrType, a.elementType, i, size(elements));
			writeStatic(writer, " = ");
			if (isChar(a.elementType)) {
				writeChar(writer, '"');
				foreach (immutable Constant element; range(elements))
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

	foreach (ref immutable PointerTypeAndConstantsLow a; range(allConstants.pointers)) {
		foreach (immutable size_t i; 0..size(a.constants)) {
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
					(ref immutable ConcreteFunSource.Lambda) {});
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
	immutable Bool hasTailRecur;
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
					writeMangledName(writer, p.name);
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
	foreach (ref immutable LowField field; range(a.fields)) {
		writeStatic(writer, "\n\t");
		writeType(writer, ctx, field.type);
		writeChar(writer, ' ');
		writeMangledName(writer, name(field));
		writeChar(writer, ';');
	}
	writeStructEnd(writer);
}

void writeUnion(Alloc)(ref Writer!Alloc writer, ref immutable Ctx ctx, ref immutable LowUnion a) {
	writeStructHead(writer, ctx, a.source);
	writeStatic(writer, "\n\tuint64_t kind;");
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
	return matchLowTypeCombinePtr!(immutable Bool)(
		t,
		(immutable LowType.ExternPtr) =>
			// Declared all up front
			True,
		(immutable LowType.FunPtr it) =>
			immutable Bool(at(states.funPtrStates, it.index)),
		(immutable PrimitiveType) =>
			True,
		(immutable Ptr!LowType pointee) =>
			canReferenceTypeAsPointee(ctx, states, pointee),
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
	return matchLowTypeCombinePtr!(immutable Bool)(
		t,
		(immutable LowType.ExternPtr) =>
			// Declared all up front
			True,
		(immutable LowType.FunPtr it) =>
			immutable Bool(at(states.funPtrStates, it.index)),
		(immutable PrimitiveType) =>
			True,
		(immutable Ptr!LowType pointee) =>
			canReferenceTypeAsPointee(ctx, states, pointee),
		(immutable LowType.Record it) =>
			immutable Bool(at(states.recordStates, it.index) != StructState.none),
		(immutable LowType.Union it) =>
			immutable Bool(at(states.unionStates, it.index) != StructState.none));
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
	immutable size_t size,
) {
	writeStatic(writer, "_Static_assert(sizeof(");
	writeType(writer, ctx, type);
	writeStatic(writer, ") == ");
	writeNat(writer, size);
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
				writeStr(writer, asExtern(body_(source)).externName);
			else {
				writeMangledName(writer, name(it));
				maybeWriteIndexSuffix(writer, getAt(ctx.mangledNames.funToNameIndex, source));
			}
		},
		(ref immutable ConcreteFunSource.Lambda it) {
			writeFunMangledName(writer, ctx, it.containingFun);
			writeStatic(writer, "__lambda");
			writeNat(writer, it.index);
		});
}

void maybeWriteIndexSuffix(Alloc)(ref Writer!Alloc writer, immutable Opt!size_t index) {
	if (has(index)) {
		writeChar(writer, '_');
		writeNat(writer, force(index));
	}
}

immutable(Bool) tryWriteFunPtrDeclaration(Alloc)(
	ref Writer!Alloc writer,
	ref immutable Ctx ctx,
	ref const StructStates structStates,
	immutable LowType.FunPtr funPtrIndex,
) {
	immutable LowFunPtrType funPtr = fullIndexDictGet(ctx.program.allFunPtrTypes, funPtrIndex);
	immutable Bool canDeclare = immutable Bool(
		canReferenceTypeAsPointee(ctx, structStates, funPtr.returnType) &&
		every!LowType(funPtr.paramTypes, (ref immutable LowType it) =>
			canReferenceTypeAsPointee(ctx, structStates, it)));
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
	if (every(record.fields, (ref immutable LowField f) => canReferenceTypeAsValue(ctx, structStates, f.type))) {
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
	if (every(union_.members, (ref immutable LowType t) => canReferenceTypeAsValue(ctx, structStates, t))) {
		writeUnion(writer, ctx, union_);
		return StructState.defined;
	} else {
		declareStruct(writer, ctx, union_.source);
		return StructState.declared;
	}
}

void writeStructs(Alloc, WriterAlloc)(ref Alloc alloc, ref Writer!WriterAlloc writer, ref immutable Ctx ctx) {
	immutable TypeLayout typeLayout = layOutTypes(alloc, ctx.program); // For debugging...

	writeStatic(writer, "\nstruct void_ {};\n");

	// Write extern-ptr types first
	fullIndexDictEachValue!(LowType.ExternPtr, LowExternPtrType)(
		ctx.program.allExternPtrTypes,
		(ref immutable LowExternPtrType it) {
			declareStruct(writer, ctx, it.source);
		});

	StructStates structStates = StructStates(
		fillArr_mut!Bool(alloc, fullIndexDictSize(ctx.program.allFunPtrTypes), (immutable size_t) =>
			Bool(false)),
		fillArr_mut!StructState(alloc, fullIndexDictSize(ctx.program.allRecords), (immutable size_t) =>
			StructState.none),
		fillArr_mut!StructState(alloc, fullIndexDictSize(ctx.program.allUnions), (immutable size_t) =>
			StructState.none));
	for (;;) {
		Bool madeProgress = False;
		Bool someIncomplete = False;
		fullIndexDictEachKey!(LowType.FunPtr, LowFunPtrType)(
			ctx.program.allFunPtrTypes,
			(immutable LowType.FunPtr funPtrIndex) {
				immutable Bool curState = at(structStates.funPtrStates, funPtrIndex.index);
				if (!curState) {
					if (tryWriteFunPtrDeclaration(writer, ctx, structStates, funPtrIndex)) {
						setAt(structStates.funPtrStates, funPtrIndex.index, True);
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
		staticAssertStructSize(writer, ctx, t, sizeOfType(typeLayout, t).raw());
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
			foreach (ref immutable LowParam p; range(tail(fun.params))) {
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

void writeTempRefs(Alloc)(ref Writer!Alloc writer, ref immutable Arr!Temp args) {
	writeWithCommas!Temp(writer, args, (ref immutable Temp it) {
		writeTempRef(writer, it);
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

struct WriteResult {
	immutable Opt!Temp temp;
}

struct WriteKind {
	@safe @nogc pure nothrow:

	struct MakeTemp {}
	struct Return {}
	struct UseTemp {
		immutable Temp temp;
	}
	struct Void {}

	@trusted immutable this(immutable Ptr!LowLocal a) { kind = Kind.local; local =  a; }
	immutable this(immutable MakeTemp a) { kind = Kind.makeTemp; makeTemp = a; }
	immutable this(immutable Return a) { kind = Kind.return_; return_ = a; }
	immutable this(immutable UseTemp a) { kind = Kind.useTemp; useTemp = a; }
	immutable this(immutable Void a) { kind = Kind.void_; void_ = a; }

	private:
	enum Kind {
		local,
		makeTemp,
		return_,
		useTemp,
		void_,
	}
	immutable Kind kind;
	union {
		immutable Ptr!LowLocal local;
		immutable MakeTemp makeTemp;
		immutable Return return_;
		immutable UseTemp useTemp;
		immutable Void void_;
	}
}

immutable(Bool) isMakeTemp(ref immutable WriteKind a) {
	return immutable Bool(a.kind == WriteKind.Kind.makeTemp);
}

immutable(Bool) isReturn(ref immutable WriteKind a) {
	return immutable Bool(a.kind == WriteKind.Kind.return_);
}

immutable(Bool) isVoid(ref immutable WriteKind a) {
	return immutable Bool(a.kind == WriteKind.Kind.void_);
}

@trusted T matchWriteKind(T)(
	ref immutable WriteKind a,
	scope T delegate(immutable Ptr!LowLocal) @safe @nogc pure nothrow cbLocal,
	scope T delegate(ref immutable WriteKind.MakeTemp) @safe @nogc pure nothrow cbMakeTemp,
	scope T delegate(ref immutable WriteKind.Return) @safe @nogc pure nothrow cbReturn,
	scope T delegate(ref immutable WriteKind.UseTemp) @safe @nogc pure nothrow cbUseTemp,
	scope T delegate(ref immutable WriteKind.Void) @safe @nogc pure nothrow cbVoid,
) {
	final switch (a.kind) {
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

immutable(Arr!Temp) writeExprsTemp(Alloc, TempAlloc)(
	ref Writer!Alloc writer,
	ref TempAlloc tempAlloc,
	immutable size_t indent,
	ref FunBodyCtx ctx,
	immutable Arr!LowExpr args,
) {
	return map(tempAlloc, args, (ref immutable LowExpr arg) =>
		writeExprTemp(writer, tempAlloc, indent, ctx, arg));
}

immutable(Temp) writeExprTemp(Alloc, TempAlloc)(
	ref Writer!Alloc writer,
	ref TempAlloc tempAlloc,
	immutable size_t indent,
	ref FunBodyCtx ctx,
	ref immutable LowExpr expr,
) {
	immutable WriteKind writeKind = immutable WriteKind(immutable WriteKind.MakeTemp());
	immutable WriteResult res = writeExpr!(Alloc, TempAlloc)(writer, tempAlloc, indent, ctx, writeKind, expr);
	return force(res.temp);
}

immutable(WriteResult) writeExpr(Alloc, TempAlloc)(
	ref Writer!Alloc writer,
	ref TempAlloc tempAlloc,
	immutable size_t indent,
	ref FunBodyCtx ctx,
	ref immutable WriteKind writeKind,
	ref immutable LowExpr expr,
) {
	immutable LowType type = expr.type;
	immutable(WriteResult) return_(scope void delegate() @safe @nogc pure nothrow cb) {
		return writeReturn(writer, indent, ctx, writeKind, type, cb);
	}
	return matchLowExprKind!(immutable WriteResult)(
		expr.kind,
		(ref immutable LowExprKind.Call it) =>
			writeCallExpr(writer, tempAlloc, indent, ctx, writeKind, type, it),
		(ref immutable LowExprKind.CreateRecord it) {
			immutable Arr!Temp args = writeExprsTemp(writer, tempAlloc, indent, ctx, it.args);
			return return_(() {
				writeCastToType(writer, ctx.ctx, type);
				writeChar(writer, '{');
				writeTempRefs(writer, args);
				writeChar(writer, '}');
			});
		},
		(ref immutable LowExprKind.ConvertToUnion it) {
			immutable Temp arg = writeExprTemp(writer, tempAlloc, indent, ctx, it.arg);
			return return_(() {
				writeConvertToUnion(writer, ctx.ctx, ConstantRefPos.outer, type, it.memberIndex, () {
					writeTempRef(writer, arg);
				});
			});
		},
		(ref immutable LowExprKind.FunPtr it) {
			return return_(() { writeFunPtr(writer, ctx.ctx, it); });
		},
		(ref immutable LowExprKind.Let it) {
			writeDeclareLocal(writer, indent, ctx, it.local);
			writeChar(writer, ';');
			immutable WriteKind localWriteKind = immutable WriteKind(it.local);
			drop(writeExpr(writer, tempAlloc, indent, ctx, localWriteKind, it.value));
			writeNewline(writer, indent);
			return writeExpr(writer, tempAlloc, indent, ctx, writeKind, it.then);
		},
		(ref immutable LowExprKind.LocalRef it) =>
			return_(() {
				writeLocalRef(writer, it.local);
			}),
		(ref immutable LowExprKind.Match it) =>
			writeMatch(writer, tempAlloc, indent, ctx, writeKind, type, it),
		(ref immutable LowExprKind.ParamRef it) =>
			return_(() {
				writeParamRef(writer, ctx, it);
			}),
		(ref immutable LowExprKind.PtrCast it) {
			immutable Temp temp = writeExprTemp(writer, tempAlloc, indent, ctx, it.target);
			return return_(() {
				writeCastToType(writer, ctx.ctx, type);
				writeTempRef(writer, temp);
			});
		},
		(ref immutable LowExprKind.RecordFieldGet it) {
			immutable Temp recordValue = writeExprTemp(writer, tempAlloc, indent, ctx, it.target);
			return return_(() {
				writeTempRef(writer, recordValue);
				writeRecordFieldRef!Alloc(writer, ctx, it.targetIsPointer, it.record, it.fieldIndex);
			});
		},
		(ref immutable LowExprKind.RecordFieldSet it) {
			immutable Temp recordValue = writeExprTemp(writer, tempAlloc, indent, ctx, it.target);
			immutable Temp fieldValue = writeExprTemp(writer, tempAlloc, indent, ctx, it.value);
			return writeReturnVoid(writer, indent, ctx, writeKind, () {
				writeTempRef(writer, recordValue);
				writeRecordFieldRef(writer, ctx, it.targetIsPointer, it.record, it.fieldIndex);
				writeStatic(writer, " = ");
				writeTempRef(writer, fieldValue);
			});
		},
		(ref immutable LowExprKind.Seq it) {
			immutable WriteKind writeKindVoid = immutable WriteKind(immutable WriteKind.Void());
			drop(writeExpr(writer, tempAlloc, indent, ctx, writeKindVoid, it.first));
			return writeExpr(writer, tempAlloc, indent, ctx, writeKind, it.then);
		},
		(ref immutable LowExprKind.SizeOf it) =>
			return_(() {
				writeStatic(writer, "sizeof(");
				writeType(writer, ctx.ctx, it.type);
				writeChar(writer, ')');
			}),
		(ref immutable Constant it) =>
			return_(() {
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
		(ref immutable LowExprKind.Switch it) =>
			writeSwitch(writer, tempAlloc, indent, ctx, writeKind, type, it),
		(ref immutable LowExprKind.TailRecur it) {
			verify(isReturn(writeKind));
			writeTailRecur(writer, tempAlloc, indent, ctx, it);
			return immutable WriteResult(none!Temp);
		});
}

//TODO:RENAME
immutable(WriteResult) writeReturn(Alloc)(
	ref Writer!Alloc writer,
	immutable size_t indent,
	ref FunBodyCtx ctx,
	ref immutable WriteKind writeKind,
	ref immutable LowType type,
	scope void delegate() @safe @nogc pure nothrow cb,
) {
	writeNewline(writer, indent);
	immutable WriteResult res = matchWriteKind!(immutable WriteResult)(
		writeKind,
		(immutable Ptr!LowLocal it) {
			writeLocalRef(writer, it);
			writeStatic(writer, " = ");
			return immutable WriteResult(none!Temp);
		},
		(ref immutable MakeTemp) {
			immutable Temp temp = getNextTemp(ctx);
			writeTempDeclare!Alloc(writer, ctx, type, temp);
			writeStatic(writer, " = ");
			return immutable WriteResult(some(temp));
		},
		(ref immutable WriteKind.Return) {
			writeStatic(writer, "return ");
			return immutable WriteResult(none!Temp);
		},
		(ref immutable WriteKind.UseTemp it) {
			writeTempRef(writer, it.temp);
			writeStatic(writer, " = ");
			return immutable WriteResult(none!Temp);
		},
		(ref immutable WriteKind.Void) =>
			immutable WriteResult(none!Temp));
	cb();
	writeChar(writer, ';');
	return res;
}

immutable(WriteResult) writeReturnVoid(Alloc)(
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
		return immutable WriteResult(none!Temp);
	} else
		return writeReturn(writer, indent, ctx, writeKind, voidType, () {
			writeChar(writer, '(');
			cb();
			writeStatic(writer, ", (struct void_) {})");
		});
}

immutable(WriteResult) writeCallExpr(Alloc, TempAlloc)(
	ref Writer!Alloc writer,
	ref TempAlloc tempAlloc,
	immutable size_t indent,
	ref FunBodyCtx ctx,
	ref immutable WriteKind writeKind,
	ref immutable LowType type,
	ref immutable LowExprKind.Call a,
) {
	immutable Arr!Temp args = writeExprsTemp(writer, tempAlloc, indent, ctx, a.args);
	return writeReturn(writer, indent, ctx, writeKind, type, () {
		immutable Ptr!LowFun called = fullIndexDictGetPtr(ctx.ctx.program.allFuns, a.called);
		immutable Bool isCVoid = isExtern(called.body_) && isVoid(called.returnType);
		if (isCVoid)
			//TODO: this is unnecessary if writeKind is not 'expr'
			writeChar(writer, '(');
		writeLowFunMangledName(writer, ctx.ctx, a.called, called);
		if (!isGlobal(called.body_)) {
			writeChar(writer, '(');
			writeTempRefs(writer, args);
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
	immutable Arr!LowParam params = regularParams(fullIndexDictGet(ctx.ctx.program.allFuns, ctx.curFun));
	immutable Arr!Temp args = writeExprsTemp(writer, tempAlloc, indent, ctx, a.args);
	zip!(LowParam, Temp)(params, args, (ref immutable LowParam param, ref immutable Temp arg) {
		writeNewline(writer, indent);
		writeLowParamName(writer, param);
		writeStatic(writer, " = ");
		writeTempRef(writer, arg);
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

immutable(WriteResult) writeMatch(Alloc, TempAlloc)(
	ref Writer!Alloc writer,
	ref TempAlloc tempAlloc,
	immutable size_t indent,
	ref FunBodyCtx ctx,
	ref immutable WriteKind writeKind,
	ref immutable LowType type,
	ref immutable LowExprKind.Match a,
) {
	immutable Temp matchedValue = writeExprTemp(writer, tempAlloc, indent, ctx, a.matchedValue);
	immutable WriteResultAndNested nested = getNestedWriteKind(writer, indent, ctx, type, writeKind);
	writeNewline(writer, indent);
	writeStatic(writer, "switch (");
	writeTempRef(writer, matchedValue);
	writeStatic(writer, ".kind) {");
	foreach (immutable size_t caseIndex; 0..size(a.cases)) {
		immutable LowExprKind.Match.Case case_ = at(a.cases, caseIndex);
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
	if (isReturn(nested.writeKind))
		writeStatic(writer, "return ");
	writeHardFail(writer, ctx.ctx, type);
	writeChar(writer, ';');
	writeNewline(writer, indent);
	writeChar(writer, '}');
	return nested.result;
}

//TODO: share code with writeMatch
immutable(WriteResult) writeSwitch(Alloc, TempAlloc)(
	ref Writer!Alloc writer,
	ref TempAlloc tempAlloc,
	immutable size_t indent,
	ref FunBodyCtx ctx,
	immutable WriteKind writeKind,
	ref immutable LowType type,
	ref immutable LowExprKind.Switch a,
) {
	immutable Temp value = writeExprTemp(writer, tempAlloc, indent, ctx, a.value);
	immutable WriteResultAndNested nested = getNestedWriteKind(writer, indent, ctx, type, writeKind);
	writeStatic(writer, "switch (");
	writeTempRef(writer, value);
	writeStatic(writer, ") {");
	foreach (immutable size_t caseIndex; 0..size(a.cases)) {
		immutable LowExpr case_ = at(a.cases, caseIndex);
		writeNewline(writer, indent + 1);
		writeStatic(writer, "case ");
		writeNat(writer, caseIndex);
		writeChar(writer, ':');
		writeNewline(writer, indent + 2);
		drop(writeExpr(writer, tempAlloc, indent + 2, ctx, nested.writeKind, case_));
		if (!isReturn(nested.writeKind)) {
			writeNewline(writer, indent + 2);
			writeStatic(writer, "break;");
		}
	}
	writeNewline(writer, indent + 1);
	writeStatic(writer, "default:");
	writeNewline(writer, indent + 2);
	if (isReturn(nested.writeKind))
		writeStatic(writer, "return ");
	writeHardFail(writer, ctx.ctx, type);
	writeChar(writer, ';');
	writeNewline(writer, indent);
	writeChar(writer, '}');
	return nested.result;
}

void writeRecordFieldRef(Alloc)(
	ref Writer!Alloc writer,
	ref const FunBodyCtx ctx,
	immutable Bool targetIsPointer,
	immutable LowType.Record record,
	immutable u8 fieldIndex,
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
			todo!void("write float");
		},
		(immutable Constant.Integral it) {
			if (isSignedIntegral(asPrimitive(type)))
				writeInt(writer, i64OfU64Bits(it.value));
			else {
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
			immutable Arr!LowField fields = fullIndexDictGet(ctx.program.allRecords, asRecordType(type)).fields;
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

immutable(Bool) isSignedIntegral(immutable PrimitiveType a) {
	switch (a) {
		case PrimitiveType.int8:
		case PrimitiveType.int16:
		case PrimitiveType.int32:
		case PrimitiveType.int64:
			return True;
		case PrimitiveType.bool_:
		case PrimitiveType.char_:
		case PrimitiveType.nat8:
		case PrimitiveType.nat16:
		case PrimitiveType.nat32:
		case PrimitiveType.nat64:
			return False;
		default:
			return unreachable!(immutable Bool);
	}
}

immutable(WriteResult) writeSpecialUnary(Alloc, TempAlloc)(
	ref Writer!Alloc writer,
	ref TempAlloc tempAlloc,
	immutable size_t indent,
	ref FunBodyCtx ctx,
	immutable WriteKind writeKind,
	ref immutable LowType type,
	ref immutable LowExprKind.SpecialUnary a,
) {
	immutable(WriteResult) prefix(string prefix) {
		immutable Temp temp = writeExprTemp(writer, tempAlloc, indent, ctx, a.arg);
		return writeReturn(writer, indent, ctx, writeKind, type, () {
			writeStatic(writer, prefix);
			writeTempRef(writer, temp);
		});
	}
	final switch (a.kind) {
		case LowExprKind.SpecialUnary.Kind.asAnyPtr:
			return prefix("(uint8_t*) ");
		case LowExprKind.SpecialUnary.Kind.asRef:
		case LowExprKind.SpecialUnary.Kind.toNatFromPtr:
		case LowExprKind.SpecialUnary.Kind.toFloat64FromInt64:
		case LowExprKind.SpecialUnary.Kind.toFloat64FromNat64:
		case LowExprKind.SpecialUnary.Kind.toIntFromInt16:
		case LowExprKind.SpecialUnary.Kind.toIntFromInt32:
		case LowExprKind.SpecialUnary.Kind.toNatFromNat8:
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
			immutable Temp temp = writeExprTemp(writer, tempAlloc, indent, ctx, a.arg);
			return writeReturn(writer, indent, ctx, writeKind, type, () {
				writeCastToType(writer, ctx.ctx, type);
				writeTempRef(writer, temp);
			});
		case LowExprKind.SpecialUnary.Kind.bitsNotNat64:
			return prefix("~");
		case LowExprKind.SpecialUnary.Kind.deref:
			return prefix("*");
		case LowExprKind.SpecialUnary.Kind.hardFail:
			return writeReturn(writer, indent, ctx, writeKind, type, () {
				writeHardFail(writer, ctx.ctx, type);
			});
		case LowExprKind.SpecialUnary.Kind.not:
			return prefix("!");
		case LowExprKind.SpecialUnary.Kind.ptrTo:
		case LowExprKind.SpecialUnary.Kind.refOfVal:
			return writeReturn(writer, indent, ctx, writeKind, type, () {
				writeChar(writer, '&');
				writeLValue(writer, ctx, a.arg);
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
		(ref immutable LowExprKind.Match) => unreachable!void(),
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
					debug {
						import core.stdc.stdio : printf;
						printf("HUH %d\n", cast(int) it.kind);
					}
					todo!void("!");
			}
		},
		(ref immutable LowExprKind.SpecialBinary) => unreachable!void(),
		(ref immutable LowExprKind.SpecialTrinary) => unreachable!void(),
		(ref immutable LowExprKind.SpecialNAry) => unreachable!void(),
		(ref immutable LowExprKind.Switch) => unreachable!void(),
		(ref immutable LowExprKind.TailRecur) => unreachable!void());
}

void writeHardFail(Alloc)(ref Writer!Alloc writer, ref immutable Ctx ctx, ref immutable LowType type) {
	//TODO: this doesn't use the message we gave it..
	//TODO: this won't work for non-integral types
	writeStatic(writer, "(assert(0),");
	writeEmptyValue(writer, ctx, type);
	writeChar(writer, ')');
}

void writeEmptyValue(Alloc)(ref Writer!Alloc writer, ref immutable Ctx ctx, ref immutable LowType type) {
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
			immutable Arr!LowField fields = fullIndexDictGet(ctx.program.allRecords, it).fields;
			writeWithCommas!LowField(writer, fields, (ref immutable LowField field) {
				writeEmptyValue(writer, ctx, field.type);
			});
			writeChar(writer, '}');
		},
		(immutable LowType.Union) {
			writeCastToType(writer, ctx, type);
			writeStatic(writer, "{0}");
		});
}

immutable(WriteResult) writeSpecialBinary(Alloc, TempAlloc)(
	ref Writer!Alloc writer,
	ref TempAlloc tempAlloc,
	immutable size_t indent,
	ref FunBodyCtx ctx,
	immutable WriteKind writeKind,
	ref immutable LowType type,
	ref immutable LowExprKind.SpecialBinary it,
) {
	immutable(Temp) arg0() {
		return writeExprTemp(writer, tempAlloc, indent, ctx, it.left);
	}
	immutable(Temp) arg1() {
		return writeExprTemp(writer, tempAlloc, indent, ctx, it.right);
	}

	immutable(WriteResult) operator(string op) {
		immutable Temp temp0 = arg0();
		immutable Temp temp1 = arg1();
		return writeReturn(writer, indent, ctx, writeKind, type, () {
			writeTempRef(writer, temp0);
			writeChar(writer, ' ');
			writeStatic(writer, op);
			writeChar(writer, ' ');
			writeTempRef(writer, temp1);
		});
	}

	final switch (it.kind) {
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
		case LowExprKind.SpecialBinary.Kind.eqNat64:
		case LowExprKind.SpecialBinary.Kind.eqPtr:
			return operator("==");
		case LowExprKind.SpecialBinary.Kind.lessBool:
		case LowExprKind.SpecialBinary.Kind.lessChar:
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
		case LowExprKind.SpecialBinary.Kind.unsafeDivFloat64:
		case LowExprKind.SpecialBinary.Kind.unsafeDivInt64:
		case LowExprKind.SpecialBinary.Kind.unsafeDivNat64:
			return operator("/");
		case LowExprKind.SpecialBinary.Kind.unsafeModNat64:
			return operator("%");
		case LowExprKind.SpecialBinary.Kind.writeToPtr:
			immutable Temp temp0 = arg0();
			immutable Temp temp1 = arg1();
			return writeReturnVoid(writer, indent, ctx, writeKind, () {
				writeStatic(writer, "*");
				writeTempRef(writer, temp0);
				writeStatic(writer, " = ");
				writeTempRef(writer, temp1);
			});
			break;
	}
}

enum LogicalOperator { and, or }

struct WriteResultAndNested {
	immutable WriteResult result;
	immutable WriteKind writeKind;
}

// If we need to make a temporary, have to do that in an outer scope and write to it in an inner scope
immutable(WriteResultAndNested) getNestedWriteKind(Alloc)(
	ref Writer!Alloc writer,
	immutable size_t indent,
	ref FunBodyCtx ctx,
	ref immutable LowType type,
	ref immutable WriteKind writeKind,
) {
	if (isMakeTemp(writeKind)) {
		immutable Temp temp = getNextTemp(ctx);
		writeTempDeclare(writer, ctx, type, temp);
		writeChar(writer, ';');
		writeNewline(writer, indent);
		return immutable WriteResultAndNested(
			immutable WriteResult(some(temp)),
			immutable WriteKind(immutable WriteKind.UseTemp(temp)));
	} else
		return immutable WriteResultAndNested(
			immutable WriteResult(none!Temp),
			writeKind);
}

immutable(WriteResult) writeLogicalOperator(Alloc, TempAlloc)(
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
	immutable Temp cond = writeExprTemp(writer, tempAlloc, indent, ctx, left);
	immutable WriteResultAndNested nested = getNestedWriteKind(writer, indent, ctx, boolType, writeKind);
	writeNewline(writer, indent);
	writeStatic(writer, "if (");
	writeTempRef(writer, cond);
	writeStatic(writer, ") {");
	final switch (operator) {
		case LogicalOperator.and:
			drop(writeExpr(writer, tempAlloc, indent + 1, ctx, nested.writeKind, right));
			break;
		case LogicalOperator.or:
			drop(writeReturn(writer, indent + 1, ctx, nested.writeKind, boolType, () {
				writeChar(writer, '1');
			}));
			break;
	}
	writeNewline(writer, indent);
	writeStatic(writer, "} else {");
	final switch (operator) {
		case LogicalOperator.and:
			drop(writeReturn(writer, indent + 1, ctx, nested.writeKind, boolType, () {
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

immutable(WriteResult) writeSpecialTrinary(Alloc, TempAlloc)(
	ref Writer!Alloc writer,
	ref TempAlloc tempAlloc,
	immutable size_t indent,
	ref FunBodyCtx ctx,
	immutable WriteKind writeKind,
	ref immutable LowType type,
	ref immutable LowExprKind.SpecialTrinary a,
) {
	immutable(Temp) arg0() {
		return writeExprTemp(writer, tempAlloc, indent, ctx, a.p0);
	}
	immutable(Temp) arg1() {
		return writeExprTemp(writer, tempAlloc, indent, ctx, a.p1);
	}
	immutable(Temp) arg2() {
		return writeExprTemp(writer, tempAlloc, indent, ctx, a.p2);
	}

	final switch (a.kind) {
		case LowExprKind.SpecialTrinary.Kind.if_:
			immutable Temp temp0 = arg0();
			immutable WriteResultAndNested nested = getNestedWriteKind(writer, indent, ctx, type, writeKind);
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
			return writeReturn(writer, indent, ctx, writeKind, type, () {
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

immutable(WriteResult) writeSpecialNAry(Alloc, TempAlloc)(
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
			immutable Temp fn = writeExprTemp(writer, tempAlloc, indent, ctx, first(it.args));
			immutable Arr!Temp args = writeExprsTemp(writer, tempAlloc, indent, ctx, tail(it.args));
			return writeReturn(writer, indent, ctx, writeKind, type, () {
				writeTempRef(writer, fn);
				writeChar(writer, '(');
				writeTempRefs(writer, args);
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
	if (isSymOperator(name)) {
		writeStatic(writer, "_op");
		eachCharInSym(name, (immutable char c) {
			writeStatic(writer, () {
				final switch (c) {
					case '-': return "_minus";
					case '+': return "_plus";
					case '*': return "_times";
					case '/': return "_div";
					case '<': return "_less";
					case '>': return "_greater";
					case '=': return "_equal";
					case '!': return "_bang";
				}
			}());
		});
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
				default:
					writeChar(writer, c);
					break;
			}
		});
	}
}

immutable(Bool) conflictsWithCName(immutable Sym name) {
	switch (name.value) {
		case shortSymAlphaLiteralValue("atomic-bool"): // avoid conflicting with c's "atomic_bool" type
		case shortSymAlphaLiteralValue("default"):
		case shortSymAlphaLiteralValue("float"):
		case shortSymAlphaLiteralValue("int"):
		case shortSymAlphaLiteralValue("void"):
			return True;
		default:
			return False;
	}
}
