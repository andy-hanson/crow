# Noze

TODO: Include a link to the website.
This readme describes how to contribute to noze. For information about the langauge itself, visit the website.

# Setup

Install these tools (potentially from your operating system's package manager):

* [`hg`](http://mercurial-scm.org)
* [`dmd`](https://dlang.org/download.html#dmd)
* [`ldc`](https://wiki.dlang.org/LDC).

Then run `make all`.
Noze will be built to `bin/noze` and tested.
You can run it directly from there, or use `./run` which ensures an up-to-date build first.

## Other dependencies

* [`python`](https://www.python.org/) for `make doc-server`.
* [`node`](https://nodejs.org/en/) and [`typescript`](https://www.typescriptlang.org/) for type-checking JS code.
  (Not used as a compiler.)


# Testing

`make test` runs all tests. (Before any PR, you should run `make all` to lint as well.)

There are 2 kinds of tests:

* Unit tests in `src/test`. `make unit-test` runs these.
* End-to-end tests in the `test` directory. `make end-to-end-test` runs these.

Most tests are end-to-end.
These use the test runner `test/test.nz`, written in noze,
which runs the comipler on the files in `test/compile-errors`, `test/parse-errors`, and `test/runnable`.
Each test consists of a source file (ending in `.nz`) and output files that add various extensions,
so a file `a.nz.stdout` would be an output of `a.nz`.
The test runner will fail if the output is not exactly as in the file;
if adding or changing tests, run `make end-to-end-test-overwrite`.


# Debugging

### Debugging the compiler

Use `make debug`.

### Debugging noze code

Currently noze has no debugger of its own, so you'll have to compile to C.
By default, noze compiles the C code with debug symbols.

For example:

```
noze build a.nz
gdb a
rbreak throw
run
```



# Editing

## VSCode

The VSCode extension supports syntax highlighting, compiler errors, and information on hover.

See instructions in `noze-vscode/readme.md`.

## Sublime Text

Sublime Text has syntax support but no other support.
To install the plugin, run the following from the directory containing this readme:

```sh
bash -llc 'ln -s `pwd`/syntaxes/noze.sublime-syntax ~/.config/sublime-text-3/Packages/User/noze.sublime-syntax'
bash -llc 'ln -s `pwd`/syntaxes/tata.sublime-syntax ~/.config/sublime-text-3/Packages/User/tata.sublime-syntax'
```


# Viewing documentation locally

Run `make doc-server` and visit `http://localhost:8080/doc/index.html` in a browser.
