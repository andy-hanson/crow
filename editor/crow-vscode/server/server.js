/// <reference types="crow" />
// @ts-ignore
require("../../../crow-js/crow.js")

const fs = require("fs")
const {createConnection, TextDocuments, ProposedFeatures} = require("vscode-languageserver")
/** @typedef {import("vscode-languageserver-protocol").TextDocumentPositionParams} TextDocumentPositionParams */
const {
	DidChangeConfigurationNotification, DefinitionRequest, HoverRequest, TextDocumentIdentifier,
} = require("vscode-languageserver-protocol")
/** @typedef {import("vscode-languageserver-types").CompletionItem} CompletionItem */
const {CompletionItemKind, Diagnostic, Position, Range} = require("vscode-languageserver-types")
const {TextDocumentSyncKind} = require("vscode-languageserver-protocol")
/** @typedef {import("vscode-languageserver-protocol").InitializeParams} InitializeParams */
/** @typedef {import("vscode-languageserver-protocol").InitializeResult<unknown>} InitializeResult */
/** @typedef {import("vscode-languageserver-protocol").PublishDiagnosticsParams} PublishDiagnosticsParams */
const {TextDocument} = require("vscode-languageserver-textdocument")

// Avoiding TypeScript "is not a module" error
const require2 = require
require2("../../../crow-js/crow.js")

// @ts-ignore
const connection = createConnection(ProposedFeatures.all)

/** @type {TextDocuments<TextDocument>} */
const documents = new TextDocuments(TextDocument)

let hasConfigurationCapability = false

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

connection.onInitialized(() => {
	connection.console.log("ONINITIALIZED")
	for (const request of [DefinitionRequest, HoverRequest]) {
		connection.client.register(request.type)
	}
	if (hasConfigurationCapability) {
		connection.client.register(DidChangeConfigurationNotification.type, undefined)
	}
})

documents.onDidChangeContent(async ({document}) => {
	try {
		compiler.addOrChangeFile(pathForDocument(document), document.getText())
		const diags = getSyntaxDiagnostics(document)
		connection.sendDiagnostics(diags)
	} catch (e) {
		console.error("CAUGHT ERROR", e)
		throw e
	}
})

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

/** @type {function(TextDocument, crow.DiagRange): Range} */
const toRange = (document, {start, end}) =>
	Range.create(toPosition(document, start), toPosition(document, end))

/** @type {function(TextDocument, number): Position} */
const toPosition = (document, x) => {
	const res = document.positionAt(x)
	// It will sometimes give NaN positions at the end of the file, which breaks the protocol
	return Number.isNaN(res.character) ? Position.create(res.line, 0) : res
}

connection.onDidChangeWatchedFiles(_change => {
	// Monitored files have change in VSCode
	connection.console.log('We received an file change event')
})

connection.onHover(params => {
	const {path, offset} = getPathAndOffset(params)
	const hover = compiler.getHover(path, offset)
	return hover ? {contents:hover} : null
})

connection.onDefinition(params => {
	const {path, offset} = getPathAndOffset(params)
	connection.console.log("IN ONDEFINITION " + JSON.stringify({path, offset}))
	return null
})

/** @type {function(TextDocumentPositionParams): {path:string, offset:number}} */
const getPathAndOffset = ({position, textDocument}) => {
	const document = nonUndefined(documents.get(textDocument.uri))
	const offset = document.offsetAt(position)
	return {path:pathForDocument(textDocument), offset}
}

// This handler provides the initial list of the completion items.
connection.onCompletion(_textDocumentPosition => {
	/** @type {CompletionItem[]} */
	const res = [
		{
			label: 'JavaScript',
			kind: CompletionItemKind.Text,
			data: 2
		}
	]
	return res
})

connection.onCompletionResolve(item => {
	if (item.data === 2) {
		item.detail = 'JavaScript details'
		item.documentation = 'JavaScript documentation'
	}
	return item
})

// Make the text document manager listen on the connection
// for open, change and close text document events
documents.listen(connection)

const setUpCompiler = async () => {
	try {
		compiler = await crow.makeCompiler(fs.readFileSync(__dirname + "/../../../bin/crow.wasm"))
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
