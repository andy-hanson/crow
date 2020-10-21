module test.testLineAndColumnGetter;

@safe @nogc nothrow: // not pure

import util.alloc.stackAlloc : StackAlloc;
import util.collection.str : asCStr, NulTerminatedStr, strLiteral;
import util.io : tryReadFile;
import util.opt : force, none, Opt;
import util.lineAndColumnGetter : LineAndColumn, lineAndColumnAtPos, LineAndColumnGetter, lineAndColumnGetterForText;
import util.path : AbsolutePath, Path;
import util.ptr : Ptr, ptrTrustMe;
import util.sourceRange : Pos;
import util.sym : shortSymAlphaLiteral;

void testLineAndColumnGetter() {
	StackAlloc!("testLineAndColumnGetter", 1024 * 1024) alloc;
	immutable Path path = immutable Path(none!(Ptr!Path), shortSymAlphaLiteral("runtime"));
	immutable AbsolutePath absPath = immutable AbsolutePath(
		strLiteral("./include"),
		ptrTrustMe(path),
		strLiteral(".nz"));
	immutable Opt!NulTerminatedStr opText = tryReadFile(alloc, absPath);
	immutable NulTerminatedStr text = force(opText).str;

	immutable LineAndColumnGetter lcg = lineAndColumnGetterForText(alloc, text.str);

	immutable LineAndColumn lc = lineAndColumnAtPos(lcg, immutable Pos(2000));

	//debug {
	//	import core.stdc.stdio : printf;
	//	printf("line: %d, column: %d\n", lc.line, lc.column);
	//}
}
