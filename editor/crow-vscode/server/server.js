/// <reference path="../../../crow-js/crow.js" />

const fs = require("fs")
const {createConnection, TextDocuments, ProposedFeatures} = require("vscode-languageserver")
const {DidChangeConfigurationNotification, HoverRequest} = require("vscode-languageserver-protocol")
/** @typedef {import("vscode-languageserver-types").CompletionItem} CompletionItem */
const {CompletionItemKind, DiagnosticSeverity} = require("vscode-languageserver-types")
/** @typedef {import("vscode-languageserver-types").Diagnostic} Diagnostic */
const {TextDocumentSyncKind} = require("vscode-languageserver-protocol")
/** @typedef {import("vscode-languageserver-protocol").InitializeParams} InitializeParams */
/** @typedef {import("vscode-languageserver-protocol").InitializeResult<unknown>} InitializeResult */
/** @typedef {import("vscode-languageserver-protocol").PublishDiagnosticsParams} PublishDiagnosticsParams */
const {TextDocument} = require("vscode-languageserver-textdocument")

// Avoiding TypeScript "is not a module" error
const require2 = require
require2("../../../crow-js/crow.js")

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
	connection.client.register(HoverRequest.type)
	if (hasConfigurationCapability) {
		connection.client.register(DidChangeConfigurationNotification.type, undefined)
	}
})

documents.onDidChangeContent(change => {
	getSyntaxDiagnostics(change.document)
		.then(diags => {
			connection.sendDiagnostics(diags)
		}).catch(e => {
			console.error("CAUGHT ERROR", e)
			throw e
		})
})

/** @type {Promise<Compiler> | null} */
let _compiler = null
/** @type {function(): Promise<Compiler>} */
const getCompiler = () => {
	if (_compiler === null)
		_compiler = compiler.Compiler.makeFromBytes(fs.readFileSync(__dirname + "/../../../bin/crow.wasm"))
	return _compiler
}

/** @type {function(TextDocument): Promise<PublishDiagnosticsParams>} */
const getSyntaxDiagnostics = async document => {
	const comp = await getCompiler()
	comp.addOrChangeFile(StorageKind.local, "main", document.getText())
	const diags = comp.getParseDiagnostics(StorageKind.local, "main").map(diag => {
		/** @type {Diagnostic} */
		const res = {
			severity: DiagnosticSeverity.Error,
			range: {
				start: document.positionAt(diag.range.args[0]),
				end: document.positionAt(diag.range.args[1]),
			},
			message: diag.message,
			source: "ex", // TODO: WHAT IS THIS?
		}
		return res
	})
	return {uri: document.uri, diagnostics: diags}
}

connection.onDidChangeWatchedFiles(_change => {
	// Monitored files have change in VSCode
	connection.console.log('We received an file change event')
})

connection.onHover(({position, textDocument}) => {
	const document = nonUndefined(documents.get(textDocument.uri))
	const offset = document.offsetAt(position)
	return {contents: `your offset is: ${offset}`}
})

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

// Listen on the connection
connection.listen()

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
