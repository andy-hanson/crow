import { copyIcon, downloadIcon, playIcon, upIcon } from "./CrowIcon.js"
import { CrowText } from "./CrowText.js"
import { LoadingIcon } from "./LoadingIcon.js"
import { MutableObservable } from "./util/MutableObservable.js"
import { createButton, createDiv, nonNull, removeAllChildren, setStyleSheet } from "./util/util.js"
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
		const src = nonNull(this.getAttribute("src"))
		Promise.all([compiler.getGlobalCompiler(), fetch(`/example/${src}.crow`).then(x => x.text())])
			.then(([comp, initialText]) =>
				connected(this.shadowRoot, src, this.getAttribute("no-run") !== null, comp, initialText))
			.catch(console.error)
	}
}
customElements.define("crow-runnable", CrowRunnable)

const connected = (shadowRoot, src, noRun, comp, initialText) => {
	const MAIN = src

	/** @type {MutableObservable<string>} */
	const text = new MutableObservable(initialText)
	/** @type {MutableObservable<ReadonlyArray<Token>>} */
	const tokens = new MutableObservable(/** @type {ReadonlyArray<Token>} */ ([]))
	/** @type {function(number): string} */
	const getHover = pos =>
		comp.getHover(StorageKind.local, src, pos)
	const crowText = CrowText.create({getHover, tokens, text})

	for (const [name, content] of Object.entries(includeAll))
		comp.addOrChangeFile(StorageKind.global, name, content)

	text.nowAndSubscribe(value => {
		comp.addOrChangeFile(StorageKind.local, MAIN, value)
		tokens.set(comp.getTokens(StorageKind.local, MAIN))
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
		a.href = "data:text/csv;charset=utf-8," + encodeURI(text.get())
		a.target = "_blank"
		a.download = `${src}.crow`
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
