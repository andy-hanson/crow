### Build and install

Run `make all`. Noze will be built to `bin/noze` and tested.

### Debugging the compiler

Use `make debug`.

### Debugging noze code

Noze is easiest to debug when compiling to C. By default it compiles the C code with debug symbols.

For example:

```
noze build a.nz
gdb a
rbreak throw
run
```

### Editing

It's recommended to install the Sublime Text syntax.
This will help you get used to the language.
It also supports go-to-definition, which includes all builtin functions (including things like `+`),
so you can go to their definitions to read documentation.

```sh
bash -llc 'ln -s `pwd`/syntaxes/noze.sublime-syntax ~/.config/sublime-text-3/Packages/User/noze.sublime-syntax'
bash -llc 'ln -s `pwd`/syntaxes/tata.sublime-syntax ~/.config/sublime-text-3/Packages/User/tata.sublime-syntax'
```

## Viewing docs

(In progress)

`make doc-server`

Then in another terminal, visit http://localhost:8080/doc .


## Running tests

`make test` runs tests.
Tests generate many output files; to overwrite these files use `make test-overwrite`.
(Use `git add .` first to save the old state of files.)

