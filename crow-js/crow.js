const globalCrow = {}

if (typeof window !== "undefined")
	Object.assign(window, {crow:globalCrow})
// @ts-ignore
if (typeof global !== "undefined")
	// @ts-ignore
	Object.assign(global, {crow:globalCrow})

/** @typedef {number & {_isServer:true}} Server */

/** @typedef {number} Ptr */
/** @typedef {number} CStr */

/**
Exports of `wasm.d`:

@typedef ExportFunctions
@property {function(): number} getParameterBufferPointer
@property {function(): number} getParameterBufferSizeBytes
@property {function(CStr): Server} newServer
@property {function(Server, CStr, CStr): void} addOrChangeFile
@property {function(Server, CStr): void} deleteFile
@property {function(Server, CStr): CStr} getFile
@property {function(Server, CStr): CStr} getTokensAndParseDiagnostics
@property {function(Server, CStr, number): CStr} getHover
@property {function(Server, CStr): number} run
*/

/** @typedef {ExportFunctions & {memory:WebAssembly.Memory}} Exports */

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
	].map(name => [name, /** @type {any} */ (Math)[name]]))

/** @type {crow.Write[]} */
let globalWrites = []


/**
@param {ArrayBuffer} bytes This is the content of 'crow.wasm'
@param {string} includeDir
@return {Promise<crow.Compiler>}
*/
globalCrow.makeCompiler = async (bytes, includeDir) => {
	const result = await WebAssembly.instantiate(bytes, {
		env: {
			/** @type {function(): bigint} */
			getTimeNanos: () =>
				BigInt(Math.round(performance.now() * 1_000_000)),
			/** @type {function(number, number, bigint, number): void} */
			perfLog: (namePtr, count, nanoseconds, bytesAllocated) => {
				const name = res._readCStr(namePtr)
				console.log(`${name} x ${count} took ${nanoseconds / 1_000_000n}ms and ${bytesAllocated} bytes`)
			},
			/** @type {function(number, number): void} */
			debugLog: (str, value) => {
				console.log(res._readCStr(str), value)
			},
			/** @type {function(): void} */
			verifyFail: () => {
				throw new Error("Called verifyFail!")
			},
			...mathFunctions,
			/** @type {function(number, number, number): void} */
			write: (pipe, begin, length) => {
				globalWrites.push({pipe:pipe == 0 ? "stdout" : "stderr", text:res._readString(begin, length)})
			},
			/** @type {function(...unknown[]): void} */
			__assert: (...args) => {
				console.log("ASSERT", args)
			},
		}
	})
	const { exports } = result.instance
	const res = new CompilerImpl(/** @type {Exports} */ (exports), includeDir)
	return res
}

/** @implements {crow.Compiler} */
class CompilerImpl {
	/**
	@param {Exports} exports
	@param {string} includeDir
	*/
	constructor(exports, includeDir) {
		this._exports = exports
		const { getParameterBufferPointer, getParameterBufferSizeBytes, memory, newServer } = exports
		this._view = new DataView(memory.buffer)
		this._paramAlloc = new Allocator(this._view, getParameterBufferPointer(), getParameterBufferSizeBytes())
		this._server = newServer(this._paramAlloc.writeCStr(includeDir))
		this._paramAlloc.clear()
	}

	/** @param {number} begin */
	_readCStr(begin) {
		return readCString(this._view, begin, this._exports.memory.buffer.byteLength)
	}

	/**
	@param {number} begin
	@param {number} length
	*/
	_readString(begin, length) {
		return readString(this._view, begin, length)
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
	@return {crow.TokensAndParseDiagnostics}
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
	@return {crow.RunOutput}
	*/
	run(path) {
		try {
			globalWrites = []
			const exitCode = this._exports.run(this._server, this._paramAlloc.writeCStr(path))
			return {exitCode, writes:[...globalWrites]}
		} finally {
			globalWrites = []
			this._paramAlloc.clear()
		}
	}
}

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
			begin,
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

/** @type {function(number): number} */
const roundUpToWord = n => {
	const diff = n % 8
	return diff === 0 ? n : n + 8 - diff
}
