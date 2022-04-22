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
import util.ptr : Ptr;
import util.writer : Writer, writeChar, writeNat, writeStatic, writeWithCommas;
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
		(immutable Ptr!ConcreteFun it) {
			writeConcreteFunName(writer, allSymbols, it.deref());
		},
		(ref immutable LowFunSource.Generated it) {
			writeSym(writer, allSymbols, it.name);
			if (!empty(it.typeArgs)) {
				writeChar(writer, '<');
				writeWithCommas!LowType(writer, it.typeArgs, (scope ref immutable LowType it) {
					writeLowType(writer, allSymbols, lowProgram.allTypes, it);
				});
				writeChar(writer, '>');
			}
			writeStatic(writer, " (generated)");
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
		(immutable Ptr!ConcreteFun it) {
			writeConcreteType(writer, allSymbols, it.deref().returnType);
			writeChar(writer, '(');
			writeWithCommas!ConcreteParam(
				writer,
				it.deref().paramsExcludingCtxAndClosure,
				(scope ref immutable ConcreteParam param) {
					matchConcreteParamSource!void(
						param.source,
						(scope ref immutable ConcreteParamSource.Closure) {
							writeStatic(writer, "<closure>");
						},
						(scope ref immutable Param p) {
							if (has(p.name))
								writeSym(writer, allSymbols, force(p.name));
							else
								writeChar(writer, '_');
						},
						(scope ref immutable ConcreteParamSource.Synthetic) {
							writeChar(writer, '_');
						});
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
	scope ref const AllSymbols allSymbols,
	scope ref immutable AllLowTypes lowTypes,
	scope immutable LowType a,
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
			writeConcreteStruct(writer, allSymbols, lowTypes.allRecords[it].source.deref());
		},
		(immutable LowType.Union it) {
			writeConcreteStruct(writer, allSymbols, lowTypes.allUnions[it].source.deref());
		},
	)(a);
}

private void writeConcreteFunName(ref Writer writer, ref const AllSymbols allSymbols, ref immutable ConcreteFun a) {
	matchConcreteFunSource!(
		void,
		(ref immutable FunInst it) {
			writeSym(writer, allSymbols, name(it));
			if (!empty(typeArgs(it))) {
				writeChar(writer, '<');
				writeWithCommas!Type(writer, typeArgs(it), (ref immutable Type typeArg) {
					writeTypeUnquoted(writer, allSymbols, typeArg);
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

void writeConcreteStruct(
	scope ref Writer writer,
	scope ref const AllSymbols allSymbols,
	scope ref immutable ConcreteStruct a,
) {
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

void writeConcreteType(scope ref Writer writer, scope ref const AllSymbols allSymbols, scope immutable ConcreteType a) {
	//TODO: if it doesn't have the usual by-ref or by-val we should write that
	writeConcreteStruct(writer, allSymbols, a.struct_.deref());
}
