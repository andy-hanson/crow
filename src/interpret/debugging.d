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
import frontend.showDiag : ShowDiagCtx, writeTypeArgs, writeTypeArgsGeneric;
import model.lowModel :
	AllLowTypes, LowFun, LowFunIndex, LowFunSource, LowProgram, LowType, PrimitiveType, symOfPrimitiveType;
import model.model : decl, FunInst, name, Local, typeArgs;
import util.col.arr : only;
import util.writer : Writer, writeWithCommas;
import util.sym : writeSym;

void writeFunName(ref Writer writer, ref ShowDiagCtx ctx, in LowProgram lowProgram, LowFunIndex fun) {
	writeFunName(writer, ctx, lowProgram, lowProgram.allFuns[fun]);
}

void writeFunName(ref Writer writer, ref ShowDiagCtx ctx, in LowProgram lowProgram, in LowFun a) {
	a.source.matchIn!void(
		(in ConcreteFun x) {
			writeConcreteFunName(writer, ctx, x);
		},
		(in LowFunSource.Generated x) {
			writeSym(writer, ctx.allSymbols, x.name);
			writeLowTypeArgs(writer, ctx, lowProgram, x.typeArgs);
			writer ~= " (generated)";
		});
}

private void writeLowTypeArgs(ref Writer writer, ref ShowDiagCtx ctx, in LowProgram lowProgram, in LowType[] typeArgs) {
	writeTypeArgsGeneric!LowType(writer, typeArgs,
		(in LowType x) => false,
		(in LowType typeArg) {
			writeLowType(writer, ctx, lowProgram.allTypes, typeArg);
		});
}

void writeFunSig(scope ref Writer writer, ref ShowDiagCtx ctx, in LowProgram lowProgram, in LowFun a) {
	a.source.matchIn!void(
		(in ConcreteFun x) {
			writeConcreteType(writer, ctx, x.returnType);
			writer ~= '(';
			writeWithCommas!ConcreteLocal(
				writer,
				x.paramsIncludingClosure,
				(in ConcreteLocal param) {
					param.source.matchIn!void(
						(in Local p) {
							writeSym(writer, ctx.allSymbols, p.name);
						},
						(in ConcreteLocalSource.Closure) {
							writer ~= "<closure>";
						},
						(in ConcreteLocalSource.Generated x) {
							writeSym(writer, ctx.allSymbols, x.name);
						});
					writer ~= ' ';
					writeConcreteType(writer, ctx, param.type);
				});
			writer ~= ')';
		},
		(in LowFunSource.Generated) {
			writer ~= "(generated)";
		});
}

void writeLowType(scope ref Writer writer, ref ShowDiagCtx ctx, in AllLowTypes lowTypes, in LowType a) {
	a.matchIn!void(
		(in LowType.Extern) {
			writer ~= "some extern type"; // TODO: more detail
		},
		(in LowType.FunPtr) {
			writer ~= "some fun ptr type"; // TODO: more detail
		},
		(in PrimitiveType x) {
			writeSym(writer, ctx.allSymbols, symOfPrimitiveType(x));
		},
		(in LowType.PtrGc x) {
			writer ~= "gc-ptr(";
			writeLowType(writer, ctx, lowTypes, *x.pointee);
			writer ~= ')';
		},
		(in LowType.PtrRawConst x) {
			writer ~= "raw-ptr-const(";
			writeLowType(writer, ctx, lowTypes, *x.pointee);
			writer ~= ')';
		},
		(in LowType.PtrRawMut x) {
			writer ~= "raw-ptr-mut(";
			writeLowType(writer, ctx, lowTypes, *x.pointee);
			writer ~= ')';
		},
		(in LowType.Record x) {
			writeConcreteStruct(writer, ctx, *lowTypes.allRecords[x].source);
		},
		(in LowType.Union x) {
			writeConcreteStruct(writer, ctx, *lowTypes.allUnions[x].source);
		});
}

void writeConcreteFunName(scope ref Writer writer, ref ShowDiagCtx ctx, in ConcreteFun a) {
	a.source.matchIn!void(
		(in FunInst it) {
			writeSym(writer, ctx.allSymbols, it.name);
			writeTypeArgs(writer, ctx, typeArgs(it));
		},
		(in ConcreteFunSource.Lambda it) {
			writeConcreteFunName(writer, ctx, *it.containingFun);
			writer ~= ".lambda";
			writer ~= it.index;
		},
		(in ConcreteFunSource.Test) {
			//TODO: more unique name for each test
			writer ~= "test";
		},
		(in ConcreteFunSource.WrapMain) {
			writer ~= "wrap-main";
		});
}

void writeConcreteType(scope ref Writer writer, ref ShowDiagCtx ctx, in ConcreteType a) {
	writeConcreteStruct(writer, ctx, *a.struct_);
	if (a.reference != ReferenceKind.byVal) {
		writer ~= ' ';
		writeSym(writer, ctx.allSymbols, symOfReferenceKind(a.reference));
	}
}

private:

void writeConcreteStruct(scope ref Writer writer, ref ShowDiagCtx ctx, in ConcreteStruct a) {
	a.source.matchIn!void(
		(in ConcreteStructSource.Bogus) {
			writer ~= "BOGUS";
		},
		(in ConcreteStructSource.Inst x) {
			switch (x.typeArgs.length) {
				case 0:
					break;
				case 1:
					writeConcreteType(writer, ctx, only(x.typeArgs));
					writer ~= ' ';
					break;
				default:
					writer ~= '(';
					writeWithCommas!ConcreteType(writer, x.typeArgs, (in ConcreteType arg) {
						writeConcreteType(writer, ctx, arg);
					});
					writer ~= ") ";
			}
			writeSym(writer, ctx.allSymbols, decl(*x.inst).name);
		},
		(in ConcreteStructSource.Lambda x) {
			writeConcreteFunName(writer, ctx, *x.containingFun);
			writer ~= ".lambda";
			writer ~= x.index;
		});
}
