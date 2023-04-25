module interpret.debugging;

@safe @nogc pure nothrow:

import model.concreteModel :
	ConcreteFun,
	ConcreteFunSource,
	ConcreteLocal,
	ConcreteLocalSource,
	ConcreteStruct,
	ConcreteStructSource,
	ConcreteType,
	ReferenceKind,
	symOfReferenceKind;
import model.lowModel :
	AllLowTypes, LowFun, LowFunIndex, LowFunSource, LowProgram, LowType, PrimitiveType, symOfPrimitiveType;
import model.model : decl, FunInst, name, Local, Program, typeArgs, writeTypeArgs, writeTypeArgsGeneric;
import util.col.arr : only;
import util.writer : Writer, writeWithCommas;
import util.sym : AllSymbols, writeSym;

void writeFunName(
	scope ref Writer writer,
	in AllSymbols allSymbols,
	in Program program,
	in LowProgram lowProgram,
	LowFunIndex fun,
) {
	writeFunName(writer, allSymbols, program, lowProgram, lowProgram.allFuns[fun]);
}

void writeFunName(
	scope ref Writer writer,
	in AllSymbols allSymbols,
	in Program program,
	in LowProgram lowProgram,
	in LowFun a,
) {
	a.source.matchIn!void(
		(in ConcreteFun x) {
			writeConcreteFunName(writer, allSymbols, program, x);
		},
		(in LowFunSource.Generated x) {
			writeSym(writer, allSymbols, x.name);
			writeLowTypeArgs(writer, allSymbols, program, lowProgram, x.typeArgs);
			writer ~= " (generated)";
		});
}

private void writeLowTypeArgs(
	scope ref Writer writer,
	in AllSymbols allSymbols,
	in Program program,
	in LowProgram lowProgram,
	in LowType[] typeArgs,
) {
	writeTypeArgsGeneric!LowType(writer, typeArgs,
		(in LowType x) => false,
		(in LowType typeArg) {
			writeLowType(writer, allSymbols, program, lowProgram.allTypes, typeArg);
		});
}

void writeFunSig(
	scope ref Writer writer,
	in AllSymbols allSymbols,
	in Program program,
	in LowProgram lowProgram,
	in LowFun a,
) {
	a.source.matchIn!void(
		(in ConcreteFun x) {
			writeConcreteType(writer, allSymbols, program, x.returnType);
			writer ~= '(';
			writeWithCommas!ConcreteLocal(
				writer,
				x.paramsIncludingClosure,
				(in ConcreteLocal param) {
					param.source.matchIn!void(
						(in Local p) {
							writeSym(writer, allSymbols, p.name);
						},
						(in ConcreteLocalSource.Closure) {
							writer ~= "<closure>";
						},
						(in ConcreteLocalSource.Generated x) {
							writeSym(writer, allSymbols, x.name);
						});
					writer ~= ' ';
					writeConcreteType(writer, allSymbols, program, param.type);
				});
			writer ~= ')';
		},
		(in LowFunSource.Generated) {
			writer ~= "(generated)";
		});
}

void writeLowType(
	scope ref Writer writer,
	in AllSymbols allSymbols,
	in Program program,
	in AllLowTypes lowTypes,
	in LowType a,
) {
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
			writeLowType(writer, allSymbols, program, lowTypes, *it.pointee);
			writer ~= ')';
		},
		(in LowType.PtrRawConst it) {
			writer ~= "raw-ptr-const(";
			writeLowType(writer, allSymbols, program, lowTypes, *it.pointee);
			writer ~= ')';
		},
		(in LowType.PtrRawMut it) {
			writer ~= "raw-ptr-mut(";
			writeLowType(writer, allSymbols, program, lowTypes, *it.pointee);
			writer ~= ')';
		},
		(in LowType.Record it) {
			writeConcreteStruct(writer, allSymbols, program, *lowTypes.allRecords[it].source);
		},
		(in LowType.Union it) {
			writeConcreteStruct(writer, allSymbols, program, *lowTypes.allUnions[it].source);
		});
}

void writeConcreteFunName(ref Writer writer, in AllSymbols allSymbols, in Program program, in ConcreteFun a) {
	a.source.matchIn!void(
		(in FunInst it) {
			writeSym(writer, allSymbols, it.name);
			writeTypeArgs(writer, allSymbols, program, typeArgs(it));
		},
		(in ConcreteFunSource.Lambda it) {
			writeConcreteFunName(writer, allSymbols, program, *it.containingFun);
			writer ~= ".lambda";
			writer ~= it.index;
		},
		(in ConcreteFunSource.Test) {
			//TODO: more unique name for each test
			writer ~= "test";
		});
}

private:

void writeConcreteStruct(scope ref Writer writer, in AllSymbols allSymbols, in Program program, in ConcreteStruct a) {
	a.source.matchIn!void(
		(in ConcreteStructSource.Bogus) {
			writer ~= "BOGUS";
		},
		(in ConcreteStructSource.Inst it) {
			switch (it.typeArgs.length) {
				case 0:
					break;
				case 1:
					writeConcreteType(writer, allSymbols, program, only(it.typeArgs));
					writer ~= ' ';
					break;
				default:
					writer ~= '(';
					writeWithCommas!ConcreteType(writer, it.typeArgs, (in ConcreteType x) {
						writeConcreteType(writer, allSymbols, program, x);
					});
					writer ~= ") ";
			}
			writeSym(writer, allSymbols, decl(*it.inst).name);
		},
		(in ConcreteStructSource.Lambda it) {
			writeConcreteFunName(writer, allSymbols, program, *it.containingFun);
			writer ~= ".lambda";
			writer ~= it.index;
		});
}

public void writeConcreteType(
	scope ref Writer writer,
	in AllSymbols allSymbols,
	in Program program,
	in ConcreteType a,
) {
	writeConcreteStruct(writer, allSymbols, program, *a.struct_);
	if (a.reference != ReferenceKind.byVal) {
		writer ~= ' ';
		writeSym(writer, allSymbols, symOfReferenceKind(a.reference));
	}
}
