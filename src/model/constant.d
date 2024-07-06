module model.constant;

@safe @nogc pure nothrow:

import model.concreteModel : ConcreteFun;
import util.col.array : arraysEqual, SmallArray;
import util.integralValues : IntegralValue;
import util.union_ : Union;

// WARN: The type of a constant is implicit (given by context).
// This means two constants that look equal may not be the same constant if they have different types
// (e.g., IntegralValue has different sizes.)
// WARN: A Constant.Record is *by value* even if the record usually isn't. Use Constant.Pointer for a pointer.
immutable struct Constant {
	@safe @nogc pure nothrow:

	immutable struct ArrConstant {
		uint typeIndex; // Index of the arr type in AllConstants
		uint index; // Index into AllConstants#arrs for this type.
	}
	// Nul-terminated string identified only by its begin pointer.
	immutable struct CString {
		uint index; // Index into AllConstants#cStrings
	}
	// Used for float32 / float64
	immutable struct Float {
		double value;
	}
	immutable struct FunPointer {
		ConcreteFun* fun;
	}
	// Pointer (or gc-pointer) to another constant
	immutable struct Pointer {
		uint typeIndex;
		uint index; // Index into AllConstants#pointers for this type
	}
	// This is a record by-value.
	immutable struct Record {
		SmallArray!Constant args;
	}
	immutable struct Union {
		size_t memberIndex;
		Constant arg;
	}
	// All 0 bits. Good for null, void, or empty value of 'extern' type.
	immutable struct Zero {}

	mixin .Union!(ArrConstant, CString, Float, FunPointer, IntegralValue, Pointer, Record, Union*, Zero);

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
			(in IntegralValue x) =>
				b.as!IntegralValue.value == x.value,
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
static assert(Constant.sizeof <= 16);

Constant constantBool(bool b) =>
	Constant(IntegralValue(b));

bool asBool(Constant a) {
	ulong value = a.as!IntegralValue.asUnsigned;
	assert(value == 0 || value == 1);
	return value == 1;
}

Constant constantZero() =>
	Constant(Constant.Zero());

long asInt64(Constant a) =>
	a.isA!(Constant.Zero) ? 0 : a.as!IntegralValue.asSigned;
ulong asNat64(Constant a) =>
	a.isA!(Constant.Zero) ? 0 : a.as!IntegralValue.asUnsigned;
