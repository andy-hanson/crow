const childProcess = require("child_process")
/** @typedef {import("vscode").ExtensionContext} ExtensionContext */
/** @typedef {import("vscode").TextDocument} TextDocument */
const { Uri, workspace } = require("vscode")
/** @typedef {import("vscode-languageclient").LanguageClientOptions} LanguageClientOptions */
/** @typedef {import("vscode-languageclient/lib/node/main.js").ServerOptions} ServerOptions */
const { LanguageClient } = require("vscode-languageclient/lib/node/main.js")

/** @type {LanguageClient} */
let client

/** @type {function(ExtensionContext): void} */
exports.activate = context => {
	/** @type {ServerOptions} */
	const serverOptions = () => {
		const proc = childProcess.spawn("crow", ["lsp"], {stdio:'pipe'})
		proc.stderr.on('data', chunk => {
			logError("Crow stderr:", chunk.toString('utf-8'))
		})
		proc.stderr.on('close', () => {
			console.log("Crow stderr closed")
		})
		return Promise.resolve(proc)
	}

	/** @type {LanguageClientOptions} */
	const clientOptions = {
		documentSelector: [{scheme:"file", language:"crow"}],
		outputChannelName: 'Crow language server',
	}
	client = new LanguageClient("crow", "Crow language server", serverOptions, clientOptions)
	client.start()

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
			logError(`Error in ${description}: ` + (/** @type {Error} */ (error)).stack)
			throw error
		}
	}
}

/** @type {function(string): void} */
const logError = message => {
	client.outputChannel.appendLine(message)
}

/** @type {function({unknownUris: ReadonlyArray<string>}): void} */
const onUnknownUris = ({unknownUris}) => {
	for (const uri of unknownUris) {
		/** @type {Promise<TextDocument>} */ (workspace.openTextDocument(Uri.parse(uri)))
			// This triggers 'onDidOpen', so no need to do anything else on success
			.catch(error => {
				if (error.name !== "CodeExpectedError")
					logError(`Error reading file: ${JSON.stringify({uri, error})}`)
				client.sendNotification("custom/readFileResult", {
					uri,
					type: error.name === "CodeExpectedError" ? "notFound" : "error",
				})
			})
	}
}

/** @type {function(): Thenable<void> | undefined} */
exports.deactivate = () =>
	client && client.stop()
