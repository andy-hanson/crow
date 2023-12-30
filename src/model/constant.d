module model.constant;

@safe @nogc pure nothrow:

import model.concreteModel : ConcreteFun;
import util.col.array : arraysEqual;
import util.union_ : Union;

// WARN: The type of a constant is implicit (given by context).
// This means two constants that look equal may not be the same constant if they have different types
// (e.g., Constant.Integral has different sizes.)
// WARN: A Constant.Record is *by value* even if the record usually isn't. Use Constant.Pointer for a pointer.
immutable struct Constant {
	@safe @nogc pure nothrow:

	immutable struct ArrConstant {
		size_t typeIndex; // Index of the arr type in AllConstants
		size_t index; // Index into AllConstants#arrs for this type.
	}
	// Nul-terminated string identified only by its begin pointer.
	immutable struct CString {
		size_t index; // Index into AllConstants#cStrings
	}
	// Used for float32 / float64
	immutable struct Float {
		double value;
	}
	immutable struct FunPointer {
		ConcreteFun* fun;
	}
	// For intX, natX, and enum / flags types.
	// For a large nat, this may wrap around to negative.
	immutable struct Integral {
		long value;
	}
	// Pointer (or gc-pointer) to another constant
	immutable struct Pointer {
		size_t typeIndex;
		size_t index; // Index into AllConstants#pointers for this type
	}
	// This is a record by-value.
	immutable struct Record {
		Constant[] args;
	}
	immutable struct Union {
		size_t memberIndex;
		Constant arg;
	}
	// All 0 bits. Good for null, void, or empty value of 'extern' type.
	immutable struct Zero {}

	mixin .Union!(ArrConstant, CString, Float, FunPointer, Integral, Pointer, Record, Union*, Zero);

	// WARN: Only do this with constants known to have the same type
	bool opEquals(in Constant b) scope {
		assert(kind == b.kind);
		return matchIn!bool(
			(in Constant.ArrConstant x) =>
				b.as!(Constant.ArrConstant).index == x.index,
			(in Constant.CString x) =>
				b.as!(Constant.CString).index == x.index,
			(in Constant.Float x) =>
				//TODO: handle NaN
				b.as!(Constant.Float).value == x.value,
			(in Constant.FunPointer x) =>
				b.as!(Constant.FunPointer).fun == x.fun,
			(in Constant.Integral x) =>
				b.as!(Constant.Integral).value == x.value,
			(in Constant.Pointer x) =>
				b.as!(Constant.Pointer).index == x.index,
			(in Constant.Record ra) =>
				arraysEqual!Constant(ra.args, b.as!(Constant.Record).args),
			(in Constant.Union ua) =>
				ua.memberIndex == b.as!(Constant.Union*).memberIndex && ua.arg == b.as!(Constant.Union*).arg,
			(in Constant.Zero) =>
				true);
	}
}
static assert(Constant.sizeof <= 24);

Constant constantBool(bool b) =>
	Constant(Constant.Integral(b));

bool asBool(Constant a) {
	long value = a.as!(Constant.Integral).value;
	assert(value == 0 || value == 1);
	return value == 1;
}

Constant constantZero() =>
	Constant(Constant.Zero());
