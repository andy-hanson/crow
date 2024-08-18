module backend.js.jsAst;

@safe @nogc pure nothrow:

import backend.js.allUsed : AnyDecl;
import util.alloc.alloc : Alloc;
import util.col.array : newArray, newSmallArray, SmallArray;
import util.col.map : KeyValuePair;
import util.comparison : compareEnum, Comparison, compareOptions, compareOr, compareUint;
import util.integralValues : IntegralValue;
import util.memory : allocate;
import util.opt : none, Opt, some;
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
	mixin Union!(JsClassGetter, JsClassMethod, JsExpr);
}
immutable struct JsClassGetter {
	JsBlockStatement body_;
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

JsExpr genAnd(ref Alloc alloc, JsExpr arg0, JsExpr arg1) =>
	genBinary(alloc, JsBinaryExpr.Kind.and, arg0, arg1);
JsExpr genArray(JsExpr[] elements) =>
	JsExpr(JsArrayExpr(elements));
JsExpr genArrowFunction(SyncOrAsync async, JsParams params, JsExprOrBlockStatement body_) =>
	JsExpr(JsArrowFunction(async, params, body_));
JsExpr genArrowFunction(ref Alloc alloc, SyncOrAsync async, in JsDestructure[] params, JsExpr body_) =>
	genArrowFunction(async, JsParams(newSmallArray(alloc, params)), JsExprOrBlockStatement(allocate(alloc, body_)));
JsExpr genArrowFunction(ref Alloc alloc, SyncOrAsync async, in JsDestructure[] params, in JsStatement[] body_) =>
	genArrowFunction(
		async,
		JsParams(newSmallArray(alloc, params)),
		JsExprOrBlockStatement(genBlockStatement(alloc, body_)));
JsStatement genAssign(ref Alloc alloc, JsExpr left, JsExpr right) =>
	JsStatement(allocate(alloc, JsAssignStatement(left, right)));
JsStatement genAssign(ref Alloc alloc, JsName left, JsExpr right) =>
	genAssign(alloc, JsExpr(left), right);
JsExpr genAwait(ref Alloc alloc, JsExpr arg) =>
	genUnary(alloc, JsUnaryExpr.Kind.await, arg);
private JsExpr genAwaitIf(ref Alloc alloc, SyncOrAsync async, JsExpr arg) {
	final switch (async) {
		case SyncOrAsync.sync:
			return arg;
		case SyncOrAsync.async:
			return genAwait(alloc, arg);
	}
}
JsExpr genBinary(ref Alloc alloc, JsBinaryExpr.Kind kind, JsExpr arg0, JsExpr arg1) =>
	JsExpr(JsBinaryExpr(kind, allocate(alloc, arg0), allocate(alloc, arg1)));
JsExpr genBitwiseAnd(ref Alloc alloc, JsExpr arg0, JsExpr arg1) =>
	genBinary(alloc, JsBinaryExpr.Kind.bitwiseAnd, arg0, arg1);
JsExpr genBitwiseNot(ref Alloc alloc, JsExpr arg) =>
	genUnary(alloc, JsUnaryExpr.Kind.bitwiseNot, arg);
JsBlockStatement genBlockStatement(ref Alloc alloc, in JsStatement[] statements) =>
	JsBlockStatement(newArray(alloc, statements));
JsExpr genBool(bool value) =>
	JsExpr(JsLiteralBool(value));
JsStatement genBreakNoLabel() =>
	JsStatement(JsBreakStatement(none!JsName));
JsStatement genBreak(JsName label) =>
	JsStatement(JsBreakStatement(some(label)));
JsExpr genCall(ref Alloc alloc, SyncOrAsync await, JsExpr* called, JsExpr[] args) =>
	genAwaitIf(alloc, await, genCallSync(called, args));
JsExpr genCallAwait(ref Alloc alloc, JsExpr* called, JsExpr[] args) =>
	genAwait(alloc, genCallSync(called, args));
JsExpr genCallSync(JsExpr* called, JsExpr[] args) =>
	JsExpr(JsCallExpr(called, args));
JsExpr genCall(ref Alloc alloc, SyncOrAsync await, JsExpr called, in JsExpr[] args) =>
	genCall(alloc, await, allocate(alloc, called), newArray(alloc, args));
JsExpr genCallAwait(ref Alloc alloc, JsExpr called, in JsExpr[] args) =>
	genAwait(alloc, genCall(alloc, SyncOrAsync.async, called, args));
JsExpr genCallSync(ref Alloc alloc, JsExpr called, in JsExpr[] args) =>
	genCall(alloc, SyncOrAsync.sync, called, args);
JsExpr genCallWithSpread(ref Alloc alloc, SyncOrAsync await, JsExpr called, in JsExpr[] args, JsExpr spreadArg) =>
	genAwaitIf(
		alloc,
		await,
		JsExpr(JsCallWithSpreadExpr(allocate(alloc, called), newArray(alloc, args), allocate(alloc, spreadArg))));
JsExpr genCallPropertySync(ref Alloc alloc, JsExpr object, JsMemberName property, in JsExpr[] args) =>
	genCallSync(alloc, genPropertyAccess(alloc, object, property), args);
JsExpr genGlobal(Symbol name) =>
	JsExpr(JsName.noPrefix(name));
JsStatement genIf(ref Alloc alloc, JsExpr cond, JsStatement then) =>
	JsStatement(allocate(alloc, JsIfStatement(cond, then)));
JsStatement genIf(ref Alloc alloc, JsExpr cond, JsStatement then, JsStatement else_) =>
	JsStatement(allocate(alloc, JsIfStatement(cond, then, some(else_))));
JsExpr genIife(ref Alloc alloc, SyncOrAsync async, JsBlockStatement body_) =>
	genCall(alloc, async, allocate(alloc, genArrowFunction(async, JsParams(), JsExprOrBlockStatement(body_))), []);
JsExpr genIn(ref Alloc alloc, JsMemberName arg0, JsExpr arg1) =>
	genBinary(alloc, JsBinaryExpr.Kind.in_, genStringFromMemberName(arg0), arg1);
JsExpr genInstanceof(ref Alloc alloc, JsExpr arg0, JsExpr arg1) =>
	genBinary(alloc, JsBinaryExpr.Kind.instanceof, arg0, arg1);
JsExpr genInteger(bool isSigned, IntegralValue value) =>
	JsExpr(JsLiteralInteger(isSigned, value));
JsExpr genIntegerSigned(long value) =>
	genInteger(true, IntegralValue(value));
JsExpr genIntegerUnsigned(ulong value) =>
	genInteger(false, IntegralValue(value));
JsExpr genNot(ref Alloc alloc, JsExpr arg) =>
	genUnary(alloc, JsUnaryExpr.Kind.not, arg);
JsExpr genNotEqEq(ref Alloc alloc, JsExpr left, JsExpr right) =>
	genBinary(alloc, JsBinaryExpr.Kind.notEqEq, left, right);
JsExpr genNull() =>
	JsExpr(JsNullExpr());
JsExpr genNumber(double value) =>
	JsExpr(JsLiteralNumber(value));
JsExpr genNew(ref Alloc alloc, JsExpr class_, in JsExpr[] args) =>
	genNew(allocate(alloc, class_), newArray(alloc, args));
JsExpr genNew(JsExpr* class_, JsExpr[] args) =>
	JsExpr(JsNewExpr(class_, args));
JsExpr genOr(ref Alloc alloc, JsExpr arg0, JsExpr arg1) =>
	genBinary(alloc, JsBinaryExpr.Kind.or, arg0, arg1);
JsExpr genPlus(ref Alloc alloc, JsExpr arg0, JsExpr arg1) =>
	genBinary(alloc, JsBinaryExpr.Kind.plus, arg0, arg1);
JsExpr genPropertyAccess(ref Alloc alloc, JsExpr arg, JsMemberName propertyName) =>
	JsExpr(JsPropertyAccessExpr(allocate(alloc, arg), propertyName));
JsExpr genPropertyAccessComputed(ref Alloc alloc, JsExpr object, JsExpr propertyName) =>
	propertyName.isA!JsLiteralString
		? genPropertyAccess(alloc, object, JsMemberName.noPrefix(symbolOfString(propertyName.as!JsLiteralString.value)))
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
JsStatement genVarDecl(JsVarDecl.Kind kind, JsDestructure destructure, Opt!(JsExpr*) initializer) =>
	JsStatement(JsVarDecl(kind, destructure, initializer));
JsStatement genConst(ref Alloc alloc, JsName name, JsExpr initializer) =>
	genConst(alloc, JsDestructure(name), initializer);
JsStatement genConst(ref Alloc alloc, JsDestructure destructure, JsExpr initializer) =>
	genVarDecl(JsVarDecl.Kind.const_, destructure, some(allocate(alloc, initializer)));
JsStatement genLet(JsName name) =>
	genVarDecl(JsVarDecl.Kind.let, JsDestructure(name), none!(JsExpr*));
JsStatement genLet(ref Alloc alloc, JsDestructure destructure, JsExpr initializer) =>
	genVarDecl(JsVarDecl.Kind.let, destructure, some(allocate(alloc, initializer)));
JsExpr genObject(ref Alloc alloc, JsMemberName name, JsExpr value) =>
	JsExpr(JsObject1Expr(name, allocate(alloc, value)));
JsExpr genString(string value) =>
	JsExpr(JsLiteralString(value));
JsExpr genStringFromSymbol(Symbol value) =>
	JsExpr(JsLiteralStringFromSymbol(value));
private JsExpr genStringFromMemberName(JsMemberName value) =>
	JsExpr(JsLiteralStringFromMemberName(value));
JsExpr genThis() =>
	JsExpr(JsThisExpr());
JsExpr genTimes(ref Alloc alloc, JsExpr left, JsExpr right) =>
	genBinary(alloc, JsBinaryExpr.Kind.times, left, right);
JsExpr genUnary(ref Alloc alloc, JsUnaryExpr.Kind kind, JsExpr arg) =>
	JsExpr(JsUnaryExpr(kind, allocate(alloc, arg)));
private JsExpr number0 = genNumber(0);
JsExpr genUndefined() =>
	JsExpr(JsUnaryExpr(JsUnaryExpr.Kind.void_, &number0));
JsStatement genWhile(ref Alloc alloc, JsExpr condition, JsBlockStatement body_) =>
	genWhile(alloc, none!JsName, condition, body_);
JsStatement genWhile(ref Alloc alloc, Opt!JsName label, JsExpr condition, JsBlockStatement body_) =>
	JsStatement(JsWhileStatement(label, allocate(alloc, condition), body_));
JsStatement genWhileTrue(ref Alloc alloc, JsBlockStatement body_) =>
	genWhileTrue(alloc, none!JsName, body_);
JsStatement genWhileTrue(ref Alloc alloc, Opt!JsName label, JsBlockStatement body_) =>
	genWhile(alloc, label, genBool(true), body_);

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
	JsBlockStatement body_,
) =>
	genInstanceMethod(async, name, JsParams(newSmallArray(alloc, params)), body_);
JsClassMember genInstanceMethod(
	ref Alloc alloc,
	SyncOrAsync async,
	JsMemberName name,
	in JsDestructure[] params,
	JsExpr body_,
) =>
	genInstanceMethod(alloc, async, name, params, genBlockStatement(alloc, [genReturn(alloc, body_)]));
JsClassMember genField(JsClassMember.Static static_, JsMemberName name, JsExpr value) =>
	JsClassMember(static_, name, JsClassMemberKind(value));
JsClassMember genGetter(JsClassMember.Static static_, JsMemberName name, JsBlockStatement body_) =>
	JsClassMember(static_, name, JsClassMemberKind(JsClassGetter(body_)));
