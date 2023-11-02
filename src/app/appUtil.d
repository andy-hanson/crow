module app.appUtil;

@safe @nogc nothrow: // not pure

import app.fileSystem : stderr;
import core.stdc.stdio : fprintf, printf;
import util.col.str : SafeCStr;
import util.exitCode : ExitCode;

@trusted ExitCode print(in SafeCStr a) {
	printf("%s\n", a.ptr);
	return ExitCode.ok;
}

@trusted ExitCode printError(in SafeCStr a) {
	fprintf(stderr, "%s\n", a.ptr);
	return ExitCode.error;
}
