module model.constant;

@safe @nogc pure nothrow:

import model.concreteModel : ConcreteFun;
import util.col.arrUtil : eachCorresponds;
import util.union_ : Union;
import util.util : verify;

// WARN: The type of a constant is implicit (given by context).
// This means two constants that look equal may not be the same constant if they have different types
// (e.g., Constant.Integral has different sizes.)
// WARN: A Constant.Record is *by value* even if the record usually isn't. Use Constant.Pointer for a pointer.
struct Constant {
	struct ArrConstant {
		immutable size_t typeIndex; // Index of the arr type in AllConstants
		immutable size_t index; // Index into AllConstants#arrs for this type.
	}
	// Nul-terminated string identified only by its begin pointer.
	struct CString {
		immutable size_t index; // Index into AllConstants#cStrings
	}
	// Used for float32 / float64
	struct Float {
		immutable double value;
	}
	struct FunPtr {
		immutable ConcreteFun* fun;
	}
	// For intX, natX, and enum / flags types.
	// For a large nat, this may wrap around to negative.
	struct Integral {
		immutable long value;
	}
	// Pointer (or gc-pointer) to another constant
	struct Pointer {
		immutable size_t typeIndex;
		immutable size_t index; // Index into AllConstants#pointers for this type
	}
	// This is a record by-value.
	struct Record {
		immutable Constant[] args;
	}
	struct Union {
		immutable size_t memberIndex;
		immutable Constant arg;
	}
	// All 0 bits. Good for null, void, or empty value of 'extern' type.
	struct Zero {}

	mixin .Union!(
		immutable ArrConstant,
		immutable CString,
		immutable Float,
		immutable FunPtr,
		immutable Integral,
		immutable Pointer,
		immutable Record,
		immutable Union*,
		immutable Zero);
}
static assert(Constant.sizeof <= 24);

immutable(Constant) constantBool(immutable bool b) =>
	immutable Constant(immutable Constant.Integral(b));

immutable(bool) asBool(immutable Constant a) {
	immutable long value = a.as!(Constant.Integral).value;
	verify(value == 0 || value == 1);
	return value == 1;
}

immutable(Constant) constantZero() =>
	immutable Constant(immutable Constant.Zero());

// WARN: Only do this with constants known to have the same type
@trusted immutable(bool) constantEqual(immutable Constant a, immutable Constant b) {
	verify(a.kind == b.kind);
	return a.match!(immutable bool)(
		(immutable Constant.ArrConstant x) =>
			b.as!(Constant.ArrConstant).index == x.index,
		(immutable Constant.CString x) =>
			b.as!(Constant.CString).index == x.index,
		(immutable Constant.Float x) =>
			//TODO: handle NaN
			b.as!(Constant.Float).value == x.value,
		(immutable Constant.FunPtr x) =>
			b.as!(Constant.FunPtr).fun == x.fun,
		(immutable Constant.Integral x) =>
			b.as!(Constant.Integral).value == x.value,
		(immutable Constant.Pointer x) =>
			b.as!(Constant.Pointer).index == x.index,
		(immutable Constant.Record ra) =>
			eachCorresponds!(Constant, Constant)(
				ra.args,
				b.as!(Constant.Record).args,
				(ref immutable Constant x, ref immutable Constant y) =>
					constantEqual(x, y)),
		(ref immutable Constant.Union ua) =>
			ua.memberIndex == b.as!(Constant.Union*).memberIndex && constantEqual(ua.arg, b.as!(Constant.Union*).arg),
		(immutable Constant.Zero) =>
			true);
}
