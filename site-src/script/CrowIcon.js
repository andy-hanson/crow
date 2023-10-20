import { createDiv, nonNull } from "./util/util.js"

// Icons from https://heroicons.com/

export const copyIcon = () => {
	const data =
		"M8 5H6a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2v-1M8 5a2 2 0 002 2h2a2 2 " +
		"0 002-2M8 5a2 2 0 012-2h2a2 2 0 012 2m0 0h2a2 2 0 012 2v3m2 4H10m0 0l3-3m-3 3l3 3"
	return icon(`<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="${data}"/>`)
}

export const downloadIcon = () =>
	icon(`<path
		stroke-linecap="round"
		stroke-linejoin="round"
		stroke-width="2"
		d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"
	/>`)

export const playIcon = () =>
	icon(`
		<path
			stroke-linecap="round"
			stroke-linejoin="round"
			stroke-width="2"
			d="M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z" />
		<path
			stroke-linecap="round"
			stroke-linejoin="round"
			stroke-width="2"
			d="M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />`)

export const upIcon = () =>
	icon(`<path
		stroke-linecap="round"
		stroke-linejoin="round"
		stroke-width="2"
		d="M5 15l7-7 7 7"
	/>`)

export const externalLinkIcon = () => {
	const data = 'M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14'
	return icon(`<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="${data}"/>`)
}

/** @type {function(string): HTMLElement} */
const icon = content => {
	const res = createDiv({className:"icon"})
	res.innerHTML = `<svg
		xmlns="http://www.w3.org/2000/svg"
		fill="none"
		viewBox="0 0 22 22"
		stroke="currentColor">
		${content}
	</svg>`
	return res
}

customElements.define("crow-icon", class CrowIcon extends HTMLElement {
	constructor() {
		super()
		this.attachShadow({ mode: "open" })
	}

	connectedCallback() {
		const fn = nonNull({
			copy: copyIcon,
			download: downloadIcon,
			play: playIcon,
			"external-link": externalLinkIcon,
		}[nonNull(this.getAttribute("icon"))])
		nonNull(this.shadowRoot).appendChild(fn())
	}
})
