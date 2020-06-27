module util.sourceRange;

@safe @nogc pure nothrow:

import util.types : u32;

alias Pos = u32;

//TODO:MOVE
struct SourceRange {
	immutable Pos start;
	immutable Pos end;

	static immutable SourceRange empty = SourceRange(Pos(0), Pos(0));
}
