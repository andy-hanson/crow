extern(C): // disable D mangling

//import frontend.parse : parse;

double add(double a, double b) { return a + b; }

immutable(char*) getAString() {
	return "hello world";
}

int foo() {
	enum E { a, b }
	immutable E e = E.a;
	final switch (e) {
		case E.a:
		case E.b:
			return 0;
	}
}

// seems to be the required entry point
void _start() {}
