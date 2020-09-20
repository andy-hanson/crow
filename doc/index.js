window.onload = () => {
	main().catch(e => { console.error(e) })
}

const src = `
f void()
	a
`

const main = async () => {
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
