/// <reference path="../../../doc/script/Compiler.js" />

const fs = require("fs")
const path = require("path")
/** @typedef {import("vscode").CancellationToken} CancellationToken */
/** @typedef {import("vscode").DocumentSemanticTokensProvider} DocumentSemanticTokensProvider */
/** @typedef {import("vscode").ExtensionContext} ExtensionContext */
/** @typedef {import("vscode").TextDocument} TextDocument */
const {languages, workspace, SemanticTokens, SemanticTokensBuilder, SemanticTokensLegend} = require("vscode")
/** @typedef {import("../node_modules/vscode-languageclient").LanguageClientOptions} LanguageClientOptions */
/** @typedef {import("../node_modules/vscode-languageclient").ServerOptions} ServerOptions */
const {LanguageClient, TransportKind} = require("../node_modules/vscode-languageclient")

// Avoiding TypeScript "is not a module" error
const require2 = require
require2("../../../doc/script/Compiler.js")

/** @type {LanguageClient | undefined} */
let client

/** @type {function(ExtensionContext): void} */
exports.activate = context => {
	const serverModule = context.asAbsolutePath(path.join('server', 'src', 'server.js'))
	// The debug options for the server
	// --inspect=6009: runs the server in Node's Inspector mode so VS Code can attach to the server for debugging
	const debugOptions = {execArgv:['--nolazy', '--inspect=6009']}

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
	const clientOptions = {
		documentSelector: [{scheme:"file", language:"noze"}],
		synchronize: {
			// Notify the server about file changes to '.clientrc files contained in the workspace
			//fileEvents: workspace.createFileSystemWatcher('**/.clientrc')
		},
	}

	client = new LanguageClient("noze", "noze", serverOptions, clientOptions)
	client.start()

	context.subscriptions.push(
		languages.registerDocumentSemanticTokensProvider({language:"noze"}, myDocumentSemanticTokensProvider, legend))
}

/** @type {function(): Thenable<void> | undefined} */
exports.deactivate = () =>
	client && client.stop()


/** @type {Map<string, number>} */
const tokenTypes = new Map()
/** @type {Map<string, number>} */
const tokenModifiers = new Map()


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

tokenTypesLegend.forEach((tokenType, index) => {
	tokenTypes.set(tokenType, index)
});
tokenModifiersLegend.forEach((tokenModifier, index) => {
	tokenModifiers.set(tokenModifier, index)
});
const legend = new SemanticTokensLegend(
	/** @type {string[]} */ (tokenTypesLegend),
	/** @type {string[]} */ (tokenModifiersLegend));

/** @type {Promise<Compiler> | null} */
let myCompiler = null
/** @type {function(): Promise<Compiler>} */
const getCompiler = () => {
	if (myCompiler == null) {
		const bytes = fs.readFileSync(__dirname + "/../../../bin/noze.wasm")
		/** @type {Files} */
		const include = {} // TODO
		myCompiler = compiler.Compiler.makeFromBytes(bytes, include)
	}
	return myCompiler
}

/**
 * @typedef IParsedToken
 * @property {number} line
 * @property {number} startCharacter
 * @property {number} length
 * @property {string} tokenType
 * @property {string[]} tokenModifiers
 */


/**
 * @param {TextDocument} document
 * @param {CancellationToken} _cancellationToken
 * @return {Promise<SemanticTokens>}
 */
const provideDocumentSemanticTokens = async (document, _cancellationToken) => {
	const comp = await getCompiler()
	const tokens = comp.getTokens(document.getText())
	const builder = new SemanticTokensBuilder();
	for (const token of tokens.tokens) {
		const start = token.range.args[0]
		const end = token.range.args[1]
		const length = end - start
		const pos = document.positionAt(start)
		builder.push(
			pos.line,
			pos.character,
			length,
			encodeTokenType(convertToken(token.kind)),
			encodeTokenModifiers([]))
	}
	return builder.build();
}

/**
 * @param {TokenKind} kind
 * @return {TokenType}
 */
const convertToken = kind => {
	switch (kind) {
		case "by-val-ref":
			return "keyword"
		case "field-def":
		case "field-ref":
			return "property"
		case "fun-def":
		case "fun-ref":
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
		case "local-def":
			return "variable"
		case "param-def":
			return "parameter"
		case "purity":
			return "keyword"
		case "spec-def":
		case "spec-ref":
			return "label"
		case "struct-def":
		case "struct-ref":
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
const myDocumentSemanticTokensProvider = {provideDocumentSemanticTokens}

/**
 * @param {string} tokenType
 * @return {number}
 */
const encodeTokenType = tokenType => {
	if (tokenTypes.has(tokenType)) {
		return nonUndefined(tokenTypes.get(tokenType));
	} else if (tokenType === 'notInLegend') {
		return tokenTypes.size + 2;
	}
	return 0;
}

/**
 * @private
 * @param {ReadonlyArray<string>} strTokenModifiers
 * @return {number}
 */
const encodeTokenModifiers = strTokenModifiers => {
	let result = 0;
	for (let i = 0; i < strTokenModifiers.length; i++) {
		const tokenModifier = strTokenModifiers[i];
		if (tokenModifiers.has(tokenModifier)) {
			result = result | (1 << nonUndefined(tokenModifiers.get(tokenModifier)));
		} else if (tokenModifier === 'notInLegend') {
			result = result | (1 << tokenModifiers.size + 2);
		}
	}
	return result;
}

/**
 * @template T
 * @param {T | undefined} x
 * @return {T}
 */
const nonUndefined = x => {
	if (x === undefined)
		throw new Error()
	return x
}
