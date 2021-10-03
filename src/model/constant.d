module model.constant;

@safe @nogc pure nothrow:

import model.concreteModel : ConcreteFun;
import util.collection.arrUtil : eachCorresponds;
import util.ptr : Ptr, ptrEquals;
import util.util : verify;

// WARN: The type of a constant is implicit (given by context).
// This means two constants that look equal may not be the same constant if they have different types
// (e.g., Constant.Integral has different sizes.)
// WARN: A Constant.Record is *by value* even if the record usually isn't. Use Constant.Ptr for a pointer.
struct Constant {
	@safe @nogc pure nothrow:

	struct ArrConstant {
		immutable size_t typeIndex; // Index of the arr type in AllConstants
		immutable size_t index; // Index into AllConstants#arrs for this type.
	}
	struct BoolConstant { // TODO: just use Integral?
		immutable bool value;
	}
	// Nul-terminated string identified only by its begin pointer.
	struct CString {
		immutable size_t index; // Index into AllConstants#cStrings
	}
	struct FunPtr {
		immutable Ptr!ConcreteFun fun;
	}
	// For int and nat types.
	// For a large nat, this may wrap around to negative.
	struct Integral {
		immutable long value;
	}
	struct Null {}
	struct Pointer {
		immutable size_t typeIndex;
		immutable size_t index; // Index into AllConstants#pointers for this type
	}
	// This is a record by-value.
	struct Record {
		immutable Constant[] args;
	}
	struct Union {
		immutable ubyte memberIndex;
		immutable Ptr!Constant arg;
	}
	struct Void {}

	private:
	enum Kind {
		arr,
		bool_,
		cString,
		float_,
		funPtr,
		integral,
		null_,
		pointer,
		record,
		union_,
		void_,
	}
	immutable Kind kind;
	union {
		immutable ArrConstant arr_;
		immutable BoolConstant bool_;
		immutable CString cString;
		immutable double float_;
		immutable FunPtr funPtr;
		immutable Integral integral;
		immutable Null null_;
		immutable Pointer pointer;
		immutable Record record;
		immutable Union union_;
		immutable Void void_;
	}
	public:
	@trusted immutable this(immutable ArrConstant a) { kind = Kind.arr; arr_ = a; }
	immutable this(immutable BoolConstant a) { kind = Kind.bool_; bool_ = a; }
	immutable this(immutable CString a) { kind = Kind.cString; cString = a; }
	// used for both float32 and float64
	immutable this(immutable double a) { kind = Kind.float_; float_ = a; }
	immutable this(immutable FunPtr a) { kind = Kind.funPtr; funPtr = a; }
	immutable this(immutable Integral a) { kind = Kind.integral; integral = a; }
	immutable this(immutable Null a) { kind = Kind.null_; null_ = a; }
	@trusted immutable this(immutable Pointer a) { kind = Kind.pointer; pointer = a; }
	@trusted immutable this(immutable Record a) { kind = Kind.record; record = a; }
	@trusted immutable this(immutable Union a) { kind = Kind.union_; union_ = a; }
	immutable this(immutable Void a) { kind = Kind.void_; void_ = a; }
}
static assert(Constant.sizeof <= 24);

immutable(bool) asBool(ref immutable Constant a) {
	verify(a.kind == Constant.Kind.bool_);
	return a.bool_.value;
}

immutable(Constant.Integral) asIntegral(ref immutable Constant a) {
	verify(a.kind == Constant.Kind.integral);
	return a.integral;
}

immutable(Constant.Pointer) asPointer(ref immutable Constant a) {
	verify(a.kind == Constant.Kind.pointer);
	return a.pointer;
}

@trusted immutable(Constant.Record) asRecord(ref immutable Constant a) {
	verify(a.kind == Constant.Kind.record);
	return a.record;
}

@trusted immutable(Constant.Union) asUnion(ref immutable Constant a) {
	verify(a.kind == Constant.Kind.union_);
	return a.union_;
}

// WARN: Only do this with constants known to have the same type
@trusted immutable(bool) constantEqual(ref immutable Constant a, ref immutable Constant b) {
	verify(a.kind == b.kind);
	final switch (a.kind) {
		case Constant.Kind.arr:
			return a.arr_.index == b.arr_.index;
		case Constant.Kind.bool_:
			return a.bool_.value == b.bool_.value;
		case Constant.Kind.cString:
			return a.cString.index == b.cString.index;
		case Constant.Kind.float_:
			//TODO: handle NaN
			return a.float_ == b.float_;
		case Constant.Kind.funPtr:
			return ptrEquals(a.funPtr.fun, b.funPtr.fun);
		case Constant.Kind.integral:
			return a.integral.value == b.integral.value;
		case Constant.Kind.null_:
		case Constant.Kind.void_:
			return true;
		case Constant.Kind.pointer:
			return a.pointer.index == b.pointer.index;
		case Constant.Kind.record:
			return eachCorresponds!(Constant, Constant)(
				a.record.args,
				b.record.args,
				(ref immutable Constant x, ref immutable Constant y) =>
					constantEqual(x, y));
		case Constant.Kind.union_:
			return a.union_.memberIndex == b.union_.memberIndex && constantEqual(a.union_.arg, b.union_.arg);
	}
}

@trusted T matchConstant(T)(
	ref immutable Constant a,
	scope T delegate(ref immutable Constant.ArrConstant) @safe @nogc pure nothrow cbArr,
	scope T delegate(immutable Constant.BoolConstant) @safe @nogc pure nothrow cbBool,
	scope T delegate(ref immutable Constant.CString) @safe @nogc pure nothrow cbCString,
	scope T delegate(immutable double) @safe @nogc pure nothrow cbFloat,
	scope T delegate(immutable Constant.FunPtr) @safe @nogc pure nothrow cbFunPtr,
	scope T delegate(immutable Constant.Integral) @safe @nogc pure nothrow cbIntegral,
	scope T delegate(immutable Constant.Null) @safe @nogc pure nothrow cbNull,
	scope T delegate(immutable Constant.Pointer) @safe @nogc pure nothrow cbPointer,
	scope T delegate(ref immutable Constant.Record) @safe @nogc pure nothrow cbRecord,
	scope T delegate(ref immutable Constant.Union) @safe @nogc pure nothrow cbUnion,
	scope T delegate(immutable Constant.Void) @safe @nogc pure nothrow cbVoid,
) {
	final switch (a.kind) {
		case Constant.Kind.arr:
			return cbArr(a.arr_);
		case Constant.Kind.bool_:
			return cbBool(a.bool_);
		case Constant.Kind.cString:
			return cbCString(a.cString);
		case Constant.Kind.float_:
			return cbFloat(a.float_);
		case Constant.Kind.funPtr:
			return cbFunPtr(a.funPtr);
		case Constant.Kind.integral:
			return cbIntegral(a.integral);
		case Constant.Kind.null_:
			return cbNull(a.null_);
		case Constant.Kind.pointer:
			return cbPointer(a.pointer);
		case Constant.Kind.record:
			return cbRecord(a.record);
		case Constant.Kind.union_:
			return cbUnion(a.union_);
		case Constant.Kind.void_:
			return cbVoid(a.void_);
	}
}
