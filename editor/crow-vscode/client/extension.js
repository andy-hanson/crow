/** @typedef {import("vscode").CancellationToken} CancellationToken */
/** @typedef {import("vscode").DocumentSemanticTokensProvider} DocumentSemanticTokensProvider */
/** @typedef {import("vscode").ExtensionContext} ExtensionContext */
/** @typedef {import("vscode").TextDocument} TextDocument */
const {languages, SemanticTokens, Uri, workspace} = require("vscode")
/** @typedef {import("vscode-languageclient").LanguageClientOptions} LanguageClientOptions */
/** @typedef {import("vscode-languageclient/lib/node/main.js").ServerOptions} ServerOptions */
const {LanguageClient, TransportKind} = require("vscode-languageclient/lib/node/main.js")

const {makeCompiler} = require("../server/util.js")
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

	client.onNotification("custom/unknownUris", onUnknownUris)
}

/** @type {function(string): void} */
const log = message =>
	client.outputChannel.appendLine(message)

/** @type {function(crowProtocol.UnknownUris): void} */
const onUnknownUris = ({unknownUris}) => {
	log("client will open unknown URIs " + JSON.stringify(unknownUris))
	for (const uri of unknownUris) {
		log("URI IS " + uri);
		/** @type {Promise<TextDocument>} */ (workspace.openTextDocument(Uri.parse(uri)))
			.then(doc => {
				log("successfully read " + doc.uri)
				// In success case, it will get 'onDidOpen'?
			})
			.catch(error => {
				client.sendNotification("custom/readFileResult", {
					uri,
					type: error.name === 'CodeExpectedError' ? 'notFound' : 'error',
				})
				//log(`error name is: ${error.name}`)
				//log(`error message is: ${error.message}`)
				//log(`error reading ${uri}: ${error}`)
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
	if (myCompiler == null) myCompiler = makeCompiler()
	return myCompiler
}

/**
 * @param {TextDocument} document
 * @param {CancellationToken} _cancellationToken
 * @return {Promise<SemanticTokens>}
 */
const provideDocumentSemanticTokens = async (document, _cancellationToken) => {
	try {
		return getTokens(await getCompiler(), document)
	} catch (e) {
		// VSCode just swallows exceptions, at least log them
		console.log("Caught error in provideDocumentSemanticTokens")
		console.error(/** @type {Error} */ (e).stack)
		throw e
	}
}


/** @type {DocumentSemanticTokensProvider} */
const crowSemanticTokensProvider = {provideDocumentSemanticTokens}
