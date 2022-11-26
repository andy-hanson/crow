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
	fullIndexDictEachValue!(LowFunIndex, LowFun)(program.allFuns, (ref immutable LowFun fun) {
		fun.source.matchWithPointers!void(
			(immutable ConcreteFun* cf) {
				cf.source.match!void(
					(ref immutable FunInst i) {
						//TODO: use temp alloc
						addToPrevOrIndex!ConcreteFun(alloc, funNameToIndex, funToNameIndex, cf, i.name);
					},
					(ref immutable ConcreteFunSource.Lambda) {},
					(ref immutable ConcreteFunSource.Test) {});
			},
			(immutable LowFunSource.Generated*) {});
	});

	MutDict!(immutable Sym, immutable PrevOrIndex!ConcreteStruct) structNameToIndex;
	// This will not have an entry for non-overloaded structs.
	DictBuilder!(ConcreteStruct*, size_t) structToNameIndex;

	void build(immutable ConcreteStruct* s) {
		s.source.match!void(
			(immutable ConcreteStructSource.Inst it) {
				addToPrevOrIndex!ConcreteStruct(alloc, structNameToIndex, structToNameIndex, s, name(*it.inst));
			},
			(immutable ConcreteStructSource.Lambda) {});
	}
	fullIndexDictEachValue!(LowType.Extern, LowExternType)(
		program.allExternTypes,
		(ref immutable LowExternType it) {
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
	source.source.match!void(
		(immutable ConcreteStructSource.Inst it) {
			writeMangledName(writer, mangledNames, name(*it.inst));
			maybeWriteIndexSuffix(writer, mangledNames.structToNameIndex[source]);
		},
		(immutable ConcreteStructSource.Lambda it) {
			writeConcreteFunMangledName(writer, mangledNames, it.containingFun);
			writer ~= "__lambda";
			writer ~= it.index;
		});
}

void writeLowFunMangledName(
	scope ref Writer writer,
	scope ref immutable MangledNames mangledNames,
	immutable LowFunIndex funIndex,
	scope ref immutable LowFun fun,
) {
	fun.source.matchWithPointers!void(
		(immutable ConcreteFun* x) {
			writeConcreteFunMangledName(writer, mangledNames, x);
		},
		(immutable LowFunSource.Generated* x) {
			writeMangledName(writer, mangledNames, x.name);
			if (x.name != sym!"main") {
				writer ~= '_';
				writer ~= funIndex.index;
			}
		});
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
	source.source.match!void(
		(ref immutable FunInst it) {
			if (body_(*source).isA!(ConcreteFunBody.Extern))
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
		});
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
	a.source.match!void(
		(ref immutable ConcreteLocal it) {
			// Need to distinguish local names from function names
			writer ~= "__local";
			writeMangledName(writer, mangledNames, it.source.name);
		},
		(ref immutable LowLocalSource.Generated it) {
			writeMangledName(writer, mangledNames, it.name);
			writer ~= it.index;
		});
}

void writeLowParamName(
	scope ref Writer writer,
	scope ref immutable MangledNames mangledNames,
	scope ref immutable LowParam a,
) {
	a.source.match!void(
		(ref immutable ConcreteParam cp) {
			cp.source.match!void(
				(immutable ConcreteParamSource.Closure) {
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
				(immutable ConcreteParamSource.Synthetic it) {
					writer ~= "_p";
					writer ~= force(cp.index);
				});
		},
		(ref immutable LowParamSource.Generated it) {
			writeMangledName(writer, mangledNames, it.name);
		});
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
	writeRecordName(writer, mangledNames, program, pointeeType.as!(LowType.Record));
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
	mixin Union!(immutable T*, immutable size_t);
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
		(ref immutable PrevOrIndex!T x) =>
			immutable PrevOrIndex!T(x.matchWithPointers!(immutable size_t)(
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
