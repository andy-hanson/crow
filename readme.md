### Build and install

Build with `./build`.


### Debugging the compiler

`gdb app`


### Run all tests

`./run-test`

The compiler has no internal unit tests of its own.
Instead, the tests are written in noze which invokes the compiler executable.

## Debugging the compiler

`./noze print --help` is a useful command to see compiler stages.


### Debugging noze code

```
cd test
gdb test
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

`./build-wasm`
`./doc-server`

Then visit http://localhost:8080/doc .
