[![Gitter](https://badges.gitter.im/crow-lang-org/community.svg)](
	https://gitter.im/crow-lang-org/community?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)

# Crow

This readme describes how to contribute to crow.

For information about the langauge itself, visit the [website](http://crow-lang.xyz/).


# Setup

Install these tools (potentially from your operating system's package manager):

* [`dmd`](https://dlang.org/download.html#dmd) (used to compile `bin/crow-debug` due to much faster compiles)
* [`git`](https://git-scm.com/) (used to get this repository)
* [`hg`](https://mercurial-scm.org) (used to clone the `dyncall` library)
* [`ldc`](https://github.com/ldc-developers/ldc#installation) (used to compile `bin/crow`).
	- `wasm-ld` may need to be installed separately (used to compile `bin/crow.wasm`)
* [`libgccjit`](https://gcc.gnu.org/onlinedocs/jit) (`bin/crow` links to this)
	- Skip this on Windows
* [`node.js](https://nodejs.org/) (used for tests of WASM module)

Then run:

```sh
git clone https://github.com/andy-hanson/crow.git
cd crow
make all
```

This will build `bin/crow` (or `bin\crow.exe` on Windows), test, then serve the website on localhost.


# Testing

`make test` runs all tests. (Before any PR, you should run `make all` to lint as well.)

There are 2 kinds of tests:

* Unit tests in `src/test`. `make unit-test` runs these.
* End-to-end tests in the `test` directory. `make end-to-end-test` runs these.

Most tests are end-to-end.
These use the test runner `test/test.crow`, written in crow,
which runs the comipler on the files in `test/compile-errors`, `test/parse-errors`, and `test/runnable`.
Each test consists of a source file (ending in `.crow`) and output files that add various extensions,
so a file `a.crow.stdout` would be an output of `a.crow`.
The test runner will fail if the output is not exactly as in the file;
if adding or changing tests, run `make end-to-end-test-overwrite`.


# Debugging

### Debugging the compiler

Use `make debug`.

### Debugging crow code

Currently crow has no debugger of its own, so you'll have to compile to C.
By default, crow compiles the C code with debug symbols.

For example:

```
crow build a.crow
gdb a
rbreak throw
run
```


# Testing compiler/interpreter performance

```sh
make bin/crow-o2-debug
mkdir perf && cd perf
valgrind --tool=callgrind -v --dump-every-bb=10000000 ../bin/crow-o2-debug run some-program.crow --interpret
kcachegrind .
```

# Editing

## VSCode

The VSCode extension supports syntax highlighting, compiler errors, and information on hover.

See instructions in `editor/crow-vscode/readme.md`.

## Sublime Text

Sublime Text has syntax support but no other support.
To install the plugin, run the following from the directory containing this readme:

```sh
bash -llc 'ln -s `pwd`/editor/sublime/crow.sublime-syntax ~/.config/sublime-text-3/Packages/User/crow.sublime-syntax'
bash -llc 'ln -s `pwd`/editor/sublime/repr.sublime-syntax ~/.config/sublime-text-3/Packages/User/repr.sublime-syntax'
```


# Viewing documentation locally

Run `make doc-server` and visit `http://localhost:8080/doc/index.html` in a browser.
