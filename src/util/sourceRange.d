module util.sourceRange;

@safe @nogc pure nothrow:

struct Pos {
	uint start;
	uint end;
}

//TODO:MOVE
struct SourceRange {
	immutable Pos start;
	immutable Pos end;

	static immutable SourceRange empty = SourceRange(Pos(0), Pos(0));
}
