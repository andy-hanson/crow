module frontend.ide.getRename;

@safe @nogc pure nothrow:

import frontend.ide.getTarget : Target, targetForPosition;
import frontend.ide.ideUtil : ReferenceCb;
import frontend.ide.position : Position;
import frontend.ide.getReferences : eachReferenceForTarget;
import lib.lsp.lspTypes : TextEdit, WorkspaceEdit;
import model.model : Program;
import util.alloc.alloc : Alloc;
import util.col.multiMap : makeMultiMap, MultiMapCb;
import util.col.str : copyStr;
import util.opt : force, has, none, Opt, some;
import util.sourceRange : UriAndRange;
import util.sym : AllSymbols;
import util.uri : AllUris, Uri;

Opt!WorkspaceEdit getRenameForPosition(
	ref Alloc alloc,
	scope ref AllSymbols allSymbols,
	in AllUris allUris,
	in Program program,
	in Position pos,
	in string newName,
) {
	Opt!Target target = targetForPosition(program, pos.kind);
	return has(target)
		? some(WorkspaceEdit(makeMultiMap!(Uri, TextEdit)(alloc, (in MultiMapCb!(Uri, TextEdit) cb) {
			string newNameOut = copyStr(alloc, newName);
			eachRenameLocation(allSymbols, allUris, program, pos.module_.uri, force(target), (in UriAndRange x) {
				cb(x.uri, TextEdit(x.range, newNameOut));
			});
		})))
		: none!WorkspaceEdit;
}

private:

void eachRenameLocation(
	scope ref AllSymbols allSymbols,
	in AllUris allUris,
	in Program program,
	Uri curUri,
	in Target target,
	in ReferenceCb cb,
) {
	//eachImportLocation(..., cb);
	eachReferenceForTarget(allSymbols, allUris, program, curUri, target, cb);
}
