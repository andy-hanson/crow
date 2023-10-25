module frontend.diagnosticsBuilder;

@safe @nogc pure nothrow:

import frontend.getDiagnosticSeverity : getDiagnosticSeverity;
import model.diag : Diag, Diagnostic, Diagnostics, DiagnosticWithinFile, DiagSeverity;
import util.alloc.alloc : Alloc;
import util.col.arrBuilder : add, ArrBuilder, arrBuilderClear, arrBuilderSort, arrBuilderTempAsArr, finishArr;
import util.comparison : compareNat32, Comparison;
import util.sourceRange : FileAndRange, FileIndex, FileUris;
import util.uri : AllUris, compareUriAlphabetically;

/// Stores only diags at the highest severity seen.
struct DiagnosticsBuilder {
	private:
	DiagSeverity severity;
	// All diags have above severity
	ArrBuilder!Diagnostic diags;
}

void addDiagnostic(ref Alloc alloc, scope ref DiagnosticsBuilder a, FileAndRange where, Diag diag) {
	DiagSeverity severity = getDiagnosticSeverity(diag);
	if (severity >= a.severity) {
		if (severity > a.severity) {
			arrBuilderClear(a.diags);
			a.severity = severity;
		}
		add(alloc, a.diags, Diagnostic(where, diag));
	}
}

Diagnostics finishDiagnostics(ref Alloc alloc, ref DiagnosticsBuilder a, in AllUris allUris, in FileUris fileUris) {
	arrBuilderSort!Diagnostic(a.diags, (in Diagnostic a, in Diagnostic b) =>
		compareDiagnostic(a, b, allUris, fileUris));
	return Diagnostics(a.severity, finishArr(alloc, a.diags));
}

Diagnostics diagnosticsForFile(
	ref Alloc alloc,
	FileIndex fileIndex,
	ref ArrBuilder!DiagnosticWithinFile diagnostics,
	in AllUris allUris,
	in FileUris fileUris,
) {
	DiagnosticsBuilder builder;
	addDiagnosticsForFile(alloc, builder, fileIndex, diagnostics);
	return finishDiagnostics(alloc, builder, allUris, fileUris);
}

void addDiagnosticsForFile(
	ref Alloc alloc,
	scope ref DiagnosticsBuilder a,
	FileIndex fileIndex,
	ref ArrBuilder!DiagnosticWithinFile diagnostics,
) {
	foreach (ref const DiagnosticWithinFile diag; arrBuilderTempAsArr(diagnostics))
		addDiagnostic(alloc, a, FileAndRange(fileIndex, diag.range), diag.diag);
}

private:

Comparison compareDiagnostic(in Diagnostic a, in Diagnostic b, in AllUris allUris, in FileUris fileUris) {
	Comparison cmpUri = compareUriAlphabetically(allUris, fileUris[a.where.fileIndex], fileUris[b.where.fileIndex]);
	return cmpUri != Comparison.equal ? cmpUri : compareNat32(a.where.start, b.where.start);
}
