module backend.js.jsAst;

@safe @nogc pure nothrow:

import model.ast : PathOrRelPath;
import util.alloc.alloc : Alloc;
import util.col.array : newArray, SmallArray;
import util.col.map : KeyValuePair, Map;
import util.integralValues : IntegralValue;
import util.memory : allocate;
import util.opt : Opt;
import util.symbol : Symbol;
import util.union_ : Union;
import util.uri : Uri;

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
	PathOrRelPath path;
}

immutable struct JsDecl {
	enum Kind { export_, private_ }
	Kind kind;
	Symbol name;
	JsExpr value;
}

immutable struct JsArrowFunction {
	JsParams params;
	JsExprOrStatements body_;
}
immutable struct JsParams {
	SmallArray!JsDestructure params;
	Opt!JsDestructure restParam;
}
immutable struct JsExprOrStatements {
	mixin Union!(JsExpr*, JsStatement[]);
}

immutable struct JsDestructure {
	mixin Union!(JsName, JsArrayDestructure*, JsObjectDestructure*);
}
immutable struct JsArrayDestructure {
	JsDestructure[] elements;
}
immutable struct JsObjectDestructure {
	Map!(Symbol, JsDestructure) fields;
}

immutable struct JsStatement {
	mixin Union!(
		JsAssignStatement,
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
		JsTryFinallyStatement*,
		JsVarDecl,
		JsWhileStatement*);
}
immutable struct JsAssignStatement {
	JsName left;
	JsExpr* right;
}
immutable struct JsBlockStatement {
	JsStatement[] inner;
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
		// Technically multiple statemnets are allowed, but it's safer to force braces around them so they have a scope
		JsStatement then;
	}

	JsExpr* arg;
	Case[] cases_;
	JsStatement* default_;
}
immutable struct JsThrowStatement {
	JsExpr* arg;
}
immutable struct JsTryCatchStatement {
	JsStatement* tried;
	JsName exception;
	JsStatement* catch_;
}
immutable struct JsTryFinallyStatement {
	JsStatement tried;
	JsStatement finally_;
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
		JsLiteralBool,
		JsLiteralNumber,
		JsLiteralString,
		JsName,
		JsObjectExpr,
		JsPropertyAccessExpr,
		JsUnaryExpr,
		JsTernaryExpr*,
	);
}
immutable struct JsArrayExpr {
	JsExpr[] elements;
}
immutable struct JsBinaryExpr {
	enum Kind { in_, instanceof, or }
	Kind kind;
	JsExpr* arg0;
	JsExpr* arg1;
}
immutable struct JsCallExpr {
	JsExpr* called;
	JsExpr[] args;
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
immutable struct JsLiteralNumber {
	double value;
}
immutable struct JsLiteralString {
	string value;
}
immutable struct JsObjectExpr {
	KeyValuePair!(Symbol, JsExpr)[] fields;
}
immutable struct JsPropertyAccessExpr {
	JsExpr* arg;
	// Property names are not mangled
	Symbol name;
}
immutable struct JsUnaryExpr {
	enum Kind { not }
	Kind kind;
	JsExpr* arg;
}
immutable struct JsTernaryExpr {
	JsExpr condition;
	JsExpr then;
	JsExpr else_;
}

JsExpr genBool(bool value) =>
	JsExpr(JsLiteralBool(true));
JsExpr genCall(JsExpr* called, JsExpr[] args) =>
	JsExpr(JsCallExpr(called, args));
JsExpr genCall(ref Alloc alloc, JsExpr called, in JsExpr[] args) =>
	genCall(allocate(alloc, called), newArray(alloc, args));
JsStatement genEmptyStatement() =>
	JsStatement(JsEmptyStatement());
JsExpr genIn(ref Alloc alloc, JsExpr arg0, JsExpr arg1) =>
	genBinary(alloc, JsBinaryExpr.Kind.in_, arg0, arg1);
JsExpr genInstanceof(ref Alloc alloc, JsExpr arg0, JsExpr arg1) =>
	genBinary(alloc, JsBinaryExpr.Kind.instanceof, arg0, arg1);
JsExpr genNot(ref Alloc alloc, JsExpr arg) => //TODO:MOVE -------------------------------------------------------------------------------
	JsExpr(JsUnaryExpr(JsUnaryExpr.Kind.not, allocate(alloc, arg)));
JsExpr genOr(ref Alloc alloc, JsExpr arg0, JsExpr arg1) =>
	genBinary(alloc, JsBinaryExpr.Kind.or, arg0, arg1);
JsExpr genPropertyAccess(ref Alloc alloc, JsExpr arg, Symbol propertyName) =>
	JsExpr(JsPropertyAccessExpr(allocate(alloc, arg), propertyName));
JsStatement genThrow(ref Alloc alloc, JsExpr thrown) =>
	JsStatement(JsThrowStatement(allocate(alloc, thrown)));

private JsExpr genBinary(ref Alloc alloc, JsBinaryExpr.Kind kind, JsExpr arg0, JsExpr arg1) =>
	JsExpr(JsBinaryExpr(kind, allocate(alloc, arg0), allocate(alloc, arg1)));
