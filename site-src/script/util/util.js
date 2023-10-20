/**
 * @param {boolean} b
 * @param {() => string} msg?
 * @return {asserts b}
*/
export function assert(b, msg = () => "Assertion failed") {
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

/** @type {function(CreateNodeOptions): HTMLButtonElement} */
export const createButton = options =>
	createNode("button", options)

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
