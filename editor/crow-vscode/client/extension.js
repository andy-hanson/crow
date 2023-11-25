const childProcess = require("child_process")
const fs = require("fs")
const path = require("path")
/** @typedef {import("vscode").CancellationToken} CancellationToken */
/** @typedef {import("vscode").DocumentSemanticTokensProvider} DocumentSemanticTokensProvider */
/** @typedef {import("vscode").ExtensionContext} ExtensionContext */
/** @typedef {import("vscode").TextDocument} TextDocument */
const {languages, SemanticTokens, Uri, workspace} = require("vscode")
/** @typedef {import("vscode-languageclient").LanguageClientOptions} LanguageClientOptions */
/** @typedef {import("vscode-languageclient/lib/node/main.js").ServerOptions} ServerOptions */
/** @typedef {import("vscode-languageclient/lib/node/main.js").StreamInfo} StreamInfo */
const {LanguageClient} = require("vscode-languageclient/lib/node/main.js")
const protocol = require("vscode-languageserver-protocol")

// @ts-ignore
require("../../../crow-js/crow.js")

const {crowSemanticTokensLegend, getTokens} = require("./tokens.js")

const crowDir = path.join(__dirname, "../../../")
/** @type {function(crow.Logger): Promise<crow.Compiler>} */
const makeCompiler = logger =>
	crow.makeCompiler(
		fs.readFileSync(path.join(crowDir, "bin/crow.wasm")),
		path.join(crowDir, "include"),
		// TODO: get the real CWD from VSCode API
		crowDir,
		logger)

/**
 * @template T
 * @param {T | null | undefined} x
 * @return {T}
 */
const nonNull = x => {
	if (x == null)
		throw new Error("Null value")
	return x
}

const LOG_VERBOSE = false

/** @type {LanguageClient} */
let client

/** @type {function(ExtensionContext): void} */
exports.activate = context => {
	// TODO: '.exe' on Windows
	const crowPath = context.asAbsolutePath("../../bin/crow-debug")

	/** @type {ServerOptions} */
	const serverOptions = () => {
		const proc = childProcess.spawn(crowPath, ['lsp'], {stdio:'pipe'})

		proc.stderr.on('data', chunk => {
			console.log("GOT A CHUNK OF STDERR", chunk.toString('utf-8'))
		})
		proc.stderr.on('close', () => {
			console.log("stderr closed??")
		})

		// Use this to log the server's responsees
		//cp.stdout.on('data', chunk => {
		//	console.log("GOT A CHUNK OF STDOUT", chunk.toString('utf-8'))
		//})

		// TODO: log when cp closed
		return Promise.resolve(proc)
	}

	/** @type {LanguageClientOptions} */
	const clientOptions = {
		documentSelector: [{scheme:"file", language:"crow"}],
		outputChannelName: 'Crow language server',
	}
	client = new LanguageClient("crow", "Crow language server", serverOptions, clientOptions)
	client.start()

	context.subscriptions.push(
		languages.registerDocumentSemanticTokensProvider(
			{language:"crow"},
			crowSemanticTokensProvider,
			crowSemanticTokensLegend))

	client.onNotification("custom/unknownUris", withLogErrors("unknownUris", onUnknownUris))
}

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
			log(`Error in ${description}: ` + (/** @type {Error} */ (error)).stack)
			throw error
		}
	}
}

/** @type {function(string): void} */
const log = message => {
	client.outputChannel.appendLine(message)
}
/** @type {function(string): void} */
const logError = message => {
	client.outputChannel.appendLine("ERROR: " + message)
}
/** @type {function(string): void} */
const logVerbose = message => {
	if (LOG_VERBOSE)
		log(message)
}

/** @type {function(crow.UnknownUris): void} */
const onUnknownUris = ({unknownUris}) => {
	for (const uri of unknownUris) {
		logVerbose(`Handle unknown uri ${uri}`);
		/** @type {Promise<TextDocument>} */ (workspace.openTextDocument(Uri.parse(uri)))
			.then(document => {
				logVerbose(`Successfully opened ${document.uri}`)
				// This triggers 'onDidOpen', so no need to do anything else on success
			})
			.catch(error => {
				if (error.name !== "CodeExpectedError")
					logVerbose(`Error reading file: ${JSON.stringify({uri, error})}`)
				/** @type {crow.ReadFileResult} */
				const message = {
					uri,
					type: error.name === "CodeExpectedError" ? "notFound" : "error",
				}
				client.sendNotification("custom/readFileResult", message)
			})
	}
}

/** @type {function(): Thenable<void> | undefined} */
exports.deactivate = () =>
	client && client.stop()

/** @type {Promise<crow.Compiler> | null} */
let myCompiler = null
/** @type {function(): Promise<crow.Compiler>} */
const getCompiler = () => {
	if (myCompiler == null) myCompiler = makeCompiler(console.log)
	return myCompiler
}

/**
 * @param {TextDocument} document
 * @param {CancellationToken} _cancellationToken
 * @return {Promise<SemanticTokens>}
 */
const provideDocumentSemanticTokens = async (document, _cancellationToken) => {
	try {
		console.log("TOP OF provideDocumentSemanticTokens")
		log("Will get tokens")
		const uri = document.uri.toString()
		const comp = await getCompiler()
		/** @type {protocol.DidOpenTextDocumentParams} */
		const params = {
			textDocument: {uri, languageId:document.languageId, version:document.version, text:document.getText()},
		}
		//TODO: this opens it every time...
		comp.handleLspMessage({method:"textDocument/didOpen", params})
		log("Will really get tokens this time")
		return getTokens(comp, uri)
	} catch (e) {
		// VSCode just swallows exceptions, at least log them
		logError(`Caught error in provideDocumentSemanticTokens for ${document.uri}: ${
			nonNull(/** @type {Error} */ (e).stack)
		}`)
		throw e
	}
}

/** @type {DocumentSemanticTokensProvider} */
const crowSemanticTokensProvider = {provideDocumentSemanticTokens}
