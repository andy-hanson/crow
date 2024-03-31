/**
 * @param {boolean} b
 * @param {() => string} msg?
 * @return {asserts b}
*/
export const assert = (b, msg = () => "Assertion failed") => {
	if (!b)
		throw new Error(msg())
}

/**
 * @template T
 * @param {T | null | undefined} x
 * @return {T}
 */
export const nonNull = x => {
	if (x == null)
		throw new Error("Null value")
	return x
}

/**
 * @template T
 * @param {T | null} x
 * @return {T[]}
 */
export const optionToList = x =>
	x === null ? [] : [x]

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
export const createNode = (tagName, options = {}) => {
	const node = document.createElement(tagName)
	if (options.attr)
		for (const key in options.attr)
			node.setAttribute(key, nonNull(options.attr[key]))
	if (options.className)
		node.className = options.className
	if (options.children)
		node.append(...options.children)
	return node
}

/** @type {function(string, CreateNodeOptions): HTMLButtonElement} */
export const createButton = (title, options) =>
	createNode("button", {attr:{title}, ...options})

/** @type {function({oninput:(event: Event) => void, value:string}): HTMLInputElement} */
export const createInputText = ({oninput, value}) => {
	const res = createNode("input", {attr:{type:"text", value:value}})
	res.addEventListener('input', oninput)
	return res
}

/**
 * @param {CreateNodeOptions=} options
 * @return {HTMLDivElement}
 */
export const createDiv = options =>
	createNode("div", options)

/** @type {function(CreateNodeOptions): HTMLSpanElement} */
export const createSpan = options =>
	createNode("span", options)

	/** @type {function(Node): void} */
export function removeAllChildren(em) {
	while (true) {
		const child = em.firstChild
		if (child === null)
			break
		em.removeChild(child)
	}
}

/** @type {function(ShadowRoot, string): void} */
export const setStyleSheet = (shadowRoot, css) => {
	const styleSheet = new CSSStyleSheet()
	styleSheet.replace(css)
		.then(() => { shadowRoot.adoptedStyleSheets = [styleSheet] })
		.catch(console.error)
}

/**
@param {number} msec
@return {function(() => void): void}
*/
export const makeDebouncer = msec => {
	/** @type {ReturnType<setTimeout> | null} */
	let cur = null
	return action => {
		if (cur)
			clearTimeout(cur)
		cur = setTimeout(action, msec)
	}
}

/** @type {function(NodeListOf<ChildNode>): string} */
export const getChildText = childNodes => {
	assert(childNodes.length === 1)
	return getTextFromNode(childNodes[0])
}

/** @type {function(Node): string} */
const getTextFromNode = node => {
	assert(node instanceof Text)
	return reduceIndent(node.data)
}

/**
@type {function(string): string}
Counts indentation for the first line, and reduces indentation of all lines so that the first will be at 0.
*/
const reduceIndent = a =>
	a.startsWith("\n")
		// Count indent for the first line
		? a.replaceAll(a.slice(0, a.search(/\S/)), "\n").trim()
		: a
