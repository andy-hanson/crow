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
	LowThreadLocal,
	LowType,
	LowUnion,
	matchLowFunSource,
	matchLowLocalSource,
	matchLowParamSource;
import model.model : FunInst, name, Param;
import util.alloc.alloc : Alloc;
import util.col.dict : Dict;
import util.col.dictBuilder : finishDict, mustAddToDict, DictBuilder;
import util.col.fullIndexDict : fullIndexDictEachValue;
import util.col.mutDict : insertOrUpdate, MutDict, setInDict;
import util.opt : force, has, none, Opt, some;
import util.sym : AllSymbols, eachCharInSym, Sym, sym, writeSym;
import util.writer : Writer;

struct MangledNames {
	immutable AllSymbols* allSymbols;
	immutable Dict!(ConcreteFun*, size_t) funToNameIndex;
	//TODO:PERF we could use separate FullIndexDict for record, union, etc.
	immutable Dict!(ConcreteStruct*, size_t) structToNameIndex;
}

immutable(MangledNames) buildMangledNames(
	ref Alloc alloc,
	return scope immutable AllSymbols* allSymbols,
	ref immutable LowProgram program,
) {
	// First time we see a fun with a name, we'll store the fun-pointer here in case it's not overloaded.
	// After that, we'll start putting them in funToNameIndex, and store the next index here.
	MutDict!(immutable Sym, immutable PrevOrIndex!ConcreteFun) funNameToIndex;
	// This will not have an entry for non-overloaded funs.
	DictBuilder!(ConcreteFun*, size_t) funToNameIndex;
	// HAX: Ensure "main" has that name.
	setInDict(alloc, funNameToIndex, sym!"main", immutable PrevOrIndex!ConcreteFun(0));
	fullIndexDictEachValue!(LowFunIndex, LowFun)(program.allFuns, (ref immutable LowFun it) {
		matchLowFunSource!(
			void,
			(immutable ConcreteFun* cf) {
				matchConcreteFunSource!(
					void,
					(ref immutable FunInst i) {
						//TODO: use temp alloc
						addToPrevOrIndex!ConcreteFun(alloc, funNameToIndex, funToNameIndex, cf, i.name);
					},
					(ref immutable ConcreteFunSource.Lambda) {},
					(ref immutable ConcreteFunSource.Test) {},
				)(cf.source);
			},
			(ref immutable LowFunSource.Generated it) {},
		)(it.source);
	});

	MutDict!(immutable Sym, immutable PrevOrIndex!ConcreteStruct) structNameToIndex;
	// This will not have an entry for non-overloaded structs.
	DictBuilder!(ConcreteStruct*, size_t) structToNameIndex;

	void build(immutable ConcreteStruct* s) {
		matchConcreteStructSource!(
			void,
			(ref immutable ConcreteStructSource.Inst it) {
				addToPrevOrIndex!ConcreteStruct(alloc, structNameToIndex, structToNameIndex, s, name(*it.inst));
			},
			(ref immutable ConcreteStructSource.Lambda) {},
		)(s.source);
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
	scope ref Writer writer,
	scope ref immutable MangledNames mangledNames,
	scope immutable ConcreteStruct* source,
) {
	matchConcreteStructSource!(
		void,
		(ref immutable ConcreteStructSource.Inst it) {
			writeMangledName(writer, mangledNames, name(*it.inst));
			maybeWriteIndexSuffix(writer, mangledNames.structToNameIndex[source]);
		},
		(ref immutable ConcreteStructSource.Lambda it) {
			writeConcreteFunMangledName(writer, mangledNames, it.containingFun);
			writer ~= "__lambda";
			writer ~= it.index;
		},
	)(source.source);
}

void writeLowFunMangledName(
	scope ref Writer writer,
	scope ref immutable MangledNames mangledNames,
	immutable LowFunIndex funIndex,
	scope ref immutable LowFun fun,
) {
	matchLowFunSource!(
		void,
		(immutable ConcreteFun* it) {
			writeConcreteFunMangledName(writer, mangledNames, it);
		},
		(ref immutable LowFunSource.Generated it) {
			writeMangledName(writer, mangledNames, it.name);
			if (it.name != sym!"main") {
				writer ~= '_';
				writer ~= funIndex.index;
			}
		},
	)(fun.source);
}

void writeLowThreadLocalMangledName(
	scope ref Writer writer,
	scope ref immutable MangledNames mangledNames,
	scope ref immutable LowThreadLocal threadLocal,
) {
	writeConcreteFunMangledName(writer, mangledNames, threadLocal.source);
}

private void writeConcreteFunMangledName(
	scope ref Writer writer,
	scope ref immutable MangledNames mangledNames,
	scope immutable ConcreteFun* source,
) {
	matchConcreteFunSource!(
		void,
		(ref immutable FunInst it) {
			if (isExtern(body_(*source)))
				writeSym(writer, *mangledNames.allSymbols, it.name);
			else {
				writeMangledName(writer, mangledNames, it.name);
				maybeWriteIndexSuffix(writer, mangledNames.funToNameIndex[source]);
			}
		},
		(ref immutable ConcreteFunSource.Lambda it) {
			writeConcreteFunMangledName(writer, mangledNames, it.containingFun);
			writer ~= "__lambda";
			writer ~= it.index;
		},
		(ref immutable ConcreteFunSource.Test it) {
			writer ~= "__test";
			writer ~= it.testIndex;
		},
	)(source.source);
}

private void maybeWriteIndexSuffix(scope ref Writer writer, immutable Opt!size_t index) {
	if (has(index)) {
		writer ~= '_';
		writer ~= force(index);
	}
}

void writeLowLocalName(
	scope ref Writer writer,
	scope ref immutable MangledNames mangledNames,
	scope ref immutable LowLocal a,
) {
	matchLowLocalSource!(
		void,
		(ref immutable ConcreteLocal it) {
			// Need to distinguish local names from function names
			writer ~= "__local";
			writeMangledName(writer, mangledNames, it.source.name);
		},
		(ref immutable LowLocalSource.Generated it) {
			writeMangledName(writer, mangledNames, it.name);
			writer ~= it.index;
		},
	)(a.source);
}

void writeLowParamName(
	scope ref Writer writer,
	scope ref immutable MangledNames mangledNames,
	scope ref immutable LowParam a,
) {
	matchLowParamSource!(
		void,
		(ref immutable ConcreteParam cp) {
			matchConcreteParamSource!void(
				cp.source,
				(ref immutable ConcreteParamSource.Closure) {
					writer ~= "_closure";
				},
				(ref immutable Param p) {
					if (has(p.name))
						writeMangledName(writer, mangledNames, force(p.name));
					else {
						writer ~= "_p";
						writer ~= p.index;
					}
				},
				(ref immutable ConcreteParamSource.Synthetic it) {
					writer ~= "_p";
					writer ~= force(cp.index);
				});
		},
		(ref immutable LowParamSource.Generated it) {
			writeMangledName(writer, mangledNames, it.name);
		},
	)(a.source);
}

void writeConstantArrStorageName(
	scope ref Writer writer,
	scope ref immutable MangledNames mangledNames,
	scope ref immutable LowProgram program,
	immutable LowType.Record arrType,
	immutable size_t index,
) {
	writer ~= "constant";
	writeRecordName(writer, mangledNames, program, arrType);
	writer ~= '_';
	writer ~= index;
}

void writeConstantPointerStorageName(
	scope ref Writer writer,
	scope ref immutable MangledNames mangledNames,
	scope ref immutable LowProgram program,
	scope immutable LowType pointeeType,
	immutable size_t index,
) {
	writer ~= "constant";
	writeRecordName(writer, mangledNames, program, asRecordType(pointeeType));
	writer ~= '_';
	writer ~= index;
}

void writeRecordName(
	scope ref Writer writer,
	scope ref immutable MangledNames mangledNames,
	scope ref immutable LowProgram program,
	immutable LowType.Record a,
) {
	writeStructMangledName(writer, mangledNames, program.allRecords[a].source);
}

private:

struct PrevOrIndex(T) {
	@safe @nogc pure nothrow:

	@trusted immutable this(immutable T* a) { kind_ = Kind.prev; prev_ = a;}
	immutable this(immutable size_t a) { kind_ = Kind.index; index_ = a; }

	private:
	enum Kind {
		prev,
		index,
	}
	immutable Kind kind_;
	union {
		immutable T* prev_;
		immutable size_t index_;
	}
}

@trusted T matchPrevOrIndex(T, P)(
	ref immutable PrevOrIndex!P a,
	scope T delegate(immutable P*) @safe @nogc pure nothrow cbPrev,
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
	ref MutDict!(immutable Sym, immutable PrevOrIndex!T) nameToIndex,
	ref DictBuilder!(T*, size_t) toNameIndex,
	immutable T* cur,
	immutable Sym name,
) {
	insertOrUpdate!(immutable Sym, immutable PrevOrIndex!T)(
		alloc,
		nameToIndex,
		name,
		() =>
			immutable PrevOrIndex!T(cur),
		(ref immutable PrevOrIndex!T it) =>
			immutable PrevOrIndex!T(matchPrevOrIndex!(immutable size_t, T)(
				it,
				(immutable T* prev) {
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
	//TODO: this applies to any C function. Maybe crow functions should have a common prefix.
	if (a == sym!"errno") {
		writer ~= "_crow_errno";
		return;
	}

	if (conflictsWithCName(a))
		writer ~= '_';
	eachCharInSym(*mangledNames.allSymbols, a, (immutable char c) {
		immutable Opt!string mangled = mangleChar(c);
		if (has(mangled))
			writer ~= force(mangled);
		else
			writer ~= c;
	});
}

immutable(Opt!string) mangleChar(immutable char a) {
	switch (a) {
		case '~':
			return some("__t");
		case '!':
			return some("__b");
		case '%':
			return some("__u");
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
		case sym!"atomic-bool".value: // avoid conflicting with c's "atomic_bool" type
		case sym!"break".value:
		case sym!"continue".value:
		case sym!"default".value:
		case sym!"do".value:
		case sym!"double".value:
		case sym!"float".value:
		case sym!"for".value:
		case sym!"int".value:
		case sym!"void".value:
		case sym!"while".value:
			return true;
		default:
			return false;
	}
}
