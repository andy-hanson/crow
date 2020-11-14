.PHONY: debug doc-server test

all: test lint

doc-server: bin/noze.wasm
	python -m SimpleHTTPServer 8080

lint:
	dub run dscanner -- --styleCheck src/*.d src/*/*.d src/*/*/*.d
	rdmd lint.d

debug: bin/noze
	gdb ./bin/noze

test: bin/noze
	./bin/noze test && ./bin/noze run test/test.nz

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
		src/frontend/*.d \
		src/model/*.d \
		src/util/alloc/globalAlloc.d \
		src/util/bitUtils.d \
		src/util/bools.d \
		src/util/cell.d \
		src/util/collection/*.d \
		src/util/comparison.d \
		src/util/diff.d \
		src/util/ptr.d \
		src/util/late.d \
		src/util/lineAndColumnGetter.d \
		src/util/memory.d \
		src/util/opt.d \
		src/util/path.d \
		src/util/result.d \
		src/util/sexpr.d \
		src/util/sourceRange.d \
		src/util/sym.d \
		src/util/types.d \
		src/util/util.d \
		src/util/writer.d \
		src/util/writerUtils.d \
		src/wasm.d
