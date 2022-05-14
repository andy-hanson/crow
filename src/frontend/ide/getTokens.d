module frontend.ide.getTokens;

@safe @nogc pure nothrow:

import frontend.parse.ast :
	ArrowAccessAst,
	BogusAst,
	CallAst,
	ExprAst,
	FileAst,
	ForAst,
	FunBodyAst,
	FunDeclAst,
	FunPtrAst,
	IdentifierAst,
	IdentifierSetAst,
	IfAst,
	IfOptionAst,
	ImportOrExportAst,
	ImportsOrExportsAst,
	InterpolatedAst,
	InterpolatedPart,
	LambdaAst,
	LetAst,
	LiteralAst,
	LoopAst,
	LoopBreakAst,
	LoopContinueAst,
	LoopUntilAst,
	LoopWhileAst,
	MatchAst,
	matchExprAstKind,
	matchFunBodyAst,
	matchInterpolatedPart,
	matchLiteralAst,
	matchNameOrUnderscoreOrNone,
	matchParamsAst,
	matchSpecBodyAst,
	matchStructDeclAstBody,
	matchTypeAst,
	ModifierAst,
	NameAndRange,
	NameOrUnderscoreOrNone,
	ParamAst,
	ParamsAst,
	ParenthesizedAst,
	range,
	rangeOfModifierAst,
	rangeOfNameAndRange,
	rangeOfOptNameAndRange,
	SeqAst,
	SigAst,
	SpecBodyAst,
	SpecDeclAst,
	SpecSigAst,
	SpecUseAst,
	StructAliasAst,
	StructDeclAst,
	suffixRange,
	ThenAst,
	ThenVoidAst,
	ThrowAst,
	TypeAst,
	TypedAst,
	UnlessAst;
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
import util.sym : AllSymbols, shortSym, Sym, symSize;
import util.util : todo;

struct Token {
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
	immutable Kind kind;
	immutable RangeWithinFile range;
}

immutable(Repr) reprTokens(ref Alloc alloc, ref immutable Token[] tokens) {
	return reprArr(alloc, tokens, (ref immutable Token it) =>
		reprToken(alloc, it));
}

immutable(Token[]) tokensOfAst(ref Alloc alloc, ref const AllSymbols allSymbols, scope ref immutable FileAst ast) {
	ArrBuilder!Token tokens;

	addImportTokens(alloc, tokens, allSymbols, ast.imports, shortSym("import"));
	addImportTokens(alloc, tokens, allSymbols, ast.exports, shortSym("export"));

	//TODO: also tests...
	eachSorted!(RangeWithinFile, SpecDeclAst, StructAliasAst, StructDeclAst, FunDeclAst)(
		RangeWithinFile.max,
		(scope ref immutable RangeWithinFile a, scope ref immutable RangeWithinFile b) =>
			compareRangeWithinFile(a, b),
		ast.specs, (scope ref immutable SpecDeclAst it) => it.range, (scope ref immutable SpecDeclAst it) {
			addSpecTokens(alloc, tokens, allSymbols, it);
		},
		ast.structAliases,
		(scope ref immutable StructAliasAst it) => it.range,
		(scope ref immutable StructAliasAst it) {
			addStructAliasTokens(alloc, tokens, allSymbols, it);
		},
		ast.structs, (scope ref immutable StructDeclAst it) => it.range, (scope ref immutable StructDeclAst it) {
			addStructTokens(alloc, tokens, allSymbols, it);
		},
		ast.funs, (scope ref immutable FunDeclAst it) => it.range, (scope ref immutable FunDeclAst it) {
			addFunTokens(alloc, tokens, allSymbols, it);
		});
	immutable Token[] res = finishArr(alloc, tokens);
	assertTokensSorted(res);
	return res;
}

private:

immutable(RangeWithinFile) rangeAtName(
	ref const AllSymbols allSymbols,
	immutable Visibility visibility,
	immutable Pos start,
	immutable Sym name,
) {
	immutable uint offset = () {
		final switch (visibility) {
			case Visibility.public_:
				return 0;
			case Visibility.private_:
				return 1;
		}
	}();
	immutable Pos afterDot = start + offset;
	return immutable RangeWithinFile(afterDot, afterDot + symSize(allSymbols, name));
}

immutable(RangeWithinFile) rangeAtName(ref const AllSymbols allSymbols, immutable Pos start, immutable Sym name) {
	return rangeAtName(allSymbols, Visibility.public_, start, name);
}

void addImportTokens(
	ref Alloc alloc,
	ref ArrBuilder!Token tokens,
	ref const AllSymbols allSymbols,
	scope ref immutable Opt!ImportsOrExportsAst a,
	immutable Sym keyword,
) {
	if (has(a)) {
		add(alloc, tokens, immutable Token(
			Token.Kind.keyword,
			rangeAtName(allSymbols, force(a).range.start, keyword)));
		foreach (ref immutable ImportOrExportAst path; force(a).paths)
			add(alloc, tokens, immutable Token(
				Token.Kind.importPath,
				path.range));
	}
}

void addSpecTokens(
	ref Alloc alloc,
	ref ArrBuilder!Token tokens,
	ref const AllSymbols allSymbols,
	scope ref immutable SpecDeclAst a,
) {
	add(alloc, tokens, immutable Token(
		Token.Kind.spec,
		rangeAtName(allSymbols, a.visibility, a.range.start, a.name)));
	addTypeParamsTokens(alloc, tokens, allSymbols, a.typeParams);
	matchSpecBodyAst!(
		void,
		(ref immutable SpecBodyAst.Builtin) {},
		(ref immutable SpecSigAst[] sigs) {
			foreach (ref immutable SpecSigAst sig; sigs) {
				add(alloc, tokens, immutable Token(
					Token.Kind.fun,
					rangeAtName(allSymbols, sig.sig.range.start, sig.sig.name)));
				addSigReturnTypeAndParamsTokens(alloc, tokens, allSymbols, sig.sig);
			}
		},
	)(a.body_);
}

void addSigReturnTypeAndParamsTokens(
	ref Alloc alloc,
	ref ArrBuilder!Token tokens,
	ref const AllSymbols allSymbols,
	scope ref immutable SigAst a,
) {
	addTypeTokens(alloc, tokens, allSymbols, a.returnType);
	matchParamsAst!(
		void,
		(immutable ParamAst[] params) {
			foreach (ref immutable ParamAst param; params)
				addParamTokens(alloc, tokens, allSymbols, param);
		},
		(ref immutable ParamsAst.Varargs v) {
			addParamTokens(alloc, tokens, allSymbols, v.param);
		},
	)(a.params);
}

void addTypeTokens(
	ref Alloc alloc,
	ref ArrBuilder!Token tokens,
	ref const AllSymbols allSymbols,
	scope immutable TypeAst a,
) {
	matchTypeAst!(
		void,
		(immutable TypeAst.Dict it) {
			addTypeTokens(alloc, tokens, allSymbols, it.v);
			add(alloc, tokens, immutable Token(
				Token.Kind.keyword,
				immutable RangeWithinFile(range(it.v).end, range(it.k).start)));
			addTypeTokens(alloc, tokens, allSymbols, it.k);
			add(alloc, tokens, immutable Token(
				Token.Kind.keyword,
				rangeOfStartAndLength(range(it.k).end, "]".length)));
		},
		(immutable TypeAst.Fun it) {
			add(alloc, tokens, immutable Token(
				Token.Kind.keyword,
				rangeOfStartAndName(it.range.start, shortSym("fun"), allSymbols)));
			foreach (immutable TypeAst t; it.returnAndParamTypes)
				addTypeTokens(alloc, tokens, allSymbols, t);
		},
		(immutable TypeAst.InstStruct it) {
			addInstStructTokens(alloc, tokens, allSymbols, it);
		},
		(immutable TypeAst.Suffix it) {
			addTypeTokens(alloc, tokens, allSymbols, it.left);
			add(alloc, tokens, immutable Token(Token.Kind.keyword, suffixRange(it)));
		},
	)(a);
}

void addInstStructTokens(
	ref Alloc alloc,
	ref ArrBuilder!Token tokens,
	ref const AllSymbols allSymbols,
	scope ref immutable TypeAst.InstStruct a,
) {
	add(alloc, tokens, immutable Token(Token.Kind.struct_, rangeOfNameAndRange(a.name, allSymbols)));
	addTypeArgsTokens(alloc, tokens, allSymbols, a.typeArgs);
}

void addTypeArgsTokens(
	ref Alloc alloc,
	ref ArrBuilder!Token tokens,
	ref const AllSymbols allSymbols,
	scope immutable TypeAst[] typeArgs,
) {
	foreach (immutable TypeAst typeArg; typeArgs)
		addTypeTokens(alloc, tokens, allSymbols, typeArg);
}

void addParamTokens(
	ref Alloc alloc,
	ref ArrBuilder!Token tokens,
	ref const AllSymbols allSymbols,
	scope ref immutable ParamAst a,
) {
	if (has(a.name))
		add(alloc, tokens, immutable Token(
			Token.Kind.param,
			rangeOfStartAndName(a.range.start, force(a.name), allSymbols)));
	addTypeTokens(alloc, tokens, allSymbols, a.type);
}

void addTypeParamsTokens(
	ref Alloc alloc,
	ref ArrBuilder!Token tokens,
	ref const AllSymbols allSymbols,
	scope immutable NameAndRange[] a,
) {
	foreach (immutable NameAndRange typeParam; a)
		add(alloc, tokens, immutable Token(Token.Kind.typeParam, rangeOfNameAndRange(typeParam, allSymbols)));
}

void addStructAliasTokens(
	ref Alloc alloc,
	ref ArrBuilder!Token tokens,
	ref const AllSymbols allSymbols,
	scope ref immutable StructAliasAst a,
) {
	add(alloc, tokens, immutable Token(
		Token.Kind.struct_,
		rangeAtName(allSymbols, a.visibility, a.range.start, a.name)));
	addTypeParamsTokens(alloc, tokens, allSymbols, a.typeParams);
	addTypeTokens(alloc, tokens, allSymbols, a.target);
}

void addStructTokens(
	ref Alloc alloc,
	ref ArrBuilder!Token tokens,
	ref const AllSymbols allSymbols,
	scope ref immutable StructDeclAst a,
) {
	add(alloc, tokens, immutable Token(
		Token.Kind.struct_,
		rangeAtName(allSymbols, a.visibility, a.range.start, a.name)));
	addTypeParamsTokens(alloc, tokens, allSymbols, a.typeParams);
	matchStructDeclAstBody!(
		void,
		(ref immutable StructDeclAst.Body.Builtin) {
			addModifierTokens(alloc, tokens, allSymbols, a);
		},
		(ref immutable StructDeclAst.Body.Enum it) {
			addEnumOrFlagsTokens(alloc, tokens, allSymbols, a, it.typeArg, it.members);
		},
		(ref immutable StructDeclAst.Body.Flags it) {
			addEnumOrFlagsTokens(alloc, tokens, allSymbols, a, it.typeArg, it.members);
		},
		(ref immutable StructDeclAst.Body.ExternPtr) {
			addModifierTokens(alloc, tokens, allSymbols, a);
		},
		(ref immutable StructDeclAst.Body.Record record) {
			addModifierTokens(alloc, tokens, allSymbols, a);
			foreach (ref immutable StructDeclAst.Body.Record.Field field; record.fields) {
				add(alloc, tokens, immutable Token(
					Token.Kind.member,
					rangeAtName(allSymbols, field.range.start, field.name)));
				addTypeTokens(alloc, tokens, allSymbols, field.type);
			}
		},
		(ref immutable StructDeclAst.Body.Union union_) {
			addModifierTokens(alloc, tokens, allSymbols, a);
			foreach (ref immutable StructDeclAst.Body.Union.Member member; union_.members) {
				add(alloc, tokens, immutable Token(
					Token.Kind.member,
					rangeAtName(allSymbols, member.range.start, member.name)));
				if (has(member.type))
					addTypeTokens(alloc, tokens, allSymbols, force(member.type));
			}
		},
	)(a.body_);
}

void addModifierTokens(
	ref Alloc alloc,
	ref ArrBuilder!Token tokens,
	ref const AllSymbols allSymbols,
	scope ref immutable StructDeclAst a,
) {
	foreach (ref immutable ModifierAst modifier; a.modifiers)
		add(alloc, tokens, immutable Token(Token.Kind.modifier, rangeOfModifierAst(modifier, allSymbols)));
}

void addEnumOrFlagsTokens(
	ref Alloc alloc,
	ref ArrBuilder!Token tokens,
	ref const AllSymbols allSymbols,
	ref immutable StructDeclAst a,
	scope immutable Opt!(TypeAst*) typeArg,
	scope immutable StructDeclAst.Body.Enum.Member[] members,
) {
	if (has(typeArg))
		addTypeTokens(alloc, tokens, allSymbols, *force(typeArg));
	addModifierTokens(alloc, tokens, allSymbols, a);
	foreach (ref immutable StructDeclAst.Body.Enum.Member member; members) {
		add(alloc, tokens, immutable Token(Token.Kind.member, member.range));
		if (has(member.value)) {
			immutable uint addLen = " = ".length;
			immutable Pos pos = member.range.start + symSize(allSymbols, member.name) + addLen;
			add(alloc, tokens, immutable Token(
				Token.Kind.literalNumber,
				immutable RangeWithinFile(pos, member.range.end)));
		}
	}
}

void addFunTokens(
	ref Alloc alloc,
	ref ArrBuilder!Token tokens,
	ref const AllSymbols allSymbols,
	scope ref immutable FunDeclAst a,
) {
	add(alloc, tokens, immutable Token(
		Token.Kind.fun,
		rangeAtName(allSymbols, a.visibility, a.range.start, a.sig.name)));
	addTypeParamsTokens(alloc, tokens, allSymbols, a.typeParams);
	addSigReturnTypeAndParamsTokens(alloc, tokens, allSymbols, a.sig);
	foreach (ref immutable SpecUseAst specUse; a.specUses) {
		add(alloc, tokens, immutable Token(Token.Kind.spec, rangeOfNameAndRange(specUse.spec, allSymbols)));
		addTypeArgsTokens(alloc, tokens, allSymbols, specUse.typeArgs);
	}
	matchFunBodyAst!(
		void,
		(ref immutable FunBodyAst.Builtin) {},
		(ref immutable FunBodyAst.Extern) {},
		(ref immutable ExprAst it) {
			addExprTokens(alloc, tokens, allSymbols, it);
		},
	)(a.body_);
}

void addExprTokens(
	ref Alloc alloc,
	ref ArrBuilder!Token tokens,
	ref const AllSymbols allSymbols,
	ref immutable ExprAst a,
) {
	matchExprAstKind!(
		void,
		(ref immutable ArrowAccessAst it) {
			addExprTokens(alloc, tokens, allSymbols, it.left);
			add(alloc, tokens, immutable Token(Token.Kind.fun, rangeOfNameAndRange(it.name, allSymbols)));
			addTypeArgsTokens(alloc, tokens, allSymbols, it.typeArgs);
		},
		(ref immutable BogusAst) {},
		(ref immutable CallAst it) {
			void addName() {
				add(alloc, tokens, immutable Token(Token.Kind.fun, rangeOfNameAndRange(it.funName, allSymbols)));
				addTypeArgsTokens(alloc, tokens, allSymbols, it.typeArgs);
			}
			final switch (it.style) {
				case CallAst.Style.dot:
				case CallAst.Style.setDot:
				case CallAst.Style.infix:
				case CallAst.Style.suffixOperator:
					addExprTokens(alloc, tokens, allSymbols, it.args[0]);
					addName();
					addExprsTokens(alloc, tokens, allSymbols, it.args[1 .. $]);
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
				case CallAst.Style.setDeref:
				case CallAst.Style.setSubscript:
				case CallAst.Style.subscript:
					addExprsTokens(alloc, tokens, allSymbols, it.args);
					break;
			}
		},
		(ref immutable ForAst x) {
			add(alloc, tokens, immutable Token(
				Token.Kind.keyword,
				rangeOfStartAndLength(a.range.start, "for".length)));
			addLambdaAstParam(alloc, tokens, allSymbols, x.param);
			addExprTokens(alloc, tokens, allSymbols, x.collection);
			addExprTokens(alloc, tokens, allSymbols, x.body_);
		},
		(ref immutable(FunPtrAst)) {
			add(alloc, tokens, immutable Token(Token.Kind.identifier, a.range));
		},
		(ref immutable(IdentifierAst)) {
			add(alloc, tokens, immutable Token(Token.Kind.identifier, a.range));
		},
		(ref immutable IdentifierSetAst x) {
			add(alloc, tokens, immutable Token(
				Token.Kind.identifier,
				rangeOfNameAndRange(immutable NameAndRange(a.range.start, x.name), allSymbols))) ;
			addExprTokens(alloc, tokens, allSymbols, x.value);
		},
		(ref immutable IfAst it) {
			addExprTokens(alloc, tokens, allSymbols, it.cond);
			addExprTokens(alloc, tokens, allSymbols, it.then);
			if (has(it.else_))
				addExprTokens(alloc, tokens, allSymbols, force(it.else_));
		},
		(ref immutable IfOptionAst it) {
			add(alloc, tokens, localDefOfNameAndRange(allSymbols, it.name));
			addExprTokens(alloc, tokens, allSymbols, it.option);
			addExprTokens(alloc, tokens, allSymbols, it.then);
			if (has(it.else_))
				addExprTokens(alloc, tokens, allSymbols, force(it.else_));
		},
		(ref immutable InterpolatedAst it) {
			Pos pos = a.range.start;
			if (!empty(it.parts)) {
				// Ensure opening quote is highlighted
				matchInterpolatedPart!(
					void,
					(ref immutable(string)) {},
					(ref immutable(ExprAst)) {
						add(alloc, tokens, immutable Token(
							Token.Kind.literalString,
							immutable RangeWithinFile(pos, pos + 1)));
					},
				)(it.parts[0]);
				foreach (immutable size_t i, ref immutable InterpolatedPart part; it.parts)
					matchInterpolatedPart!(
						void,
						(ref immutable string s) {
							// TODO: length may be wrong if there are escapes
							// Ensure the closing quote is highlighted
							immutable Pos end = safeToUint(pos + s.length) + (i == it.parts.length - 1 ? 1 : 0);
							add(alloc, tokens, immutable Token(
								Token.Kind.literalString,
								immutable RangeWithinFile(pos, end)));
						},
						(ref immutable ExprAst e) {
							addExprTokens(alloc, tokens, allSymbols, e);
							pos = safeToUint(e.range.end + 1);
						},
					)(part);
				// Ensure closing quote is highlighted
				matchInterpolatedPart!(
					void,
					(ref immutable(string)) {},
					(ref immutable(ExprAst)) {
						add(alloc, tokens, immutable Token(
							Token.Kind.literalString,
							immutable RangeWithinFile(a.range.end - 1, a.range.end)));
					},
				)(it.parts[$ - 1]);
			}
		},
		(ref immutable LambdaAst it) {
			foreach (ref immutable LambdaAst.Param param; it.params)
				addLambdaAstParam(alloc, tokens, allSymbols, param);
			addExprTokens(alloc, tokens, allSymbols, it.body_);
		},
		(ref immutable LetAst it) {
			add(alloc, tokens, has(it.name)
				? localDefOfNameAndRange(allSymbols, immutable NameAndRange(a.range.start, force(it.name)))
				: immutable Token(Token.Kind.keyword, rangeOfStartAndLength(a.range.start, "_".length)));
			addExprTokens(alloc, tokens, allSymbols, it.initializer);
			addExprTokens(alloc, tokens, allSymbols, it.then);
		},
		(ref immutable LiteralAst literal) {
			immutable Token.Kind kind = matchLiteralAst!(
				immutable Token.Kind,
				(immutable LiteralAst.Float) =>
					Token.Kind.literalNumber,
				(immutable LiteralAst.Int) =>
					Token.Kind.literalNumber,
				(immutable LiteralAst.Nat) =>
					Token.Kind.literalNumber,
				(immutable(string)) =>
					Token.Kind.literalString,
			)(literal);
			add(alloc, tokens, immutable Token(kind, a.range));
		},
		(ref immutable LoopAst it) {
			add(alloc, tokens, immutable Token(
				Token.Kind.keyword,
				rangeOfStartAndLength(a.range.start, "loop".length)));
			addExprTokens(alloc, tokens, allSymbols, it.body_);
		},
		(ref immutable LoopBreakAst it) {
			add(alloc, tokens, immutable Token(
				Token.Kind.keyword,
				rangeOfStartAndLength(a.range.start, "break".length)));
			if (has(it.value))
				addExprTokens(alloc, tokens, allSymbols, force(it.value));
		},
		(ref immutable LoopContinueAst it) {
			add(alloc, tokens, immutable Token(
				Token.Kind.keyword,
				rangeOfStartAndLength(a.range.start, "continue".length)));
		},
		(ref immutable LoopUntilAst it) {
			add(alloc, tokens, immutable Token(
				Token.Kind.keyword,
				rangeOfStartAndLength(a.range.start, "until".length)));
			addExprTokens(alloc, tokens, allSymbols, it.condition);
			addExprTokens(alloc, tokens, allSymbols, it.body_);
		},
		(ref immutable LoopWhileAst it) {
			add(alloc, tokens, immutable Token(
				Token.Kind.keyword,
				rangeOfStartAndLength(a.range.start, "while".length)));
			addExprTokens(alloc, tokens, allSymbols, it.condition);
			addExprTokens(alloc, tokens, allSymbols, it.body_);
		},
		(ref immutable MatchAst it) {
			addExprTokens(alloc, tokens, allSymbols, it.matched);
			foreach (ref immutable MatchAst.CaseAst case_; it.cases) {
				add(alloc, tokens, immutable Token(Token.Kind.struct_, case_.memberNameRange(allSymbols)));
				matchNameOrUnderscoreOrNone!(
					void,
					(immutable(Sym)) {
						add(alloc, tokens, immutable Token(Token.Kind.local, case_.localRange(allSymbols)));
					},
					(ref immutable NameOrUnderscoreOrNone.Underscore) {},
					(ref immutable NameOrUnderscoreOrNone.None) {},
				)(case_.local);
				addExprTokens(alloc, tokens, allSymbols, case_.then);
			}
		},
		(ref immutable ParenthesizedAst it) {
			addExprTokens(alloc, tokens, allSymbols, it.inner);
		},
		(ref immutable SeqAst it) {
			addExprTokens(alloc, tokens, allSymbols, it.first);
			addExprTokens(alloc, tokens, allSymbols, it.then);
		},
		(ref immutable ThenAst it) {
			addLambdaAstParam(alloc, tokens, allSymbols, it.left);
			addExprTokens(alloc, tokens, allSymbols, it.futExpr);
			addExprTokens(alloc, tokens, allSymbols, it.then);
		},
		(ref immutable ThenVoidAst it) {
			addExprTokens(alloc, tokens, allSymbols, it.futExpr);
			addExprTokens(alloc, tokens, allSymbols, it.then);
		},
		(ref immutable ThrowAst it) {
			add(alloc, tokens, immutable Token(
				Token.Kind.keyword,
				rangeOfStartAndLength(a.range.start, "throw".length)));
			addExprTokens(alloc, tokens, allSymbols, it.thrown);
		},
		(ref immutable TypedAst it) {
			addExprTokens(alloc, tokens, allSymbols, it.expr);
			addTypeTokens(alloc, tokens, allSymbols, it.type);
		},
		(ref immutable UnlessAst it) {
			addExprTokens(alloc, tokens, allSymbols, it.cond);
			addExprTokens(alloc, tokens, allSymbols, it.body_);
		},
	)(a.kind);
}

immutable(Token) localDefOfNameAndRange(ref const AllSymbols allSymbols, immutable NameAndRange a) {
	return immutable Token(Token.Kind.local, rangeOfNameAndRange(a, allSymbols));
}

void addLambdaAstParam(
	ref Alloc alloc,
	ref ArrBuilder!Token tokens,
	ref const AllSymbols allSymbols,
	ref immutable LambdaAst.Param param,
) {
	add(alloc, tokens, immutable Token(Token.Kind.param, rangeOfOptNameAndRange(param, allSymbols)));
}

void addExprsTokens(
	ref Alloc alloc,
	ref ArrBuilder!Token tokens,
	ref const AllSymbols allSymbols,
	scope immutable ExprAst[] exprs,
) {
	foreach (ref immutable ExprAst expr; exprs)
		addExprTokens(alloc, tokens, allSymbols, expr);
}

void assertTokensSorted(ref immutable Token[] tokens) {
	immutable Opt!UnsortedPair pair = findUnsortedPair!Token(tokens, (ref immutable Token a, ref immutable Token b) =>
		compareRangeWithinFile(a.range, b.range));
	if (has(pair))
		// To debug, just disable this assertion and look for the unsorted token in the output
		todo!void("tokens not sorted!");
}

immutable(Comparison) compareRangeWithinFile(ref immutable RangeWithinFile a, ref immutable RangeWithinFile b) {
	return compareNat32(a.start, b.start);
}

immutable(Sym) symOfTokenKind(immutable Token.Kind kind) {
	final switch (kind) {
		case Token.Kind.fun:
			return shortSym("fun");
		case Token.Kind.identifier:
			return shortSym("identifier");
		case Token.Kind.importPath:
			return shortSym("import");
		case Token.Kind.keyword:
			return shortSym("keyword");
		case Token.Kind.literalNumber:
			return shortSym("lit-num");
		case Token.Kind.literalString:
			return shortSym("lit-str");
		case Token.Kind.local:
			return shortSym("local");
		case Token.Kind.member:
			return shortSym("member");
		case Token.Kind.modifier:
			return shortSym("modifier");
		case Token.Kind.param:
			return shortSym("param");
		case Token.Kind.spec:
			return shortSym("spec");
		case Token.Kind.struct_:
			return shortSym("struct");
		case Token.Kind.typeParam:
			return shortSym("type-param");
	}
}

immutable(Repr) reprToken(ref Alloc alloc, ref immutable Token token) {
	return reprNamedRecord(alloc, "token", [
		nameAndRepr("kind", reprSym(symOfTokenKind(token.kind))),
		nameAndRepr("range", reprRangeWithinFile(alloc, token.range))]);
}
