const crow = {}

if (typeof window !== "undefined")
	Object.assign(window, {crow})
if (typeof global !== "undefined")
	Object.assign(global, {crow})

/** @typedef {number & {_isServer:true}} Server */

/** @typedef {number} Ptr */
/** @typedef {number} CStr */

/**
Exports of `wasm.d`:

@typedef ExportFunctions
@property {function(): number} getParameterBufferPointer
@property {function(): number} getParameterBufferSizeBytes
@property {function(): Server} newServer
@property {function(Server, CStr, CStr): void} addOrChangeFile
@property {function(Server, CStr): void} deleteFile
@property {function(Server, CStr): CStr} getFile
@property {function(Server, CStr): CStr} getTokensAndParseDiagnostics
@property {functionServer, CStr, number): CStr} getHover
@property {function(Ptr, number, Ptr, number, Server, CStr): number} run
*/

/** @typedef {ExportFunctions & {memory:WebAssembly.Memory}} Exports */

/**
@typedef DiagRange
@property {[number, number]} args
*/

/**
@typedef {
	| "fun"
	| "identifier"
	| "import"
	| "keyword"
	| "lit-num"
	| "lit-str"
	| "local"
	| "member"
	| "modifier"
	| "param"
	| "spec"
	| "struct"
	| "type-param"
	| "var-decl"
} TokenKind
*/
crow.TokenKind = {}

/**
 * @typedef Token
 * @property {TokenKind} token
 * @property {DiagRange} range
 */
crow.Token = {}

/**
 * @typedef Diagnostic
 * @property {string} message
 * @property {DiagRange} range
 */
crow.Diagnostic = {}

/**
 * @typedef TokensAndParseDiagnostics
 * @property {ReadonlyArray<Token>} tokens
 * @property {ReadonlyArray<Diagnostic>} parseDiagnostics
 */
crow.TokensAndParseDiagnostics = {}

/** @type {Promise<Compiler> | null} */
let globalCompiler = null

/** @type {function(): Promise<Compiler>} */
crow.getGlobalCompiler = async () => {
	if (globalCompiler === null)
		globalCompiler = crow.Compiler.make()
	return globalCompiler
}

/**
 * @typedef BufferSpace
 * @property {number} begin
 * @property {number} size
 */

class Allocator {
	/**
	 * @param {DataView} view
	 * @param {number} begin
	 * @param {number} size
	 */
	constructor(view, begin, size) {
		this._view = view
		this._begin = begin
		this._cur = begin
		this._end = begin + size
	}

	/**
	@param {string} str
	@return {CStr}
	*/
	writeCStr(str) {
		const res = this.reserve(str.length + 1).begin
		for (let i = 0; i < str.length; i++)
			this._view.setUint8(res + i, str.charCodeAt(i))
		this._view.setUint8(res + str.length, 0)
		const readBack = readCString(this._view, res, this._end)
		if (readBack !== str) {
			console.error("Failed to write string", {str, readBack})
			throw new Error()
		}
		return res
	}

	/**
	 * @param {number} size
	 * @return {BufferSpace}
	 */
	reserve(size) {
		if (this._cur + size > this._end)
			throw new Error("input too long")
		const res = {begin:this._cur, size}
		this._cur += size
		return res
	}

	/** @return {BufferSpace} */
	reserveRest() {
		const begin = roundUpToWord(this._cur)
		const res = {begin, size:this._end - begin}
		this._cur = this._end
		return res
	}

	clear() {
		this._cur = this._begin
	}
}

const mathFunctions = Object.fromEntries(
	["acos", "acosh", "asin", "asinh", "atan", "atanh", "atan2",
		"cos", "cosh", "round", "sin", "sinh", "sqrt", "tan", "tanh",
	].map(name => [name, Math[name]]))

class Compiler {
	/** @return {Promise<Compiler>} */
	static async make() {
		return Compiler.makeFromBytes(await (await fetch("../bin/crow.wasm")).arrayBuffer())
	}

	/**
	@param {ArrayBuffer} bytes
	@return {Promise<Compiler>}
	*/
	static async makeFromBytes(bytes) {
		const result = await WebAssembly.instantiate(bytes, {
			env: {
				getTimeNanos: () =>
					BigInt(Math.round(performance.now() * 1_000_000)),
				perfLog: (namePtr, count, nanoseconds, bytesAllocated) => {
					const name = res._readCStr(namePtr)
					console.log(`${name} x ${count} took ${nanoseconds / 1_000_000n}ms and ${bytesAllocated} bytes`)
				},
				debugLog: (str, value) => {
					console.log(res._readCStr(str), value)
				},
				verifyFail: () => {
					throw new Error("Called verifyFail!")
				},
				...mathFunctions
			}
		})
		const { exports } = result.instance
		const res = new Compiler(/** @type {Exports} */ (exports))
		return res
	}

	/**
	@param {Exports} exports
	*/
	constructor(exports) {
		this._exports = exports
		const { getParameterBufferPointer, getParameterBufferSizeBytes, memory, newServer } = exports
		this._view = new DataView(memory.buffer)
		this._paramAlloc = new Allocator(this._view, getParameterBufferPointer(), getParameterBufferSizeBytes())
		this._server = newServer()
	}

	/** @param {number} begin */
	_readCStr(begin) {
		return readCString(this._view, begin, this._exports.memory.buffer.byteLength)
	}

	/**
	@param {string} path
	@param {string} content
	@return {void}
	*/
	addOrChangeFile(path, content) {
		try {
			this._exports.addOrChangeFile(
				this._server,
				this._paramAlloc.writeCStr(path),
				this._paramAlloc.writeCStr(content))
		} finally {
			this._paramAlloc.clear()
		}
	}

	/**
	@param {string} path
	@return {void}
	*/
	deleteFile(path) {
		try {
			this._exports.deleteFile(this._server, this._paramAlloc.writeCStr(path))
		} finally {
			this._paramAlloc.clear()
		}
	}

	/**
	For debug/test.
	@param {string} path
	@return {string}
	*/
	getFile(path) {
		try {
			return this._readCStr(this._exports.getFile(this._server, this._paramAlloc.writeCStr(path)))
		} finally {
			this._paramAlloc.clear()
		}
	}

	/**
	@param {string} path
	@return {TokensAndParseDiagnostics}
	*/
	getTokensAndParseDiagnostics(path) {
		try {
			const res = JSON.parse(this._readCStr(
				this._exports.getTokensAndParseDiagnostics(this._server, this._paramAlloc.writeCStr(path))))
			return {tokens:res.tokens, parseDiagnostics:res["parse-diagnostics"]}
		} finally {
			this._paramAlloc.clear()
		}
	}

	/**
	@param {string} path
	@param {number} pos
	@return {string}
	*/
	getHover(path, pos) {
		try {
			return JSON.parse(this._readCStr(
				this._exports.getHover(this._server, this._paramAlloc.writeCStr(path), pos)
			)).hover
		} finally {
			this._paramAlloc.clear()
		}
	}

	/**
	@param {string} path
	@return {RunResult}
	*/
	run(path) {
		try {
			return JSON.parse(this._readCStr(this._exports.run(this._server, this._paramAlloc.writeCStr(path))))
		} finally {
			this._paramAlloc.clear()
		}
	}
}
crow.Compiler = Compiler

/**
Currently `includeDir` is hardcoded in the constructor in `server.d`.
TODO someday: Make this configurable.
*/
crow.includeDir = '/include'

/**
@typedef RunResult
@property {number} err
@property {string} stdout
@property {string} stderr
*/
crow.RunResult = {}

/** @type {function(DataView, number, number): string} */
const readCString = (view, begin, maxPointer) => {
	let s = ""
	let ptr;
	for (ptr = begin; ptr < maxPointer; ptr++) {
		const code = view.getUint8(ptr)
		if (code === 0)
			break
		s += String.fromCharCode(code)
	}
	if (ptr == maxPointer) {
		console.log("Trying to read a string, but it's too long", {
			bufferSize,
		})
		throw new Error("TOO LONG")
	}
	return s
}

/** @type {function(DataView, number, number): string} */
const readString = (view, buffer, bufferSize) => {
	let s = ""
	for (let i = 0; i < bufferSize; i++)
		s += String.fromCharCode(view.getUint8(buffer + i))
	return s
}

const roundUpToWord = n => {
	const diff = n % 8
	return diff === 0 ? n : n + 8 - diff
}
