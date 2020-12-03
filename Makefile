.PHONY: debug doc-server test

all: test lint bin/noze.wasm

dyncall:
	hg clone https://dyncall.org/pub/dyncall/dyncall/
	cd dyncall && ./configure
	cd dyncall && make

doc/includeList.txt: include/*.nz
	ls include | cut -f 1 -d '.' > doc/includeList.txt

doc-server: doc/includeList.txt bin/noze.wasm
	python -m SimpleHTTPServer 8080

lint-js:
	cd doc/script && tsc

lint-dscanner:
	dub run dscanner -- --styleCheck src/*.d src/*/*.d src/*/*/*.d

lint-imports-exports:
	rdmd lint.d

lint: lint-js lint-dscanner lint-imports-exports

debug: bin/noze
	gdb ./bin/noze

unit-test: bin/noze
	./bin/noze test

test: unit-test
	./bin/noze run test/test.nz

test-overwrite: bin/noze
	./bin/noze run test/test.nz -- --overwrite-output

src_deps = src/*.d src/*/*.d src/*/*/*.d
cli_deps = dyncall $(src_deps)
d_flags = -betterC -preview=dip25 -preview=dip1000
app_link = -L=-ldl -L=-ldyncall_s -L=-L./dyncall/dyncall

app_files = src/app.d src/*/*.d src/*/*/*.d
wasm_files = src/wasm.d src/*.d src/*/*.d

bin/noze: $(cli_deps)
	dmd -ofbin/noze $(d_flags) -debug -g $(app_files) $(app_link)

# Not currently used for anything
bin/noze-opt: $(cli_deps)
	ldc2 -O3 --enable-asserts=false --boundscheck=off -ofbin/noze-opt $(d_flags) $(app_files) $(app_link)

bin/noze.wasm: $(src_deps)
	# Unfortunately it fails with `undefined symbol: __assert` regardless of the `--checkaction` setting without `--enable-asserts=false`
	# --static would be nice, but doesn't seem to work: `lld: error: unknown argument: -static`
	# Need '--boundscheck=off' to avoid `undefined symbol: __assert` on D array access
	ldc2 -ofbin/noze.wasm -mtriple=wasm32-unknown-unknown-wasm \
		--d-debug -g $(d_flags) --enable-asserts=false --boundscheck=off $(wasm_files)

# TODO: do as part of 'test'
test-wasm: bin/noze.wasm
	node testWasm.js

