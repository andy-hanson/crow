.PHONY: debug end-to-end-test end-to-end-test-overwrite pug-watch sdl-demo serve prepare-site test unit-test

all: test lint bin/crow.wasm sdl-demo serve

sdl-demo: bin/crow
	bin/crow run demo/sdl.crow

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
	./bin/crow run test/test.crow --out test/test.c

end-to-end-test-overwrite: bin/crow
	./bin/crow run test/test.crow --out test/test.c -- --overwrite-output

test: unit-test end-to-end-test

src_deps = src/*.d src/*/*.d src/*/*/*.d
cli_deps = dyncall $(src_deps)
d_flags = -betterC -preview=dip25 -preview=dip1000
app_link = -L=-ldyncall_s -L=-L./dyncall/dyncall

app_files = src/app.d src/*/*.d src/*/*/*.d
wasm_files = src/wasm.d src/*/*.d src/*/*/*.d

bin/crow: $(cli_deps)
	dmd -ofbin/crow $(d_flags) -debug -g $(app_files) $(app_link)

# Not currently used for anything
bin/crow-optimized: $(cli_deps)
	ldc2 -O3 --enable-asserts=false --boundscheck=off -ofbin/crow-optimized $(d_flags) $(app_files) $(app_link)

# Unfortunately it fails with `undefined symbol: __assert` regardless of the `--checkaction` setting without `--enable-asserts=false`
# --static would be nice, but doesn't seem to work: `lld: error: unknown argument: -static`
# Need '--boundscheck=off' to avoid `undefined symbol: __assert` on D array access
wasm_flags = --enable-asserts=false --boundscheck=off

bin/crow.wasm: $(src_deps)
	ldc2 -ofbin/crow.wasm -mtriple=wasm32-unknown-unknown-wasm \
		--d-debug -g $(d_flags) $(wasm_flags) $(wasm_files)

bin/crow.tar.xz: bin/crow demo/* include/* include/*/*
	tar -C .. -cJf bin/crow.tar.xz crow/bin/crow crow/demo crow/include

site/include-list.txt: bin/crow include/*.crow
	./bin/crow run script/gen-include-list.crow > site/include-list.txt

prepare-site: bin/crow.wasm site/include-list.txt bin/crow.tar.xz pug

pugs: site/documentation/compare.pug site/documentation/collection/arr.pug

site/documentation/%.pug: include/%.crow
	bin/crow doc $< --out $@



#$(pugs): site/documentation/%.pug: include/%.crow

site/%.html:

pug: site/*.pug site/*/*.pug
	pug site

pug-watch:
	# WARN: Can't introduce --pretty as that introduces whitespace which changes how things render
	pug site --watch

serve: prepare-site
	cd site && python -m SimpleHTTPServer 8080
