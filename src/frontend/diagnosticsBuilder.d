module frontend.diagnosticsBuilder;

@safe @nogc pure nothrow:

import frontend.getDiagnosticSeverity : getDiagnosticSeverity;
import model.diag : Diag, Diagnostic, Diagnostics, DiagSeverity;
import util.alloc.alloc : Alloc;
import util.collection.arrBuilder : add, ArrBuilder, arrBuilderClear, arrBuilderSort, finishArr;
import util.collection.fullIndexDict : fullIndexDictGet;
import util.path : comparePathAndStorageKind;
import util.sourceRange : FileAndRange, FilePaths;

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
