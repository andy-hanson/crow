.PHONY: debug doc-server test

all: test lint

doc-server: bin/noze.wasm
	python -m SimpleHTTPServer 8080

lint:
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
		src/concreteModel.d \
		src/constant.d \
		src/diag.d \
		src/lowModel.d \
		src/model.d \
		src/parseDiag.d \
		src/sexprOfConcreteModel.d \
		src/sexprOfConstant.d \
		src/sexprOfLowModel.d \
		src/sexprOfModel.d \
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
		src/diag.d \
		src/frontend/ast.d \
		src/frontend/getTokens.d \
		src/frontend/parse.d \
		src/frontend/parseExpr.d \
		src/frontend/parseType.d \
		src/frontend/lang.d \
		src/frontend/lexer.d \
		src/frontend/showDiag.d \
		src/model.d \
		src/parseDiag.d \
		src/util/alloc/alloc.d \
		src/util/alloc/globalAlloc.d \
		src/util/bitUtils.d \
		src/util/bools.d \
		src/util/collection/arr.d \
		src/util/collection/arrBuilder.d \
		src/util/collection/arrUtil.d \
		src/util/collection/dict.d \
		src/util/collection/multiDict.d \
		src/util/collection/mutArr.d \
		src/util/collection/mutSet.d \
		src/util/collection/mutSlice.d \
		src/util/collection/sortUtil.d \
		src/util/collection/str.d \
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
