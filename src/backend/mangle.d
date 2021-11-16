module backend.mangle;

@safe @nogc pure nothrow:

import model.concreteModel :
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
	matchConcreteLocalSource,
	matchConcreteParamSource,
	matchConcreteStructSource;
import model.lowModel :
	asRecordType,
	LowExternPtrType,
	LowFun,
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
	matchLowFunSource,
	matchLowLocalSource,
	matchLowParamSource;
import model.model : FunInst, name, Local, Param;
import util.alloc.alloc : Alloc;
import util.collection.dict : getAt, PtrDict;
import util.collection.dictBuilder : finishDict, mustAddToDict, PtrDictBuilder;
import util.collection.fullIndexDict : fullIndexDictEachValue, fullIndexDictGet;
import util.collection.mutDict : insertOrUpdate, MutSymDict, setInDict;
import util.opt : force, has, Opt;
import util.ptr : Ptr;
import util.sym :
	eachCharInSym,
	hashSym,
	Operator,
	operatorForSym,
	shortSymAlphaLiteral,
	shortSymAlphaLiteralValue,
	Sym,
	symEq,
	writeSym;
import util.writer : writeChar, writeNat, Writer, writeStatic;

struct MangledNames {
	immutable PtrDict!(ConcreteFun, size_t) funToNameIndex;
	//TODO:PERF we could use separate FullIndexDict for record, union, etc.
	immutable PtrDict!(ConcreteStruct, size_t) structToNameIndex;
}

immutable(MangledNames) buildMangledNames(ref Alloc alloc, ref immutable LowProgram program) {
	// First time we see a fun with a name, we'll store the fun-ptr here in case it's not overloaded.
	// After that, we'll start putting them in funToNameIndex, and store the next index here.
	MutSymDict!(immutable PrevOrIndex!ConcreteFun) funNameToIndex;
	// This will not have an entry for non-overloaded funs.
	PtrDictBuilder!(ConcreteFun, size_t) funToNameIndex;
	// HAX: Ensure "main" has that name.
	setInDict(alloc, funNameToIndex, shortSymAlphaLiteral("main"), immutable PrevOrIndex!ConcreteFun(0));
	fullIndexDictEachValue!(LowFunIndex, LowFun)(program.allFuns, (ref immutable LowFun it) {
		matchLowFunSource!void(
			it.source,
			(immutable Ptr!ConcreteFun cf) {
				matchConcreteFunSource!void(
					cf.deref().source,
					(ref immutable FunInst i) {
						//TODO: use temp alloc
						addToPrevOrIndex!ConcreteFun(alloc, funNameToIndex, funToNameIndex, cf, name(i));
					},
					(ref immutable ConcreteFunSource.Lambda) {},
					(ref immutable ConcreteFunSource.Test) {});
			},
			(ref immutable LowFunSource.Generated it) {});
	});

	MutSymDict!(immutable PrevOrIndex!ConcreteStruct) structNameToIndex;
	// This will not have an entry for non-overloaded structs.
	PtrDictBuilder!(ConcreteStruct, size_t) structToNameIndex;

	void build(immutable Ptr!ConcreteStruct s) {
		matchConcreteStructSource!void(
			s.deref().source,
			(ref immutable ConcreteStructSource.Inst it) {
				addToPrevOrIndex!ConcreteStruct(alloc, structNameToIndex, structToNameIndex, s, name(it.inst.deref()));
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
		finishDict(alloc, funToNameIndex),
		finishDict(alloc, structToNameIndex));
}

void writeStructMangledName(
	ref Writer writer,
	ref immutable MangledNames mangledNames,
	immutable Ptr!ConcreteStruct source,
) {
	matchConcreteStructSource!void(
		source.deref().source,
		(ref immutable ConcreteStructSource.Inst it) {
			writeMangledName(writer, name(it.inst.deref()));
			maybeWriteIndexSuffix(writer, getAt(mangledNames.structToNameIndex, source));
		},
		(ref immutable ConcreteStructSource.Lambda it) {
			writeConcreteFunMangledName(writer, mangledNames, it.containingFun);
			writeStatic(writer, "__lambda");
			writeNat(writer, it.index);
		});
}

void writeLowFunMangledName(
	ref Writer writer,
	ref immutable MangledNames mangledNames,
	immutable LowFunIndex funIndex,
	ref immutable LowFun fun,
) {
	matchLowFunSource!void(
		fun.source,
		(immutable Ptr!ConcreteFun it) {
			writeConcreteFunMangledName(writer, mangledNames, it);
		},
		(ref immutable LowFunSource.Generated it) {
			writeMangledName(writer, it.name);
			if (!symEq(it.name, shortSymAlphaLiteral("main"))) {
				writeChar(writer, '_');
				writeNat(writer, funIndex.index);
			}
		});
}

private void writeConcreteFunMangledName(
	ref Writer writer,
	ref immutable MangledNames mangledNames,
	immutable Ptr!ConcreteFun source,
) {
	matchConcreteFunSource!void(
		source.deref().source,
		(ref immutable FunInst it) {
			immutable Sym name = name(it);
			if (isExtern(body_(source.deref())))
				writeSym(writer, name);
			else {
				writeMangledName(writer, name);
				maybeWriteIndexSuffix(writer, getAt(mangledNames.funToNameIndex, source));
			}
		},
		(ref immutable ConcreteFunSource.Lambda it) {
			writeConcreteFunMangledName(writer, mangledNames, it.containingFun);
			writeStatic(writer, "__lambda");
			writeNat(writer, it.index);
		},
		(ref immutable ConcreteFunSource.Test it) {
			writeStatic(writer, "__test");
			writeNat(writer, it.index);
		});
}

private void maybeWriteIndexSuffix(ref Writer writer, immutable Opt!size_t index) {
	if (has(index)) {
		writeChar(writer, '_');
		writeNat(writer, force(index));
	}
}

void writeLowLocalName(ref Writer writer, ref immutable LowLocal a) {
	matchLowLocalSource!void(
		a.source,
		(ref immutable ConcreteLocal it) {
			matchConcreteLocalSource!void(
				it.source,
				(ref immutable ConcreteLocalSource.Arr) {
					writeStatic(writer, "_arr");
				},
				(ref immutable Local it) {
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

void writeLowParamName(ref Writer writer, ref immutable LowParam a) {
	matchLowParamSource!void(
		a.source,
		(ref immutable ConcreteParam cp) {
			matchConcreteParamSource!void(
				cp.source,
				(ref immutable ConcreteParamSource.Closure) {
					writeStatic(writer, "_closure");
				},
				(ref immutable Param p) {
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

void writeConstantArrStorageName(
	ref Writer writer,
	ref immutable MangledNames mangledNames,
	ref immutable LowProgram program,
	immutable LowType.Record arrType,
	immutable size_t index,
) {
	writeStatic(writer, "constant");
	writeRecordName(writer, mangledNames, program, arrType);
	writeChar(writer, '_');
	writeNat(writer, index);
}

void writeConstantPointerStorageName(
	ref Writer writer,
	ref immutable MangledNames mangledNames,
	ref immutable LowProgram program,
	immutable LowType pointeeType,
	immutable size_t index,
) {
	writeStatic(writer, "constant");
	writeRecordName(writer, mangledNames, program, asRecordType(pointeeType));
	writeChar(writer, '_');
	writeNat(writer, index);
}

void writeRecordName(
	ref Writer writer,
	ref immutable MangledNames mangledNames,
	ref immutable LowProgram program,
	immutable LowType.Record a,
) {
	writeStructMangledName(writer, mangledNames, fullIndexDictGet(program.allRecords, a).source);
}

private:

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

void addToPrevOrIndex(T)(
	ref Alloc alloc,
	ref MutSymDict!(immutable PrevOrIndex!T) nameToIndex,
	ref PtrDictBuilder!(T, size_t) toNameIndex,
	immutable Ptr!T cur,
	immutable Sym name,
) {
	insertOrUpdate!(immutable Sym, immutable PrevOrIndex!T, symEq, hashSym)(
		alloc,
		nameToIndex,
		name,
		() =>
			immutable PrevOrIndex!T(cur),
		(ref immutable PrevOrIndex!T it) =>
			immutable PrevOrIndex!T(matchPrevOrIndex!(immutable size_t)(
				it,
				(immutable Ptr!T prev) {
					mustAddToDict(alloc, toNameIndex, prev, 0);
					mustAddToDict(alloc, toNameIndex, cur, 1);
					return immutable size_t(2);
				},
				(immutable size_t index) {
					mustAddToDict(alloc, toNameIndex, cur, index);
					return index + 1;
				})));
}

public void writeMangledName(ref Writer writer, immutable Sym a) {
	immutable Opt!Operator operator = operatorForSym(a);
	if (has(operator))
		writeStatic(writer, mangleOperator(force(operator)));
	else {
		if (conflictsWithCName(a))
			writeChar(writer, '_');
		eachCharInSym(a, (immutable char c) {
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

immutable(string) mangleOperator(immutable Operator a) {
	final switch (a) {
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
		case Operator.range:
			return "_range";
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
}

immutable(bool) conflictsWithCName(immutable Sym a) {
	switch (a.value) {
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
