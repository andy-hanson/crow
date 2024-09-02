module backend.js.jsAst;

@safe @nogc pure nothrow:

import backend.js.allUsed : AnyDecl;
import backend.js.sourceMap : noSource, Source;
import util.alloc.alloc : Alloc;
import util.col.array : newArray, newSmallArray, SmallArray;
import util.col.map : KeyValuePair;
import util.comparison : compareEnum, Comparison, compareOptions, compareOr, compareUint;
import util.integralValues : IntegralValue;
import util.memory : allocate;
import util.opt : none, Opt, some;
import util.sourceRange : LineAndColumn;
import util.symbol : compareSymbolsAlphabetically, Symbol, symbolOfString;
import util.union_ : Union;
import util.uri : RelPath, Uri;

immutable struct JsScriptAst {
	Shebang shebang;
	JsDecl[] decls;
	JsStatement[] statements;
}
immutable struct JsModuleAst {
	Shebang shebang;
	Uri sourceUri;
	JsImport[] imports;
	JsImport[] reExports;
	JsDecl[] decls;
	JsStatement[] statements;
}

enum Shebang { none, node }

// Mangle lazily
immutable struct JsName {
	@safe @nogc pure nothrow:
	// Kind.none means: Don't include the kind in the name
	// 'local' is for locals from the source code, 'temp' is for those generated by the compiler.
	enum Kind { none, function_, local, specialLocal, specSig, temp, type }
	Kind kind;
	Symbol crowName;
	Opt!ushort mangleIndex;

	static JsName noPrefix(Symbol name) =>
		JsName(Kind.none, name);
	static JsName local(Symbol name) =>
		JsName(Kind.local, name);
	static JsName specialLocal(Symbol name) =>
		JsName(Kind.specialLocal, name);
	static JsName temp(Symbol name, ushort index) =>
		JsName(Kind.temp, name, some(index));
}
Comparison compareJsName(JsName a, JsName b) =>
	compareOr(
		compareEnum(a.kind, b.kind),
		() => compareSymbolsAlphabetically(a.crowName, b.crowName),
		() => compareOptions!ushort(a.mangleIndex, b.mangleIndex, (in ushort x, in ushort y) => compareUint(x, y)));

immutable struct JsMemberName {
	@safe @nogc pure nothrow:
	enum Kind { none, enumMember, recordField, special, unionConstructor, unionMember, variantMethod }
	Kind kind;
	Symbol crowName;

	static JsMemberName noPrefix(Symbol name) =>
		JsMemberName(Kind.none, name);
	static JsMemberName enumMember(Symbol name) =>
		JsMemberName(Kind.enumMember, name);
	static JsMemberName recordField(Symbol name) =>
		JsMemberName(Kind.recordField, name);
	static JsMemberName special(Symbol name) =>
		JsMemberName(Kind.special, name);
	static JsMemberName unionConstructor(Symbol name) =>
		JsMemberName(Kind.unionConstructor, name);
	static JsMemberName unionMember(Symbol name) =>
		JsMemberName(Kind.unionMember, name);
	static JsMemberName variantMethod(Symbol name) =>
		JsMemberName(Kind.variantMethod, name);
}

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
	immutable struct Let {}
	mixin Union!(JsClassDecl, JsExpr, Let);
}
immutable struct JsClassDecl {
	Opt!(JsExpr*) extends;
	JsClassMember[] members;
}
immutable struct JsClassMember {
	enum Static { instance, static_ }
	Static isStatic;
	JsMemberName name;
	JsClassMemberKind kind;
}
private immutable struct JsClassMemberKind {
	mixin Union!(JsClassMethod, JsExpr);
}
immutable struct JsClassMethod {
	SyncOrAsync async;
	JsParams params;
	JsBlockStatement body_;
}

enum SyncOrAsync { sync, async }

immutable struct JsArrowFunction {
	SyncOrAsync async;
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
	mixin Union!(JsName, JsDefaultDestructure*, JsObjectDestructure);
}
// 'left = default'
immutable struct JsDefaultDestructure {
	JsDestructure left;
	JsExpr default_;
}
immutable struct JsObjectDestructure {
	KeyValuePair!(JsMemberName, JsDestructure)[] fields;
}

immutable struct JsStatement {
	Source source;
	JsStatementKind kind;
}

immutable struct JsStatementKind {
	mixin Union!(
		JsAssignStatement*,
		JsBlockStatement,
		JsBreakStatement,
		JsContinueStatement,
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
		// Technically un-blocked statements are allowed,
		// but it's safer to force braces around them so they have a scope
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
	Opt!(JsExpr*) initializer;
}
immutable struct JsWhileStatement {
	Opt!JsName label;
	JsExpr* condition;
	JsBlockStatement body_;
}

immutable struct JsExpr {
	Source source;
	JsExprKind kind;
}
immutable struct JsExprKind {
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
		JsLiteralStringFromMemberName,
		JsLiteralStringFromSymbol,
		JsName,
		JsNewExpr,
		JsNullExpr,
		JsObject1Expr,
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
immutable struct JsLiteralStringFromMemberName {
	JsMemberName value;
}
immutable struct JsLiteralStringFromSymbol {
	Symbol value;
}
immutable struct JsNewExpr {
	JsExpr* class_;
	JsExpr[] arguments;
}
immutable struct JsNullExpr {}
immutable struct JsObject1Expr {
	JsMemberName key;
	JsExpr* value;
}
immutable struct JsPropertyAccessExpr {
	JsExpr* object;
	JsMemberName propertyName;
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
	enum Kind { await, bitwiseNot, not, typeof_, void_ }
	Kind kind;
	JsExpr* arg;
}

JsStatement exprStatement(JsExpr expr) =>
	JsStatement(expr.source, JsStatementKind(expr));
JsExpr genAnd(ref Alloc alloc, in Source source, JsExpr arg0, JsExpr arg1) =>
	genBinary(alloc, source, JsBinaryExpr.Kind.and, arg0, arg1);
JsExpr genArray(in Source source, JsExpr[] elements) =>
	JsExpr(source, JsExprKind(JsArrayExpr(elements)));
JsExpr genArrowFunction(in Source source, SyncOrAsync async, JsParams params, JsExprOrBlockStatement body_) =>
	JsExpr(source, JsExprKind(JsArrowFunction(async, params, body_)));
JsExpr genArrowFunction(ref Alloc alloc, in Source source, SyncOrAsync async, in JsDestructure[] params, JsExpr body_) =>
	genArrowFunction(source, async, JsParams(newSmallArray(alloc, params)), JsExprOrBlockStatement(allocate(alloc, body_)));
JsExpr genArrowFunction(ref Alloc alloc, in Source source, SyncOrAsync async, in JsDestructure[] params, in JsStatement[] body_) =>
	genArrowFunction(
		source,
		async,
		JsParams(newSmallArray(alloc, params)),
		JsExprOrBlockStatement(genBlockStatement(alloc, body_)));
JsStatement genAssign(ref Alloc alloc, in Source source, JsExpr left, JsExpr right) =>
	JsStatement(source, JsStatementKind(allocate(alloc, JsAssignStatement(left, right))));
JsStatement genAssign(ref Alloc alloc, in Source source, JsName left, JsExpr right) =>
	genAssign(alloc, source, genLocalGet(source, left), right);
JsExpr genAwait(ref Alloc alloc, in Source source, JsExpr arg) =>
	genUnary(alloc, source, JsUnaryExpr.Kind.await, arg);
private JsExpr genAwaitIf(ref Alloc alloc, in Source source, SyncOrAsync async, JsExpr arg) {
	final switch (async) {
		case SyncOrAsync.sync:
			return arg;
		case SyncOrAsync.async:
			return genAwait(alloc, source, arg);
	}
}
JsExpr genBinary(ref Alloc alloc, in Source source, JsBinaryExpr.Kind kind, JsExpr arg0, JsExpr arg1) =>
	JsExpr(source, JsExprKind(JsBinaryExpr(kind, allocate(alloc, arg0), allocate(alloc, arg1))));
JsExpr genBitwiseAnd(ref Alloc alloc, in Source source, JsExpr arg0, JsExpr arg1) =>
	genBinary(alloc, source, JsBinaryExpr.Kind.bitwiseAnd, arg0, arg1);
JsExpr genBitwiseNot(ref Alloc alloc, in Source source, JsExpr arg) =>
	genUnary(alloc, source, JsUnaryExpr.Kind.bitwiseNot, arg);
JsBlockStatement genBlockStatement(ref Alloc alloc, in JsStatement[] statements) =>
	JsBlockStatement(newArray(alloc, statements));
JsExpr genBool(in Source source, bool value) =>
	JsExpr(source, JsExprKind(JsLiteralBool(value)));
JsStatement genBreakNoLabel(in Source source) =>
	JsStatement(source, JsStatementKind(JsBreakStatement(none!JsName)));
JsStatement genBreak(in Source source, JsName label) =>
	JsStatement(source, JsStatementKind(JsBreakStatement(some(label))));
JsExpr genCall(ref Alloc alloc, in Source source, SyncOrAsync await, JsExpr* called, JsExpr[] args) =>
	genAwaitIf(alloc, source, await, genCallSync(source, called, args));
JsExpr genCallAwait(ref Alloc alloc, in Source source, JsExpr* called, JsExpr[] args) =>
	genAwait(alloc, source, genCallSync(source, called, args));
JsExpr genCallSync(in Source source, JsExpr* called, JsExpr[] args) =>
	JsExpr(source, JsExprKind(JsCallExpr(called, args)));
JsExpr genCall(ref Alloc alloc, in Source source, SyncOrAsync await, JsExpr called, in JsExpr[] args) =>
	genCall(alloc, source, await, allocate(alloc, called), newArray(alloc, args));
JsExpr genCallAwait(ref Alloc alloc, in Source source, JsExpr called, in JsExpr[] args) =>
	genAwait(alloc, source, genCall(alloc, source, SyncOrAsync.async, called, args)); // TODO: wait, isn't this redundant???????
JsExpr genCallSync(ref Alloc alloc, in Source source, JsExpr called, in JsExpr[] args) =>
	genCall(alloc, source, SyncOrAsync.sync, called, args);
JsExpr genCallWithSpread(ref Alloc alloc, in Source source, SyncOrAsync await, JsExpr called, in JsExpr[] args, JsExpr spreadArg) =>
	genAwaitIf(
		alloc,
		source,
		await,
		JsExpr(source, JsExprKind(JsCallWithSpreadExpr(
			allocate(alloc, called),
			newArray(alloc, args),
			allocate(alloc, spreadArg)))));
JsExpr genCallPropertySync(ref Alloc alloc, in Source source, JsExpr object, JsMemberName property, in JsExpr[] args) =>
	genCallSync(alloc, source, genPropertyAccess(alloc, source, object, property), args);
JsStatement genContinue(in Source source) =>
	JsStatement(source, JsStatementKind(JsContinueStatement()));
JsExpr genGlobal(in Source source, Symbol name) =>
	JsExpr(source, JsExprKind(JsName.noPrefix(name)));
JsStatement genIf(ref Alloc alloc, in Source source, JsExpr cond, JsStatement then) =>
	JsStatement(source, JsStatementKind(allocate(alloc, JsIfStatement(cond, then))));
JsStatement genIf(ref Alloc alloc, in Source source, JsExpr cond, JsStatement then, JsStatement else_) =>
	JsStatement(source, JsStatementKind(allocate(alloc, JsIfStatement(cond, then, some(else_)))));
JsExpr genIife(ref Alloc alloc, in Source source, SyncOrAsync async, JsBlockStatement body_) =>
	genCall(alloc, source, async, allocate(alloc, genArrowFunction(source, async, JsParams(), JsExprOrBlockStatement(body_))), []);
JsExpr genIn(ref Alloc alloc, in Source source, JsMemberName arg0, JsExpr arg1) =>
	genBinary(alloc, source, JsBinaryExpr.Kind.in_, genStringFromMemberName(source, arg0), arg1);
JsExpr genInstanceof(ref Alloc alloc, in Source source, JsExpr arg0, JsExpr arg1) =>
	genBinary(alloc, source, JsBinaryExpr.Kind.instanceof, arg0, arg1);
JsExpr genInteger(in Source source, bool isSigned, IntegralValue value) =>
	JsExpr(source, JsExprKind(JsLiteralInteger(isSigned, value)));
JsExpr genIntegerSigned(in Source source, long value) =>
	genInteger(source, true, IntegralValue(value));
JsExpr genIntegerUnsigned(in Source source, ulong value) =>
	genInteger(source, false, IntegralValue(value));
JsExpr genNot(ref Alloc alloc, in Source source, JsExpr arg) =>
	genUnary(alloc, source, JsUnaryExpr.Kind.not, arg);
JsExpr genNotEqEq(ref Alloc alloc, in Source source, JsExpr left, JsExpr right) =>
	genBinary(alloc, source, JsBinaryExpr.Kind.notEqEq, left, right);
JsExpr genNull(in Source source) =>
	JsExpr(source, JsExprKind(JsNullExpr()));
JsExpr genNumber(in Source source, double value) =>
	JsExpr(source, JsExprKind(JsLiteralNumber(value)));
JsExpr genNew(ref Alloc alloc, in Source source, JsExpr class_, in JsExpr[] args) =>
	genNew(source, allocate(alloc, class_), newArray(alloc, args));
JsExpr genNew(in Source source, JsExpr* class_, JsExpr[] args) =>
	JsExpr(source, JsExprKind(JsNewExpr(class_, args)));
JsExpr genOr(ref Alloc alloc, in Source source, JsExpr arg0, JsExpr arg1) =>
	genBinary(alloc, source, JsBinaryExpr.Kind.or, arg0, arg1);
JsExpr genPlus(ref Alloc alloc, in Source source, JsExpr arg0, JsExpr arg1) =>
	genBinary(alloc, source, JsBinaryExpr.Kind.plus, arg0, arg1);
JsExpr genPropertyAccess(ref Alloc alloc, in Source source, JsExpr arg, JsMemberName propertyName) =>
	JsExpr(source, JsExprKind(JsPropertyAccessExpr(allocate(alloc, arg), propertyName)));
JsExpr genPropertyAccessComputed(ref Alloc alloc, in Source source, JsExpr object, JsExpr propertyName) =>
	propertyName.kind.isA!JsLiteralString
		? genPropertyAccess(alloc, source, object, JsMemberName.noPrefix(symbolOfString(propertyName.kind.as!JsLiteralString.value)))
		: JsExpr(source, JsExprKind(allocate(alloc, JsPropertyAccessComputedExpr(object, propertyName))));
JsStatement genReturn(ref Alloc alloc, in Source source, JsExpr arg) =>
	JsStatement(source, JsStatementKind(JsReturnStatement(allocate(alloc, arg))));
JsStatement genSwitch(ref Alloc alloc, in Source source, JsExpr arg, JsSwitchStatement.Case[] cases, JsBlockStatement default_) =>
	JsStatement(source, JsStatementKind(JsSwitchStatement(allocate(alloc, arg), cases, default_)));
JsExpr genTernary(ref Alloc alloc, in Source source, JsExpr cond, JsExpr then, JsExpr else_) =>
	JsExpr(source, JsExprKind(allocate(alloc, JsTernaryExpr(cond, then, else_))));
JsStatement genThrow(ref Alloc alloc, in Source source, JsExpr thrown) =>
	JsStatement(source, JsStatementKind(JsThrowStatement(allocate(alloc, thrown))));
JsStatement genTryFinally(in Source source, JsBlockStatement tried, JsBlockStatement finally_) =>
	JsStatement(source, JsStatementKind(JsTryFinallyStatement(tried, finally_)));
JsExpr genTypeof(ref Alloc alloc, in Source source, JsExpr arg) =>
	genUnary(alloc, source, JsUnaryExpr.Kind.typeof_, arg);
JsExpr genEqEqEq(ref Alloc alloc, in Source source, JsExpr a, JsExpr b) =>
	genBinary(alloc, source, JsBinaryExpr.Kind.eqEqEq, a, b);
JsStatement genTryCatch(ref Alloc alloc, in Source source, JsBlockStatement tryBlock, JsName exception, JsBlockStatement catchBlock) =>
	JsStatement(source, JsStatementKind(JsTryCatchStatement(tryBlock, exception, catchBlock)));
JsStatement genVarDecl(in Source source, JsVarDecl.Kind kind, JsDestructure destructure, Opt!(JsExpr*) initializer) =>
	JsStatement(source, JsStatementKind(JsVarDecl(kind, destructure, initializer)));
JsStatement genConst(ref Alloc alloc, in Source source, JsName name, JsExpr initializer) =>
	genConst(alloc, source, JsDestructure(name), initializer);
JsStatement genConst(ref Alloc alloc, in Source source, JsDestructure destructure, JsExpr initializer) =>
	genVarDecl(source, JsVarDecl.Kind.const_, destructure, some(allocate(alloc, initializer)));
JsStatement genLet(in Source source, JsName name) =>
	genVarDecl(source, JsVarDecl.Kind.let, JsDestructure(name), none!(JsExpr*));
JsStatement genLet(ref Alloc alloc, in Source source, JsDestructure destructure, JsExpr initializer) =>
	genVarDecl(source, JsVarDecl.Kind.let, destructure, some(allocate(alloc, initializer)));
JsExpr genLocalGet(in Source source, JsName name) => // TODO: this is not always a local, rename? ------------------------------------
	JsExpr(source, JsExprKind(name));
JsExpr genObject(ref Alloc alloc, in Source source, JsMemberName name, JsExpr value) =>
	JsExpr(source, JsExprKind(JsObject1Expr(name, allocate(alloc, value))));
JsExpr genString(in Source source, string value) =>
	JsExpr(source, JsExprKind(JsLiteralString(value)));
JsExpr genStringFromSymbol(in Source source, Symbol value) =>
	JsExpr(source, JsExprKind(JsLiteralStringFromSymbol(value)));
private JsExpr genStringFromMemberName(in Source source, JsMemberName value) =>
	JsExpr(source, JsExprKind(JsLiteralStringFromMemberName(value)));
JsExpr genThis(in Source source) =>
	JsExpr(source, JsExprKind(JsThisExpr()));
JsExpr genTimes(ref Alloc alloc, in Source source, JsExpr left, JsExpr right) =>
	genBinary(alloc, source, JsBinaryExpr.Kind.times, left, right);
JsExpr genUnary(ref Alloc alloc, in Source source, JsUnaryExpr.Kind kind, JsExpr arg) =>
	JsExpr(source, JsExprKind(JsUnaryExpr(kind, allocate(alloc, arg))));
private JsExpr number0 = genNumber(noSource, 0);
JsExpr genUndefined(in Source source) =>
	JsExpr(source, JsExprKind(JsUnaryExpr(JsUnaryExpr.Kind.void_, &number0)));
JsStatement genWhile(ref Alloc alloc, in Source source, JsExpr condition, JsBlockStatement body_) =>
	genWhile(alloc, source, none!JsName, condition, body_);
JsStatement genWhile(ref Alloc alloc, in Source source, Opt!JsName label, JsExpr condition, JsBlockStatement body_) =>
	JsStatement(source, JsStatementKind(JsWhileStatement(label, allocate(alloc, condition), body_)));
JsStatement genWhileTrue(ref Alloc alloc, in Source source, JsBlockStatement body_) =>
	genWhileTrue(alloc, source, none!JsName, body_);
JsStatement genWhileTrue(ref Alloc alloc, in Source source, Opt!JsName label, JsBlockStatement body_) =>
	genWhile(alloc, source, label, genBool(source, true), body_);

private JsClassMember genMethod(
	JsClassMember.Static static_,
	SyncOrAsync async,
	JsMemberName name,
	JsParams params,
	JsBlockStatement body_,
) =>
	JsClassMember(static_, name, JsClassMemberKind(JsClassMethod(async, params, body_)));
JsClassMember genInstanceMethod(SyncOrAsync async, JsMemberName name, JsParams params, JsBlockStatement body_) =>
	genMethod(JsClassMember.Static.instance, async, name, params, body_);
JsClassMember genStaticMethod(SyncOrAsync async, JsMemberName name, JsParams params, JsBlockStatement body_) =>
	genMethod(JsClassMember.Static.static_, async, name, params, body_);
JsClassMember genInstanceMethod(
	ref Alloc alloc,
	SyncOrAsync async,
	JsMemberName name,
	in JsDestructure[] params,
	in JsStatement[] body_,
) =>
	genInstanceMethod(alloc, async, name, params, genBlockStatement(alloc, body_));
JsClassMember genInstanceMethod(
	ref Alloc alloc,
	SyncOrAsync async,
	JsMemberName name,
	in JsDestructure[] params,
	JsBlockStatement body_,
) =>
	genInstanceMethod(async, name, JsParams(newSmallArray(alloc, params)), body_);
JsClassMember genInstanceMethod(
	ref Alloc alloc,
	in Source source,
	SyncOrAsync async,
	JsMemberName name,
	in JsDestructure[] params,
	JsExpr body_,
) =>
	genInstanceMethod(alloc, async, name, params, genBlockStatement(alloc, [genReturn(alloc, source, body_)]));
JsClassMember genField(JsClassMember.Static static_, JsMemberName name, JsExpr value) =>
	JsClassMember(static_, name, JsClassMemberKind(value));
