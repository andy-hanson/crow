module backend.js.writeJsAst;

@safe @nogc pure nothrow:

import backend.js.jsAst :
	genAssign,
	genBool,
	genCall,
	genCallWithSpread,
	genConst,
	genEmptyStatement,
	genIf,
	genIn,
	genInstanceof,
	genIntegerSigned,
	genIntegerUnsigned,
	genLet,
	genNew,
	genNot,
	genNumber,
	genOr,
	genPropertyAccess,
	genReturn,
	genString,
	genSwitch,
	genThis,
	genThrow,
	genTryCatch,
	genVarDecl,
	genWhile,
	JsArrowFunction,
	JsAssignStatement,
	JsBlockStatement,
	JsBreakStatement,
	JsCallExpr,
	JsClassDecl,
	JsClassMember,
	JsClassMemberKind,
	JsClassMethod,
	JsContinueStatement,
	JsDecl,
	JsDeclKind,
	JsDestructure,
	JsEmptyStatement,
	JsExpr,
	JsExprOrStatements,
	JsIfStatement,
	JsImport,
	JsLiteralBool,
	JsLiteralNumber,
	JsLiteralString,
	JsModuleAst,
	JsName,
	JsObjectDestructure,
	JsObjectExpr,
	JsParams,
	JsPropertyAccessExpr,
	JsReturnStatement,
	JsStatement,
	JsSwitchStatement,
	JsTernaryExpr,
	JsThrowStatement,
	JsTryFinallyStatement,
	JsUnaryExpr,
	JsVarDecl,
	JsWhileStatement;
import util.alloc.alloc : Alloc;
import util.util : todo;
import util.writer : makeStringWithWriter, Writer;

string writeJsAst(ref Alloc alloc, in JsModuleAst a) =>
	makeStringWithWriter(alloc, (scope ref Writer writer) {
		todo!void("WRITE JS AST");
	});
