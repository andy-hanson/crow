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
	JsArrayExpr,
	JsArrowFunction,
	JsAssignStatement,
	JsBinaryExpr,
	JsBlockStatement,
	JsBreakStatement,
	JsCallExpr,
	JsCallWithSpreadExpr,
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
	JsExprOrBlockStatement,
	JsIfStatement,
	JsImport,
	JsLiteralBool,
	JsLiteralInteger,
	JsLiteralNumber,
	JsLiteralString,
	JsModuleAst,
	JsName,
	JsNewExpr,
	JsNullExpr,
	JsObjectDestructure,
	JsObjectExpr,
	JsParams,
	JsPropertyAccessExpr,
	JsPropertyAccessComputedExpr,
	JsReturnStatement,
	JsStatement,
	JsSwitchStatement,
	JsTernaryExpr,
	JsThrowStatement,
	JsTryCatchStatement,
	JsTryFinallyStatement,
	JsUnaryExpr,
	JsVarDecl,
	JsWhileStatement;
import util.alloc.alloc : Alloc;
import util.col.map : KeyValuePair;
import util.opt : force, has, none, Opt, some;
import util.symbol : Symbol, symbol, writeQuotedSymbol;
import util.uri : Path, RelPath;
import util.util : stringOfEnum, todo;
import util.writer : makeStringWithWriter, writeFloatLiteral, writeNewline, writeQuotedString, Writer, writeWithCommas;

string writeJsAst(ref Alloc alloc, in JsModuleAst a, bool isMain) =>
	makeStringWithWriter(alloc, (scope ref Writer writer) {
		foreach (JsImport x; a.imports)
			writeImportOrReExport(writer, "import", x);
		foreach (JsImport x; a.reExports)
			writeImportOrReExport(writer, "export", x);
		foreach (JsDecl x; a.decls)
			writeDecl(writer, x);
		if (isMain)
			writer ~= "\nmain()\n";
	});

private:

void writeJsName(scope ref Writer writer, in JsName name) {
	if (isJsKeyword(name.crowName) && !has(name.mangleIndex)) {
		writer ~= '_';
		writer ~= name.crowName;
	} else {
		foreach (dchar x; name.crowName) {
			Opt!string out_ = mangleChar(x);
			if (has(out_))
				writer ~= force(out_);
			else
				writer ~= x;
		}
		if (has(name.mangleIndex)) {
			writer ~= "__";
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
		case symbol!"new".value:
		case symbol!"null".value:
			return true;
		default:
			return false;
	}
}
bool isAllowedJsIdentifierChar(dchar a) =>
	!has(mangleChar(a));
Opt!string mangleChar(dchar a) {
	switch (a) {
		case '-':
			return some("_");
		case '+':
			return some("__plus");
		case '*':
			return some("__times");
		case '~':
			return some("__tilde");
		case '/':
			return some("__div");
		case '<':
			return some("__less");
		case '>':
			return some("__gt");
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

//TODO:MOVE? --------------------------------------------------------------------------------------------------------------------------
void writeQuotedRelPath(scope ref Writer writer, RelPath path) {
	writer ~= '"';
	if (path.nParents == 0)
		writer ~= "./";
	else
		foreach (uint i; 0 .. path.nParents)
			writer ~= "../";
	writer ~= path.path;
	writer ~= '"';
}

void writeDecl(scope ref Writer writer, in JsDecl decl) {
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
		});
	writer ~= "\n";
}

void writeClass(scope ref Writer writer, JsName name, in JsClassDecl x) {
	writer ~= "class ";
	writeJsName(writer, name);
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
	writeNamePossiblyBracketQuoted(writer, member.name);
	member.kind.matchIn!void(
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
	bool parens = alwaysParens || a.params.length != 1 || has(a.restParam);
	if (parens) writer ~= '(';
	writeWithCommas!JsDestructure(writer, a.params, (in JsDestructure x) {
		writeDestructure(writer, x);
	});
	if (has(a.restParam)) {
		writer ~= ", ...";
		writeDestructure(writer, force(a.restParam));
	}
	if (parens) writer ~= ')';
}
void writeDestructure(scope ref Writer writer, in JsDestructure a) {
	a.matchIn!void(
		(in JsName x) {
			writeJsName(writer, x);
		},
		(in JsObjectDestructure x) {
			writer ~= "{ ";
			writeWithCommas!(KeyValuePair!(Symbol, JsDestructure))(writer, x.fields, (in KeyValuePair!(Symbol, JsDestructure) pair) {
				writeObjectKey(writer, pair.key);
				writer ~= ": ";
				writeDestructure(writer, pair.value);
			});
		});
}

void writeBlockStatement(scope ref Writer writer, uint indent, in JsBlockStatement a) {
	writer ~= '{';
	foreach (JsStatement x; a.statements) {
		writeNewline(writer, indent + 1);
		writeStatement(writer, indent + 1, x);
	}
	writeNewline(writer, indent);
	writer ~= '}';
}

void writeExprOrBlockStatement(scope ref Writer writer, uint indent, in JsExprOrBlockStatement a) {
	a.matchIn!void(
		(in JsExpr x) {
			writeExpr(writer, indent + 1, x);
		},
		(in JsBlockStatement x) {
			writeBlockStatement(writer, indent, x);
		});
}

void writeStatement(scope ref Writer writer, uint indent, in JsStatement a) {
	a.matchIn!void(
		(in JsAssignStatement x) {
			writeAssign(writer, indent, x);
		},
		(in JsBlockStatement x) {
			writeBlockStatement(writer, indent, x);
		},
		(in JsBreakStatement x) {
			writer ~= "break";
		},
		(in JsContinueStatement x) {
			writer ~= "continue";
		},
		(in JsEmptyStatement x) {
			writer ~= "{}";
		},
		(in JsExpr x) {
			writeExpr(writer, indent, x, isStatement: true);
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
	if (writeStatementIndented(writer, indent, a.then))
		writer ~= ' ';
	writer ~= "else";
	writeStatementIndented(writer, indent, a.else_);
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
	writer ~= " = ";
	writeExpr(writer, indent, *a.initializer);
}
pragma(inline, false)
void writeWhile(scope ref Writer writer, uint indent, in JsWhileStatement a) {
	writer ~= "while (";
	writeExpr(writer, indent + 2, a.condition);
	writer ~= ')';
	writeStatementIndented(writer, indent, a.body_);
}

bool writeStatementIndented(scope ref Writer writer, uint indent, in JsStatement a) {
	if (a.isA!JsBlockStatement) {
		writer ~= ' ';
		writeBlockStatement(writer, indent, a.as!JsBlockStatement);
		return true;
	} else {
		writeNewline(writer, indent + 1);
		writeStatement(writer, indent + 1, a);
		return false;
	}
}

void writeExpr(scope ref Writer writer, uint indent, in JsExpr a, bool isStatement = false) {
	void writeArg(in JsExpr arg, bool isStatement = false) {
		writeExpr(writer, indent, arg);
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
			writeParams(writer, x.params, alwaysParens: false);
			writer ~= " => ";
			writeExprOrBlockStatement(writer, indent, x.body_);
		},
		(in JsBinaryExpr x) {
			assert(!isStatement);
			writer ~= '(';
			writeArg(*x.left);
			writer ~= ' ';
			writer ~= () {
				final switch (x.kind) {
					case JsBinaryExpr.Kind.eqEqEq:
						return "===";
					case JsBinaryExpr.Kind.in_:
						return "in";
					case JsBinaryExpr.Kind.instanceof:
						return "instanceof";
					case JsBinaryExpr.Kind.or:
						return "or";
				}
			}();
			writer ~= ' ';
			writeArg(*x.right);
			writer ~= ')';
		},
		(in JsCallExpr x) {
			writeArg(*x.called, isStatement);
			writer ~= '(';
			writeArgs(x.args);
			writer ~= ')';
		},
		(in JsCallWithSpreadExpr x) {
			writeArg(*x.called, isStatement);
			writer ~= '(';
			writeArgs(x.args);
			writer ~= ", ...";
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
			writeFloatLiteral(writer, x.value);
		},
		(in JsLiteralString x) {
			writeQuotedString(writer, x.value);
		},
		(in JsName x) {
			writeJsName(writer, x);
		},
		(in JsNewExpr x) {
			writer ~= "new ";
			writeArg(*x.class_);
			writer ~= '(';
			writeArgs(x.arguments);
			writer ~= ')';
		},
		(in JsNullExpr x) {
			writer ~= "null";
		},
		(in JsObjectExpr x) {
			assert(!isStatement);
			writer ~= "{ ";
			writeWithCommas!(KeyValuePair!(Symbol, JsExpr))(writer, x.fields, (in KeyValuePair!(Symbol, JsExpr) field) {
				writeObjectKey(writer, field.key);
				writer ~= ": ";
				writeArg(field.value);
			});
			writer ~= " }";
		},
		(in JsPropertyAccessExpr x) {
			writeArg(*x.object, isStatement);
			writePropertyAccess(writer, x.propertyName);
		},
		(in JsPropertyAccessComputedExpr x) {
			writeArg(x.object, isStatement);
			writer ~= '[';
			writeArg(x.propertyName);
			writer ~= ']';
		},
		(in JsTernaryExpr x) {
			writeArg(x.condition, isStatement);
			writer ~= " ? ";
			writeArg(x.then);
			writer ~= " : ";
			writeArg(x.else_);
		},
		(in JsUnaryExpr x) {
			writer ~= () {
				final switch (x.kind) {
					case JsUnaryExpr.Kind.not:
						return "!";
					case JsUnaryExpr.Kind.typeof_:
						return "typeof ";
					case JsUnaryExpr.Kind.void_:
						return "void ";
				}
			}();
			writeArg(*x.arg);
		});
}
