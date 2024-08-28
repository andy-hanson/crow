serve: index.js
	./main.crow

index.js: index.crow model.crow
	rm -f index.js
	crow build index.crow --out index.js
