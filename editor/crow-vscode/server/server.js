const {createConnection, ProposedFeatures} = require("vscode-languageserver")
/** @typedef {import("vscode-languageserver-protocol").TextDocumentPositionParams} TextDocumentPositionParams */
const {
	DidChangeConfigurationNotification, DefinitionRequest, HoverRequest,
} = require("vscode-languageserver-protocol")
/** @typedef {import("vscode-languageserver-types").CompletionItem} CompletionItem */
/** @typedef {import("vscode-languageserver-types").WorkspaceEdit} WorkspaceEdit */
const {CompletionItemKind} = require("vscode-languageserver-types")
const {TextDocumentSyncKind} = require("vscode-languageserver-protocol")
/** @typedef {import("vscode-languageserver-protocol").InitializeParams} InitializeParams */
/** @typedef {import("vscode-languageserver-protocol").InitializeResult<unknown>} InitializeResult */
/** @typedef {import("vscode-languageserver-protocol").PublishDiagnosticsParams} PublishDiagnosticsParams */
/** @typedef {import("vscode-languageserver-protocol").TextDocumentContentChangeEvent} TextDocumentContentChangeEvent */
const {TextDocument} = require("vscode-languageserver-textdocument")

const {makeCompiler, LOG_PERF, LOG_VERBOSE} = require("./util.js")

// @ts-ignore
const connection = createConnection(ProposedFeatures.all)

/** @type {function(string, unknown): string} */
const formatLog = (message, content) =>
	content === undefined ? message : `${new Date().toISOString()} ${message}: ${JSON.stringify(content)}`

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
	if (LOG_VERBOSE)
		log(message, content)
}

/** @type {function(string, ?unknown): void} */
const logPerf = (message, content) => {
	if (LOG_PERF)
		log(message, content)
}

/**
 * @template P, R
 * @param {string} description
 * @param {(params: P) => R} cb
 * @return {(params: P) => R}
 */
const withLogErrors = (description, cb) => {
	return params => {
		const paramsWithDocument = /** @type {{document:TextDocument | undefined}} */ (params)
		const info = paramsWithDocument.document ? {...params, document:paramsWithDocument.document.uri} : params
		try {
			logVerbose(`begin ${description}`, info)
			return cb(params)
		} catch (error) {
			log(`Error in ${description}`, {stack:(/** @type {Error} */ (error)).stack})
			throw error
		} finally {
			logVerbose("end " + description, info)
		}
	}
}

connection.onInitialize(_params => {
	/** @type {InitializeResult} */
	const result = {
		capabilities: {
			textDocumentSync: TextDocumentSyncKind.Incremental,
			completionProvider: {resolveProvider: true},
			referencesProvider: {},
			renameProvider: {}
		},
	}
	return result
})

connection.onInitialized(withLogErrors("onInitialized", _params => {
	for (const request of [DefinitionRequest, HoverRequest]) {
		connection.client.register(request.type)
	}
	connection.client.register(DidChangeConfigurationNotification.type, undefined)
}))

connection.onDidOpenTextDocument(withLogErrors("onDidOpenTextDocument", params => {
	const {uri, text} = params.textDocument
	compiler.setFileSuccess(uri, text)
	afterOpenOrChangeFile(uri)
}))

connection.onDidChangeTextDocument(withLogErrors("onDidChangeTextDocument", params => {
	const {contentChanges, textDocument:{uri}} = params
	compiler.changeFile(uri, contentChanges)
	afterOpenOrChangeFile(uri)
}))

connection.onDidCloseTextDocument(withLogErrors("onDidCloseTextDocument", _params => {
}))

/** @type {function(crowProtocol.ReadFileResult): void} */
const onReadFileResult = ({uri, type}) => {
	logVerbose("onReadFileResult", {uri, type})
	compiler.setFileIssue(uri, type)
	afterFileChange()
}
// 'onDidOpen' should handle normal files, this is for file not found or error
connection.onNotification("custom/readFileResult", withLogErrors("readFileResult", onReadFileResult))

/** @type {function(crow.Uri): void} */
const afterOpenOrChangeFile = uri => {
	compiler.searchImportsFromUri(uri)
	afterFileChange()
}

let lastDiagnosticsUris = new Set()

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
		const newDiags = compiler.getAllDiagnostics() // TODO: use getDiagnosticsForUri?
		for (const {uri, diagnostics} of newDiags) {
			lastDiagnosticsUris.delete(uri)
			connection.sendDiagnostics({uri, diagnostics})
		}
		for (const uri of lastDiagnosticsUris)
			connection.sendDiagnostics({uri, diagnostics:[]})
		lastDiagnosticsUris = new Set(newDiags.map(x => x.uri))
	}
}

/** @type {crow.Compiler} */
let compiler

connection.onDidChangeWatchedFiles(withLogErrors("onDidChangeWatchedFiles", _change => {
	// Monitored files have change in VSCode
	log("onDidChangeWatchedFiles (unimplemented)", {})
}))

connection.onDefinition(withLogErrors("onDefinition", params =>
	compiler.handleLspMessage("textDocument/definition", params)))

connection.onHover(withLogErrors("onHover", params =>
	compiler.handleLspMessage("textDocument/hover", params)))

connection.onReferences(withLogErrors("onReferences", params =>
	compiler.getReferences(getUriLineAndCharacter(params))))

connection.onRenameRequest(withLogErrors("onRename", params =>
	compiler.getRename(getUriLineAndCharacter(params), params.newName)))

/** @type {function(TextDocumentPositionParams): crow.UriLineAndCharacter} */
const getUriLineAndCharacter = ({textDocument, position}) =>
	({uri:textDocument.uri, position})

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
		const start = +new Date()
		compiler = await makeCompiler(log)
		logPerf("Time to start compiler", {time:+new Date() - start})
		connection.listen()
		log("Crow language server started", {version: compiler.version()})
	} catch (error) {
		logError("Failed to initialize", error)
		throw error
	}
}
setUpCompiler()
