module backend.mangle;

@safe @nogc pure nothrow:

import model.concreteModel :
	body_,
	ConcreteFun,
	ConcreteFunBody,
	ConcreteFunSource,
	ConcreteLocal,
	ConcreteParam,
	ConcreteParamSource,
	ConcreteStruct,
	ConcreteStructSource;
import model.lowModel :
	LowExternType,
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
	LowUnion;
import model.model : FunInst, name, Param;
import util.alloc.alloc : Alloc;
import util.col.dict : Dict;
import util.col.dictBuilder : finishDict, mustAddToDict, DictBuilder;
import util.col.fullIndexDict : fullIndexDictEachValue;
import util.col.mutDict : insertOrUpdate, MutDict, setInDict;
import util.opt : force, has, none, Opt, some;
import util.sym : AllSymbols, eachCharInSym, Sym, sym, writeSym;
import util.union_ : Union;
import util.writer : Writer;

const struct MangledNames {
	AllSymbols* allSymbols;
	Dict!(ConcreteFun*, size_t) funToNameIndex;
	//TODO:PERF we could use separate FullIndexDict for record, union, etc.
	Dict!(ConcreteStruct*, size_t) structToNameIndex;
}

MangledNames buildMangledNames(
	ref Alloc alloc,
	return scope const AllSymbols* allSymbols,
	return scope const LowProgram program,
) {
	// First time we see a fun with a name, we'll store the fun-pointer here in case it's not overloaded.
	// After that, we'll start putting them in funToNameIndex, and store the next index here.
	MutDict!(Sym, PrevOrIndex!ConcreteFun) funNameToIndex;
	// This will not have an entry for non-overloaded funs.
	DictBuilder!(ConcreteFun*, size_t) funToNameIndex;
	// HAX: Ensure "main" has that name.
	setInDict(alloc, funNameToIndex, sym!"main", PrevOrIndex!ConcreteFun(0));
	fullIndexDictEachValue!(LowFunIndex, LowFun)(program.allFuns, (ref LowFun fun) {
		fun.source.matchWithPointers!void(
			(ConcreteFun* cf) {
				cf.source.matchIn!void(
					(in FunInst i) {
						//TODO: use temp alloc
						addToPrevOrIndex!ConcreteFun(alloc, funNameToIndex, funToNameIndex, cf, i.name);
					},
					(in ConcreteFunSource.Lambda) {},
					(in ConcreteFunSource.Test) {});
			},
			(LowFunSource.Generated*) {});
	});

	MutDict!(Sym, PrevOrIndex!ConcreteStruct) structNameToIndex;
	// This will not have an entry for non-overloaded structs.
	DictBuilder!(ConcreteStruct*, size_t) structToNameIndex;

	void build(ConcreteStruct* s) {
		s.source.match!void(
			(ConcreteStructSource.Inst it) {
				addToPrevOrIndex!ConcreteStruct(alloc, structNameToIndex, structToNameIndex, s, name(*it.inst));
			},
			(ConcreteStructSource.Lambda) {});
	}
	fullIndexDictEachValue!(LowType.Extern, LowExternType)(program.allExternTypes, (ref LowExternType it) {
		build(it.source);
	});
	fullIndexDictEachValue!(LowType.FunPtr, LowFunPtrType)(program.allFunPtrTypes, (ref LowFunPtrType it) {
		build(it.source);
	});
	fullIndexDictEachValue!(LowType.Record, LowRecord)(program.allRecords, (ref LowRecord it) {
		build(it.source);
	});
	fullIndexDictEachValue!(LowType.Union, LowUnion)(program.allUnions, (ref LowUnion it) {
		build(it.source);
	});

	return MangledNames(allSymbols, finishDict(alloc, funToNameIndex), finishDict(alloc, structToNameIndex));
}

void writeStructMangledName(scope ref Writer writer, in MangledNames mangledNames, in ConcreteStruct* source) {
	source.source.matchIn!void(
		(in ConcreteStructSource.Inst it) {
			writeMangledName(writer, mangledNames, name(*it.inst));
			maybeWriteIndexSuffix(writer, mangledNames.structToNameIndex[source]);
		},
		(in ConcreteStructSource.Lambda it) {
			writeConcreteFunMangledName(writer, mangledNames, it.containingFun);
			writer ~= "__lambda";
			writer ~= it.index;
		});
}

void writeLowFunMangledName(
	scope ref Writer writer,
	in MangledNames mangledNames,
	LowFunIndex funIndex,
	in LowFun fun,
) {
	fun.source.matchWithPointers!void(
		(ConcreteFun* x) {
			writeConcreteFunMangledName(writer, mangledNames, x);
		},
		(LowFunSource.Generated* x) {
			writeMangledName(writer, mangledNames, x.name);
			if (x.name != sym!"main") {
				writer ~= '_';
				writer ~= funIndex.index;
			}
		});
}

void writeLowThreadLocalMangledName(
	scope ref Writer writer,
	in MangledNames mangledNames,
	in LowThreadLocal threadLocal,
) {
	writeConcreteFunMangledName(writer, mangledNames, threadLocal.source);
}

private void writeConcreteFunMangledName(
	scope ref Writer writer,
	in MangledNames mangledNames,
	in ConcreteFun* source,
) {
	source.source.matchIn!void(
		(in FunInst it) {
			if (body_(*source).isA!(ConcreteFunBody.Extern))
				writeSym(writer, *mangledNames.allSymbols, it.name);
			else {
				writeMangledName(writer, mangledNames, it.name);
				maybeWriteIndexSuffix(writer, mangledNames.funToNameIndex[source]);
			}
		},
		(in ConcreteFunSource.Lambda it) {
			writeConcreteFunMangledName(writer, mangledNames, it.containingFun);
			writer ~= "__lambda";
			writer ~= it.index;
		},
		(in ConcreteFunSource.Test it) {
			writer ~= "__test";
			writer ~= it.testIndex;
		});
}

private void maybeWriteIndexSuffix(scope ref Writer writer, Opt!size_t index) {
	if (has(index)) {
		writer ~= '_';
		writer ~= force(index);
	}
}

void writeLowLocalName(scope ref Writer writer, in MangledNames mangledNames, in LowLocal a) {
	a.source.matchIn!void(
		(in ConcreteLocal it) {
			// Need to distinguish local names from function names
			writer ~= "__local";
			writeMangledName(writer, mangledNames, it.source.name);
		},
		(in LowLocalSource.Generated it) {
			writeMangledName(writer, mangledNames, it.name);
			writer ~= it.index;
		});
}

void writeLowParamName(scope ref Writer writer, in MangledNames mangledNames, in LowParam a) {
	a.source.matchIn!void(
		(in ConcreteParam cp) {
			cp.source.matchIn!void(
				(in ConcreteParamSource.Closure) {
					writer ~= "_closure";
				},
				(in Param p) {
					if (has(p.name))
						writeMangledName(writer, mangledNames, force(p.name));
					else {
						writer ~= "_p";
						writer ~= p.index;
					}
				},
				(in ConcreteParamSource.Synthetic it) {
					writer ~= "_p";
					writer ~= force(cp.index);
				});
		},
		(in LowParamSource.Generated it) {
			writeMangledName(writer, mangledNames, it.name);
		});
}

void writeConstantArrStorageName(
	scope ref Writer writer,
	in MangledNames mangledNames,
	in LowProgram program,
	LowType.Record arrType,
	size_t index,
) {
	writer ~= "constant";
	writeRecordName(writer, mangledNames, program, arrType);
	writer ~= '_';
	writer ~= index;
}

void writeConstantPointerStorageName(
	scope ref Writer writer,
	in MangledNames mangledNames,
	in LowProgram program,
	in LowType pointeeType,
	size_t index,
) {
	writer ~= "constant";
	writeRecordName(writer, mangledNames, program, pointeeType.as!(LowType.Record));
	writer ~= '_';
	writer ~= index;
}

void writeRecordName(scope ref Writer writer, in MangledNames mangledNames, in LowProgram program, LowType.Record a) {
	writeStructMangledName(writer, mangledNames, program.allRecords[a].source);
}

private:

immutable struct PrevOrIndex(T) {
	mixin Union!(immutable T*, immutable size_t);
}

void addToPrevOrIndex(T)(
	ref Alloc alloc,
	ref MutDict!(Sym, PrevOrIndex!T) nameToIndex,
	ref DictBuilder!(T*, size_t) toNameIndex,
	immutable T* cur,
	Sym name,
) {
	insertOrUpdate!(Sym, PrevOrIndex!T)(
		alloc,
		nameToIndex,
		name,
		() =>
			PrevOrIndex!T(cur),
		(ref PrevOrIndex!T x) =>
			PrevOrIndex!T(x.matchWithPointers!size_t(
				(T* prev) {
					mustAddToDict(alloc, toNameIndex, prev, 0);
					mustAddToDict(alloc, toNameIndex, cur, 1);
					return size_t(2);
				},
				(size_t index) {
					mustAddToDict(alloc, toNameIndex, cur, index);
					return index + 1;
				})));
}

public void writeMangledName(ref Writer writer, in MangledNames mangledNames, Sym a) {
	//TODO: this applies to any C function. Maybe crow functions should have a common prefix.
	if (a == sym!"errno") {
		writer ~= "_crow_errno";
		return;
	}

	if (conflictsWithCName(a))
		writer ~= '_';
	eachCharInSym(*mangledNames.allSymbols, a, (char c) {
		Opt!string mangled = mangleChar(c);
		if (has(mangled))
			writer ~= force(mangled);
		else
			writer ~= c;
	});
}

Opt!string mangleChar(char a) {
	switch (a) {
		case '~':
			return some!string("__t");
		case '!':
			return some!string("__b");
		case '%':
			return some!string("__u");
		case '^':
			return some!string("__x");
		case '&':
			return some!string("__a");
		case '*':
			return some!string("__m");
		case '-':
			return some!string("__s");
		case '+':
			return some!string("__p");
		case '=':
			return some!string("__e");
		case '|':
			return some!string("__o");
		case '<':
			return some!string("__l");
		case '.':
			return some!string("__r");
		case '>':
			return some!string("__g");
		case '/':
			return some!string("__d");
		case '?':
			return some!string("__q");
		default:
			return none!string;
	}
}

bool conflictsWithCName(Sym a) {
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
