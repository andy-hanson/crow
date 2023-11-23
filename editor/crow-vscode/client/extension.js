/** @typedef {import("vscode").CancellationToken} CancellationToken */
/** @typedef {import("vscode").DocumentSemanticTokensProvider} DocumentSemanticTokensProvider */
/** @typedef {import("vscode").ExtensionContext} ExtensionContext */
/** @typedef {import("vscode").TextDocument} TextDocument */
const {languages, SemanticTokens, Uri, workspace} = require("vscode")
/** @typedef {import("vscode-languageclient").LanguageClientOptions} LanguageClientOptions */
/** @typedef {import("vscode-languageclient/lib/node/main.js").ServerOptions} ServerOptions */
const {LanguageClient, TransportKind} = require("vscode-languageclient/lib/node/main.js")

const {makeCompiler, nonNull, LOG_VERBOSE} = require("../server/util.js")
const {crowSemanticTokensLegend, getTokens} = require("./tokens.js")

/** @type {LanguageClient} */
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

/** @type {function(crowProtocol.UnknownUris): void} */
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
				/** @type {crowProtocol.ReadFileResult} */
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
		const uri = document.uri.toString()
		const comp = await getCompiler()
		comp.setFileSuccess(uri, document.getText())
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
