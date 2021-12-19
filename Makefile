.PHONY: debug end-to-end-test end-to-end-test-overwrite serve prepare-site test unit-test

# WARN: Does not clean `dyncall` as that takes too long to restore
# Also does not clean `node_modules` for the VSCode plugin
clean:
	rm -rf bin
	rm -f site/*.html site/*/*.html site/*/*/*.html site/*/*/*/*.html
	rm -rf temp

all: clean test lint serve

dyncall:
	hg clone https://dyncall.org/pub/dyncall/dyncall/
	cd dyncall && ./configure
	cd dyncall && make

lint-dscanner:
	dub run dscanner -- --styleCheck src/*.d src/*/*.d src/*/*/*.d

lint-imports-exports:
	rdmd script/lint.d

lint: lint-dscanner lint-imports-exports

debug: bin/crow
	gdb ./bin/crow

unit-test: bin/crow
	./bin/crow test

end-to-end-test: bin/crow
	./bin/crow run test/test.crow

end-to-end-test-overwrite: bin/crow
	./bin/crow run test/test.crow -- --overwrite-output

test: unit-test end-to-end-test

src_deps = src/*.d src/*/*.d src/*/*/*.d
cli_deps = dyncall $(src_deps)
d_flags = -betterC -preview=dip25 -preview=dip1000
app_link = -L=-ldyncall_s -L=-L./dyncall/dyncall -L=-lgccjit

app_files = src/app.d src/*/*.d src/*/*/*.d
# TODO: shouldn't need writeToC
wasm_files = src/wasm.d src/backend/mangle.d src/backend/writeToC.d src/backend/writeTypes.d src/concretize/*.d src/document/*.d src/frontend/*.d src/frontend/*/*.d src/interpret/*.d src/lib/*.d src/lower/*.d src/model/*.d src/util/*.d src/util/*/*.d

bin/crow: $(cli_deps)
	dmd -ofbin/crow $(d_flags) -debug -g $(app_files) $(app_link)
	rm bin/crow.o

d_flags_fast = $(d_flags) --enable-asserts=false --boundscheck=off

# Optimized builds are not currently used for anything
bin/crow-o2: $(cli_deps)
	ldc2 -ofbin/crow-o2 $(d_flags_fast) -O2 --d-version=TailRecursionAvialable $(app_files) $(app_link)

bin/crow-o2-debug: $(cli_deps)
	ldc2 -ofbin/crow-o2-debug $(d_flags_fast) -O2 --d-version=TailRecursionAvialable -g $(app_files) $(app_link)

# -O3 seems to have no benefit

# Unfortunately it fails with `undefined symbol: __assert` regardless of the `--checkaction` setting without `--enable-asserts=false`
# --static would be nice, but doesn't seem to work: `lld: error: unknown argument: -static`
# Need '--boundscheck=off' to avoid `undefined symbol: __assert` on D array access
wasm_flags = --enable-asserts=false --boundscheck=off

# To debug: Add `--d-debug -g`, remove `--Oz` and `-L=--strip-all`
# --Oz breaks it: CompileError: WebAssembly.instantiate(): Compiling function #6000:"_D10concretizeQm__TQrTS4util5alloc10rangeAlloc1..." failed: not enough arguments on the stack for local.set, expected 1 more @+1538610
bin/crow.wasm: $(src_deps)
	ldc2 -ofbin/crow.wasm -mtriple=wasm32-unknown-unknown-wasm $(d_flags) $(wasm_flags) $(wasm_files) -L=--strip-all
	rm bin/crow.o

ALL_INCLUDE = include/*.crow include/*/*.crow include/*/*/*.crow include/*/*/*/*.crow

bin/crow.tar.xz: bin/crow demo/* $(ALL_INCLUDE)
	tar -C .. -cJf bin/crow.tar.xz crow/bin/crow crow/demo crow/include

prepare-site: bin/crow.wasm bin/crow.tar.xz $(HTMLS)
	crow run site-src/site.crow

serve: prepare-site
	cd site && python -m SimpleHTTPServer 8080
