#! /usr/bin/env node

require("../crow-js/crow.js")
const fs = require("fs")

const main = async () => {
	const comp = await crow.Compiler.makeFromBytes(fs.readFileSync('bin/crow.wasm'))
	const include = JSON.parse(fs.readFileSync("site/include-all.json", "utf-8"))
	for (const [path, content] of Object.entries(include)) {
		const fullPath = `${crow.includeDir}/${path}`
		comp.addOrChangeFile(fullPath, content)
		if (comp.getFile(fullPath) !== content)
			throw new Error(`Can't read back ${path}`)
	}

	const path = "demo/hello.crow"
	const content = fs.readFileSync(path, "utf-8")
	comp.addOrChangeFile(path, content)
	const result = comp.run(path)
	if (result.stdout !== "Hello, world!\n" || result.err != 0 || result.stderr != '') {
		console.error(result)
		throw new Error("Bad result")
	}
}

main().catch(e => {
	console.error("ERROR", e)
	process.exit(1)
})
