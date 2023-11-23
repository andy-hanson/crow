/** @typedef {import("vscode").TextDocument} TextDocument */
const {SemanticTokens, SemanticTokensBuilder, SemanticTokensLegend} = require("vscode")

/** @type {function(crow.Compiler, string): SemanticTokens} */
exports.getTokens = (comp, uri) => {
	const builder = new SemanticTokensBuilder()
	for (const {token, range:{start, end}} of comp.getTokens(uri)) {
		if (start.line !== end.line)
			throw new Error("Multi-line token? " + JSON.stringify({token, start, end}))
		const length = end.character - start.character
		builder.push(
			start.line,
			start.character,
			length,
			encodeTokenType(convertToken(token)),
			encodeTokenModifiers([]))
	}
	return builder.build()
}

/**
 * @param {crow.TokenKind} kind
 * @return {TokenType}
 */
const convertToken = kind => {
	switch (kind) {
		case "member":
			return "property"
		case "fun":
			return "function"
		case "identifier":
			return "variable"
		case "import":
			return "namespace"
		case "keyword":
			return "keyword"
		case "lit-num":
			return "number"
		case "lit-str":
			return "string"
		case "local":
			return "variable"
		case "modifier":
			return "keyword"
		case "param":
			return "parameter"
		case "spec":
			return "label"
		case "struct":
			return "type"
		case "var-decl":
			return "variable"
		case "type-param":
			return "typeParameter"
		default:
			return assertNever(kind)
	}
}

/**
 * @param {string} tokenType
 * @return {number}
 */
const encodeTokenType = tokenType =>
	tokenTypes.get(tokenType) || 0

/** @type {function(ReadonlyArray<string>): number} */
const encodeTokenModifiers = modifiers => {
	let result = 0
	for (const mod of modifiers) {
		const modifierNumber = tokenModifiers.get(mod)
		if (modifierNumber !== undefined)
			result = result | (1 << modifierNumber)
	}
	return result
}

/** @type {function(never): never} */
const assertNever = () => {
	throw new Error()
}

/**
@typedef {
	| "comment"
	| "string"
	| "keyword"
	| "number"
	| "regexp"
	| "operator"
	| "namespace"
	| "type"
	| "struct"
	| "class"
	| "interface"
	| "enum"
	| "typeParameter"
	| "function"
	| "method"
	| "macro"
	| "variable"
	| "parameter"
	| "property"
	| "label"
} TokenType
*/

/** @type {ReadonlyArray<TokenType>} */
const tokenTypesLegend = [
	"comment",
	"string",
	"keyword",
	"number",
	"regexp",
	"operator",
	"namespace",
	"type",
	"struct",
	"class",
	"interface",
	"enum",
	"typeParameter",
	"function",
	"method",
	"macro",
	"variable",
	"parameter",
	"property",
	"label"
]

/**
@typedef {
	| "declaration"
	| "documentation"
	| "readonly"
	| "static"
	| "abstract"
	| "deprecated"
	| "modification"
	| "async"
} TokenModifier
*/

/** @type {ReadonlyArray<TokenModifier>} */
const tokenModifiersLegend = [
	"declaration",
	"documentation",
	"readonly",
	"static",
	"abstract",
	"deprecated",
	"modification",
	"async",
]

/** @type {Map<string, number>} */
const tokenTypes = new Map()
tokenTypesLegend.forEach((tokenType, index) => {
	tokenTypes.set(tokenType, index)
})

/** @type {Map<string, number>} */
const tokenModifiers = new Map()
tokenModifiersLegend.forEach((tokenModifier, index) => {
	tokenModifiers.set(tokenModifier, index)
})
exports.crowSemanticTokensLegend = new SemanticTokensLegend(
	/** @type {string[]} */ (tokenTypesLegend),
	/** @type {string[]} */ (tokenModifiersLegend))
