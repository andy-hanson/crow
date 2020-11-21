import {Compiler, Diagnostic, Token} from "./Compiler.js"
import {assert} from "./util/assert.js"
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
			color: new Color("#00000010"),
			/* In contrast, cursor should remain 100% visible. */
			caret_color: Color.black,
			background: Color.transparent,
			line_height,
			font_size,
			border: Border.none,
			outline: Outline.none,
			resize: Resize.none,
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
		const ta = textarea()
		//TODO: options for 'textArea' function
		ta.value = props.text.get()
		ta.setAttribute("spellcheck", "false")
		ta.addEventListener("keydown", e => {
			const { keyCode } = e
			const { value, selectionStart, selectionEnd } = ta
			if (keyCode === "\t".charCodeAt(0)) {
				e.preventDefault()
				ta.value = value.slice(0, selectionStart) + "\t" + value.slice(selectionEnd)
				ta.setSelectionRange(selectionStart + 1, selectionStart + 1);
				highlight(props.compiler, highlightDiv, ta.value)
			}
		})
		ta.addEventListener("input", () => {
			props.text.set(ta.value)
			highlight(props.compiler, highlightDiv, ta.value)
		})
		highlight(props.compiler, highlightDiv, ta.value)

		root.append(div({class:codeClass}, [highlightDiv, ta]))
	},
})

/** @type {function(Compiler, Node, string): void} */
const highlight = (compiler, highlightDiv, v) => {
	const {tokens, diags} = compiler.getTokens(v)
	const nodes = tokensAndDiagsToNodes(tokens, diags, v)
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
		console.log("ADDSPAN", {pos, end})
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
