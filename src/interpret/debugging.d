module interpret.debugging;

@safe @nogc pure nothrow:

import model.concreteModel :
	ConcreteFun,
	ConcreteFunSource,
	ConcreteParam,
	ConcreteParamSource,
	ConcreteStruct,
	ConcreteStructSource,
	ConcreteType;
import model.lowModel :
	AllLowTypes, LowFun, LowFunIndex, LowFunSource, LowProgram, LowType, PrimitiveType, symOfPrimitiveType;
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
	a.source.match!void(
		(ref immutable ConcreteFun x) {
			writeConcreteFunName(writer, allSymbols, x);
		},
		(ref immutable LowFunSource.Generated x) {
			writeSym(writer, allSymbols, x.name);
			if (!empty(x.typeArgs)) {
				writer ~= '<';
				writeWithCommas!LowType(writer, x.typeArgs, (scope ref immutable LowType typeArg) {
					writeLowType(writer, allSymbols, lowProgram.allTypes, typeArg);
				});
				writer ~= '>';
			}
			writer ~= " (generated)";
		});
}

void writeFunSig(
	scope ref Writer writer,
	scope ref const AllSymbols allSymbols,
	scope ref immutable LowProgram lowProgram,
	scope ref immutable LowFun a,
) {
	a.source.match!void(
		(ref immutable ConcreteFun x) {
			writeConcreteType(writer, allSymbols, x.returnType);
			writer ~= '(';
			writeWithCommas!ConcreteParam(
				writer,
				x.paramsExcludingClosure,
				(scope ref immutable ConcreteParam param) {
					param.source.match!void(
						(immutable ConcreteParamSource.Closure) {
							writer ~= "<closure>";
						},
						(ref immutable Param p) {
							if (has(p.name))
								writeSym(writer, allSymbols, force(p.name));
							else
								writer ~= '_';
						},
						(immutable ConcreteParamSource.Synthetic) {
							writer ~= '_';
						});
					writer ~= ' ';
					writeConcreteType(writer, allSymbols, param.type);
				});
			writer ~= ')';
		},
		(ref immutable LowFunSource.Generated) {
			writer ~= "(generated)";
		});
}

void writeLowType(
	ref Writer writer,
	scope ref const AllSymbols allSymbols,
	scope ref immutable AllLowTypes lowTypes,
	scope immutable LowType a,
) {
	a.match!void(
		(immutable LowType.Extern) {
			writer ~= "some extern type"; // TODO: more detail
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
		});
}

private void writeConcreteFunName(
	ref Writer writer,
	scope ref const AllSymbols allSymbols,
	ref immutable ConcreteFun a,
) {
	a.source.match!void(
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
		});
}

private:

void writeConcreteStruct(
	scope ref Writer writer,
	scope ref const AllSymbols allSymbols,
	scope ref immutable ConcreteStruct a,
) {
	a.source.match!void(
		(immutable ConcreteStructSource.Inst it) {
			writeSym(writer, allSymbols, decl(*it.inst).name);
			if (!empty(it.typeArgs)) {
				writer ~= '<';
				writeWithCommas!ConcreteType(writer, it.typeArgs, (ref immutable ConcreteType t) {
					writeConcreteType(writer, allSymbols, t);
				});
				writer ~= '>';
			}
		},
		(immutable ConcreteStructSource.Lambda it) {
			writeConcreteFunName(writer, allSymbols, *it.containingFun);
			writer ~= ".lambda";
			writer ~= it.index;
		});
}

void writeConcreteType(scope ref Writer writer, scope ref const AllSymbols allSymbols, scope immutable ConcreteType a) {
	//TODO: if it doesn't have the usual by-ref or by-val we should write that
	writeConcreteStruct(writer, allSymbols, *a.struct_);
}
