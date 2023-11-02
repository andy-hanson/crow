const {createConnection, TextDocuments, ProposedFeatures} = require("vscode-languageserver")
/** @typedef {import("vscode-languageserver-protocol").TextDocumentPositionParams} TextDocumentPositionParams */
const {
	DidChangeConfigurationNotification, DefinitionRequest, HoverRequest,
} = require("vscode-languageserver-protocol")
/** @typedef {import("vscode-languageserver-types").CompletionItem} CompletionItem */
const {CompletionItemKind, Diagnostic, Location, Position, Range} = require("vscode-languageserver-types")
const {TextDocumentSyncKind} = require("vscode-languageserver-protocol")
/** @typedef {import("vscode-languageserver-protocol").InitializeParams} InitializeParams */
/** @typedef {import("vscode-languageserver-protocol").InitializeResult<unknown>} InitializeResult */
/** @typedef {import("vscode-languageserver-protocol").PublishDiagnosticsParams} PublishDiagnosticsParams */
const {TextDocument} = require("vscode-languageserver-textdocument")

const {makeCompiler, nonNull} = require("./util.js")

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

connection.onInitialized(withLogErrors("onInitialized", () => {
	for (const request of [DefinitionRequest, HoverRequest]) {
		connection.client.register(request.type)
	}
	if (hasConfigurationCapability) {
		connection.client.register(DidChangeConfigurationNotification.type, undefined)
	}
}))

documents.onDidOpen(withLogErrors("onDidOpen", ({document}) => {
	connection.console.log("onDidOpen " + document.uri)
	onDidOpenOrChangeDocument(document)
}))

documents.onDidClose(withLogErrors("onDidClose", ({/*document*/}) => {
	connection.console.log("onDidClose (unimplemented)")
}))

documents.onDidChangeContent(withLogErrors("onDidChangeContent", ({document}) => {
	connection.console.log("onDidChangeContent " + document.uri)
	onDidOpenOrChangeDocument(document)
}))

/** @type {function(crowProtocol.ReadFileResult): void} */
const onReadFileResult = ({uri}) => {
	connection.console.log("GOT readFileResult " + uri)
	// TODO: Handle error results differently (this will allow the correct diagnostic to be shown)
	compiler.deleteFile(uri)
}
// 'onDidOpen' should handle normal files, this is for file not found or error
connection.onNotification("custom/readFileResult", withLogErrors("readFileResult", onReadFileResult))

/** @type {function(TextDocument): void} */
const onDidOpenOrChangeDocument = document => {
	compiler.addOrChangeFile(document.uri, document.getText())
	const diags = getSyntaxDiagnostics(document)
	connection.sendDiagnostics(diags)

	compiler.searchImportsFromUri(document.uri)

	const unknownUris = compiler.allUnknownUris()
	if (unknownUris.length) {
		connection.console.log("Server will notify client of unknown URIs")
		/** @type {crowProtocol.UnknownUris} */
		const message = {unknownUris}
		connection.sendNotification("custom/unknownUris", message)
	} else {
		connection.console.log("Will now get semantic diagnostics")
		for (const {uri, diagnostics} of compiler.getAllDiagnostics().diagnostics) {
			connection.sendDiagnostics(toDiagnostics(nonNull(documents.get(uri)), diagnostics))
		}
		connection.console.log("Did get semantic diagnostics")
	}
}

// Make the text document manager listen on the connection
// for open, change and close text document events
documents.listen(connection)

/** @type {crow.Compiler} */
let compiler

/** @type {function(TextDocument): PublishDiagnosticsParams} */
const getSyntaxDiagnostics = (document) =>
	toDiagnostics(document, compiler.getTokensAndParseDiagnostics(document.uri).parseDiagnostics)

/** @type {function(TextDocument, ReadonlyArray<crow.Diagnostic>): PublishDiagnosticsParams} */
const toDiagnostics = (document, diagnostics) =>
	({uri:document.uri, diagnostics:diagnostics.map(x => toDiagnostic(document, x))})

/** @type {function(TextDocument, crow.Diagnostic): Diagnostic} */
const toDiagnostic = (document, {range, message}) =>
	Diagnostic.create(toRange(document, range), message)

/** @type {function(TextDocument, crow.RangeWithinFile): Range} */
const toRange = (document, {start, end}) =>
	Range.create(toPosition(document, start), toPosition(document, end))

/** @type {function(TextDocument, number): Position} */
const toPosition = (document, offset) => {
	const res = document.positionAt(offset)
	// It will sometimes give NaN positions at the end of the file, which breaks the protocol
	return Number.isNaN(res.character) ? Position.create(res.line, 0) : res
}

/** @type {function(crow.UriAndRange): Location} */
const toLocation = ({uri, range}) => {
	const document = nonNull(documents.get(uri))
	return Location.create(uri, toRange(document, range))
}

connection.onDidChangeWatchedFiles(withLogErrors("onDidChangeWatchedFiles", _change => {
	// Monitored files have change in VSCode
	connection.console.log("onDidChangeWatchedFiles (unimplemented)")
}))

connection.onDefinition(withLogErrors("onDefinition", params => {
	const {definition} = compiler.getDefinition(getUriAndPosition(params))
	return definition
		? [toLocation(definition)]
		: []
}))

connection.onHover(withLogErrors("onHover", params => {
	const hover = compiler.getHover(getUriAndPosition(params))
	return hover ? {contents:hover} : null
}))

/** @type {function(TextDocumentPositionParams): crow.UriAndPosition} */
const getUriAndPosition = ({position, textDocument}) => {
	const document = nonNull(documents.get(textDocument.uri))
	return {uri:textDocument.uri, position:document.offsetAt(position)}
}

// This handler provides the initial list of the completion items.
connection.onCompletion(withLogErrors("onCompletion", _textDocumentPosition => {
	/** @type {CompletionItem[]} */
	const res = [
		{
			label: "JavaScript",
			kind: CompletionItemKind.Text,
			data: 2
		}
	]
	return res
}))

connection.onCompletionResolve(withLogErrors("onCompletionResolve", item => {
	if (item.data === 2) {
		item.detail = "JavaScript details"
		item.documentation = "JavaScript documentation"
	}
	return item
}))

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
