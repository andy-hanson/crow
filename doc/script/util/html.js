import {assert, nonNull} from "./assert.js"
import {CSSClass} from "./css.js"
import {safeCast} from "./util.js"
import {toFloat, uint} from "./types.js"

/**
 * @typedef ElementOptions
 * @property {Record<string, string | number | boolean | null | undefined> | undefined} [attributes]
 * @property {CSSClass| ReadonlyArray<CSSClass> | undefined} [class]
 * @property {string | undefined} [id]
 */

/** @typedef {HTMLElement | string} NodeOrString */

/**
 * @param {string} name
 * @param {ElementOptions} [options]
 * @param {ReadonlyArray<NodeOrString>} [children]
 * @return {HTMLElement}
 */
export function element(name, options, children) {
	const res = document.createElement(name)
	if (options && options.class) {
		res.classList.add(...(options.class instanceof CSSClass ? [options.class] : options.class).map(c => c.name))
	}
	if (options && options.attributes)
		for (const key of Object.getOwnPropertyNames(options.attributes)) {
			const value = options.attributes[key]
			if (value !== null)
				res.setAttribute(key, String(value))
		}
	if (options && options.id)
		res.setAttribute("id", options.id)
	if (children) res.append(...children)
	return res
}

/** @typedef {"email" | "password" | "text" | "url"} InputType */
export const InputType = {}

/**
 * @param {NodeOrString} child
 * @return {HTMLButtonElement}
 */
export function button(child) {
	return safeCast(element("button", {
		attributes: { type: "button" },
	}, [child]), HTMLButtonElement)
}

/**
 * @param {NodeOrString} summary
 * @param {ReadonlyArray<NodeOrString>} children
 * @returns {HTMLElement}
 */
export const details = (summary, children) =>
	element("details", {}, [
		element("summary", {}, [summary]),
		...children,
	])

/**
 * @param {ElementOptions} [options]
 * @param {ReadonlyArray<NodeOrString>} [children]
 * @returns {HTMLDivElement}
 */
export const div = (options, children) =>
	safeCast(element("div", options, children), HTMLDivElement)

/** @type {function(string): HTMLImageElement} */
export const img = url =>
	safeCast(element("img", {
		attributes: {
			src: url,
		}
	}), HTMLImageElement)

/**
 * @typedef InputOptions
 * @property {InputType} type
 * @property {string} placeholder
 * @property {string | undefined} [initial]
 * @property {uint | undefined} [minLength]
 * @property {uint | undefined} [maxLength]
 * @property {RegExp | undefined} [pattern]
 * @property {boolean | undefined} [required]
 * @property {ElementOptions | undefined} [options]
 */

/**
 * @param {InputOptions} options
 * @return {HTMLInputElement}
 */
export function input(
	{ type, placeholder, initial, minLength, maxLength, pattern, required, options }) {
	const res = safeCast(element("input", {
		...options,
		attributes: {
			type,
			placeholder,
			minlength: minLength == null ? null : toFloat(minLength),
			maxlength: maxLength == null ? null : toFloat(maxLength),
			required,
			...(pattern ? {pattern: pattern.source} : {}),
			...(options && options.attributes),
		},
	}), HTMLInputElement)
	if (initial)
		res.value = initial
	return res
}

/** @type {function(string): HTMLElement} */
export const ionIcon = name => {
	assert(!!customElements.get("ion-icon"))
	const res = element("ion-icon", {attributes: {name}})
	// Hack to make sure it doesn't show a tooltip
	new MutationObserver(() => {
		while (true) {
			const node = nonNull(res.shadowRoot).querySelector("title")
			if (node === null) break
			node.remove()
		}
	}).observe(nonNull(res.shadowRoot), { childList: true, subtree: true })
	return res
}

/** @type {function(ReadonlyArray<NodeOrString>): HTMLTableElement} */
export function table(children) {
	return safeCast(element("table", {}, children), HTMLTableElement)
}

/** @type {function(ReadonlyArray<NodeOrString>): HTMLElement} */
export function thead(children) {
	return element("thead", {}, children)
}

/** @type {function(ReadonlyArray<NodeOrString>): HTMLElement} */
export function tbody(children) {
	return element("tbody", {}, children)
}

/** @type {function(ReadonlyArray<NodeOrString>): HTMLElement} */
export function tr(children) {
	return element("tr", {}, children)
}
/** @type {function(ElementOptions, ReadonlyArray<NodeOrString>): HTMLElement} */
export function th(options, children) {
	return element("th", options, children)
}

/** @type {function(ElementOptions, ReadonlyArray<NodeOrString>): HTMLElement} */
export function td(options, children) {
	return element("td", options, children)
}

/** @return {HTMLTextAreaElement} */
export function textarea() {
	return safeCast(element("textarea"), HTMLTextAreaElement)
}

/**
 * @param {ReadonlyArray<NodeOrString>} children
 * @return {HTMLElement}
 */
export function footer(children) {
	return element("footer", {}, children)
}

/**
 * @param {ReadonlyArray<NodeOrString>} children
 * @return {HTMLElement}
 */
export function header(children) {
	return element("header", {}, children)
}

/**
 * @param {ReadonlyArray<NodeOrString>} children
 * @return {HTMLElement}
 */
export function main(children) {
	return element("main", {}, children)
}

/**
 * @param {ReadonlyArray<NodeOrString>} children
 * @return {HTMLElement}
 */
export function section(children) {
	return element("section", {}, children)
}

/**
 * @param {ElementOptions} options
 * @param {ReadonlyArray<NodeOrString>} children
 * @return {HTMLElement}
 */
export function span(options, children) {
	return element("span", options, children)
}


/**
 * @typedef HrefOptions
 * @property {string} href
 * @property {string} title
 * @property {HTMLElement} child
 */

/** @type {function(HrefOptions): HTMLElement} */
export const link = ({ href, title, child }) =>
	element("a", { attributes: { href, title } }, [child])
