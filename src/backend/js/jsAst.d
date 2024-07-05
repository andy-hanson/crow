module backend.js.jsAst;

@safe @nogc pure nothrow:

import backend.js.allUsed : AnyDecl;
import util.alloc.alloc : Alloc;
import util.col.array : newArray, SmallArray;
import util.col.map : KeyValuePair, Map;
import util.integralValues : IntegralValue;
import util.memory : allocate;
import util.opt : none, Opt, some;
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

	@safe @nogc pure nothrow:
	this(Symbol cn, Opt!ushort mi = none!ushort) { // RM --------------------------------------------------------------------------------------------------
		crowName = cn;
		mangleIndex = mi;
		// Test for iteration errors
		foreach (dchar x; crowName) {
			assert(true);
		}
	}
}
static assert(JsName.sizeof == ulong.sizeof);

immutable struct JsImport {
	Opt!(JsName[]) importedNames; // Otherwise this is 'import *'
	RelPath path;
}

immutable struct JsDecl {
	enum Exported { private_, export_ }
	AnyDecl source;
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
		JsWhileStatement);
}
immutable struct JsAssignStatement {
	JsExpr left;
	JsExpr right;
}
immutable struct JsBlockStatement {
	JsStatement[] statements;
}
immutable struct JsBreakStatement {
	Opt!JsName label;
}
immutable struct JsContinueStatement {}
immutable struct JsEmptyStatement {}
immutable struct JsIfStatement {
	JsExpr cond;
	JsStatement then;
	Opt!JsStatement else_;
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
	JsBlockStatement default_;
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
	Opt!JsName label;
	JsExpr* condition;
	JsBlockStatement body_;
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
		JsLiteralIntegerLarge,
		JsLiteralNumber,
		JsLiteralString,
		JsLiteralStringFromSymbol,
		JsName,
		JsNewExpr,
		JsNullExpr,
		JsObjectExpr,
		JsPropertyAccessExpr,
		JsPropertyAccessComputedExpr*,
		JsTernaryExpr*,
		JsThisExpr,
		JsUnaryExpr,
	);
}
immutable struct JsArrayExpr {
	JsExpr[] elements;
}
immutable struct JsBinaryExpr {
	enum Kind {
		and,
		bitShiftLeft,
		bitShiftRight,
		bitwiseAnd,
		bitwiseOr,
		bitwiseXor,
		divide,
		eqEqEq,
		in_,
		instanceof,
		less,
		minus,
		modulo, // WARN: not a true modulo, keeps numbers negative
		notEqEq,
		or,
		plus,
		times,
	}
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
immutable struct JsLiteralIntegerLarge {
	string value;
}
immutable struct JsLiteralNumber {
	double value;
}
immutable struct JsLiteralString {
	string value;
}
immutable struct JsLiteralStringFromSymbol {
	Symbol value;
}
immutable struct JsNewExpr {
	JsExpr* class_;
	JsExpr[] arguments;
}
immutable struct JsNullExpr {}
immutable struct JsObjectExpr {
	Symbol name;
	JsExpr* value;
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
immutable struct JsThisExpr {}
immutable struct JsUnaryExpr {
	enum Kind { bitwiseNot, not, typeof_, void_ }
	Kind kind;
	JsExpr* arg;
}

JsExpr genAnd(ref Alloc alloc, JsExpr arg0, JsExpr arg1) =>
	genBinary(alloc, JsBinaryExpr.Kind.and, arg0, arg1);
JsExpr genArray(JsExpr[] elements) =>
	JsExpr(JsArrayExpr(elements));
JsExpr genArrowFunction(JsParams params, JsExprOrBlockStatement body_) =>
	JsExpr(JsArrowFunction(params, body_));
JsStatement genAssign(ref Alloc alloc, JsExpr left, JsExpr right) =>
	JsStatement(allocate(alloc, JsAssignStatement(left, right)));
JsStatement genAssign(ref Alloc alloc, JsName left, JsExpr right) =>
	genAssign(alloc, JsExpr(left), right);
JsExpr genBinary(ref Alloc alloc, JsBinaryExpr.Kind kind, JsExpr arg0, JsExpr arg1) =>
	JsExpr(JsBinaryExpr(kind, allocate(alloc, arg0), allocate(alloc, arg1)));
JsBlockStatement genBlockStatement(ref Alloc alloc, in JsStatement[] statements) =>
	JsBlockStatement(newArray(alloc, statements));
JsExpr genBool(bool value) =>
	JsExpr(JsLiteralBool(value));
JsStatement genBreakNoLabel() =>
	JsStatement(JsBreakStatement(none!JsName));
JsStatement genBreak(JsName label) =>
	JsStatement(JsBreakStatement(some(label)));
JsExpr genCall(JsExpr* called, JsExpr[] args) =>
	JsExpr(JsCallExpr(called, args));
JsExpr genCall(ref Alloc alloc, JsExpr called, in JsExpr[] args) =>
	genCall(allocate(alloc, called), newArray(alloc, args));
JsExpr genCallWithSpread(ref Alloc alloc, JsExpr called, in JsExpr[] args, JsExpr spreadArg) =>
	JsExpr(JsCallWithSpreadExpr(allocate(alloc, called), newArray(alloc, args), allocate(alloc, spreadArg)));
JsExpr genCallProperty(ref Alloc alloc, JsExpr object, Symbol property, in JsExpr[] args) =>
	genCall(alloc, genPropertyAccess(alloc, object, property), args);
JsStatement genEmptyStatement() =>
	JsStatement(JsEmptyStatement());
JsStatement genIf(ref Alloc alloc, JsExpr cond, JsStatement then) =>
	JsStatement(allocate(alloc, JsIfStatement(cond, then)));
JsStatement genIf(ref Alloc alloc, JsExpr cond, JsStatement then, JsStatement else_) =>
	JsStatement(allocate(alloc, JsIfStatement(cond, then, some(else_))));
JsExpr genIife(ref Alloc alloc, JsBlockStatement body_) =>
	genCall(allocate(alloc, genArrowFunction(JsParams(), JsExprOrBlockStatement(body_))), []);
JsExpr genIn(ref Alloc alloc, Symbol arg0, JsExpr arg1) =>
	genBinary(alloc, JsBinaryExpr.Kind.in_, genString(arg0), arg1);
JsExpr genInstanceof(ref Alloc alloc, JsExpr arg0, JsExpr arg1) =>
	genBinary(alloc, JsBinaryExpr.Kind.instanceof, arg0, arg1);
JsExpr genIntegerSigned(long value) =>
	JsExpr(JsLiteralInteger(isSigned: true, value: IntegralValue(value)));
JsExpr genIntegerUnsigned(ulong value) =>
	JsExpr(JsLiteralInteger(isSigned: false, value: IntegralValue(value)));
JsExpr genIntegerLarge(string value) =>
	JsExpr(JsLiteralIntegerLarge(value));
JsExpr genNot(ref Alloc alloc, JsExpr arg) =>
	genUnary(alloc, JsUnaryExpr.Kind.not, arg);
JsExpr genNotEqEq(ref Alloc alloc, JsExpr left, JsExpr right) =>
	genBinary(alloc, JsBinaryExpr.Kind.notEqEq, left, right);
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
JsStatement genSwitch(ref Alloc alloc, JsExpr arg, JsSwitchStatement.Case[] cases, JsBlockStatement default_) =>
	JsStatement(JsSwitchStatement(allocate(alloc, arg), cases, default_));
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
JsExpr genObject(ref Alloc alloc, Symbol name, JsExpr value) =>
	JsExpr(JsObjectExpr(name, allocate(alloc, value)));
JsExpr genString(string value) =>
	JsExpr(JsLiteralString(value));
JsExpr genString(Symbol value) =>
	JsExpr(JsLiteralStringFromSymbol(value));
JsExpr genThis() =>
	JsExpr(JsThisExpr());
JsExpr genUnary(ref Alloc alloc, JsUnaryExpr.Kind kind, JsExpr arg) =>
	JsExpr(JsUnaryExpr(kind, allocate(alloc, arg)));
JsExpr number0 = genNumber(0);
JsExpr genUndefined() =>
	JsExpr(JsUnaryExpr(JsUnaryExpr.Kind.void_, &number0));
JsStatement genWhile(ref Alloc alloc, Opt!JsName label, JsExpr condition, JsBlockStatement body_) =>
	JsStatement(JsWhileStatement(label, allocate(alloc, condition), body_));
JsStatement genWhileTrue(ref Alloc alloc, Opt!JsName label, JsBlockStatement body_) =>
	genWhile(alloc, label, genBool(true), body_);
