// Importing these modules registers custom elements
import {} from "./CrowIcon.js"
import {} from "./CrowRunnable.js"
import {} from "./SyntaxTranslate.js"

for (const details of document.querySelectorAll('details')) {
	const link = details.querySelector('a')
	if (link) {
		link.onclick = () => {
			details.setAttribute('open', true)
		}
	}
}
