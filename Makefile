.PHONY: debug end-to-end-test end-to-end-test-overwrite serve prepare-site test unit-test

# WARN: Does not clean `dyncall` as that takes too long to restore
# Also does not clean `node_modules` for the VSCode plugin
clean:
	rm -rf bin site temp

all: clean bin/crow-debug test lint serve

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

unit-test: bin/crow-debug
	./bin/crow-debug test

end-to-end-test: bin/crow
	./bin/crow run test/test.crow

end-to-end-test-overwrite: bin/crow
	./bin/crow run test/test.crow -- --overwrite-output

test: unit-test end-to-end-test

src_files_common = src/concretize/*.d \
	src/frontend/*.d \
	src/frontend/*/*.d \
	src/interpret/*.d \
	src/lib/*.d \
	src/lower/*.d \
	src/model/*.d \
	src/util/*.d \
	src/util/*/*.d
app_src_no_test = src/app.d $(src_files_common) src/backend/*.d src/document/*.d
app_src_with_test = $(app_src_no_test) src/test/*.d
other_deps = bin/d-imports/date.txt bin/d-imports/commit-hash.txt
app_deps_no_test = $(app_src_no_test) $(other_deps) dyncall
app_deps_with_test = $(app_src_with_test) $(other_deps) dyncall
d_flags_common = -betterC -preview=dip25 -preview=dip1000 -J=bin/d-imports
dmd_flags_assert = $(d_flags_common) -check=on -boundscheck=on
dmd_flags_debug = -debug -g -version=Debug -version=Test
ldc_flags_assert = $(d_flags_common) --enable-asserts=true --boundscheck=on
ldc_flags_no_assert = $(d_flags_common) --enable-asserts=false --boundscheck=off
ldc_fast_flags = -O2 --d-version=Optimized --d-version=TailRecursionAvailable -L=--strip-all
ldc_fast_flags_no_tail_call = -O2 --d-version=Optimized -L=--strip-all
app_link = -L=-ldyncall_s -L=-L./dyncall/dyncall -L=-lgccjit

app_files_no_test = src/app.d $(src_files_no_test)
app_files_with_test = src/app.d $(src_files_with_test)
# TODO: should not need document/mangle/writeToC/writeTypes
wasm_src = src/wasm.d $(src_files_common) src/document/document.d src/backend/mangle.d src/backend/writeToC.d src/backend/writeTypes.d
wasm_deps = $(wasm_src)

bin/d-imports/date.txt:
	mkdir -p bin/d-imports
	date --iso-8601 --utc > bin/d-imports/date.txt

bin/d-imports/commit-hash.txt:
	mkdir -p bin/d-imports
	git rev-parse --short HEAD > bin/d-imports/commit-hash.txt

bin/crow-debug: $(app_deps_with_test)
	dmd -ofbin/crow-debug $(dmd_flags_assert) $(dmd_flags_debug) $(app_src_with_test) $(app_link)
	rm bin/crow-debug.o

bin/crow: $(app_deps_no_test)
	ldc2 -ofbin/crow $(ldc_flags_assert) $(ldc_fast_flags) $(app_src_no_test) $(app_link)
	rm bin/crow.o

# 'fast' builds not currently used for anything.
# Not much faster than with asserts.
bin/crow-fast: $(app_deps_no_test)
	ldc2 -ofbin/crow-fast $(ldc_flags_no_assert) $(ldc_fast_flags) $(app_src_no_test) $(app_link)
	rm bin/crow-fast.o
bin/crow-fast-debug: $(app_deps_no_test)
	ldc2 -ofbin/crow-fast-debug $(ldc_flags_no_assert) $(ldc_fast_flags) -g $(app_src_no_test) $(app_link)
	rm bin/crow-fast-debug.o

# To debug: Add `-g`, remove $(ldc_fast_flags_no_tail_call)
bin/crow.wasm: $(wasm_deps)
	ldc2 -ofbin/crow.wasm -mtriple=wasm32-unknown-unknown-wasm $(ldc_flags_no_assert) $(ldc_fast_flags_no_tail_call) -L-allow-undefined $(wasm_src)
	rm bin/crow.o

ALL_INCLUDE = include/*.crow include/*/*.crow include/*/*/*.crow include/*/*/*/*.crow

bin/crow.tar.xz: bin/crow demo/* $(ALL_INCLUDE)
	tar -C .. -cJf bin/crow.tar.xz crow/bin/crow crow/demo crow/include

prepare-site: bin/crow.wasm bin/crow.tar.xz $(HTMLS)
	crow run site-src/site.crow

serve: prepare-site
	cd site && python -m SimpleHTTPServer 8080
