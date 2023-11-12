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

const {makeCompiler, nonNull, VERBOSE} = require("./util.js")

// @ts-ignore
const connection = createConnection(ProposedFeatures.all)

/** @type {function(string, unknown): string} */
const formatLog = (message, content) =>
	content === undefined ? message : `${message}: ${JSON.stringify(content)}`

/** @type {function(string, ?unknown): void} */
const log = (message, content) => {
	connection.console.log(formatLog(message, content))
}

/** @type {function(string, ?unknown): void} */
const logError = (message, content) => {
	connection.console.error(formatLog(message, content))
}

/** @type {function(string, ?unknown): void} */
const logVerbose = (message, content) => {
	if (VERBOSE)
		log(message, content)
}

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
			log(`Error in ${description}`, {stack:(/** @type {Error} */ (error)).stack})
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
	logVerbose("onDidOpen", {uri:document.uri})
	onDidOpenOrChangeDocument(document)
}))

documents.onDidClose(withLogErrors("onDidClose", ({document}) => {
	log("onDidClose (unimplemented)", {uri:document.uri})
}))

documents.onDidChangeContent(withLogErrors("onDidChangeContent", ({document}) => {
	logVerbose("onDidChangeContent", {uri:document.uri})
	onDidOpenOrChangeDocument(document)
}))

/** @type {function(crowProtocol.ReadFileResult): void} */
const onReadFileResult = ({uri, type}) => {
	logVerbose("onReadFileResult", {uri, type})
	compiler.setFileIssue(uri, type)
	afterFileChange()
}
// 'onDidOpen' should handle normal files, this is for file not found or error
connection.onNotification("custom/readFileResult", withLogErrors("readFileResult", onReadFileResult))

/** @type {function(TextDocument): void} */
const onDidOpenOrChangeDocument = document => {
	compiler.setFileSuccess(document.uri, document.getText())
	compiler.searchImportsFromUri(document.uri)
	afterFileChange()
}

const afterFileChange = () => {
	const unknownUris = compiler.allUnknownUris()
	if (unknownUris.length) {
		for (const uri of unknownUris)
			compiler.setFileIssue(uri, "loading")
		logVerbose("Server will notify client of unknown URIs", unknownUris)
		/** @type {crowProtocol.UnknownUris} */
		const message = {unknownUris}
		connection.sendNotification("custom/unknownUris", message)
	} else if (compiler.allLoadingUris().length) {
		logVerbose("Waiting on loading URIs", compiler.allLoadingUris())
	} else {
		for (const {uri, diagnostics} of compiler.getAllDiagnostics().diagnostics) {
			const doc = getDocument(uri)
			if (doc !== null)
				connection.sendDiagnostics(toDiagnostics(doc, diagnostics))
		}
	}
}

// Make the text document manager listen on the connection
// for open, change and close text document events
documents.listen(connection)

/** @type {crow.Compiler} */
let compiler

/** @type {function(TextDocument, ReadonlyArray<crow.Diagnostic>): PublishDiagnosticsParams} */
const toDiagnostics = (document, diagnostics) =>
	({uri:document.uri, diagnostics:diagnostics.map(x => toDiagnostic(x))})

/** @type {function(crow.Diagnostic): Diagnostic} */
const toDiagnostic = ({range, message}) =>
	Diagnostic.create(toRange(range), message)

/** @type {function(crow.RangeWithinFile): Range} */
const toRange = ({start, end}) =>
	Range.create(toPosition(start), toPosition(end))

/** @type {function(crow.LineAndCharacter): Position} */
const toPosition = ({line, character}) =>
	Position.create(line, character)

/** @type {function(crow.UriAndRange): Location} */
const toLocation = ({uri, range}) =>
	Location.create(uri, toRange(range))

/** @type {function(string): TextDocument | null} */
const getDocument = uri => {
	const res = documents.get(uri)
	if (res === undefined) {
		if (!compiler.allUnknownUris().includes(uri))
			logError("Failed to get document.", {
				uri,
				allDocuments: documents.keys().slice().sort(),
				compilerAllUris: compiler.allStorageUris().slice().sort(),
				unknownUris: compiler.allUnknownUris(),
			})
		return null
	} else
		return res
}

connection.onDidChangeWatchedFiles(withLogErrors("onDidChangeWatchedFiles", _change => {
	// Monitored files have change in VSCode
	log("onDidChangeWatchedFiles (unimplemented)", {})
}))

connection.onDefinition(withLogErrors("onDefinition", params => {
	const {definition} = compiler.getDefinition(getUriAndPosition(params))
	return definition === null ? [] : [toLocation(definition)]
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
		log("Crow language server started", {version: compiler.version()})
	} catch (error) {
		logError("Failed to initialize", error)
		throw error
	}
}
setUpCompiler()
