module interpret.debugging;

@safe @nogc pure nothrow:

import model.concreteModel :
	ConcreteFun,
	ConcreteFunSource,
	ConcreteLocal,
	ConcreteLocalSource,
	ConcreteParam,
	ConcreteParamSource,
	ConcreteStruct,
	ConcreteStructSource,
	ConcreteType,
	matchConcreteFieldSource,
	matchConcreteFunSource,
	matchConcreteLocalSource,
	matchConcreteParamSource,
	matchConcreteStructSource;
import model.lowModel :
	AllLowTypes,
	LowField,
	LowFun,
	LowFunIndex,
	LowFunSource,
	LowProgram,
	LowType,
	matchLowFunSource,
	matchLowType,
	PrimitiveType,
	symOfPrimitiveType;
import model.model : ClosureField, decl, FunInst, name, Param, RecordField, Type, typeArgs, writeType;
import util.collection.arr : empty;
import util.collection.fullIndexDict : fullIndexDictGet;
import util.opt : force, has;
import util.ptr : Ptr;
import util.writer : Writer, writeChar, writeNat, writeStatic, writeWithCommas;
import util.sym : writeSym;
import util.util : todo;

void writeFunName(Alloc)(ref Writer!Alloc writer, ref immutable LowProgram lowProgram, immutable LowFunIndex fun) {
	writeFunName(writer, lowProgram, fullIndexDictGet(lowProgram.allFuns, fun));
}

void writeFunName(Alloc)(ref Writer!Alloc writer, ref immutable LowProgram lowProgram, ref immutable LowFun a) {
	matchLowFunSource!void(
		a.source,
		(immutable Ptr!ConcreteFun it) {
			writeConcreteFunName(writer, it);
		},
		(ref immutable LowFunSource.Generated it) {
			writeSym(writer, it.name);
			if (!empty(it.typeArgs)) {
				writeChar(writer, '<');
				writeWithCommas!(LowType, Alloc)(writer, it.typeArgs, (ref immutable LowType it) {
					writeLowType(writer, lowProgram.allTypes, it);
				});
				writeChar(writer, '>');
			}
			writeStatic(writer, " (generated)");
		});
}

void writeFunSig(Alloc)(ref Writer!Alloc writer, ref immutable LowProgram lowProgram, ref immutable LowFun a) {
	matchLowFunSource!void(
		a.source,
		(immutable Ptr!ConcreteFun it) {
			writeConcreteType!Alloc(writer, it.returnType);
			writeChar(writer, '(');
			writeWithCommas!(ConcreteParam, Alloc)(
				writer,
				it.paramsExcludingCtxAndClosure(),
				(ref immutable ConcreteParam param) {
					matchConcreteParamSource!void(
						param.source,
						(ref immutable ConcreteParamSource.Closure) {
							writeStatic(writer, "<closure>");
						},
						(immutable Ptr!Param p) {
							if (has(p.name))
								writeSym(writer, force(p.name));
							else
								writeChar(writer, '_');
						});
				writeChar(writer, ' ');
				writeConcreteType(writer, param.type);
			});
			writeChar(writer, ')');
		},
		(ref immutable LowFunSource.Generated) {
			writeStatic(writer, "(generated)");
		});
}

void writeLowType(Alloc)(ref Writer!Alloc writer, ref immutable AllLowTypes lowTypes, ref immutable LowType a) {
	matchLowType!void(
		a,
		(immutable LowType.ExternPtr) {
			todo!void("write ExternPtr type");
		},
		(immutable LowType.FunPtr) {
			writeStatic(writer, "some fun ptr type"); // TODO: more detail
		},
		(immutable PrimitiveType it) {
			writeSym(writer, symOfPrimitiveType(it));
		},
		(immutable LowType.PtrGc it) {
			writeStatic(writer, "gc-ptr(");
			writeLowType(writer, lowTypes, it.pointee);
			writeChar(writer, ')');
		},
		(immutable LowType.PtrRaw it) {
			writeStatic(writer, "raw-ptr(");
			writeLowType(writer, lowTypes, it.pointee);
			writeChar(writer, ')');
		},
		(immutable LowType.Record it) {
			writeConcreteStruct(writer, fullIndexDictGet(lowTypes.allRecords, it).source);
		},
		(immutable LowType.Union it) {
			writeConcreteStruct(writer, fullIndexDictGet(lowTypes.allUnions, it).source);
		});
}

void writeConcreteFunName(Alloc)(ref Writer!Alloc writer, ref immutable ConcreteFun a) {
	matchConcreteFunSource!void(
		a.source,
		(immutable Ptr!FunInst it) {
			writeSym(writer, name(it));
			if (!empty(typeArgs(it))) {
				writeChar(writer, '<');
				writeWithCommas!(Type, Alloc)(writer, typeArgs(it), (ref immutable Type typeArg) {
					writeType(writer, typeArg);
				});
				writeChar(writer, '>');
			}
		},
		(ref immutable ConcreteFunSource.Lambda it) {
			writeConcreteFunName(writer, it.containingFun);
			writeStatic(writer, ".lambda");
			writeNat(writer, it.index);
		},
		(ref immutable(ConcreteFunSource.Test)) {
			todo!void("!");
		});
}

private:

void writeRecordName(Alloc)(ref Writer!Alloc writer, ref immutable LowRecord a) {
	writeConcreteStruct(writer, a.source);
}

void writeConcreteStruct(Alloc)(ref Writer!Alloc writer, ref immutable ConcreteStruct a) {
	matchConcreteStructSource!void(
		a.source,
		(ref immutable ConcreteStructSource.Inst it) {
			writeSym(writer, decl(it.inst).name);
			if (!empty(it.typeArgs)) {
				writeChar(writer, '<');
				writeWithCommas!(ConcreteType, Alloc)(writer, it.typeArgs, (ref immutable ConcreteType t) {
					writeConcreteType(writer, t);
				});
				writeChar(writer, '>');
			}
		},
		(ref immutable ConcreteStructSource.Lambda it) {
			writeConcreteFunName(writer, it.containingFun);
			writeStatic(writer, ".lambda");
			writeNat(writer, it.index);
		});
}

void writeConcreteType(Alloc)(ref Writer!Alloc writer, immutable ConcreteType a) {
	//TODO: if it doesn't have the usual by-ref or by-val we should write that
	writeConcreteStruct(writer, a.struct_);
}

void writeFieldName(Alloc)(ref Writer!Alloc writer, ref immutable LowField a) {
	matchConcreteFieldSource!void(
		a.source.source,
		(immutable Ptr!ClosureField it) {
			writeSym(writer, it.name);
		},
		(immutable Ptr!RecordField it) {
			writeSym(writer, it.name);
		});
}

void writeLocalName(Alloc)(ref Writer!Alloc writer, ref immutable LowLocal a) {
	matchLowLocalSource!void(
		a.source,
		(immutable Ptr!ConcreteLocal it) {
			matchConcreteLocalSource!void(
				it.source,
				(ref immutable ConcreteLocalSource.Arr) {
					writeStatic(writer, "<<arr>>");
				},
				(immutable Ptr!Local it) {
					writeSym(writer, it.name);
				},
				(ref immutable ConcreteLocalSource.Matched) {
					writeStatic(writer, "<<matched>>");
				});
		},
		(ref immutable LowLocalSource.Generated) {
			writeStatic(writer, "<<generated>>");
		});
}
