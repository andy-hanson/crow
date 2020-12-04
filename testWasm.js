
import {Compiler, runCode} from "./noze-js/server.js"
import fs from "fs"

const TEST_SRC = fs.readFileSync("a.nz", "utf-8")

const main = async () => {
	const bytes = fs.readFileSync("bin/noze.wasm")
	const compiler = await Compiler.makeFromBytes(bytes)

	const includeList = fs.readFileSync("doc/includeList.txt", "utf-8").trim().split("\n")
	const include = Object.fromEntries(includeList.map(nameAndText))
	const runResult = runCode(compiler, include, TEST_SRC)
	console.log("RUN RESULT", runResult)
}

/** @type {function(string): [string, string]} */
const nameAndText = name =>
	[name, fs.readFileSync(`include/${name}.nz`, "utf-8")]

main().catch(e => {
	console.error("ERROR", e)
})



