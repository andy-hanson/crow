module backend.mangle;

@safe @nogc pure nothrow:

import model.concreteModel :
	body_,
	ConcreteFun,
	ConcreteFunSource,
	ConcreteLocal,
	ConcreteParam,
	ConcreteParamSource,
	ConcreteStruct,
	ConcreteStructSource,
	isExtern,
	matchConcreteFunSource,
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
import model.model : FunInst, name, Param;
import util.alloc.alloc : Alloc;
import util.col.dict : getAt, PtrDict;
import util.col.dictBuilder : finishDict, mustAddToDict, PtrDictBuilder;
import util.col.fullIndexDict : fullIndexDictEachValue, fullIndexDictGet;
import util.col.mutDict : insertOrUpdate, MutSymDict, setInDict;
import util.opt : force, has, none, Opt, some;
import util.ptr : Ptr;
import util.sym : AllSymbols, eachCharInSym, hashSym, shortSym, shortSymValue, Sym, symEq, writeSym;
import util.writer : writeChar, writeNat, Writer, writeStatic;

struct MangledNames {
	immutable Ptr!AllSymbols allSymbols;
	immutable PtrDict!(ConcreteFun, size_t) funToNameIndex;
	//TODO:PERF we could use separate FullIndexDict for record, union, etc.
	immutable PtrDict!(ConcreteStruct, size_t) structToNameIndex;
}

immutable(MangledNames) buildMangledNames(
	ref Alloc alloc,
	return scope immutable Ptr!AllSymbols allSymbols,
	ref immutable LowProgram program,
) {
	// First time we see a fun with a name, we'll store the fun-ptr here in case it's not overloaded.
	// After that, we'll start putting them in funToNameIndex, and store the next index here.
	MutSymDict!(immutable PrevOrIndex!ConcreteFun) funNameToIndex;
	// This will not have an entry for non-overloaded funs.
	PtrDictBuilder!(ConcreteFun, size_t) funToNameIndex;
	// HAX: Ensure "main" has that name.
	setInDict(alloc, funNameToIndex, shortSym("main"), immutable PrevOrIndex!ConcreteFun(0));
	fullIndexDictEachValue!(LowFunIndex, LowFun)(program.allFuns, (ref immutable LowFun it) {
		matchLowFunSource!(
			void,
			(immutable Ptr!ConcreteFun cf) {
				matchConcreteFunSource!(
					void,
					(ref immutable FunInst i) {
						//TODO: use temp alloc
						addToPrevOrIndex!ConcreteFun(alloc, funNameToIndex, funToNameIndex, cf, name(i));
					},
					(ref immutable ConcreteFunSource.Lambda) {},
					(ref immutable ConcreteFunSource.Test) {},
				)(cf.deref().source);
			},
			(ref immutable LowFunSource.Generated it) {},
		)(it.source);
	});

	MutSymDict!(immutable PrevOrIndex!ConcreteStruct) structNameToIndex;
	// This will not have an entry for non-overloaded structs.
	PtrDictBuilder!(ConcreteStruct, size_t) structToNameIndex;

	void build(immutable Ptr!ConcreteStruct s) {
		matchConcreteStructSource!(
			void,
			(ref immutable ConcreteStructSource.Inst it) {
				addToPrevOrIndex!ConcreteStruct(alloc, structNameToIndex, structToNameIndex, s, name(it.inst.deref()));
			},
			(ref immutable ConcreteStructSource.Lambda) {},
		)(s.deref().source);
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
		allSymbols,
		finishDict(alloc, funToNameIndex),
		finishDict(alloc, structToNameIndex));
}

void writeStructMangledName(
	ref Writer writer,
	ref immutable MangledNames mangledNames,
	immutable Ptr!ConcreteStruct source,
) {
	matchConcreteStructSource!(
		void,
		(ref immutable ConcreteStructSource.Inst it) {
			writeMangledName(writer, mangledNames, name(it.inst.deref()));
			maybeWriteIndexSuffix(writer, getAt(mangledNames.structToNameIndex, source));
		},
		(ref immutable ConcreteStructSource.Lambda it) {
			writeConcreteFunMangledName(writer, mangledNames, it.containingFun);
			writeStatic(writer, "__lambda");
			writeNat(writer, it.index);
		},
	)(source.deref().source);
}

void writeLowFunMangledName(
	ref Writer writer,
	ref immutable MangledNames mangledNames,
	immutable LowFunIndex funIndex,
	ref immutable LowFun fun,
) {
	matchLowFunSource!(
		void,
		(immutable Ptr!ConcreteFun it) {
			writeConcreteFunMangledName(writer, mangledNames, it);
		},
		(ref immutable LowFunSource.Generated it) {
			writeMangledName(writer, mangledNames, it.name);
			if (!symEq(it.name, shortSym("main"))) {
				writeChar(writer, '_');
				writeNat(writer, funIndex.index);
			}
		},
	)(fun.source);
}

private void writeConcreteFunMangledName(
	ref Writer writer,
	ref immutable MangledNames mangledNames,
	immutable Ptr!ConcreteFun source,
) {
	matchConcreteFunSource!(
		void,
		(ref immutable FunInst it) {
			immutable Sym name = name(it);
			if (isExtern(body_(source.deref())))
				writeSym(writer, mangledNames.allSymbols.deref(), name);
			else {
				writeMangledName(writer, mangledNames, name);
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
			writeNat(writer, it.testIndex);
		},
	)(source.deref().source);
}

private void maybeWriteIndexSuffix(ref Writer writer, immutable Opt!size_t index) {
	if (has(index)) {
		writeChar(writer, '_');
		writeNat(writer, force(index));
	}
}

void writeLowLocalName(ref Writer writer, ref immutable MangledNames mangledNames, ref immutable LowLocal a) {
	matchLowLocalSource!(
		void,
		(ref immutable ConcreteLocal it) {
			writeMangledName(writer, mangledNames, it.source.deref().name);
			writeNat(writer, it.index);
		},
		(ref immutable LowLocalSource.Generated it) {
			writeMangledName(writer, mangledNames, it.name);
			writeNat(writer, it.index);
		},
	)(a.source);
}

void writeLowParamName(ref Writer writer, scope ref immutable MangledNames mangledNames, ref immutable LowParam a) {
	matchLowParamSource!(
		void,
		(ref immutable ConcreteParam cp) {
			matchConcreteParamSource!void(
				cp.source,
				(ref immutable ConcreteParamSource.Closure) {
					writeStatic(writer, "_closure");
				},
				(ref immutable Param p) @safe {
					if (has(p.name))
						writeMangledName(writer, mangledNames, force(p.name));
					else {
						writeStatic(writer, "_p");
						writeNat(writer, p.index);
					}
				},
				(ref immutable ConcreteParamSource.Synthetic it) {
					writeStatic(writer, "_p");
					writeNat(writer, force(cp.index));
				});
		},
		(ref immutable LowParamSource.Generated it) {
			writeMangledName(writer, mangledNames, it.name);
		},
	)(a.source);
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

public void writeMangledName(ref Writer writer, scope ref immutable MangledNames mangledNames, immutable Sym a) {
	if (conflictsWithCName(a))
		writeChar(writer, '_');
	eachCharInSym(mangledNames.allSymbols.deref(), a, (immutable char c) {
		immutable Opt!string mangled = mangleChar(c);
		if (has(mangled))
			writeStatic(writer, force(mangled));
		else
			writeChar(writer, c);
	});
}

immutable(Opt!string) mangleChar(immutable char a) {
	switch (a) {
		case '~':
			return some("__t");
		case '!':
			return some("__b");
		case '^':
			return some("__x");
		case '&':
			return some("__a");
		case '*':
			return some("__m");
		case '-':
			return some("__s");
		case '+':
			return some("__p");
		case '=':
			return some("__e");
		case '|':
			return some("__o");
		case '<':
			return some("__l");
		case '.':
			return some("__r");
		case '>':
			return some("__g");
		case '/':
			return some("__d");
		case '?':
			return some("__q");
		default:
			return none!string;
	}
}

immutable(bool) conflictsWithCName(immutable Sym a) {
	switch (a.value) {
		case shortSymValue("atomic-bool"): // avoid conflicting with c's "atomic_bool" type
		case shortSymValue("break"):
		case shortSymValue("continue"):
		case shortSymValue("default"):
		case shortSymValue("double"):
		case shortSymValue("float"):
		case shortSymValue("for"):
		case shortSymValue("int"):
		case shortSymValue("void"):
		case shortSymValue("while"):
			return true;
		default:
			return false;
	}
}
