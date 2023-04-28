import { copyIcon, downloadIcon, playIcon, upIcon } from "./CrowIcon.js"
import { CrowText } from "./CrowText.js"
import { LoadingIcon } from "./LoadingIcon.js"
import { MutableObservable } from "./util/MutableObservable.js"
import { assert, createButton, createDiv, nonNull, removeAllChildren, setStyleSheet } from "./util/util.js"
import includeAll from '/include-all.json' assert { type: "json" }

const css = `
.outer-container {
	max-width: 40em;
	margin-left: auto;
	margin-right: auto;
}
.output {
	width: 100%;
	color: #fdf9f3;
	background: #161517;
	font-family: "hack";
	white-space: pre;
	tab-size: 4;
	overflow: hidden;
	transition: height 0.25s ease;
}
.output.running { transition: none; }
button {
	border: none;
	outline: none;
	color: #ffebbd;
	background: #00000000;
	cursor: pointer;
}
.run { color: #ffd866; }
.bottom {
	border-bottom-left-radius: 1.5em;
	border-bottom-right-radius: 1.5em;
	background: #423e44;
	margin: 0;
	padding-left: 0.5em;
	padding-right: 0.5em;
}
div.icon svg { height: 1.5em; }
button.collapsed { display: none; }
`

export class CrowRunnable extends HTMLElement {
	constructor() {
		super()
		setStyleSheet(this.attachShadow({ mode: "open" }), css)
	}

	connectedCallback() {
		crow.getGlobalCompiler()
			.then(comp =>
				connected(
					nonNull(this.shadowRoot),
					getCrowRunnableName(this.getAttribute("name")),
					this.getAttribute("no-run") !== null,
					comp,
					getChildText(this.childNodes)))
			.catch(console.error)
	}
}
customElements.define("crow-runnable", CrowRunnable)

/** @type {Set<string>} */
const seenNames = new Set()
/** @type {function(string | null): string} */
const getCrowRunnableName = specified => {
	const name = specified === null ? getDefaultName() : specified
	assert(name.endsWith(".crow"))
	if (seenNames.has(name))
		console.error("Two CrowRunnable have the same name", {name})
	seenNames.add(name)
	return name
}

let nextNameIndex = 0
/** @type {function(): string} */
const getDefaultName = () => {
	const res = `demo${nextNameIndex}.crow`
	nextNameIndex++
	return res
}

/** @type {function(ReadonlyArray<ChildNode>): string} */
const getChildText = childNodes => {
	assert(childNodes.length === 1)
	const child = childNodes[0]
	assert(child instanceof Text)
	return reduceIndent(child.data)
}

/**
@type {function(string): string}
Counts indentation for the first line, and reduces indentation of all lines so that the first will be at 0.
*/
const reduceIndent = a => {
	// Count indent for the first line
	assert(a.startsWith("\n"))
	return a.replaceAll(a.slice(0, a.search(/\S/)), "\n").trim()
}

/** @type {function(ShadowRoot, string, boolean, crow.Compiler, string): void} */
const connected = (shadowRoot, name, noRun, comp, initialText) => {
	const MAIN = `/code/${name}`

	/** @type {MutableObservable<string>} */
	const text = new MutableObservable(initialText)
	/** @type {MutableObservable<ReadonlyArray<Token>>} */
	const tokens = new MutableObservable(/** @type {ReadonlyArray<Token>} */ ([]))
	/** @type {function(number): string} */
	const getHover = pos =>
		comp.getHover(MAIN, pos)
	const crowText = CrowText.create({getHover, tokens, text})

	for (const [path, content] of Object.entries(includeAll))
		comp.addOrChangeFile(`${crow.includeDir}/${path}`, content)

	text.nowAndSubscribe(value => {
		comp.addOrChangeFile(MAIN, value)
		tokens.set(comp.getTokens(MAIN))
	})

	const output = createDiv({className:"output"})
	output.style.height = "0"

	const runButton = noRun ? null : createButton({className:"run", children:[playIcon()]})
	if (runButton) runButton.onclick = () => {
		try {
			output.className = "output"
			output.classList.add("running")
			output.style.height = "2em"
			removeAllChildren(output)
			output.append(new LoadingIcon())
			output.append(createDiv(), createDiv(), createDiv(), createDiv())
			// Put behind a timeout so loading will show
			setTimeout(() => {
				collapseButton.classList.remove("collapsed")
				output.classList.remove("running")
				const result = comp.run(MAIN)
				const text = (result.stdout === "" && result.stderr === ""
				? "no output"
				: result.stdout === "" || result.stderr === ""
				? result.stdout + result.stderr
				: `stderr:\n${result.stderr}\nstdout:\n${result.stdout}`).trim()
				output.textContent = text
				const lines = text.split("\n").length
				output.style.height = `${lines * 1.19}em`
				output.classList.add(result.err === 0 ? "ok" : "err")
			}, 0)
		} catch (e) {
			console.error("ERROR WHILE RUNNING", e)
			throw e
		}
	}

	const copyButton = createButton({children:[copyIcon()]})
	copyButton.onclick = () => {
		navigator.clipboard.writeText(text.get()).catch(e => {
			console.error(e)
		})
	}

	const downloadButton = createButton({children:[downloadIcon()]})
	downloadButton.onclick = () => {
		const a = document.createElement("a")
		a.href = URL.createObjectURL(new Blob([text.get()], {type:"text/crow"}))
		a.target = "_blank"
		a.download = name
		a.click()
	}

	const collapseButton = createButton({children:[upIcon()]})
	collapseButton.classList.add("collapsed")
	collapseButton.style.float = "right"
	collapseButton.onclick = () => {
		output.style.height = "0"
		collapseButton.classList.add("collapsed")
	}

	const bottom = createDiv({
		className: "bottom",
		children: [...(runButton ? [runButton] : []), copyButton, downloadButton, collapseButton],
	})
	shadowRoot.append(createDiv({className:"outer-container", children:[crowText, output, bottom]}))
}
