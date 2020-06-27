module util.bools;

immutable(Bool) and(alias a, alias b)() {
	return a().value ? b() : False;
}

immutable(Bool) and(alias a, alias b, alias c)() {
	return a().value && b().value ? c() : False;
}

@safe @nogc pure nothrow:

struct Bool {
	bool value;

	alias value this;
}

immutable Bool False = Bool(false);
immutable Bool True = Bool(true);

immutable(Bool) and(immutable Bool a, immutable Bool b) {
	return a.value ? b : False;
}

immutable(Bool) or(immutable Bool a, immutable Bool b) {
	return a.value ? True : b;
}

immutable(Bool) not(immutable Bool a) {
	return Bool(!a.value);
}
