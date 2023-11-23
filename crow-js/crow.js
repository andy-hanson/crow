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
@property {function(CStr, CStr): Server} newServer
@property {function(Server): CStr} version_
@property {function(Server, CStr, CStr): void} setFileSuccess
@property {function(Server, CStr, CStr): void} setFileIssue
@property {function(Server, CStr, CStr): void} changeFile
@property {function(Server, CStr): CStr} getFile
@property {function(Server, CStr): void} searchImportsFromUri
@property {function(Server): CStr} allStorageUris
@property {function(Server): CStr} allUnknownUris
@property {function(Server): CStr} allLoadingUris
@property {function(Server, CStr): CStr} getTokens
@property {function(Server): CStr} getAllDiagnostics
@property {function(Server, CStr, number): CStr} getDiagnosticsForUri
@property {function(Server, CStr, number, number): CStr} getDefinition
@property {function(Server, CStr, number, number): CStr} getReferences
@property {function(Server, CStr, number, number, CStr): CStr} getRename
@property {function(Server, CStr, number, number): CStr} getHover
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
		const readBack = readCStringFromView(this._view, res, this._end)
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

/** @type {function(bigint): number} */
const toMsec = nsec =>
	Math.round(Number(nsec) / 1_000_000)

/** @type {crow.makeCompiler} */
globalCrow.makeCompiler = async (bytes, includeDir, cwd, logger) => {
	/** @type {Array<{name:string, count:number, msec:number, bytesAllocated:number}>} */
	let perfMeasures = []
	const result = await WebAssembly.instantiate(bytes, {
		env: {
			/** @type {function(): bigint} */
			getTimeNanos: () =>
				BigInt(Math.round(performance.now() * 1_000_000)),
			/** @type {function(number, number, bigint, number): void} */
			perfLogMeasure: (namePtr, count, nanoseconds, bytesAllocated) => {
				perfMeasures.push({name:readCStr(namePtr), count, msec:toMsec(nanoseconds), bytesAllocated})
			},
			/** @type {function(number, bigint): void} */
			perfLogFinish: (name, totalNanoseconds) => {
				logger(`performance for ${readCStr(name)}`, {
					TOTAL: toMsec(totalNanoseconds),
					...Object.fromEntries(perfMeasures.map(({name, count, msec, bytesAllocated}) =>
						[name, {count, msec, bytesAllocated}]))
				})
				perfMeasures = []
			},
			/** @type {function(number, number): void} */
			debugLog: (str, value) => {
				logger(readCStr(str), value)
			},
			/** @type {function(number, number, number): void} */
			_verifyFail: (fileStart, fileLength, line) => {
				throw new Error("Called verifyFail! " + JSON.stringify({file:readString(fileStart, fileLength), line}))
			},
			...mathFunctions,
			/** @type {function(number, number, number): void} */
			write: (pipe, begin, length) => {
				globalWrites.push({pipe:pipe == 0 ? "stdout" : "stderr", text:readString(begin, length)})
			},
			/** @type {function(...unknown[]): void} */
			__assert: (...args) => {
				logger("ASSERT", args)
			},
		}
	})

	const exports = /** @type {Exports} */ (result.instance.exports)

	const { getParameterBufferPointer, getParameterBufferSizeBytes, memory, newServer } = exports
	const view = new DataView(memory.buffer)
	const paramAlloc = new Allocator(view, getParameterBufferPointer(), getParameterBufferSizeBytes())
	const server = newServer(paramAlloc.writeCStr(includeDir), paramAlloc.writeCStr(cwd))
	paramAlloc.clear()

	/** @type {function(number): string} */
	const readCStr = begin =>
		readCStringFromView(view, begin, exports.memory.buffer.byteLength)

	/** @type {function(number, number): string} */
	const readString = (begin, end) =>
		readStringFromView(view, begin, end)

	/**
	@template T
	@param {() => T} cb
	@return T
	*/
	const withParams = cb => {
		try {
			return cb()
		} finally {
			paramAlloc.clear()
		}
	}

	/** @type {function(() => number): any} */
	const withParamsAndJson = cb => {
		try {
			return JSON.parse(readCStr(cb()))
		} finally {
			paramAlloc.clear()
		}
	}

	return {
		version: () =>
			readCStr(exports.version_(server)),
		setFileSuccess: (uri, content) => withParams(() =>
			exports.setFileSuccess(server, paramAlloc.writeCStr(uri), paramAlloc.writeCStr(content))),
		setFileIssue: (uri, issue) => withParams(() =>
			exports.setFileIssue(server, paramAlloc.writeCStr(uri), paramAlloc.writeCStr(issue))),
		changeFile: (uri, changes) => withParams(() =>
			exports.changeFile(server, paramAlloc.writeCStr(uri), paramAlloc.writeCStr(JSON.stringify(changes)))),
		getFile: uri => withParams(() =>
			readCStr(exports.getFile(server, paramAlloc.writeCStr(uri)))),
		searchImportsFromUri: uri => withParams(() =>
			exports.searchImportsFromUri(server, paramAlloc.writeCStr(uri))),
		allStorageUris: () =>
			JSON.parse(readCStr(exports.allStorageUris(server))),
		allUnknownUris: () =>
			JSON.parse(readCStr(exports.allUnknownUris(server))),
		allLoadingUris: () =>
			JSON.parse(readCStr(exports.allLoadingUris(server))),
		getTokens: uri =>
			withParamsAndJson(() => exports.getTokens(server, paramAlloc.writeCStr(uri))),
		getAllDiagnostics: () =>
			JSON.parse(readCStr(exports.getAllDiagnostics(server))),
		getDiagnosticsForUri: (uri, minSeverity) =>
			withParamsAndJson(() => exports.getDiagnosticsForUri(server, paramAlloc.writeCStr(uri), minSeverity || 0)),
		getDefinition: ({uri, position:{line, character}}) => withParamsAndJson(() =>
			exports.getDefinition(server, paramAlloc.writeCStr(uri), line, character)),
		getReferences: ({uri, position:{line, character}}) =>
			withParamsAndJson(() => exports.getReferences(server, paramAlloc.writeCStr(uri), line, character)),
		getRename: ({uri, position:{line, character}}, newName) =>
			withParamsAndJson(() => exports.getRename(
				server, paramAlloc.writeCStr(uri), line, character, paramAlloc.writeCStr(newName))),
		getHover: ({uri, position:{line, character}}) => withParamsAndJson(() =>
			exports.getHover(server, paramAlloc.writeCStr(uri), line, character)).hover,
		run: uri => {
			try {
				globalWrites = []
				const exitCode = exports.run(server, paramAlloc.writeCStr(uri))
				return {exitCode, writes:[...globalWrites]}
			} finally {
				globalWrites = []
				paramAlloc.clear()
			}
		},
	}
}

/** @type {function(DataView, number, number): string} */
const readCStringFromView = (view, begin, maxPointer) => {
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
const readStringFromView = (view, buffer, bufferSize) => {
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
