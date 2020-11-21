import { assert, nonNull } from "./assert.js"
import { objectToMap } from "./collection.js"
import { lateinit, launch, safeCast } from "./util.js"

/**
 * @template InProps, OutProps, State
 * @typedef CustomElementOptions
 * @property {string} tagName
 * @property {Promise<CSSStyleSheet>} styleSheet
 * @property {function(InProps): {state: State, out: OutProps}} init
 * @property {(function({ props: InProps, state: State, root: ShadowRoot }): Promise<void>)} [connected]
 * @property {(function({ props: InProps, state: State, root: ShadowRoot }): Promise<void>) | undefined} [disconnected]
 */

/**
 * @template InProps
 * @typedef Attribute
 * @property {function({
 *	props: InProps,
 *	oldValue: string | null,
 *	newValue: string | null,
 *	root: ShadowRoot
 * }): Promise<void>} changed
 */

/**
 * @template InProps, OutProps, State
 * @typedef CustomElementClass
 * @property {string} tagName
 * @property {(inProps: InProps, initAttributes?: Record<string, string>) => HTMLElement & { out: OutProps }} create
 */
export const CustomElementClass = {}

/**
 * @template InProps, OutProps, State
 * @param {CustomElementOptions<InProps, OutProps, State>} options
 * @return {CustomElementClass<InProps, OutProps, State>}
 */
export function makeCustomElement({ tagName, styleSheet, init, connected, disconnected }) {
	assert(tagName.startsWith("noze-"))
	const attributesMap = objectToMap({}) //TODO:REMOVE
	class C extends CustomElement {
		static tagName = tagName

		inProps = /** @type {InProps} */ (lateinit)
		out = /** @type {OutProps} */ (lateinit)
		state = /** @type {State} */ (lateinit)

		/**
		 * @param {InProps} inProps
		 * @param {Record<string, string>} [initAttributes]
		 * @return {HTMLElement & { out: OutProps }}
		 */
		static create(inProps, initAttributes) {
			const em = safeCast(document.createElement(tagName), C)
			for (const [key, value] of objectToMap(initAttributes || {})) {
				assert(attributesMap.has(key))
				em.setAttribute(key, value)
			}
			em.inProps = inProps
			const {out, state} = init(inProps)
			em.state = state
			em.out = out
			return em
		}

		constructor() {
			super()
		}

		/**
		 * @readonly
		 * @type {ReadonlyArray<string>}
		 */
		static observedAttributes = Array.from(attributesMap.keys())

		get styleSheet() { return styleSheet }

		connectedCallback() {
			if (connected != null) launch(() => connected({
				props: this.inProps,
				state: this.state,
				root: nonNull(this.shadowRoot)
			}))
		}

		disconnectedCallback() {
			if (disconnected != null)
				launch(() =>
					disconnected({props:this.inProps, state:this.state, root:nonNull(this.shadowRoot)}))
		}

		/**
		 * @param {string} name
		 * @param {string | null} oldValue
		 * @param {string | null} newValue
		 * @return {void}
		 */
		attributeChangedCallback(name, oldValue, newValue) {
			const attr = attributesMap.get(name)
			if (attr === undefined)
				throw new Error(`No such attribute ${name}`)
			launch(() => attr.changed({ props: this.inProps, oldValue, newValue, root: this.root }))
		}
	}
	customElements.define(tagName, C)
	return C
}

class CustomElement extends HTMLElement {
	/** @return {Promise<CSSStyleSheet>} */
	get styleSheet() {
		throw new Error("Should have style")
	}

	constructor() {
		super()
		const shadow = this.attachShadow({ mode: "open" })
		this.styleSheet.then(ss => {
			shadow.adoptedStyleSheets = [ss]
		})
	}

	/** @return {ShadowRoot} */
	get root() {
		return nonNull(this.shadowRoot)
	}
}
