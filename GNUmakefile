# This file is for Linux.
# WARN: If editing this file, you might need to change NMakefile too.

.PHONY: confirm-upload-site debug end-to-end-test end-to-end-test-overwrite serve prepare-site show-dependencies test unit-test

# WARN: Does not clean `dyncall` as that takes too long to restore
# Also does not clean `node_modules` for the VSCode plugin
clean:
	rm -rf bin site temp

all: clean test lint serve

debug: bin/crow-debug
	gdb ./bin/crow-debug

debug-dmd: bin/crow-dmd
	gdb ./bin/crow-dmd

### test ###

test: unit-test crow-unit-tests end-to-end-test

unit-test: bin/crow-debug
	./bin/crow-debug test

crow-unit-tests: bin/crow
	./bin/crow run test/crow-unit-tests.crow
	./bin/crow run test/crow-unit-tests.crow --jit
	./bin/crow run test/crow-unit-tests.crow --aot

end-to-end-test: bin/crow
	./bin/crow run test/test-end-to-end.crow

end-to-end-test-overwrite: bin/crow
	./bin/crow run test/test-end-to-end.crow -- --overwrite-output

### external dependencies ###

dyncall:
	hg clone https://dyncall.org/pub/dyncall/dyncall/
	cd dyncall && ./configure
	cd dyncall && make

### D build ###

src_files_common = src/concretize/*.d \
	src/frontend/*.d \
	src/frontend/*/*.d \
	src/frontend/*/*/*.d \
	src/interpret/*.d \
	src/lib/*.d \
	src/lib/*/*.d \
	src/lower/*.d \
	src/model/*.d \
	src/util/*.d \
	src/util/*/*.d \
	src/versionInfo.d
app_src_no_test = src/app/*.d $(src_files_common) src/backend/*.d src/document/*.d
app_src_with_test = $(app_src_no_test) src/test/*.d
other_deps = bin/d-imports/date.txt bin/d-imports/commit-hash.txt
app_deps_no_test = $(app_src_no_test) $(other_deps) dyncall
app_deps_with_test = $(app_src_with_test) src/test/hover/* $(other_deps) dyncall

d_flags_common = -w -betterC -preview=dip1000 -preview=in -J=bin/d-imports -J=src/test -J=include
dmd_flags_common = $(d_flags_common) -version=GccJitAvailable
dmd_flags_assert = $(dmd_flags_common) -check=on -boundscheck=on
dmd_flags_debug = -debug -g -version=Debug -version=Test
ldc_flags_common = $(d_flags_common) --d-version=GccJitAvailable
ldc_flags_assert = $(ldc_flags_common) --enable-asserts=true --boundscheck=on
ldc_wasm_flags = -mtriple=wasm32-unknown-unknown-wasm -L-allow-undefined
ldc_fast_flags_no_tail_call = -O2 -L=--strip-all
ldc_fast_flags = $(ldc_fast_flags_no_tail_call) --d-version=TailRecursionAvailable
app_link = -L=-ldyncall_s -L=-ldyncallback_s -L=-ldynload_s -L=-L./dyncall/dyncall -L=-L./dyncall/dyncallback -L=-L./dyncall/dynload -L=-lgccjit

# TODO: should not need document/mangle/writeToC/writeTypes
wasm_src = src/wasm.d $(src_files_common) src/document/document.d src/backend/mangle.d src/backend/writeToC.d src/backend/writeTypes.d
wasm_deps = $(wasm_src) $(other_deps)

bin/d-imports/date.txt:
	mkdir -p bin/d-imports
	date --iso-8601 --utc > bin/d-imports/date.txt

bin/d-imports/commit-hash.txt:
	mkdir -p bin/d-imports
	git rev-parse --short HEAD > bin/d-imports/commit-hash.txt

debug_flags = --d-debug -g --d-version=Debug

bin/crow-debug: $(app_deps_with_test)
	ldc2 -ofbin/crow-debug $(ldc_flags_assert) $(debug_flags) --d-version=Test $(app_src_with_test) $(app_link)
	rm bin/crow-debug.o

# This isn't used anywhere, but you could use it to test things out quickly, since compilation with DMD is much faster.
bin/crow-dmd: $(app_deps_with_test)
	dmd -ofbin/crow-dmd -m64  $(dmd_flags_assert) -debug -g -version=Debug -version=Test $(app_src_with_test) $(app_link)
	rm -f bin/crow-dmd.o

bin/crow: $(app_deps_no_test)
	ldc2 -ofbin/crow $(ldc_flags_assert) $(ldc_fast_flags) $(app_src_no_test) $(app_link) -deps=bin/dependencies.txt
	rm bin/crow.o

# This isn't used anywhere, but you can rename the result to 'crow.wasm' to help debugging in the browser
bin/crow-debug.wasm: $(wasm_deps)
	ldc2 -ofbin/crow-debug.wasm $(debug_flags) $(ldc_flags_assert) $(ldc_wasm_flags) $(wasm_src)
	rm bin/crow-debug.o

bin/crow.wasm: $(wasm_deps)
	ldc2 -ofbin/crow.wasm $(ldc_flags_assert) $(ldc_wasm_flags) $(ldc_fast_flags_no_tail_call) $(wasm_src)
	rm bin/crow.o

ALL_INCLUDE = include/*.crow include/*/*.crow include/*/*/*.crow include/*/*/*/*.crow

### lint ###

lint: lint-basic lint-dscanner lint-d-imports-exports bin/dependencies.dot

lint-basic: bin/crow
	./bin/crow run test/lint-basic.crow

lint-dscanner:
	dub run dscanner -- --styleCheck src/*.d src/*/*.d src/*/*/*.d

lint-d-imports-exports: bin/crow
	./bin/crow run test/lint-d-imports-exports.crow

show-dependencies: bin/dependencies.svg
	open bin/dependencies.svg

bin/dependencies.svg: bin/dependencies.dot
	dot -Tsvg -o bin/dependencies.svg bin/dependencies.dot

bin/dependencies.dot: bin/crow test/dependencies.crow
	./bin/crow run test/dependencies.crow

### site ###

prepare-site: bin/crow bin/crow.wasm bin/crow.tar.xz
	bin/crow run site-src/site.crow

serve: prepare-site
	bin/crow run site-src/serve.crow

### publish ###

bin/crow.tar.xz: bin/crow bin/crow.vsix demo/* demo/*/* editor/sublime/* $(ALL_INCLUDE) libraries/* libraries/*/*
	tar --directory .. --create --xz --exclude demo/extern --file bin/crow.tar.xz crow/bin/crow crow/demo crow/editor crow/include crow/libraries

bin/crow.vsix: editor/vscode/* editor/vscode/node_modules
	cd editor/vscode && ./node_modules/vsce/vsce package --allow-missing-repository --out ../../bin/crow.vsix

editor/vscode/node_modules:
	cd editor/vscode && npm install

# `crow.zip` is uploaded by NMakefile
aws_upload_command = aws s3 sync site s3://crow-lang.org --delete --exclude "crow.zip"

confirm-upload-site:
	$(aws_upload_command) --dryrun
	@echo -n "Make these changes to crow-lang.org? [y/n] " && read ans && [ $${ans:-n} = y ]

upload-site: prepare-site confirm-upload-site
	$(aws_upload_command)
