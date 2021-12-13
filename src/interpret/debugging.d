module interpret.debugging;

@safe @nogc pure nothrow:

import model.concreteModel :
	ConcreteFun,
	ConcreteFunSource,
	ConcreteLocal,
	ConcreteParam,
	ConcreteParamSource,
	ConcreteStruct,
	ConcreteStructSource,
	ConcreteType,
	matchConcreteFieldSource,
	matchConcreteFunSource,
	matchConcreteParamSource,
	matchConcreteStructSource;
import model.lowModel :
	AllLowTypes,
	LowField,
	LowFun,
	LowFunIndex,
	LowFunSource,
	LowLocal,
	LowLocalSource,
	LowProgram,
	LowType,
	matchLowFunSource,
	matchLowLocalSource,
	matchLowType,
	PrimitiveType,
	symOfPrimitiveType;
import model.model : ClosureField, decl, FunInst, name, Param, RecordField, Type, typeArgs, writeType;
import util.collection.arr : empty;
import util.collection.fullIndexDict : fullIndexDictGet;
import util.opt : force, has;
import util.ptr : Ptr;
import util.writer : Writer, writeChar, writeNat, writeStatic, writeWithCommas;
import util.sym : AllSymbols, writeSym;

void writeFunName(
	ref Writer writer,
	ref const AllSymbols allSymbols,
	ref immutable LowProgram lowProgram,
	immutable LowFunIndex fun,
) {
	writeFunName(writer, allSymbols, lowProgram, fullIndexDictGet(lowProgram.allFuns, fun));
}

void writeFunName(
	ref Writer writer,
	ref const AllSymbols allSymbols,
	ref immutable LowProgram lowProgram,
	ref immutable LowFun a,
) {
	matchLowFunSource!(
		void,
		(immutable Ptr!ConcreteFun it) {
			writeConcreteFunName(writer, allSymbols, it.deref());
		},
		(ref immutable LowFunSource.Generated it) {
			writeSym(writer, allSymbols, it.name);
			if (!empty(it.typeArgs)) {
				writeChar(writer, '<');
				writeWithCommas!LowType(writer, it.typeArgs, (ref immutable LowType it) {
					writeLowType(writer, allSymbols, lowProgram.allTypes, it);
				});
				writeChar(writer, '>');
			}
			writeStatic(writer, " (generated)");
		},
	)(a.source);
}

void writeFunSig(
	ref Writer writer,
	ref const AllSymbols allSymbols,
	ref immutable LowProgram lowProgram,
	ref immutable LowFun a,
) {
	matchLowFunSource!(
		void,
		(immutable Ptr!ConcreteFun it) {
			writeConcreteType(writer, allSymbols, it.deref().returnType);
			writeChar(writer, '(');
			writeWithCommas!ConcreteParam(
				writer,
				it.deref().paramsExcludingCtxAndClosure,
				(ref immutable ConcreteParam param) {
					matchConcreteParamSource!(
						void,
						(ref immutable ConcreteParamSource.Closure) {
							writeStatic(writer, "<closure>");
						},
						(ref immutable Param p) {
							if (has(p.name))
								writeSym(writer, allSymbols, force(p.name));
							else
								writeChar(writer, '_');
						},
					)(param.source);
					writeChar(writer, ' ');
					writeConcreteType(writer, allSymbols, param.type);
				});
			writeChar(writer, ')');
		},
		(ref immutable LowFunSource.Generated) {
			writeStatic(writer, "(generated)");
		},
	)(a.source);
}

void writeLowType(
	ref Writer writer,
	ref const AllSymbols allSymbols,
	ref immutable AllLowTypes lowTypes,
	ref immutable LowType a,
) {
	matchLowType!(
		void,
		(immutable LowType.ExternPtr) {
			writeStatic(writer, "some extern-ptr type"); // TODO: more detail
		},
		(immutable LowType.FunPtr) {
			writeStatic(writer, "some fun ptr type"); // TODO: more detail
		},
		(immutable PrimitiveType it) {
			writeSym(writer, allSymbols, symOfPrimitiveType(it));
		},
		(immutable LowType.PtrGc it) {
			writeStatic(writer, "gc-ptr(");
			writeLowType(writer, allSymbols, lowTypes, it.pointee.deref());
			writeChar(writer, ')');
		},
		(immutable LowType.PtrRawConst it) {
			writeStatic(writer, "raw-ptr-const(");
			writeLowType(writer, allSymbols, lowTypes, it.pointee.deref());
			writeChar(writer, ')');
		},
		(immutable LowType.PtrRawMut it) {
			writeStatic(writer, "raw-ptr-mut(");
			writeLowType(writer, allSymbols, lowTypes, it.pointee.deref());
			writeChar(writer, ')');
		},
		(immutable LowType.Record it) {
			writeConcreteStruct(writer, allSymbols, fullIndexDictGet(lowTypes.allRecords, it).source.deref());
		},
		(immutable LowType.Union it) {
			writeConcreteStruct(writer, allSymbols, fullIndexDictGet(lowTypes.allUnions, it).source.deref());
		},
	)(a);
}

void writeConcreteFunName(ref Writer writer, ref const AllSymbols allSymbols, ref immutable ConcreteFun a) {
	matchConcreteFunSource!(
		void,
		(ref immutable FunInst it) {
			writeSym(writer, allSymbols, name(it));
			if (!empty(typeArgs(it))) {
				writeChar(writer, '<');
				writeWithCommas!Type(writer, typeArgs(it), (ref immutable Type typeArg) {
					writeType(writer, allSymbols, typeArg);
				});
				writeChar(writer, '>');
			}
		},
		(ref immutable ConcreteFunSource.Lambda it) {
			writeConcreteFunName(writer, allSymbols, it.containingFun.deref());
			writeStatic(writer, ".lambda");
			writeNat(writer, it.index);
		},
		(ref immutable(ConcreteFunSource.Test)) {
			//TODO: more unique name for each test
			writeStatic(writer, "test");
		},
	)(a.source);
}

private:

void writeConcreteStruct(ref Writer writer, ref const AllSymbols allSymbols, ref immutable ConcreteStruct a) {
	matchConcreteStructSource!(
		void,
		(ref immutable ConcreteStructSource.Inst it) {
			writeSym(writer, allSymbols, decl(it.inst.deref()).deref().name);
			if (!empty(it.typeArgs)) {
				writeChar(writer, '<');
				writeWithCommas!ConcreteType(writer, it.typeArgs, (ref immutable ConcreteType t) {
					writeConcreteType(writer, allSymbols, t);
				});
				writeChar(writer, '>');
			}
		},
		(ref immutable ConcreteStructSource.Lambda it) {
			writeConcreteFunName(writer, allSymbols, it.containingFun.deref());
			writeStatic(writer, ".lambda");
			writeNat(writer, it.index);
		},
	)(a.source);
}

void writeConcreteType(ref Writer writer, ref const AllSymbols allSymbols, immutable ConcreteType a) {
	//TODO: if it doesn't have the usual by-ref or by-val we should write that
	writeConcreteStruct(writer, allSymbols, a.struct_.deref());
}

void writeFieldName(ref Writer writer, ref const AllSymbols allSymbols, ref immutable LowField a) {
	matchConcreteFieldSource!(
		void,
		(immutable Ptr!ClosureField it) {
			writeSym(writer, allSymbols, it.deref().name);
		},
		(immutable Ptr!RecordField it) {
			writeSym(writer, allSymbols, it.deref().name);
		},
	)(a.source.deref().source);
}

void writeLocalName(ref Writer writer, ref const AllSymbols allSymbols, ref immutable LowLocal a) {
	matchLowLocalSource!(
		void,
		(ref immutable ConcreteLocal it) {
			writeSym(writer, allSymbols, it.source.deref().name);
		},
		(ref immutable LowLocalSource.Generated) {
			writeStatic(writer, "<<generated>>");
		},
	)(a.source);
}
