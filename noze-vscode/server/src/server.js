/// <reference path="../../../doc/script/Compiler.js" />

const fs = require("fs")
const {createConnection, TextDocuments, ProposedFeatures} = require("vscode-languageserver")
const {DidChangeConfigurationNotification} = require("vscode-languageserver-protocol")
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
require2("../../../doc/script/Compiler.js")

const connection = createConnection(ProposedFeatures.all)

/** @type {TextDocuments<TextDocument>} */
const documents = new TextDocuments(TextDocument)

let hasConfigurationCapability = false
let hasWorkspaceFolderCapability = false

connection.onInitialize(params => {
	let capabilities = params.capabilities

	// Does the client support the `workspace/configuration` request?
	// If not, we fall back using global settings.
	hasConfigurationCapability = !!(
		capabilities.workspace && !!capabilities.workspace.configuration
	)
	hasWorkspaceFolderCapability = !!(
		capabilities.workspace && !!capabilities.workspace.workspaceFolders
	)

	/** @type {InitializeResult} */
	const result = {
		capabilities: {
			textDocumentSync: TextDocumentSyncKind.Incremental,
			// Tell the client that this server supports code completion.
			completionProvider: {
				resolveProvider: true
			},

		}
	}
	if (hasWorkspaceFolderCapability) {
		result.capabilities.workspace = {
			workspaceFolders: {
				supported: true
			}
		}
	}
	return result
})

connection.onInitialized(() => {
	if (hasConfigurationCapability) {
		// Register for all configuration changes.
		connection.client.register(DidChangeConfigurationNotification.type, undefined)
	}
	if (hasWorkspaceFolderCapability) {
		connection.workspace.onDidChangeWorkspaceFolders(_event => {
			connection.console.log('Workspace folder change event received.')
		})
	}
})

// The content of a text document has changed. This event is emitted
// when the text document first opened or when its content has changed.
documents.onDidChangeContent(change => {
	const fn = async () => {
		connection.sendDiagnostics(await getSyntaxDiagnostics(change.document))
	}
	fn().catch(e => {
		console.error("CAUGHT ERROR", e)
		throw e
	})
})

/** @type {Promise<compiler.Compiler> | null} */
let myCompiler = null
/** @type {function(): Promise<compiler.Compiler>} */
const getCompiler = () => {
	if (myCompiler == null) {
		const bytes = fs.readFileSync(__dirname + "/../../../bin/noze.wasm")
		/** @type {Files} */
		const include = {} // TODO
		myCompiler = compiler.Compiler.makeFromBytes(bytes, include)
	}
	return myCompiler
}

/** @type {function(TextDocument): Promise<PublishDiagnosticsParams>} */
const getSyntaxDiagnostics = async document => {
	const tokens = (await getCompiler()).getTokens(document.getText())
	return {
		uri: document.uri,
		diagnostics: tokens.diags.map(diag => {
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
	}
}

/**
 * @param {TextDocuments<TextDocument>} documents
 * @return {Promise<ReadonlyArray<PublishDiagnosticsParams>>}
 */
const getAllDiagnostics = async documents => {
	/** @type {{[key: string]: string}} */
	const files = {}
	const all = documents.all()
	for (const document of all) {
		document.positionAt(1)
		files[document.uri] = document.getText()
	}

	//TODO: real validation
	for (const fileName in files) {
		return [
			{
				uri: fileName,
				diagnostics: [
					{
						severity: DiagnosticSeverity.Error,
						range: {
							start: {line:1,character:1},
							end: {line:1,character:2},
						},
						message: 'I AM ERROR',
						source: 'ex', //TODO: What is this?
					}
				],
			}
		]
	}

	return []
}
getAllDiagnostics;

/*
/** @type {function(TextDocument): Promise<PublishDiagnosticsParams>} * /
const validateTextDocument = async textDocument => {
	// The validator creates diagnostics for all uppercase words length 2 and more
	const text = textDocument.getText()
	const pattern = /\b[A-Z]{2,}\b/g
	/** @type {RegExpExecArray | null} * /
	let m

	let problems = 0
	/** @type {Diagnostic[]} * /
	const diagnostics = []
	while ((m = pattern.exec(text)) && problems < 1000) {
		problems++
		/** @type {Diagnostic} * /
		let diagnostic = {
			severity: DiagnosticSeverity.Warning,
			range: {
				start: textDocument.positionAt(m.index),
				end: textDocument.positionAt(m.index + m[0].length)
			},
			message: `${m[0]} is all uppercase.`,
			source: 'ex'
		}
		if (hasDiagnosticRelatedInformationCapability) {
			diagnostic.relatedInformation = [
				{
					location: {
						uri: textDocument.uri,
						range: Object.assign({}, diagnostic.range)
					},
					message: 'Spelling matters'
				},
				{
					location: {
						uri: textDocument.uri,
						range: Object.assign({}, diagnostic.range)
					},
					message: 'Particularly for names'
				}
			]
		}
		diagnostics.push(diagnostic)
	}

	return { uri: textDocument.uri, diagnostics }
}
*/

connection.onDidChangeWatchedFiles(_change => {
	// Monitored files have change in VSCode
	connection.console.log('We received an file change event')
})

// This handler provides the initial list of the completion items.
connection.onCompletion(_textDocumentPosition => {
	// The pass parameter contains the position of the text document in
	// which code complete got requested. For the example we ignore this
	// info and always provide the same completion items.
	/** @type {CompletionItem[]} */
	const res = [
		{
			label: 'TypeScript',
			kind: CompletionItemKind.Text,
			data: 1
		},
		{
			label: 'JavaScript',
			kind: CompletionItemKind.Text,
			data: 2
		}
	]
	return res
})

// This handler resolves additional information for the item selected in
// the completion list.
connection.onCompletionResolve(item => {
	if (item.data === 1) {
		item.detail = 'TypeScript details'
		item.documentation = 'TypeScript documentation'
	} else if (item.data === 2) {
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
