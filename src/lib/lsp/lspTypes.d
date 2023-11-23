module lib.lsp.lspTypes;

@safe @nogc pure nothrow:

import util.lineAndColumnGetter : LineAndCharacterRange;
import util.opt : Opt;

immutable struct ChangeEvent {
	Opt!LineAndCharacterRange range;
	string text;
}
