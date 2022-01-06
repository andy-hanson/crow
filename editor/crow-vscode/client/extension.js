/// <reference path="../../../crow-js/crow.js" />

const fs = require("fs")
/** @typedef {import("vscode").CancellationToken} CancellationToken */
/** @typedef {import("vscode").DocumentSemanticTokensProvider} DocumentSemanticTokensProvider */
/** @typedef {import("vscode").ExtensionContext} ExtensionContext */
/** @typedef {import("vscode").TextDocument} TextDocument */
const {languages, SemanticTokens, SemanticTokensBuilder, SemanticTokensLegend} = require("vscode")
/** @typedef {import("vscode-languageclient").LanguageClientOptions} LanguageClientOptions */
/** @typedef {import("vscode-languageclient").ServerOptions} ServerOptions */
const {LanguageClient, TransportKind} = require("vscode-languageclient")

// Avoiding TypeScript "is not a module" error
const require2 = require
require2("../../../crow-js/crow.js")

/** @type {LanguageClient | undefined} */
let client

/** @type {function(ExtensionContext): void} */
exports.activate = context => {
	const serverModule = context.asAbsolutePath("server/server.js")
	// The debug options for the server
	// --inspect=6009: runs the server in Node's Inspector mode so VS Code can attach to the server for debugging
	const debugOptions = {execArgv:["--nolazy", "--inspect=6009"]}

	// If the extension is launched in debug mode then the debug server options are used
	// Otherwise the run options are used
	/** @type {ServerOptions} */
	const serverOptions = {
		run: {module:serverModule, transport:TransportKind.ipc},
		debug: {
			module: serverModule,
			transport: TransportKind.ipc,
			options: debugOptions,
		}
	}

	/** @type {LanguageClientOptions} */
	const clientOptions = {documentSelector: [{scheme:"file", language:"crow"}]}
	client = new LanguageClient("crow", "crow", serverOptions, clientOptions)
	client.start()

	context.subscriptions.push(
		languages.registerDocumentSemanticTokensProvider({language:"crow"}, crowSemanticTokensProvider, legend))
}

/** @type {function(): Thenable<void> | undefined} */
exports.deactivate = () =>
	client && client.stop()

/**
@typedef {
	| "comment"
	| "string"
	| "keyword"
	| "number"
	| "regexp"
	| "operator"
	| "namespace"
	| "type"
	| "struct"
	| "class"
	| "interface"
	| "enum"
	| "typeParameter"
	| "function"
	| "method"
	| "macro"
	| "variable"
	| "parameter"
	| "property"
	| "label"
} TokenType
*/

/** @type {ReadonlyArray<TokenType>} */
const tokenTypesLegend = [
	"comment",
	"string",
	"keyword",
	"number",
	"regexp",
	"operator",
	"namespace",
	"type",
	"struct",
	"class",
	"interface",
	"enum",
	"typeParameter",
	"function",
	"method",
	"macro",
	"variable",
	"parameter",
	"property",
	"label"
]

/**
@typedef {
	| "declaration"
	| "documentation"
	| "readonly"
	| "static"
	| "abstract"
	| "deprecated"
	| "modification"
	| "async"
} TokenModifier
*/

/** @type {ReadonlyArray<TokenModifier>} */
const tokenModifiersLegend = [
	"declaration",
	"documentation",
	"readonly",
	"static",
	"abstract",
	"deprecated",
	"modification",
	"async",
]


/** @type {Map<string, number>} */
const tokenTypes = new Map()
tokenTypesLegend.forEach((tokenType, index) => {
	tokenTypes.set(tokenType, index)
})

/** @type {Map<string, number>} */
const tokenModifiers = new Map()
tokenModifiersLegend.forEach((tokenModifier, index) => {
	tokenModifiers.set(tokenModifier, index)
})
const legend = new SemanticTokensLegend(
	/** @type {string[]} */ (tokenTypesLegend),
	/** @type {string[]} */ (tokenModifiersLegend))

/** @type {Promise<Compiler> | null} */
let myCompiler = null
/** @type {function(): Promise<Compiler>} */
const getCompiler = () => {
	if (myCompiler == null) {
		const bytes = fs.readFileSync(__dirname + "/../../../bin/crow.wasm")
		myCompiler = compiler.Compiler.makeFromBytes(bytes)
	}
	return myCompiler
}

/**
 * @param {TextDocument} document
 * @param {CancellationToken} _cancellationToken
 * @return {Promise<SemanticTokens>}
 */
const provideDocumentSemanticTokens = async (document, _cancellationToken) => {
	try {
		const comp = await getCompiler()
		comp.addOrChangeFile(StorageKind.local, "main", document.getText())
		const tokens = comp.getTokens(StorageKind.local, "main")
		const builder = new SemanticTokensBuilder()
		for (const {kind, range:{args:[start, end]}} of tokens) {
			const length = end - start
			const {line, character} = document.positionAt(start)
			builder.push(line, character, length, encodeTokenType(convertToken(kind)), encodeTokenModifiers([]))
		}
		return builder.build()
	} catch (e) {
		// VSCode just swallows exceptions, at least log them
		console.log("Caught error in provideDocumentSemanticTokens")
		console.error(e.stack)
		throw e
	}
}

/**
 * @param {TokenKind} kind
 * @return {TokenType}
 */
const convertToken = kind => {
	switch (kind) {
		case "by-val-ref":
			return "keyword"
		case "field":
			return "property"
		case "fun":
			return "function"
		case "identifier":
			return "variable"
		case "import":
			return "namespace"
		case "keyword":
			return "keyword"
		case "lit-num":
			return "number"
		case "lit-str":
			return "string"
		case "local":
			return "variable"
		case "param":
			return "parameter"
		case "purity":
			return "keyword"
		case "spec":
			return "label"
		case "struct":
			return "type"
		case "tparam-def":
		case "tparam-ref":
			return "typeParameter"
		default:
			return assertNever(kind)
	}
}

/** @type {function(never): never} */
const assertNever = () => {
	throw new Error()
}

/** @type {DocumentSemanticTokensProvider} */
const crowSemanticTokensProvider = {provideDocumentSemanticTokens}

/**
 * @param {string} tokenType
 * @return {number}
 */
const encodeTokenType = tokenType =>
	tokenTypes.get(tokenType) || 0

/** @type {function(ReadonlyArray<string>): number} */
const encodeTokenModifiers = modifiers => {
	let result = 0
	for (const mod of modifiers) {
		const modifierNumber = tokenModifiers.get(mod)
		if (modifierNumber !== undefined)
			result = result | (1 << modifierNumber)
	}
	return result
}
