window.onload = () => {
	main().catch(e => { console.error(e) })
}

const src = `
f void()
	a
`

const mainTEST = async () => {
	const bytes = await (await fetch('../bin/noze.wasm')).arrayBuffer()
	const result = await WebAssembly.instantiate(bytes, {})
	const { exports } = result.instance;
	const { getBufferSize, getBuffer, getAst, memory } = exports
	const view = new DataView(memory.buffer)

	const bufferSize = getBufferSize()
	const buffer = getBuffer()

	const setStr = str => writeString(view, buffer, bufferSize, str)
	const getStr = () => readString(view, buffer, bufferSize)

	setStr(src)
	console.log(getStr())
	getAst()
	console.log(getStr())
}

const main = async () => {
	const nozeDiv = document.querySelector(".noze")
	const highlightDiv = document.createElement("div")
	highlightDiv.className = 'highlight'
	nozeDiv.appendChild(highlightDiv)
	const ta = document.createElement("textarea")
	nozeDiv.appendChild(ta)
	ta.value = "import\n\tio\n\nmain void()\n\t0\n\n"
	ta.setAttribute('spellcheck', 'false')

	ta.addEventListener("keydown", e => {
		console.log("keydown!")
		const { keyCode } = e
		const { value, selectionStart, selectionEnd } = ta
		if (keyCode === "\t".charCodeAt(0)) {
			e.preventDefault()
			ta.value = value.slice(0, selectionStart) + "\t" + value.slice(selectionEnd)
			ta.setSelectionRange(selectionStart + 1, selectionStart + 1);
			highlight(highlightDiv, ta)
		}
	})
	ta.addEventListener("input", () => {
		highlight(highlightDiv, ta)
	})
	highlight(highlightDiv, ta)
	console.log("DONE")
}

const removeAllChildren = em => {
	while (em.firstChild)
		em.removeChild(em.lastChild)
}

const highlight = (highlightDiv, ta) => {
	const v = ta.value
	const valueLines = v.split('\n')
	removeAllChildren(highlightDiv)

	for (let i = 0; i < valueLines.length; i++) {
		const lineText = valueLines[i].replace(/\t/g, " ".repeat(4))
		const childTextClass = i == 0 ? 'keyword' : 'name'
		highlightDiv.appendChild(createDiv({
			className: 'line',
			children: [createSpan(childTextClass, lineText)],
		}))
	}
}

const createDiv = (options) => {
	const div = document.createElement('div')
	if (options.className)
		div.className = options.className
	if (options.children)
		for (const child of options.children)
			div.appendChild(child)
	return div
}

const createSpan = (className, text) => {
	const span = document.createElement('span')
	span.className = className
	span.innerText = text
	return span
}

const fillIn = async node => {
	const src = node.getAttribute('data-src')
	console.log(src)
	const text = await (await fetch(`../test/runnable/${src}`)).text()
	node.innerText = text
}

function writeString(view, buffer, bufferSize, str) {
	if (str.length >= bufferSize)
		throw new Error("input too long")
	for (let i = 0; i < str.length; i++)
		view.setUint8(buffer + i, str.charCodeAt(i))
	view.setUint8(buffer + str.length, 0)
}

function readString(view, buffer, bufferSize) {
	let s = ''
	let i;
	for (i = 0; i < bufferSize; i++) {
		const code = view.getUint8(buffer + i)
		if (code === 0)
			break
		s += String.fromCharCode(code)
	}
	if (i == bufferSize)
		throw new Error("TOO LONG")
	return s
}
