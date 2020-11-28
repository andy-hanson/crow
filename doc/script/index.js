export {}

Error.stackTraceLimit = 1000

//import {NozeText} from "./NozeText.js"
compiler.getGlobalCompiler()

// Registers the element
import {NozeRunnable} from "./NozeRunnable.js"
NozeRunnable;

window.onload = () => {
	main().catch(e => {
		console.error(e.stack)
	})
}

const main = async () => {
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



