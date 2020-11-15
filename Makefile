.PHONY: debug doc-server test

all: test lint

doc-server: bin/noze.wasm
	python -m SimpleHTTPServer 8080

lint:
	dub run dscanner -- --styleCheck src/*.d src/*/*.d src/*/*/*.d
	rdmd lint.d

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
	dmd -debug -g -ofbin/noze -betterC \
		src/app.d \
		src/cli.d \
		src/compiler.d \
		src/*/*.d \
		src/*/*/*.d \
		-I=src/ \
		-L=-ldl -L=-ldyncall_s

bin/noze.wasm: src/**/*.d
	# Unfortunately it fails with `undefined symbol: __assert` regardless of the `--checkaction` setting without `--enable-asserts=false`
	# --static would be nice, but doesn't seem to work: `lld: error: unknown argument: -static`
	ldc2 \
		-g \
		-ofbin/noze.wasm \
		-mtriple=wasm32-unknown-unknown-wasm \
		-betterC \
		--enable-asserts=false \
		src/wasm.d \
		src/compiler.d \
		src/*/*.d \
		src/*/*/*.d \
