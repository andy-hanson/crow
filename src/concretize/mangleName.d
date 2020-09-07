module concretize.mangleName;

@safe @nogc pure nothrow:

import util.alloc.stackAlloc : StackAlloc;
import util.bools : Bool, True;
import util.collection.arrUtil : every, map;
import util.collection.str : Str;
import util.ptr : ptrTrustMe_mut;
import util.sym : eachCharInSym, isSymOperator, shortSymAlphaLiteralValue, strOfSym, Sym, symEqLongAlphaLiteral;
import util.util : todo;
import util.writer : finishWriter, writeChar, Writer, writeStatic;

immutable(Str) mangleName(Alloc)(ref Alloc alloc, immutable Sym name) {
	Writer!Alloc writer = Writer!Alloc(ptrTrustMe_mut(alloc));
	writeMangledName(writer, name);
	immutable Str res = finishWriter(writer);
	assert(isMangledName(res));
	return res;
}

void writeMangledName(Alloc)(ref Writer!Alloc writer, immutable Sym name) {
	if (isSymOperator(name)) {
		writeStatic(writer, "_op");
		eachCharInSym(name, (immutable char c) {
			writeStatic(writer, () {
				final switch (c) {
					case '-': return "_minus";
					case '+': return "_plus";
					case '*': return "_times";
					case '/': return "_div";
					case '<': return "_less";
					case '>': return "_greater";
					case '=': return "_equal";
					case '!': return "_bang";
				}
			}());
		});
	} else {
		if (conflictsWithCName(name))
			writeChar(writer, '_');
		eachCharInSym(name, (immutable char c) {
			switch (c) {
				case '-':
					writeChar(writer, '_');
					break;
				case '?':
					writeStatic(writer, "__q");
					break;
				default:
					writeChar(writer, c);
					break;
			}
		});
	}
}

immutable(Str) mangleExternFunName(Alloc)(ref Alloc alloc, immutable Sym name) {
	StackAlloc!("mangleExternFunName", 256) tempAlloc;
	return map!(char, char, Alloc)(alloc, strOfSym(tempAlloc, name), (ref immutable char c) =>
		isMangledChar(c) ? c :
		c == '-' ? '_' :
		todo!(immutable char)("extern fun with unusual char?"));
}

immutable(Bool) isMangledName(immutable Str name) {
	return every(name, (ref immutable char c) => isMangledChar(c));
}

private:

immutable(Bool) conflictsWithCName(immutable Sym name) {
	switch (name.value) {
		case shortSymAlphaLiteralValue("default"):
		case shortSymAlphaLiteralValue("float"):
		case shortSymAlphaLiteralValue("int"):
		case shortSymAlphaLiteralValue("void"):
			return True;
		default:
			// avoid conflicting with c's "atomic_bool" type
			return symEqLongAlphaLiteral(name, "atomic-bool");
	}
}

immutable(Bool) isMangledChar(immutable char c) {
	return Bool(
		'a' <= c && c <= 'z' ||
		'A' <= c && c <= 'Z' ||
		'0' <= c && c <= '9' ||
		c == '_');
}
