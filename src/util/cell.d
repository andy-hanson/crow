module util.cell;

@safe @nogc pure nothrow:

import util.memory : initMemory;

struct Cell(T) {
	private:
	union {
		T value;
	}
}

@trusted ref const(T) cellGet(T)(ref const Cell!T cell) {
	return cell.value;
}

@trusted void cellSet(T)(ref Cell!T cell, immutable T value) {
	initMemory(&cell.value, value);
}
