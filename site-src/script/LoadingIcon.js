import { createDiv, nonNull, setStyleSheet } from "./util/util.js"

const css = `
.root {
	display: inline-block;
	position: relative;
	height: 2em;
}
.child-0, .child-1, .child-2, .child-3 {
	position: absolute;
	top: 0.75em;
	width: 0.666em;
	height: 0.666em;
	border-radius: 50%;
	background: #ab9df2;
	animation-timing-function: cubic-bezier(0, 1, 1, 0);
}
.child-0 { left: 1em; animation: ani0 0.8s infinite; }
.child-1 { left: 1em; animation: ani1 0.8s infinite; }
.child-2 { left: 2em; animation: ani1 0.8s infinite; }
.child-3 { left: 3em; animation: ani2 0.8s infinite; }
@keyframes ani0 {
	0% { transform: scale(0); }
	100% { transform: scale(1); }
}
@keyframes ani1 {
	0% { transform: translate(0, 0); }
	100% { transform: translate(1em, 0); }
}
@keyframes ani2 {
	0% { transform: scale(1); }
	100% { transform: scale(0); }
}`

export class LoadingIcon extends HTMLElement {
	constructor() {
		super()
		setStyleSheet(this.attachShadow({ mode: "open" }), css)
	}

	connectedCallback() {
		nonNull(this.shadowRoot).append(createDiv({
			className:"root",
			children: ["child-0", "child-1", "child-2", "child-3"].map(className => createDiv({className})),
		}))
	}
}
customElements.define("crow-loading-spinner", LoadingIcon)
