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
 * @typedef Diagnostic
 * @property {string} message
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

/**
 * @typedef AllContainer
 * @property {"all"} type
 * @property {Array<Node>} children
 */

/**
 * @typedef LineContainer
 * @property {"line"} type
 * @property {Array<Node>} children
 */

/**
 * @typedef DiagContainer
 * @property {"diag"} type
 * @property {Array<Node>} children
 * @property {number} end
 * @property {string} message
 */

/**
 * @typedef {AllContainer | LineContainer | DiagContainer} Container
 */

/**
 * @template T
 * @param {ReadonlyArray<T>} xs
 * @return {T}
*/
const last = xs => {
	if (xs.length === 0) throw new Error()
	return xs[xs.length - 1]
}

/**
 * @template T
 * @param {ReadonlyArray<T>} xs
 * @return {T}
 */
const secondLast = xs => {
	if (xs.length < 2) throw new Error()
	return xs[xs.length - 2]
}

/**
 * @template T
 * @param {Array<T>} xs
 * @return {T}
 */
const mustPop = xs => {
	return nonNull(xs.pop())
}

/**
 * @param {string} msg
 * @return {never}
 */
const unreachable = msg => {
	throw new Error(msg)
}

/** @type {function(string, ReadonlyArray<Node | string>): HTMLSpanElement} */
const createDiagSpan = (message, children) => {
	return createSpan({
		attr: {"data-tooltip": message},
		className: "diag",
		children,
	})
}

/** @type {function(ReadonlyArray<Token>, ReadonlyArray<Diagnostic>, string): ReadonlyArray<Node>} */
const tokensAndDiagsToNodes = (tokens, diags, text) => {
	let pos = 0
	// Last entry is the most nested container
	/** @type {Array<Container>} */
	const containerStack = [
		{type:"all", children:[]},
	]

	const popContainer = () => {
		const popped = mustPop(containerStack)
		const child = popped.type === "diag"
				? createDiagSpan(popped.message, popped.children)
			: popped.type === "line"
				? createDiv({ className: "line", children: popped.children })
			: unreachable(`Unexpected type ${popped.type}`);
		const lastContainer = last(containerStack)
		if (lastContainer.type === "text")
			throw new Error() // text can't contain other nodes
		lastContainer.children.push(child)
	}

	const startLine = () => {
		containerStack.push({type:"line", children:[]})
	}

	const endLine = () => {
		while (last(containerStack).type !== "line")
			popContainer()
		popContainer()
	}

	const nextLine = () => {
		endLine()
		startLine()
	}

	const finishText = () => {
		const l = last(containerStack)
		if (l.type === "text") {
			mustPop(containerStack)
			const newLast = last(containerStack)
			if (newLast.type === "text")
				throw new Error() // text can't contain other nodes
			newLast.children.push(createSpan({ className: "no-token", children: [l.text] }))
		}
	}

	/** @type {function(number): boolean} */
	const maybeStartDiag = nextPos => {
		if (diagIndex < diags.length) {
			const diag = diags[diagIndex]
			if (diag.range.args[0] < nextPos) {
				// Ignore nested diags
				if (last(containerStack).type !== "diag") {
					finishText()
					containerStack.push({type:"diag", children:[], end:diag.range.args[1], message:diag.message})
				}
				diagIndex++
				return true
			}
		}
		return false
	}

	/** @type {function(number): boolean} */
	const shouldStopDiag = tokenEnd => {
		const lastContainer = last(containerStack)
		return lastContainer.type === "diag" && lastContainer.end <= tokenEnd
	}

	/** @type {function(number): void} */
	const maybeStopDiag = tokenEnd => {
		if (shouldStopDiag(tokenEnd)) {
			popContainer()
		}
	}


	/** @type {function(number): HTMLSpanElement} */
	const noTokenNode = startPos => {
		assert(startPos < pos)
		return createSpan({ className: "no-token", children: [text.slice(startPos, pos)] })
	}

	/** @type {function(number): void} */
	const walkTo = end => {
		let startPos = pos
		///** @type {TextContainer} */
		//containerStack.push({type: "text", text:""})
		while (pos < end) {
			if (maybeStartDiag(pos)) {
				if (startPos < pos) secondLast(containerStack).children.push(noTokenNode(startPos))
				startPos = pos
			}
			if (text[pos] === '\n') {
				if (startPos < pos) last(containerStack).children.push(noTokenNode(startPos))
				startPos = pos + 1
				nextLine()
			}
			pos++
			if (shouldStopDiag(pos)) {
				last(containerStack).children.push(noTokenNode(startPos))
				startPos = pos
				popContainer()
			}
		}
		if (startPos < pos) last(containerStack).children.push(noTokenNode(startPos))
	}

	/** @type {function(string, number): void} */
	const addSpan = (className, end) => {
		assert(pos < end)
		last(containerStack).children.push(createSpan({ className, children: [text.slice(pos, end)] }))
		pos = end
	}

	startLine()

	let diagIndex = 0
	for (const token of tokens) {
		const tokenPos = token.range.args[0]
		const tokenEnd = token.range.args[1]
		walkTo(tokenPos)
		maybeStartDiag(tokenPos)
		addSpan(classForKind(token.kind), tokenEnd)
		maybeStopDiag(tokenEnd)
	}

	walkTo(text.length)
	console.log("?1", containerStack)
	endLine()
	console.log("?2", containerStack)
	assert(containerStack.length === 1 && containerStack[0].type === "all")
	return containerStack[0].children
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
	to-int int(a |foo bar<?a>)

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
	const {tokens, diags} = noze.getTokens(v)
	console.log("DIAGS", diags)
	const nodes = tokensAndDiagsToNodes(tokens, diags, v)

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

/**
 * @typedef CreateNodeOptions
 * @property {{[name: string]: string}} [attr]
 * @property {string} [className]
 * @property {ReadonlyArray<Node | string>} [children]
 */

/**
 * @template {keyof HTMLElementTagNameMap} K
 * @param {K} tagName
 * @param {CreateNodeOptions} options
 * @return {HTMLElementTagNameMap[K]}
 */
const createNode = (tagName, options) => {
	const node = document.createElement(tagName)
	if (options.attr)
		for (const key in options.attr)
			node.setAttribute(key, options.attr[key])
	if (options.className)
		node.className = options.className
	if (options.children)
		node.append(...options.children)
	return node
}

/** @type {function(CreateNodeOptions): HTMLDivElement} */
const createDiv = options =>
	createNode("div", options)

/** @type {function(CreateNodeOptions): HTMLSpanElement} */
const createSpan = options =>
	createNode("span", options)

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
