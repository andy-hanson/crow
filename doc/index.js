export {}

window.onload = () => {
	main().catch(e => { console.error(e) })
}

/** @type {function(boolean): void} cond */
const assert = cond => {
	if (!cond) throw new Error('Assertion failed')
}

/**
 * @typedef Exports
 * @property {function(): number} getBufferSize
 * @property {function(): number} getBuffer
 * @property {function(): void} getTokens
 * @property {WebAssembly.Memory} memory
 */

/**
 * @typedef Range
 * @property {[number, number]} args
 */

/**
 * @typedef Token
 * @property {string} kind
 * @property {Range} range
 */

 /**
  * @typedef TokensDiags
  * @property {ReadonlyArray<Token>} tokens
  * @property {ReadonlyArray<Diagnostic>} diags
  */

class Noze {
	static async make() {
		const bytes = await (await fetch("../bin/noze.wasm")).arrayBuffer()
		const result = await WebAssembly.instantiate(bytes, {})
		const { exports } = result.instance;
		exports.memory;
		return new Noze(/** @type {Exports} */ (exports))
	}

	/** @param {Exports} exports */
	constructor(exports) {
		/** @type {Exports} */
		this._exports = exports
		const { getBufferSize, getBuffer, memory } = exports
		const view = new DataView(memory.buffer)
		const bufferSize = getBufferSize()
		const buffer = getBuffer()
		/** @type {function(string): void} */
		this._setStr = str =>
			writeString(view, buffer, bufferSize, str)
		/** @type {function(): string} */
		this._getStr = () =>
			readString(view, buffer, bufferSize)
	}

	/**
	 * @param {string} src
	 * @return {TokensDiags}
	 */
	getTokens(src) {
		this._setStr(src)
		this._exports.getTokens()
		const json = this._getStr()
		return JSON.parse(json)
	}
}

/** @type {function(ReadonlyArray<Token>, string): ReadonlyArray<Node>} */
const tokensToNodes = (tokens, text) => {
	console.log("TOKENS", tokens)
	let pos = 0
	/** @type {Array<Node>} */
	const lines = []
	/** @type {Array<Node>} */
	let curLine = []

	const nextLine = () => {
		lines.push(createDiv({ className: "line", children: curLine }))
		curLine = []
	}

	/** @type {function(number): void} */
	const walkTo = end => {
		if (pos < end) {
			const nl = text.indexOf('\n', pos)
			if (nl < end) {
				if (pos < nl)
					curLine.push(createSpan('no-token', text.slice(pos, nl)))
				pos = nl + 1
				nextLine()
				walkTo(end)
			} else {
				curLine.push(createSpan('no-token', text.slice(pos, end)))
				pos = end
			}
		}
	}

	/** @type {function(string, number): void} */
	const addSpan = (className, end) => {
		assert(pos < end)
		curLine.push(createSpan(className, text.slice(pos, end)))
		pos = end
	}

	for (const token of tokens) {
		const tokenPos = token.range.args[0]
		const tokenEnd = token.range.args[1]
		walkTo(tokenPos)
		addSpan(classForKind(token.kind), tokenEnd)
	}

	walkTo(text.length)
	nextLine()
	return lines
}



/** @type {function(string): string} */
const classForKind = kind => {
	return kind
}

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

const TEST_SRC = `
import
	io

r record
	x int

to-int<?a> spec
	to-int int(a ?a)

main void(r r)
	r.x + 0
`

const main = async () => {
	const noze = await Noze.make()

	const nozeDiv = nonNull(document.querySelector(".noze"))
	const highlightDiv = document.createElement("div")
	highlightDiv.className = "highlight"
	nozeDiv.appendChild(highlightDiv)
	const ta = document.createElement("textarea")
	nozeDiv.appendChild(ta)
	ta.value = TEST_SRC
	ta.setAttribute("spellcheck", "false")

	ta.addEventListener("keydown", e => {
		const { keyCode } = e
		const { value, selectionStart, selectionEnd } = ta
		if (keyCode === "\t".charCodeAt(0)) {
			e.preventDefault()
			ta.value = value.slice(0, selectionStart) + "\t" + value.slice(selectionEnd)
			ta.setSelectionRange(selectionStart + 1, selectionStart + 1);
			highlight(noze, highlightDiv, ta)
		}
	})
	ta.addEventListener("input", () => {
		highlight(noze, highlightDiv, ta)
	})
	highlight(noze, highlightDiv, ta)
	console.log("DONE")
}

/** @type {function(Node): void} */
const removeAllChildren = em => {
	while (em.lastChild)
		em.removeChild(em.lastChild)
}

/** @type {function(Noze, Node, HTMLTextAreaElement): void} */
const highlight = (noze, highlightDiv, ta) => {
	const v = ta.value
	const tokens = noze.getTokens(v).tokens
	console.log("?", {v, tokens})
	const nodes = tokensToNodes(tokens, v)
	console.log("NODES", nodes)

	//const valueLines = v.split("\n")
	removeAllChildren(highlightDiv)

	for (const node of nodes)
		highlightDiv.appendChild(node)

	/*
	for (let i = 0; i < valueLines.length; i++) {
		const lineText = valueLines[i].replace(/\t/g, " ".repeat(4))
		const childTextClass = i == 0 ? "keyword" : "name"
		highlightDiv.appendChild(createDiv({
			className: "line",
			children: [createSpan(childTextClass, lineText)],
		}))
	}
	*/
}

/** @type {function({className?: string, children?: ReadonlyArray<Node>}): HTMLDivElement} */
const createDiv = (options) => {
	const div = document.createElement("div")
	if (options.className)
		div.className = options.className
	if (options.children)
		for (const child of options.children)
			div.appendChild(child)
	return div
}

/** @type {function(string, string): HTMLSpanElement} */
const createSpan = (className, text) => {
	const span = document.createElement("span")
	span.className = className
	span.innerText = text
	return span
}

/** @type {function(HTMLElement): Promise<void>} */
const fillIn = async node => {
	const src = node.getAttribute("data-src")
	console.log(src)
	const text = await (await fetch(`../test/runnable/${src}`)).text()
	node.innerText = text
}

/** @type {function(DataView, number, number, string): void} */
function writeString(view, buffer, bufferSize, str) {
	if (str.length >= bufferSize)
		throw new Error("input too long")
	for (let i = 0; i < str.length; i++)
		view.setUint8(buffer + i, str.charCodeAt(i))
	view.setUint8(buffer + str.length, 0)
}

/** @type {function(DataView, number, number): string} */
function readString(view, buffer, bufferSize) {
	let s = ""
	let i;
	for (i = 0; i < bufferSize; i++) {
		const code = view.getUint8(buffer + i)
		if (code === 0)
			break
		s += String.fromCharCode(code)
	}
	if (i == bufferSize)
		throw new Error("TOO LONG")
	return s
}
