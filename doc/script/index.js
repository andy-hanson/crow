export {}

import {assert, nonNull} from "./util/assert.js"
// Registers the element
import {NozeRunnable} from "./NozeRunnable.js"
NozeRunnable;

window.onload = () => {
	window.onhashchange = onHashChange
	onHashChange()
}

const onHashChange = () => {
	main().catch(e => {
		console.error(e.stack)
	})
}

const main = async () => {
	const hash = window.location.hash || "#crow"
	assert(hash.startsWith("#"))
	const pageName = hash.slice(1)
	const html = await (await fetch(`./content/${pageName}.html`)).text()
	nonNull(document.querySelector('main')).innerHTML = html

}
