module model.showLowModel;

@safe @nogc pure nothrow:

import model.concreteModel :
	ConcreteFun,
	ConcreteFunKey,
	ConcreteFunSource,
	ConcreteLocal,
	ConcreteLocalSource,
	ConcreteStruct,
	ConcreteStructSource,
	ConcreteType,
	ReferenceKind;
import frontend.showModel : ShowCtx, writeTypeArgsGeneric;
import model.lowModel :
	AllLowTypes, LowFun, LowFunIndex, LowFunSource, LowProgram, LowType, PrimitiveType;
import model.model : Local;
import util.col.array : only;
import util.writer : Writer, writeWithCommas;
import util.symbol : writeSymbol;
import util.util : stringOfEnum;

void writeFunName(scope ref Writer writer, in ShowCtx ctx, in LowProgram lowProgram, LowFunIndex fun) {
	writeFunName(writer, ctx, lowProgram, lowProgram.allFuns[fun]);
}

void writeFunName(scope ref Writer writer, in ShowCtx ctx, in LowProgram lowProgram, in LowFun a) {
	a.source.matchIn!void(
		(in ConcreteFun x) {
			writeConcreteFunName(writer, ctx, x);
		},
		(in LowFunSource.Generated x) {
			writeSymbol(writer, ctx.allSymbols, x.name);
			writeLowTypeArgs(writer, ctx, lowProgram, x.typeArgs);
			writer ~= " (generated)";
		});
}

private void writeLowTypeArgs(
	scope ref Writer writer,
	in ShowCtx ctx,
	in LowProgram lowProgram,
	in LowType[] typeArgs,
) {
	writeTypeArgsGeneric!LowType(writer, typeArgs,
		(in LowType x) => false,
		(in LowType typeArg) {
			writeLowType(writer, ctx, lowProgram.allTypes, typeArg);
		});
}

void writeFunSig(scope ref Writer writer, in ShowCtx ctx, in LowProgram lowProgram, in LowFun a) {
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
							writeSymbol(writer, ctx.allSymbols, p.name);
						},
						(in ConcreteLocalSource.Closure) {
							writer ~= "<closure>";
						},
						(in ConcreteLocalSource.Generated x) {
							writeSymbol(writer, ctx.allSymbols, x.name);
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

void writeConcreteType(scope ref Writer writer, in ShowCtx ctx, in ConcreteType a) {
	writeConcreteStruct(writer, ctx, *a.struct_);
	if (a.reference != ReferenceKind.byVal) {
		writer ~= ' ';
		writer ~= stringOfEnum(a.reference);
	}
}

private:

void writeLowType(scope ref Writer writer, in ShowCtx ctx, in AllLowTypes lowTypes, in LowType a) {
	a.matchIn!void(
		(in LowType.Extern) {
			writer ~= "some extern type"; // TODO: more detail
		},
		(in LowType.FunPointer) {
			writer ~= "some fun ptr type"; // TODO: more detail
		},
		(in PrimitiveType x) {
			writer ~= stringOfEnum(x);
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

void writeConcreteFunName(scope ref Writer writer, in ShowCtx ctx, in ConcreteFun a) {
	a.source.matchIn!void(
		(in ConcreteFunKey x) {
			writeSymbol(writer, ctx.allSymbols, x.decl.name);
			writeConcreteTypeArgs(writer, ctx, x.typeArgs);
			// TODO: write spec impls?
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

void writeConcreteTypeArgs(scope ref Writer writer, in ShowCtx ctx, in ConcreteType[] a) {
	writeTypeArgsGeneric!ConcreteType(writer, a,
		(in ConcreteType x) => false,
		(in ConcreteType x) {
			writeConcreteType(writer, ctx, x);
		});
}

void writeConcreteStruct(scope ref Writer writer, in ShowCtx ctx, in ConcreteStruct a) {
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
			writeSymbol(writer, ctx.allSymbols, x.inst.decl.name);
		},
		(in ConcreteStructSource.Lambda x) {
			writeConcreteFunName(writer, ctx, *x.containingFun);
			writer ~= ".lambda";
			writer ~= x.index;
		});
}
