module frontend.parse.parseImport;

@safe @nogc pure nothrow:

import frontend.parse.lexer : addDiag, alloc, allSymbols, curPos, Lexer, range, Token;
import frontend.parse.parseType : parseType;
import frontend.parse.parseUtil :
	NewlineOrDedent,
	peekEndOfLine,
	peekToken,
	takeIndentOrFailGeneric,
	takeName,
	takeNameAndRange,
	takeNameOrOperator,
	takeNewlineOrDedent,
	takeOrAddDiagExpectedOperator,
	tryTakeOperator,
	tryTakeToken;
import model.ast :
	ImportOrExportAst, ImportOrExportAstKind, ImportsOrExportsAst, NameAndRange, PathOrRelPath, range, TypeAst;
import model.model : ImportFileType;
import model.parseDiag : ParseDiag;
import util.col.array : emptySmallArray, small, SmallArray;
import util.col.arrayBuilder : add, ArrayBuilder, finish;
import util.conv : safeToUshort;
import util.memory : allocate;
import util.opt : force, has, none, Opt, some;
import util.sourceRange : Pos, Range;
import util.symbol : concatSymbolsWithDot, Symbol, symbol;
import util.uri : AllUris, childPath, Path, RelPath, rootPath;

Opt!ImportsOrExportsAst parseImportsOrExports(scope ref AllUris allUris, ref Lexer lexer, Token keyword) {
	Pos start = curPos(lexer);
	if (tryTakeToken(lexer, keyword)) {
		SmallArray!ImportOrExportAst imports = takeIndentOrFailGeneric!(SmallArray!ImportOrExportAst)(
			lexer,
			() => parseImportLines(allUris, lexer),
			(in Range _) => emptySmallArray!ImportOrExportAst);
		return some(ImportsOrExportsAst(range(lexer, start), imports));
	} else
		return none!ImportsOrExportsAst;
}

private:

SmallArray!ImportOrExportAst parseImportLines(scope ref AllUris allUris, ref Lexer lexer) {
	ArrayBuilder!ImportOrExportAst res;
	while (true) {
		add(lexer.alloc, res, parseSingleModuleImportOnOwnLine(allUris, lexer));
		final switch (takeNewlineOrDedent(lexer)) {
			case NewlineOrDedent.newline:
				continue;
			case NewlineOrDedent.dedent:
				return small!ImportOrExportAst(finish(lexer.alloc, res));
		}
	}
}

PathOrRelPath parseImportPath(scope ref AllUris allUris, ref Lexer lexer) {
	Opt!ushort nParents = () {
		if (tryTakeToken(lexer, Token.dot)) {
			takeOrAddDiagExpectedOperator(lexer, symbol!"/", ParseDiag.Expected.Kind.slash);
			return some!ushort(0);
		} else if (tryTakeOperator(lexer, symbol!"..")) {
			takeOrAddDiagExpectedOperator(lexer, symbol!"/", ParseDiag.Expected.Kind.slash);
			return some(safeToUshort(takeDotDotSlashes(lexer, 1)));
		} else
			return none!ushort;
	}();
	Path path = addPathComponents(allUris, lexer, rootPath(allUris, takePathComponent(lexer)));
	return has(nParents) ? PathOrRelPath(RelPath(force(nParents), path)) : PathOrRelPath(path);
}

size_t takeDotDotSlashes(ref Lexer lexer, size_t acc) {
	if (tryTakeOperator(lexer, symbol!"..")) {
		takeOrAddDiagExpectedOperator(lexer, symbol!"/", ParseDiag.Expected.Kind.slash);
		return takeDotDotSlashes(lexer, acc + 1);
	} else
		return acc;
}

Path addPathComponents(scope ref AllUris allUris, ref Lexer lexer, Path acc) =>
	tryTakeOperator(lexer, symbol!"/")
		? addPathComponents(allUris, lexer, childPath(allUris, acc, takePathComponent(lexer)))
		: acc;

ImportOrExportAst parseSingleModuleImportOnOwnLine(scope ref AllUris allUris, ref Lexer lexer) {
	Pos start = curPos(lexer);
	PathOrRelPath path = parseImportPath(allUris, lexer);
	ImportOrExportAstKind kind = parseImportOrExportKind(lexer, start);
	return ImportOrExportAst(range(lexer, start), path, kind);
}

ImportOrExportAstKind parseImportOrExportKind(ref Lexer lexer, Pos start) {
	if (tryTakeToken(lexer, Token.colon)) {
		return peekToken(lexer, [Token.name, Token.nameOrOperatorEquals, Token.operator])
			? ImportOrExportAstKind(parseSingleImportNamesOnSingleLine(lexer))
			: takeIndentOrFailGeneric(
				lexer,
				() => parseIndentedImportNames(lexer, start),
				(in Range _) => ImportOrExportAstKind(ImportOrExportAstKind.ModuleWhole()));
	} else if (tryTakeToken(lexer, Token.as)) {
		NameAndRange name = takeNameAndRange(lexer);
		TypeAst type = parseType(lexer);
		return ImportOrExportAstKind(allocate(lexer.alloc, ImportOrExportAstKind.File(
			name, type, toImportFileTypeOrDiag(lexer, type))));
	} else
		return ImportOrExportAstKind(ImportOrExportAstKind.ModuleWhole());
}

ImportFileType toImportFileTypeOrDiag(ref Lexer lexer, in TypeAst type) {
	Opt!ImportFileType fileType = toImportFileType(type);
	if (has(fileType))
		return force(fileType);
	else {
		addDiag(lexer, type.range(lexer.allSymbols), ParseDiag(ParseDiag.ImportFileTypeNotSupported()));
		return ImportFileType.string;
	}
}

Opt!ImportFileType toImportFileType(in TypeAst a) =>
	isSimpleName(a, symbol!"string")
	? some(ImportFileType.string)
	: isInstStructOneArg(a, symbol!"nat8", symbol!"array")
	? some(ImportFileType.nat8Array)
	: none!ImportFileType;

bool isSimpleName(TypeAst a, Symbol name) =>
	a.isA!NameAndRange && a.as!NameAndRange.name == name;

bool isInstStructOneArg(TypeAst a, Symbol typeArgName, Symbol name) {
	if (a.isA!(TypeAst.SuffixName*)) {
		TypeAst.SuffixName* s = a.as!(TypeAst.SuffixName*);
		return isSimpleName(s.left, typeArgName) && s.name.name == name;
	} else
		return false;
}

ImportOrExportAstKind parseIndentedImportNames(ref Lexer lexer, Pos start) {
	ArrayBuilder!NameAndRange names;
	while (true) {
		Opt!Range trailingComma = takeCommaSeparatedNames(lexer, names);
		final switch (takeNewlineOrDedent(lexer)) {
			case NewlineOrDedent.newline:
				if (!has(trailingComma))
					addDiag(lexer, range(lexer, start), ParseDiag(
						ParseDiag.Expected(ParseDiag.Expected.Kind.comma)));
				continue;
			case NewlineOrDedent.dedent:
				addDiagIfTrailingComma(lexer, trailingComma);
				return ImportOrExportAstKind(finish(lexer.alloc, names));
		}
	}
}

NameAndRange[] parseSingleImportNamesOnSingleLine(ref Lexer lexer) {
	ArrayBuilder!NameAndRange names;
	addDiagIfTrailingComma(lexer, takeCommaSeparatedNames(lexer, names));
	return finish(lexer.alloc, names);
}

void addDiagIfTrailingComma(ref Lexer lexer, in Opt!Range trailingComma) {
	if (has(trailingComma))
		addDiag(lexer, force(trailingComma), ParseDiag(ParseDiag.TrailingComma()));
}

// Returns position of trailing comma
Opt!Range takeCommaSeparatedNames(ref Lexer lexer, ref ArrayBuilder!NameAndRange names) {
	add(lexer.alloc, names, takeNameOrOperator(lexer));
	Pos start = curPos(lexer);
	return tryTakeToken(lexer, Token.comma)
		? peekEndOfLine(lexer)
			? some(range(lexer, start))
			: takeCommaSeparatedNames(lexer, names)
		: none!Range;
}

Symbol takePathComponent(ref Lexer lexer) =>
	takePathComponentRest(lexer, takeName(lexer));
Symbol takePathComponentRest(ref Lexer lexer, Symbol cur) {
	if (tryTakeToken(lexer, Token.dot)) {
		Symbol extension = takeName(lexer);
		return takePathComponentRest(lexer, concatSymbolsWithDot(lexer.allSymbols, cur, extension));
	} else
		return cur;
}
