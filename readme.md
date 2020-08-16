### Build and install

Build with `./build`.


### Debugging the compiler

`gdb app`


### Editing

It's recommended to install the Sublime Text syntax.
This will help you get used to the language.
It also supports go-to-definition, which includes all builtin functions (including things like `+`),
so you can go to their definitions to read documentation.

```sh
bash -llc 'ln -s `pwd`/noze.sublime-syntax ~/.config/sublime-text-3/Packages/User/noze.sublime-syntax'
```
