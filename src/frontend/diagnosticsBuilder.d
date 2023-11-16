module frontend.diagnosticsBuilder;

@safe @nogc pure nothrow:

import frontend.getDiagnosticSeverity : getDiagnosticSeverity;
import model.diag : Diag, Diagnostic, Diagnostics, DiagSeverity;
import util.alloc.alloc : Alloc;
import util.col.arrBuilder : add, ArrBuilder, arrBuilderClear, arrBuilderSort, finishArr;
import util.comparison : Comparison;
import util.sourceRange : compareUriAndRange, Range, UriAndRange;
import util.uri : AllUris, Uri;

/// Stores only diags at the highest severity seen.
struct DiagnosticsBuilder {
	@safe @nogc pure nothrow:

	@disable this();

	this(return scope Alloc* a) {
		alloc = a;
	}

	private:
	Alloc* alloc;
	DiagSeverity severity;
	// All diags have above severity
	ArrBuilder!Diagnostic diags;
}

void addDiagnostic(scope ref DiagnosticsBuilder a, in UriAndRange where, Diag diag) {
	DiagSeverity severity = getDiagnosticSeverity(diag);
	if (severity >= a.severity) {
		if (severity > a.severity) {
			arrBuilderClear(a.diags);
			a.severity = severity;
		}
		add(*a.alloc, a.diags, Diagnostic(where, diag));
	}
}

Diagnostics finishDiagnostics(scope ref DiagnosticsBuilder a, in AllUris allUris) {
	arrBuilderSort!Diagnostic(a.diags, (in Diagnostic a, in Diagnostic b) =>
		compareDiagnostic(allUris, a, b));
	return Diagnostics(a.severity, finishArr(*a.alloc, a.diags));
}

struct DiagnosticsBuilderForFile {
	private:
	DiagnosticsBuilder* builder;
	Uri uri;
}

void addDiagnosticForFile(scope ref DiagnosticsBuilderForFile a, in Range range, Diag diag) {
	addDiagnostic(*a.builder, UriAndRange(a.uri, range), diag);
}

private:

Comparison compareDiagnostic(in AllUris allUris, in Diagnostic a, in Diagnostic b) =>
	compareUriAndRange(allUris, a.where, b.where);
