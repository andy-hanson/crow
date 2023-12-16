module app.appUtil;

@safe @nogc nothrow: // not pure

import app.fileSystem : stderr;
import core.stdc.stdio : fprintf, printf;
import util.exitCode : ExitCode;
import util.string : CString;

@trusted ExitCode print(in CString a) {
	printf("%s\n", a.ptr);
	return ExitCode.ok;
}

@trusted ExitCode printError(in CString a) {
	fprintf(stderr, "%s\n", a.ptr);
	return ExitCode.error;
}
