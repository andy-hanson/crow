/**
 * @typedef Exports
 * @property {function(): number} getBufferSize
 * @property {function(): number} getBuffer
 * @property {function(): void} getTokens
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

 /**
  * @typedef TokensDiags
  * @property {ReadonlyArray<Token>} tokens
  * @property {ReadonlyArray<Diagnostic>} diags
  */

export class Compiler {
	static async make() {
		const bytes = await (await fetch("../bin/noze.wasm")).arrayBuffer()
		const result = await WebAssembly.instantiate(bytes, {})
		const { exports } = result.instance;
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
	 * @param {string} src
	 * @return {TokensDiags}
	 */
	getTokens(src) {
		this._setStr(src)
		this._exports.getTokens()
		const json = this._getStr()
		console.log("GOT JSON", json)
		return JSON.parse(json)
	}

	/**
	 * @param {AllFiles} files
	 * @return {RunResult}
	 */
	run(files) {
		console.log("RUN", JSON.stringify(files))
		this._setStr(JSON.stringify(files))
		this._exports.run()
		return JSON.parse(this._getStr())
	}
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

/**
 * @typedef AllContainer
 * @property {"all"} type
 * @property {Array<Node>} children
 */

/**
 * @typedef LineContainer
 * @property {"line"} type
 * @property {Array<Node>} children
 */

/**
 * @typedef DiagContainer
 * @property {"diag"} type
 * @property {Array<Node>} children
 * @property {number} end
 * @property {string} message
 */

/**
 * @typedef {AllContainer | LineContainer | DiagContainer} Container
 */
export const Container = {}

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
	if (i == bufferSize)
		throw new Error("TOO LONG")
	return s
}
