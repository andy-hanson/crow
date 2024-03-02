import { CrowServer, getCrowServer } from "./crow.js"
import { assert, createInputText, createNode, getChildText, nonNull, setStyleSheet } from "./util/util.js"

const css = `
table {
	table-layout: fixed;
	width: 100%;
	border-collapse: collapse;
}
table th {
	padding: 0;
	width: 33%;
}
table td {
	padding: 0;
	width: 33%;
	border: 1px solid #888;
}
table td:focus-within {
	background: #f8ffe0;
}
input {
	padding-left: 0.5em;
	padding-right: 0;
	width: calc(100% - 0.5em);
	font-family: "hack";
	font-size: 105%;
	border: none;
}
input:focus-visible {
	outline: none;
	background: #f8ffe0;
}
`

class SyntaxTranslate extends HTMLElement {
	constructor() {
		super()
		setStyleSheet(this.attachShadow({ mode: "open" }), css)
	}

	connectedCallback() {
		getCrowServer().then(crow => {
			connected(nonNull(this.shadowRoot), crow, this.childNodes)
		})
	}
}

/** @type {function(ShadowRoot, CrowServer, NodeListOf<ChildNode>): void} */
const connected = (shadowRoot, crow, childNodes) => {
	shadowRoot.append(createNode("table", {
		children: [
			createNode("thead", {children:[
				createNode("tr", {children:[
					createNode("th", {children:["Crow syntax"]}),
					createNode("th", {children:["Java-like syntax"]}),
					createNode("th", {children:["C-like syntax"]}),
				]}),
			]}),
			createNode("tbody", {
				children: Array.from(childNodes)
					.filter(node => node instanceof SyntaxTranslateRow)
					.map(node => createRow(crow, getChildText(node.childNodes))),
			}),
		],
	}))
}

const langs = ["crow", "java", "c"]

/** @type {function(CrowServer, string): Node} */
const createRow = (crow, initialCSource) => {
	/** @type {function(HTMLInputElement): string} */
	const langFor = x => langs[allInputs.indexOf(x)]

	/** @type {function({target:EventTarget | null}): void} */
	const oninput = ({target}) => {
		assert(target instanceof HTMLInputElement)
		for (const x of allInputs) {
			if (x !== target)
				writeTranslation(crow, target.value, langFor(target), x, langFor(x))
		}
	}

	const allInputs = langs.map(x => createInputText({oninput, value:x === "c" ? initialCSource : ""}))
	oninput({target:allInputs[langs.indexOf("c")]})
	return createNode("tr", {children: allInputs.map(x => createNode("td", {children:[x]}))})
}

/** @type {function(CrowServer, string, string, HTMLInputElement, string): void} */
const writeTranslation = (crow, source, fromLang, to, toLang) => {
	const response = crow.request("custom/syntaxTranslate", {source, from:fromLang, to:toLang})
	to.value = response.diagnostics.length === 0
		? response.output
		: `Parse error at ${response.diagnostics[0]}`
}

customElements.define("syntax-translate", SyntaxTranslate)

// This is only for use inside "syntax-translate"
class SyntaxTranslateRow extends HTMLElement {
	connectedCallback() {}
}
customElements.define("syntax-translate-row", SyntaxTranslateRow)
