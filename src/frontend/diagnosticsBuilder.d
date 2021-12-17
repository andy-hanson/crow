module frontend.diagnosticsBuilder;

@safe @nogc pure nothrow:

import frontend.getDiagnosticSeverity : getDiagnosticSeverity;
import model.diag : Diag, Diagnostic, Diagnostics, DiagnosticWithinFile, DiagSeverity;
import util.alloc.alloc : Alloc;
import util.col.arrBuilder : add, ArrBuilder, arrBuilderClear, arrBuilderSort, arrBuilderTempAsArr, finishArr;
import util.col.fullIndexDict : fullIndexDictGet;
import util.path : comparePathAndStorageKind;
import util.sourceRange : FileAndRange, FileIndex, FilePaths;

/// Stores only diags at the highest severity seen.
struct DiagnosticsBuilder {
	private:
	DiagSeverity severity;
	// All diags have above severity
	ArrBuilder!Diagnostic diags;
}

void addDiagnostic(ref Alloc alloc, ref DiagnosticsBuilder a, immutable FileAndRange where, immutable Diag diag) {
	immutable DiagSeverity severity = getDiagnosticSeverity(diag);
	if (severity >= a.severity) {
		if (severity > a.severity) {
			arrBuilderClear(a.diags);
			a.severity = severity;
		}
		add(alloc, a.diags, immutable Diagnostic(where, diag));
	}
}

immutable(Diagnostics) finishDiagnostics(ref Alloc alloc, ref DiagnosticsBuilder a, immutable FilePaths filePaths) {
	arrBuilderSort!Diagnostic(a.diags, (ref immutable Diagnostic a, ref immutable Diagnostic b) =>
		// TOOD: sort by file position too
		comparePathAndStorageKind(
			fullIndexDictGet(filePaths, a.where.fileIndex),
			fullIndexDictGet(filePaths, b.where.fileIndex)));
	return immutable Diagnostics(a.severity, finishArr(alloc, a.diags));
}

immutable(Diagnostics) diagnosticsForFile(
	ref Alloc alloc,
	immutable FileIndex fileIndex,
	ref ArrBuilder!DiagnosticWithinFile diagnostics,
	immutable FilePaths filePaths,
) {
	DiagnosticsBuilder builder;
	addDiagnosticsForFile(alloc, builder, fileIndex, diagnostics);
	return finishDiagnostics(alloc, builder, filePaths);
}

void addDiagnosticsForFile(
	ref Alloc alloc,
	ref DiagnosticsBuilder a,
	immutable FileIndex fileIndex,
	ref ArrBuilder!DiagnosticWithinFile diagnostics,
) {
	foreach (ref const DiagnosticWithinFile diag; arrBuilderTempAsArr(diagnostics))
		addDiagnostic(alloc, a, immutable FileAndRange(fileIndex, diag.range), diag.diag);
}
