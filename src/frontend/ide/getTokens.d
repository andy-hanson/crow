module frontend.ide.getTokens;

@safe @nogc pure nothrow:

import frontend.parse.ast :
	ArrowAccessAst,
	AssertOrForbidAst,
	AssignmentAst,
	AssignmentCallAst,
	BogusAst,
	CallAst,
	DestructureAst,
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
	WithAst;
import model.model : Visibility;
import util.alloc.alloc : Alloc;
import util.col.arr : empty;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.col.sortUtil : eachSorted, findUnsortedPair, UnsortedPair;
import util.comparison : compareNat32, Comparison;
import util.conv : safeToUint;
import util.opt : force, has, Opt;
import util.repr : Repr, nameAndRepr, reprArr, reprNamedRecord, reprSym;
import util.sourceRange : Pos, rangeOfStartAndLength, rangeOfStartAndName, RangeWithinFile, reprRangeWithinFile;
import util.sym : AllSymbols, Sym, sym, symSize;
import util.util : todo;

immutable struct Token {
	enum Kind {
		fun,
		identifier,
		importPath,
		keyword,
		local,
		literalNumber,
		literalString,
		member, // record / union / enum / flags member
		modifier,
		param,
		spec,
		struct_,
		typeParam,
	}
	Kind kind;
	RangeWithinFile range;
}

Repr reprTokens(ref Alloc alloc, scope Token[] tokens) =>
	reprArr!Token(alloc, tokens, (in Token it) =>
		reprToken(alloc, it));

Token[] tokensOfAst(ref Alloc alloc, ref AllSymbols allSymbols, in FileAst ast) {
	TokensBuilder tokens;

	addImportTokens(alloc, tokens, allSymbols, ast.imports, sym!"import");
	addImportTokens(alloc, tokens, allSymbols, ast.exports, sym!"export");

	//TODO: also tests...
	eachSorted!(RangeWithinFile, SpecDeclAst, StructAliasAst, StructDeclAst, FunDeclAst)(
		RangeWithinFile.max,
		(in RangeWithinFile a, in RangeWithinFile b) =>
			compareRangeWithinFile(a, b),
		ast.specs, (in SpecDeclAst it) => it.range, (in SpecDeclAst it) {
			addSpecTokens(alloc, tokens, allSymbols, it);
		},
		ast.structAliases, (in StructAliasAst it) => it.range, (in StructAliasAst it) {
			addStructAliasTokens(alloc, tokens, allSymbols, it);
		},
		ast.structs, (in StructDeclAst it) => it.range, (in StructDeclAst it) {
			addStructTokens(alloc, tokens, allSymbols, it);
		},
		ast.funs, (in FunDeclAst it) => it.range, (in FunDeclAst it) {
			addFunTokens(alloc, tokens, allSymbols, it);
		});
	Token[] res = finishArr(alloc, tokens);
	assertTokensSorted(res);
	return res;
}

private:

alias TokensBuilder = ArrBuilder!Token;

RangeWithinFile rangeAtName(in AllSymbols allSymbols, Visibility visibility, Pos start, Sym name) {
	uint offset = () {
		final switch (visibility) {
			case Visibility.private_:
			case Visibility.public_:
				return 1;
			case Visibility.internal:
				return 0;
		}
	}();
	return rangeAtName(allSymbols, start + offset, name);
}

RangeWithinFile rangeAtName(in AllSymbols allSymbols, Pos start, Sym name) =>
	RangeWithinFile(start, start + symSize(allSymbols, name));

void addImportTokens(
	ref Alloc alloc,
	ref TokensBuilder tokens,
	in AllSymbols allSymbols,
	in Opt!ImportsOrExportsAst a,
	Sym keyword,
) {
	if (has(a)) {
		add(alloc, tokens, Token(Token.Kind.keyword, rangeAtName(allSymbols, force(a).range.start, keyword)));
		foreach (ref ImportOrExportAst path; force(a).paths)
			add(alloc, tokens, Token(Token.Kind.importPath, path.range));
	}
}

void addSpecTokens(ref Alloc alloc, ref TokensBuilder tokens, in AllSymbols allSymbols, in SpecDeclAst a) {
	add(alloc, tokens, Token(Token.Kind.spec, rangeAtName(allSymbols, a.visibility, a.range.start, a.name)));
	addTypeParamsTokens(alloc, tokens, allSymbols, a.typeParams);
	a.body_.matchIn!void(
		(in SpecBodyAst.Builtin) {},
		(in SpecSigAst[] sigs) {
			foreach (ref SpecSigAst sig; sigs) {
				add(alloc, tokens, Token(Token.Kind.fun, rangeAtName(allSymbols, sig.range.start, sig.name)));
				addSigReturnTypeAndParamsTokens(alloc, tokens, allSymbols, sig.returnType, sig.params);
			}
		});
}

// LDC compilation is slow without this pragma.
// Might be https://github.com/ldc-developers/ldc/issues/3879
pragma(inline, false)
void addSigReturnTypeAndParamsTokens(
	ref Alloc alloc,
	ref TokensBuilder tokens,
	in AllSymbols allSymbols,
	in TypeAst returnType,
	in ParamsAst params,
) {
	addTypeTokens(alloc, tokens, allSymbols, returnType);
	params.matchIn!void(
		(in DestructureAst[] regular) {
			foreach (ref DestructureAst param; regular)
				addDestructureTokens(alloc, tokens, allSymbols, param);
		},
		(in ParamsAst.Varargs) {
			addDestructureTokens(alloc, tokens, allSymbols, params.as!(ParamsAst.Varargs*).param);
		});
}

void addTypeTokens(ref Alloc alloc, ref TokensBuilder tokens, in AllSymbols allSymbols, in TypeAst a) {
	a.matchIn!void(
		(in TypeAst.Bogus) {},
		(in TypeAst.Dict it) {
			addTypeTokens(alloc, tokens, allSymbols, it.v);
			add(alloc, tokens, Token(
				Token.Kind.keyword,
				RangeWithinFile(range(it.v, allSymbols).end, range(it.k, allSymbols).start)));
			addTypeTokens(alloc, tokens, allSymbols, it.k);
			add(alloc, tokens, Token(
				Token.Kind.keyword,
				rangeOfStartAndLength(range(it.k, allSymbols).end, "]".length)));
		},
		(in TypeAst.Fun it) {
			add(alloc, tokens, Token(
				Token.Kind.keyword,
				rangeOfStartAndName(it.range.start, sym!"fun", allSymbols)));
			foreach (TypeAst t; it.returnAndParamTypes)
				addTypeTokens(alloc, tokens, allSymbols, t);
		},
		(in NameAndRange x) {
			add(alloc, tokens, Token(Token.Kind.struct_, rangeOfNameAndRange(x, allSymbols)));
		},
		(in TypeAst.SuffixName x) {
			addTypeTokens(alloc, tokens, allSymbols, x.left);
			add(alloc, tokens, Token(Token.Kind.struct_, rangeOfNameAndRange(x.name, allSymbols)));
		},
		(in TypeAst.SuffixSpecial it) {
			addTypeTokens(alloc, tokens, allSymbols, it.left);
			add(alloc, tokens, Token(Token.Kind.keyword, suffixRange(it)));
		},
		(in TypeAst.Tuple it) {
			foreach (TypeAst t; it.members)
				addTypeTokens(alloc, tokens, allSymbols, t);
		});
}

void addTypeParamsTokens(ref Alloc alloc, ref TokensBuilder tokens, in AllSymbols allSymbols, in NameAndRange[] a) {
	foreach (NameAndRange typeParam; a)
		add(alloc, tokens, Token(Token.Kind.typeParam, rangeOfNameAndRange(typeParam, allSymbols)));
}

void addStructAliasTokens(ref Alloc alloc, ref TokensBuilder tokens, in AllSymbols allSymbols, in StructAliasAst a) {
	add(alloc, tokens, Token(Token.Kind.struct_, rangeAtName(allSymbols, a.visibility, a.range.start, a.name)));
	addTypeParamsTokens(alloc, tokens, allSymbols, a.typeParams);
	addTypeTokens(alloc, tokens, allSymbols, a.target);
}

void addStructTokens(ref Alloc alloc, ref TokensBuilder tokens, in AllSymbols allSymbols, in StructDeclAst a) {
	add(alloc, tokens, Token(Token.Kind.struct_, rangeAtName(allSymbols, a.visibility, a.range.start, a.name)));
	addTypeParamsTokens(alloc, tokens, allSymbols, a.typeParams);
	a.body_.matchIn!void(
		(in StructDeclAst.Body.Builtin) {
			addModifierTokens(alloc, tokens, allSymbols, a);
		},
		(in StructDeclAst.Body.Enum it) {
			addEnumOrFlagsTokens(alloc, tokens, allSymbols, a, it.typeArg, it.members);
		},
		(in StructDeclAst.Body.Extern) {
			addModifierTokens(alloc, tokens, allSymbols, a);
		},
		(in StructDeclAst.Body.Flags it) {
			addEnumOrFlagsTokens(alloc, tokens, allSymbols, a, it.typeArg, it.members);
		},
		(in StructDeclAst.Body.Record record) {
			addModifierTokens(alloc, tokens, allSymbols, a);
			foreach (ref StructDeclAst.Body.Record.Field field; record.fields) {
				add(alloc, tokens, Token(Token.Kind.member, rangeAtName(allSymbols, field.range.start, field.name)));
				addTypeTokens(alloc, tokens, allSymbols, field.type);
			}
		},
		(in StructDeclAst.Body.Union union_) {
			addModifierTokens(alloc, tokens, allSymbols, a);
			foreach (ref StructDeclAst.Body.Union.Member member; union_.members) {
				add(alloc, tokens, Token(Token.Kind.member, rangeAtName(allSymbols, member.range.start, member.name)));
				if (has(member.type))
					addTypeTokens(alloc, tokens, allSymbols, force(member.type));
			}
		});
}

void addModifierTokens(ref Alloc alloc, ref TokensBuilder tokens, in AllSymbols allSymbols, in StructDeclAst a) {
	foreach (ref ModifierAst modifier; a.modifiers)
		add(alloc, tokens, Token(Token.Kind.modifier, rangeOfModifierAst(modifier, allSymbols)));
}

void addEnumOrFlagsTokens(
	ref Alloc alloc,
	ref TokensBuilder tokens,
	in AllSymbols allSymbols,
	in StructDeclAst a,
	in Opt!(TypeAst*) typeArg,
	in StructDeclAst.Body.Enum.Member[] members,
) {
	if (has(typeArg))
		addTypeTokens(alloc, tokens, allSymbols, *force(typeArg));
	addModifierTokens(alloc, tokens, allSymbols, a);
	foreach (ref StructDeclAst.Body.Enum.Member member; members) {
		add(alloc, tokens, Token(Token.Kind.member, member.range));
		if (has(member.value)) {
			uint addLen = " = ".length;
			Pos pos = member.range.start + symSize(allSymbols, member.name) + addLen;
			add(alloc, tokens, Token(Token.Kind.literalNumber, RangeWithinFile(pos, member.range.end)));
		}
	}
}

void addFunTokens(ref Alloc alloc, ref TokensBuilder tokens, ref AllSymbols allSymbols, in FunDeclAst a) {
	add(alloc, tokens, Token(
		Token.Kind.fun,
		rangeAtName(allSymbols, a.visibility, a.range.start, a.name)));
	addTypeParamsTokens(alloc, tokens, allSymbols, a.typeParams);
	addSigReturnTypeAndParamsTokens(alloc, tokens, allSymbols, a.returnType, a.params);
	foreach (ref FunModifierAst modifier; a.modifiers) {
		modifier.matchIn!void(
			(in FunModifierAst.Special x) {
				add(alloc, tokens, Token(Token.Kind.modifier, x.range(allSymbols)));
			},
			(in FunModifierAst.ExternOrGlobal x) @safe {
				addTypeTokens(alloc, tokens, allSymbols, *x.left);
				add(alloc, tokens, Token(Token.Kind.modifier, x.suffixRange(allSymbols)));
			},
			(in TypeAst x) {
				if (x.isA!NameAndRange)
					add(alloc, tokens, Token(Token.Kind.spec, x.range(allSymbols)));
				else if (x.isA!(TypeAst.SuffixName*)) {
					TypeAst.SuffixName* n = x.as!(TypeAst.SuffixName*);
					addTypeTokens(alloc, tokens, allSymbols, n.left);
					add(alloc, tokens, Token(Token.Kind.spec, rangeOfNameAndRange(n.name, allSymbols)));
				}
				// else parse error, so ignore
			});
	}
	if (has(a.body_))
		addExprTokens(alloc, tokens, allSymbols, force(a.body_));
}

void addExprTokens(ref Alloc alloc, ref TokensBuilder tokens, ref AllSymbols allSymbols, in ExprAst a) {
	a.kind.matchIn!void(
		(in ArrowAccessAst it) {
			addExprTokens(alloc, tokens, allSymbols, it.left);
			add(alloc, tokens, Token(Token.Kind.fun, rangeOfNameAndRange(it.name, allSymbols)));
		},
		(in AssertOrForbidAst it) {
			add(alloc, tokens, Token(
				Token.Kind.keyword,
				// Only the length matters, and "assert" is same length as "forbid"
				rangeOfNameAndRange(NameAndRange(a.range.start, sym!"assert"), allSymbols)));
		},
		(in AssignmentAst x) {
			addExprTokens(alloc, tokens, allSymbols, x.left);
			add(alloc, tokens, Token(Token.Kind.keyword, rangeOfStartAndLength(x.assignmentPos, ":=".length)));
			addExprTokens(alloc, tokens, allSymbols, x.right);
		},
		(in AssignmentCallAst x) {
			addExprTokens(alloc, tokens, allSymbols, x.left);
			add(alloc, tokens, Token(Token.Kind.fun, rangeOfNameAndRange(x.funName, allSymbols)));
			addExprTokens(alloc, tokens, allSymbols, x.right);
		},
		(in BogusAst _) {},
		(in CallAst it) {
			void addName() {
				add(alloc, tokens, Token(Token.Kind.fun, rangeOfNameAndRange(it.funName, allSymbols)));
				if (has(it.typeArg))
					addTypeTokens(alloc, tokens, allSymbols, *force(it.typeArg));
			}
			final switch (it.style) {
				case CallAst.Style.dot:
				case CallAst.Style.infix:
					addExprTokens(alloc, tokens, allSymbols, it.args[0]);
					addName();
					addExprsTokens(alloc, tokens, allSymbols, it.args[1 .. $]);
					break;
				case CallAst.Style.prefixBang:
					add(alloc, tokens, Token(Token.Kind.fun, rangeOfStartAndLength(it.funName.start, 1)));
					addExprTokens(alloc, tokens, allSymbols, it.args[0]);
					break;
				case CallAst.Style.suffixBang:
					addExprTokens(alloc, tokens, allSymbols, it.args[0]);
					add(alloc, tokens, Token(Token.Kind.fun, rangeOfStartAndLength(it.funName.start, 1)));
					break;
				case CallAst.style.emptyParens:
					break;
				case CallAst.style.prefixOperator:
				case CallAst.Style.prefix:
				case CallAst.Style.single:
					addName();
					addExprsTokens(alloc, tokens, allSymbols, it.args);
					break;
				case CallAst.Style.comma:
				case CallAst.Style.subscript:
					addExprsTokens(alloc, tokens, allSymbols, it.args);
					break;
			}
		},
		(in ForAst x) {
			add(alloc, tokens, Token(Token.Kind.keyword, rangeOfStartAndLength(a.range.start, "for".length)));
			addDestructureTokens(alloc, tokens, allSymbols, x.param);
			addExprTokens(alloc, tokens, allSymbols, x.collection);
			addExprTokens(alloc, tokens, allSymbols, x.body_);
			if (has(x.else_))
				addExprTokens(alloc, tokens, allSymbols, force(x.else_));
		},
		(in IdentifierAst _) {
			add(alloc, tokens, Token(Token.Kind.identifier, a.range));
		},
		(in IfAst it) {
			addExprTokens(alloc, tokens, allSymbols, it.cond);
			addExprTokens(alloc, tokens, allSymbols, it.then);
			if (has(it.else_))
				addExprTokens(alloc, tokens, allSymbols, force(it.else_));
		},
		(in IfOptionAst it) {
			addDestructureTokens(alloc, tokens, allSymbols, it.destructure);
			addExprTokens(alloc, tokens, allSymbols, it.option);
			addExprTokens(alloc, tokens, allSymbols, it.then);
			if (has(it.else_))
				addExprTokens(alloc, tokens, allSymbols, force(it.else_));
		},
		(in InterpolatedAst it) {
			Pos pos = a.range.start;
			if (!empty(it.parts)) {
				// Ensure opening quote is highlighted
				it.parts[0].matchIn!void(
					(in string) {},
					(in ExprAst _) {
						add(alloc, tokens, Token(Token.Kind.literalString, RangeWithinFile(pos, pos + 1)));
					});
				foreach (size_t i, ref InterpolatedPart part; it.parts)
					part.matchIn!void(
						(in string s) {
							// TODO: length may be wrong if there are escapes
							// Ensure the closing quote is highlighted
							Pos end = safeToUint(pos + s.length) + (i == it.parts.length - 1 ? 1 : 0);
							add(alloc, tokens, Token(Token.Kind.literalString, RangeWithinFile(pos, end)));
						},
						(in ExprAst e) {
							addExprTokens(alloc, tokens, allSymbols, e);
							pos = safeToUint(e.range.end + 1);
						});
				// Ensure closing quote is highlighted
				it.parts[$ - 1].matchIn!void(
					(in string) {},
					(in ExprAst _) {
						add(alloc, tokens, Token(
							Token.Kind.literalString,
							RangeWithinFile(a.range.end - 1, a.range.end)));
					});
			}
		},
		(in LambdaAst it) {
			addDestructureTokens(alloc, tokens, allSymbols, it.param);
			addExprTokens(alloc, tokens, allSymbols, it.body_);
		},
		(in LetAst x) {
			addDestructureTokens(alloc, tokens, allSymbols, x.destructure);
			addExprTokens(alloc, tokens, allSymbols, x.initializer);
			addExprTokens(alloc, tokens, allSymbols, x.then);
		},
		(in LiteralFloatAst _) {
			add(alloc, tokens, Token(Token.Kind.literalNumber, a.range));
		},
		(in LiteralIntAst _) {
			add(alloc, tokens, Token(Token.Kind.literalNumber, a.range));
		},
		(in LiteralNatAst _) {
			add(alloc, tokens, Token(Token.Kind.literalNumber, a.range));
		},
		(in LiteralStringAst _) {
			add(alloc, tokens, Token(Token.Kind.literalString, a.range));
		},
		(in LoopAst x) {
			add(alloc, tokens, Token(
				Token.Kind.keyword,
				rangeOfStartAndLength(a.range.start, "loop".length)));
			addExprTokens(alloc, tokens, allSymbols, x.body_);
		},
		(in LoopBreakAst it) {
			add(alloc, tokens, Token(Token.Kind.keyword, rangeOfStartAndLength(a.range.start, "break".length)));
			if (has(it.value))
				addExprTokens(alloc, tokens, allSymbols, force(it.value));
		},
		(in LoopContinueAst _) {
			add(alloc, tokens, Token(Token.Kind.keyword, rangeOfStartAndLength(a.range.start, "continue".length)));
		},
		(in LoopUntilAst it) {
			add(alloc, tokens, Token(Token.Kind.keyword, rangeOfStartAndLength(a.range.start, "until".length)));
			addExprTokens(alloc, tokens, allSymbols, it.condition);
			addExprTokens(alloc, tokens, allSymbols, it.body_);
		},
		(in LoopWhileAst it) {
			add(alloc, tokens, Token(Token.Kind.keyword, rangeOfStartAndLength(a.range.start, "while".length)));
			addExprTokens(alloc, tokens, allSymbols, it.condition);
			addExprTokens(alloc, tokens, allSymbols, it.body_);
		},
		(in MatchAst it) {
			addExprTokens(alloc, tokens, allSymbols, it.matched);
			foreach (ref MatchAst.CaseAst case_; it.cases) {
				add(alloc, tokens, Token(Token.Kind.struct_, case_.memberNameRange(allSymbols)));
				if (has(case_.destructure))
					addDestructureTokens(alloc, tokens, allSymbols, force(case_.destructure));
				addExprTokens(alloc, tokens, allSymbols, case_.then);
			}
		},
		(in ParenthesizedAst it) {
			addExprTokens(alloc, tokens, allSymbols, it.inner);
		},
		(in PtrAst x) {
			addExprTokens(alloc, tokens, allSymbols, x.inner);
		},
		(in SeqAst it) {
			addExprTokens(alloc, tokens, allSymbols, it.first);
			addExprTokens(alloc, tokens, allSymbols, it.then);
		},
		(in ThenAst x) {
			addDestructureTokens(alloc, tokens, allSymbols, x.left);
			addExprTokens(alloc, tokens, allSymbols, x.futExpr);
			addExprTokens(alloc, tokens, allSymbols, x.then);
		},
		(in ThrowAst it) {
			add(alloc, tokens, Token(Token.Kind.keyword, rangeOfStartAndLength(a.range.start, "throw".length)));
			addExprTokens(alloc, tokens, allSymbols, it.thrown);
		},
		(in TrustedAst it) {
			add(alloc, tokens, Token(Token.Kind.keyword, rangeOfStartAndLength(a.range.start, "trusted".length)));
			addExprTokens(alloc, tokens, allSymbols, it.inner);
		},
		(in TypedAst it) {
			addExprTokens(alloc, tokens, allSymbols, it.expr);
			addTypeTokens(alloc, tokens, allSymbols, it.type);
		},
		(in UnlessAst it) {
			addExprTokens(alloc, tokens, allSymbols, it.cond);
			addExprTokens(alloc, tokens, allSymbols, it.body_);
		},
		(in WithAst x) {
			add(alloc, tokens, Token(Token.Kind.keyword, rangeOfStartAndLength(a.range.start, "with".length)));
			addDestructureTokens(alloc, tokens, allSymbols, x.param);
			addExprTokens(alloc, tokens, allSymbols, x.arg);
			addExprTokens(alloc, tokens, allSymbols, x.body_);
		});
}

void addDestructureTokens(ref Alloc alloc, ref TokensBuilder tokens, in AllSymbols allSymbols, in DestructureAst a) {
	a.matchIn!void(
		(in DestructureAst.Single x) {
			add(alloc, tokens, Token(
				x.name.name == sym!"_" ? Token.Kind.keyword : Token.Kind.param,
				rangeOfNameAndRange(x.name, allSymbols)));
			//TODO: add 'mut' keyword
			if (has(x.type))
				addTypeTokens(alloc, tokens, allSymbols, *force(x.type));
		},
		(in DestructureAst.Void x) {
			add(alloc, tokens, Token(Token.Kind.keyword, a.range(allSymbols)));
		},
		(in DestructureAst[] xs) {
			foreach (ref DestructureAst x; xs)
				addDestructureTokens(alloc, tokens, allSymbols, x);
		});
}

void addExprsTokens(ref Alloc alloc, ref TokensBuilder tokens, ref AllSymbols allSymbols, in ExprAst[] exprs) {
	foreach (ref ExprAst expr; exprs)
		addExprTokens(alloc, tokens, allSymbols, expr);
}

void assertTokensSorted(Token[] tokens) {
	Opt!UnsortedPair pair = findUnsortedPair!Token(tokens, (in Token a, in Token b) =>
		compareRangeWithinFile(a.range, b.range));
	if (has(pair))
		// To debug, just disable this assertion and look for the unsorted token in the output
		todo!void("tokens not sorted!");
}

Comparison compareRangeWithinFile(RangeWithinFile a, RangeWithinFile b) =>
	compareNat32(a.start, b.start);

Sym symOfTokenKind(Token.Kind kind) {
	final switch (kind) {
		case Token.Kind.fun:
			return sym!"fun";
		case Token.Kind.identifier:
			return sym!"identifier";
		case Token.Kind.importPath:
			return sym!"import";
		case Token.Kind.keyword:
			return sym!"keyword";
		case Token.Kind.literalNumber:
			return sym!"lit-num";
		case Token.Kind.literalString:
			return sym!"lit-str";
		case Token.Kind.local:
			return sym!"local";
		case Token.Kind.member:
			return sym!"member";
		case Token.Kind.modifier:
			return sym!"modifier";
		case Token.Kind.param:
			return sym!"param";
		case Token.Kind.spec:
			return sym!"spec";
		case Token.Kind.struct_:
			return sym!"struct";
		case Token.Kind.typeParam:
			return sym!"type-param";
	}
}

Repr reprToken(ref Alloc alloc, Token token) =>
	reprNamedRecord!"token"(alloc, [
		nameAndRepr!"kind"(reprSym(symOfTokenKind(token.kind))),
		nameAndRepr!"range"(reprRangeWithinFile(alloc, token.range))]);
