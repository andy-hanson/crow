[![Gitter](https://badges.gitter.im/crow-lang-org/community.svg)](
	https://gitter.im/crow-lang-org/community?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)

# Crow

This readme describes how to contribute to Crow.

For information about the language itself, visit the [website](https://crow-lang.org/).


# Setup

To work on Crow, you'll need these tools:

* [`git`](https://git-scm.com): Used to get this repository.
* [`hg`](https://mercurial-scm.org): Used to clone the `dyncall` library.
* [`ldc`](https://github.com/ldc-developers/ldc#installation): Used to compile `bin/crow`.
	- Don't use the Visual D installer as it uses an older compiler.
	Download the latest [release](https://github.com/ldc-developers/ldc/releases) instead.
* Also install dependencies listed on the [download](https://crow-lang.org/download.html) page.
* On Windows, use the "x64 Native Tools Command Prompt for VS 20__" (fill in the year) when running build commands.

Then run:

```sh
git clone https://github.com/andy-hanson/crow.git
cd crow
make all
```

This will build `bin/crow` (or `bin\crow.exe` on Windows), test, then serve the website on `localhost`.


# Testing

`make test` runs all tests. (Before any PR, you should run `make all` to lint as well.)

There are 2 kinds of tests:

* Unit tests in `src/test`. `make unit-test` runs these.
* End-to-end tests in the `test` directory. `make end-to-end-test` runs these.
	- If adding or changing tests, run `make end-to-end-test-overwrite`.


# Debugging

### Debugging `crow` itself (compiler or interpreter)

Use `make debug`.

### Debugging Crow code

Currently, Crow has no debugger of its own, so you'll have to compile to C and debug that.
By default, crow compiles the C code with debug symbols.

For example:

```sh
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


# Publishing

Run `make upload-site` to build and publish. This requires you to have `node` and `aws` installed.
You need to do this on both Linux and Windows. (Windows updates `crow.zip`, Linux handles everything else.)
