/// <reference types="crow" />
// @ts-ignore
require("../../../crow-js/crow.js")

const fs = require("fs")
const path = require("path")

const crowDir = path.join(__dirname, "../../../")

exports.makeCompiler = () =>
	crow.makeCompiler(fs.readFileSync(path.join(crowDir, "bin/crow.wasm")), path.join(crowDir, "include"))
