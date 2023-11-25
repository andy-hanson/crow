#! /usr/bin/env node

// @ts-ignore
require("../crow-js/crow.js")
const assert = require("assert")
const fs = require("fs")

const main = async () => {
	const comp = await crow.makeCompiler(fs.readFileSync('bin/crow.wasm'), "file:///include", "/cwd", console.log)
	const include = JSON.parse(fs.readFileSync("site/include-all.json", "utf-8"))
	for (const [path, content] of Object.entries(include)) {
		const fullPath = `file:///include/${path}`
		comp.handleLspMessage(didOpen(fullPath, content))
	}
	const MAIN = "file:///demo/hello.crow"
	comp.handleLspMessage(didOpen(MAIN, fs.readFileSync(`${__dirname}/../demo/hello.crow`, "utf-8")))

	comp.handleLspMessage(didOpen("file:///crow-config.json", "{}"))
	const {unloadedUris} = comp.handleLspMessage({method:"custom/unloadedUris", id:1, params:{}}).messages[0].result
	for (const uri of unloadedUris) {
		assert(uri.endsWith("/crow-config.json"))
		comp.handleLspMessage({method: "custom/readFileResult", params:{uri, type:"notFound"}})
	}

	const result = comp.run(MAIN)
	if (result.exitCode !== 0 || !writesEqual(result.writes, [{pipe:'stdout', text:"Hello, world!\n"}])) {
		console.error(result)
		throw new Error("Bad result")
	}
}

// TODO: share code with CrowRunnable.js
/** @type {function(string, string): unknown} */
const didOpen = (uri, text) => ({
	method: "textDocument/didOpen",
	params: {textDocument: {uri, text}},
})

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
