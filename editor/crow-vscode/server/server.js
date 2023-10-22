const {createConnection, TextDocuments, ProposedFeatures} = require("vscode-languageserver")
/** @typedef {import("vscode-languageserver-protocol").TextDocumentPositionParams} TextDocumentPositionParams */
const {
	DidChangeConfigurationNotification, DefinitionRequest, HoverRequest, TextDocumentIdentifier,
} = require("vscode-languageserver-protocol")
/** @typedef {import("vscode-languageserver-types").CompletionItem} CompletionItem */
const {CompletionItemKind, Diagnostic, Location, Position, Range} = require("vscode-languageserver-types")
const {TextDocumentSyncKind} = require("vscode-languageserver-protocol")
/** @typedef {import("vscode-languageserver-protocol").InitializeParams} InitializeParams */
/** @typedef {import("vscode-languageserver-protocol").InitializeResult<unknown>} InitializeResult */
/** @typedef {import("vscode-languageserver-protocol").PublishDiagnosticsParams} PublishDiagnosticsParams */
const {TextDocument} = require("vscode-languageserver-textdocument")

const {makeCompiler} = require("./util.js")

// @ts-ignore
const connection = createConnection(ProposedFeatures.all)

/** @type {TextDocuments<TextDocument>} */
const documents = new TextDocuments(TextDocument)

let hasConfigurationCapability = false

/**
 * @template P, R
 * @param {string} description
 * @param {(p: P) => R} cb
 * @return {(p: P) => R}
 */
const withLogErrors = (description, cb) => {
	return p => {
		try {
			return cb(p)
		} catch (error) {
			connection.console.log(`Error in ${description}: ` + (/** @type {Error} */ (error)).stack)
			throw error
		}
	}
}

connection.onInitialize(({capabilities}) => {
	// Does the client support the `workspace/configuration` request?
	// If not, we fall back using global settings.
	hasConfigurationCapability = !!(capabilities.workspace && !!capabilities.workspace.configuration)
	/** @type {InitializeResult} */
	const result = {
		capabilities: {
			textDocumentSync: TextDocumentSyncKind.Incremental,
			completionProvider: {resolveProvider: true},
		},
	}
	return result
})

connection.onInitialized(withLogErrors('onInitialized', () => {
	for (const request of [DefinitionRequest, HoverRequest]) {
		connection.client.register(request.type)
	}
	if (hasConfigurationCapability) {
		connection.client.register(DidChangeConfigurationNotification.type, undefined)
	}
}))

documents.onDidChangeContent(withLogErrors('onDidChangeContent', ({document}) => {
	compiler.addOrChangeFile(pathForDocument(document), document.getText())
	const diags = getSyntaxDiagnostics(document)
	connection.sendDiagnostics(diags)
}))

/** @type {crow.Compiler} */
let compiler

/** @type {function(TextDocument): PublishDiagnosticsParams} */
const getSyntaxDiagnostics = (document) => {
	const {parseDiagnostics} = compiler.getTokensAndParseDiagnostics(pathForDocument(document))
	const diags = parseDiagnostics.map(({message, range}) =>
		Diagnostic.create(toRange(document, range), message))
	return {uri: document.uri, diagnostics: diags}
}

/** @type {function(TextDocumentIdentifier): string} */
const pathForDocument = document =>
	document.uri.startsWith("file://") ? document.uri.slice("file://".length) : document.uri
/** @type {function(string): string} */
const uriForPath = path =>
	'file://' + path

/** @type {function(TextDocument, crow.DiagRange): Range} */
const toRange = (document, {start, end}) =>
	Range.create(toPosition(document, start), toPosition(document, end))

/** @type {function(TextDocument, number): Position} */
const toPosition = (document, offset) => {
	const res = document.positionAt(offset)
	// It will sometimes give NaN positions at the end of the file, which breaks the protocol
	return Number.isNaN(res.character) ? Position.create(res.line, 0) : res
}

/** @type {function(TextDocument, crow.PathAndRange): Location} */
const toLocation = (document, {path, range}) =>
	Location.create(uriForPath(path), toRange(document, range))

connection.onDidChangeWatchedFiles(withLogErrors('onDidChangeWatchedFiles', _change => {
	// Monitored files have change in VSCode
	connection.console.log('We received an file change event')
}))

connection.onDefinition(withLogErrors('onDefinition', params => {
	connection.console.log("TOP OF connection.getDefinition")
	const {document, path, offset} = getDocumentPathAndOffset(params)
	const {definition} = compiler.getDefinition(path, offset)
	return definition
		? [toLocation(document, definition)]
		: []
}))

connection.onHover(withLogErrors('onHover', params => {
	const {path, offset} = getDocumentPathAndOffset(params)
	const hover = compiler.getHover(path, offset)
	return hover ? {contents:hover} : null
}))

/** @type {function(TextDocumentPositionParams): {document:TextDocument, path:string, offset:number}} */
const getDocumentPathAndOffset = ({position, textDocument}) => {
	const document = nonUndefined(documents.get(textDocument.uri))
	return {document, path:pathForDocument(textDocument), offset:document.offsetAt(position)}
}

// This handler provides the initial list of the completion items.
connection.onCompletion(withLogErrors('onCompletion', _textDocumentPosition => {
	/** @type {CompletionItem[]} */
	const res = [
		{
			label: 'JavaScript',
			kind: CompletionItemKind.Text,
			data: 2
		}
	]
	return res
}))

connection.onCompletionResolve(withLogErrors('onCompletionResolve', item => {
	if (item.data === 2) {
		item.detail = 'JavaScript details'
		item.documentation = 'JavaScript documentation'
	}
	return item
}))

// Make the text document manager listen on the connection
// for open, change and close text document events
documents.listen(connection)


const setUpCompiler = async () => {
	try {
		compiler = await makeCompiler()
		connection.listen()
	} catch (error) {
		connection.console.log("Failed to initialize: " + error)
		throw error
	}
}
setUpCompiler()

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
