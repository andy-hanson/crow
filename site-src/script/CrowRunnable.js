import { CrowServer, getCrowServer, LineAndCharacter, SemanticTokensLegend, Write } from "./crow.js"
import { copyIcon, downloadIcon, playIcon, upIcon } from "./CrowIcon.js"
import { CrowText, Token, TokensAndDiagnostics } from "./CrowText.js"
import { LoadingIcon } from "./LoadingIcon.js"
import { MutableObservable } from "./util/MutableObservable.js"
import { assert, createButton, createDiv, createSpan, nonNull, removeAllChildren, setStyleSheet } from "./util/util.js"

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
	white-space: pre-wrap;
	tab-size: 4;
	overflow: hidden;
}
.output.running { transition: none; }
.output > .stderr { color: #ff6622; }
.output > .exit-code { color: #ff4444; }
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
		getCrowServer().then(crow => {
			connected(
				nonNull(this.shadowRoot),
				getCrowRunnableName(this.getAttribute("name")),
				this.getAttribute("no-run") !== null,
				crow,
				getChildText(this.childNodes))
		})
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

/** @type {function(NodeListOf<ChildNode>): string} */
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

/** @type {function(ShadowRoot, string, boolean, CrowServer, string): void} */
const connected = (shadowRoot, name, noRun, crow, initialText) => {
	const mainUri = `file:///${name}`
	/** @type {MutableObservable<string>} */
	const text = new MutableObservable(initialText)
	/** @type {TokensAndDiagnostics} */
	const empty = {tokens:[], diagnostics:[]}
	/** @type {MutableObservable<TokensAndDiagnostics>} */
	const tokensAndDiagnostics = new MutableObservable(empty)
	/** @type {function(LineAndCharacter): string} */
	const getHover = position => {
		const hover = crow.request("textDocument/hover", {textDocument:{uri:mainUri}, position})
		return hover ? hover.contents.value : ""
	}
	const crowText = CrowText.create({getHover, tokensAndDiagnostics, text})

	text.nowAndSubscribe(value => {
		const diagnostics = crow.openFile(mainUri, value)
		const encodedTokens = crow.request("textDocument/semanticTokens/full", {textDocument:{uri:mainUri}}).data
		tokensAndDiagnostics.set({
			tokens: decodeTokens(encodedTokens, crow.tokensLegend),
			// Errors only
			diagnostics: diagnostics.filter((/** @type {{severity:number}} */ x) => x.severity <= 1),
		})
	})

	const output = makeOutput()

	const runButton = noRun ? null : createButton({className:"run", children:[playIcon()]})
	if (runButton) runButton.onclick = () => {
		try {
			// Put behind a timeout so loading will show
			setTimeout(() => {
				collapseButton.classList.remove("collapsed")
				output.finishRunning(crow.request("custom/run", {uri:mainUri, diagnosticsOnlyForUris:[mainUri]}))
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
		output.hide()
		collapseButton.classList.add("collapsed")
	}

	const bottom = createDiv({
		className: "bottom",
		children: [...(runButton ? [runButton] : []), copyButton, downloadButton, collapseButton],
	})
	shadowRoot.append(createDiv({className:"outer-container", children:[crowText, output.container, bottom]}))
}

const makeOutput = () => {
	const container = createDiv({className:"output"})
	container.style.height = "0"

	return {
		container,
		hide: () => {
			container.style.height = "0"
		},
		startRunning: () => {
			container.className = "output"
			container.classList.add("running")
			container.style.height = "2em"
			removeAllChildren(container)
			container.append(new LoadingIcon())
			container.append(createDiv(), createDiv(), createDiv(), createDiv())
		},
		/** @type {function(RunResult): void} */
		finishRunning: ({writes, exitCode}) => {
			container.classList.remove("running")
			container.style.height = ''
			removeAllChildren(container)
			addSpansForWrites(container, writes, exitCode)
		},
	}
}

/** @typedef {{exitCode:number, writes:ReadonlyArray<Write>}} RunResult */

/** @type {function(ParentNode, ReadonlyArray<Write>, number): void} */
const addSpansForWrites = (container, writes, exitCode) => {
	/** @type {Write["pipe"] | "exit-code" | null} */
	let curPipe = null
	let curLine = ""

	const finishLine = () => {
		if (container.textContent)
			container.append(document.createElement("br"))
		container.append(createSpan({children:[curLine], className:nonNull(curPipe)}))
		curLine = ""
	}

	for (const {pipe, text} of writes) {
		if (curPipe !== null && pipe !== curPipe) {
			if (curLine) finishLine()
		}

		curPipe = pipe
		const parts = text.split("\n")
		curLine += parts[0]
		for (const part of parts.slice(1)) {
			finishLine()
			curLine += part
		}
	}
	if (curLine !== "")
		finishLine()

	if (exitCode !== 0) {
		curPipe = "exit-code"
		curLine = `Exit code: ${exitCode}`
		finishLine()
	} else if (writes.length === 0) {
		curPipe = "stdout"
		curLine = "<<no output>>"
		finishLine()
	}
}
/** @type {function(number[], SemanticTokensLegend): Token[]} */
const decodeTokens = (data, legend) => {
	const res = []
	let prevLine = 0
	let prevCharacter = 0
	let i = 0
	const next = () => nonNull(data[i++])
	while (i < data.length) {
		const lineDelta = next()
		const characterDelta = next()
		const [line, character] = lineDelta === 0
			? [prevLine, prevCharacter + characterDelta]
			: [prevLine + lineDelta, characterDelta]
		prevLine = line
		prevCharacter = character
		const length = next()
		const type = nonNull(legend.tokenTypes[next()])
		const modifiers = decodeModifiers(next(), legend.tokenModifiers)
		res.push({line, character, length, type, modifiers})
	}
	return res
}

/** @type {function(number, ReadonlyArray<string>): ReadonlyArray<string>} */
const decodeModifiers = (encoded, legend) => {
	assert(legend.length === 1)
	assert(encoded === 0 || encoded === 1)
	return encoded === 0 ? [] : legend
}
