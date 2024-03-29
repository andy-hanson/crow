import { Diagnostic, LineAndCharacter } from "./crow.js"
import { MutableObservable, Observable } from "./util/MutableObservable.js"
import {
	assert, createDiv, createNode, createSpan, makeDebouncer, nonNull, removeAllChildren, setStyleSheet,
} from "./util/util.js"

const lineHeightPx = 20
const tab_size = 4

/**
@typedef Token
@property {number} line
@property {number} character
@property {number} length
@property {string} type
@property {ReadonlyArray<string>} modifiers
*/
export const Token = null

/** @typedef {{tokens:ReadonlyArray<Token>, diagnostics:ReadonlyArray<Diagnostic>}} TokensAndDiagnostics */
export const TokensAndDiagnostics = null

/**
 * @typedef CrowTextProps
 * @property {function(LineAndCharacter): string} getHover
 * @property {Observable<TokensAndDiagnostics>} tokensAndDiagnostics
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

.declaration { font-weight: bold; }
.function { color: #78dce8; }
.interface { color: #a9dc76; }
.keyword { font-weight: bold; color: #ff6188; }
.modifier { color: #ff6188; }
.name { color: green; }
.namespace { color: #ff6188; }
.number { color: #ffd866; }
.parameter { color: #ffebbd; }
.property, .enumMember { color: #fefefe; }
.string { color: #ffd866; }
.type { color: #ab9df2; }
.typeParameter { color: #fc9867; }
.variable { color: #ffebbd; }
.comment { color: #ddeedd; }

.diagnostic {
	position: relative;
	border-bottom: 0.2em dotted #e87878;
}
.diagnostic::after {
	content: attr(data-tooltip);
	position: absolute;
	white-space: nowrap;
	background: #80000080;
	padding: 0.25em;
	color: #fdf9f3;
	border-radius: 0.5em;
	margin-left: -1em;
	margin-top: 0.25ex;
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
	props = /** @type {CrowTextProps} */ (/** @type {any} */ (null))

	/**
	 * @param {CrowTextProps} props
	 * @return {HTMLElement}
	 */
	static create(props) {
		const em = /** @type {HTMLElement & CrowText} */ (document.createElement("crow-text"))
		em.props = props
		return em
	}

	constructor() {
		super()
		setStyleSheet(this.attachShadow({ mode: "open" }), css)
	}

	connectedCallback() {
		const {getHover, tokensAndDiagnostics, text} = this.props
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
					default:
							return null
				}
			})()
			if (insert !== null) {
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
			const character = lineText == "" ? 0 : clamp(columnPre - tabsFix, 0, lineText.length - 1)
			mouseMoveIndex++

			if (mouseMoveIndex === 2**16) mouseMoveIndex = 0
			const saveMouseMoveIndex = mouseMoveIndex
			setTimeout(() => {
				if (mouseIsIn && mouseMoveIndex === saveMouseMoveIndex) {
					const hover = getHover({line, character})
					if (hover !== "") {
						tooltip = createDiv({className:"hover-tooltip", children:[hover]})
						textContainer.append(tooltip)
						tooltip.style.left = offsetX + "px"
						tooltip.style.top = offsetY + "px"
					}
				}
			}, 200)
		})

		const lineNumbers = createDiv({className:"line-numbers"})

		const diagDebounce = makeDebouncer(1000)

		tokensAndDiagnostics.nowAndSubscribe(({tokens, diagnostics}) => {
			highlight({tokens, diagnostics:[]}, highlightDiv, ta.value)
			lineNumbers.textContent = ta.value.split("\n").map((_, i) => String(i + 1)).join("\n")
			diagDebounce(() => {
				highlight({tokens, diagnostics}, highlightDiv, ta.value)
			})
		})

		const measurerSpan = createSpan({children:["a"]})
		const measurer = createDiv({className:"measurer", children:[measurerSpan]})
		const textContainer = createDiv({className:"code", children:[measurer, highlightDiv, ta]})
		nonNull(this.shadowRoot).append(createDiv({className:"root", children:[lineNumbers, textContainer]}))
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


/** @type {function(TokensAndDiagnostics, Node, string): void} */
const highlight = (td, highlightDiv, text) => {
	const nodes = tokensAndDiagsToNodes(td, text)
	removeAllChildren(highlightDiv)
	for (const node of nodes)
		highlightDiv.appendChild(node)
}

/** @type {function(string, ReadonlyArray<Node | string>): HTMLSpanElement} */
const createDiagSpan = (message, children) =>
	createSpan({
		attr: {"data-tooltip": message},
		className: "diagnostic",
		children,
	})

/** @typedef {{type:"all", children:Node[]}} AllContainer */

/** @typedef {{type:"line", children:Node[]}} LineContainer */

/**
 * @typedef DiagContainer
 * @property {"diag"} type
 * @property {Array<Node>} children
 * @property {LineAndCharacter} end
 * @property {string} message
 */

/** @typedef {{type:"text", text:string, children:Node[]}} TextContainer */

/** @typedef {AllContainer | LineContainer | DiagContainer} Container */

/** @typedef {Container | TextContainer} SomeContainer */

/** @type {function(TokensAndDiagnostics, string): ReadonlyArray<Node>} */
const tokensAndDiagsToNodes = ({tokens, diagnostics}, text) => {
	const lines = text.split('\n')
	/** @type {LineAndCharacter} */
	let pos = {line:0, character:0}
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

	/** @type {function(): boolean} */
	const maybeStartDiag = () => {
		if (diagIndex < diagnostics.length) {
			const {message, range:{start, end}} = nonNull(diagnostics[diagIndex])
			if (less(start, pos)) {
				// Ignore nested diags
				if (last(containerStack).type !== "diag") {
					finishText()
					containerStack.push({type:"diag", children:[], end:end, message})
				}
				diagIndex++
				return true
			}
		}
		return false
	}

	/** @type {function(): boolean} */
	const shouldStopDiag = () => {
		const lastContainer = last(containerStack)
		return lastContainer.type === "diag" && lessOrEqual(lastContainer.end, pos)
	}

	/** @type {function(): void} */
	const maybeStopDiag = () => {
		if (shouldStopDiag()) {
			popContainer()
		}
	}


	/** @type {function(LineAndCharacter): HTMLSpanElement} */
	const noTokenNode = startPos => {
		assert(less(startPos, pos))
		return createSpan({ className: "no-token", children: [sliceLine(lines, startPos, pos)] })
	}

	/** @type {function(LineAndCharacter): void} */
	const walkTo = end => {
		let startPos = pos
		while (less(pos, end)) {
			if (maybeStartDiag()) {
				if (less(startPos, pos)) secondLast(containerStack).children.push(noTokenNode(startPos))
				startPos = pos
			}
			const nextPos = nextPosition(lines, pos)
			if (nextPos.line !== pos.line) {
				if (!equal(startPos, pos)) last(containerStack).children.push(noTokenNode(startPos))
				startPos = nextPos
				nextLine()
			}
			pos = nextPos
			if (shouldStopDiag()) {
				last(containerStack).children.push(noTokenNode(startPos))
				startPos = pos
				popContainer()
			}
		}
		if (less(startPos, pos))
			last(containerStack).children.push(noTokenNode(startPos))
	}

	/** @type {function(string, LineAndCharacter): void} */
	const addSpan = (className, end) => {
		assert(lessOrEqual(pos, end))
		// Ignore empty spans, they can happen when there are parse errors
		if (!equal(pos, end)) {
			const parts = sliceLines(lines, pos, end)
			last(containerStack).children.push(createSpan({ className, children: [nonNull(parts[0])] }))
			for (const part of parts.slice(1)) {
				nextLine()
				last(containerStack).children.push(createSpan({ className, children:[part] }))
			}
			pos = end
		}
	}

	startLine()

	let diagIndex = 0
	for (const {type, modifiers, line, character, length} of tokens) {
		walkTo({line, character})
		maybeStartDiag()
		addSpan([type, ...modifiers].join(' '), {line, character:character + length})
		maybeStopDiag()
	}

	walkTo(lastPosition(lines))
	endLine()
	assert(containerStack.length === 1 && nonNull(containerStack[0]).type === "all")
	return nonNull(containerStack[0]).children
}

/** @type {function(ReadonlyArray<string>, LineAndCharacter, LineAndCharacter): ReadonlyArray<string>} */
const sliceLines = (lines, start, end) =>
	start.line === end.line
		? [sliceLine(lines, start, end)]
		: [
			sliceLine(lines, start, null),
			...lines.slice(start.line, end.line),
			sliceLine(lines, null, end),
		]

/** @type {function(ReadonlyArray<string>, LineAndCharacter | null, LineAndCharacter | null): string} */
const sliceLine = (lines, start, end) => {
	assert(start === null || end === null || start.line === end.line)
	if (start !== null) {
		if (end !== null) {
			assert(start.line === end.line)
			return nonNull(lines[start.line]).slice(start.character, end.character)
		} else
			return nonNull(lines[start.line]).slice(start.character)
	} else {
		assert(end !== null)
		return nonNull(lines[end.line]).slice(0, end.character)
	}
}

/** @type {function(LineAndCharacter, LineAndCharacter): boolean} */
const less = (a, b) =>
	a.line < b.line ? true :
	b.line < a.line ? false :
	a.character < b.character;

/** @type {function(LineAndCharacter, LineAndCharacter): boolean} */
const equal = (a, b) =>
	a.line === b.line && a.character === b.character

/** @type {function(LineAndCharacter, LineAndCharacter): boolean} */
const lessOrEqual = (a, b) =>
	less(a, b) || equal(a, b)

/** @type {function(ReadonlyArray<string>, LineAndCharacter): LineAndCharacter} */
const nextPosition = (lines, pos) =>
	pos.character >= nonNull(lines[pos.line]).length
		? {line:pos.line + 1, character:0}
		: {line:pos.line, character:pos.character + 1}

/** @type {function(ReadonlyArray<string>): LineAndCharacter} */
const lastPosition = lines =>
	({line:lines.length - 1, character:last(lines).length})

/**
 * @template T
 * @param {ReadonlyArray<T>} xs
 * @return {T}
*/
const last = xs => {
	if (xs.length === 0) throw new Error()
	return nonNull(xs[xs.length - 1])
}

/**
 * @template T
 * @param {ReadonlyArray<T>} xs
 * @return {T}
 */
const secondLast = xs => {
	if (xs.length < 2) throw new Error()
	return nonNull(xs[xs.length - 2])
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
