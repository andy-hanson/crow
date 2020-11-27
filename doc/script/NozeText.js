import {Compiler, Diagnostic, Token} from "./Compiler.js"
import {assert, assertNever} from "./util/assert.js"
import {
	Align,
	Border,
	Color,
	Content,
	cssClass,
	Cursor,
	Display,
	Float,
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
import {removeAllChildren} from "./util/dom.js"
import {div, textarea} from "./util/html.js"
import {MutableObservable} from "./util/MutableObservable.js"

const codeClass = cssClass("code")
const highlightClass = cssClass("highlight")
const lineClass = cssClass("line")
const noTokenClass = cssClass("no-token")
const diagClass = cssClass("diag")

const line_height = Measure.px(20)
const font_size = Measure.em(1)

const lineNumbersClass = cssClass("line-numbers")
const rootClass = cssClass("root")

/** @type {CustomElementClass<{ compiler: Compiler, text: MutableObservable<string> }, null, null>} */
export const NozeText = makeCustomElement({
	tagName: "noze-text",
	styleSheet: new StyleBuilder()
		.class(rootClass, {
			display: Display.flex,
			background: Color.darkGray,
			font_family: FontFamily.monospace,
		})
		.class(lineNumbersClass, {
			display: Display.inlineBlock,
			width: Measure.em(1.5),
			color: Color.lightGray,
			border_right: Border.solid(Measure.em(0.1), Color.lightGray),
			line_height,
			text_align: Align.right,
			white_space: WhiteSpace.pre,
			padding_right: Measure.em(0.25),
			margin_right: Measure.em(0.25),
		})
		.class(codeClass, {
			width: Measure.pct100,
			height: Measure.pct100,
			margin: Measure.zero,
			padding: Measure.zero,
			position: Position.relative,
			tab_size: 4,
			font_size,
			line_height,
			white_space: WhiteSpace.pre,
			display: Display.inlineBlock,
		})
		.class(highlightClass, {
			margin: Measure.zero,
			padding: Measure.zero,
			width: Measure.pct100,
			height: Measure.pct100,
			z_index: 10,
		})
		.class(lineClass, {height: line_height})
		.textarea({
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
			caret_color: Color.white,
			background: Color.transparent,
			line_height,
			font_size,
			border: Border.none,
			outline: Outline.none,
			resize: Resize.none,
			overflow: Overflow.auto,
			white_space: WhiteSpace.pre,
		})
		.class(noTokenClass, {
			font_weight: FontWeight.light,
			color: Color.lightGray,
		})
		.class(cssClass("keyword"), {
			font_weight: FontWeight.bold,
			color: Color.pink,
		})
		.class(cssClass("identifier"), {color: Color.lightYellow})
		.class(cssClass("import"), {color: Color.pink})
		.class(cssClass("fun-def"), {font_weight: FontWeight.bold, color: Color.blue})
		.class(cssClass("fun-ref"), {color: Color.blue})
		.class(cssClass("struct-def"), {font_weight: FontWeight.bold, color: Color.lavender})
		.class(cssClass("struct-ref"), {color: Color.lavender})
		.class(cssClass("tparam-def"), {font_weight: FontWeight.bold, color: Color.peach})
		.class(cssClass("tparam-ref"), {color: Color.peach})
		.class(cssClass("spec-def"), {font_weight: FontWeight.bold, color: Color.green})
		.class(cssClass("spec-ref"), {color: Color.green})
		.class(cssClass("param-def"), {font_weight: FontWeight.bold, color: Color.lightYellow})
		.class(cssClass("lit-num"), {color: Color.yellow})
		.class(cssClass("lit-str"), {color: Color.yellow})
		.class(cssClass("field-def"), {font_weight: FontWeight.bold, color: Color.peach})
		.class(cssClass("field-ref"), {color: Color.peach})
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
	connected: async ({ props: {compiler, text}, root }) => {
		const highlightDiv = div({class:highlightClass}, [])
		const ta = textarea()
		const initialText = text.get()
		ta.value = initialText
		ta.setAttribute("spellcheck", "false")
		ta.addEventListener("keydown", e => {
			if (e.key === "Tab") {
				e.preventDefault()
				const { value, selectionStart, selectionEnd } = ta
				ta.value = value.slice(0, selectionStart) + "\t" + value.slice(selectionEnd)
				ta.setSelectionRange(selectionStart + 1, selectionStart + 1);
				update()
			}
		})
		ta.addEventListener("input", () => {
			text.set(ta.value)
			update()
		})

		const update = () => {
			highlight(compiler, highlightDiv, ta.value)
			lineNumbers.textContent = ta.value.split("\n").map((x, i) => String(i + 1)).join("\n")
		}

		const lineNumbers = div({class:lineNumbersClass})

		update()

		const textContainer = div({class:codeClass}, [highlightDiv, ta])
		root.append(div({class:rootClass}, [lineNumbers, textContainer]))
	},
})

/** @type {function(Compiler, Node, string): void} */
const highlight = (compiler, highlightDiv, v) => {
	const {tokens, diags} = compiler.getTokens(v)
	// Only use at most 1 diag
	const nodes = tokensAndDiagsToNodes(tokens, diags.slice(0, 1), v)
	removeAllChildren(highlightDiv)
	for (const node of nodes)
		highlightDiv.appendChild(node)
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