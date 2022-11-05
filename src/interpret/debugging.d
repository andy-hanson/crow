module interpret.debugging;

@safe @nogc pure nothrow:

import model.concreteModel :
	ConcreteFun,
	ConcreteFunSource,
	ConcreteParam,
	ConcreteParamSource,
	ConcreteStruct,
	ConcreteStructSource,
	ConcreteType,
	matchConcreteFunSource,
	matchConcreteParamSource,
	matchConcreteStructSource;
import model.lowModel :
	AllLowTypes,
	LowFun,
	LowFunIndex,
	LowFunSource,
	LowProgram,
	LowType,
	matchLowFunSource,
	matchLowType,
	PrimitiveType,
	symOfPrimitiveType;
import model.model : decl, FunInst, name, Param, Type, typeArgs, writeTypeUnquoted;
import util.col.arr : empty;
import util.opt : force, has;
import util.writer : Writer, writeWithCommas;
import util.sym : AllSymbols, writeSym;

void writeFunName(
	ref Writer writer,
	scope ref const AllSymbols allSymbols,
	scope ref immutable LowProgram lowProgram,
	immutable LowFunIndex fun,
) {
	writeFunName(writer, allSymbols, lowProgram, lowProgram.allFuns[fun]);
}

void writeFunName(
	ref Writer writer,
	scope ref const AllSymbols allSymbols,
	scope ref immutable LowProgram lowProgram,
	scope ref immutable LowFun a,
) {
	matchLowFunSource!(
		void,
		(immutable ConcreteFun* it) {
			writeConcreteFunName(writer, allSymbols, *it);
		},
		(ref immutable LowFunSource.Generated it) {
			writeSym(writer, allSymbols, it.name);
			if (!empty(it.typeArgs)) {
				writer ~= '<';
				writeWithCommas!LowType(writer, it.typeArgs, (scope ref immutable LowType it) {
					writeLowType(writer, allSymbols, lowProgram.allTypes, it);
				});
				writer ~= '>';
			}
			writer ~= " (generated)";
		},
	)(a.source);
}

void writeFunSig(
	scope ref Writer writer,
	scope ref const AllSymbols allSymbols,
	scope ref immutable LowProgram lowProgram,
	scope ref immutable LowFun a,
) {
	matchLowFunSource!(
		void,
		(immutable ConcreteFun* it) {
			writeConcreteType(writer, allSymbols, it.returnType);
			writer ~= '(';
			writeWithCommas!ConcreteParam(
				writer,
				it.paramsExcludingClosure,
				(scope ref immutable ConcreteParam param) {
					matchConcreteParamSource!void(
						param.source,
						(scope ref immutable ConcreteParamSource.Closure) {
							writer ~= "<closure>";
						},
						(scope ref immutable Param p) {
							if (has(p.name))
								writeSym(writer, allSymbols, force(p.name));
							else
								writer ~= '_';
						},
						(scope ref immutable ConcreteParamSource.Synthetic) {
							writer ~= '_';
						});
					writer ~= ' ';
					writeConcreteType(writer, allSymbols, param.type);
				});
			writer ~= ')';
		},
		(ref immutable LowFunSource.Generated) {
			writer ~= "(generated)";
		},
	)(a.source);
}

void writeLowType(
	ref Writer writer,
	scope ref const AllSymbols allSymbols,
	scope ref immutable AllLowTypes lowTypes,
	scope immutable LowType a,
) {
	matchLowType!(
		void,
		(immutable LowType.ExternPtr) {
			writer ~= "some extern-pointer type"; // TODO: more detail
		},
		(immutable LowType.FunPtr) {
			writer ~= "some fun ptr type"; // TODO: more detail
		},
		(immutable PrimitiveType it) {
			writeSym(writer, allSymbols, symOfPrimitiveType(it));
		},
		(immutable LowType.PtrGc it) {
			writer ~= "gc-ptr(";
			writeLowType(writer, allSymbols, lowTypes, *it.pointee);
			writer ~= ')';
		},
		(immutable LowType.PtrRawConst it) {
			writer ~= "raw-ptr-const(";
			writeLowType(writer, allSymbols, lowTypes, *it.pointee);
			writer ~= ')';
		},
		(immutable LowType.PtrRawMut it) {
			writer ~= "raw-ptr-mut(";
			writeLowType(writer, allSymbols, lowTypes, *it.pointee);
			writer ~= ')';
		},
		(immutable LowType.Record it) {
			writeConcreteStruct(writer, allSymbols, *lowTypes.allRecords[it].source);
		},
		(immutable LowType.Union it) {
			writeConcreteStruct(writer, allSymbols, *lowTypes.allUnions[it].source);
		},
	)(a);
}

private void writeConcreteFunName(ref Writer writer, ref const AllSymbols allSymbols, ref immutable ConcreteFun a) {
	matchConcreteFunSource!(
		void,
		(ref immutable FunInst it) {
			writeSym(writer, allSymbols, it.name);
			if (!empty(typeArgs(it))) {
				writer ~= '<';
				writeWithCommas!Type(writer, typeArgs(it), (ref immutable Type typeArg) {
					writeTypeUnquoted(writer, allSymbols, typeArg);
				});
				writer ~= '>';
			}
		},
		(ref immutable ConcreteFunSource.Lambda it) {
			writeConcreteFunName(writer, allSymbols, *it.containingFun);
			writer ~= ".lambda";
			writer ~= it.index;
		},
		(ref immutable(ConcreteFunSource.Test)) {
			//TODO: more unique name for each test
			writer ~= "test";
		},
	)(a.source);
}

private:

void writeConcreteStruct(
	scope ref Writer writer,
	scope ref const AllSymbols allSymbols,
	scope ref immutable ConcreteStruct a,
) {
	matchConcreteStructSource!(
		void,
		(ref immutable ConcreteStructSource.Inst it) {
			writeSym(writer, allSymbols, decl(*it.inst).name);
			if (!empty(it.typeArgs)) {
				writer ~= '<';
				writeWithCommas!ConcreteType(writer, it.typeArgs, (ref immutable ConcreteType t) {
					writeConcreteType(writer, allSymbols, t);
				});
				writer ~= '>';
			}
		},
		(ref immutable ConcreteStructSource.Lambda it) {
			writeConcreteFunName(writer, allSymbols, *it.containingFun);
			writer ~= ".lambda";
			writer ~= it.index;
		},
	)(a.source);
}

void writeConcreteType(scope ref Writer writer, scope ref const AllSymbols allSymbols, scope immutable ConcreteType a) {
	//TODO: if it doesn't have the usual by-ref or by-val we should write that
	writeConcreteStruct(writer, allSymbols, *a.struct_);
}
