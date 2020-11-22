/**
 * @typedef Exports
 * @property {function(): number} getBuffer
 * @property {function(): number} getBufferSize
 * @property {function(): void} getTokens
 * @property {function(): void} readDebugLog
 * @property {function(): void} run
 * @property {WebAssembly.Memory} memory
 */

/**
 * @typedef Range
 * @property {[number, number]} args
 */

/**
 * @typedef Token
 * @property {string} kind
 * @property {Range} range
 */
export const Token = {}

/**
 * @typedef Diagnostic
 * @property {string} message
 * @property {Range} range
 */
export const Diagnostic = {}


/** @type {Promise<Compiler> | null} */
let globalCompiler = null

/** @type {function(): Promise<Compiler>} */
export const getGlobalCompiler = async () => {
	if (globalCompiler === null)
		globalCompiler = Compiler.make()
	return globalCompiler
}

 /**
  * @typedef TokensDiags
  * @property {ReadonlyArray<Token>} tokens
  * @property {ReadonlyArray<Diagnostic>} diags
  */

export class Compiler {
	/** @return {Promise<Compiler>} */
	static async make() {
		return Compiler.makeFromBytes(await (await fetch("../bin/noze.wasm")).arrayBuffer())
	}

	/**
	 * @param {ArrayBuffer} bytes
	 * @return {Promise<Compiler>}
	 */
	static async makeFromBytes(bytes) {
		const result = await WebAssembly.instantiate(bytes, {})
		const { exports } = result.instance
		return new Compiler(/** @type {Exports} */ (exports))
	}

	/** @param {Exports} exports */
	constructor(exports) {
		/** @type {Exports} */
		this._exports = exports
		const { getBufferSize, getBuffer, memory } = exports

		const view = new DataView(memory.buffer)
		const bufferSize = getBufferSize()
		const buffer = getBuffer()
		/** @type {function(string): void} */
		this._setStr = str =>
			writeString(view, buffer, bufferSize, str)
		/** @type {function(): string} */
		this._getStr = () =>
			readString(view, buffer, bufferSize)
	}

	/**
	 * @param {"getTokens" | "run"} name
	 * @param {string} param
	 * @return {string}
	 */
	_useExports(name, param) {
		try {
			this._setStr(param)
			this._exports[name]()
		} catch (e) {
			this._exports.readDebugLog()
			console.error("Error in WASM. Debug log:", this._getStr())
			throw e
		}
		return this._getStr()
	}

	/**
	 * @param {string} src
	 * @return {TokensDiags}
	 */
	getTokens(src) {
		const json = this._useExports("getTokens", src)
		return JSON.parse(json)
	}

	/**
	 * @param {AllFiles} files
	 * @return {RunResult}
	 */
	run(files) {
		const result = this._useExports("run", JSON.stringify(files))
		return JSON.parse(result)
	}
}

/** @type {function(Compiler, Files, string): RunResult} */
export const runCode = (compiler, includeFiles, text) => {
	const allFiles = {
		include: includeFiles,
		user: {main:text}
	}
	return compiler.run(allFiles)
}

/**
 * @typedef AllFiles
 * @property {Files} include
 * @property {Files} user
 */

/**
 * @typedef RunResult
 * @property {number} err
 * @property {string} stdout
 * @property {string} stderr
 */
export const RunResult = {}

/**
 * @typedef {{readonly [name:string]: string}} Files
 */
export const Files = {}

/** @type {function(DataView, number, number, string): void} */
function writeString(view, buffer, bufferSize, str) {
	if (str.length >= bufferSize)
		throw new Error("input too long")
	for (let i = 0; i < str.length; i++)
		view.setUint8(buffer + i, str.charCodeAt(i))
	view.setUint8(buffer + str.length, 0)
}

/** @type {function(DataView, number, number): string} */
function readString(view, buffer, bufferSize) {
	let s = ""
	let i;
	for (i = 0; i < bufferSize; i++) {
		const code = view.getUint8(buffer + i)
		if (code === 0)
			break
		s += String.fromCharCode(code)
	}
	if (i == bufferSize) {
		console.log("Trying to read a string, but it's too long", {
			bufferSize,
		})
		throw new Error("TOO LONG")
	}
	return s
}
