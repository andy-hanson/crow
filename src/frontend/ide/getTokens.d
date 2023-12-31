module frontend.ide.getTokens;

@safe @nogc pure nothrow:

import std.range : iota;
import std.traits : EnumMembers, staticMap;

import frontend.parse.lexWhitespace : lexTokensBetweenAsts;
import frontend.storage : SourceAndAst;
import lib.lsp.lspTypes : SemanticTokens;
import model.ast :
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
	StructBodyAst,
	StructDeclAst,
	suffixRange,
	ThenAst,
	TestAst,
	ThrowAst,
	TrustedAst,
	TypeAst,
	TypedAst,
	UnlessAst,
	VarDeclAst,
	WithAst;
import util.alloc.alloc : Alloc;
import util.col.array : isEmpty, newArray;
import util.col.arrayBuilder : add, addAll, ArrayBuilder, finish;
import util.col.sortUtil : eachSorted, sortedIter;
import util.conv : safeToUint;
import util.json : field, Json, jsonList, jsonObject;
import util.opt : force, has, Opt;
import util.sourceRange :
	LineAndCharacterGetter,
	LineAndCharacter,
	LineAndCharacterRange,
	lineLengthInCharacters,
	Pos,
	rangeContains,
	rangeOfStartAndLength,
	Range;
import util.string : CString, cStringSize;
import util.symbol : AllSymbols, Symbol, symbol, symbolSize;
import util.uri : AllUris;
import util.util : ptrTrustMe, stringOfEnum;

SemanticTokens tokensOfAst(
	ref Alloc alloc,
	in AllSymbols allSymbols,
	in AllUris allUris,
	in LineAndCharacterGetter lineAndCharacterGetter,
	in SourceAndAst sourceAndAst,
) {
	scope Ctx ctx = Ctx(TokensBuilder(sourceAndAst.source, &alloc, lineAndCharacterGetter), ptrTrustMe(allSymbols));
	FileAst* ast = sourceAndAst.ast;

	if (has(ast.imports))
		addImportTokens(ctx, allUris, force(ast.imports));
	if (has(ast.reExports))
		addImportTokens(ctx, allUris, force(ast.reExports));

	eachSorted!(Pos, Ctx)(
		ctx,
		sortedIter!(SpecDeclAst, Pos, Ctx, (in SpecDeclAst x) => x.range.start, addSpecTokens)(ast.specs),
		sortedIter!(StructAliasAst, Pos, Ctx, (in StructAliasAst x) => x.range.start, addStructAliasTokens)(
			ast.structAliases),
		sortedIter!(StructDeclAst, Pos, Ctx, (in StructDeclAst x) => x.range.start, addStructTokens)(ast.structs),
		sortedIter!(FunDeclAst, Pos, Ctx, (in FunDeclAst x) => x.range.start, addFunTokens)(ast.funs),
		sortedIter!(TestAst, Pos, Ctx, (in TestAst x) => x.range.start, addTestTokens)(ast.tests),
		sortedIter!(VarDeclAst, Pos, Ctx, (in VarDeclAst x) => x.range.start, addVarDeclTokens)(ast.vars));
	addLastTokens(ctx.tokens);
	return SemanticTokens(finish(alloc, ctx.tokens.encoded));
}

Json jsonOfDecodedTokens(ref Alloc alloc, in SemanticTokens a) {
	ArrayBuilder!Json res;
	decodeTokens(a, (in LineAndCharacter lc, size_t length, TokenType type, TokenModifiers modifiers) {
		add(alloc, res, jsonObject(alloc, [
			field!"line"(lc.line),
			field!"character"(lc.character),
			field!"length"(length),
			field!"type"(stringOfTokenType(type)),
			field!"modifiers"(jsonList(modifiers == noTokenModifiers
				? []
				: newArray(alloc, [Json(stringOfTokenModifier(modifiers))])))]));
	});
	return jsonList(finish(alloc, res));
}

Json getTokensLegend() {
	static immutable Json.StringObject fields = [
		Json.StringObjectField("tokenTypes", Json(allTokenTypesJson)),
		Json.StringObjectField("tokenModifiers", Json(allTokenModifiersJson)),
	];
	return Json(fields);
}

private:

struct Ctx {
	@safe @nogc pure nothrow:

	TokensBuilder tokens;
	const AllSymbols* allSymbolsPtr;

	ref const(AllSymbols) allSymbols() return scope =>
		*allSymbolsPtr;
}

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

string stringOfTokenType(TokenType a) =>
	stringOfEnum(a);

string stringOfTokenModifier(TokenModifiers a) {
	final switch (a) {
		case TokenModifiers.declaration:
			return "declaration";
	}
}

struct TokensBuilder {
	CString source;
	Alloc* alloc;
	LineAndCharacterGetter lineAndCharacterGetter;
	ArrayBuilder!(immutable uint) encoded;
	Pos prevPos;
	uint prevLine;
	uint prevCharacter;
}
void add(scope ref TokensBuilder a, Range range, TokenType type, TokenModifiers modifiers) {
	if (range.length != 0) { // This can happen for missing names
		addTokensBetween(a, Range(a.prevPos, range.start));
		a.prevPos = range.end;
		addInner(a, range, type, modifiers);
	}
}

void addLastTokens(scope ref TokensBuilder a) {
	addTokensBetween(a, rangeOfStartAndLength(a.prevPos, cStringSize((() @trusted => a.source.jumpTo(a.prevPos))())));
}

void addInner(scope ref TokensBuilder a, Range range, TokenType type, TokenModifiers modifiers) {
	LineAndCharacterRange lcRange = a.lineAndCharacterGetter[range];
	LineAndCharacter start = lcRange.start;
	LineAndCharacter end = lcRange.end;
	if (start.line == end.line)
		addSingleLineToken(a, start, range.length, type, modifiers);
	else {
		uint firstLength = lineLengthInCharacters(a.lineAndCharacterGetter, start.line) - start.character;
		addSingleLineToken(a, start, firstLength, type, modifiers);
		foreach (uint line; start.line + 1 .. end.line)
			addSingleLineToken(
				a, LineAndCharacter(line, 0), lineLengthInCharacters(a.lineAndCharacterGetter, line), type, modifiers);
		addSingleLineToken(a, LineAndCharacter(end.line, 0), end.character, type, modifiers);
	}
}

void addSingleLineToken(
	scope ref TokensBuilder a,
	in LineAndCharacter pos,
	uint length,
	TokenType type,
	TokenModifiers modifiers,
) {
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

@trusted void addTokensBetween(scope ref TokensBuilder a, Range range) {
	lexTokensBetweenAsts(
		a.source, range,
		(Range commentRange) {
			assert(rangeContains(range, commentRange));
			addInner(a, commentRange, TokenType.comment, noTokenModifiers);
		},
		(Range keywordRange) {
			assert(rangeContains(range, keywordRange));
			addInner(a, keywordRange, TokenType.keyword, noTokenModifiers);
		});
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
void keyword(scope ref TokensBuilder a, Pos start, in string name) {
	keyword(a, rangeOfStartAndLength(start, name.length));
}
void numberLiteral(scope ref TokensBuilder a, in Range range) {
	reference(a, TokenType.number, range);
}
void stringLiteral(scope ref TokensBuilder a, in Range range) {
	reference(a, TokenType.string, range);
}

Range rangeAtName(in AllSymbols allSymbols, Pos start, Symbol name) =>
	Range(start, start + symbolSize(allSymbols, name));

void addImportTokens(scope ref Ctx ctx, in AllUris allUris, in ImportsOrExportsAst a) {
	// "export".length is the same
	keyword(ctx.tokens, a.range.start, "import");
	foreach (ref ImportOrExportAst x; a.paths) {
		reference(ctx.tokens, TokenType.namespace, pathRange(allUris, x));
		// TODO: tokens for imported names
	}
}

void addSpecTokens(scope ref Ctx ctx, in SpecDeclAst a) {
	declare(ctx.tokens, TokenType.interface_, rangeOfNameAndRange(a.name, ctx.allSymbols));
	addTypeParamsTokens(ctx, a.typeParams);
	a.body_.matchIn!void(
		(in SpecBodyAst.Builtin) {},
		(in SpecSigAst[] sigs) {
			foreach (ref SpecSigAst sig; sigs) {
				declare(ctx.tokens, TokenType.function_, rangeAtName(ctx.allSymbols, sig.range.start, sig.name));
				addSigReturnTypeAndParamsTokens(ctx, sig.returnType, sig.params);
			}
		});
}

void addSigReturnTypeAndParamsTokens(scope ref Ctx ctx, in TypeAst returnType, in ParamsAst params) {
	addTypeTokens(ctx, returnType);
	params.matchIn!void(
		(in DestructureAst[] regular) {
			foreach (ref DestructureAst param; regular)
				addDestructureTokens(ctx, param);
		},
		(in ParamsAst.Varargs) {
			addDestructureTokens(ctx, params.as!(ParamsAst.Varargs*).param);
		});
}

void addTypeTokens(scope ref Ctx ctx, in TypeAst a) {
	a.matchIn!void(
		(in TypeAst.Bogus) {},
		(in TypeAst.Fun x) {
			keyword(ctx.tokens, x.range.start, "fun");
			foreach (TypeAst t; x.returnAndParamTypes)
				addTypeTokens(ctx, t);
		},
		(in TypeAst.Map x) {
			addTypeTokens(ctx, x.v);
			addTypeTokens(ctx, x.k);
		},
		(in NameAndRange x) {
			reference(ctx.tokens, TokenType.type, rangeOfNameAndRange(x, ctx.allSymbols));
		},
		(in TypeAst.SuffixName x) {
			addTypeTokens(ctx, x.left);
			reference(ctx.tokens, TokenType.type, rangeOfNameAndRange(x.name, ctx.allSymbols));
		},
		(in TypeAst.SuffixSpecial x) {
			addTypeTokens(ctx, x.left);
			declare(ctx.tokens, TokenType.type, suffixRange(x));
		},
		(in TypeAst.Tuple x) {
			foreach (TypeAst t; x.members)
				addTypeTokens(ctx, t);
		});
}

void addTypeParamsTokens(scope ref Ctx ctx, in NameAndRange[] a) {
	foreach (NameAndRange typeParam; a)
		declare(ctx.tokens, TokenType.typeParameter, rangeOfNameAndRange(typeParam, ctx.allSymbols));
}

void addStructAliasTokens(scope ref Ctx ctx, in StructAliasAst a) {
	declare(ctx.tokens, TokenType.type, rangeOfNameAndRange(a.name, ctx.allSymbols));
	addTypeParamsTokens(ctx, a.typeParams);
	addTypeTokens(ctx, a.target);
}

void addStructTokens(scope ref Ctx ctx, in StructDeclAst a) {
	declare(ctx.tokens, TokenType.type, rangeOfNameAndRange(a.name, ctx.allSymbols));
	addTypeParamsTokens(ctx, a.typeParams);
	a.body_.matchIn!void(
		(in StructBodyAst.Builtin) {
			addModifierTokens(ctx, a);
		},
		(in StructBodyAst.Enum x) {
			addEnumOrFlagsTokens(ctx, a, x.typeArg, x.members);
		},
		(in StructBodyAst.Extern) {
			addModifierTokens(ctx, a);
		},
		(in StructBodyAst.Flags x) {
			addEnumOrFlagsTokens(ctx, a, x.typeArg, x.members);
		},
		(in StructBodyAst.Record record) {
			addModifierTokens(ctx, a);
			foreach (ref StructBodyAst.Record.Field field; record.fields) {
				declare(ctx.tokens, TokenType.property, rangeOfNameAndRange(field.name, ctx.allSymbols));
				addTypeTokens(ctx, field.type);
			}
		},
		(in StructBodyAst.Union union_) {
			addModifierTokens(ctx, a);
			foreach (ref StructBodyAst.Union.Member member; union_.members) {
				declare(ctx.tokens, TokenType.enumMember, rangeAtName(ctx.allSymbols, member.range.start, member.name));
				if (has(member.type))
					addTypeTokens(ctx, force(member.type));
			}
		});
}

void addModifierTokens(scope ref Ctx ctx, in StructDeclAst a) {
	foreach (ref ModifierAst x; a.modifiers)
		keyword(ctx.tokens, rangeOfModifierAst(x, ctx.allSymbols));
}
void addFunModifierTokens(scope ref Ctx ctx, in FunModifierAst[] a) {
	foreach (ref FunModifierAst mod; a) {
		mod.matchIn!void(
			(in FunModifierAst.Special x) {
				keyword(ctx.tokens, x.range);
			},
			(in FunModifierAst.Extern x) {
				addTypeTokens(ctx, *x.left);
				keyword(ctx.tokens, x.suffixRange);
			},
			(in TypeAst x) {
				if (x.isA!NameAndRange)
					reference(ctx.tokens, TokenType.interface_, x.range(ctx.allSymbols));
				else if (x.isA!(TypeAst.SuffixName*)) {
					TypeAst.SuffixName* n = x.as!(TypeAst.SuffixName*);
					addTypeTokens(ctx, n.left);
					reference(ctx.tokens, TokenType.interface_, rangeOfNameAndRange(n.name, ctx.allSymbols));
				}
				// else parse error, so ignore
			});
	}
}

void addEnumOrFlagsTokens(
	scope ref Ctx ctx,
	in StructDeclAst a,
	in Opt!(TypeAst*) typeArg,
	in StructBodyAst.Enum.Member[] members,
) {
	if (has(typeArg))
		addTypeTokens(ctx, *force(typeArg));
	addModifierTokens(ctx, a);
	foreach (ref StructBodyAst.Enum.Member member; members) {
		declare(ctx.tokens, TokenType.enumMember, member.nameRange(ctx.allSymbols));
		if (has(member.value))
			numberLiteral(ctx.tokens, force(member.value).range);
	}
}

void addVarDeclTokens(scope ref Ctx ctx, in VarDeclAst a) {
	declare(ctx.tokens, TokenType.variable, rangeOfNameAndRange(a.name, ctx.allSymbols));
	addTypeParamsTokens(ctx, a.typeParams);
	addTypeTokens(ctx, a.type);
	addFunModifierTokens(ctx, a.modifiers);
}

void addFunTokens(scope ref Ctx ctx, in FunDeclAst a) {
	declare(ctx.tokens, TokenType.function_, rangeOfNameAndRange(a.name, ctx.allSymbols));
	addTypeParamsTokens(ctx, a.typeParams);
	addSigReturnTypeAndParamsTokens(ctx, a.returnType, a.params);
	addFunModifierTokens(ctx, a.modifiers);
	addExprTokens(ctx, a.body_);
}

void addTestTokens(scope ref Ctx ctx, in TestAst a) {
	addExprTokens(ctx, a.body_);
}

void addExprTokens(scope ref Ctx ctx, in ExprAst a) {
	a.kind.matchIn!void(
		(in ArrowAccessAst x) {
			addExprTokens(ctx, *x.left);
			reference(ctx.tokens, TokenType.function_, rangeOfNameAndRange(x.name, ctx.allSymbols));
		},
		(in AssertOrForbidAst x) {
			// Only the length matters, and "assert" is same length as "forbid"
			keyword(ctx.tokens, a.range.start, "assert");
			addExprTokens(ctx, x.condition);
			if (has(x.thrown))
				addExprTokens(ctx, force(x.thrown));
		},
		(in AssignmentAst x) {
			addExprTokens(ctx, x.left);
			keyword(ctx.tokens, x.assignmentPos, ":=");
			addExprTokens(ctx, x.right);
		},
		(in AssignmentCallAst x) {
			addExprTokens(ctx, x.left);
			reference(ctx.tokens, TokenType.function_, rangeOfNameAndRange(x.funName, ctx.allSymbols));
			addExprTokens(ctx, x.right);
		},
		(in BogusAst _) {},
		(in CallAst x) {
			void addName() {
				reference(ctx.tokens, TokenType.function_, rangeOfNameAndRange(x.funName, ctx.allSymbols));
				if (has(x.typeArg))
					addTypeTokens(ctx, *force(x.typeArg));
			}
			final switch (x.style) {
				case CallAst.Style.dot:
				case CallAst.Style.infix:
					addExprTokens(ctx, x.args[0]);
					addName();
					addExprsTokens(ctx, x.args[1 .. $]);
					break;
				case CallAst.Style.prefixBang:
					reference(ctx.tokens, TokenType.function_, rangeOfStartAndLength(x.funName.start, 1));
					addExprTokens(ctx, x.args[0]);
					break;
				case CallAst.Style.suffixBang:
					addExprTokens(ctx, x.args[0]);
					reference(ctx.tokens, TokenType.function_, rangeOfStartAndLength(x.funName.start, 1));
					break;
				case CallAst.style.emptyParens:
					break;
				case CallAst.style.prefixOperator:
				case CallAst.Style.single:
					addName();
					addExprsTokens(ctx, x.args);
					break;
				case CallAst.Style.comma:
				case CallAst.Style.subscript:
					addExprsTokens(ctx, x.args);
					break;
			}
		},
		(in EmptyAst x) {},
		(in ForAst x) {
			keyword(ctx.tokens, a.range.start, "for");
			addDestructureTokens(ctx, x.param);
			addExprTokens(ctx, x.collection);
			addExprTokens(ctx, x.body_);
			addExprTokens(ctx, x.else_);
		},
		(in IdentifierAst _) {
			reference(ctx.tokens, TokenType.variable, a.range);
		},
		(in IfAst x) {
			addExprTokens(ctx, x.cond);
			addExprTokens(ctx, x.then);
			addExprTokens(ctx, x.else_);
		},
		(in IfOptionAst x) {
			addDestructureTokens(ctx, x.destructure);
			addExprTokens(ctx, x.option);
			addExprTokens(ctx, x.then);
			addExprTokens(ctx, x.else_);
		},
		(in InterpolatedAst x) {
			Pos pos = a.range.start;
			if (!isEmpty(x.parts)) {
				// Ensure opening quote is highlighted
				x.parts[0].matchIn!void(
					(in string) {},
					(in ExprAst _) {
						stringLiteral(ctx.tokens, Range(pos, pos + 1));
					});
				foreach (size_t i, ref InterpolatedPart part; x.parts)
					part.matchIn!void(
						(in string s) {
							// TODO: length may be wrong if there are escapes
							// Ensure the closing quote is highlighted
							Pos end = safeToUint(pos + s.length) + (i == x.parts.length - 1 ? 1 : 0);
							stringLiteral(ctx.tokens, Range(pos, end));
						},
						(in ExprAst e) {
							addExprTokens(ctx, e);
							pos = safeToUint(e.range.end + 1);
						});
				// Ensure closing quote is highlighted
				x.parts[$ - 1].matchIn!void(
					(in string) {},
					(in ExprAst _) {
						stringLiteral(ctx.tokens, a.range[$ - 1 .. $]);
					});
			}
		},
		(in LambdaAst x) {
			addDestructureTokens(ctx, x.param);
			addExprTokens(ctx, x.body_);
		},
		(in LetAst x) {
			addDestructureTokens(ctx, x.destructure);
			addExprTokens(ctx, x.value);
			addExprTokens(ctx, x.then);
		},
		(in LiteralFloatAst _) {
			numberLiteral(ctx.tokens, a.range);
		},
		(in LiteralIntAst _) {
			numberLiteral(ctx.tokens, a.range);
		},
		(in LiteralNatAst _) {
			numberLiteral(ctx.tokens, a.range);
		},
		(in LiteralStringAst _) {
			stringLiteral(ctx.tokens, a.range);
		},
		(in LoopAst x) {
			keyword(ctx.tokens, a.range.start, "loop");
			addExprTokens(ctx, x.body_);
		},
		(in LoopBreakAst x) {
			keyword(ctx.tokens, a.range.start, "break");
			addExprTokens(ctx, x.value);
		},
		(in LoopContinueAst _) {
			keyword(ctx.tokens, a.range.start, "continue");
		},
		(in LoopUntilAst x) {
			keyword(ctx.tokens, a.range.start, "until");
			addExprTokens(ctx, x.condition);
			addExprTokens(ctx, x.body_);
		},
		(in LoopWhileAst x) {
			keyword(ctx.tokens, a.range.start, "while");
			addExprTokens(ctx, x.condition);
			addExprTokens(ctx, x.body_);
		},
		(in MatchAst x) {
			addExprTokens(ctx, x.matched);
			foreach (ref MatchAst.CaseAst case_; x.cases) {
				reference(ctx.tokens, TokenType.enumMember, case_.memberNameRange(ctx.allSymbols));
				if (has(case_.destructure))
					addDestructureTokens(ctx, force(case_.destructure));
				addExprTokens(ctx, case_.then);
			}
		},
		(in ParenthesizedAst x) {
			addExprTokens(ctx, x.inner);
		},
		(in PtrAst x) {
			addExprTokens(ctx, x.inner);
		},
		(in SeqAst x) {
			addExprTokens(ctx, x.first);
			addExprTokens( ctx, x.then);
		},
		(in ThenAst x) {
			addDestructureTokens(ctx, x.left);
			addExprTokens(ctx, x.futExpr);
			addExprTokens(ctx, x.then);
		},
		(in ThrowAst x) {
			keyword(ctx.tokens, a.range.start, "throw");
			addExprTokens(ctx, x.thrown);
		},
		(in TrustedAst x) {
			keyword(ctx.tokens, a.range.start, "trusted");
			addExprTokens(ctx, x.inner);
		},
		(in TypedAst x) {
			addExprTokens(ctx, x.expr);
			addTypeTokens(ctx, x.type);
		},
		(in UnlessAst x) {
			addExprTokens(ctx, x.cond);
			addExprTokens(ctx, x.body_);
		},
		(in WithAst x) {
			keyword(ctx.tokens, a.range.start, "with");
			addDestructureTokens(ctx, x.param);
			addExprTokens(ctx, x.arg);
			addExprTokens(ctx, x.body_);
		});
}

void addDestructureTokens(scope ref Ctx ctx, in DestructureAst a) {
	a.matchIn!void(
		(in DestructureAst.Single x) {
			declare(
				ctx.tokens,
				x.name.name == symbol!"_" ? TokenType.comment : TokenType.parameter,
				rangeOfNameAndRange(x.name, ctx.allSymbols));
			//TODO: add 'mut' keyword
			if (has(x.type))
				addTypeTokens(ctx, *force(x.type));
		},
		(in DestructureAst.Void x) {
			keyword(ctx.tokens, a.range(ctx.allSymbols));
		},
		(in DestructureAst[] xs) {
			foreach (ref DestructureAst x; xs)
				addDestructureTokens(ctx, x);
		});
}

void addExprsTokens(scope ref Ctx ctx, in ExprAst[] exprs) {
	foreach (ref ExprAst expr; exprs)
		addExprTokens(ctx, expr);
}
