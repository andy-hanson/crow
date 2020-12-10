module test.testHover;

@safe @nogc nothrow: // not pure

import frontend.frontendCompile : frontendCompile;
import model.model : Program;
import test.testUtil : Test;
import util.collection.mutDict : addToMutDict;
import util.collection.str : nulTerminatedStrOfCStr;
import util.dictReadOnlyStorage : DictReadOnlyStorage, MutFiles;
import util.path : Path, PathAndStorageKind, rootPath, StorageKind;
import util.ptr : Ptr, ptrTrustMe_const;
import util.sym : shortSymAlphaLiteral;

@trusted void testHover(Alloc)(ref Test!Alloc test) {
	immutable Path path = rootPath(test.allPaths, shortSymAlphaLiteral("main"));
	immutable PathAndStorageKind key = immutable PathAndStorageKind(path, StorageKind.local);
	MutFiles files;
	addToMutDict(test.alloc, files, key, nulTerminatedStrOfCStr(content));
	DictReadOnlyStorage storage = DictReadOnlyStorage(ptrTrustMe_const(files));
	//immutable Ptr!Program programResult =
	frontendCompile(test.alloc, test.alloc, test.allPaths, test.allSymbols, storage, path);
	// TODO: the rest...
}

private:

immutable char* content = `
r record
	x nat
`;
