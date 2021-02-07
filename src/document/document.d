module document.document;

@safe @nogc pure nothrow:

import model.model : Module, NameReferents;
import util.collection.dict : dictEach;
import util.ptr : ptrTrustMe_mut;
import util.sym : compareSym, Sym, writeSym;
import util.writer : finishWriter, Writer, writeStatic;

immutable(string) document(Alloc)(ref Alloc alloc, ref immutable Module a) {
	Writer!Alloc writer = Writer!Alloc(ptrTrustMe_mut(alloc));
	dictEach!(Sym, NameReferents, compareSym)(
		a.allExportedNames,
		(ref immutable Sym name, ref immutable NameReferents referents) {
			writeStatic(writer, "Export: ");
			writeSym(writer, name);
			writeStatic(writer, "\n");
		});
	return finishWriter(writer);
}
