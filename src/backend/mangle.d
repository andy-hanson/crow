module backend.mangle;

@safe @nogc pure nothrow:

import model.concreteModel :
	body_,
	ConcreteFun,
	ConcreteFunBody,
	ConcreteFunKey,
	ConcreteFunSource,
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
	LowProgram,
	LowRecord,
	LowType,
	LowUnion,
	LowVar,
	LowVarIndex;
import model.model : FunInst, Local, name;
import util.alloc.alloc : Alloc;
import util.col.map : Map;
import util.col.mapBuilder : finishMap, mustAddToMap, MapBuilder;
import util.col.fullIndexMap : FullIndexMap, fullIndexMapEachValue, mapFullIndexMap;
import util.col.mutMap : getOrAdd, insertOrUpdate, MutMap, setInMap;
import util.opt : force, has, none, Opt, some;
import util.sym : AllSymbols, eachCharInSym, Sym, sym, writeSym;
import util.union_ : Union;
import util.util : todo;
import util.writer : Writer;

const struct MangledNames {
	AllSymbols* allSymbols;
	FullIndexMap!(LowVarIndex, size_t) varToNameIndex;
	Map!(ConcreteFun*, size_t) funToNameIndex;
	//TODO:PERF we could use separate FullIndexMap for record, union, etc.
	Map!(ConcreteStruct*, size_t) structToNameIndex;
}

MangledNames buildMangledNames(
	ref Alloc alloc,
	return scope const AllSymbols* allSymbols,
	return scope const LowProgram program,
) {
	// First time we see a fun with a name, we'll store the fun-pointer here in case it's not overloaded.
	// After that, we'll start putting them in funToNameIndex, and store the next index here.
	MutMap!(Sym, PrevOrIndex!ConcreteFun) funNameToIndex;
	// This will not have an entry for non-overloaded funs.
	MapBuilder!(ConcreteFun*, size_t) funToNameIndex;
	// HAX: Ensure "main" has that name.
	setInMap(alloc, funNameToIndex, sym!"main", PrevOrIndex!ConcreteFun(0));
	fullIndexMapEachValue!(LowFunIndex, LowFun)(program.allFuns, (ref LowFun fun) {
		fun.source.matchWithPointers!void(
			(ConcreteFun* cf) {
				cf.source.matchIn!void(
					(in ConcreteFunKey x) {
						//TODO: use temp alloc
						addToPrevOrIndex!ConcreteFun(alloc, funNameToIndex, funToNameIndex, cf, x.decl.name);
					},
					(in ConcreteFunSource.Lambda) {},
					(in ConcreteFunSource.Test) {},
					(in ConcreteFunSource.WrapMain) {});
			},
			(LowFunSource.Generated*) {});
	});

	MutMap!(Sym, PrevOrIndex!ConcreteStruct) structNameToIndex;
	// This will not have an entry for non-overloaded structs.
	MapBuilder!(ConcreteStruct*, size_t) structToNameIndex;

	void build(ConcreteStruct* s) {
		s.source.match!void(
			(ConcreteStructSource.Bogus) {},
			(ConcreteStructSource.Inst it) {
				addToPrevOrIndex!ConcreteStruct(alloc, structNameToIndex, structToNameIndex, s, name(*it.inst));
			},
			(ConcreteStructSource.Lambda) {});
	}
	fullIndexMapEachValue!(LowType.Extern, LowExternType)(program.allExternTypes, (ref LowExternType it) {
		build(it.source);
	});
	fullIndexMapEachValue!(LowType.FunPtr, LowFunPtrType)(program.allFunPtrTypes, (ref LowFunPtrType it) {
		build(it.source);
	});
	fullIndexMapEachValue!(LowType.Record, LowRecord)(program.allRecords, (ref LowRecord it) {
		build(it.source);
	});
	fullIndexMapEachValue!(LowType.Union, LowUnion)(program.allUnions, (ref LowUnion it) {
		build(it.source);
	});

	return MangledNames(
		allSymbols,
		makeVarToNameIndex(alloc, program.vars),
		finishMap(alloc, funToNameIndex),
		finishMap(alloc, structToNameIndex));
}

private immutable(FullIndexMap!(LowVarIndex, size_t)) makeVarToNameIndex(
	ref Alloc alloc,
	in immutable FullIndexMap!(LowVarIndex, LowVar) vars,
) {
	MutMap!(Sym, size_t) counts;
	return mapFullIndexMap!(LowVarIndex, size_t, LowVar)(alloc, vars, (LowVarIndex _, in LowVar x) {
		//TODO:PERF use temp alloc
		size_t* index = &getOrAdd!(Sym, size_t)(alloc, counts, x.name, () => 0);
		size_t res = *index;
		(*index)++;
		if (x.isExtern && res != 0)
			todo!void("'extern' vars can't have same name");
		return res;
	});
}

void writeStructMangledName(scope ref Writer writer, in MangledNames mangledNames, in ConcreteStruct* source) {
	source.source.matchIn!void(
		(in ConcreteStructSource.Bogus) {
			writer ~= "__BOGUS";
		},
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

void writeLowVarMangledName(
	scope ref Writer writer,
	in MangledNames mangledNames,
	LowVarIndex varIndex,
	in LowVar var,
) {
	writeMangledName(writer, mangledNames, var.name);
	size_t index = mangledNames.varToNameIndex[varIndex];
	if (index != 0) {
		writer ~= '_';
		writer ~= index;
	}
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

private void writeConcreteFunMangledName(
	scope ref Writer writer,
	in MangledNames mangledNames,
	in ConcreteFun* source,
) {
	source.source.matchIn!void(
		(in ConcreteFunKey x) {
			if (body_(*source).isA!(ConcreteFunBody.Extern))
				writeSym(writer, *mangledNames.allSymbols, x.decl.name);
			else {
				writeMangledName(writer, mangledNames, x.decl.name);
				maybeWriteIndexSuffix(writer, mangledNames.funToNameIndex[source]);
			}
		},
		(in ConcreteFunSource.Lambda x) {
			writeConcreteFunMangledName(writer, mangledNames, x.containingFun);
			writer ~= "__lambda";
			writer ~= x.index;
		},
		(in ConcreteFunSource.Test x) {
			writer ~= "__test";
			writer ~= x.testIndex;
		},
		(in ConcreteFunSource.WrapMain x) {
			writer ~= "__wrap_main";
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
		(in Local it) {
			// Need to distinguish local names from function names
			writer ~= "__local";
			writeMangledName(writer, mangledNames, it.name);
		},
		(in LowLocalSource.Generated it) {
			writeMangledName(writer, mangledNames, it.name);
			writer ~= it.index;
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
	ref MutMap!(Sym, PrevOrIndex!T) nameToIndex,
	ref MapBuilder!(T*, size_t) toNameIndex,
	immutable T* cur,
	Sym name,
) {
	insertOrUpdate!(Sym, PrevOrIndex!T)(
		alloc,
		nameToIndex,
		name,
		() =>
			PrevOrIndex!T(cur),
		(in PrevOrIndex!T x) =>
			PrevOrIndex!T(x.matchWithPointers!size_t(
				(T* prev) {
					mustAddToMap(alloc, toNameIndex, prev, 0);
					mustAddToMap(alloc, toNameIndex, cur, 1);
					return size_t(2);
				},
				(size_t index) {
					mustAddToMap(alloc, toNameIndex, cur, index);
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
		case sym!"log".value: // defined by tgmath.h
		case sym!"void".value:
		case sym!"while".value:
			return true;
		default:
			return false;
	}
}
