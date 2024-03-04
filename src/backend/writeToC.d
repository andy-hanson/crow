module backend.writeToC;

@safe @nogc pure nothrow:

import backend.mangle :
	buildMangledNames,
	MangledNames,
	writeConstantArrStorageName,
	writeConstantPointerStorageName,
	writeLowFunMangledName,
	writeLowLocalName,
	writeLowVarMangledName,
	writeMangledName,
	writeRecordName,
	writeStructMangledName;
import backend.builtinMath : builtinForBinaryMath, builtinForUnaryMath;
import backend.writeTypes : ElementAndCount, TypeWriters, writeTypes;
import frontend.lang : CCompileOptions, OptimizationLevel;
import frontend.showModel : ShowCtx;
import lower.lowExprHelpers : boolType;
import model.concreteModel : ConcreteStruct, ConcreteStructBody, TypeSize;
import model.constant : Constant;
import model.lowModel :
	AllConstantsLow,
	ArrTypeAndConstantsLow,
	asPtrGcPointee,
	debugName,
	ExternLibraries,
	ExternLibrary,
	isChar8,
	isChar32,
	isGeneratedMain,
	isVoid,
	LowExpr,
	LowExprKind,
	LowField,
	LowFun,
	LowFunBody,
	LowFunExprBody,
	LowFunIndex,
	LowFunPointerType,
	LowLocal,
	LowPtrCombine,
	LowProgram,
	LowRecord,
	LowVar,
	LowVarIndex,
	LowType,
	LowUnion,
	PointerTypeAndConstantsLow,
	PrimitiveType,
	targetIsPointer,
	targetRecordType,
	UpdateParam;
import model.model : BuiltinBinary, BuiltinType, BuiltinUnary, EnumValue;
import model.showLowModel : writeFunName, writeFunSig;
import model.typeLayout : sizeOfType, typeSizeBytes;
import util.alloc.alloc : Alloc, TempAlloc;
import util.col.array : contains, every, exists, isEmpty, map, only, sizeEq, zip;
import util.col.arrayBuilder : buildArray, Builder;
import util.col.map : mustGet;
import util.col.fullIndexMap : FullIndexMap, fullIndexMapEach, fullIndexMapEachKey;
import util.col.stackMap : StackMap, stackMapAdd, stackMapMustGet;
import util.opt : force, has, Opt, some;
import util.string : CString, cString, cStringSize, stringOfCString;
import util.symbol : addExtension, cStringOfSymbol, Extension, Symbol, symbol;
import util.unicode : isValidUnicodeCharacter, mustUnicodeDecode;
import util.union_ : Union;
import util.uri : asFilePath, cStringOfFilePath, FilePath, uriIsFile;
import util.util : abs, castImmutable, castNonScope, castNonScope_ref, ptrTrustMe, stringOfEnum, todo;
import util.writer :
	makeStringWithWriter,
	withWriter,
	writeEscapedChar_inner,
	writeFloatLiteral,
	writeNewline,
	writeQuotedString,
	Writer,
	writeWithCommas,
	writeWithCommasZip,
	writeWithSpaces;
import versionInfo : isWindows;

immutable struct PathAndArgs {
	FilePath path;
	CString[] args;
}

immutable struct WriteToCResult {
	PathAndArgs compileCommand;
	string cSource;
}

immutable struct WriteToCParams {
	FilePath cCompiler;
	FilePath cPath;
	FilePath exePath;
	CCompileOptions compileOptions;
}

WriteToCResult writeToC(ref Alloc alloc, in ShowCtx printCtx, in LowProgram program, in WriteToCParams params) {
	bool isMSVC = isWindows(program.version_);
	CString[] args = cCompileArgs(alloc, program.externLibraries, isMSVC, params);
	string content = makeStringWithWriter(alloc, (scope ref Writer writer) {
		writeCommandComment(writer, params.cCompiler, args);
		writer ~= "#include <math.h>\n"; // for e.g. 'sin'
		writer ~= "#include <stddef.h>\n"; // for NULL
		writer ~= "#include <stdint.h>\n";
		writer ~= "typedef uint32_t char32_t;\n";
		if (isMSVC) {
			writer ~= "unsigned short __popcnt16(unsigned short value);\n";
			writer ~= "unsigned int __popcnt(unsigned int value);\n";
			writer ~= "unsigned __int64 __popcnt64(unsigned __int64 value);\n";
		}

		Ctx ctx = Ctx(
			ptrTrustMe(printCtx), ptrTrustMe(program), buildMangledNames(alloc, program, isMSVC), isMSVC: isMSVC);

		writeStructs(alloc, writer, ctx);

		fullIndexMapEach!(LowFunIndex, LowFun)(program.allFuns, (LowFunIndex funIndex, ref LowFun fun) {
			writeFunDeclaration(writer, ctx, funIndex, fun);
		});

		writeConstants(writer, ctx, program.allConstants);
		writeVars(writer, ctx, program.vars);

		fullIndexMapEach!(LowFunIndex, LowFun)(
			program.allFuns,
			(LowFunIndex funIndex, ref LowFun fun) {
				writeFunDefinition(writer, alloc, ctx, funIndex, fun);
			});
	});
	return WriteToCResult(PathAndArgs(params.cCompiler, args), content);
}

private void writeCommandComment(scope ref Writer writer, FilePath cCompiler, in CString[] args) {
	writer ~= "/* \"";
	writer ~= cCompiler;
	writer ~= "\" ";
	writeWithSpaces!CString(writer, args, (in CString arg) { writeAndQuoteIfNecessary(writer, stringOfCString(arg)); });
	writer ~= " */\n\n";
}

private void writeAndQuoteIfNecessary(scope ref Writer writer, in string a) {
	if (contains(a, ' '))
		writeQuotedString(writer, a);
	else
		writer ~= a;
}

public void getLinkOptions(
	ref Alloc alloc,
	bool isMSVC,
	in ExternLibraries externLibraries,
	in void delegate(CString) @safe @nogc pure nothrow cb,
) {
	if (isMSVC)
		cb(cString!"/link");
	foreach (ExternLibrary x; externLibraries) {
		if (isMSVC) {
			Symbol xDotLib = addExtension(x.libraryName, Extension.lib);
			if (has(x.configuredDir)) {
				if (!uriIsFile(force(x.configuredDir)))
					todo!void("diagnostic: can't link to non-file");
				cb(cStringOfFilePath(alloc, asFilePath(force(x.configuredDir)) / xDotLib));
			} else
				switch (x.libraryName.value) {
					case symbol!"c".value:
					case symbol!"m".value:
						break;
					default:
						cb(cStringOfSymbol(alloc, xDotLib));
						break;
				}
		} else {
			if (has(x.configuredDir)) {
				cb(withWriter(alloc, (scope ref Writer writer) {
					writer ~= "-L/";
					if (!uriIsFile(force(x.configuredDir)))
						todo!void("diagnostic: can't link to non-file");
					writer ~= asFilePath(force(x.configuredDir));
				}));
			}

			cb(withWriter(alloc, (scope ref Writer writer) {
				writer ~= "-l";
				writer ~= x.libraryName;
			}));
		}
	}
}

private:

CString[] cCompileArgs(
	ref Alloc alloc,
	in ExternLibraries externLibraries,
	bool isMSVC,
	in WriteToCParams params,
) =>
	buildArray(alloc, (scope ref Builder!CString args) {
		args ~= cCompilerArgs(isMSVC, params.compileOptions);
		args ~= cStringOfFilePath(alloc, params.cPath);
		getLinkOptions(alloc, isMSVC, externLibraries, (CString x) { args ~= x; });
		if (isMSVC) {
			args ~= [
				cString!"/nologo",
				withWriter(alloc, (scope ref Writer writer) {
					writer ~= "/out:";
					writer ~= params.exePath;
				}),
			];
		} else {
			args ~= [cString!"-o", cStringOfFilePath(alloc, params.exePath)];
		}
	});

CString[] cCompilerArgs(bool isMSVC, in CCompileOptions options) {
	if (isMSVC) {
		static immutable CString[] optimizedArgs = [
			cString!"/DEBUG",
			cString!"/Z7",
			cString!"/std:c17",
			cString!"/W3",
			cString!"/wd4028",
			cString!"/wd4098",
			cString!"/wd4723",
			cString!"/WX",
			cString!"/O2",
		];
		static immutable CString[] regularArgs = optimizedArgs[0 .. $ - 1];
		final switch (options.optimizationLevel) {
			case OptimizationLevel.none:
				return regularArgs;
			case OptimizationLevel.o2:
				return optimizedArgs;
		}
	} else {
		static immutable CString[] optimizedArgs = [
			cString!"-Werror",
			cString!"-Wextra",
			cString!"-Wall",
			cString!"-ansi",
			cString!"-std=c17",
			cString!"-Wno-address-of-packed-member",
			cString!"-Wno-builtin-declaration-mismatch",
			cString!"-Wno-div-by-zero",
			cString!"-Wno-maybe-uninitialized",
			cString!"-Wno-missing-field-initializers",
			cString!"-Wno-unused-but-set-parameter",
			cString!"-Wno-unused-but-set-variable",
			cString!"-Wno-unused-function",
			cString!"-Wno-unused-parameter",
			cString!"-Wno-unused-variable",
			cString!"-Wno-unused-value",
			cString!"-Ofast",
		];
		static immutable CString[] regularArgs = optimizedArgs[0 .. $ - 1] ~ [cString!"-g"];
		final switch (options.optimizationLevel) {
			case OptimizationLevel.none:
				return regularArgs;
			case OptimizationLevel.o2:
				return optimizedArgs;
		}
	}
}

void writeCStringName(scope ref Writer writer, size_t index) {
	writer ~= "__cString";
	writer ~= index;
}

void writeConstants(scope ref Writer writer, scope ref Ctx ctx, in AllConstantsLow allConstants) {
	// Need to ensure strings are written only once so MSVC doesn't create duplicates (which breaks Symbol uniqueness)
	foreach (size_t index, CString x; allConstants.cStrings) {
		writer ~= "char ";
		writeCStringName(writer, index);
		writer ~= "[";
		writer ~= cStringSize(x) + 1;
		writer ~= "] = ";
		writeStringLiteralWithNul(writer, ctx.isMSVC, stringOfCString(x));
		writer ~= ";\n";
	}
	writer ~= '\n';

	foreach (ref ArrTypeAndConstantsLow a; allConstants.arrs) {
		foreach (size_t i, Constant[] elements; a.constants) {
			declareConstantArrStorage(writer, ctx, a.arrType, a.elementType, i, elements.length);
			writer ~= ";\n";
		}
	}

	foreach (ref PointerTypeAndConstantsLow a; allConstants.pointers) {
		foreach (size_t i; 0 .. a.constants.length) {
			declareConstantPointerStorage(writer, ctx, a.pointeeType, i);
			writer ~= ";\n";
		}
	}

	foreach (ref ArrTypeAndConstantsLow a; allConstants.arrs) {
		foreach (size_t i, Constant[] elements; a.constants) {
			declareConstantArrStorage(writer, ctx, a.arrType, a.elementType, i, elements.length);
			writer ~= " = ";
			writeArrayConstant(writer, ctx, a.elementType, elements);
			writer ~= ";\n";
		}
	}

	foreach (ref PointerTypeAndConstantsLow a; allConstants.pointers) {
		foreach (size_t i, Constant pointee; a.constants) {
			declareConstantPointerStorage(writer, ctx, a.pointeeType, i);
			writer ~= " = ";
			writeConstantRef(writer, ctx, ConstantRefPos.inner, a.pointeeType, pointee);
			writer ~= ";\n";
		}
	}
}

void writeArrayConstant(scope ref Writer writer, scope ref Ctx ctx, in LowType elementType, in Constant[] elements) {
	if (isChar8(elementType)) {
		char[0x10000] buf;
		foreach (size_t i, Constant x; elements)
			buf[i] = cast(char) x.as!(Constant.Integral).value;
		writeStringLiteralWithoutNul(writer, ctx.isMSVC, castImmutable(buf[0 .. elements.length]));
	} else if (isChar32(elementType) && !ctx.isMSVC) {
		writer ~= "U\"";
		foreach (Constant element; elements)
			writeEscapedCharForC(writer, cast(dchar) element.as!(Constant.Integral).value);
		writer ~= '"';
	} else {
		writer ~= '{';
		writeWithCommas!Constant(writer, elements, (in Constant element) {
			writeConstantRef(writer, ctx, ConstantRefPos.inner, elementType, element);
		});
		writer ~= '}';
	}
}

void writeEscapedCharForC(scope ref Writer writer, dchar a) {
	if (a == '?')
		// avoid trigraphs
		writer ~= "\\?";
	else
		writeEscapedChar_inner(writer, a);
}

void writeVars(scope ref Writer writer, scope ref Ctx ctx, in immutable FullIndexMap!(LowVarIndex, LowVar) vars) {
	fullIndexMapEach!(LowVarIndex, LowVar)(vars, (LowVarIndex varIndex, ref LowVar var) {
		writer ~= () {
			final switch (var.kind) {
				case LowVar.Kind.externGlobal:
					return "extern ";
				case LowVar.Kind.global:
					return "static ";
				case LowVar.Kind.threadLocal:
					return ctx.isMSVC ? "static __declspec(thread) " : "static _Thread_local ";
			}
		}();
		writeType(writer, ctx, var.type);
		writer ~= ' ';
		writeLowVarMangledName(writer, ctx.mangledNames, varIndex, var);
		writer ~= ";\n";
	});
}

void declareConstantArrStorage(
	scope ref Writer writer,
	scope ref Ctx ctx,
	LowType.Record arrType,
	in LowType elementType,
	size_t index,
	size_t nElements,
) {
	writeType(writer, ctx, elementType);
	writer ~= ' ';
	writeConstantArrStorageName(writer, ctx.mangledNames, ctx.program, arrType, index);
	writer ~= '[';
	writer ~= nElements;
	writer ~= ']';
}

void declareConstantPointerStorage(
	scope ref Writer writer,
	scope ref Ctx ctx,
	in LowType pointeeType,
	size_t index,
) {
	//TODO: some day we may support non-record pointee?
	writeRecordType(writer, ctx, pointeeType.as!(LowType.Record));
	writer ~= ' ';
	writeConstantPointerStorageName(writer, ctx.mangledNames, ctx.program, pointeeType, index);
}

const struct Ctx {
	@safe @nogc pure nothrow:

	ShowCtx* showDiagCtxPtr;
	LowProgram* programPtr;
	MangledNames mangledNames;
	bool isMSVC;

	ref ShowCtx printCtx() return scope =>
		*showDiagCtxPtr;
	ref LowProgram program() return scope const =>
		*programPtr;
}

struct FunBodyCtx {
	@safe @nogc pure nothrow:

	TempAlloc* tempAllocPtr;
	Ctx* ctxPtr;
	immutable bool hasTailRecur;
	immutable LowFunIndex curFun;
	size_t nextTemp;

	ref TempAlloc tempAlloc() scope =>
		*castNonScope(tempAllocPtr);

	ref inout(Ctx) ctx() return scope inout =>
		*ctxPtr;

	ref LowProgram program() return scope const =>
		ctx.program;

	ref MangledNames mangledNames() return scope const =>
		ctx.mangledNames;
}

size_t nextLoopIndex(ref FunBodyCtx ctx) {
	size_t res = ctx.nextTemp;
	ctx.nextTemp++;
	return res;
}

Temp getNextTemp(ref FunBodyCtx ctx) {
	Temp temp = Temp(ctx.nextTemp);
	ctx.nextTemp++;
	return temp;
}

void writeType(scope ref Writer writer, scope ref Ctx ctx, in LowType t) {
	t.combinePointer.matchIn!void(
		(in LowType.Extern it) {
			writer ~= "struct ";
			writeStructMangledName(writer, ctx.mangledNames, ctx.program.allExternTypes[it].source);
		},
		(in LowType.FunPointer it) {
			writeStructMangledName(writer, ctx.mangledNames, ctx.program.allFunPointerTypes[it].source);
		},
		(in PrimitiveType it) {
			writePrimitiveType(writer, it);
		},
		(in LowPtrCombine it) {
			writeType(writer, ctx, it.pointee);
			writer ~= '*';
		},
		(in LowType.Record it) {
			writeRecordType(writer, ctx, it);
		},
		(in LowType.Union it) {
			writer ~= "struct ";
			writeStructMangledName(writer, ctx.mangledNames, ctx.program.allUnions[it].source);
		});
}

void writeRecordType(scope ref Writer writer, scope ref Ctx ctx, LowType.Record a) {
	writer ~= "struct ";
	writeRecordName(writer, ctx.mangledNames, ctx.program, a);
}

void writeCastToType(scope ref Writer writer, scope ref Ctx ctx, in LowType type) {
	writer ~= '(';
	writeType(writer, ctx, type);
	writer ~= ") ";
}

void writeParamDecl(scope ref Writer writer, scope ref Ctx ctx, in LowLocal a) {
	writeType(writer, ctx, a.type);
	writer ~= ' ';
	writeLowLocalName(writer, ctx.mangledNames, a);
}

void writeStructHead(scope ref Writer writer, scope ref Ctx ctx, in ConcreteStruct* source) {
	writer ~= "struct ";
	writeStructMangledName(writer, ctx.mangledNames, source);
	writer ~= " {";
}

void writeStructEnd(ref Writer writer) {
	writer ~= "\n};\n";
}

bool isEmptyType(in ConcreteStruct a) =>
	a.typeSize.sizeBytes == 0;
bool isEmptyType(in Ctx ctx, in LowType a) =>
	sizeOfType(ctx.program, a).sizeBytes == 0;
bool isEmptyType(in FunBodyCtx ctx, in LowType a) =>
	isEmptyType(ctx.ctx, a);

void writeRecord(scope ref Writer writer, scope ref Ctx ctx, in LowRecord a) {
	if (a.packed && ctx.isMSVC)
		writer ~= "__pragma(pack(push, 1))\n";
	writeStructHead(writer, ctx, a.source);
	foreach (ref LowField field; a.fields) {
		if (!isEmptyType(ctx, field.type)) {
			writer ~= "\n\t";
			writeType(writer, ctx, field.type);
			writer ~= ' ';
			writeMangledName(writer, ctx.mangledNames, debugName(field));
			writer ~= ';';
		}
	}
	writer ~= "\n}";
	if (a.packed)
		writer ~= ctx.isMSVC ? "__pragma(pack(pop))" : " __attribute__ ((__packed__))";
	writer ~= ";\n";
}

void writeUnion(scope ref Writer writer, scope ref Ctx ctx, in LowUnion a) {
	writeStructHead(writer, ctx, a.source);
	writer ~= "\n\tuint64_t kind;";
	bool isBuiltin = a.source.body_.isA!(ConcreteStructBody.Builtin);
	if (isBuiltin) assert(a.source.body_.as!(ConcreteStructBody.Builtin).kind == BuiltinType.lambda);
	if (isBuiltin || exists!LowType(a.members, (in LowType member) => !isEmptyType(ctx, member))) {
		writer ~= "\n\tunion {";
		foreach (size_t memberIndex, LowType member; a.members) {
			if (!isEmptyType(ctx, member)) {
				writer ~= "\n\t\t";
				writeType(writer, ctx, member);
				writer ~= " as";
				writer ~= memberIndex;
				writer ~= ';';
			}
		}
		// Fun types must be 16 bytes
		if (isBuiltin &&
			every!LowType(a.members, (in LowType member) => typeSizeBytes(ctx.program, member) < 8))
			writer ~= "\n\t\tuint64_t __ensureSizeIs16;";
		writer ~= "\n\t};";
	}
	writeStructEnd(writer);
}

void declareStruct(scope ref Writer writer, scope ref Ctx ctx, in ConcreteStruct* source) {
	writer ~= "struct ";
	writeStructMangledName(writer, ctx.mangledNames, source);
	writer ~= ";\n";
}

void staticAssertStructSize(scope ref Writer writer, scope ref Ctx ctx, in LowType type, TypeSize size) {
	writer ~= "_Static_assert(sizeof(";
	writeType(writer, ctx, type);
	writer ~= ") == ";
	writer ~= size.sizeBytes;
	writer ~= ", \"\");\n";

	writer ~= "_Static_assert(_Alignof(";
	writeType(writer, ctx, type);
	writer ~= ") == ";
	writer ~= size.alignmentBytes;
	writer ~= ", \"\");\n";
}

void writeStructs(ref Alloc alloc, scope ref Writer writer, scope ref Ctx ctx) {
	scope TypeWriters writers = TypeWriters(
		(ConcreteStruct* x) {
			if (!isEmptyType(*x))
				declareStruct(writer, ctx, x);
		},
		(ConcreteStruct* source, in Opt!ElementAndCount ec) {
			writer ~= "struct ";
			writeStructMangledName(writer, ctx.mangledNames, source);
			if (has(ec)) {
				writer ~= " { ";
				writePrimitiveType(writer, force(ec).elementType);
				writer ~= " __sizer[";
				writer ~= force(ec).count;
				writer ~= "]; }";
			}
			writer ~= ";\n";
		},
		(LowType.FunPointer, in LowFunPointerType funPtr) {
			writer ~= "typedef ";
			if (isEmptyType(ctx, funPtr.returnType))
				writer ~= "void";
			else
				writeType(writer, ctx, funPtr.returnType);
			writer ~= " (*";
			writeStructMangledName(writer, ctx.mangledNames, funPtr.source);
			writer ~= ")(";
			if (isEmpty(funPtr.paramTypes))
				writer ~= "void";
			else
				writeWithCommas!LowType(
					writer,
					funPtr.paramTypes,
					(in LowType paramType) =>
						!isEmptyType(ctx, paramType),
					(in LowType paramType) {
						writeType(writer, ctx, paramType);
					});
			writer ~= ");\n";
		},
		(LowType.Record x, in LowRecord record) {
			if (!isEmptyType(ctx, LowType(x)))
				writeRecord(writer, ctx, record);
		},
		(LowType.Union, in LowUnion union_) {
			writeUnion(writer, ctx, union_);
		});
	writeTypes(alloc, ctx.program, writers);

	writer ~= '\n';

	void assertSize(LowType t) {
		staticAssertStructSize(writer, ctx, t, sizeOfType(ctx.program, t));
	}

	//TODO: use a temp alloc
	fullIndexMapEachKey!(LowType.Record, LowRecord)(ctx.program.allRecords, (LowType.Record x) {
		if (!isEmptyType(ctx, LowType(x)))
			assertSize(LowType(x));
	});
	fullIndexMapEachKey!(LowType.Union, LowUnion)(ctx.program.allUnions, (LowType.Union x) {
		assertSize(LowType(x));
	});
}

void writeFunReturnTypeNameAndParams(scope ref Writer writer, scope ref Ctx ctx, LowFunIndex funIndex, in LowFun fun) {
	if (isEmptyType(ctx,fun.returnType))
		writer ~= "void";
	else
		writeType(writer, ctx, fun.returnType);
	writer ~= ' ';
	writeLowFunMangledName(writer, ctx.mangledNames, funIndex, fun);
	writer ~= '(';
	if (every!LowLocal(fun.params, (in LowLocal x) => isEmptyType(ctx, x.type)))
		writer ~= "void";
	else
		writeWithCommas!LowLocal(
			writer,
			fun.params,
			(in LowLocal x) =>
				!isEmptyType(ctx, x.type),
			(in LowLocal x) {
				writeParamDecl(writer, ctx, x);
			});
	writer ~= ')';
}

void writeFunDeclaration(scope ref Writer writer, scope ref Ctx ctx, LowFunIndex funIndex, in LowFun fun) {
	if (fun.body_.isA!(LowFunBody.Extern))
		writer ~= "extern ";
	else if (!isGeneratedMain(fun))
		writer ~= "static ";
	writeFunReturnTypeNameAndParams(writer, ctx, funIndex, fun);
	writer ~= ";\n";
}

void writeFunDefinition(
	scope ref Writer writer,
	ref TempAlloc tempAlloc,
	scope ref Ctx ctx,
	LowFunIndex funIndex,
	in LowFun fun,
) {
	fun.body_.matchIn!void(
		(in LowFunBody.Extern) {
			// declaration is enough
		},
		(in LowFunExprBody x) {
			// TODO: only if a flag is set
			writer ~= "/* ";
			writeFunName(writer, ctx.printCtx, ctx.program, funIndex);
			writer ~= ' ';
			writeFunSig(writer, ctx.printCtx, ctx.program, fun);
			writer ~= " */\n";
			writeFunWithExprBody(writer, tempAlloc, ctx, funIndex, fun, x);
		});
}

//TODO: not @trusted
@trusted void writeFunWithExprBody(
	scope ref Writer writer,
	ref TempAlloc tempAlloc,
	scope ref Ctx ctx,
	LowFunIndex funIndex,
	in LowFun fun,
	in LowFunExprBody body_,
) {
	if (!isGeneratedMain(fun)) writer ~= "static ";
	writeFunReturnTypeNameAndParams(writer, ctx, funIndex, fun);
	writer ~= " {";
	if (body_.hasTailRecur)
		writer ~= "\n\ttop:;"; // Need ';' so it labels a statement
	FunBodyCtx bodyCtx = FunBodyCtx(ptrTrustMe(tempAlloc), ptrTrustMe(ctx), body_.hasTailRecur, funIndex, 0);
	WriteKind writeKind = WriteKind(WriteKind.Return());
	Locals locals;
	cast(void) writeExpr(writer, 1, bodyCtx, locals, writeKind, body_.expr);
	writer ~= "\n}\n";
}

immutable struct Temp {
	size_t index;
}

// If expr, we refused to write to a temp because this can be written inline
immutable struct WriteExprResult {
	// Meaning depends on the WriteKind
	// If the write kind was TempOrInline, this indicates that it should be done inline.
	immutable struct Done {
		// Args (not written inline) prepared for writing inline.
		WriteExprResult[] args;
	}

	mixin Union!(Done, Temp);
}

WriteExprResult writeExprDone() =>
	WriteExprResult(WriteExprResult.Done([]));

void writeTempDeclare(
	scope ref Writer writer,
	scope ref FunBodyCtx ctx,
	in LowType type,
	Temp temp,
) {
	writeType(writer, ctx.ctx, type);
	writer ~= ' ';
	writeTempRef(writer, temp);
}

void writeTempRef(scope ref Writer writer, in Temp a) {
	writer ~= "_";
	writer ~= a.index;
}

void writeTempOrInline(
	scope ref Writer writer,
	scope ref FunBodyCtx ctx,
	in Locals locals,
	in LowExpr e,
	in WriteExprResult a,
) {
	a.matchIn!void(
		(in WriteExprResult.Done it) {
			WriteKind writeKind = WriteKind(WriteKind.Inline(it.args));
			WriteExprResult res = writeExpr(writer, 0, ctx, locals, writeKind, e);
			assert(isEmpty(res.as!(WriteExprResult.Done).args));
		},
		(in Temp it) {
			writeTempRef(writer, it);
		});
}

void writeTempOrInlines(
	scope ref Writer writer,
	scope ref FunBodyCtx ctx,
	in Locals locals,
	in LowExpr[] exprs,
	in WriteExprResult[] args,
) {
	assert(sizeEq(exprs, args));
	writeWithCommasZip!(LowExpr, WriteExprResult)(
		writer,
		exprs,
		args,
		(in LowExpr expr, in WriteExprResult) =>
			!isEmptyType(ctx, expr.type),
		(in expr, in WriteExprResult arg) {
			writeTempOrInline(writer, ctx, locals, expr, arg);
		});
}

void writeDeclareLocal(scope ref Writer writer, size_t indent, scope ref FunBodyCtx ctx, in LowLocal local) {
	writeNewline(writer, indent);
	writeType(writer, ctx.ctx, local.type);
	writer ~= ' ';
	writeLowLocalName(writer, ctx.mangledNames, local);
}

immutable struct WriteKind {
	immutable struct Inline {
		WriteExprResult[] args;
	}
	// May write a temp now, or delay and write inline when needed.
	immutable struct InlineOrTemp {}
	immutable struct MakeTemp {}
	immutable struct Return {}
	immutable struct UseTemp {
		Temp temp;
	}
	// Simple statement, don't return anything
	immutable struct Void {}

	mixin Union!(Inline, InlineOrTemp, LowLocal*, LowVarIndex, MakeTemp, Return, UseTemp, Void);
}
static assert(WriteKind.sizeof == size_t.sizeof * 3);

WriteExprResult[] writeExprsTempOrInline(
	scope ref Writer writer,
	size_t indent,
	scope ref FunBodyCtx ctx,
	in Locals locals,
	in LowExpr[] args,
) =>
	map(ctx.tempAlloc, args, (ref LowExpr arg) =>
		writeExprTempOrInline(writer, indent, ctx, locals, arg));

Temp writeExprTemp(
	scope ref Writer writer,
	size_t indent,
	scope ref FunBodyCtx ctx,
	in Locals locals,
	in LowExpr expr,
) {
	WriteKind writeKind = WriteKind(WriteKind.MakeTemp());
	return writeExpr(writer, indent, ctx, locals, writeKind, expr).as!Temp;
}

void writeExprVoid(
	scope ref Writer writer,
	size_t indent,
	scope ref FunBodyCtx ctx,
	in Locals locals,
	in LowExpr expr,
) {
	WriteKind writeKind = WriteKind(WriteKind.Void());
	cast(void) writeExpr(writer, indent, ctx, locals, writeKind, expr);
}

WriteExprResult writeExprTempOrInline(
	scope ref Writer writer,
	size_t indent,
	scope ref FunBodyCtx ctx,
	in Locals locals,
	in LowExpr expr,
) {
	WriteKind writeKind = WriteKind(WriteKind.InlineOrTemp());
	return writeExpr(writer, indent, ctx, locals, writeKind, expr);
}

immutable struct LoopInfo {
	size_t index;
	WriteKind writeKind;
}

// Currently only needed to map loop to a unique (within the function) identifier
alias Locals = StackMap!(LowExprKind.Loop*, LoopInfo*);
alias addLoop = stackMapAdd!(LowExprKind.Loop*, LoopInfo*);
alias getLoop = stackMapMustGet!(LowExprKind.Loop*, LoopInfo*);

WriteExprResult writeExpr(
	scope ref Writer writer,
	size_t indent,
	scope ref FunBodyCtx ctx,
	in Locals locals,
	in WriteKind writeKind,
	in LowExpr expr,
) {
	LowType type = expr.type;
	WriteExprResult nonInlineable(in void delegate() @safe @nogc pure nothrow cb) {
		return writeNonInlineable(writer, indent, ctx, writeKind, type, cb);
	}
	WriteExprResult inlineable(
		in LowExpr[] args,
		in void delegate(in WriteExprResult[]) @safe @nogc pure nothrow inline,
	) {
		return writeInlineable(writer, indent, ctx, locals, writeKind, type, args, inline);
	}
	WriteExprResult inlineableSingleArg(
		in LowExpr arg,
		in void delegate(in WriteExprResult) @safe @nogc pure nothrow inline,
	) {
		return writeInlineableSingleArg(writer, indent, ctx, locals, writeKind, type, arg, inline);
	}
	WriteExprResult inlineableSimple(in void delegate() @safe @nogc pure nothrow inline) {
		return writeInlineableSimple(writer, indent, ctx, locals, writeKind, type, inline);
	}

	return expr.kind.matchIn!WriteExprResult(
		(in LowExprKind.Call it) =>
			writeCallExpr(writer, indent, ctx, locals, writeKind, type, it),
		(in LowExprKind.CallFunPointer it) =>
			writeCallFunPointer(writer, indent, ctx, locals, writeKind, type, it),
		(in LowExprKind.CreateRecord it) =>
			inlineable(it.args, (in WriteExprResult[] args) {
				writeCastToType(writer, ctx.ctx, type);
				writer ~= '{';
				writeTempOrInlines(writer, ctx, locals, it.args, args);
				writer ~= '}';
			}),
		(in LowExprKind.CreateUnion it) =>
			inlineableSingleArg(it.arg, (in WriteExprResult arg) {
				writeCreateUnion(writer, ctx.ctx, ConstantRefPos.outer, type, it.memberIndex, () {
					writeTempOrInline(writer, ctx, locals, it.arg, arg);
				});
			}),
		(in LowExprKind.If it) =>
			writeIf(writer, indent, ctx, locals, writeKind, type, it),
		(in LowExprKind.InitConstants) =>
			// writeToC doesn't need to do anything in 'init-constants'
			writeReturnVoid(writer, indent, ctx, writeKind),
		(in LowExprKind.Let it) =>
			writeLet(writer, indent, ctx, locals, writeKind, it),
		(in LowExprKind.LocalGet it) =>
			inlineableSimple(() {
				writeLowLocalName(writer, ctx.mangledNames, *it.local);
			}),
		(in LowExprKind.LocalSet it) =>
			writeLocalSet(writer, indent, ctx, locals, writeKind, it),
		(in LowExprKind.Loop it) =>
			writeLoop(writer, indent, ctx, locals, writeKind, type, it),
		(in LowExprKind.LoopBreak it) =>
			writeLoopBreak(writer, indent, ctx, locals, writeKind, it),
		(in LowExprKind.LoopContinue it) =>
			// Do nothing, continuing the loop is implicit in C
			writeVoid(writeKind),
		(in LowExprKind.MatchUnion it) =>
			writeMatchUnion(writer, indent, ctx, locals, writeKind, type, it),
		(in LowExprKind.PtrCast it) =>
			inlineableSingleArg(it.target, (in WriteExprResult arg) {
				writer ~= '(';
				writeCastToType(writer, ctx.ctx, type);
				writeTempOrInline(writer, ctx, locals, it.target, arg);
				writer ~= ')';
			}),
		(in LowExprKind.PtrToField it) =>
			writePtrToField(writer, indent, ctx, locals, writeKind, type, it),
		(in LowExprKind.PtrToLocal it) =>
			inlineableSimple(() {
				writer ~= '&';
				writeLowLocalName(writer, ctx.mangledNames, *it.local);
			}),
		(in LowExprKind.RecordFieldGet it) =>
			writeRecordFieldGet(writer, indent, ctx, locals, writeKind, type, it),
		(in LowExprKind.RecordFieldSet x) {
			WriteExprResult recordValue = writeExprTempOrInline(writer, indent, ctx, locals, *x.target);
			WriteExprResult fieldValue = writeExprTempOrInline(writer, indent, ctx, locals, *x.value);
			return writeReturnVoid(writer, indent, ctx, writeKind, () {
				writeTempOrInline(writer, ctx, locals, *x.target, recordValue);
				writeRecordFieldRef(writer, ctx, targetIsPointer(x), targetRecordType(x), x.fieldIndex);
				writer ~= " = ";
				writeTempOrInline(writer, ctx, locals, *x.value, fieldValue);
			});
		},
		(in LowExprKind.SizeOf x) =>
			inlineableSimple(() {
				if (isVoid(x.type))
					writer ~= '0';
				else {
					writer ~= "sizeof(";
					writeType(writer, ctx.ctx, x.type);
					writer ~= ')';
				}
			}),
		(in Constant it) =>
			inlineableSimple(() {
				writeConstantRef(writer, ctx.ctx, ConstantRefPos.outer, type, it);
			}),
		(in LowExprKind.SpecialUnary it) =>
			writeSpecialUnary(writer, indent, ctx, locals, writeKind, type, it),
		(in LowExprKind.SpecialUnaryMath x) =>
			specialCallUnary(
				writer, indent, ctx, locals, writeKind, type, x.arg, stringOfEnum(builtinForUnaryMath(x.kind))),
		(in LowExprKind.SpecialBinary it) =>
			writeSpecialBinary(writer, indent, ctx, locals, writeKind, type, it),
		(in LowExprKind.SpecialBinaryMath x) =>
			specialCallBinary(
				writer, indent, ctx, locals, writeKind, type, x.args, stringOfEnum(builtinForBinaryMath(x.kind))),
		(in LowExprKind.SpecialTernary) =>
			assert(false),
		(in LowExprKind.Switch0ToN it) =>
			writeSwitch(
				writer, indent, ctx, locals, writeKind, type, it.value, it.cases,
				(size_t i) => EnumValue(i)),
		(in LowExprKind.SwitchWithValues it) =>
			writeSwitch(
				writer, indent, ctx, locals, writeKind, type, it.value, it.cases,
				(size_t i) => it.values[i]),
		(in LowExprKind.TailRecur it) {
			assert(writeKind.isA!(WriteKind.Return));
			writeTailRecur(writer, indent, ctx, locals, it);
			return writeExprDone();
		},
		(in LowExprKind.UnionAs x) =>
			writeUnionAs(writer, indent, ctx, locals, writeKind, type, x),
		(in LowExprKind.UnionKind x) =>
			writeUnionKind(writer, indent, ctx, locals, writeKind, type, x),
		(in LowExprKind.VarGet x) =>
			inlineableSimple(() {
				writeLowVarMangledName(writer, ctx.mangledNames, x.varIndex, ctx.program.vars[x.varIndex]);
			}),
		(in LowExprKind.VarSet x) {
			WriteKind varWriteKind = WriteKind(x.varIndex);
			cast(void) writeExpr(writer, indent, ctx, locals, varWriteKind, *x.value);
			return writeReturnVoid(writer, indent, ctx, writeKind);
		});
}

WriteExprResult writeNonInlineable(
	scope ref Writer writer,
	size_t indent,
	scope ref FunBodyCtx ctx,
	in WriteKind writeKind,
	in LowType type,
	in void delegate() @safe @nogc pure nothrow cb,
) {
	if (!writeKind.isA!(WriteKind.Inline))
		writeNewline(writer, indent);
	WriteExprResult makeTemp() {
		Temp temp = getNextTemp(ctx);
		if (!isEmptyType(ctx, type)) {
			writeTempDeclare(writer, ctx, type, temp);
			writer ~= " = ";
		}
		return WriteExprResult(temp);
	}
	WriteExprResult res = castNonScope_ref(writeKind).matchIn!WriteExprResult(
		(in WriteKind.Inline) =>
			writeExprDone(),
		(in WriteKind.InlineOrTemp) =>
			makeTemp(),
		(in LowLocal x) {
			writeLowLocalName(writer, ctx.mangledNames, x);
			writer ~= " = ";
			return writeExprDone();
		},
		(in LowVarIndex x) {
			writeLowVarMangledName(writer, ctx.mangledNames, x, ctx.program.vars[x]);
			writer ~= " = ";
			return writeExprDone();
		},
		(in MakeTemp) =>
			makeTemp(),
		(in WriteKind.Return) {
			writer ~= "return ";
			return writeExprDone();
		},
		(in WriteKind.UseTemp x) {
			writeTempRef(writer, x.temp);
			writer ~= " = ";
			return writeExprDone();
		},
		(in WriteKind.Void) =>
			writeExprDone());
	cb();
	if (!writeKind.isA!(WriteKind.Inline))
		writer ~= ';';
	return res;
}

WriteExprResult writeVoid(in WriteKind writeKind) {
	assert(writeKind.isA!(WriteKind.Void));
	return WriteExprResult(WriteExprResult.Done());
}

WriteExprResult writeInlineable(
	scope ref Writer writer,
	size_t indent,
	scope ref FunBodyCtx ctx,
	in Locals locals,
	in WriteKind writeKind,
	in LowType type,
	in LowExpr[] args,
	in void delegate(in WriteExprResult[]) @safe @nogc pure nothrow inline,
) {
	if (writeKind.isA!(WriteKind.InlineOrTemp))
		return WriteExprResult(WriteExprResult.Done(writeExprsTempOrInline(writer, indent, ctx, locals, args)));
	else if (writeKind.isA!(WriteKind.Inline)) {
		inline(writeKind.as!(WriteKind.Inline).args);
		return writeExprDone();
	} else {
		WriteExprResult[] argTemps = writeExprsTempOrInline(writer, indent, ctx, locals,args);
		return writeNonInlineable(writer, indent, ctx, writeKind, type, () {
			inline(argTemps);
		});
	}
}

WriteExprResult writeInlineableSingleArg(
	scope ref Writer writer,
	size_t indent,
	scope ref FunBodyCtx ctx,
	in Locals locals,
	in WriteKind writeKind,
	in LowType type,
	in LowExpr arg,
	in void delegate(in WriteExprResult) @safe @nogc pure nothrow inline,
) =>
	writeInlineable(
		writer, indent, ctx, locals, writeKind, type, [castNonScope_ref(arg)],
		(in WriteExprResult[] args) {
			inline(only(args));
		});

WriteExprResult writeInlineableSimple(
	scope ref Writer writer,
	size_t indent,
	scope ref FunBodyCtx ctx,
	in Locals locals,
	in WriteKind writeKind,
	in LowType type,
	in void delegate() @safe @nogc pure nothrow inline,
) =>
	writeInlineable(writer, indent, ctx, locals, writeKind, type, [], (in WriteExprResult[]) {
		if (!isEmptyType(ctx, type))
			inline();
	});

WriteExprResult writeReturnVoid(
	scope ref Writer writer,
	size_t indent,
	scope ref FunBodyCtx ctx,
	in WriteKind writeKind,
) =>
	writeReturnVoid(writer, indent, ctx, writeKind, null);

WriteExprResult writeReturnVoid(
	scope ref Writer writer,
	size_t indent,
	scope ref FunBodyCtx ctx,
	in WriteKind writeKind,
	in void delegate() @safe @nogc pure nothrow cb,
) =>
	castNonScope_ref(writeKind).matchIn!WriteExprResult(
		(in WriteKind.Inline) =>
			assert(false),
		(in WriteKind.InlineOrTemp) =>
			assert(false),
		(in LowLocal) =>
			assert(false),
		(in LowVarIndex) =>
			assert(false),
		(in WriteKind.MakeTemp) =>
			assert(false),
		(in WriteKind.Return) {
			if (cb != null) {
				writeNewline(writer, indent);
				cb();
			}
			writer ~= ';';
			writeNewline(writer, indent);
			writer ~= "return;";
			return writeExprDone();
		},
		(in WriteKind.UseTemp) =>
			assert(false),
		(in WriteKind.Void) {
			if (cb != null) {
				writeNewline(writer, indent);
				cb();
				writer ~= ';';
			}
			return writeExprDone();
		});

WriteExprResult writeCallExpr(
	scope ref Writer writer,
	size_t indent,
	scope ref FunBodyCtx ctx,
	in Locals locals,
	in WriteKind writeKind,
	in LowType type,
	in LowExprKind.Call a,
) {
	WriteExprResult[] args = writeExprsTempOrInline(writer, indent, ctx, locals, a.args);
	return writeNonInlineable(writer, indent, ctx, writeKind, type, () {
		writeLowFunMangledName(writer, ctx.mangledNames, a.called, ctx.program.allFuns[a.called]);
		writer ~= '(';
		writeTempOrInlines(writer, ctx, locals, a.args, args);
		writer ~= ')';
	});
}

void writeTailRecur(
	scope ref Writer writer,
	size_t indent,
	scope ref FunBodyCtx ctx,
	in Locals locals,
	in LowExprKind.TailRecur a,
) {
	WriteExprResult[] newValues =
		map(ctx.tempAlloc, a.updateParams, (ref UpdateParam updateParam) =>
			writeExprTempOrInline(writer, indent, ctx, locals, updateParam.newValue));
	zip!(UpdateParam, WriteExprResult)(
		a.updateParams,
		newValues,
		(ref UpdateParam updateParam, ref WriteExprResult newValue) {
			if (!isEmptyType(ctx, updateParam.param.type)) {
				writeNewline(writer, indent);
				writeLowLocalName(writer, ctx.mangledNames, *updateParam.param);
				writer ~= " = ";
				writeTempOrInline(writer, ctx, locals, updateParam.newValue, newValue);
				writer ~= ';';
			}
		});
	writeNewline(writer, indent);
	writer ~= "goto top;";
}

void writeCreateUnion(
	scope ref Writer writer,
	scope ref Ctx ctx,
	ConstantRefPos pos,
	in LowType type,
	size_t memberIndex,
	in void delegate() @safe @nogc pure nothrow cbWriteMember,
) {
	if (pos == ConstantRefPos.outer) writeCastToType(writer, ctx, type);
	writer ~= '{';
	writer ~= memberIndex;
	LowType memberType = ctx.program.allUnions[type.as!(LowType.Union)].members[memberIndex];
	if (!isEmptyType(ctx, memberType)) {
		writer ~= ", .as";
		writer ~= memberIndex;
		writer ~= " = ";
		cbWriteMember();
	}
	writer ~= '}';
}

void writeFunPointer(scope ref Writer writer, scope ref Ctx ctx, LowFunIndex a) {
	writeLowFunMangledName(writer, ctx.mangledNames, a, ctx.program.allFuns[a]);
}

WriteExprResult writeMatchUnion(
	scope ref Writer writer,
	size_t indent,
	scope ref FunBodyCtx ctx,
	in Locals locals,
	in WriteKind writeKind,
	in LowType type,
	in LowExprKind.MatchUnion a,
) {
	Temp matchedValue = writeExprTemp(writer, indent, ctx, locals, a.matchedValue);
	WriteExprResultAndNested nested = getNestedWriteKind(writer, indent, ctx, type, castNonScope_ref(writeKind));
	writeNewline(writer, indent);
	writer ~= "switch (";
	writeTempRef(writer, matchedValue);
	writer ~= ".kind) {";
	foreach (size_t caseIndex, ref LowExprKind.MatchUnion.Case case_; a.cases) {
		writeNewline(writer, indent + 1);
		writer ~= "case ";
		writer ~= caseIndex;
		writer ~= ": {";
		if (has(case_.local) && !isEmptyType(ctx, force(case_.local).type)) {
			writeDeclareLocal(writer, indent + 2, ctx, *force(case_.local));
			writer ~= " = ";
			writeTempRef(writer, matchedValue);
			writer ~= ".as";
			writer ~= caseIndex;
			writer ~= ';';
			writeNewline(writer, indent + 2);
		}
		cast(void) writeExpr(writer, indent + 2, ctx, locals, nested.writeKind, case_.then);
		if (!nested.writeKind.isA!(WriteKind.Return)) {
			writeNewline(writer, indent + 2);
			writer ~= "break;";
		}
		writeNewline(writer, indent + 1);
		writer ~= '}';
	}
	writeDefaultAbort(writer, indent, ctx, locals, nested.writeKind, type);
	writeNewline(writer, indent);
	writer ~= '}';
	return nested.result;
}

void writeDefaultAbort(
	scope ref Writer writer,
	size_t indent,
	scope ref FunBodyCtx ctx,
	in Locals locals,
	in WriteKind writeKind,
	in LowType type,
) {
	writeNewline(writer, indent + 1);
	writer ~= "default:";
	writeNewline(writer, indent + 2);
	writer ~= "abort();";
	if (ctx.ctx.isMSVC && !isEmptyType(ctx, type)) {
		cast(void) writeInlineableSimple(writer, indent, ctx, locals, writeKind, type, () {
			writeZeroedValue(writer, ctx.ctx, type);
		});
		writer ~= ';';
	}
}

//TODO: share code with writeMatchUnion
WriteExprResult writeSwitch(
	scope ref Writer writer,
	size_t indent,
	scope ref FunBodyCtx ctx,
	in Locals locals,
	in WriteKind writeKind,
	in LowType type, // type returned by the switch
	in LowExpr value,
	in LowExpr[] cases,
	in EnumValue delegate(size_t) @safe @nogc pure nothrow getValue,
) {
	WriteExprResult valueResult = writeExprTempOrInline(writer, indent, ctx, locals, value);
	WriteExprResultAndNested nested = getNestedWriteKind(writer, indent, ctx, type, castNonScope_ref(writeKind));
	writer ~= "switch (";
	writeTempOrInline(writer, ctx, locals, value, valueResult);
	writer ~= ") {";
	foreach (size_t caseIndex, ref LowExpr case_; cases) {
		writeNewline(writer, indent + 1);
		writer ~= "case ";
		if (isSignedIntegral(value.type.as!PrimitiveType))
			writer ~= getValue(caseIndex).asSigned();
		else
			writer ~= getValue(caseIndex).asUnsigned();
		writer ~= ": {";
		cast(void) writeExpr(writer, indent + 2, ctx, locals, nested.writeKind, case_);
		if (!nested.writeKind.isA!(WriteKind.Return)) {
			writeNewline(writer, indent + 2);
			writer ~= "break;";
		}
		writeNewline(writer, indent + 1);
		writer ~= '}';
	}
	writeDefaultAbort(writer, indent, ctx, locals, writeKind, type);
	writeNewline(writer, indent);
	writer ~= '}';
	return nested.result;
}

bool isSignedIntegral(PrimitiveType a) {
	final switch (a) {
		case PrimitiveType.char8:
		case PrimitiveType.char32:
		case PrimitiveType.float32:
		case PrimitiveType.float64:
		case PrimitiveType.void_:
			assert(false);
		case PrimitiveType.int8:
		case PrimitiveType.int16:
		case PrimitiveType.int32:
		case PrimitiveType.int64:
			return true;
		case PrimitiveType.bool_:
		case PrimitiveType.nat8:
		case PrimitiveType.nat16:
		case PrimitiveType.nat32:
		case PrimitiveType.nat64:
			return false;
	}
}

void writeRecordFieldRef(
	scope ref Writer writer,
	in FunBodyCtx ctx,
	bool targetIsPointer,
	LowType.Record record,
	size_t fieldIndex,
) {
	writer ~= targetIsPointer ? "->" : ".";
	writeMangledName(
		writer,
		ctx.mangledNames,
		debugName(ctx.program.allRecords[record].fields[fieldIndex]));
}

// For some reason, providing a type for a record makes it non-constant.
// But that is mandatory at the outermost level.
enum ConstantRefPos {
	outer,
	inner,
}

void writeConstantRef(
	scope ref Writer writer,
	scope ref Ctx ctx,
	ConstantRefPos pos,
	in LowType type,
	in Constant a,
) {
	assert(!isEmptyType(ctx, type));
	a.matchIn!void(
		(in Constant.ArrConstant x) {
			if (pos == ConstantRefPos.outer) writeCastToType(writer, ctx, type);
			size_t size = ctx.program.allConstants.arrs[x.typeIndex].constants[x.index].length;
			writer ~= '{';
			writer ~= size;
			writer ~= ", ";
			if (size == 0)
				writer ~= "NULL";
			else
				writeConstantArrStorageName(writer, ctx.mangledNames, ctx.program, type.as!(LowType.Record), x.index);
			writer ~= '}';
		},
		(in Constant.CString x) {
			writeCStringName(writer, x.index);
		},
		(in Constant.Float x) {
			switch (type.as!PrimitiveType) {
				case PrimitiveType.float32:
					writeCastToType(writer, ctx, type);
					break;
				case PrimitiveType.float64:
					break;
				default:
					assert(false);
			}
			writeFloatLiteral(writer, x.value);
		},
		(in Constant.FunPointer it) {
			bool isRawPtr = type.match!bool(
				(LowType.Extern) => assert(false),
				(LowType.FunPointer) => false,
				(PrimitiveType _) => assert(false),
				(LowType.PtrGc) => assert(false),
				(LowType.PtrRawConst) => true,
				(LowType.PtrRawMut) => true,
				(LowType.Record) => assert(false),
				(LowType.Union) => assert(false));
			if (isRawPtr)
				writer ~= "((uint8_t*)";
			writeFunPointer(writer, ctx, mustGet(ctx.program.concreteFunToLowFunIndex, it.fun));
			if (isRawPtr)
				writer ~= ')';
		},
		(in Constant.Integral x) {
			PrimitiveType primitive = type.as!PrimitiveType;
			if (primitive == PrimitiveType.char8 || primitive == PrimitiveType.char32) {
				if (!ctx.isMSVC && isValidUnicodeCharacter(cast(dchar) x.value)) {
					writer ~= "'";
					writeEscapedCharForC(writer, cast(dchar) x.value);
					writer ~= "'";
				} else
					writer ~= cast(uint) x.value;
			} else if (isSignedIntegral(primitive)) {
				if (x.value == int.min)
					writer ~= "INT32_MIN";
				else if (x.value == long.min)
					// Can't write this as a literal since the '-' and rest are parsed separately,
					// and the abs of the minimum integer is out of range.
					writer ~= "INT64_MIN";
				else {
					writer ~= x.value;
					if (primitive == PrimitiveType.int64)
						writer ~= 'l';
				}
			} else {
				writer ~= cast(ulong) x.value;
				writer ~= 'u';
				if (primitive == PrimitiveType.nat64)
					writer ~= "ll";
			}
		},
		(in Constant.Pointer it) {
			writer ~= '&';
			writeConstantPointerStorageName(writer, ctx.mangledNames, ctx.program, asPtrGcPointee(type), it.index);
		},
		(in Constant.Record it) {
			LowField[] fields = ctx.program.allRecords[type.as!(LowType.Record)].fields;
			assert(sizeEq(fields, it.args));
			if (pos == ConstantRefPos.outer)
				writeCastToType(writer, ctx, type);
			writer ~= '{';
			writeWithCommasZip!(LowField, Constant)(
				writer,
				fields,
				it.args,
				(in LowField field, in Constant arg) =>
					!isEmptyType(ctx, field.type),
				(in LowField field, in Constant arg) {
					writeConstantRef(writer, ctx, ConstantRefPos.inner, field.type, arg);
				});
			writer ~= '}';
		},
		(in Constant.Union it) {
			LowType memberType = ctx.program.allUnions[type.as!(LowType.Union)].members[it.memberIndex];
			writeCreateUnion(writer, ctx, pos, type, it.memberIndex, () {
				writeConstantRef(writer, ctx, ConstantRefPos.inner, memberType, it.arg);
			});
		},
		(in Constant.Zero) {
			writeZeroedValue(writer, ctx, type);
		});
}

void writeStringLiteralWithoutNul(scope ref Writer writer, bool isMSVC, in string a) {
	writer ~= '"';
	writeStringLiteralInner(writer, isMSVC, a);
	writer ~= '"';
}

void writeStringLiteralWithNul(scope ref Writer writer, bool isMSVC, in string a) {
	writer ~= '"';
	writeStringLiteralInner(writer, isMSVC, a);
	writer ~= "\\0";
	writer ~= '"';
}

void writeStringLiteralInner(scope ref Writer writer, bool isMSVC, in string a) {
	size_t chunk = 0;
	mustUnicodeDecode(a, (dchar x) {
		writeEscapedCharForC(writer, x);
		if (isMSVC) {
			// Avoid error with MSVC: "error C2026: string too big, trailing characters truncated"
			chunk++;
			if (chunk == 2048) {
				writer ~= '"';
				writer ~= '"';
				chunk = 0;
			}
		}
	});
}

WriteExprResult writePtrToField(
	scope ref Writer writer,
	size_t indent,
	scope ref FunBodyCtx ctx,
	in Locals locals,
	in WriteKind writeKind,
	in LowType type,
	in LowExprKind.PtrToField a,
) =>
	writeInlineableSingleArg(writer, indent, ctx, locals, writeKind, type, a.target, (in WriteExprResult recordValue) {
		writer ~= "(&";
		writeTempOrInline(writer, ctx, locals, a.target, recordValue);
		writeRecordFieldRef(writer, ctx, true, targetRecordType(a), a.fieldIndex);
		writer ~= ')';
	});

WriteExprResult writeRecordFieldGet(
	scope ref Writer writer,
	size_t indent,
	scope ref FunBodyCtx ctx,
	in Locals locals,
	in WriteKind writeKind,
	in LowType type,
	in LowExprKind.RecordFieldGet a,
) =>
	writeInlineableSingleArg(writer, indent, ctx, locals, writeKind, type, *a.target, (in WriteExprResult recordValue) {
		if (!isEmptyType(ctx, type)) {
			writeTempOrInline(writer, ctx, locals, *a.target, recordValue);
			writeRecordFieldRef(writer, ctx, targetIsPointer(a), targetRecordType(a), a.fieldIndex);
		}
	});

WriteExprResult writeUnionAs(
	scope ref Writer writer,
	size_t indent,
	scope ref FunBodyCtx ctx,
	in Locals locals,
	in WriteKind writeKind,
	in LowType type,
	in LowExprKind.UnionAs a,
) =>
	writeInlineableSingleArg(writer, indent, ctx, locals, writeKind, type, *a.union_, (in WriteExprResult unionValue) {
		if (!isEmptyType(ctx, type)) {
			writeTempOrInline(writer, ctx, locals, *a.union_, unionValue);
			writer ~= ".as";
			writer ~= a.memberIndex;
		}
	});

WriteExprResult writeUnionKind(
	scope ref Writer writer,
	size_t indent,
	scope ref FunBodyCtx ctx,
	in Locals locals,
	in WriteKind writeKind,
	in LowType type,
	in LowExprKind.UnionKind a,
) =>
	writeInlineableSingleArg(writer, indent, ctx, locals, writeKind, type, *a.union_, (in WriteExprResult unionValue) {
		if (!isEmptyType(ctx, type)) {
			writeTempOrInline(writer, ctx, locals, *a.union_, unionValue);
			writer ~= ".kind";
		}
	});

WriteExprResult writeSpecialUnary(
	scope ref Writer writer,
	size_t indent,
	scope ref FunBodyCtx ctx,
	in Locals locals,
	in WriteKind writeKind,
	in LowType type,
	in LowExprKind.SpecialUnary a,
) {
	WriteExprResult prefix(string prefix) =>
		writeInlineableSingleArg(
			writer, indent, ctx, locals, writeKind, type, a.arg,
			(in WriteExprResult temp) {
				writer ~= '(';
				writer ~= prefix;
				writeTempOrInline(writer, ctx, locals, a.arg, temp);
				writer ~= ')';
			});

	WriteExprResult writeCast() =>
		writeInlineableSingleArg(
			writer, indent, ctx, locals, writeKind, type, a.arg,
			(in WriteExprResult temp) {
				if (isEmptyType(ctx, a.arg.type))
					writeTempOrInline(writer, ctx, locals, a.arg, temp);
				else {
					writer ~= '(';
					writeCastToType(writer, ctx.ctx, type);
					writeTempOrInline(writer, ctx, locals, a.arg, temp);
					writer ~= ')';
				}
			});

	final switch (a.kind) {
		case BuiltinUnary.asAnyPtr:
			return prefix("(uint8_t*) ");
		case BuiltinUnary.deref:
			return prefix("*");
		case BuiltinUnary.drop:
			return a.arg.kind.isA!(Constant) ? writeVoid(writeKind) : writeCast();
		case BuiltinUnary.enumToIntegral:
		case BuiltinUnary.toChar8FromNat8:
		case BuiltinUnary.toFloat32FromFloat64:
		case BuiltinUnary.toFloat64FromFloat32:
		case BuiltinUnary.toFloat64FromInt64:
		case BuiltinUnary.toFloat64FromNat64:
		case BuiltinUnary.toInt64FromInt8:
		case BuiltinUnary.toInt64FromInt16:
		case BuiltinUnary.toInt64FromInt32:
		case BuiltinUnary.toNat8FromChar8:
		case BuiltinUnary.toNat32FromChar32:
		case BuiltinUnary.toNat64FromNat8:
		case BuiltinUnary.toNat64FromNat16:
		case BuiltinUnary.toNat64FromNat32:
		case BuiltinUnary.toNat64FromPtr:
		case BuiltinUnary.toPtrFromNat64:
		case BuiltinUnary.truncateToInt64FromFloat64:
		case BuiltinUnary.unsafeToChar32FromChar8:
		case BuiltinUnary.unsafeToChar32FromNat32:
		case BuiltinUnary.unsafeToInt8FromInt64:
		case BuiltinUnary.unsafeToInt16FromInt64:
		case BuiltinUnary.unsafeToInt32FromInt64:
		case BuiltinUnary.unsafeToInt64FromNat64:
		case BuiltinUnary.unsafeToNat8FromNat64:
		case BuiltinUnary.unsafeToNat16FromNat64:
		case BuiltinUnary.unsafeToNat32FromInt32:
		case BuiltinUnary.unsafeToNat32FromNat64:
		case BuiltinUnary.unsafeToNat64FromInt64:
			return writeCast();
		case BuiltinUnary.bitwiseNotNat8:
		case BuiltinUnary.bitwiseNotNat16:
		case BuiltinUnary.bitwiseNotNat32:
		case BuiltinUnary.bitwiseNotNat64:
			return prefix("~");
		case BuiltinUnary.countOnesNat64:
			string name = ctx.ctx.isMSVC ? "__popcnt64" : "__builtin_popcountl";
			return specialCallUnary(writer, indent, ctx, locals, writeKind, type, a.arg, name);
	}
}

WriteExprResult specialCallUnary(
	scope ref Writer writer,
	size_t indent,
	scope ref FunBodyCtx ctx,
	in Locals locals,
	in WriteKind writeKind,
	in LowType type,
	in LowExpr arg,
	in string name,
) =>
	writeInlineableSingleArg(
		writer, indent, ctx, locals, writeKind, type, arg,
		(in WriteExprResult temp) {
			writer ~= name;
			writer ~= '(';
			writeTempOrInline(writer, ctx, locals, arg, temp);
			writer ~= ')';
		});

WriteExprResult specialCallBinary(
	scope ref Writer writer,
	size_t indent,
	scope ref FunBodyCtx ctx,
	in Locals locals,
	in WriteKind writeKind,
	in LowType type,
	in LowExpr[2] args,
	in string name,
) {
	return writeInlineable(
		writer, indent, ctx, locals, writeKind, type, castNonScope(args),
		(in WriteExprResult[] temps) {
			writer ~= name;
			writer ~= '(';
			writeTempOrInlines(writer, ctx, locals, castNonScope(args), temps);
			writer ~= ')';
		});
}

void writeZeroedValue(scope ref Writer writer, scope ref Ctx ctx, in LowType type) {
	type.combinePointer.matchIn!void(
		(in LowType.Extern x) {
			writeExternZeroed(writer, ctx, x);
		},
		(in LowType.FunPointer) {
			writer ~= "NULL";
		},
		(in PrimitiveType it) {
			assert(it != PrimitiveType.void_);
			writer ~= '0';
		},
		(in LowPtrCombine _) {
			writer ~= "NULL";
		},
		(in LowType.Record it) {
			writeCastToType(writer, ctx, type);
			writer ~= '{';
			LowField[] fields = ctx.program.allRecords[it].fields;
			writeWithCommas!LowField(
				writer,
				fields,
				(in LowField field) =>
					!isEmptyType(ctx, field.type),
				(in LowField field) {
					writeZeroedValue(writer, ctx, field.type);
				});
			writer ~= '}';
		},
		(in LowType.Union) {
			writeCastToType(writer, ctx, type);
			writer ~= "{0}";
		});
}

void writeExternZeroed(scope ref Writer writer, scope ref Ctx ctx, LowType.Extern type) {
	writeCastToType(writer, ctx, LowType(type));
	writer ~= "{{0}}";
}

WriteExprResult writeSpecialBinary(
	scope ref Writer writer,
	size_t indent,
	scope ref FunBodyCtx ctx,
	in Locals locals,
	in WriteKind writeKind,
	in LowType type,
	in LowExprKind.SpecialBinary a,
) {
	LowExpr left = a.args[0], right = a.args[1];
	WriteExprResult arg0() {
		return writeExprTempOrInline(writer, indent, ctx, locals, left);
	}
	WriteExprResult arg1() {
		return writeExprTempOrInline(writer, indent, ctx, locals, right);
	}

	WriteExprResult operator(string op) {
		return writeInlineable(
			writer, indent, ctx, locals, writeKind, type, [castNonScope_ref(left), castNonScope_ref(right)],
			(in WriteExprResult[] args) {
				assert(args.length == 2);
				writer ~= '(';
				writeTempOrInline(writer, ctx, locals, left, args[0]);
				writer ~= ' ';
				writer ~= op;
				writer ~= ' ';
				writeTempOrInline(writer, ctx, locals, right, args[1]);
				writer ~= ')';
			});
	}

	final switch (a.kind) {
		case BuiltinBinary.addFloat32:
		case BuiltinBinary.addFloat64:
		case BuiltinBinary.addPtrAndNat64:
		case BuiltinBinary.unsafeAddInt8:
		case BuiltinBinary.unsafeAddInt16:
		case BuiltinBinary.unsafeAddInt32:
		case BuiltinBinary.unsafeAddInt64:
		case BuiltinBinary.wrapAddNat8:
		case BuiltinBinary.wrapAddNat16:
		case BuiltinBinary.wrapAddNat32:
		case BuiltinBinary.wrapAddNat64:
			return operator("+");
		case BuiltinBinary.and:
			return writeLogicalOperator(
				writer,
				indent,
				ctx,
				locals,
				writeKind,
				LogicalOperator.and,
				left,
				right);
		case BuiltinBinary.bitwiseAndInt8:
		case BuiltinBinary.bitwiseAndInt16:
		case BuiltinBinary.bitwiseAndInt32:
		case BuiltinBinary.bitwiseAndInt64:
		case BuiltinBinary.bitwiseAndNat8:
		case BuiltinBinary.bitwiseAndNat16:
		case BuiltinBinary.bitwiseAndNat32:
		case BuiltinBinary.bitwiseAndNat64:
			return operator("&");
		case BuiltinBinary.bitwiseOrInt8:
		case BuiltinBinary.bitwiseOrInt16:
		case BuiltinBinary.bitwiseOrInt32:
		case BuiltinBinary.bitwiseOrInt64:
		case BuiltinBinary.bitwiseOrNat8:
		case BuiltinBinary.bitwiseOrNat16:
		case BuiltinBinary.bitwiseOrNat32:
		case BuiltinBinary.bitwiseOrNat64:
			return operator("|");
		case BuiltinBinary.bitwiseXorInt8:
		case BuiltinBinary.bitwiseXorInt16:
		case BuiltinBinary.bitwiseXorInt32:
		case BuiltinBinary.bitwiseXorInt64:
		case BuiltinBinary.bitwiseXorNat8:
		case BuiltinBinary.bitwiseXorNat16:
		case BuiltinBinary.bitwiseXorNat32:
		case BuiltinBinary.bitwiseXorNat64:
			return operator("^");
		case BuiltinBinary.eqChar8:
		case BuiltinBinary.eqChar32:
		case BuiltinBinary.eqFloat32:
		case BuiltinBinary.eqFloat64:
		case BuiltinBinary.eqInt8:
		case BuiltinBinary.eqInt16:
		case BuiltinBinary.eqInt32:
		case BuiltinBinary.eqInt64:
		case BuiltinBinary.eqNat8:
		case BuiltinBinary.eqNat16:
		case BuiltinBinary.eqNat32:
		case BuiltinBinary.eqNat64:
		case BuiltinBinary.eqPtr:
			return operator("==");
		case BuiltinBinary.lessChar8:
		case BuiltinBinary.lessFloat32:
		case BuiltinBinary.lessFloat64:
		case BuiltinBinary.lessInt8:
		case BuiltinBinary.lessInt16:
		case BuiltinBinary.lessInt32:
		case BuiltinBinary.lessInt64:
		case BuiltinBinary.lessNat8:
		case BuiltinBinary.lessNat16:
		case BuiltinBinary.lessNat32:
		case BuiltinBinary.lessNat64:
		case BuiltinBinary.lessPtr:
			return operator("<");
		case BuiltinBinary.mulFloat32:
		case BuiltinBinary.mulFloat64:
		case BuiltinBinary.unsafeMulInt8:
		case BuiltinBinary.unsafeMulInt16:
		case BuiltinBinary.unsafeMulInt32:
		case BuiltinBinary.unsafeMulInt64:
		case BuiltinBinary.wrapMulNat8:
		case BuiltinBinary.wrapMulNat16:
		case BuiltinBinary.wrapMulNat32:
		case BuiltinBinary.wrapMulNat64:
			return operator("*");
		case BuiltinBinary.orBool:
			return writeLogicalOperator(
				writer,
				indent,
				ctx,
				locals,
				writeKind,
				LogicalOperator.or,
				left,
				right);
		case BuiltinBinary.seq:
			if (!writeKind.isA!(WriteKind.Inline))
				writeExprVoid(writer, indent, ctx, locals, left);
			return writeExpr(writer, indent, ctx, locals, writeKind, right);
		case BuiltinBinary.subFloat32:
		case BuiltinBinary.subFloat64:
		case BuiltinBinary.subPtrAndNat64:
		case BuiltinBinary.unsafeSubInt8:
		case BuiltinBinary.unsafeSubInt16:
		case BuiltinBinary.unsafeSubInt32:
		case BuiltinBinary.unsafeSubInt64:
		case BuiltinBinary.wrapSubNat8:
		case BuiltinBinary.wrapSubNat16:
		case BuiltinBinary.wrapSubNat32:
		case BuiltinBinary.wrapSubNat64:
			return operator("-");
		case BuiltinBinary.unsafeBitShiftLeftNat64:
			return operator("<<");
		case BuiltinBinary.unsafeBitShiftRightNat64:
			return operator(">>");
		case BuiltinBinary.unsafeDivFloat32:
		case BuiltinBinary.unsafeDivFloat64:
		case BuiltinBinary.unsafeDivInt8:
		case BuiltinBinary.unsafeDivInt16:
		case BuiltinBinary.unsafeDivInt32:
		case BuiltinBinary.unsafeDivInt64:
		case BuiltinBinary.unsafeDivNat8:
		case BuiltinBinary.unsafeDivNat16:
		case BuiltinBinary.unsafeDivNat32:
		case BuiltinBinary.unsafeDivNat64:
			return operator("/");
		case BuiltinBinary.unsafeModNat64:
			return operator("%");
		case BuiltinBinary.writeToPtr:
			WriteExprResult temp0 = arg0();
			WriteExprResult temp1 = arg1();
			return writeReturnVoid(writer, indent, ctx, writeKind, () {
				if (!isEmptyType(ctx, right.type)) {
					writer ~= "*";
					writeTempOrInline(writer, ctx, locals, left, temp0);
					writer ~= " = ";
					writeTempOrInline(writer, ctx, locals, right, temp1);
				}
			});
	}
}

enum LogicalOperator { and, or }

immutable struct WriteExprResultAndNested {
	WriteExprResult result;
	WriteKind writeKind;
}

// If we need to make a temporary, have to do that in an outer scope and write to it in an inner scope
WriteExprResultAndNested getNestedWriteKind(
	scope ref Writer writer,
	size_t indent,
	scope ref FunBodyCtx ctx,
	in LowType type,
	return scope ref WriteKind writeKind,
) {
	if (isEmptyType(ctx, type)) {
		assert(writeKind.isA!(WriteKind.Void) || writeKind.isA!(WriteKind.Return));
		return WriteExprResultAndNested(writeExprDone(), writeKind);
	} if (writeKind.isA!(WriteKind.MakeTemp) || writeKind.isA!(WriteKind.InlineOrTemp)) {
		Temp temp = getNextTemp(ctx);
		writeTempDeclare(writer, ctx, type, temp);
		writer ~= ';';
		writeNewline(writer, indent);
		return WriteExprResultAndNested(WriteExprResult(temp), WriteKind(WriteKind.UseTemp(temp)));
	} else
		return WriteExprResultAndNested(writeExprDone(), writeKind);
}

WriteExprResult writeLogicalOperator(
	scope ref Writer writer,
	size_t indent,
	scope ref FunBodyCtx ctx,
	in Locals locals,
	in WriteKind writeKind,
	LogicalOperator operator,
	in LowExpr left,
	in LowExpr right,
) {
	/*
	`a && b` ==> `if (a) { return b; } else { return 0; }`
	`a || b` ==> `if (a) { return 1; } else { return b; }`
	*/
	WriteExprResult cond = writeExprTempOrInline(writer, indent, ctx, locals, left);
	WriteExprResultAndNested nested = getNestedWriteKind(writer, indent, ctx, boolType, castNonScope_ref(writeKind));
	writeNewline(writer, indent);
	writer ~= "if (";
	writeTempOrInline(writer, ctx, locals, left, cond);
	writer ~= ") {";
	final switch (operator) {
		case LogicalOperator.and:
			cast(void) writeExpr(writer, indent + 1, ctx, locals, nested.writeKind, right);
			break;
		case LogicalOperator.or:
			cast(void) writeNonInlineable(writer, indent + 1, ctx, nested.writeKind, boolType, () {
				writer ~= '1';
			});
			break;
	}
	writeNewline(writer, indent);
	writer ~= "} else {";
	final switch (operator) {
		case LogicalOperator.and:
			cast(void) writeNonInlineable(writer, indent + 1, ctx, nested.writeKind, boolType, () {
				writer ~= '0';
			});
			break;
		case LogicalOperator.or:
			cast(void) writeExpr(writer, indent + 1, ctx, locals, nested.writeKind, right);
			break;
	}
	writeNewline(writer, indent);
	writer ~= '}';
	return nested.result;
}

WriteExprResult writeIf(
	scope ref Writer writer,
	size_t indent,
	scope ref FunBodyCtx ctx,
	in Locals locals,
	in WriteKind writeKind,
	in LowType type,
	in LowExprKind.If a,
) {
	// TODO: writeExprTempOrInline
	Temp temp0 = writeExprTemp(writer, indent, ctx, locals, a.cond);
	WriteExprResultAndNested nested = getNestedWriteKind(writer, indent, ctx, type, castNonScope_ref(writeKind));
	writeNewline(writer, indent);
	writer ~= "if (";
	writeTempRef(writer, temp0);
	writer ~= ") {";
	cast(void) writeExpr(writer, indent + 1, ctx, locals, nested.writeKind, a.then);
	writeNewline(writer, indent);
	writer ~= "} else {";
	cast(void) writeExpr(writer, indent + 1, ctx, locals, nested.writeKind, a.else_);
	writeNewline(writer, indent);
	writer ~= '}';
	return nested.result;
}

WriteExprResult writeCallFunPointer(
	scope ref Writer writer,
	size_t indent,
	scope ref FunBodyCtx ctx,
	in Locals locals,
	in WriteKind writeKind,
	in LowType type,
	in LowExprKind.CallFunPointer a,
) {
	WriteExprResult fn = writeExprTempOrInline(writer, indent, ctx, locals, a.funPtr);
	WriteExprResult[] args = writeExprsTempOrInline(writer, indent, ctx, locals, a.args);
	return writeNonInlineable(writer, indent, ctx, writeKind, type, () {
		writeTempOrInline(writer, ctx, locals, a.funPtr, fn);
		writer ~= '(';
		writeTempOrInlines(writer, ctx, locals, a.args, args);
		writer ~= ')';
	});
}

WriteExprResult writeLet(
	scope ref Writer writer,
	size_t indent,
	scope ref FunBodyCtx ctx,
	in Locals locals,
	in WriteKind writeKind,
	in LowExprKind.Let a,
) {
	if (!writeKind.isA!(WriteKind.Inline)) {
		if (isEmptyType(ctx, a.local.type))
			writeExprVoid(writer, indent, ctx, locals, a.value);
		else {
			writeDeclareLocal(writer, indent, ctx, *a.local);
			writer ~= ';';
			WriteKind localWriteKind = WriteKind(a.local);
			cast(void) writeExpr(writer, indent, ctx, locals, localWriteKind, a.value);
			writeNewline(writer, indent);
		}
	}
	return writeExpr(writer, indent, ctx, locals, writeKind, a.then);
}

WriteExprResult writeLocalSet(
	scope ref Writer writer,
	size_t indent,
	scope ref FunBodyCtx ctx,
	in Locals locals,
	in WriteKind writeKind,
	in LowExprKind.LocalSet a,
) {
	if (isEmptyType(ctx, a.local.type))
		writeExprVoid(writer, indent, ctx, locals, a.value);
	else {
		WriteKind localWriteKind = WriteKind(a.local);
		cast(void) writeExpr(writer, indent, ctx, locals, localWriteKind, a.value);
	}
	return writeReturnVoid(writer, indent, ctx, writeKind);
}

WriteExprResult writeLoop(
	scope ref Writer writer,
	size_t indent,
	scope ref FunBodyCtx ctx,
	in Locals locals,
	in WriteKind writeKind,
	in LowType type,
	in LowExprKind.Loop a,
) {
	WriteExprResultAndNested nested = getNestedWriteKind(writer, indent, ctx, type, castNonScope_ref(writeKind));

	size_t index = nextLoopIndex(ctx);
	LoopInfo loopInfo = LoopInfo(index, nested.writeKind);

	writeNewline(writer, indent);
	writer ~= "for (;;) {";
	writeNewline(writer, indent + 1);

	writeExprVoid(writer, indent + 1, ctx, addLoop(locals, ptrTrustMe(a), &loopInfo), a.body_);

	writeNewline(writer, indent);
	writer ~= '}';

	if (!nested.writeKind.isA!(WriteKind.Return)) {
		writeNewline(writer, indent);
		writer ~= "__break";
		writer ~= index;
		// Semicolon to avoid error "a label can only be part of a statement and a declaration is not a statement"
		writer ~= ":;";
	}

	return nested.result;
}

WriteExprResult writeLoopBreak(
	scope ref Writer writer,
	size_t indent,
	scope ref FunBodyCtx ctx,
	in Locals locals,
	in WriteKind writeKind,
	in LowExprKind.LoopBreak a,
) {
	assert(writeKind.isA!(WriteKind.Void));
	LoopInfo* info = getLoop(locals, a.loop);
	cast(void) writeExpr(writer, indent, ctx, locals, info.writeKind, a.value);
	if (!info.writeKind.isA!(WriteKind.Return)) {
		writeNewline(writer, indent);
		writer ~= "goto __break";
		writer ~= info.index;
		writer ~= ';';
	}
	return WriteExprResult(WriteExprResult.Done());
}

void writePrimitiveType(scope ref Writer writer, PrimitiveType a) {
	writer ~= () {
		final switch (a) {
			case PrimitiveType.bool_:
				return "uint8_t";
			case PrimitiveType.char8:
				return "char";
			case PrimitiveType.char32:
				return "char32_t";
			case PrimitiveType.float32:
				return "float";
			case PrimitiveType.float64:
				return "double";
			case PrimitiveType.int8:
				return "int8_t";
			case PrimitiveType.int16:
				return "int16_t";
			case PrimitiveType.int32:
				return "int32_t";
			case PrimitiveType.int64:
				return "int64_t";
			case PrimitiveType.nat8:
				return "uint8_t";
			case PrimitiveType.nat16:
				return "uint16_t";
			case PrimitiveType.nat32:
				return "uint32_t";
			case PrimitiveType.nat64:
				return "uint64_t";
			case PrimitiveType.void_:
				return "void";
		}
	}();
}
