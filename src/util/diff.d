module util.diff;

@safe @nogc pure nothrow:

import util.collection.arr : at, only, setAt, size;
import util.collection.arrUtil : arrMax, arrMaxIndex, contains, fillArrUninitialized;
import util.collection.arrBuilder : add, ArrBuilder, finishArr;
import util.comparison : compareSizeT;
import util.sym : shortSymAlphaLiteral, Sym, symEq, symSize, writeSym;
import util.writer : Writer, writeRed, writeReset, writeStatic;
import util.writerUtils : writeNlIndent, writeSpaces, writeSymPadded;
import util.util : max, verify;

void diffSymbols(TempAlloc, Alloc)(
	ref TempAlloc tempAlloc,
	ref Writer!Alloc writer,
	immutable bool color,
	immutable Sym[] a,
	immutable Sym[] b
) {
	printDiff(writer, color, a, b, longestCommonSubsequence(tempAlloc, a, b));
}

private:

ref immutable(T) atPossiblyReversed(T)(ref immutable T[] a, immutable size_t i, immutable bool reversed) {
	return at(a, reversed ? size(a) - 1 - i : i);
}
ref const(T) atPossiblyReversed(T)(ref const T[] a, immutable size_t i, immutable bool reversed) {
	return at(a, reversed ? size(a) - 1 - i : i);
}
void setAtPossiblyReversed(T)(
	ref T[] a,
	immutable size_t i,
	immutable T value,
	immutable bool reversed,
) {
	setAt(a, reversed ? size(a) - 1 - i : i, value);
}

// Returns the maximum subsequence length between a and each prefix of b.
// (If `reversed`, this is for suffixes.)
// Result[i] is the max subseq length between a and b[0 .. i].
// 'scratch' is an input for performance -- it's treated as uninitialized.
// Based on https://www.ics.uci.edu/~dan/pubs/p341-hirschberg.pdf
void getMaximumCommonSubsequenceLengths(T)(
	immutable T[] a,
	immutable T[] b,
	ref size_t[] result,
	immutable bool reversed,
) {
	// The buffers need to be 1 more than the length of b,
	// because they have an entry at size(b).
	verify(size(result) == size(b) + 1);

	// We are actually calculating a matrix. But we only need to store one row.
	// matrix[r][c] = maximum subsequence length of a[0 .. i] and b[0 .. j].
	// So the final row (matrix[size(a)]) is the maximum subsequence lengths given all or a, and all prefixes of b.

	// 0th row is all 0s.
	foreach (ref size_t x; result)
		x = 0;

	foreach (immutable size_t rowI; 1 .. size(a) + 1) {
		// Each row element depends on the left, up, and left-up diagonal entries.
		// So having only one row in memory at a time is tricky.
		// We want to preserve the left-up and up entries from the previous row, so we keep 'left' in a variable
		// and don't write it out until after.

		// First column is always a 0.
		size_t left = 0;
		foreach (immutable size_t colI; 1 .. size(b) + 1) {
			immutable size_t curRowValue =
				symEq(atPossiblyReversed(a, rowI - 1, reversed), atPossiblyReversed(b, colI - 1, reversed))
					// if a and b match here, use the diagonal
					? atPossiblyReversed(result, colI - 1, reversed) + 1
					// if a and b don't match, use the left or up value.
					: max(left, atPossiblyReversed(result, colI, reversed));
			// Now that we're done reading from result[i - 1], we can write over it.
			setAtPossiblyReversed(result, colI - 1, left, reversed);
			left = curRowValue;
		}
		setAtPossiblyReversed(result, size(b), left, reversed);
	}
}

// For each prefix and suffix of b, get the maximum common subsequence length between a and that prefix/suffix.
// Then the maximum common subsequence is where a prefix and suffix of b meet with the greatest sum of those sizes.
// Returns index to split 'b' at.
immutable(size_t) findBestSplitIndex(
	ref immutable Sym[] a,
	ref immutable Sym[] b,
	ref size_t[] scratch,
) {
	immutable size_t i = size(a) / 2;
	// 1 greater because it goes from 0 to size(b) inclusive
	immutable size_t subseqsSize = size(b) + 1;
	verify(size(scratch) >= subseqsSize * 2);
	size_t[] leftSubsequenceLengths = scratch[0 .. subseqsSize];
	size_t[] rightSubsequenceLengths = scratch[subseqsSize .. subseqsSize * 2];
	getMaximumCommonSubsequenceLengths!Sym(a[0 .. i], b, leftSubsequenceLengths, false);
	getMaximumCommonSubsequenceLengths!Sym(a[i + 1 .. $], b, rightSubsequenceLengths, true);
	return arrMaxIndex!(immutable size_t, size_t)(
		leftSubsequenceLengths,
		(ref const size_t leftLength, immutable size_t j) =>
			// Note: rightSubsequenceLengths was computed in reverse, so 'j' is from the right here.
			leftLength + at(rightSubsequenceLengths, j),
		(ref immutable size_t x, ref immutable size_t y) => compareSizeT(x, y));
}

void longestCommonSubsequenceRecur(Alloc)(
	ref Alloc alloc,
	immutable Sym[] a,
	immutable Sym[] b,
	ref size_t[] scratch,
	ref ArrBuilder!Sym res,
) {
	if (size(b) == 0) {
		// No output
	} else if (size(a) == 1) {
		immutable Sym sa = only(a);
		if (contains(b, sa, (ref immutable Sym x, ref immutable Sym y) => symEq(x, y)))
			add(alloc, res, sa);
	} else {
		// Always slice 'a' exactly in half. Then find best way to slice 'b'.
		immutable size_t aSplit = size(a) / 2;
		immutable size_t bSplit = findBestSplitIndex(a, b, scratch);
		longestCommonSubsequenceRecur(alloc, a[0 .. aSplit], b[0 .. bSplit], scratch, res);
		longestCommonSubsequenceRecur(alloc, a[aSplit .. $], b[bSplit .. $], scratch, res);
	}
}

@trusted immutable(Sym[]) longestCommonSubsequence(Alloc)(
	ref Alloc alloc,
	ref immutable Sym[] a,
	ref immutable Sym[] b,
) {
	size_t[] scratch = fillArrUninitialized!size_t(alloc, (size(b) + 1) * 2);
	ArrBuilder!Sym res;
	longestCommonSubsequenceRecur(alloc, a, b, scratch, res);
	return finishArr(alloc, res);
}

void printDiff(Alloc)(
	ref Writer!Alloc writer,
	immutable bool color,
	ref immutable Sym[] a,
	ref immutable Sym[] b,
	immutable Sym[] commonSyms,
) {
	immutable Sym expected = shortSymAlphaLiteral("expected");
	// + 2 for a margin
	immutable size_t columnSize = 2 + max(arrMax(0, a, (ref immutable Sym s) => symSize(s)), symSize(expected));

	writeNlIndent(writer);
	writeSymPadded(writer, expected, columnSize);
	writeStatic(writer, "you wrote\n");

	// This gave us the list of symbols that they have in common.
	// New just walk them together.
	size_t ai = 0;
	size_t bi = 0;
	void extraA() {
		writeNlIndent(writer);
		if (color)
			writeRed(writer);
		writeSym(writer, at(a, ai));
		if (color)
			writeReset(writer);
		ai++;
	}
	void extraB() {
		writeNlIndent(writer);
		writeSpaces(writer, columnSize);
		if (color)
			writeRed(writer);
		writeSym(writer, at(b, bi));
		if (color)
			writeReset(writer);
		bi++;
	}
	void misspelling() {
		writeNlIndent(writer);
		if (color)
			writeRed(writer);
		writeSymPadded(writer, at(a, ai), columnSize);
		writeSym(writer, at(b, bi));
		if (color)
			writeReset(writer);
		ai++;
		bi++;
	}
	void common() {
		verify(symEq(at(a, ai), at(b, bi)));
		writeNlIndent(writer);
		writeSymPadded(writer, at(a, ai), columnSize);
		writeSym(writer, at(b, bi));
		ai++;
		bi++;
	}

	foreach (immutable Sym commonSym; commonSyms) {
		while (!symEq(at(a, ai), commonSym) && !symEq(at(b, bi), commonSym))
			misspelling();
		while (!symEq(at(a, ai), commonSym))
			extraA();
		while (!symEq(at(b, bi), commonSym))
			extraB();
		common();
	}
	while (ai < size(a) && bi < size(b))
		misspelling();
	while (ai < size(a))
		extraA();
	while (bi < size(b))
		extraB();
}
