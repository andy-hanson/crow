export {}

// Registers the element
import {} from "./CrowRunnable.js"

const cur = location.pathname
const section = cur.split("/")[1]

for (const a of document.querySelectorAll("header a")) {
	if (a.getAttribute("href") === `/${section}`) {
		a.classList.add("current")
	}
}

for (const a of document.querySelectorAll("#side-nav-wrapper a")) {
	console.log("HREF", {its:a.getAttribute("href"), wanted:cur})
	if (a.getAttribute("href") === cur) {
		a.classList.add("current")
	}
}
