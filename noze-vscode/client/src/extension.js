const path = require("path")
/** @typedef {import("vscode").CancellationToken} CancellationToken */
/** @typedef {import("vscode").DocumentSemanticTokensProvider} DocumentSemanticTokensProvider */
/** @typedef {import("vscode").ExtensionContext} ExtensionContext */
/** @typedef {import("vscode").TextDocument} TextDocument */
const {languages, workspace, SemanticTokens, SemanticTokensBuilder, SemanticTokensLegend} = require("vscode")

/** @typedef {import("../node_modules/vscode-languageclient").LanguageClientOptions} LanguageClientOptions */
/** @typedef {import("../node_modules/vscode-languageclient").ServerOptions} ServerOptions */
const {LanguageClient, TransportKind} = require("../node_modules/vscode-languageclient")

/** @type {LanguageClient | undefined} */
let client

/** @type {function(ExtensionContext): void} */
exports.activate = context => {
	const serverModule = context.asAbsolutePath(path.join('server', 'src', 'server.js'))
	// The debug options for the server
	// --inspect=6009: runs the server in Node's Inspector mode so VS Code can attach to the server for debugging
	const debugOptions = {execArgv:['--nolazy', '--inspect=6009']}

	// If the extension is launched in debug mode then the debug server options are used
	// Otherwise the run options are used
	/** @type {ServerOptions} */
	const serverOptions = {
		run: {module:serverModule, transport:TransportKind.ipc},
		debug: {
			module: serverModule,
			transport: TransportKind.ipc,
			options: debugOptions
		}
	}

	/** @type {LanguageClientOptions} */
	const clientOptions = {
		// Register the server for plain text documents
		documentSelector: [{ scheme: 'file', language: 'noze' }],
		synchronize: {
			// Notify the server about file changes to '.clientrc files contained in the workspace
			fileEvents: workspace.createFileSystemWatcher('**/.clientrc')
		},
	}

	client = new LanguageClient('languageServerExample', 'Language Server Example', serverOptions, clientOptions)
	client.start()

	context.subscriptions.push(languages.registerDocumentSemanticTokensProvider({ language: 'noze'}, new MyDocumentSemanticTokensProvider(), legend))
}

/** @type {function(): Thenable<void> | undefined} */
exports.deactivate = () =>
	client && client.stop()


/** @type {Map<string, number>} */
const tokenTypes = new Map()
/** @type {Map<string, number>} */
const tokenModifiers = new Map()

const legend = (function () {
	const tokenTypesLegend = [
		'comment', 'string', 'keyword', 'number', 'regexp', 'operator', 'namespace',
		'type', 'struct', 'class', 'interface', 'enum', 'typeParameter', 'function',
		'method', 'macro', 'variable', 'parameter', 'property', 'label'
	];
	tokenTypesLegend.forEach((tokenType, index) => tokenTypes.set(tokenType, index));

	const tokenModifiersLegend = [
		'declaration', 'documentation', 'readonly', 'static', 'abstract', 'deprecated',
		'modification', 'async'
	];
	tokenModifiersLegend.forEach((tokenModifier, index) => tokenModifiers.set(tokenModifier, index));

	return new SemanticTokensLegend(tokenTypesLegend, tokenModifiersLegend);
})();

/**
 * @typedef IParsedToken
 * @property {number} line
 * @property {number} startCharacter
 * @property {number} length
 * @property {string} tokenType
 * @property {string[]} tokenModifiers
 */


/** @implements {DocumentSemanticTokensProvider} */
class MyDocumentSemanticTokensProvider {
	/**
	 * @param {TextDocument} document
	 * @param {CancellationToken} _token
	 * @return {Promise<SemanticTokens>}
	 */
	async provideDocumentSemanticTokens(document, _token) {
		const allTokens = this._parseText(document.getText());
		const builder = new SemanticTokensBuilder();
		allTokens.forEach((token) => {
			builder.push(token.line, token.startCharacter, token.length, this._encodeTokenType(token.tokenType), this._encodeTokenModifiers(token.tokenModifiers));
		});
		return builder.build();
	}

	/**
	 * @private
	 * @param {string} tokenType
	 * @return {number}
	 */
	_encodeTokenType(tokenType) {
		if (tokenTypes.has(tokenType)) {
			return nonUndefined(tokenTypes.get(tokenType));
		} else if (tokenType === 'notInLegend') {
			return tokenTypes.size + 2;
		}
		return 0;
	}

	/**
	 * @private
	 * @param {ReadonlyArray<string>} strTokenModifiers
	 * @return {number}
	 */
	_encodeTokenModifiers(strTokenModifiers) {
		let result = 0;
		for (let i = 0; i < strTokenModifiers.length; i++) {
			const tokenModifier = strTokenModifiers[i];
			if (tokenModifiers.has(tokenModifier)) {
				result = result | (1 << nonUndefined(tokenModifiers.get(tokenModifier)));
			} else if (tokenModifier === 'notInLegend') {
				result = result | (1 << tokenModifiers.size + 2);
			}
		}
		return result;
	}

	/**
	 * @private
	 * @param {string} text
	 * @return {IParsedToken[]}
	 */
	_parseText(text) {
		/** @type {IParsedToken[]} */
		const r = [];
		const lines = text.split(/\r\n|\r|\n/);
		for (let i = 0; i < lines.length; i++) {
			const line = lines[i];
			let currentOffset = 0;
			do {
				const openOffset = line.indexOf('[', currentOffset);
				if (openOffset === -1) {
					break;
				}
				const closeOffset = line.indexOf(']', openOffset);
				if (closeOffset === -1) {
					break;
				}
				const tokenData = this._parseTextToken(line.substring(openOffset + 1, closeOffset));
				r.push({
					line: i,
					startCharacter: openOffset + 1,
					length: closeOffset - openOffset - 1,
					tokenType: tokenData.tokenType,
					tokenModifiers: tokenData.tokenModifiers
				});
				currentOffset = closeOffset;
			} while (true);
		}
		return r;
	}

	/**
	 * @private
	 * @param {string} text
	 * @return {{ tokenType: string; tokenModifiers: string[]; }}
	 */
	_parseTextToken(text) {
		const parts = text.split('.');
		return {
			tokenType: parts[0],
			tokenModifiers: parts.slice(1)
		};
	}
}

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
