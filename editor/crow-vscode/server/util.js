/// <reference types="crow" />
// @ts-ignore
require("../../../crow-js/crow.js")

const fs = require("fs")
const path = require("path")

const crowDir = path.join(__dirname, "../../../")

/** @type {function(): Promise<crow.Compiler>} */
exports.makeCompiler = () =>
	crow.makeCompiler(
		fs.readFileSync(path.join(crowDir, "bin/crow.wasm")),
		path.join(crowDir, "include"),
		// TODO: get the real CWD from VSCode API
		crowDir)

/**
 * @template T
 * @param {T | null | undefined} x
 * @return {T}
 */
exports.nonNull = x => {
	if (x == null)
		throw new Error("Null value")
	return x
}
