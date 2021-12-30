#! /usr/bin/env node

require("../crow-js/crow.js")
const fs = require("fs")

const main = async () => {
	const comp = await compiler.Compiler.makeFromBytes(fs.readFileSync('bin/crow.wasm'))
	const include = JSON.parse(fs.readFileSync("site/include-all.json", "utf-8"))
	for (const path in include)
		comp.addOrChangeFile(StorageKind.global, path, include[path])
	const content = fs.readFileSync("demo/hello.crow", "utf-8")
	comp.addOrChangeFile(StorageKind.local, "hello", content)
	const result = comp.run('hello')

	if (result.stdout !== "Hello, world!\n" || result.err != 0 || result.stderr != '') {
		console.error(result)
		throw new Error("Bad result")
	}
}

main().catch(e => {
	console.error("ERROR", e)
})
