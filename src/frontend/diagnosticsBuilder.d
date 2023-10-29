module frontend.diagnosticsBuilder;

@safe @nogc pure nothrow:

import frontend.getDiagnosticSeverity : getDiagnosticSeverity;
import model.diag : Diag, Diagnostic, Diagnostics, DiagnosticWithinFile, DiagSeverity;
import util.alloc.alloc : Alloc;
import util.col.arrBuilder : add, ArrBuilder, arrBuilderClear, arrBuilderSort, arrBuilderTempAsArr, finishArr;
import util.comparison : Comparison;
import util.sourceRange : compareUriAndRange, UriAndRange;
import util.uri : AllUris, Uri;

/// Stores only diags at the highest severity seen.
struct DiagnosticsBuilder {
	private:
	DiagSeverity severity;
	// All diags have above severity
	ArrBuilder!Diagnostic diags;
}

void addDiagnostic(ref Alloc alloc, scope ref DiagnosticsBuilder a, UriAndRange where, Diag diag) {
	DiagSeverity severity = getDiagnosticSeverity(diag);
	if (severity >= a.severity) {
		if (severity > a.severity) {
			arrBuilderClear(a.diags);
			a.severity = severity;
		}
		add(alloc, a.diags, Diagnostic(where, diag));
	}
}

Diagnostics finishDiagnostics(ref Alloc alloc, ref DiagnosticsBuilder a, in AllUris allUris) {
	arrBuilderSort!Diagnostic(a.diags, (in Diagnostic a, in Diagnostic b) =>
		compareDiagnostic(allUris, a, b));
	return Diagnostics(a.severity, finishArr(alloc, a.diags));
}

Diagnostics diagnosticsForFile(
	ref Alloc alloc,
	in AllUris allUris,
	Uri uri,
	ref ArrBuilder!DiagnosticWithinFile diagnostics,
) {
	DiagnosticsBuilder builder;
	addDiagnosticsForFile(alloc, builder, uri, diagnostics);
	return finishDiagnostics(alloc, builder, allUris);
}

void addDiagnosticsForFile(
	ref Alloc alloc,
	scope ref DiagnosticsBuilder a,
	Uri uri,
	ref ArrBuilder!DiagnosticWithinFile diagnostics,
) {
	foreach (ref const DiagnosticWithinFile diag; arrBuilderTempAsArr(diagnostics))
		addDiagnostic(alloc, a, UriAndRange(uri, diag.range), diag.diag);
}

private:

Comparison compareDiagnostic(in AllUris allUris, in Diagnostic a, in Diagnostic b) =>
	compareUriAndRange(allUris, a.where, b.where);
