module interpret.types;

@safe @nogc pure nothrow:

import interpret.bytecode : Operation;
import util.col.stack : Stack;

alias DataStack = Stack!ulong;
alias ReturnStack = Stack!(immutable(Operation)*);
