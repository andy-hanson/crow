import {Compiler, Diagnostic, Token} from "./Compiler.js"
import {assert, assertNever} from "./util/assert.js"
import {
	Border,
	Color,
	Content,
	cssClass,
	Cursor,
	FontFamily,
	FontStyle,
	FontWeight,
	Measure,
	Outline,
	Overflow,
	Position,
	Resize,
	Selector,
	StyleBuilder,
	WhiteSpace,
} from "./util/css.js"
import {CustomElementClass, makeCustomElement} from "./util/CustomElement.js"
import {div, textarea} from "./util/html.js"
import {MutableObservable} from "./util/MutableObservable.js"

const codeClass = cssClass("code")
const highlightClass = cssClass("highlight")
const lineClass = cssClass("line")
const noTokenClass = cssClass("no-token")
const diagClass = cssClass("diag")
const myTextAreaClass = cssClass("my-text-area")

const line_height = Measure.px(20)
const font_size = Measure.em(1)

/** @type {CustomElementClass<{ compiler: Compiler, text: MutableObservable<string> }, null, null>} */
export const NozeText = makeCustomElement({
	tagName: "noze-text",
	styleSheet: new StyleBuilder()
		.class(codeClass, {
			width: Measure.pct100,
			height: Measure.pct100,
			margin: Measure.zero,
			padding: Measure.zero,
			position: Position.relative,
			tab_size: 4,
			font_family: FontFamily.monospace,
			font_size,
			line_height,
			white_space: WhiteSpace.pre,
		})
		.class(highlightClass, {
			margin: Measure.zero,
			padding: Measure.zero,
			width: Measure.pct100,
			height: Measure.pct100,
			z_index: 10,
		})
		.class(lineClass, {
			height: line_height,
		})
		//.textarea({
		.class(myTextAreaClass, {
			z_index: 0,
			margin: Measure.zero,
			padding: Measure.zero,
			position: Position.absolute,
			top: Measure.zero,
			left: Measure.zero,
			width: Measure.pct100,
			height: Measure.pct100,
			/* Visible enough that I can tell if the highlight is not lined up,
				but not visible enough to lessen the highlight. */
			color: new Color("#00000020"),
			/* In contrast, cursor should remain 100% visible. */
			caret_color: Color.black,
			background: Color.transparent,
			line_height,
			font_size,
			border: Border.none,
			outline: Outline.none,
			resize: Resize.none,
			overflow: Overflow.auto,
			white_space: WhiteSpace.pre,
		})
		.rule(Selector.focus(Selector.tag('textarea')), {
		})
		.pre({
			background: Color.lighterGray,
		})
		.class(noTokenClass, {
			font_weight: FontWeight.light,
			color: Color.lightGray,
		})
		.class(cssClass("keyword"), {
			font_weight: FontWeight.bold,
			color: new Color("indigo"),
		})
		.class(cssClass("import"), {
			color: Color.blue,
		})
		.class(cssClass("fun-def"), {color: new Color("crimson")})
		.class(cssClass("fun-ref"), {color: new Color("firebrick")})
		.class(cssClass("struct-def"), {color: new Color("dodgerblue")})
		.class(cssClass("struct-ref"), {
			font_style: FontStyle.italic,
			color: new Color("navy"),
		})
		.class(cssClass("tparam-def"), {
			font_style: FontStyle.italic,
			color: new Color("cyan"),
		})
		.class(cssClass("tparam-ref"), {
			font_style: FontStyle.italic,
			color: new Color("darkturquoise"),
		})
		.class(cssClass("spec-def"), {color: new Color("greenyellow")})
		.class(cssClass("spec-ref"), {color: new Color("green")})
		.class(cssClass("param-def"), {color: new Color("brown")})
		.class(cssClass("lit-num"), {color: new Color("darkorchid")})
		.class(cssClass("lit-str"), {color: new Color("darkorchid")})
		.class(cssClass("field-def"), {color: new Color("coral")})
		.class(cssClass("field-ref"), {color: new Color("indianred")})
		.class(cssClass("name"), {color: new Color("green")})
		.class(diagClass, {
			position: Position.relative,
			border_bottom: Border.dotted(Measure.em(0.2), Color.red),
		})
		.rule(Selector.after(Selector.class(diagClass)), {
			content: Content.attr("data-tooltip"),
			position: Position.absolute,
			white_space: WhiteSpace.noWrap,
			background: new Color("#80000080"),
			padding_x: Measure.em(0.5),
			padding_y: Measure.ex(0.5),
			color: Color.white,
			border_radius: Measure.em(0.5),
			margin_left: Measure.em(-1),
			margin_top: Measure.ex(0.5),
			top: Measure.ex(3),
		})
		.end(),
	init: () => ({state: null, out: null}),
	connected: async ({ props, state, root }) => {
		const highlightDiv = div({class:highlightClass}, [])
		const ta = div({class:myTextAreaClass})
		/*
		/** @return {Text} * /
		const getTextElement = () => {
			if (ta.childNodes.length !== 1)
				throw new Error("? " + ta.childNodes.length)
			const res = ta.childNodes[0]
			if (!(res instanceof Text)) throw new Error("baa")
			return res
		}
		*/
		const initialText = props.text.get()
		ta.textContent = initialText
		const textElement = ta.childNodes[0]
		if (ta.childNodes.length !== 1)
			throw new Error("???")
		if (!(textElement instanceof Text))
			throw new Error("BAI")

		ta.setAttribute("contenteditable", "true")
		ta.setAttribute("spellcheck", "false")
		ta.addEventListener("keydown", e => {
			e.preventDefault()
			console.log("EVENT", e)
			const { key, keyCode } = e
			if (typeof keyCode !== "number")
				throw new Error("?")

			const action = getAction(e)

			const sel = nonNull(root.getSelection())
			const selStart = sel.getRangeAt(0).startOffset
			const selEnd = sel.getRangeAt(0).endOffset

			if (action.type === "noop") {
			} else if (action.type === "copy") {
				navigator.clipboard.writeText(textElement.data.slice(selStart, selEnd))
			} else if (action.type === "selectAll") {
				const range = document.createRange()
				range.setStart(textElement, 0)
				range.setEnd(textElement, textElement.data.length)
				sel.removeAllRanges()
				sel.addRange(range)
			} else {
				const {newText, newPos} = modify(nonNull(textElement.data), selEnd, action)
				console.log("!!!", {newText, newPos})
				textElement.data = newText

				const range = document.createRange()
				console.log("ADD RANGE", {pos: selEnd})
				range.setStart(textElement, newPos)
				range.setEnd(textElement, newPos)
				sel.removeAllRanges()
				sel.addRange(range)
				console.log("HIGHLIGHT NEW", newText)
				highlight(props.compiler, highlightDiv, newText)
			}
		})
		ta.addEventListener("keyup", e => {
		})
		/*
		ta.addEventListener("input", () => {
			const text = realGetTextContent(ta)
			console.log("TEXT", text)
			// This collapses text nodes
			//ta.textContent = text
			props.text.set(text)
			highlight(props.compiler, highlightDiv, text)
		})
		*/
		highlight(props.compiler, highlightDiv, initialText)

		root.append(div({class:codeClass}, [highlightDiv, ta]))
	},
})

/**
 * @typedef ModAdd
 * @property {"add"} type
 * @property {string} text
 */

/**
 * @typedef {ModAdd | {type:"backspace" | "delete" | "left" | "right" | "down" | "up"}} Mod
 */

/** @typedef {Mod | {type:"copy" | "noop" | "selectAll"}} Action */

/** @type {function(KeyboardEvent): Action} */
const getAction = e => {
	if (e.ctrlKey) {
		switch (e.key) {
			case "a":
				return {type:"selectAll"}
			case "c":
				return {type:"copy"}
			//TODO: copy, paste, run
			default:
				return {type:"noop"}
		}
	}

	switch (e.key) {
		case "ArrowDown":
			return {type:"down"}
		case "ArrowUp":
			return {type:"up"}
		case "ArrowLeft":
			return {type:"left"}
		case "ArrowRight":
			return {type:"right"}
		case "Backspace":
			return {type:"backspace"}
		case "Delete":
			return {type:"delete"}
		case "Tab":
			return {type:"add", text:"\t"}
		case "Enter":
			return {type:"add", text:"\n"}
		case "CapsLock":
		case "Control":
		case "Shift":
			return {type:"noop"}
		default:
			return {type:"add", text:e.key}
	}
}

/** @type {function(string, number, Mod): {newText:string, newPos:number}} */
const modify = (text, pos, mod) => {
	switch (mod.type) {
		case "add":
			return {newText:text.slice(0, pos) + mod.text + text.slice(pos), newPos:pos + 1}
		case "backspace":
			return {newText:text.slice(0, pos - 1) + text.slice(pos), newPos:pos - 1}
		case "delete":
			return {newText:text.slice(0, pos) + text.slice(pos + 1), newPos:pos}
		case "left":
		case "up": //TODO
			return {newText:text, newPos:pos - 1}
		case "right":
		case "down": //TODO
			return {newText:text, newPos:pos + 1}
		default:
			return assertNever(mod)
	}
}


/** @type {function(Node): string} */
const realGetTextContent = node => {
	let res = ""
	console.log("CHILDREN", node.childNodes)
	for (const childNode of node.childNodes) {
		if (childNode instanceof HTMLElement && childNode.tagName === "BR")
			res += "\n"
		else if (childNode instanceof HTMLElement && childNode.tagName === "DIV")
			res += realGetTextContent(childNode)
		else if (childNode instanceof Text)
			res += childNode.data
		else {
			console.log("What is this child?", childNode, childNode instanceof HTMLElement, childNode.tagName)
			throw new Error("BAI")
		}
	}
	return res
}

/** @type {function(Compiler, Node, string): void} */
const highlight = (compiler, highlightDiv, v) => {
	const {tokens, diags} = compiler.getTokens(v)
	// Only use at most 1 diag
	const nodes = tokensAndDiagsToNodes(tokens, diags.slice(0, 1), v)
	removeAllChildren(highlightDiv)
	for (const node of nodes)
		highlightDiv.appendChild(node)
}

//TODO:MOVE
/** @type {function(Node): void} */
const removeAllChildren = em => {
	while (em.lastChild)
		em.removeChild(em.lastChild)
}
/** @type {function(string, ReadonlyArray<Node | string>): HTMLSpanElement} */
const createDiagSpan = (message, children) => {
	return createSpan({
		attr: {"data-tooltip": message},
		className: diagClass.name,
		children,
	})
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

/** @type {function(ReadonlyArray<Token>, ReadonlyArray<Diagnostic>, string): ReadonlyArray<Node>} */
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
				? createDiv({ className: lineClass.name, children: popped.children })
			: unreachable(`Unexpected type ${popped.type}`);
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
			newLast.children.push(createSpan({ className: noTokenClass.name, children: [l.text] }))
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
		return createSpan({ className: noTokenClass.name, children: [text.slice(startPos, pos)] })
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
	for (const token of tokens) {
		const tokenPos = token.range.args[0]
		const tokenEnd = token.range.args[1]
		walkTo(tokenPos)
		maybeStartDiag(tokenPos)
		addSpan(classForKind(token.kind), tokenEnd)
		maybeStopDiag(tokenEnd)
	}

	walkTo(text.length)
	endLine()
	assert(containerStack.length === 1 && containerStack[0].type === "all")
	return containerStack[0].children
}

/** @type {function(string): string} */
const classForKind = kind => {
	return kind
}

//TODO:KILL (use html.js)

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
