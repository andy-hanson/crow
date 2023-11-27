module util.diff;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc, allocateElements, TempAlloc;
import util.col.arr : only;
import util.col.arrUtil : arrMax, arrMaxIndex, contains;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.comparison : compareSizeT;
import util.sym : AllSymbols, Sym, sym, symSize, writeSym, writeSymAndGetSize;
import util.writer : writeNewline, Writer, writeRed, writeReset, writeSpaces;
import util.util : max, todo;

void diffSymbols(
	ref TempAlloc tempAlloc,
	ref Writer writer,
	in AllSymbols allSymbols,
	bool color,
	in Sym[] a,
	in Sym[] b
) {
	printDiff(writer, allSymbols, color, a, b, longestCommonSubsequence(tempAlloc, a, b));
}

private:

ref T atPossiblyReversed(T)(scope T[] a, size_t i, bool reversed) =>
	a[reversed ? a.length - 1 - i : i];
void setAtPossiblyReversed(T)(ref T[] a, size_t i, T value, bool reversed) {
	a[reversed ? a.length - 1 - i : i] = value;
}

// Returns the maximum subsequence length between a and each prefix of b.
// (If `reversed`, this is for suffixes.)
// Result[i] is the max subseq length between a and b[0 .. i].
// 'scratch' is an input for performance -- it's treated as uninitialized.
// Based on https://www.ics.uci.edu/~dan/pubs/p341-hirschberg.pdf
void getMaximumCommonSubsequenceLengths(T)(
	in T[] a,
	in T[] b,
	scope ref size_t[] result,
	bool reversed,
) {
	// The buffers need to be 1 more than the length of b,
	// because they have an entry at size(b).
	assert(result.length == b.length + 1);

	// We are actually calculating a matrix. But we only need to store one row.
	// matrix[r][c] = maximum subsequence length of a[0 .. i] and b[0 .. j].
	// So the final row (matrix[size(a)]) is the maximum subsequence lengths given all or a, and all prefixes of b.

	// 0th row is all 0s.
	foreach (ref size_t x; result)
		x = 0;

	foreach (size_t rowI; 1 .. a.length + 1) {
		// Each row element depends on the left, up, and left-up diagonal entries.
		// So having only one row in memory at a time is tricky.
		// We want to preserve the left-up and up entries from the previous row, so we keep 'left' in a variable
		// and don't write it out until after.

		// First column is always a 0.
		size_t left = 0;
		foreach (size_t colI; 1 .. b.length + 1) {
			size_t curRowValue =
				atPossiblyReversed(a, rowI - 1, reversed) == atPossiblyReversed(b, colI - 1, reversed)
					// if a and b match here, use the diagonal
					? atPossiblyReversed(result, colI - 1, reversed) + 1
					// if a and b don't match, use the left or up value.
					: max(left, atPossiblyReversed(result, colI, reversed));
			// Now that we're done reading from result[i - 1], we can write over it.
			setAtPossiblyReversed(result, colI - 1, left, reversed);
			left = curRowValue;
		}
		setAtPossiblyReversed(result, b.length, left, reversed);
	}
}

// For each prefix and suffix of b, get the maximum common subsequence length between a and that prefix/suffix.
// Then the maximum common subsequence is where a prefix and suffix of b meet with the greatest sum of those sizes.
// Returns index to split 'b' at.
size_t findBestSplitIndex(
	in Sym[] a,
	in Sym[] b,
	ref size_t[] scratch,
) {
	size_t i = a.length / 2;
	// 1 greater because it goes from 0 to b.length inclusive
	size_t subseqsSize = b.length + 1;
	assert(scratch.length >= subseqsSize * 2);
	size_t[] leftSubsequenceLengths = scratch[0 .. subseqsSize];
	size_t[] rightSubsequenceLengths = scratch[subseqsSize .. subseqsSize * 2];
	getMaximumCommonSubsequenceLengths!Sym(a[0 .. i], b, leftSubsequenceLengths, false);
	getMaximumCommonSubsequenceLengths!Sym(a[i + 1 .. $], b, rightSubsequenceLengths, true);
	return arrMaxIndex!(size_t, size_t)(
		leftSubsequenceLengths,
		(in size_t leftLength, size_t j) =>
			// Note: rightSubsequenceLengths was computed in reverse, so 'j' is from the right here.
			leftLength + rightSubsequenceLengths[j],
		(in size_t x, in size_t y) => compareSizeT(x, y));
}

void longestCommonSubsequenceRecur(
	ref Alloc alloc,
	in Sym[] a,
	in Sym[] b,
	ref size_t[] scratch,
	ref ArrBuilder!Sym res,
) {
	if (b.length == 0) {
		// No output
	} else if (a.length == 1) {
		Sym sa = only(a);
		if (contains(b, sa))
			add(alloc, res, sa);
	} else {
		// Always slice 'a' exactly in half. Then find best way to slice 'b'.
		size_t aSplit = a.length / 2;
		size_t bSplit = findBestSplitIndex(a, b, scratch);
		longestCommonSubsequenceRecur(alloc, a[0 .. aSplit], b[0 .. bSplit], scratch, res);
		longestCommonSubsequenceRecur(alloc, a[aSplit .. $], b[bSplit .. $], scratch, res);
	}
}

@trusted Sym[] longestCommonSubsequence(ref Alloc alloc, in Sym[] a, in Sym[] b) {
	size_t[] scratch = allocateElements!size_t(alloc, (b.length + 1) * 2);
	ArrBuilder!Sym res;
	longestCommonSubsequenceRecur(alloc, a, b, scratch, res);
	return finishArr(alloc, res);
}

void printDiff(
	ref Writer writer,
	in AllSymbols allSymbols,
	bool color,
	in Sym[] a,
	in Sym[] b,
	in Sym[] commonSyms,
) {
	Sym expected = sym!"expected";
	// + 2 for a margin
	size_t columnSize = 2 + max(
		arrMax!(size_t, Sym)(0, a, (in Sym s) => symSize(allSymbols, s)),
		symSize(allSymbols, expected));

	writeNewline(writer, 1);
	writeSymPadded(writer, allSymbols, expected, columnSize);
	writer ~= "you wrote\n";

	// This gave us the list of symbols that they have in common.
	// New just walk them together.
	size_t ai = 0;
	size_t bi = 0;
	void extraA() {
		writeNewline(writer, 1);
		if (color)
			writeRed(writer);
		writeSym(writer, allSymbols, a[ai]);
		if (color)
			writeReset(writer);
		ai++;
	}
	void extraB() {
		writeNewline(writer, 1);
		writeSpaces(writer, columnSize);
		if (color)
			writeRed(writer);
		writeSym(writer, allSymbols, b[bi]);
		if (color)
			writeReset(writer);
		bi++;
	}
	void misspelling() {
		writeNewline(writer, 1);
		if (color)
			writeRed(writer);
		writeSymPadded(writer, allSymbols, a[ai], columnSize);
		writeSym(writer, allSymbols, b[bi]);
		if (color)
			writeReset(writer);
		ai++;
		bi++;
	}
	void common() {
		assert(a[ai] == b[bi]);
		writeNewline(writer, 1);
		writeSymPadded(writer, allSymbols, a[ai], columnSize);
		writeSym(writer, allSymbols, b[bi]);
		ai++;
		bi++;
	}

	foreach (Sym commonSym; commonSyms) {
		while (a[ai] != commonSym && b[bi] != commonSym)
			misspelling();
		while (a[ai] != commonSym)
			extraA();
		while (b[bi] != commonSym)
			extraB();
		common();
	}
	while (ai < a.length && bi < b.length)
		misspelling();
	while (ai < a.length)
		extraA();
	while (bi < b.length)
		extraB();
}

void writeSymPadded(scope ref Writer writer, in AllSymbols allSymbols, Sym name, size_t size) {
	size_t symSize = writeSymAndGetSize(writer, allSymbols, name);
	if (symSize >= size) todo!void("??");
	writeSpaces(writer, size - symSize);
}
