# Crow

TODO: Include a link to the website.
This readme describes how to contribute to crow. For information about the langauge itself, visit the website.

# Setup

Install these tools (potentially from your operating system's package manager):

* [`hg`](http://mercurial-scm.org)
* [`dmd`](https://dlang.org/download.html#dmd)
* [`ldc`](https://wiki.dlang.org/LDC).

Then run `make all`.
It will build `bin/crow` and test.

## Other dependencies

* [`node`](https://nodejs.org/en/) to build `site` and for the VSCode extension.
* [`pug`](https://pugjs.org) (`npm install -g pug`) to build `site`.
* [`python`](https://www.python.org/) for `make serve`.


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


# Working on the site

`make watch-site` will automatically build `.html` files when the corresponding `.pug` file changes.


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
