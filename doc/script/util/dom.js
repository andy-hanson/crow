/** @type {function(ShadowRoot | HTMLElement, Node): void} */
export function replaceChildren(em, newChild) {
	removeAllChildren(em)
	em.append(newChild)
}

/** @type {function(Node): void} */
function removeAllChildren(em) {
	while (true) {
		const child = em.firstChild
		if (child === null)
			break
		em.removeChild(child)
	}
}
