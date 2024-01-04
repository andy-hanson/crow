const getUserName = async () => {
	const loginCookie = getCookie("login")
	if (loginCookie === null)
		return null
	else {
		const userId = loginCookie.split("|")[0]
		return (await fetch(`/user-name?user=${userId}`)).text()
	}
}

const showLoggedIn = async () => {
	const name = await getUserName()
	nonNull(document.getElementById("showLoggedIn")).textContent = name ? `Logged in as ${name}` : "Not logged in"
}

/** @type {function(string): string | null} */
const getCookie = cookieName => {
	for (const part of document.cookie.split(";")) {
		const [name, value] = part.split("=")
		if (name === cookieName)
			return nonNull(value)
	}
	return null
}

window.onload = () => {
	run(() => showLoggedIn())

	const register = typeAs(document.querySelector('form[name="register"]'), HTMLFormElement)
	typeAs(register.querySelector('input[type="submit"]'), HTMLInputElement).onclick = () => run(async () => {
		const userName = typeAs(register.querySelector('input[name="user-name"]'), HTMLInputElement).value
		const password = typeAs(register.querySelector('input[name="password"]'), HTMLInputElement).value
		const body = toForm({"user-name":userName, password})
		const response = await (await fetch("/register", {method:"POST", body})).text()
		await loadUsers()
		alert(response)
	})

	const login = typeAs(document.querySelector('form[name="login"]'), HTMLFormElement)
	typeAs(login.querySelector('input[type="submit"]'), HTMLInputElement).onclick = () => run(async () => {
		const userName = typeAs(login.querySelector('input[name="user-name"]'), HTMLInputElement).value
		const password = typeAs(login.querySelector('input[name="password"]'), HTMLInputElement).value
		const body = toForm({"user-name":userName, password})
		console.log("BEFORE COOKIE IS", document.cookie)
		const response = await (await fetch("/login", {method:"POST", body})).text()
		console.log("NOW COOKIE IS", document.cookie)
		await showLoggedIn()
		alert(response)
	})

	const post = typeAs(document.querySelector('form[name="post"]'), HTMLFormElement)
	typeAs(post.querySelector('input[type="submit"]'), HTMLInputElement).onclick = () => run(async () => {
		const content = typeAs(post.querySelector('input[name="content"]'), HTMLInputElement).value
		const response = await (await fetch("/post", {method:"POST", credentials: "include", body:content})).text()
		await loadPosts()
		alert(response)
	})

	run(() => loadUsersAndPosts())
}

/** @type {function(): Promise<void>} */
const loadUsersAndPosts = async () => {
	loadUsers()
	loadPosts()
}

/** @type {function(): Promise<void>} */
const loadUsers = async () => {
	const usersDiv = nonNull(document.getElementById("users"))
	clear(usersDiv)
	const {users} = await (await fetch("/users")).json()
	for (const {user, userName} of users) {
		const node = document.createElement("div")
		node.textContent = `${user}: ${userName}`
		usersDiv.append(node)
	}
}

/** @type {function(): Promise<void>} */
const loadPosts = async () => {
	const postsDiv = nonNull(document.getElementById("posts"))
	clear(postsDiv)
	const {posts} = await (await fetch("/posts")).json()
	for (const {post, userName, content} of posts) {
		const node = document.createElement("div")
		node.textContent = `${post}: ${userName} says: ${content}`
		postsDiv.append(node)
	}
}

/** @type {function(() => Promise<void>): void} */
const run = f => {
	f().catch(e => {
		console.error(e)
		alert(e.message)
	})
}

/** @type {function(Node): void} */
const clear = node => {
	while (node.lastChild)
		node.removeChild(node.lastChild)
}

/** @type {function(Record<string, string>): string} */
const toForm = data =>
	Object.entries(data)
		.map(([key, value]) => `${encodeURIComponent(key)}=${encodeURIComponent(value)}`)
		.join("&")


/**
 * @template T
 * @param {T | null | undefined} x
 * @return {T}
 */
const nonNull = x => {
	if (x == null)
		throw new Error("Null value")
	return x
}

/**
 * @template T
 * @param {unknown} x
 * @param {new () => T} type
 * @return {T}
 */
const typeAs = (x, type) => {
	if (!(x instanceof type))
		throw new Error("Not instance of type")
	return /** @type {T} */ (x)
}
