.PHONY: debug doc-server test

all: test lint bin/noze.wasm

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

bin/noze: src/*.d src/*/*.d src/*/*/*.d
	# Avoiding src/wasm.d
	dmd -preview=dip25 -preview=dip1000 -debug -g -ofbin/noze -betterC \
		src/app.d \
		src/cli.d \
		src/compiler.d \
		src/server.d \
		src/*/*.d \
		src/*/*/*.d \
		-I=src/ \
		-L=-ldl -L=-ldyncall_s

bin/noze.wasm: src/*.d src/*/*.d src/*/*/*.d
	# Unfortunately it fails with `undefined symbol: __assert` regardless of the `--checkaction` setting without `--enable-asserts=false`
	# --static would be nice, but doesn't seem to work: `lld: error: unknown argument: -static`
	# Need '--boundscheck=off' to avoid `undefined symbol: __assert` on D array access
	ldc2 \
		--d-debug \
		-g \
		-ofbin/noze.wasm \
		-mtriple=wasm32-unknown-unknown-wasm \
		-betterC \
		--enable-asserts=false \
		--boundscheck=off \
		src/wasm.d \
		src/backend/*.d \
		src/compiler.d \
		src/concretize/*.d \
		src/frontend/*.d \
		src/interpret/*.d \
		src/lower/*.d \
		src/model/*.d \
		src/server.d \
		src/test/*.d \
		src/util/*.d \
		src/util/*/*.d

# TODO: do as part of 'test'
test-wasm: bin/noze.wasm
	node testWasm.js

