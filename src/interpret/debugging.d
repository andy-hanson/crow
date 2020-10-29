module interpret.debugging;

@safe @nogc pure nothrow:

import concreteModel :
	ConcreteFun,
	ConcreteFunSource,
	ConcreteLocal,
	ConcreteLocalSource,
	ConcreteStruct,
	ConcreteStructSource,
	ConcreteType,
	matchConcreteFieldSource,
	matchConcreteFunSource,
	matchConcreteLocalSource,
	matchConcreteStructSource;
import lowModel : LowFun, LowFunIndex, LowFunSource, LowProgram, LowType, matchLowFunSource;
import model : ClosureField, FunInst, name, RecordField;
import util.collection.arr : empty;
import util.collection.fullIndexDict : fullIndexDictGet;
import util.ptr : Ptr;
import util.writer : finishWriterToCStr, Writer, writeChar, writeNat, writeStatic;
import util.sym : writeSym;

void writeFunName(Alloc)(ref Writer!Alloc writer, ref immutable LowProgram lowProgram, immutable LowFunIndex fun) {
	writeFunName(writer, fullIndexDictGet(lowProgram.allFuns, fun));
}

void writeFunName(Alloc)(ref Writer!Alloc writer, ref immutable LowFun a) {
	matchLowFunSource!void(
		a.source,
		(immutable Ptr!ConcreteFun it) {
			writeConcreteFunName(writer, it);
		},
		(ref immutable LowFunSource.Generated it) {
			writeSym(writer, it.name);
			writeStatic(writer, " (generated)");
		});
}

void writeConcreteFunName(Alloc)(ref Writer!Alloc writer, ref immutable ConcreteFun a) {
	matchConcreteFunSource!void(
		a.source,
		(immutable Ptr!FunInst it) =>
			writeSym(writer, name(it)),
		(ref immutable ConcreteFunSource.Lambda it) {
			writeConcreteFunName(writer, it.containingFun);
			writeStatic(writer, ".lambda");
			writeNat(writer, it.index);
		});
}

void writeRecordName(Alloc)(ref Writer!Alloc writer, ref immutable LowRecord a) {
	writeConcreteStruct(writer, a.source);
}

void writeType(Alloc)(ref Writer!Alloc writer, ref immutable LowProgram program, ref immutable LowType a) {
	matchLowType(
		a,
		(immutable LowType.ExternPtr) {
			todo!void("!");
		},
		(immutable LowType.FunPtr) {
			todo!void("!");
		},
		(immutable LowType.NonFunPtr) {
			todo!void("!");
		},
		(immutable PrimitiveType) {
			todo!void("!");
		},
		(immutable LowType.Record it) {
			writeConcreteStruct(writer, fullIndexDictGet(program.allRecords, it).source);
		},
		(immutable LowType.Union) {
			todo!void("!");
		});
}

void writeConcreteStruct(Alloc)(ref Writer!Alloc writer, ref immutable ConcreteStruct a) {
	matchConcreteStructSource!void(
		a.source,
		(ref immutable ConcreteStructSource.Inst it) {
			writeSym(writer, decl(it.inst).name);
			if (!empty(it.typeArgs)) {
				writeChar(writer, '<');
				foreach (ref immutable ConcreteType t; range(it.typeArgs))
					writeConcreteType(writer, t);
				writeChar(writer, '>');
			}
		},
		(ref immutable ConcreteStructSource.Lambda it) {
			writeConcreteFunName(writer, it.containingFun);
			writeStatic(writer, ".lambda");
			writeNat(writer, it.index);
		});
}

void writeConcreteType(Alloc)(ref Writer!Alloc writer, ref immutable ConcreteType a) {
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
