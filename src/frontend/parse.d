module frontend.parse;

@safe @nogc pure nothrow:

import parseDiag : ParseDiagnostic;

import frontend.ast : FileAst;

import util.collection.str : NulTerminatedStr;
import util.result : Result;
import util.sym : AllSymbols;

immutable(Result!(FileAst, ParseDiagnostic)) parseFile(Alloc)(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	immutable NulTerminatedStr source,
) {
	assert(0); //TODO
}
