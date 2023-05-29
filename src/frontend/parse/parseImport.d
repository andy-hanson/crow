module frontend.parse.parseImport;

@safe @nogc pure nothrow:

import frontend.parse.ast : ImportOrExportAst, ImportOrExportAstKind, ImportsOrExportsAst, NameAndRange, TypeAst;
import frontend.parse.lexer : addDiag, addDiagAtChar, alloc, allSymbols, curPos, Lexer, range, Token;
import frontend.parse.parseType : parseType;
import frontend.parse.parseUtil :
	NewlineOrDedent,
	peekNewline,
	peekToken,
	takeIndentOrDiagTopLevel,
	takeIndentOrFailGeneric,
	takeName,
	takeNameOrOperator,
	takeNewlineOrDedentAmount,
	takeNewlineOrSingleDedent,
	takeOrAddDiagExpectedOperator,
	toNewlineOrDedent,
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
import util.util : todo, unreachable;

Opt!ImportsOrExportsAst parseImportsOrExports(ref AllPaths allPaths, ref Lexer lexer, Token keyword) {
	Pos start = curPos(lexer);
	if (tryTakeToken(lexer, keyword)) {
		ArrBuilder!ImportOrExportAst res;
		if (takeIndentOrDiagTopLevel(lexer)) {
			void recur() {
				ImportAndDedent id = parseSingleModuleImportOnOwnLine(allPaths, lexer);
				add(lexer.alloc, res, id.import_);
				if (id.dedented == NewlineOrDedent.newline)
					recur();
			}
			recur();
		}
		return some(ImportsOrExportsAst(range(lexer, start), finishArr(lexer.alloc, res)));
	} else
		return none!ImportsOrExportsAst;
}

private:

immutable struct ImportAndDedent {
	ImportOrExportAst import_;
	NewlineOrDedent dedented;
}

immutable struct ImportOrExportKindAndDedent {
	ImportOrExportAstKind kind;
	RangeWithinFile range;
	NewlineOrDedent dedented;
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

ImportAndDedent parseSingleModuleImportOnOwnLine(ref AllPaths allPaths, ref Lexer lexer) {
	Pos start = curPos(lexer);
	PathOrRelPath path = parseImportPath(allPaths, lexer);
	ImportOrExportKindAndDedent kind = parseImportOrExportKind(lexer, start);
	return ImportAndDedent(ImportOrExportAst(kind.range, path, kind.kind), kind.dedented);
}

ImportOrExportKindAndDedent parseImportOrExportKind(ref Lexer lexer, Pos start) {
	if (tryTakeToken(lexer, Token.colon)) {
		if (peekToken(lexer, Token.newline))
			return takeIndentOrFailGeneric(
				lexer,
				() => parseIndentedImportNames(lexer, start),
				(RangeWithinFile range, uint dedents) =>
					ImportOrExportKindAndDedent(
						ImportOrExportAstKind(ImportOrExportAstKind.ModuleWhole()),
						range,
						toNewlineOrDedent(dedents)));
		else {
			Sym[] names = parseSingleImportNamesOnSingleLine(lexer);
			return ImportOrExportKindAndDedent(
				ImportOrExportAstKind(names),
				range(lexer, start),
				takeNewlineOrSingleDedent(lexer));
		}
	} else if (tryTakeToken(lexer, Token.as)) {
		Sym name = takeName(lexer);
		ImportFileType type = parseImportFileType(lexer);
		return ImportOrExportKindAndDedent(
			ImportOrExportAstKind(allocate(lexer.alloc, ImportOrExportAstKind.File(name, type))),
			range(lexer, start),
			takeNewlineOrSingleDedent(lexer));
	}
	return ImportOrExportKindAndDedent(
		ImportOrExportAstKind(ImportOrExportAstKind.ModuleWhole()),
		range(lexer, start),
		takeNewlineOrSingleDedent(lexer));
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

ImportOrExportKindAndDedent parseIndentedImportNames(ref Lexer lexer, Pos start) {
	ArrBuilder!Sym names;
	immutable struct NewlineOrDedentAndRange {
		NewlineOrDedent newlineOrDedent;
		RangeWithinFile range;
	}
	NewlineOrDedentAndRange recur() {
		TrailingComma trailingComma = takeCommaSeparatedNames(lexer, names);
		RangeWithinFile range0 = range(lexer, start);
		switch (takeNewlineOrDedentAmount(lexer)) {
			case 0:
				final switch (trailingComma) {
					case TrailingComma.no:
						addDiag(lexer, range(lexer, start), ParseDiag(
							ParseDiag.Expected(ParseDiag.Expected.Kind.comma)));
						break;
					case TrailingComma.yes:
						break;
				}
				return recur();
			case 1:
				final switch (trailingComma) {
					case TrailingComma.no:
						break;
					case TrailingComma.yes:
						todo!void("!");
						break;
				}
				return NewlineOrDedentAndRange(NewlineOrDedent.newline, range0);
			case 2:
				final switch (trailingComma) {
					case TrailingComma.no:
						break;
					case TrailingComma.yes:
						todo!void("!");
						break;
				}
				return NewlineOrDedentAndRange(NewlineOrDedent.dedent, range0);
			default:
				return unreachable!NewlineOrDedentAndRange();
		}
	}
	NewlineOrDedentAndRange res = recur();
	return ImportOrExportKindAndDedent(
		ImportOrExportAstKind(finishArr(lexer.alloc, names)),
		res.range,
		res.newlineOrDedent);
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
		? peekNewline(lexer)
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
