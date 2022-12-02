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

void writeFunName(ref Writer writer, in AllSymbols allSymbols, in LowProgram lowProgram, LowFunIndex fun) {
	writeFunName(writer, allSymbols, lowProgram, lowProgram.allFuns[fun]);
}

void writeFunName(ref Writer writer, in AllSymbols allSymbols, in LowProgram lowProgram, in LowFun a) {
	a.source.matchIn!void(
		(in ConcreteFun x) {
			writeConcreteFunName(writer, allSymbols, x);
		},
		(in LowFunSource.Generated x) {
			writeSym(writer, allSymbols, x.name);
			if (!empty(x.typeArgs)) {
				writer ~= '<';
				writeWithCommas!LowType(writer, x.typeArgs, (in LowType typeArg) {
					writeLowType(writer, allSymbols, lowProgram.allTypes, typeArg);
				});
				writer ~= '>';
			}
			writer ~= " (generated)";
		});
}

void writeFunSig(scope ref Writer writer, in AllSymbols allSymbols, in LowProgram lowProgram, in LowFun a) {
	a.source.matchIn!void(
		(in ConcreteFun x) {
			writeConcreteType(writer, allSymbols, x.returnType);
			writer ~= '(';
			writeWithCommas!ConcreteParam(
				writer,
				x.paramsExcludingClosure,
				(in ConcreteParam param) {
					param.source.matchIn!void(
						(in ConcreteParamSource.Closure) {
							writer ~= "<closure>";
						},
						(in Param p) {
							if (has(p.name))
								writeSym(writer, allSymbols, force(p.name));
							else
								writer ~= '_';
						},
						(in ConcreteParamSource.Synthetic) {
							writer ~= '_';
						});
					writer ~= ' ';
					writeConcreteType(writer, allSymbols, param.type);
				});
			writer ~= ')';
		},
		(in LowFunSource.Generated) {
			writer ~= "(generated)";
		});
}

void writeLowType(ref Writer writer, in AllSymbols allSymbols, in AllLowTypes lowTypes, in LowType a) {
	a.matchIn!void(
		(in LowType.Extern) {
			writer ~= "some extern type"; // TODO: more detail
		},
		(in LowType.FunPtr) {
			writer ~= "some fun ptr type"; // TODO: more detail
		},
		(in PrimitiveType it) {
			writeSym(writer, allSymbols, symOfPrimitiveType(it));
		},
		(in LowType.PtrGc it) {
			writer ~= "gc-ptr(";
			writeLowType(writer, allSymbols, lowTypes, *it.pointee);
			writer ~= ')';
		},
		(in LowType.PtrRawConst it) {
			writer ~= "raw-ptr-const(";
			writeLowType(writer, allSymbols, lowTypes, *it.pointee);
			writer ~= ')';
		},
		(in LowType.PtrRawMut it) {
			writer ~= "raw-ptr-mut(";
			writeLowType(writer, allSymbols, lowTypes, *it.pointee);
			writer ~= ')';
		},
		(in LowType.Record it) {
			writeConcreteStruct(writer, allSymbols, *lowTypes.allRecords[it].source);
		},
		(in LowType.Union it) {
			writeConcreteStruct(writer, allSymbols, *lowTypes.allUnions[it].source);
		});
}

private void writeConcreteFunName(ref Writer writer, in AllSymbols allSymbols, in ConcreteFun a) {
	a.source.matchIn!void(
		(in FunInst it) {
			writeSym(writer, allSymbols, it.name);
			if (!empty(typeArgs(it))) {
				writer ~= '<';
				writeWithCommas!Type(writer, typeArgs(it), (in Type typeArg) {
					writeTypeUnquoted(writer, allSymbols, typeArg);
				});
				writer ~= '>';
			}
		},
		(in ConcreteFunSource.Lambda it) {
			writeConcreteFunName(writer, allSymbols, *it.containingFun);
			writer ~= ".lambda";
			writer ~= it.index;
		},
		(in ConcreteFunSource.Test) {
			//TODO: more unique name for each test
			writer ~= "test";
		});
}

private:

void writeConcreteStruct(scope ref Writer writer, in AllSymbols allSymbols, in ConcreteStruct a) {
	a.source.matchIn!void(
		(in ConcreteStructSource.Inst it) {
			writeSym(writer, allSymbols, decl(*it.inst).name);
			if (!empty(it.typeArgs)) {
				writer ~= '<';
				writeWithCommas!ConcreteType(writer, it.typeArgs, (in ConcreteType t) {
					writeConcreteType(writer, allSymbols, t);
				});
				writer ~= '>';
			}
		},
		(in ConcreteStructSource.Lambda it) {
			writeConcreteFunName(writer, allSymbols, *it.containingFun);
			writer ~= ".lambda";
			writer ~= it.index;
		});
}

void writeConcreteType(scope ref Writer writer, in AllSymbols allSymbols, in ConcreteType a) {
	//TODO: if it doesn't have the usual by-ref or by-val we should write that
	writeConcreteStruct(writer, allSymbols, *a.struct_);
}
