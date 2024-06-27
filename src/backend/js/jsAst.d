module backend.js.jsAst;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc;
import util.col.array : newArray, SmallArray;
import util.col.map : KeyValuePair, Map;
import util.integralValues : IntegralValue;
import util.memory : allocate;
import util.opt : Opt;
import util.symbol : Symbol, symbol, symbolOfString;
import util.union_ : Union;
import util.uri : RelPath, Uri;

// This is specifically for what we emit.
// We emit a bunch of 'const' declarations.
immutable struct JsModuleAst {
	Uri sourceUri;
	JsImport[] imports;
	JsImport[] reExports;
	JsDecl[] decls;
}

// Mangle lazily
immutable struct JsName {
	Symbol crowName;
	Opt!ushort mangleIndex;
}
static assert(JsName.sizeof == ulong.sizeof);

immutable struct JsImport {
	Opt!(JsName[]) importedNames; // Otherwise this is 'import *'
	RelPath path;
}

immutable struct JsDecl {
	enum Exported { private_, export_ }
	Exported exported;
	JsName name;
	JsDeclKind kind;
}
immutable struct JsDeclKind {
	mixin Union!(JsClassDecl, JsExpr);
}
immutable struct JsClassDecl {
	Opt!(JsExpr*) extends; 
	JsClassMember[] members;
}
immutable struct JsClassMember {
	enum Static { instance, static_ }
	Static isStatic;
	Symbol name; // member names are never mangled
	JsClassMemberKind kind;
}
immutable struct JsClassMemberKind {
	mixin Union!(JsClassMethod, JsExpr);
}
immutable struct JsClassMethod {
	JsParams params;
	JsBlockStatement body_;
}

immutable struct JsArrowFunction {
	JsParams params;
	JsExprOrBlockStatement body_;
}
immutable struct JsParams {
	SmallArray!JsDestructure params;
	Opt!JsDestructure restParam;
}
immutable struct JsExprOrBlockStatement {
	mixin Union!(JsExpr*, JsBlockStatement);
}

immutable struct JsDestructure {
	mixin Union!(JsName, JsObjectDestructure);
}
immutable struct JsObjectDestructure {
	KeyValuePair!(Symbol, JsDestructure)[] fields;
}

immutable struct JsStatement {
	mixin Union!(
		JsAssignStatement*,
		JsBlockStatement,
		JsBreakStatement,
		JsContinueStatement,
		JsEmptyStatement,
		JsExpr,
		JsIfStatement*,
		JsReturnStatement,
		JsSwitchStatement,
		JsThrowStatement,
		JsTryCatchStatement,
		JsTryFinallyStatement,
		JsVarDecl,
		JsWhileStatement*);
}
immutable struct JsAssignStatement {
	JsExpr left;
	JsExpr right;
}
immutable struct JsBlockStatement {
	JsStatement[] statements;
}
immutable struct JsBreakStatement {}
immutable struct JsContinueStatement {}
immutable struct JsEmptyStatement {}
immutable struct JsIfStatement {
	JsExpr cond;
	JsStatement then;
	JsStatement else_;
}
immutable struct JsReturnStatement {
	JsExpr* arg;
}
immutable struct JsSwitchStatement {
	immutable struct Case {
		JsExpr value;
		// Technically un-blocked statements are allowed, but it's safer to force braces around them so they have a scope
		JsBlockStatement then;
	}

	JsExpr* arg;
	Case[] cases_;
	JsStatement* default_;
}
immutable struct JsThrowStatement {
	JsExpr* arg;
}
immutable struct JsTryCatchStatement {
	JsBlockStatement tried;
	JsName exception;
	JsBlockStatement catch_;
}
immutable struct JsTryFinallyStatement {
	JsBlockStatement tried;
	JsBlockStatement finally_;
}
immutable struct JsVarDecl {
	enum Kind { const_, let }
	Kind kind;
	JsDestructure destructure;
	JsExpr* initializer;
}
immutable struct JsWhileStatement {
	JsExpr condition;
	JsStatement body_;
}

immutable struct JsExpr {
	mixin Union!(
		JsArrayExpr,
		JsArrowFunction,
		JsBinaryExpr,
		JsCallExpr,
		JsCallWithSpreadExpr,
		JsLiteralBool,
		JsLiteralInteger,
		JsLiteralNumber,
		JsLiteralString,
		JsName,
		JsNewExpr,
		JsNullExpr,
		JsObjectExpr,
		JsPropertyAccessExpr,
		JsPropertyAccessComputedExpr*,
		JsTernaryExpr*,
		JsUnaryExpr,
	);
}
immutable struct JsArrayExpr {
	JsExpr[] elements;
}
immutable struct JsBinaryExpr {
	enum Kind { eqEqEq, in_, instanceof, or }
	Kind kind;
	JsExpr* left;
	JsExpr* right;
}
immutable struct JsCallExpr {
	JsExpr* called;
	JsExpr[] args;
}
immutable struct JsCallWithSpreadExpr {
	JsExpr* called;
	JsExpr[] args;
	JsExpr* spreadArg;
}
immutable struct JsInExpr {
	JsExpr string_;
	JsExpr object;
}
immutable struct JsInstanceofExpr {
	JsExpr value;
	JsExpr type;
}
immutable struct JsLiteralBool {
	bool value;
}
immutable struct JsLiteralInteger {
	bool isSigned;
	IntegralValue value;
}
immutable struct JsLiteralNumber {
	double value;
}
immutable struct JsLiteralString {
	string value;
}
immutable struct JsNewExpr {
	JsExpr* class_;
	JsExpr[] arguments;
}
immutable struct JsNullExpr {}
immutable struct JsObjectExpr {
	KeyValuePair!(Symbol, JsExpr)[] fields;
}
immutable struct JsPropertyAccessExpr {
	JsExpr* object;
	// Property names are not mangled
	Symbol propertyName;
}
immutable struct JsPropertyAccessComputedExpr {
	JsExpr object;
	JsExpr propertyName;
}
immutable struct JsTernaryExpr {
	JsExpr condition;
	JsExpr then;
	JsExpr else_;
}
immutable struct JsUnaryExpr {
	enum Kind { not, typeof_, void_ }
	Kind kind;
	JsExpr* arg;
}

JsExpr genArrowFunction(JsParams params, JsExprOrBlockStatement body_) =>
	JsExpr(JsArrowFunction(params, body_));
JsStatement genAssign(ref Alloc alloc, JsExpr left, JsExpr right) =>
	JsStatement(allocate(alloc, JsAssignStatement(left, right)));
JsStatement genAssign(ref Alloc alloc, JsName left, JsExpr right) =>
	genAssign(alloc, JsExpr(left), right);
JsExpr genBool(bool value) =>
	JsExpr(JsLiteralBool(true));
JsExpr genCall(JsExpr* called, JsExpr[] args) =>
	JsExpr(JsCallExpr(called, args));
JsExpr genCall(ref Alloc alloc, JsExpr called, in JsExpr[] args) =>
	genCall(allocate(alloc, called), newArray(alloc, args));
JsExpr genCallWithSpread(ref Alloc alloc, JsExpr called, in JsExpr[] args, JsExpr spreadArg) =>
	JsExpr(JsCallWithSpreadExpr(allocate(alloc, called), newArray(alloc, args), allocate(alloc, spreadArg)));
JsStatement genEmptyStatement() =>
	JsStatement(JsEmptyStatement());
JsStatement genIf(ref Alloc alloc, JsExpr cond, JsStatement then, JsStatement else_) =>
	JsStatement(allocate(alloc, JsIfStatement(cond, then, else_)));
JsExpr genIife(ref Alloc alloc, JsBlockStatement body_) =>
	genCall(allocate(alloc, genArrowFunction(JsParams(), JsExprOrBlockStatement(body_))), []);
JsExpr genIn(ref Alloc alloc, JsExpr arg0, JsExpr arg1) =>
	genBinary(alloc, JsBinaryExpr.Kind.in_, arg0, arg1);
JsExpr genInstanceof(ref Alloc alloc, JsExpr arg0, JsExpr arg1) =>
	genBinary(alloc, JsBinaryExpr.Kind.instanceof, arg0, arg1);
JsExpr genIntegerSigned(long value) =>
	JsExpr(JsLiteralInteger(isSigned: true, value: IntegralValue(value)));
JsExpr genIntegerUnsigned(ulong value) =>
	JsExpr(JsLiteralInteger(isSigned: false, value: IntegralValue(value)));
JsExpr genNot(ref Alloc alloc, JsExpr arg) => //TODO:MOVE -------------------------------------------------------------------------------
	genUnary(alloc, JsUnaryExpr.Kind.not, arg);
JsExpr genNull() =>
	JsExpr(JsNullExpr());
JsExpr genNumber(double value) =>
	JsExpr(JsLiteralNumber(value));
JsExpr genNew(ref Alloc alloc, JsExpr class_, in JsExpr[] args) =>
	JsExpr(JsNewExpr(allocate(alloc, class_), newArray(alloc, args)));
JsExpr genOr(ref Alloc alloc, JsExpr arg0, JsExpr arg1) =>
	genBinary(alloc, JsBinaryExpr.Kind.or, arg0, arg1);
JsExpr genPropertyAccess(ref Alloc alloc, JsExpr arg, Symbol propertyName) =>
	JsExpr(JsPropertyAccessExpr(allocate(alloc, arg), propertyName));
JsExpr genPropertyAccessComputed(ref Alloc alloc, JsExpr object, JsExpr propertyName) =>
	propertyName.isA!JsLiteralString
		? genPropertyAccess(alloc, object, symbolOfString(propertyName.as!JsLiteralString.value))
		: JsExpr(allocate(alloc, JsPropertyAccessComputedExpr(object, propertyName)));
JsStatement genReturn(ref Alloc alloc, JsExpr arg) =>
	JsStatement(JsReturnStatement(allocate(alloc, arg)));
JsStatement genSwitch(ref Alloc alloc, JsExpr arg, JsSwitchStatement.Case[] cases, JsStatement default_) =>
	JsStatement(JsSwitchStatement(allocate(alloc, arg), cases, allocate(alloc, default_)));
JsExpr genTernary(ref Alloc alloc, JsExpr cond, JsExpr then, JsExpr else_) =>
	JsExpr(allocate(alloc, JsTernaryExpr(cond, then, else_)));
JsStatement genThrow(ref Alloc alloc, JsExpr thrown) =>
	JsStatement(JsThrowStatement(allocate(alloc, thrown)));
JsExpr genTypeof(ref Alloc alloc, JsExpr arg) =>
	genUnary(alloc, JsUnaryExpr.Kind.typeof_, arg);
JsExpr genEqEqEq(ref Alloc alloc, JsExpr a, JsExpr b) =>
	genBinary(alloc, JsBinaryExpr.Kind.eqEqEq, a, b);
JsStatement genTryCatch(ref Alloc alloc, JsBlockStatement tryBlock, JsName exception, JsBlockStatement catchBlock) =>
	JsStatement(JsTryCatchStatement(tryBlock, exception, catchBlock));
JsStatement genVarDecl(ref Alloc alloc, JsVarDecl.Kind kind, JsDestructure destructure, JsExpr initializer) =>
	JsStatement(JsVarDecl(kind, destructure, allocate(alloc, initializer)));
JsStatement genConst(ref Alloc alloc, JsDestructure destructure, JsExpr initializer) =>
	genVarDecl(alloc, JsVarDecl.Kind.const_, destructure, initializer);
JsStatement genLet(ref Alloc alloc, JsDestructure destructure, JsExpr initializer) =>
	genVarDecl(alloc, JsVarDecl.Kind.let, destructure, initializer);
JsExpr genString(string value) =>
	JsExpr(JsLiteralString(value));
JsExpr genThis() =>
	JsExpr(JsName(symbol!"this"));
JsExpr genUnary(ref Alloc alloc, JsUnaryExpr.Kind kind, JsExpr arg) =>
	JsExpr(JsUnaryExpr(kind, allocate(alloc, arg)));
JsExpr number0 = genNumber(0);
JsExpr genUndefined() =>
	JsExpr(JsUnaryExpr(JsUnaryExpr.Kind.void_, &number0));
JsStatement genWhile(ref Alloc alloc, JsExpr condition, JsStatement body_) =>
	JsStatement(allocate(alloc, JsWhileStatement(condition, body_)));

private JsExpr genBinary(ref Alloc alloc, JsBinaryExpr.Kind kind, JsExpr arg0, JsExpr arg1) =>
	JsExpr(JsBinaryExpr(kind, allocate(alloc, arg0), allocate(alloc, arg1)));
