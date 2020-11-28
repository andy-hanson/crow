const compiler = {}

if (typeof window !== "undefined")
	(/** @type {any} */ (window)).compiler = compiler
if (typeof global !== "undefined")
	(/** @type {any} */ (global)).compiler = compiler

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
 * @typedef DiagRange
 * @property {[number, number]} args
 */

/**
 * @typedef Token
 * @property {string} kind
 * @property {DiagRange} range
 */
compiler.Token = {}

/**
 * @typedef Diagnostic
 * @property {string} message
 * @property {DiagRange} range
 */
compiler.Diagnostic = {}


/** @type {Promise<compiler.Compiler> | null} */
let globalCompiler = null

/** @type {function(): Promise<compiler.Compiler>} */
compiler.getGlobalCompiler = async () => {
	if (globalCompiler === null)
		globalCompiler = compiler.Compiler.make()
	return globalCompiler
}

 /**
  * @typedef TokensDiags
  * @property {ReadonlyArray<Token>} tokens
  * @property {ReadonlyArray<Diagnostic>} diags
  */

compiler.Compiler = class Compiler {
	/** @return {Promise<Compiler>} */
	static async make() {
		const includeFiles = await getIncludeFiles()
		return Compiler.makeFromBytes(await (await fetch("../bin/noze.wasm")).arrayBuffer(), includeFiles)
	}

	/**
	 * @param {ArrayBuffer} bytes
	 * @param {Files} includeFiles
	 * @return {Promise<Compiler>}
	 */
	static async makeFromBytes(bytes, includeFiles) {
		const result = await WebAssembly.instantiate(bytes, {})
		const { exports } = result.instance
		return new Compiler(/** @type {Exports} */ (exports), includeFiles)
	}

	/**
	 * @param {Exports} exports
	 * @param {Files} includeFiles
	 */
	constructor(exports, includeFiles) {
		this._exports = exports
		this._includeFiles = includeFiles
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
	 * @return {Promise<RunResult>}
	 */
	run(files) {
		return delay(() => {
			const result = this._useExports("run", JSON.stringify(files))
			return JSON.parse(result)
		})
	}

	/**
	 * @param {string} file
	 * @return {Promise<RunResult>}
	 */
	runFile(file) {
		return this.run({include:this._includeFiles, user:{main:file}})
	}
}

/** @type {function(): Promise<ReadonlyArray<string>>} */
const listInclude = async () => {
	return (await (await fetch('includeList.txt')).text()).trim().split('\n')
}

/** @type {function(): Promise<Files>} */
const getIncludeFiles = async () =>
	Object.fromEntries(await Promise.all((await listInclude()).map(nameAndText)))

/** @type {function(string): Promise<[string, string]>} */
const nameAndText = async name =>
	[name, await (await fetch(`../include/${name}.nz`)).text()]


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
compiler.RunResult = {}

/**
 * @typedef {{readonly [name:string]: string}} Files
 */
compiler.Files = {}

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

/**
 * @template T
 * @param {() => T} cb
 * @return {Promise<T>}
 */
const delay = async cb => {
	return new Promise((resolve, reject) => {
		setTimeout(() => {
			try {
				resolve(cb())
			} catch (e) {
				reject(e)
			}
		}, 0)
	})
}
