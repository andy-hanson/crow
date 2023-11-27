module frontend.ide.getTokens;

@safe @nogc pure nothrow:

import std.range : iota;
import std.traits : EnumMembers, staticMap;

import frontend.parse.ast :
	ArrowAccessAst,
	AssertOrForbidAst,
	AssignmentAst,
	AssignmentCallAst,
	BogusAst,
	CallAst,
	DestructureAst,
	EmptyAst,
	ExprAst,
	FileAst,
	ForAst,
	FunDeclAst,
	FunModifierAst,
	IdentifierAst,
	IfAst,
	IfOptionAst,
	ImportOrExportAst,
	ImportsOrExportsAst,
	InterpolatedAst,
	InterpolatedPart,
	LambdaAst,
	LetAst,
	LiteralFloatAst,
	LiteralIntAst,
	LiteralNatAst,
	LiteralStringAst,
	LoopAst,
	LoopBreakAst,
	LoopContinueAst,
	LoopUntilAst,
	LoopWhileAst,
	MatchAst,
	ModifierAst,
	NameAndRange,
	ParamsAst,
	ParenthesizedAst,
	pathRange,
	PtrAst,
	range,
	rangeOfModifierAst,
	rangeOfNameAndRange,
	SeqAst,
	SpecBodyAst,
	SpecDeclAst,
	SpecSigAst,
	StructAliasAst,
	StructDeclAst,
	suffixRange,
	ThenAst,
	ThrowAst,
	TrustedAst,
	TypeAst,
	TypedAst,
	UnlessAst,
	VarDeclAst,
	WithAst;
import lib.lsp.lspTypes : SemanticTokens;
import model.model : symOfVarKind;
import util.alloc.alloc : Alloc;
import util.col.arr : empty;
import util.col.arrBuilder : add, addAll, ArrBuilder, finishArr;
import util.col.arrUtil : arrLiteral;
import util.col.sortUtil : eachSorted;
import util.conv : safeToUint;
import util.json : field, Json, jsonList, jsonObject;
import util.lineAndColumnGetter : LineAndCharacter, LineAndCharacterRange, lineAndCharacterRange, LineAndColumnGetter;
import util.opt : force, has, Opt;
import util.sourceRange : compareRange, Pos, rangeOfStartAndLength, rangeOfStartAndName, Range;
import util.sym : AllSymbols, Sym, sym, symSize;
import util.uri : AllUris;

SemanticTokens tokensOfAst(
	ref Alloc alloc,
	in AllSymbols allSymbols,
	in AllUris allUris,
	in LineAndColumnGetter lineAndColumnGetter,
	in FileAst ast,
) {
	TokensBuilder tokens = TokensBuilder(&alloc, lineAndColumnGetter);

	if (has(ast.imports))
		addImportTokens(tokens, allSymbols, allUris, force(ast.imports));
	if (has(ast.exports))
		addImportTokens(tokens, allSymbols, allUris, force(ast.exports));

	//TODO: also tests...
	eachSorted!(Range, SpecDeclAst, StructAliasAst, StructDeclAst, FunDeclAst, VarDeclAst)(
		Range.max,
		(in Range a, in Range b) =>
			compareRange(a, b),
		ast.specs, (in SpecDeclAst x) => x.range, (in SpecDeclAst x) {
			addSpecTokens(tokens, allSymbols, x);
		},
		ast.structAliases, (in StructAliasAst x) => x.range, (in StructAliasAst x) {
			addStructAliasTokens(tokens, allSymbols, x);
		},
		ast.structs, (in StructDeclAst x) => x.range, (in StructDeclAst x) {
			addStructTokens(tokens, allSymbols, x);
		},
		ast.funs, (in FunDeclAst x) => x.range, (in FunDeclAst x) {
			addFunTokens(tokens, allSymbols, x);
		},
		ast.vars, (in VarDeclAst x) => x.range, (in VarDeclAst x) {
			addVarDeclTokens( tokens, allSymbols, x);
		});
	return SemanticTokens(finishArr(alloc, tokens.encoded));
}

Json jsonOfDecodedTokens(ref Alloc alloc, in SemanticTokens a) {
	ArrBuilder!Json res;
	decodeTokens(a, (in LineAndCharacter lc, size_t length, TokenType type, TokenModifiers modifiers) {
		add(alloc, res, jsonObject(alloc, [
			field!"line"(lc.line),
			field!"character"(lc.character),
			field!"length"(length),
			field!"type"(stringOfTokenType(type)),
			field!"modifiers"(jsonList(modifiers == noTokenModifiers
				? []
				: arrLiteral(alloc, [Json(stringOfTokenModifier(modifiers))])))]));
	});
	return jsonList(finishArr(alloc, res));
}

Json getTokensLegend() {
	static immutable Json.StringObject fields = [
		Json.StringObjectField("tokenTypes", Json(allTokenTypesJson)),
		Json.StringObjectField("tokenModifiers", Json(allTokenModifiersJson)),
	];
	return Json(fields);
}

private:

void decodeTokens(
	in SemanticTokens a,
	in void delegate(in LineAndCharacter, size_t, TokenType, TokenModifiers) @safe @nogc pure nothrow cb,
) {
	uint line = 0;
	uint character = 0;
	foreach (size_t i; iota(0, a.data.length, 5)) {
		uint deltaLine = a.data[i];
		uint deltaCharacter = a.data[i + 1];
		uint length = a.data[i + 2];
		TokenType type = cast(TokenType) a.data[i + 3];
		TokenModifiers modifiers = cast(TokenModifiers) a.data[i + 4];
		if (deltaLine == 0)
			character += deltaCharacter;
		else {
			line += deltaLine;
			character = deltaCharacter;
		}
		cb(LineAndCharacter(line, character), length, type, modifiers);
	}
}

enum TokenType {
	comment,
	enum_,
	enumMember,
	function_,
	interface_,
	keyword,
	namespace,
	number,
	parameter,
	property,
	string,
	type,
	typeParameter,
	variable,
}
// This will be a flags enum
enum TokenModifiers {
	declaration = 1,
}

immutable Json[] allTokenTypesJson = [staticMap!(jsonOfTokenType, EnumMembers!TokenType)];
enum jsonOfTokenType(TokenType a) = Json(stringOfTokenType(a));

TokenModifiers noTokenModifiers() =>
	cast(TokenModifiers) 0;
immutable Json[] allTokenModifiersJson = [staticMap!(jsonOfTokenModifier, EnumMembers!TokenModifiers)];
enum jsonOfTokenModifier(TokenModifiers a) = Json(stringOfTokenModifier(a));

string stringOfTokenType(TokenType a) {
	final switch (a) {
		case TokenType.comment:
			return "comment";
		case TokenType.enum_:
			return "enum";
		case TokenType.enumMember:
			return "enumMember";
		case TokenType.function_:
			return "function";
		case TokenType.interface_:
			return "interface";
		case TokenType.keyword:
			return "keyword";
		case TokenType.namespace:
			return "namespace";
		case TokenType.number:
			return "number";
		case TokenType.parameter:
			return "parameter";
		case TokenType.property:
			return "property";
		case TokenType.string:
			return "string";
		case TokenType.type:
			return "type";
		case TokenType.typeParameter:
			return "typeParameter";
		case TokenType.variable:
			return "variable";
	}
}

string stringOfTokenModifier(TokenModifiers a) {
	final switch (a) {
		case TokenModifiers.declaration:
			return "declaration";
	}
}

struct TokensBuilder {
	Alloc* alloc;
	LineAndColumnGetter lineAndColumnGetter; //TODO:PERF this could just be a LineAndCharacterGetter
	ArrBuilder!(immutable uint) encoded;
	uint prevLine;
	uint prevCharacter;
}
void add(scope ref TokensBuilder a, Range range, TokenType type, TokenModifiers modifiers) {
	LineAndCharacterRange lcRange = lineAndCharacterRange(a.lineAndColumnGetter, range);
	assert(lcRange.start.line == lcRange.end.line);
	LineAndCharacter pos = lcRange.start;
	uint length = lcRange.end.character - lcRange.start.character;

	assert(a.prevLine < pos.line ||
		(a.prevLine == pos.line && a.prevCharacter < pos.character) ||
		(a.prevLine == 0 && a.prevCharacter == 0));
	immutable uint[5] toAdd = pos.line == a.prevLine
		? [0, pos.character - a.prevCharacter, length, type, modifiers]
		: [pos.line - a.prevLine, pos.character, length, type, modifiers];
	addAll!(immutable uint)(*a.alloc, a.encoded, toAdd);
	a.prevLine = pos.line;
	a.prevCharacter = pos.character;
}

void declare(scope ref TokensBuilder a, TokenType type, in Range range) {
	add(a, range, type, TokenModifiers.declaration);
}
void reference(scope ref TokensBuilder a, TokenType type, in Range range) {
	add(a, range, type, noTokenModifiers);
}
void keyword(scope ref TokensBuilder a, in Range range) {
	reference(a, TokenType.keyword, range);
}
void numberLiteral(scope ref TokensBuilder a, in Range range) {
	reference(a, TokenType.number, range);
}
void stringLiteral(scope ref TokensBuilder a, in Range range) {
	reference(a, TokenType.string, range);
}

Range rangeAtName(in AllSymbols allSymbols, Pos start, Sym name) =>
	Range(start, start + symSize(allSymbols, name));

void addImportTokens(
	scope ref TokensBuilder tokens,
	in AllSymbols allSymbols,
	in AllUris allUris,
	in ImportsOrExportsAst a,
) {
	// "export".length is the same
	keyword(tokens, a.range[0 .. "import".length]);
	foreach (ref ImportOrExportAst x; a.paths) {
		reference(tokens, TokenType.namespace, pathRange(allUris, x));
		// TODO: tokens for imported names
	}
}

void addSpecTokens(ref TokensBuilder tokens, in AllSymbols allSymbols, in SpecDeclAst a) {
	declare(tokens, TokenType.interface_, rangeOfNameAndRange(a.name, allSymbols));
	addTypeParamsTokens(tokens, allSymbols, a.typeParams);
	a.body_.matchIn!void(
		(in SpecBodyAst.Builtin) {},
		(in SpecSigAst[] sigs) {
			foreach (ref SpecSigAst sig; sigs) {
				declare(tokens, TokenType.function_, rangeAtName(allSymbols, sig.range.start, sig.name));
				addSigReturnTypeAndParamsTokens(tokens, allSymbols, sig.returnType, sig.params);
			}
		});
}

// LDC compilation is slow without this pragma.
// Might be https://github.com/ldc-developers/ldc/issues/3879
pragma(inline, false)
void addSigReturnTypeAndParamsTokens(
	scope ref TokensBuilder tokens,
	in AllSymbols allSymbols,
	in TypeAst returnType,
	in ParamsAst params,
) {
	addTypeTokens(tokens, allSymbols, returnType);
	params.matchIn!void(
		(in DestructureAst[] regular) {
			foreach (ref DestructureAst param; regular)
				addDestructureTokens(tokens, allSymbols, param);
		},
		(in ParamsAst.Varargs) {
			addDestructureTokens(tokens, allSymbols, params.as!(ParamsAst.Varargs*).param);
		});
}

void addTypeTokens(scope ref TokensBuilder tokens, in AllSymbols allSymbols, in TypeAst a) {
	a.matchIn!void(
		(in TypeAst.Bogus) {},
		(in TypeAst.Fun x) {
			keyword(tokens, rangeOfStartAndName(x.range.start, sym!"fun", allSymbols));
			foreach (TypeAst t; x.returnAndParamTypes)
				addTypeTokens(tokens, allSymbols, t);
		},
		(in TypeAst.Map x) {
			addTypeTokens(tokens, allSymbols, x.v);
			keyword(tokens, Range(range(x.v, allSymbols).end, range(x.k, allSymbols).start));
			addTypeTokens(tokens, allSymbols, x.k);
			keyword(tokens, rangeOfStartAndLength(range(x.k, allSymbols).end, "]".length));
		},
		(in NameAndRange x) {
			reference(tokens, TokenType.type, rangeOfNameAndRange(x, allSymbols));
		},
		(in TypeAst.SuffixName x) {
			addTypeTokens(tokens, allSymbols, x.left);
			reference(tokens, TokenType.type, rangeOfNameAndRange(x.name, allSymbols));
		},
		(in TypeAst.SuffixSpecial x) {
			addTypeTokens(tokens, allSymbols, x.left);
			declare(tokens, TokenType.type, suffixRange(x));
		},
		(in TypeAst.Tuple x) {
			foreach (TypeAst t; x.members)
				addTypeTokens(tokens, allSymbols, t);
		});
}

void addTypeParamsTokens(scope ref TokensBuilder tokens, in AllSymbols allSymbols, in NameAndRange[] a) {
	foreach (NameAndRange typeParam; a)
		declare(tokens, TokenType.typeParameter, rangeOfNameAndRange(typeParam, allSymbols));
}

void addStructAliasTokens(scope ref TokensBuilder tokens, in AllSymbols allSymbols, in StructAliasAst a) {
	declare(tokens, TokenType.type, rangeOfNameAndRange(a.name, allSymbols));
	addTypeParamsTokens(tokens, allSymbols, a.typeParams);
	addTypeTokens(tokens, allSymbols, a.target);
}

void addStructTokens(scope ref TokensBuilder tokens, in AllSymbols allSymbols, in StructDeclAst a) {
	declare(tokens, TokenType.type, rangeOfNameAndRange(a.name, allSymbols));
	addTypeParamsTokens(tokens, allSymbols, a.typeParams);
	a.body_.matchIn!void(
		(in StructDeclAst.Body.Builtin) {
			addModifierTokens(tokens, allSymbols, a);
		},
		(in StructDeclAst.Body.Enum x) {
			addEnumOrFlagsTokens(tokens, allSymbols, a, x.typeArg, x.members);
		},
		(in StructDeclAst.Body.Extern) {
			addModifierTokens(tokens, allSymbols, a);
		},
		(in StructDeclAst.Body.Flags x) {
			addEnumOrFlagsTokens(tokens, allSymbols, a, x.typeArg, x.members);
		},
		(in StructDeclAst.Body.Record record) {
			addModifierTokens(tokens, allSymbols, a);
			foreach (ref StructDeclAst.Body.Record.Field field; record.fields) {
				declare(tokens, TokenType.property, rangeOfNameAndRange(field.name, allSymbols));
				addTypeTokens(tokens, allSymbols, field.type);
			}
		},
		(in StructDeclAst.Body.Union union_) {
			addModifierTokens(tokens, allSymbols, a);
			foreach (ref StructDeclAst.Body.Union.Member member; union_.members) {
				declare(tokens, TokenType.enumMember, rangeAtName(allSymbols, member.range.start, member.name));
				if (has(member.type))
					addTypeTokens(tokens, allSymbols, force(member.type));
			}
		});
}

void addModifierTokens(scope ref TokensBuilder tokens, in AllSymbols allSymbols, in StructDeclAst a) {
	foreach (ref ModifierAst x; a.modifiers)
		keyword(tokens, rangeOfModifierAst(x, allSymbols));
}
void addFunModifierTokens(scope ref TokensBuilder tokens, in AllSymbols allSymbols, in FunModifierAst[] a) {
	foreach (ref FunModifierAst mod; a) {
		mod.matchIn!void(
			(in FunModifierAst.Special x) {
				keyword(tokens, x.range(allSymbols));
			},
			(in FunModifierAst.Extern x) {
				addTypeTokens(tokens, allSymbols, *x.left);
				keyword(tokens, x.suffixRange(allSymbols));
			},
			(in TypeAst x) {
				if (x.isA!NameAndRange)
					reference(tokens, TokenType.interface_, x.range(allSymbols));
				else if (x.isA!(TypeAst.SuffixName*)) {
					TypeAst.SuffixName* n = x.as!(TypeAst.SuffixName*);
					addTypeTokens(tokens, allSymbols, n.left);
					reference(tokens, TokenType.interface_, rangeOfNameAndRange(n.name, allSymbols));
				}
				// else parse error, so ignore
			});
	}
}

void addEnumOrFlagsTokens(
	scope ref TokensBuilder tokens,
	in AllSymbols allSymbols,
	in StructDeclAst a,
	in Opt!(TypeAst*) typeArg,
	in StructDeclAst.Body.Enum.Member[] members,
) {
	if (has(typeArg))
		addTypeTokens(tokens, allSymbols, *force(typeArg));
	addModifierTokens(tokens, allSymbols, a);
	foreach (ref StructDeclAst.Body.Enum.Member member; members) {
		declare(tokens, TokenType.enumMember, member.range);
		if (has(member.value)) {
			uint addLen = " = ".length;
			Pos pos = member.range.start + symSize(allSymbols, member.name) + addLen;
			numberLiteral(tokens, Range(pos, member.range.end));
		}
	}
}

void addVarDeclTokens(scope ref TokensBuilder tokens, in AllSymbols allSymbols, in VarDeclAst a) {
	declare(tokens, TokenType.variable, rangeOfNameAndRange(a.name, allSymbols));
	addTypeParamsTokens(tokens, allSymbols, a.typeParams);
	keyword(tokens, rangeOfStartAndLength(a.kindPos, symSize(allSymbols, symOfVarKind(a.kind))));
	addTypeTokens(tokens, allSymbols, a.type);
	addFunModifierTokens(tokens, allSymbols, a.modifiers);
}

void addFunTokens(scope ref TokensBuilder tokens, in AllSymbols allSymbols, in FunDeclAst a) {
	declare(tokens, TokenType.function_, rangeOfNameAndRange(a.name, allSymbols));
	addTypeParamsTokens(tokens, allSymbols, a.typeParams);
	addSigReturnTypeAndParamsTokens(tokens, allSymbols, a.returnType, a.params);
	addFunModifierTokens(tokens, allSymbols, a.modifiers);
	if (has(a.body_))
		addExprTokens(tokens, allSymbols, force(a.body_));
}

void addExprTokens(scope ref TokensBuilder tokens, in AllSymbols allSymbols, in ExprAst a) {
	a.kind.matchIn!void(
		(in ArrowAccessAst x) {
			addExprTokens(tokens, allSymbols, *x.left);
			reference(tokens, TokenType.function_, rangeOfNameAndRange(x.name, allSymbols));
		},
		(in AssertOrForbidAst x) {
			// Only the length matters, and "assert" is same length as "forbid"
			keyword(tokens, rangeOfNameAndRange(NameAndRange(a.range.start, sym!"assert"), allSymbols));
			addExprTokens(tokens, allSymbols, x.condition);
			if (has(x.thrown))
				addExprTokens(tokens, allSymbols, force(x.thrown));
		},
		(in AssignmentAst x) {
			addExprTokens(tokens, allSymbols, x.left);
			keyword(tokens, rangeOfStartAndLength(x.assignmentPos, ":=".length));
			addExprTokens(tokens, allSymbols, x.right);
		},
		(in AssignmentCallAst x) {
			addExprTokens(tokens, allSymbols, x.left);
			reference(tokens, TokenType.function_, rangeOfNameAndRange(x.funName, allSymbols));
			addExprTokens(tokens, allSymbols, x.right);
		},
		(in BogusAst _) {},
		(in CallAst x) {
			void addName() {
				reference(tokens, TokenType.function_, rangeOfNameAndRange(x.funName, allSymbols));
				if (has(x.typeArg))
					addTypeTokens(tokens, allSymbols, *force(x.typeArg));
			}
			final switch (x.style) {
				case CallAst.Style.dot:
				case CallAst.Style.infix:
					addExprTokens(tokens, allSymbols, x.args[0]);
					addName();
					addExprsTokens(tokens, allSymbols, x.args[1 .. $]);
					break;
				case CallAst.Style.prefixBang:
					reference(tokens, TokenType.function_, rangeOfStartAndLength(x.funName.start, 1));
					addExprTokens(tokens, allSymbols, x.args[0]);
					break;
				case CallAst.Style.suffixBang:
					addExprTokens(tokens, allSymbols, x.args[0]);
					reference(tokens, TokenType.function_, rangeOfStartAndLength(x.funName.start, 1));
					break;
				case CallAst.style.emptyParens:
					break;
				case CallAst.style.prefixOperator:
				case CallAst.Style.single:
					addName();
					addExprsTokens(tokens, allSymbols, x.args);
					break;
				case CallAst.Style.comma:
				case CallAst.Style.subscript:
					addExprsTokens(tokens, allSymbols, x.args);
					break;
			}
		},
		(in EmptyAst x) {},
		(in ForAst x) {
			keyword(tokens, rangeOfStartAndLength(a.range.start, "for".length));
			addDestructureTokens(tokens, allSymbols, x.param);
			addExprTokens(tokens, allSymbols, x.collection);
			addExprTokens(tokens, allSymbols, x.body_);
			addExprTokens(tokens, allSymbols, x.else_);
		},
		(in IdentifierAst _) {
			reference(tokens, TokenType.variable, a.range);
		},
		(in IfAst x) {
			addExprTokens(tokens, allSymbols, x.cond);
			addExprTokens(tokens, allSymbols, x.then);
			addExprTokens(tokens, allSymbols, x.else_);
		},
		(in IfOptionAst x) {
			addDestructureTokens(tokens, allSymbols, x.destructure);
			addExprTokens(tokens, allSymbols, x.option);
			addExprTokens(tokens, allSymbols, x.then);
			addExprTokens(tokens, allSymbols, x.else_);
		},
		(in InterpolatedAst x) {
			Pos pos = a.range.start;
			if (!empty(x.parts)) {
				// Ensure opening quote is highlighted
				x.parts[0].matchIn!void(
					(in string) {},
					(in ExprAst _) {
						stringLiteral(tokens, Range(pos, pos + 1));
					});
				foreach (size_t i, ref InterpolatedPart part; x.parts)
					part.matchIn!void(
						(in string s) {
							// TODO: length may be wrong if there are escapes
							// Ensure the closing quote is highlighted
							Pos end = safeToUint(pos + s.length) + (i == x.parts.length - 1 ? 1 : 0);
							stringLiteral(tokens, Range(pos, end));
						},
						(in ExprAst e) {
							addExprTokens(tokens, allSymbols, e);
							pos = safeToUint(e.range.end + 1);
						});
				// Ensure closing quote is highlighted
				x.parts[$ - 1].matchIn!void(
					(in string) {},
					(in ExprAst _) {
						stringLiteral(tokens, Range(a.range.end - 1, a.range.end));
					});
			}
		},
		(in LambdaAst x) {
			addDestructureTokens(tokens, allSymbols, x.param);
			addExprTokens(tokens, allSymbols, x.body_);
		},
		(in LetAst x) {
			addDestructureTokens(tokens, allSymbols, x.destructure);
			addExprTokens(tokens, allSymbols, x.value);
			addExprTokens(tokens, allSymbols, x.then);
		},
		(in LiteralFloatAst _) {
			numberLiteral(tokens, a.range);
		},
		(in LiteralIntAst _) {
			numberLiteral(tokens, a.range);
		},
		(in LiteralNatAst _) {
			numberLiteral(tokens, a.range);
		},
		(in LiteralStringAst _) {
			stringLiteral(tokens, a.range);
		},
		(in LoopAst x) {
			keyword(tokens, rangeOfStartAndLength(a.range.start, "loop".length));
			addExprTokens(tokens, allSymbols, x.body_);
		},
		(in LoopBreakAst x) {
			keyword(tokens, rangeOfStartAndLength(a.range.start, "break".length));
			addExprTokens(tokens, allSymbols, x.value);
		},
		(in LoopContinueAst _) {
			keyword(tokens, rangeOfStartAndLength(a.range.start, "continue".length));
		},
		(in LoopUntilAst x) {
			keyword(tokens, rangeOfStartAndLength(a.range.start, "until".length));
			addExprTokens(tokens, allSymbols, x.condition);
			addExprTokens(tokens, allSymbols, x.body_);
		},
		(in LoopWhileAst x) {
			keyword(tokens, rangeOfStartAndLength(a.range.start, "while".length));
			addExprTokens(tokens, allSymbols, x.condition);
			addExprTokens(tokens, allSymbols, x.body_);
		},
		(in MatchAst x) {
			addExprTokens(tokens, allSymbols, x.matched);
			foreach (ref MatchAst.CaseAst case_; x.cases) {
				reference(tokens, TokenType.enumMember, case_.memberNameRange(allSymbols));
				if (has(case_.destructure))
					addDestructureTokens(tokens, allSymbols, force(case_.destructure));
				addExprTokens(tokens, allSymbols, case_.then);
			}
		},
		(in ParenthesizedAst x) {
			addExprTokens(tokens, allSymbols, x.inner);
		},
		(in PtrAst x) {
			addExprTokens(tokens, allSymbols, x.inner);
		},
		(in SeqAst x) {
			addExprTokens(tokens, allSymbols, x.first);
			addExprTokens( tokens, allSymbols, x.then);
		},
		(in ThenAst x) {
			addDestructureTokens(tokens, allSymbols, x.left);
			addExprTokens(tokens, allSymbols, x.futExpr);
			addExprTokens(tokens, allSymbols, x.then);
		},
		(in ThrowAst x) {
			keyword(tokens, rangeOfStartAndLength(a.range.start, "throw".length));
			addExprTokens(tokens, allSymbols, x.thrown);
		},
		(in TrustedAst x) {
			keyword(tokens, rangeOfStartAndLength(a.range.start, "trusted".length));
			addExprTokens(tokens, allSymbols, x.inner);
		},
		(in TypedAst x) {
			addExprTokens(tokens, allSymbols, x.expr);
			addTypeTokens(tokens, allSymbols, x.type);
		},
		(in UnlessAst x) {
			addExprTokens(tokens, allSymbols, x.cond);
			addExprTokens(tokens, allSymbols, x.body_);
		},
		(in WithAst x) {
			keyword(tokens, rangeOfStartAndLength(a.range.start, "with".length));
			addDestructureTokens(tokens, allSymbols, x.param);
			addExprTokens(tokens, allSymbols, x.arg);
			addExprTokens(tokens, allSymbols, x.body_);
		});
}

void addDestructureTokens(scope ref TokensBuilder tokens, in AllSymbols allSymbols, in DestructureAst a) {
	a.matchIn!void(
		(in DestructureAst.Single x) {
			declare(
				tokens,
				x.name.name == sym!"_" ? TokenType.comment : TokenType.parameter,
				rangeOfNameAndRange(x.name, allSymbols));
			//TODO: add 'mut' keyword
			if (has(x.type))
				addTypeTokens(tokens, allSymbols, *force(x.type));
		},
		(in DestructureAst.Void x) {
			keyword(tokens, a.range(allSymbols));
		},
		(in DestructureAst[] xs) {
			foreach (ref DestructureAst x; xs)
				addDestructureTokens(tokens, allSymbols, x);
		});
}

void addExprsTokens(scope ref TokensBuilder tokens, in AllSymbols allSymbols, in ExprAst[] exprs) {
	foreach (ref ExprAst expr; exprs)
		addExprTokens(tokens, allSymbols, expr);
}
