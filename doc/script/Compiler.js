const compiler = {}

/** @typedef {number & {_isStorageKind:true}} StorageKind */
const StorageKind = {
	global: /** @type {StorageKind} */ (0),
	local: /** @type {StorageKind} */ (1),
}
console.log("YOU GOT HERE!!")

if (typeof window !== "undefined")
	Object.assign(window, {compiler, StorageKind})
if (typeof global !== "undefined")
	Object.assign(global, {compiler, StorageKind})

/** @typedef {number & {_isServer:true}} Server */

/** @typedef {number} Ptr */

/**
@typedef ExportFunctions
@property {function(): number} getGlobalBufferSize
@property {function(): number} getGlobalBufferPtr
@property {function(Ptr, number): Server} newServer
@property {function(Server, StorageKind, Ptr, number, Ptr, number): void} addOrChangeFile
@property {function(Server, StorageKind, Ptr, number): void} deleteFile
@property {function(Server, StorageKind, Ptr, number): number} getFile
@property {function(Ptr, number, Server, StorageKind, Ptr, number): number} getTokens
@property {function(Ptr, number, Server, StorageKind, Ptr, number): number} getParseDiagnostics
@property {function(Ptr, number, Server, Ptr, number, Ptr, number): number} run
*/

/** @typedef {ExportFunctions & {memory:WebAssembly.Memory}} Exports */

/**
@typedef DiagRange
@property {[number, number]} args
*/

/**
@typedef {
	| "by-val-ref"
	| "field-def"
	| "field-ref"
	| "fun-def"
	| "fun-ref"
	| "identifier"
	| "import"
	| "keyword"
	| "lit-num"
	| "lit-str"
	| "local-def"
	| "param-def"
	| "purity"
	| "spec-def"
	| "spec-ref"
	| "struct-def"
	| "struct-ref"
	| "tparam-def"
	| "tparam-ref"
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
	@return {BufferSpace}
	*/
	writeString(str) {
		if (this._cur + str.length > this._end)
			throw new Error("input too long")
		for (let i = 0; i < str.length; i++)
			this._view.setUint8(this._cur + i, str.charCodeAt(i))
		const res = {begin:this._cur, size:str.length}
		this._cur += str.length
		return res
	}

	/** @return {BufferSpace} */
	reserveRest() {
		const res = {begin:this._cur, size:this._end - this._cur}
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
		return Compiler.makeFromBytes(await (await fetch("../bin/noze.wasm")).arrayBuffer())
	}

	/**
	@param {ArrayBuffer} bytes
	@return {Promise<Compiler>}
	*/
	static async makeFromBytes(bytes) {
		const result = await WebAssembly.instantiate(bytes, {})
		const { exports } = result.instance
		return new Compiler(/** @type {Exports} */ (exports))
	}

	/**
	@param {Exports} exports
	*/
	constructor(exports) {
		this._exports = exports
		const { getGlobalBufferSize, getGlobalBufferPtr, memory } = exports

		const view = new DataView(memory.buffer)
		this._view = view
		const bufferSize = getGlobalBufferSize()
		const buffer = getGlobalBufferPtr()
		this._bufferEnd = buffer + bufferSize

		const quarter = bufferSize / 4
		this._serverRangeStart = buffer
		this._serverRangeSize = quarter
		this._server = this._exports.newServer(this._serverRangeStart, this._serverRangeSize)

		this._tempAlloc = new Allocator(view, this._serverRangeStart + quarter, quarter)
	}

	/** @param {number} begin */
	_readCStr(begin) {
		return readString(this._view, begin, this._bufferEnd - begin)
	}

	/**
	@param {StorageKind} storageKind
	@param {string} path
	@param {string} content
	@return {void}
	*/
	addOrChangeFile(storageKind, path, content) {
		try {
			const pathBuf = this._tempAlloc.writeString(path)
			const contentBuf = this._tempAlloc.writeString(content)
			this._exports.addOrChangeFile(
				this._server,
				storageKind,
				pathBuf.begin,
				pathBuf.size,
				contentBuf.begin,
				contentBuf.size)
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
			const pathBuf = this._tempAlloc.writeString(path)
			this._exports.deleteFile(this._server, storageKind, pathBuf.begin, pathBuf.size)
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
			const pathBuf = this._tempAlloc.writeString(path)
			return this._readCStr(this._exports.getFile(this._server, storageKind, pathBuf.begin, pathBuf.size))
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
			const pathBuf = this._tempAlloc.writeString(path)
			const resultBuf = this._tempAlloc.reserveRest()
			const res = this._exports.getTokens(
				resultBuf.begin,
				resultBuf.size,
				this._server,
				storageKind,
				pathBuf.begin,
				pathBuf.size)
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
			const pathBuf = this._tempAlloc.writeString(path)
			const resultBuf = this._tempAlloc.reserveRest()
			const res = this._exports.getParseDiagnostics(
				resultBuf.begin,
				resultBuf.size,
				this._server,
				storageKind,
				pathBuf.begin,
				pathBuf.size)
			return JSON.parse(this._readCStr(res))
		} finally {
			this._tempAlloc.clear()
		}
	}

	/**
	@param {AllFiles} files
	@return {Promise<RunResult>}
	*/
	/*run(files) {
		return delay(() => {
			const result = this._useExports("run", JSON.stringify(files))
			return JSON.parse(result)
		})
	}*/

	/**
	@param {string} file
	@return {Promise<RunResult>}
	*/
	/*runFile(file) {
		return this.run({include:this._includeFiles, user:{main:file}})
	}*/
}
compiler.Compiler = Compiler

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
@typedef AllFiles
@property {Files} include
@property {Files} user
*/

/**
@typedef RunResult
@property {number} err
@property {string} stdout
@property {string} stderr
*/
compiler.RunResult = {}

/** @typedef {{readonly [name:string]: string}} Files */
compiler.Files = {}

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
@template T
@param {() => T} cb
@return {Promise<T>}
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
