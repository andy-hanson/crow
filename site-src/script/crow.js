import { assert } from "./util/util.js"
const includeAll = await (await fetch("/include-all.json")).json()

/** @typedef {string} */
export const Uri = null

/** @typedef {{pipe:"stdout" | "stderr", text:string}} */
export const Write = null

/** @typedef {{tokenTypes: ReadonlyArray<string>, tokenModifiers: ReadonlyArray<string>}} */
export const SemanticTokensLegend = null

/** @typedef {{messages:any[], exitCode?:number}} Response */

/**
@typedef
@property {(inputMessage: any) => Response} handleMessage
@property {(method: string, params: any) => any} request
*/
export const CrowLspServer = null

/** @typedef {{line:number, character:number}} */
export const LineAndCharacter = null

/** @typedef {{start:LineAndCharacter, end:LineAndCharacter}} */
export const Range = null

/**
@typedef Diagnostic
@property {Range} range
@property {1 | 2 | 3 | 4} severity Error = 1, Warning = 2, Information = 3, Hint = 4
@property {string} message
*/
export const Diagnostic = null

/**
@typedef
@property {CrowLspServer["request"]} request
@property {SemanticTokensLegend} tokensLegend
@property {(uri: Uri, text: string) => ReadonlyArray<Diagnostic>} openFile
@property {(uri: Uri, text: string) => ReadonlyArray<Diagnostic>} changeFile
@property {() => void} markUnknownFilesNotFound
*/
export const CrowServer = null

/** @type {() => Promise<CrowServer>} */
export const getCrowServer = () => crowServer

/** @type {ReadonlyArray<string & keyof Math>} */
const mathKeys = [
	"acos", "acosh", "asin", "asinh", "atan", "atanh", "atan2",
	"cos", "cosh", "log", "sin", "sinh", "sqrt", "tan", "tanh",
]

/** @type {function(number): number)} */
const round = x =>
	// Behave like C's (and Crow's) round, where `-0.5.round` is -1
	x < 0 ? -Math.round(-x) : Math.round(x)

/** @type {function(() => DataView): WebAssembly.ModuleImports} */
/** @type {Array<{name:string, count:number, msec:number, bytesAllocated:number}>} */
let perfMeasures = []
const imports = {
	/** @type {function(): bigint} */
	getTimeNanos: () =>
		BigInt(Math.round(performance.now() * 1_000_000)),
	/** @type {function(CStr, number, bigint, number): void} */
	perfLogMeasure: (namePtr, count, nanoseconds, bytesAllocated) => {
		perfMeasures.push({name:readCString(namePtr), count, msec:toMsec(nanoseconds), bytesAllocated})
	},
	/** @type {function(CStr, bigint): void} */
	perfLogFinish: (name, totalNanoseconds) => {
		console.log(`performance for ${readCString(name)}`, {
			TOTAL: toMsec(totalNanoseconds),
			...Object.fromEntries(perfMeasures.map(({name, count, msec, bytesAllocated}) =>
				[name, {count, msec, bytesAllocated}]))
		})
		perfMeasures = []
	},
	/** @type {function(CStr): void} */
	debugLog: str => {
		console.log(readCString(str))
	},
	...Object.fromEntries(mathKeys.flatMap(name => [
		[name, Math[name]],
		[`${name}f`, Math[name]],
	])),
	/** @type {function(number, number)} */
	round,
	roundf: round,
	/** @type {function(CStr, CStr, number): void} */
	__assert: (asserted, file, line) => {
		throw new Error(`Assertion '${readCString(asserted)}' failed on ${readCString(file)} line ${line}`)
	},
}

/** @type {DataView} */
let view

export const includeDir = "file:///include"

/**
Exports of `wasm.d`
@typedef WasmExports
@property {WebAssembly.Memory} memory
@property {() => CStr} getParameterBufferPointer
@property {() => number} getParameterBufferLength
@property {(params: CStr) => Server} newServer
@property {(server: Server, params: CStr) => CStr} handleLspMessage
*/

/** @typedef {number & {_isServer:true}} Server */
/** @typedef {number & {_isCStr:true}} CStr */

/** @type {function(bigint): number} */
const toMsec = nsec =>
	Math.round(Number(nsec) / 1_000_000)

/** @type {function(number): string} */
const readCString = begin => {
	let end = begin
	while (end < view.byteLength && view.getUint8(end) != 0)
		end++
	return new TextDecoder().decode(new Uint8Array(view.buffer, begin, end - begin))
}

/** @type {function({begin:CStr, length:number}, string): CStr} */
const writeCString = ({begin, length}, content) => {
	const {read, written} = new TextEncoder().encodeInto(content, new Uint8Array(view.buffer, begin, length))
	assert(read == content.length)
	assert(written < length)
	view.setUint8(begin + written, 0)
	assert(readCString(begin) == content)
	return begin
}

/** @type {() => Promise<CrowLspServer>} */
const makeLspServer = async () => {
	const result = await WebAssembly.instantiateStreaming(fetch("../bin/crow.wasm"), {env:imports})
	const wasm = /** @type {WasmExports}} */ (result.instance.exports)
	view = new DataView(wasm.memory.buffer)
	const parameterBuffer = {begin:wasm.getParameterBufferPointer(), length:wasm.getParameterBufferLength()}
	const server = wasm.newServer(writeCString(parameterBuffer, JSON.stringify({includeDir, cwd:"file:///"})))
	/** @type {CrowLspServer["handleMessage"]} */
	const handleMessage = message =>
		JSON.parse(readCString(wasm.handleLspMessage(server, writeCString(parameterBuffer, JSON.stringify(message)))))
	return {
		handleMessage,
		request: (method, params) => {
			const { exitCode, messages } = handleMessage({id:1, method, params})
			assert(exitCode == null)
			assert(messages.length === 1)
			assert(messages[0].id === 1)
			return messages[0].result
		},
	}
}

let diagnosticsPerUri = new Map()

/** @type {Promise<CrowServer>} */
const crowServer = (async () => {
	const lsp = await makeLspServer()
	const tokensLegend = lsp.request("initialize", {}).capabilities.semanticTokensProvider.legend
	lsp.handleMessage({method:"initialized", params:{}})

	/** @type {function(Uri, Response): ReadonlyArray<Diagnostic>} */
	const getDiagnostics = (uri, response) => {
		for (const message of response.messages) {
			if (message.method === "custom/unknownUris") {
			} else {
				assert(message.method === "textDocument/publishDiagnostics")
				diagnosticsPerUri.set(message.params.uri, message.params.diagnostics)
			}
		}
		return diagnosticsPerUri.get(uri) || []
	}

	/** @type {CrowServer["openFile"]} */
	const openFile = (uri, text) =>
		getDiagnostics(uri, lsp.handleMessage({
			method: "textDocument/didOpen",
			params: {textDocument:{uri, text}},
		}))

	/** @type {CrowServer["changeFile"]} */
	const changeFile = (uri, text) =>
		getDiagnostics(uri, lsp.handleMessage({
			method: "textDocument/didChange",
			params: {textDocument:{uri}, contentChanges:[{text}]},
		}))

	/** @type {CrowServer["markUnknownFilesNotFound"]} */
	const markUnknownFilesNotFound = () => {
		const {unloadedUris} = lsp.request("custom/unloadedUris", {})
		for (const uri of unloadedUris) {
			assert(uri.endsWith("/crow-config.json"))
			lsp.handleMessage({method: "custom/readFileResult", params:{uri, type:"notFound"}})
		}
		assert(lsp.request("custom/unloadedUris", {}).unloadedUris.length === 0)
	}

	for (const [path, text] of Object.entries(includeAll))
		openFile(`${includeDir}/${path}`, text)
	openFile("file:///crow-config.json", "{}")
	openFile("file:///hello.txt", "Hello, world!")
	markUnknownFilesNotFound()

	return {request:lsp.request, tokensLegend, openFile, changeFile, markUnknownFilesNotFound}
})()
crowServer.catch(console.error)
