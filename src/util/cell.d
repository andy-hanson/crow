module util.cell;

@safe @nogc pure nothrow:

import util.memory : initMemory;

struct Cell(T) {
	private:
	union {
		T value;
	}
}

@trusted ref inout(T) cellGet(T)(ref inout Cell!T cell) =>
	cell.value;

@trusted void cellSet(T)(ref Cell!T cell, T value) {
	initMemory(&cell.value, value);
}
