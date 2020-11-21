export {}

Error.stackTraceLimit = 1000

import {Compiler, Files} from "./Compiler.js"
import {NozeText} from "./NozeText.js"
import {NozeRunnable} from "./NozeRunnable.js"
import {MutableObservable} from "./util/MutableObservable.js"

window.onload = () => {
	main().catch(e => {
		console.error(e.stack)
	})
}

const TEST_SRC = `import
	io

main fut exit-code(args arr str) summon trusted
	print-sync: & "now sleep:"
	0 resolved
`

const main = async () => {
	const compiler = await Compiler.make()

	/*
	const text = new MutableObservable(TEST_SRC)
	const x = NozeText.create({compiler, text})
	document.body.append(x)
	text.subscribe(t => {
		console.log("new text: ", t)
	})
	*/

	/*
	const includeFiles = await getIncludeFiles()
	console.log("INCLUDE FILES", includeFiles)



	const runResult = runCode(compiler, includeFiles, TEST_SRC)
	console.log("RUN RESULT", runResult)
	*/

	/*const nozeDiv = nonNull(document.querySelector(".noze"))

	//const button = document.createElement("button")
	//button.textContent = "run"
	//nozeDiv.appendChild(button)

	/*
	const nozeCodeDiv = document.createElement("div")
	nozeCodeDiv.className = 'code'
	nozeDiv.appendChild(nozeCodeDiv)


	const highlightDiv = document.createElement("div")
	highlightDiv.className = "highlight"
	nozeCodeDiv.appendChild(highlightDiv)
	const ta = document.createElement("textarea")
	nozeCodeDiv.appendChild(ta)
	ta.value = TEST_SRC
	ta.setAttribute("spellcheck", "false")

	ta.addEventListener("keydown", e => {
		const { keyCode } = e
		const { value, selectionStart, selectionEnd } = ta
		if (keyCode === "\t".charCodeAt(0)) {
			e.preventDefault()
			ta.value = value.slice(0, selectionStart) + "\t" + value.slice(selectionEnd)
			ta.setSelectionRange(selectionStart + 1, selectionStart + 1);
			highlight(compiler, highlightDiv, ta)
		}
	})
	ta.addEventListener("input", () => {
		highlight(compiler, highlightDiv, ta)
	})
	highlight(compiler, highlightDiv, ta)
	console.log("DONE")
	*/
}

/** @type {function(): Promise<ReadonlyArray<string>>} */
const listInclude = async () => {
	return (await (await fetch('includeList.txt')).text()).trim().split('\n')
}

/** @type {function(): Promise<Files>} */
const getIncludeFiles = async () =>
	Object.fromEntries(await Promise.all((await listInclude()).map(nameAndText)))

/** @type {function(string): Promise<[string, string]>} */
const nameAndText = async name =>
	[name, await (await fetch(`../include/${name}.nz`)).text()]




