#! /usr/bin/env node

// @ts-ignore
require("../crow-js/crow.js")
const fs = require("fs")

const main = async () => {
	const comp = await crow.makeCompiler(fs.readFileSync('bin/crow.wasm'), "/include", "/cwd")
	const include = JSON.parse(fs.readFileSync("site/include-all.json", "utf-8"))
	for (const [path, content] of Object.entries(include)) {
		const fullPath = `/include/${path}`
		comp.setFileSuccess(fullPath, content)
		if (comp.getFile(fullPath) !== content)
			throw new Error(`Can't read back ${path}`)
	}

	const path = "demo/hello.crow"
	const content = fs.readFileSync(path, "utf-8")
	comp.setFileSuccess(path, content)
	const result = comp.run(path)
	if (result.exitCode !== 0 || !writesEqual(result.writes, [{pipe:'stdout', text:"Hello, world!\n"}])) {
		console.error(result)
		throw new Error("Bad result")
	}
}

/** @type {function(ReadonlyArray<crow.Write>, ReadonlyArray<crow.Write>): boolean} */
const writesEqual = (a, b) => {
	if (a.length !== b.length)
		return false
	for (let i = 0; i < a.length; i++)
		if (!writeEqual(nonNull(a[i]), nonNull(b[i])))
			return false
	return true
}

/** @type {function(crow.Write, crow.Write): boolean} */
const writeEqual = (a, b) =>
	a.pipe === b.pipe && a.text === b.text

/**
 * @template T
 * @param {T | null | undefined} x
 * @return {T}
 */
const nonNull = x => {
	if (x == null)
		throw new Error("Null value")
	return x
}

main().catch(e => {
	console.error("ERROR", e)
	process.exit(1)
})
