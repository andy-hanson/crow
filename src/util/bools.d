module util.bools;

@safe @nogc pure nothrow:

immutable(Bool) and(alias a, alias b)() {
	return a().value ? b() : False;
}

immutable(Bool) and(alias a, alias b, alias c)() {
	return a().value && b().value ? c() : False;
}

struct Bool {
	@safe @nogc pure nothrow:

	bool value;

	alias value this;

	@disable this();
	immutable this(immutable bool v) {
		value = v;
	}
}

immutable Bool False = Bool(false);
immutable Bool True = Bool(true);

immutable(Bool) not(immutable Bool a) {
	return Bool(!a.value);
}
