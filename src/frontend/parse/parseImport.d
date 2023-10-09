module frontend.parse.parseImport;

@safe @nogc pure nothrow:

import frontend.parse.ast : ImportOrExportAst, ImportOrExportAstKind, ImportsOrExportsAst, NameAndRange, TypeAst;
import frontend.parse.lexer : addDiag, addDiagAtChar, alloc, allSymbols, curPos, Lexer, range, Token;
import frontend.parse.parseType : parseType;
import frontend.parse.parseUtil :
	NewlineOrDedent,
	peekEndOfLine,
	peekToken,
	takeIndentOrFailGeneric,
	takeName,
	takeNameOrOperator,
	takeNewlineOrDedent,
	takeOrAddDiagExpectedOperator,
	tryTakeOperator,
	tryTakeToken;
import model.model : ImportFileType;
import model.parseDiag : ParseDiag;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.conv : safeToUshort;
import util.memory : allocate;
import util.opt : force, has, none, Opt, some;
import util.path : AllPaths, childPath, Path, PathOrRelPath, rootPath;
import util.sourceRange : Pos, RangeWithinFile;
import util.sym : concatSymsWithDot, Sym, sym;
import util.util : todo, typeAs;

Opt!ImportsOrExportsAst parseImportsOrExports(ref AllPaths allPaths, ref Lexer lexer, Token keyword) {
	Pos start = curPos(lexer);
	if (tryTakeToken(lexer, keyword)) {
		ImportOrExportAst[] imports = takeIndentOrFailGeneric!(ImportOrExportAst[])(
			lexer,
			() => parseImportLines(allPaths, lexer),
			(RangeWithinFile _) => typeAs!(ImportOrExportAst[])([]));
		return some(ImportsOrExportsAst(range(lexer, start), imports));
	} else
		return none!ImportsOrExportsAst;
}

private:

ImportOrExportAst[] parseImportLines(ref AllPaths allPaths, ref Lexer lexer) {
	ArrBuilder!ImportOrExportAst res;
	while (true) {
		add(lexer.alloc, res, parseSingleModuleImportOnOwnLine(allPaths, lexer));
		final switch (takeNewlineOrDedent(lexer)) {
			case NewlineOrDedent.newline:
				continue;
			case NewlineOrDedent.dedent:
				return finishArr(lexer.alloc, res);
		}
	}
}

PathOrRelPath parseImportPath(ref AllPaths allPaths, ref Lexer lexer) {
	Opt!ushort nParents = () {
		if (tryTakeToken(lexer, Token.dot)) {
			takeOrAddDiagExpectedOperator(lexer, sym!"/", ParseDiag.Expected.Kind.slash);
			return some!ushort(0);
		} else if (tryTakeOperator(lexer, sym!"..")) {
			takeOrAddDiagExpectedOperator(lexer, sym!"/", ParseDiag.Expected.Kind.slash);
			return some(safeToUshort(takeDotDotSlashes(lexer, 1)));
		} else
			return none!ushort;
	}();
	return PathOrRelPath(
		nParents,
		addPathComponents(allPaths, lexer, rootPath(allPaths, takePathComponent(lexer))));
}

size_t takeDotDotSlashes(ref Lexer lexer, size_t acc) {
	if (tryTakeOperator(lexer, sym!"..")) {
		takeOrAddDiagExpectedOperator(lexer, sym!"/", ParseDiag.Expected.Kind.slash);
		return takeDotDotSlashes(lexer, acc + 1);
	} else
		return acc;
}

Path addPathComponents(ref AllPaths allPaths, ref Lexer lexer, Path acc) =>
	tryTakeOperator(lexer, sym!"/")
		? addPathComponents(allPaths, lexer, childPath(allPaths, acc, takePathComponent(lexer)))
		: acc;

ImportOrExportAst parseSingleModuleImportOnOwnLine(ref AllPaths allPaths, ref Lexer lexer) {
	Pos start = curPos(lexer);
	PathOrRelPath path = parseImportPath(allPaths, lexer);
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
				(RangeWithinFile _) =>
					ImportOrExportAstKind(ImportOrExportAstKind.ModuleWhole()));
	} else if (tryTakeToken(lexer, Token.as)) {
		Sym name = takeName(lexer);
		ImportFileType type = parseImportFileType(lexer);
		return ImportOrExportAstKind(allocate(lexer.alloc, ImportOrExportAstKind.File(name, type)));
	} else
		return ImportOrExportAstKind(ImportOrExportAstKind.ModuleWhole());
}

ImportFileType parseImportFileType(ref Lexer lexer) {
	Pos start = curPos(lexer);
	TypeAst type = parseType(lexer);
	Opt!ImportFileType fileType = toImportFileType(type);
	if (has(fileType))
		return force(fileType);
	else {
		addDiag(lexer, range(lexer, start), ParseDiag(ParseDiag.ImportFileTypeNotSupported()));
		return ImportFileType.str;
	}
}

Opt!ImportFileType toImportFileType(in TypeAst a) =>
	isSimpleName(a, sym!"string")
	? some(ImportFileType.str)
	: isInstStructOneArg(a, sym!"nat8", sym!"array")
	? some(ImportFileType.nat8Array)
	: none!ImportFileType;

bool isSimpleName(TypeAst a, Sym name) =>
	a.isA!NameAndRange && a.as!NameAndRange.name == name;

bool isInstStructOneArg(TypeAst a, Sym typeArgName, Sym name) {
	if (a.isA!(TypeAst.SuffixName*)) {
		TypeAst.SuffixName* s = a.as!(TypeAst.SuffixName*);
		return isSimpleName(s.left, typeArgName) && s.name.name == name;
	} else
		return false;
}

ImportOrExportAstKind parseIndentedImportNames(ref Lexer lexer, Pos start) {
	ArrBuilder!Sym names;
	while (true) {
		TrailingComma trailingComma = takeCommaSeparatedNames(lexer, names);
		final switch (takeNewlineOrDedent(lexer)) {
			case NewlineOrDedent.newline:
				final switch (trailingComma) {
					case TrailingComma.no:
						addDiag(lexer, range(lexer, start), ParseDiag(
							ParseDiag.Expected(ParseDiag.Expected.Kind.comma)));
						break;
					case TrailingComma.yes:
						break;
				}
				continue;
			case NewlineOrDedent.dedent:
				final switch (trailingComma) {
					case TrailingComma.no:
						break;
					case TrailingComma.yes:
						todo!void("!");
						break;
				}
				return ImportOrExportAstKind(finishArr(lexer.alloc, names));
		}
	}
}

Sym[] parseSingleImportNamesOnSingleLine(ref Lexer lexer) {
	ArrBuilder!Sym names;
	final switch (takeCommaSeparatedNames(lexer, names)) {
		case TrailingComma.no:
			break;
		case TrailingComma.yes:
			addDiagAtChar(lexer, ParseDiag(ParseDiag.TrailingComma()));
			break;
	}
	return finishArr(lexer.alloc, names);
}

enum TrailingComma { no, yes }

TrailingComma takeCommaSeparatedNames(ref Lexer lexer, ref ArrBuilder!Sym names) {
	add(lexer.alloc, names, takeNameOrOperator(lexer));
	return tryTakeToken(lexer, Token.comma)
		? peekEndOfLine(lexer)
			? TrailingComma.yes
			: takeCommaSeparatedNames(lexer, names)
		: TrailingComma.no;
}

Sym takePathComponent(ref Lexer lexer) =>
	takePathComponentRest(lexer, takeName(lexer));
Sym takePathComponentRest(ref Lexer lexer, Sym cur) {
	if (tryTakeToken(lexer, Token.dot)) {
		Sym extension = takeName(lexer);
		return takePathComponentRest(lexer, concatSymsWithDot(lexer.allSymbols, cur, extension));
	} else
		return cur;
}
