module util.alloc.mallocArena;

@safe @nogc pure nothrow:

import util.alloc.arena : Arena;
import util.alloc.mallocator : Mallocator;

alias MallocArena = Arena!Mallocator;
