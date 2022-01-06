const compiler = {}

/** @typedef {number & {_isStorageKind:true}} StorageKind */
const StorageKind = {
	global: /** @type {StorageKind} */ (0),
	local: /** @type {StorageKind} */ (1),
}

if (typeof window !== "undefined")
	Object.assign(window, {compiler, StorageKind})
if (typeof global !== "undefined")
	Object.assign(global, {compiler, StorageKind})

/** @typedef {number & {_isServer:true}} Server */

/** @typedef {number} Ptr */
/** @typedef {number} CStr */

/**
@typedef ExportFunctions
@property {function(): number} getGlobalBufferSizeBytes
@property {function(): number} getGlobalBufferPtr
@property {function(Ptr, number): Server} newServer
@property {function(Server, StorageKind, CStr, CStr): void} addOrChangeFile
@property {function(Server, StorageKind, CStr): void} deleteFile
@property {function(Server, StorageKind, CStr): CStr} getFile
@property {function(Ptr, number, Server, StorageKind, CStr): CStr} getTokens
@property {function(Ptr, number, Server, StorageKind, CStr): CStr} getParseDiagnostics
@property {function(Ptr, number, Ptr, number, Server, StorageKind, CStr, number): CStr} getHover
@property {function(Ptr, number, Ptr, number, Server, CStr): number} run
*/

/** @typedef {ExportFunctions & {memory:WebAssembly.Memory}} Exports */

/**
@typedef DiagRange
@property {[number, number]} args
*/

/**
@typedef {
	| "by-val-ref"
	| "fun"
	| "identifier"
	| "import"
	| "keyword"
	| "lit-num"
	| "lit-str"
	| "local"
	| "member"
	| "param"
	| "purity"
	| "spec"
	| "struct"
	| "type-param"
} TokenKind
*/
compiler.TokenKind = {}

/**
 * @typedef Token
 * @property {TokenKind} kind
 * @property {DiagRange} range
 */
compiler.Token = {}

/**
 * @typedef Diagnostic
 * @property {string} message
 * @property {DiagRange} range
 */
compiler.Diagnostic = {}

/** @type {Promise<Compiler> | null} */
let globalCompiler = null

/** @type {function(): Promise<Compiler>} */
compiler.getGlobalCompiler = async () => {
	if (globalCompiler === null)
		globalCompiler = compiler.Compiler.make()
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
		if (readCString(this._view, res, this._end - res) !== str)
			throw new Error()
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
		const { getGlobalBufferSizeBytes, getGlobalBufferPtr, memory } = exports

		const view = new DataView(memory.buffer)
		this._view = view
		const bufferSize = getGlobalBufferSizeBytes()
		const buffer = getGlobalBufferPtr()
		this._bufferEnd = buffer + bufferSize

		const half = Math.floor(bufferSize / 2)
		this._serverRangeStart = buffer
		this._serverRangeSize = half
		this._tempAlloc = new Allocator(view, this._serverRangeStart + half, half)
		this._server = this._exports.newServer(this._serverRangeStart, this._serverRangeSize)
	}

	/** @param {number} begin */
	_readCStr(begin) {
		return readCString(this._view, begin, this._bufferEnd - begin)
	}

	/**
	@param {StorageKind} storageKind
	@param {string} path
	@param {string} content
	@return {void}
	*/
	addOrChangeFile(storageKind, path, content) {
		try {
			this._exports.addOrChangeFile(
				this._server,
				storageKind,
				this._tempAlloc.writeCStr(path),
				this._tempAlloc.writeCStr(content))
		} finally {
			this._tempAlloc.clear()
		}
	}

	/**
	@param {StorageKind} storageKind
	@param {string} path
	@return {void}
	*/
	deleteFile(storageKind, path) {
		try {
			this._exports.deleteFile(this._server, storageKind, this._tempAlloc.writeCStr(path))
		} finally {
			this._tempAlloc.clear()
		}
	}

	/**
	@param {StorageKind} storageKind
	@param {string} path
	@return {string}
	*/
	getFile(storageKind, path) {
		try {
			return this._readCStr(this._exports.getFile(this._server, storageKind, this._tempAlloc.writeCStr(path)))
		} finally {
			this._tempAlloc.clear()
		}
	}

	/**
	@param {StorageKind} storageKind
	@param {string} path
	@return {ReadonlyArray<Token>}
	*/
	getTokens(storageKind, path) {
		try {
			const pathCStr = this._tempAlloc.writeCStr(path)
			const resultBuf = this._tempAlloc.reserveRest()
			const res = this._exports.getTokens(
				resultBuf.begin,
				resultBuf.size,
				this._server,
				storageKind,
				pathCStr)
			return JSON.parse(this._readCStr(res))
		} finally {
			this._tempAlloc.clear()
		}
	}

	/**
	@param {StorageKind} storageKind
	@param {string} path
	@return {ReadonlyArray<Diagnostic>}
	*/
	getParseDiagnostics(storageKind, path) {
		try {
			const pathCStr = this._tempAlloc.writeCStr(path)
			const resultBuf = this._tempAlloc.reserveRest()
			const res = this._exports.getParseDiagnostics(
				resultBuf.begin,
				resultBuf.size,
				this._server,
				storageKind,
				pathCStr)
			return JSON.parse(this._readCStr(res))
		} finally {
			this._tempAlloc.clear()
		}
	}

	/**
	@param {StorageKind} storageKind
	@param {string} path
	@param {number} pos
	@return {string}
	*/
	getHover(storageKind, path, pos) {
		try {
			const pathCStr = this._tempAlloc.writeCStr(path)
			const resultBuf = this._tempAlloc.reserveRest()
			const res = this._exports.getHover(
				resultBuf.begin,
				resultBuf.size,
				this._server,
				storageKind,
				pathCStr,
				pos)
			return this._readCStr(res)
		} finally {
			this._tempAlloc.clear()
		}
	}

	/**
	@param {string} path
	@return {RunResult}
	*/
	run(path) {
		try {
			const pathCStr = this._tempAlloc.writeCStr(path)
			const resultBuf = this._tempAlloc.reserveRest()
			const res = this._exports.run(resultBuf.begin, resultBuf.size, this._server, pathCStr)
			return JSON.parse(this._readCStr(res))
		} finally {
			this._tempAlloc.clear()
		}
	}
}
compiler.Compiler = Compiler

/**
@typedef RunResult
@property {number} err
@property {string} stdout
@property {string} stderr
*/
compiler.RunResult = {}

/** @type {function(DataView, number, number): string} */
const readCString = (view, buffer, bufferSize) => {
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
