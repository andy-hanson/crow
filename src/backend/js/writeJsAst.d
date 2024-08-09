module backend.js.writeJsAst;

@safe @nogc pure nothrow:

import backend.js.allUsed : AnyDecl;
import backend.js.jsAst :
	JsArrayExpr,
	JsArrowFunction,
	JsAssignStatement,
	JsBinaryExpr,
	JsBlockStatement,
	JsBreakStatement,
	JsCallExpr,
	JsCallWithSpreadExpr,
	JsClassDecl,
	JsClassGetter,
	JsClassMember,
	JsClassMethod,
	JsContinueStatement,
	JsDecl,
	JsDeclKind,
	JsDefaultDestructure,
	JsDestructure,
	JsExpr,
	JsExprOrBlockStatement,
	JsIfStatement,
	JsImport,
	JsLiteralBool,
	JsLiteralInteger,
	JsLiteralNumber,
	JsLiteralString,
	JsLiteralStringFromSymbol,
	JsModuleAst,
	JsName,
	JsNewExpr,
	JsNullExpr,
	JsObjectDestructure,
	JsObject1Expr,
	JsParams,
	JsPropertyAccessExpr,
	JsPropertyAccessComputedExpr,
	JsReturnStatement,
	JsStatement,
	JsSwitchStatement,
	JsTernaryExpr,
	JsThisExpr,
	JsThrowStatement,
	JsTryCatchStatement,
	JsTryFinallyStatement,
	JsUnaryExpr,
	JsVarDecl,
	JsWhileStatement,
	SyncOrAsync;
import backend.mangle : genericMangleName, isAsciiIdentifierChar;
import frontend.showModel : ShowTypeCtx, writeFunDecl;
import model.model : FunDecl, SpecDecl, StructAlias, StructDecl, Test, VarDecl;
import util.alloc.alloc : Alloc;
import util.col.array : isEmpty, only;
import util.col.map : KeyValuePair;
import util.opt : force, has, none, Opt, some;
import util.symbol : Symbol, symbol, writeQuotedSymbol;
import util.uri : RelPath, Uri;
import util.util : stringOfEnum;
import util.writer : makeStringWithWriter, writeFloatLiteral, writeNewline, writeQuotedString, Writer, writeWithCommas;

string writeJsAst(ref Alloc alloc, in ShowTypeCtx showCtx, Uri sourceUri, in JsModuleAst a) =>
	makeStringWithWriter(alloc, (scope ref Writer writer) {
		writer ~= "// ";
		writer ~= sourceUri;
		writer ~= '\n';
		foreach (JsImport x; a.imports)
			writeImportOrReExport(writer, "import", x);
		foreach (JsImport x; a.reExports)
			writeImportOrReExport(writer, "export", x);
		foreach (JsDecl x; a.decls)
			writeDecl(writer, showCtx, x);
		foreach (JsStatement x; a.statements) {
			writeNewline(writer, 0);
			writeStatement(writer, 0, x, StatementPos.nonFirst);
		}
	});

private:

void writeJsName(scope ref Writer writer, in JsName name) {
	if (isJsKeyword(name.crowName) && !has(name.mangleIndex)) {
		writer ~= '_';
		writer ~= name.crowName;
	} else {
		writer ~= () {
			final switch (name.kind) {
				case JsName.Kind.none:
					return "";
				case JsName.Kind.function_:
					return "f_";
				case JsName.Kind.local:
					return "l_";
				case JsName.Kind.specSig:
					return "s_";
				case JsName.Kind.temp:
					return "x_";
				case JsName.Kind.type:
					return "t_";
			}
		}();
		genericMangleName(writer, name.crowName);
		if (has(name.mangleIndex)) {
			writer ~= "___";
			writer ~= force(name.mangleIndex);
		}
	}
}
void writeObjectKey(scope ref Writer writer, Symbol a) {
	if (needsMangle(a))
		writeQuotedSymbol(writer, a);
	else
		writer ~= a;
}
void writePropertyAccess(scope ref Writer writer, Symbol a) {
	if (needsMangle(a)) {
		writer ~= '[';
		writeQuotedSymbol(writer, a);
		writer ~= ']';
	} else {
		writer ~= '.';
		writer ~= a;
	}
}
void writeNamePossiblyBracketQuoted(scope ref Writer writer, Symbol a) {
	if (needsMangle(a)) {
		writer ~= '[';
		writeQuotedSymbol(writer, a);
		writer ~= ']';
	} else
		writer ~= a;
}
bool needsMangle(Symbol a) {
	foreach (dchar x; a)
		if (!isAllowedJsIdentifierChar(x))
			return true;
	return isJsKeyword(a);
}
bool isJsKeyword(Symbol a) {
	switch (a.value) {
		case symbol!"await".value:
		case symbol!"case".value:
		case symbol!"const".value:
		case symbol!"debugger".value:
		case symbol!"default".value:
		case symbol!"delete".value:
		case symbol!"enum".value:
		case symbol!"false".value:
		case symbol!"function".value:
		case symbol!"in".value:
		case symbol!"instanceof".value:
		case symbol!"let".value:
		case symbol!"new".value:
		case symbol!"null".value:
		case symbol!"static".value:
		case symbol!"switch".value:
		case symbol!"this".value:
		case symbol!"true".value:
		case symbol!"typeof".value:
		case symbol!"var".value:
		case symbol!"void".value:
			return true;
		default:
			return false;
	}
}
bool isAllowedJsIdentifierChar(dchar a) =>
	// TODO: JS allows more
	isAsciiIdentifierChar(a);

Opt!string mangleChar(dchar a) {
	switch (a) {
		case '+':
			return some("__plus");
		case '-':
			return some("_");
		case '*':
			return some("__times");
		case '/':
			return some("__div");
		case '%':
			return some("__mod");
		case '~':
			return some("__tilde");
		case '<':
			return some("__less");
		case '>':
			return some("__gt");
		case '=':
			return some("__eq");
		case '!':
			return some("__bang");
		case '.':
			return some("__dot");
		case '&':
			return some("__amp");
		case '|':
			return some("__bar");
		default:
			return none!string;
	}
}

void writeImportOrReExport(scope ref Writer writer, in string importOrExport, in JsImport import_) {
	writer ~= importOrExport;
	if (has(import_.importedNames)) {
		writer ~= " { ";
		writeWithCommas!JsName(writer, force(import_.importedNames), (in JsName name) {
			writeJsName(writer, name);
		});
		writer ~= " }";
	} else
		writer ~= " *";
	writer ~= " from ";
	writeQuotedRelPath(writer, import_.path);
	writer ~= "\n";
}

void writeQuotedRelPath(scope ref Writer writer, RelPath path) {
	writer ~= '"';
	writer ~= path;
	writer ~= '"';
}

void writeDecl(scope ref Writer writer, in ShowTypeCtx showCtx, in JsDecl decl) {
	writeDeclComment(writer, showCtx, decl.source);
	writer ~= '\n';
	final switch (decl.exported) {
		case JsDecl.Exported.private_:
			break;
		case JsDecl.Exported.export_:
			writer ~= "export ";
			break;
	}
	decl.kind.matchIn!void(
		(in JsClassDecl x) {
			writeClass(writer, decl.name, x);
		},
		(in JsExpr x) {
			writer ~= "const ";
			writeJsName(writer, decl.name);
			writer ~= " = ";
			writeExpr(writer, 0, x);
		},
		(in JsDeclKind.Let) {
			writer ~= "let ";
			writeJsName(writer, decl.name);
		});
	writer ~= "\n";
}

void writeDeclComment(scope ref Writer writer, in ShowTypeCtx showCtx, in AnyDecl a) {
	writer ~= "// ";
	writer ~= showCtx.lineAndColumnGetters[a.range].range;
	a.matchWithPointers!void(
		(FunDecl* x) {
			writer ~= ' ';
			writeFunDecl(writer, showCtx, x);
		},
		(SpecDecl*) {},
		(StructAlias*) {},
		(StructDecl*) {},
		(Test*) {},
		(VarDecl*) {});
}

void writeClass(scope ref Writer writer, JsName name, in JsClassDecl x) {
	writer ~= "class ";
	writeJsName(writer, name);
	if (has(x.extends)) {
		writer ~= " extends ";
		writeExpr(writer, 2, *force(x.extends));
	}

	writer ~= " {";
	foreach (JsClassMember member; x.members) {
		writeNewline(writer, 1);
		writeClassMember(writer, member);
	}
	writeNewline(writer, 0);
	writer ~= "}";
}
void writeClassMember(scope ref Writer writer, in JsClassMember member) {
	final switch (member.isStatic) {
		case JsClassMember.Static.instance:
			break;
		case JsClassMember.Static.static_:
			writer ~= "static ";
			break;
	}
	if (member.kind.isA!JsClassGetter)
		writer ~= "get ";
	if (member.kind.isA!JsClassMethod)
		maybeWriteAsync(writer, member.kind.as!JsClassMethod.async);
	writeNamePossiblyBracketQuoted(writer, member.name);
	member.kind.matchIn!void(
		(in JsClassGetter x) {
			writer ~= "() ";
			writeBlockStatement(writer, 1, x.body_);
		},
		(in JsClassMethod x) {
			writeParams(writer, x.params, alwaysParens: true);
			writeBlockStatement(writer, 1, x.body_);
		},
		(in JsExpr x) {
			writer ~= " = ";
			writeExpr(writer, 1, x);
		});
}

void writeParams(scope ref Writer writer, in JsParams a, bool alwaysParens) {
	bool parens = alwaysParens || a.params.length != 1 || !only(a.params).isA!JsName || has(a.restParam);
	if (parens) writer ~= '(';
	writeWithCommas!JsDestructure(writer, a.params, (in JsDestructure x) {
		writeDestructure(writer, x);
	});
	if (has(a.restParam)) {
		if (!isEmpty(a.params))
			writer ~= ", ";
		writer ~= "...";
		writeDestructure(writer, force(a.restParam));
	}
	if (parens) writer ~= ')';
}
void writeDestructure(scope ref Writer writer, in JsDestructure a) {
	a.matchIn!void(
		(in JsName x) {
			writeJsName(writer, x);
		},
		(in JsDefaultDestructure x) {
			writeDestructure(writer, x.left);
			writer ~= " = ";
			writeExpr(writer, 0, x.default_, ExprPos.expr);
		},
		(in JsObjectDestructure x) {
			writer ~= "{ ";
			writeWithCommas!(KeyValuePair!(Symbol, JsDestructure))(
				writer, x.fields,
				(in KeyValuePair!(Symbol, JsDestructure) pair) {
					writeObjectKey(writer, pair.key);
					writer ~= ": ";
					writeDestructure(writer, pair.value);
				});
			writer ~= " }";
		});
}

void writeBlockStatement(scope ref Writer writer, uint indent, in JsBlockStatement a) {
	writer ~= '{';
	foreach (size_t index, JsStatement x; a.statements) {
		writeNewline(writer, indent + 1);
		writeStatement(writer, indent + 1, x, index == 0 ? StatementPos.first : StatementPos.nonFirst);
	}
	writeNewline(writer, indent);
	writer ~= '}';
}

void writeExprOrBlockStatementIndented(scope ref Writer writer, uint indent, in JsExprOrBlockStatement a) {
	a.matchIn!void(
		(in JsExpr x) {
			writeNewline(writer, indent + 1);
			writeExpr(writer, indent + 1, x);
		},
		(in JsBlockStatement x) {
			writer ~= ' ';
			writeBlockStatement(writer, indent, x);
		});
}

enum StatementPos { first, nonFirst }
void writeStatement(scope ref Writer writer, uint indent, in JsStatement a, StatementPos pos) {
	a.matchIn!void(
		(in JsAssignStatement x) {
			writeAssign(writer, indent, x);
		},
		(in JsBlockStatement x) {
			writeBlockStatement(writer, indent, x);
		},
		(in JsBreakStatement x) {
			writer ~= "break";
			if (has(x.label)) {
				writer ~= ' ';
				writeJsName(writer, force(x.label));
			}
		},
		(in JsContinueStatement x) {
			writer ~= "continue";
		},
		(in JsExpr x) {
			writeExpr(writer, indent, x, () {
				final switch (pos) {
					case StatementPos.first:
						return ExprPos.statementFirst;
					case StatementPos.nonFirst:
						return ExprPos.statementNonFirst;
				}
			}());
		},
		(in JsIfStatement x) {
			writeIf(writer, indent, x);
		},
		(in JsReturnStatement x) {
			writer ~= "return ";
			writeExpr(writer, indent, *x.arg);
		},
		(in JsSwitchStatement x) {
			writeSwitch(writer, indent, x);
		},
		(in JsThrowStatement x) {
			writer ~= "throw ";
			writeExpr(writer, indent, *x.arg);
		},
		(in JsTryCatchStatement x) {
			writeTryCatch(writer, indent, x);
		},
		(in JsTryFinallyStatement x) {
			writeTryFinally(writer, indent, x);
		},
		(in JsVarDecl x) {
			writeVarDecl(writer, indent, x);
		},
		(in JsWhileStatement x) {
			writeWhile(writer, indent, x);
		});
}
// Optimized build has infinite compile time inlining 'writeStatement' into itself recursively.
// May be a similar issue to https://github.com/ldc-developers/ldc/issues/3879
pragma(inline, false)
void writeAssign(scope ref Writer writer, uint indent, in JsAssignStatement a) {
	writeExpr(writer, indent, a.left);
	writer ~= " = ";
	writeExpr(writer, indent, a.right);
}
pragma(inline, false)
void writeIf(scope ref Writer writer, uint indent, in JsIfStatement a) {
	writer ~= "if (";
	writeExpr(writer, indent + 2, a.cond);
	writer ~= ")";
	bool wasBlock = writeStatementIndented(writer, indent, a.then, StatementPos.first);
	if (has(a.else_)) {
		if (wasBlock)
			writer ~= ' ';
		else
			writeNewline(writer, indent);
		writer ~= "else";
		JsStatement else_ = force(a.else_);
		if (else_.isA!(JsIfStatement*)) {
			writer ~= ' ';
			writeStatement(writer, indent, else_, StatementPos.first);
		} else
			cast(void) writeStatementIndented(writer, indent, else_, StatementPos.first);
	}
}
pragma(inline, false)
void writeSwitch(scope ref Writer writer, uint indent, in JsSwitchStatement a) {
	writer ~= "switch (";
	writeExpr(writer, indent + 2, *a.arg);
	writer ~= ") {";
	foreach (JsSwitchStatement.Case case_; a.cases_) {
		writeNewline(writer, indent + 1);
		writer ~= "case ";
		writeExpr(writer, indent, case_.value);
		writer ~= ":";
		writeBlockStatement(writer, indent + 1, case_.then);
	}
	writeNewline(writer, indent + 1);
	writer ~= "default:";
	writeBlockStatement(writer, indent + 1, a.default_);
	writeNewline(writer, indent);
	writer ~= "}";
}
pragma(inline, false)
void writeTryCatch(scope ref Writer writer, uint indent, in JsTryCatchStatement a) {
	writer ~= "try ";
	writeBlockStatement(writer, indent, a.tried);
	writer ~= " catch (";
	writeJsName(writer, a.exception);
	writer ~= ") ";
	writeBlockStatement(writer, indent, a.catch_);
}
pragma(inline, false)
void writeTryFinally(scope ref Writer writer, uint indent, in JsTryFinallyStatement a) {
	writer ~= "try ";
	writeBlockStatement(writer, indent, a.tried);
	writer ~= " finally ";
	writeBlockStatement(writer, indent, a.finally_);
}
pragma(inline, false)
void writeVarDecl(scope ref Writer writer, uint indent, in JsVarDecl a) {
	writer ~= stringOfEnum(a.kind);
	writer ~= ' ';
	writeDestructure(writer, a.destructure);
	if (has(a.initializer)) {
		writer ~= " = ";
		writeExpr(writer, indent, *force(a.initializer));
	}
}
pragma(inline, false)
void writeWhile(scope ref Writer writer, uint indent, in JsWhileStatement a) {
	if (has(a.label)) {
		writeJsName(writer, force(a.label));
		writer ~= ": ";
	}
	writer ~= "while (";
	writeExpr(writer, indent + 2, *a.condition);
	writer ~= ')';
	writeBlockStatement(writer, indent, a.body_);
}

// Returns true if it was a block
bool writeStatementIndented(scope ref Writer writer, uint indent, in JsStatement a, StatementPos pos) {
	if (a.isA!JsBlockStatement) {
		writer ~= ' ';
		writeBlockStatement(writer, indent, a.as!JsBlockStatement);
		return true;
	} else {
		writeNewline(writer, indent + 1);
		writeStatement(writer, indent + 1, a, pos);
		return false;
	}
}

struct ExprPos {
	@safe @nogc pure nothrow:

	bool isNonFirstStatement; // Expression is at the start of a statement and may need ';'
	bool isCalled; // Expression is called and may need to be wrapped in '()'

	ExprPos withCalled() =>
		ExprPos(isNonFirstStatement, isCalled: true);

	static ExprPos expr() =>
		ExprPos(false, false);
	static ExprPos statementFirst() =>
		ExprPos(isNonFirstStatement: false, isCalled: false);
	static ExprPos statementNonFirst() =>
		ExprPos(isNonFirstStatement: true, isCalled: false);
}
void writeExpr(scope ref Writer writer, uint indent, in JsExpr a, ExprPos pos = ExprPos.expr) {
	void writeArg(in JsExpr arg, ExprPos pos = ExprPos.expr) {
		writeExpr(writer, indent, arg, pos);
	}
	void writeArgs(in JsExpr[] args) {
		writeWithCommas!JsExpr(writer, args, (in JsExpr arg) {
			writeExpr(writer, indent + 1, arg);
		});
	}

	a.matchIn!void(
		(in JsArrayExpr x) {
			writer ~= '[';
			writeArgs(x.elements);
			writer ~= ']';
		},
		(in JsArrowFunction x) {
			if (pos.isNonFirstStatement)
				writer ~= ';';
			if (pos.isCalled)
				writer ~= '(';
			maybeWriteAsync(writer, x.async);
			writeParams(writer, x.params, alwaysParens: false);
			writer ~= " =>";
			writeExprOrBlockStatementIndented(writer, indent, x.body_);
			if (pos.isCalled)
				writer ~= ')';
		},
		(in JsBinaryExpr x) {
			if (pos.isNonFirstStatement)
				writer ~= ';';
			writer ~= '(';
			writeArg(*x.left);
			writer ~= ' ';
			writer ~= () {
				final switch (x.kind) {
					case JsBinaryExpr.Kind.and:
						return "&&";
					case JsBinaryExpr.Kind.bitShiftLeft:
						return "<<";
					case JsBinaryExpr.Kind.bitShiftRight:
						return ">>";
					case JsBinaryExpr.Kind.bitwiseAnd:
						return "&";
					case JsBinaryExpr.Kind.bitwiseOr:
						return "|";
					case JsBinaryExpr.Kind.bitwiseXor:
						return "^";
					case JsBinaryExpr.Kind.divide:
						return "/";
					case JsBinaryExpr.Kind.eqEqEq:
						return "===";
					case JsBinaryExpr.Kind.in_:
						return "in";
					case JsBinaryExpr.Kind.instanceof:
						return "instanceof";
					case JsBinaryExpr.Kind.less:
						return "<";
					case JsBinaryExpr.Kind.minus:
						return "-";
					case JsBinaryExpr.Kind.modulo:
						return "%";
					case JsBinaryExpr.Kind.notEqEq:
						return "!==";
					case JsBinaryExpr.Kind.or:
						return "||";
					case JsBinaryExpr.Kind.plus:
						return "+";
					case JsBinaryExpr.Kind.times:
						return "*";
				}
			}();
			writer ~= ' ';
			writeArg(*x.right);
			writer ~= ')';
		},
		(in JsCallExpr x) {
			writeArg(*x.called, pos.withCalled);
			writer ~= '(';
			writeArgs(x.args);
			writer ~= ')';
		},
		(in JsCallWithSpreadExpr x) {
			writeArg(*x.called, pos.withCalled);
			writer ~= '(';
			writeArgs(x.args);
			if (!isEmpty(x.args))
				writer ~= ", ";
			writer ~= "...";
			writeArg(*x.spreadArg);
			writer ~= ')';
		},
		(in JsLiteralBool x) {
			writer ~= x.value;
		},
		(in JsLiteralInteger x) {
			if (x.isSigned)
				writer ~= x.value.asSigned;
			else
				writer ~= x.value.asUnsigned;
			writer ~= 'n';
		},
		(in JsLiteralNumber x) {
			writeFloatLiteral(writer, x.value, infinity: "Number.POSITIVE_INFINITY", nan: "Number.NaN");
		},
		(in JsLiteralString x) {
			writeQuotedString(writer, x.value);
		},
		(in JsLiteralStringFromSymbol x) {
			writeQuotedSymbol(writer, x.value);
		},
		(in JsName x) {
			writeJsName(writer, x);
		},
		(in JsNewExpr x) {
			writer ~= "new ";
			writer ~= '(';
			writeArg(*x.class_);
			writer ~= ')';
			writer ~= '(';
			writeArgs(x.arguments);
			writer ~= ')';
		},
		(in JsNullExpr x) {
			writer ~= "null";
		},
		(in JsObject1Expr x) {
			assert(!pos.isNonFirstStatement);
			writer ~= "{ ";
			writeObjectPair(writer, indent, x.key, *x.value);
			writer ~= " }";
		},
		(in JsPropertyAccessExpr x) {
			writeArg(*x.object, pos);
			writePropertyAccess(writer, x.propertyName);
		},
		(in JsPropertyAccessComputedExpr x) {
			writeArg(x.object, pos);
			writer ~= '[';
			writeArg(x.propertyName);
			writer ~= ']';
		},
		(in JsTernaryExpr x) {
			writeArg(x.condition, pos);
			writer ~= " ? ";
			writeArg(x.then);
			writer ~= " : ";
			writeArg(x.else_);
		},
		(in JsThisExpr x) {
			writer ~= "this";
		},
		(in JsUnaryExpr x) {
			if (pos.isNonFirstStatement)
				writer ~= ';';
			writer ~= '(';
			writer ~= () {
				final switch (x.kind) {
					case JsUnaryExpr.Kind.await:
						return "await ";
					case JsUnaryExpr.Kind.bitwiseNot:
						return "~";
					case JsUnaryExpr.Kind.not:
						return "!";
					case JsUnaryExpr.Kind.typeof_:
						return "typeof ";
					case JsUnaryExpr.Kind.void_:
						return "void ";
				}
			}();
			writeArg(*x.arg);
			writer ~= ')';
		});
}

void maybeWriteAsync(scope ref Writer writer, SyncOrAsync async) {
	final switch (async) {
		case SyncOrAsync.sync:
			break;
		case SyncOrAsync.async:
			writer ~= "async ";
			break;
	}
}

void writeObjectPair(scope ref Writer writer, uint indent, Symbol key, in JsExpr value) {
	writeObjectKey(writer, key);
	writer ~= ": ";
	writeExpr(writer, indent, value);
}
