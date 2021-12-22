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

debug: bin/crow-debug
	gdb ./bin/crow-debug

unit-test: bin/crow
	./bin/crow test

end-to-end-test: bin/crow
	./bin/crow run test/test.crow

end-to-end-test-overwrite: bin/crow
	./bin/crow run test/test.crow -- --overwrite-output

test: unit-test end-to-end-test

src_deps = src/*.d src/*/*.d src/*/*/*.d
cli_deps = dyncall $(src_deps)
d_flags_common = -betterC -preview=dip25 -preview=dip1000
dmd_flags_assert= $(d_flags_common) -check=on -boundscheck=on
ldc_flags_assert = $(d_flags_common) --enable-asserts=true --boundscheck=on
ldc_flags_no_assert = $(d_flags_common) --enable-asserts=false --boundscheck=off
ldc_small_flags = -Oz -L=--strip-all
ldc_fast_flags = -O2 --d-version=TailRecursionAvailable
app_link = -L=-ldyncall_s -L=-L./dyncall/dyncall -L=-lgccjit

app_files = src/app.d src/*/*.d src/*/*/*.d
# TODO: shouldn't need writeToC
wasm_files = src/wasm.d src/backend/mangle.d src/backend/writeToC.d src/backend/writeTypes.d src/concretize/*.d src/document/*.d src/frontend/*.d src/frontend/*/*.d src/interpret/*.d src/lib/*.d src/lower/*.d src/model/*.d src/util/*.d src/util/*/*.d

bin/crow-debug: $(cli_deps)
	dmd -ofbin/crow-debug $(dmd_flags_assert) -debug -g $(app_files) $(app_link)
	rm bin/crow-debug.o

bin/crow: $(cli_deps)
	ldc2 -ofbin/crow $(ldc_flags_assert) $(ldc_fast_flags) $(app_files) $(app_link)
	rm bin/crow.o

# 'fast' builds not currently used for anything.
# Not much faster than with asserts.
bin/crow-fast: $(cli_deps)
	ldc2 -ofbin/crow-fast $(ldc_flags_no_assert) $(ldc_fast_flags) $(app_files) $(app_link)
	rm bin/crow-fast.o
bin/crow-fast-debug: $(cli_deps)
	ldc2 -ofbin/crow-fast-debug $(ldc_flags_no_assert) $(ldc_fast_flags) -g $(app_files) $(app_link)
	rm bin/crow-fast-debug.o

# To debug: Add `-g`, remove $(ldc_small_flags)
# Asserts don't work in WASM due to `undefined symbol: __assert`
bin/crow.wasm: $(src_deps)
	ldc2 -ofbin/crow.wasm -mtriple=wasm32-unknown-unknown-wasm $(ldc_flags_no_assert) $(ldc_small_flags) -L-allow-undefined $(wasm_files)
	rm bin/crow.o

ALL_INCLUDE = include/*.crow include/*/*.crow include/*/*/*.crow include/*/*/*/*.crow

bin/crow.tar.xz: bin/crow demo/* $(ALL_INCLUDE)
	tar -C .. -cJf bin/crow.tar.xz crow/bin/crow crow/demo crow/include

prepare-site: bin/crow.wasm bin/crow.tar.xz $(HTMLS)
	crow run site-src/site.crow

serve: prepare-site
	cd site && python -m SimpleHTTPServer 8080
