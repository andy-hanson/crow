[![Gitter](https://badges.gitter.im/crow-lang-org/community.svg)](
	https://gitter.im/crow-lang-org/community?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)

# Crow

This readme describes how to contribute to Crow.

For information about the language itself, visit the [website](https://crow-lang.org/).


# Setup

To work on Crow, you'll need these tools:

* [`git`](https://git-scm.com): Used to get this repository
* [`hg`](https://mercurial-scm.org): Used to clone the `dyncall` library
* [`ldc`](https://github.com/ldc-developers/ldc#installation): Used to compile `bin/crow`.
	- Don't use the Visual D installer as it uses an older compiler.
	  Download the latest [release](https://github.com/ldc-developers/ldc/releases) instead.
* [`node.js`](https://nodejs.org/): Used for tests of the WASM module

Linux only:

* [`libgccjit`](https://gcc.gnu.org/onlinedocs/jit) (`bin/crow` links to this)
* [`libunwind`](https://www.nongnu.org/libunwind)

Windows only:


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

## Linux

```sh
make bin/crow-fast-debug
mkdir perf && cd perf
valgrind --tool=callgrind -v --dump-every-bb=10000000 ../bin/crow-fast-debug run some-program.crow --interpret
kcachegrind .
```

## Windows

Haven't tested this yet.

# Editing

## Sublime Text

To get syntax highlighting in Sublime Text, run the following from the directory containing this readme:

```sh
bash -llc 'ln -s `pwd`/editor/sublime/crow.sublime-syntax ~/.config/sublime-text/Packages/User/crow.sublime-syntax'
```

Or on Windows:

```sh
copy %CD%\editor\sublime\crow.sublime-syntax ^
	"%USERPROFILE%\AppData\Roaming\Sublime Text\Packages\User\crow.sublime-syntax"
```

Then open a Crow file. In the lower-right corner, click "Plain text" and change it to "Crow".

# Viewing documentation locally

Run `make doc-server` and visit `http://localhost:8080/doc/index.html` in a browser.
