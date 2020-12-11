module test.testHover;

@safe @nogc nothrow: // not pure

import frontend.frontendCompile : frontendCompile;
import frontend.getHover : getHoverStr;
import frontend.getPosition : getPosition, Position;
import model.model : Module, Program;
import test.testUtil : Test;
import util.collection.arr : last, size;
import util.collection.mutDict : addToMutDict;
import util.collection.str :
	emptyStr,
	NulTerminatedStr,
	nulTerminatedStrOfCStr,
	Str,
	strEqLiteral,
	strLiteral,
	strOfNulTerminatedStr;
import util.dbg : log, logNat, logNoNewline;
import util.dictReadOnlyStorage : DictReadOnlyStorage, MutFiles;
import util.opt : force, has, Opt;
import util.path : Path, PathAndStorageKind, rootPath, StorageKind;
import util.ptr : Ptr, ptrTrustMe_const;
import util.sourceRange : Pos;
import util.sym : shortSymAlphaLiteral;
import util.util : verify, verifyFail;

@trusted void testHover(Debug, Alloc)(ref Test!(Debug, Alloc) test) {
	immutable Path path = rootPath(test.allPaths, shortSymAlphaLiteral("main"));
	immutable PathAndStorageKind key = immutable PathAndStorageKind(path, StorageKind.local);
	MutFiles files;
	immutable NulTerminatedStr contentStr = nulTerminatedStrOfCStr(content);
	addToMutDict(test.alloc, files, key, contentStr);
	DictReadOnlyStorage storage = DictReadOnlyStorage(ptrTrustMe_const(files));
	immutable Ptr!Program program =
		frontendCompile(test.alloc, test.alloc, test.allPaths, test.allSymbols, storage, path);
	immutable Ptr!Module mainModule = last(program.allModules);

	immutable(Str) hover(immutable Pos pos) {
		immutable Opt!Position position = getPosition(mainModule, pos);
		return has(position)
			? getHoverStr!(Alloc, Alloc, Alloc)(test.alloc, test.alloc, test.allPaths, program, force(position))
			: emptyStr;
	}

	void checkHover(immutable Pos pos, immutable string expected) {
		verifyStrEq(test.dbg, pos, hover(pos), expected);
	}
	void checkHoverRange(immutable Pos start, immutable Pos end, immutable string expected) {
		foreach (immutable Pos pos; start..end)
			checkHover(pos, expected);
	}

	checkHover(0, "");
	checkHoverRange(1, 13, "builtin type nat");
	// TODO: 13 (the blank line) should not have hover
	immutable Pos rStart = 14;
	verify(content[rStart] == 'r');
	immutable Pos fldStart = rStart + 10;
	checkHoverRange(rStart, fldStart, "record r");
	verify(content[fldStart] == 'f');
	checkHoverRange(fldStart, fldStart + 3, "field r.fld (nat)");
	checkHoverRange(fldStart + 3, fldStart + 7, "builtin type nat");
	checkHoverRange(fldStart + 7, fldStart + 8, "record r");
	verify(fldStart + 8 == size(strOfNulTerminatedStr(contentStr)));

	// TODO: TEST:
	// * imports (have these be actually working!)
	// * unions
	// * specs
	// * every expression
}

private:

void verifyStrEq(Debug)(ref Debug dbg, immutable Pos pos, immutable Str actual, immutable string expected) {
	if (!strEqLiteral(actual, expected)) {
		logNoNewline(dbg, strLiteral("at position "));
		logNat(dbg, pos);
		log(dbg, "\nactual:");
		log(dbg, actual);
		log(dbg, "expected:");
		log(dbg, expected);
		verifyFail();
	}
}

immutable char* content = `
nat builtin

r record
	fld nat
`;
