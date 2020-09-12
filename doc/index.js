console.log("HELLO WORLD")


window.onload = () => {
	console.log("LOADED!")
	const nodes = document.body.querySelectorAll('[data-src]')
	for (const node of nodes) {
		fillIn(node).catch(e => console.error(e))
	}
	console.log({nodes})
}

const fillIn = async node => {
	const src = node.getAttribute('data-src')
	console.log(src)
	const text = await (await fetch(`../test/runnable/${src}`)).text()
	node.innerText = text
}


const main = async () => {
	//const rslt = await (await fetch('../test/runnable/example-record.c')).text()
	//console.log({rslt})
}

main().catch(e => {
	console.error(e)
})

