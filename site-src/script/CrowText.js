import { MutableObservable, Observable } from "./util/MutableObservable.js"
import { assert, createDiv, createNode, createSpan, nonNull, removeAllChildren, setStyleSheet } from "./util/util.js"

const lineHeightPx = 20
const tab_size = 4

/**
 * @typedef CrowTextProps
 * @property {function(number): string} getHover
 * @property {Observable<ReadonlyArray<Token>>} tokens
 * @property {MutableObservable<string>} text
 */

const css = `
.root {
	display: flex;
	background: #2c292d;
	font-family: "hack";
	font-size: 85%;
}
.line-numbers {
	display: inline-block;
	width: 1.5em;
	color: #6c696d;
	border-right: 0.1em solid #6c696d;
	line-height: 20px;
	text-align: right;
	white-space: pre;
	padding-right: 0.25em;
	margin-right: 0.25em;
}
.measurer {
	visibility: hidden;
	height: 0;
}
.code {
	width: 100%;
	height: 100%;
	margin: 0;
	padding: 0;
	position: relative;
	tab-size: 4;
	font-size: 1em;
	line-height: 20px;
	white-space: pre;
	display: inline-block;
}
.highlight {
	margin: 0;
	padding: 0;
	width: 100%;
	height: 100%;
	z-index: 10;
}
.line {
	height: 20px;
}
textarea {
	z-index: 0;
	margin: 0;
	padding: 0;
	position: absolute;
	top: 0;
	left: 0;
	width: 100%;
	height: 100%;
	color: #00000020;
	caret-color: #fdf9f3;
	background: #00000000;
	line-height: 20px;
	font-size: 1em;
	border: none;
	outline: none;
	resize: none;
	overflow: hidden;
	white-space: pre;
	font-family: "hack";
}
.no-token { font-weight: light; color: #aaa; }
.keyword { font-weight: bold; color: #ff6188; }
.identifier { color: #ffebbd; }
.import { color: #ff6188; }
.modifier { color: #ff6188; }
.fun { color: #78dce8; }
.struct { color: #ab9df2; }
.type-param { color: #fc9867; }
.spec { color: #a9dc76; }
.param { color: #ffebbd; }
.local { bold; color: #ffebbd; }
.lit-num { color: #ffd866; }
.lit-str { color: #ffd866; }
.member { color: #fc9867; }
.name { color: green; }
.diag {
	position: relative;
	border-bottom: 0.2em dotted #e87878;
}
.diag::after {
	content: attr(data-tooltip);
	position: absolute;
	white-space: nowrap;
	background: #80000080;
	padding: 0.5em;
	color: #fdf9f3;
	border-radius: 0.5em;
	margin-left: -1em;
	margin-top: 0.5ex;
	top: 3ex;
}
.hover-tooltip {
	background: #423e44;
	color: #fdf9f3;
	position: absolute;
	padding: 0.5em;
	border-radius: 0.5em;
	z-index: 100;
}
`

export class CrowText extends HTMLElement {
	/**
	 * @param {CrowTextProps} props
	 * @return {CrowText}
	 */
	static create(props) {
		const em = document.createElement("crow-text")
		em.props = props
		return em
	}

	constructor() {
		super()
		setStyleSheet(this.attachShadow({ mode: "open" }), css)
	}

	connectedCallback() {
		const {getHover, tokens, text} = this.props
		const highlightDiv = createDiv({className:"highlight"})
		const ta = createNode("textarea")
		const initialText = text.get()
		ta.value = initialText
		ta.setAttribute("spellcheck", "false")
		ta.addEventListener("keydown", e => {
			const insert = (() => {
				switch (e.key) {
					case "Enter":
						return "\n" + indentationAt(ta.value, ta.selectionStart)
					case "Tab":
						return "\t"
				}
			})()
			if (insert !== undefined) {
				e.preventDefault()
				text.set(insertTextAreaText(ta, insert))
			}
		})
		ta.addEventListener("input", () => {
			text.set(ta.value)
		})

		let mouseMoveIndex = 0

		/** @type {HTMLDivElement | null} */
		let tooltip = null
		let mouseIsIn = false
		const removeTooltip = () => {
			if (tooltip !== null) {
				tooltip.remove()
				tooltip = null
			}
		}
		ta.addEventListener("mouseout", () => {
			mouseIsIn = false
			removeTooltip()
		})
		ta.addEventListener("mousemove", e => {
			mouseIsIn = true
			removeTooltip()
			const offsetX = e.offsetX
			const offsetY = e.offsetY
			const lines = ta.value.split("\n")
			const columnWidth = measurerSpan.offsetWidth
			const line = Math.floor(offsetY / lineHeightPx)
			const columnPre = Math.floor(offsetX / columnWidth)
			const lineText = lines[line] || ''
			const leadingTabs = countLeadingTabs(lineText)
			const tabsFix = leadingTabs * (tab_size - 1)
			const column = clamp(columnPre - tabsFix, 0, lineText.length - 1)
			const pos = sum(lines.slice(0, line), line => line.length + "\n".length) + column
			mouseMoveIndex++

			if (mouseMoveIndex === 2**16) mouseMoveIndex = 0
			const saveMouseMoveIndex = mouseMoveIndex
			setTimeout(() => {
				if (mouseIsIn && mouseMoveIndex === saveMouseMoveIndex) {
					const hover = getHover(pos)
					if (hover !== "") {
						tooltip = createDiv({className:"hover-tooltip", children:[hover]})
						textContainer.append(tooltip)
						tooltip.style.left = offsetX + "px"
						tooltip.style.top = offsetY + "px"
					} else {
						console.log("NO HOVER")
					}
				}
			}, 200)
		})

		const lineNumbers = createDiv({className:"line-numbers"})

		tokens.nowAndSubscribe(value => {
			highlight(value, highlightDiv, ta.value)
			lineNumbers.textContent = ta.value.split("\n").map((_, i) => String(i + 1)).join("\n")
		})

		const measurerSpan = createSpan({children:["a"]})
		const measurer = createDiv({className:"measurer", children:[measurerSpan]})
		const textContainer = createDiv({className:"code", children:[measurer, highlightDiv, ta]})
		this.shadowRoot.append(createDiv({className:"root", children:[lineNumbers, textContainer]}))
	}
}
customElements.define("crow-text", CrowText)

/** @type {function(HTMLTextAreaElement, string): string} */
const insertTextAreaText = (textArea, inserted) => {
	const { value, selectionStart, selectionEnd } = textArea
	textArea.value = value.slice(0, selectionStart) + inserted + value.slice(selectionEnd)
	const newCursor = selectionStart + inserted.length
	textArea.setSelectionRange(newCursor, newCursor)
	return textArea.value
}

/** @type {function(string, number): string} */
const indentationAt = (str, pos) => {
	// Find beginning of line and end of whitespace
	let firstNonSpace = pos
	do {
		if (str[pos] != " " && str[pos] != "\t")
			firstNonSpace = pos
		pos--
	} while (pos >= 0 && str[pos] != "\n")
	return str.slice(pos + 1, firstNonSpace)
}

/**
 * @template T
 * @param {ReadonlyArray<T>} xs
 * @param {function(T): number} cb
 * @return {number}
 */
const sum = (xs, cb) => {
	let res = 0
	for (const x of xs)
		res += cb(x)
	return res
}

/** @type {function(string): number} */
const countLeadingTabs = s => {
	let res = 0
	for (const c of s)
		if (c === "\t")
			res++
		else
			break
	return res
}


/** @type {function(ReadonlyArray<Token>, Node, string): void} */
const highlight = (tokens, highlightDiv, v) => {
	/** @type {ReadonlyArray<Diagnostic>} */
	const diags = [] //TODO: compiler.getParseDiagnostics(v)
	// Only use at most 1 diag
	const nodes = tokensAndDiagsToNodes(tokens, diags.slice(0, 1), v)
	removeAllChildren(highlightDiv)
	for (const node of nodes)
		highlightDiv.appendChild(node)
}

/** @type {function(string, ReadonlyArray<Node | string>): HTMLSpanElement} */
const createDiagSpan = (message, children) =>
	createSpan({
		attr: {"data-tooltip": message},
		className: "diag",
		children,
	})

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
 * @typedef TextContainer
 * @property {"text"} type
 * @property {string} text
 * @property {Array<Node>} children
 */

/**
 * @typedef {AllContainer | LineContainer | DiagContainer} Container
 */

 /**
 * @typedef {Container | TextContainer} SomeContainer
 */

/** @type {function(ReadonlyArray<compiler.Token>, ReadonlyArray<compiler.Diagnostic>, string): ReadonlyArray<Node>} */
const tokensAndDiagsToNodes = (tokens, diags, text) => {
	let pos = 0
	// Last entry is the most nested container
	/** @type {Array<SomeContainer>} */
	const containerStack = [
		{type:"all", children:[]},
	]

	const popContainer = () => {
		const popped = mustPop(containerStack)
		const child = popped.type === "diag"
				? createDiagSpan(popped.message, popped.children)
			: popped.type === "line"
				? createDiv({ className: "line", children: popped.children })
			: unreachable(`Unexpected type ${popped.type}`)
		const lastContainer = last(containerStack)
		if (/** @type {SomeContainer} */ (lastContainer).type === "text")
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
		assert(pos <= end)
		// Ignore empty spans, they can happen when there are parse errors
		if (pos != end) {
			last(containerStack).children.push(createSpan({ className, children: [text.slice(pos, end)] }))
			pos = end
		}
	}

	startLine()

	let diagIndex = 0
	for (const {token, range:{start:tokenPos, end:tokenEnd}} of tokens) {
		walkTo(tokenPos)
		maybeStartDiag(tokenPos)
		addSpan(token, tokenEnd)
		maybeStopDiag(tokenEnd)
	}

	walkTo(text.length)
	endLine()
	assert(containerStack.length === 1 && containerStack[0].type === "all")
	return containerStack[0].children
}

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

/** @type {function(number, number, number): number} */
const clamp = (x, min, max) =>
	x < min ? min :
	x > max ? max :
	x
