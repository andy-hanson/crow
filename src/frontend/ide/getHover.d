module frontend.ide.getHover;

@safe @nogc pure nothrow:

import frontend.ide.getPosition : Position, PositionKind;
import frontend.showDiag : ShowDiagOptions, writeCalled, writeFunInst;
import model.diag : writeFile;
import model.model :
	AssertOrForbidKind,
	body_,
	ClosureRef,
	decl,
	Expr,
	ExprKind,
	FunDecl,
	FunKind,
	StructDecl,
	Local,
	Module,
	name,
	Program,
	SpecDecl,
	StructBody,
	Type,
	TypeParam,
	writeStructDecl,
	writeTypeUnquoted;
import util.alloc.alloc : Alloc, TempAlloc;
import util.col.str : SafeCStr;
import util.lineAndColumnGetter : lineAndColumnAtPos, PosKind;
import util.path : AllPaths, PathsInfo;
import util.ptr : ptrTrustMe;
import util.sym : AllSymbols, writeSym;
import util.writer : finishWriterToSafeCStr, Writer;

SafeCStr getHoverStr(
	ref TempAlloc tempAlloc,
	ref Alloc alloc,
	in AllSymbols allSymbols,
	in AllPaths allPaths,
	in PathsInfo pathsInfo,
	in Program program,
	in Position pos,
) {
	Writer writer = Writer(ptrTrustMe(alloc));
	getHover(tempAlloc, writer, allSymbols, allPaths, pathsInfo, program, pos);
	return finishWriterToSafeCStr(writer);
}

void getHover(
	ref TempAlloc tempAlloc,
	scope ref Writer writer,
	in AllSymbols allSymbols,
	in AllPaths allPaths,
	in PathsInfo pathsInfo,
	in Program program,
	in Position pos,
) =>
	pos.kind.matchIn!void(
		(in PositionKind.None) {},
		(in Expr x) {
			getExprHover(writer, allSymbols, allPaths, pathsInfo, program, *pos.module_, x);
		},
		(in FunDecl it) {
			writer ~= "function ";
			writeSym(writer, allSymbols, it.name);
		},
		(in PositionKind.ImportedModule x) {
			writer ~= "import module ";
			writeFile(writer, allPaths, pathsInfo, program.filesInfo, x.module_.fileIndex);
		},
		(in PositionKind.ImportedName x) {
			getImportedNameHover(writer, x);
		},
		(in PositionKind.Parameter x) {
			writer ~= "parameter ";
			writeSym(writer, allSymbols, x.local.name);
		},
		(in PositionKind.RecordFieldPosition x) {
			writer ~= "field ";
			writeStructDecl(writer, allSymbols, program, *x.struct_);
			writer ~= '.';
			writeSym(writer, allSymbols, x.field.name);
			writer ~= " (";
			writeTypeUnquoted(writer, allSymbols, program, x.field.type);
			writer ~= ')';
		},
		(in SpecDecl x) {
			writer ~= "spec ";
			writeSym(writer, allSymbols, x.name);
		},
		(in StructDecl x) {
			writer ~= body_(x).matchIn!string(
				(in StructBody.Bogus) =>
					"type ",
				(in StructBody.Builtin) =>
					"builtin type ",
				(in StructBody.Enum) =>
					"enum type ",
				(in StructBody.Extern) =>
					"extern type ",
				(in StructBody.Flags) =>
					"flags type ",
				(in StructBody.Record) =>
					"record ",
				(in StructBody.Union) =>
					"union ");
			writeSym(writer, allSymbols, x.name);
		},
		(in Type a) {
			writer ~= "TODO: hover for type";
		},
		(in TypeParam _) {
			writer ~= "TODO: hover for type param";
		});

private:

void getImportedNameHover(ref Writer writer, in PositionKind.ImportedName) {
	writer ~= "TODO: getImportedNameHover";
}

void getExprHover(
	ref Writer writer,
	in AllSymbols allSymbols,
	in AllPaths allPaths,
	in PathsInfo pathsInfo,
	in Program program,
	in Module curModule,
	in Expr a,
) =>
	a.kind.matchIn!void(
		(in ExprKind.AssertOrForbid x) {
			writer ~= "throws if the condition is ";
			writer ~= () {
				final switch (x.kind) {
					case AssertOrForbidKind.assert_:
						return "false";
					case AssertOrForbidKind.forbid:
						return "true";
				}
			}();
		},
		(in ExprKind.Bogus) {},
		(in ExprKind.Call x) {
			writeCalled(writer, allSymbols, allPaths, pathsInfo, ShowDiagOptions(false), program, x.called);
		},
		(in ExprKind.ClosureGet x) {
			writer ~= "gets ";
			closureRefHover(writer, allSymbols, program, *x.closureRef);
		},
		(in ExprKind.ClosureSet x) {
			writer ~= "sets ";
			closureRefHover(writer, allSymbols, program, *x.closureRef);
		},
		(in ExprKind.FunPtr x) {
			writer ~= "pointer to function ";
			writeFunInst(writer, allSymbols, allPaths, pathsInfo, ShowDiagOptions(false), program, *x.funInst);
		},
		(in ExprKind.If) {
			writer ~= "returns the first branch if the condition is 'true', " ~
				"and the second branch if the condition is 'false'";
		},
		(in ExprKind.IfOption) {
			writer ~= "returns the first branch if the option is non-empty, " ~
				"and the second branch if it is empty";
		},
		(in ExprKind.Lambda x) {
			writer ~= () {
				final switch (x.kind) {
					case FunKind.fun:
						return "function";
					case FunKind.act:
						return "'act' function";
					case FunKind.far:
						return "far function";
					case FunKind.pointer:
						return "function pointer";
				}
			}();
			writer ~= " literal";
		},
		(in ExprKind.Let) {},
		(in ExprKind.Literal) {},
		(in ExprKind.LiteralCString) {},
		(in ExprKind.LiteralSymbol) {},
		(in ExprKind.LocalGet x) {
			localHover(writer, allSymbols, program, *x.local);
		},
		(in ExprKind.LocalSet x) {
			writer ~= "sets ";
			localHover(writer, allSymbols, program, *x.local);
		},
		(in ExprKind.Loop) {
			writer ~= "loop that terminates at a 'break'";
		},
		(in ExprKind.LoopBreak x) {
			writer ~= "breaks out of ";
			writeLoop(writer, program, curModule, *x.loop);
		},
		(in ExprKind.LoopContinue x) {
			writer ~= "goes back to top of ";
			writeLoop(writer, program, curModule, *x.loop);
		},
		(in ExprKind.LoopUntil) {
			writer ~= "loop that runs as long as the condition is 'false'";
		},
		(in ExprKind.LoopWhile) {
			writer ~= "loop that runs as long as the condition is 'true'";
		},
		(in ExprKind.MatchEnum) {},
		(in ExprKind.MatchUnion) {},
		(in ExprKind.PtrToField x) {
			// TODO: ExprKind.PtrToField should have the RecordField
		},
		(in ExprKind.PtrToLocal x) {
			writer ~= "pointer to ";
			localHover(writer, allSymbols, program, *x.local);
		},
		(in ExprKind.Seq) {},
		(in ExprKind.Throw) {
			writer ~= "throws an exception";
		});

void closureRefHover(ref Writer writer, in AllSymbols allSymbols, in Program program, in ClosureRef a) {
	writer ~= "closure variable ";
	writeSym(writer, allSymbols, a.name);
	writer ~= ' ';
	writeTypeUnquoted(writer, allSymbols, program, a.type);
}

void localHover(ref Writer writer, in AllSymbols allSymbols, in Program program, in Local a) {
	writer ~= "local ";
	writeSym(writer, allSymbols, a.name);
	writer ~= " of type ";
	writeTypeUnquoted(writer, allSymbols, program, a.type);
}

void writeLoop(ref Writer writer, in Program program, in Module curModule, in ExprKind.Loop a) {
	writer ~= "loop on line ";
	writer ~= lineAndColumnAtPos(
		program.filesInfo.lineAndColumnGetters[curModule.fileIndex],
		a.range.start,
		PosKind.startOfRange,
	).line;
}
