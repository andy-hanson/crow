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
	document.getElementById("showLoggedIn").textContent = name ? `Logged in as ${name}` : "Not logged in"
}

/** @type {function(string): string | null} */
const getCookie = cookieName => {
	for (const part of document.cookie.split(";")) {
		const [name, value] = part.split("=")
		if (name === cookieName)
			return value
	}
	return null
}

window.onload = () => {
	run(() => showLoggedIn())

	const register = document.querySelector('form[name="register"]')
	register.querySelector('input[type="submit"]').onclick = () => run(async () => {
		const userName = register.querySelector('input[name="user-name"]').value
		const password = register.querySelector('input[name="password"]').value
		const body = JSON.stringify({userName, password})
		const response = await (await fetch("/register", {method:"POST", body})).text()
		await loadUsers()
		alert(response)
	})

	const login = document.querySelector('form[name="login"]')
	login.querySelector('input[type="submit"]').onclick = () => run(async () => {
		const userName = login.querySelector('input[name="user-name"]').value
		const password = login.querySelector('input[name="password"]').value
		const body = JSON.stringify({userName, password})
		const response = await (await fetch("/login", {method:"POST", body})).text()
		await showLoggedIn()
		alert(response)
	})

	const post = document.querySelector('form[name="post"]')
	post.querySelector('input[type="submit"]').onclick = () => run(async () => {
		const content = post.querySelector('input[name="content"]').value
		const body = JSON.stringify({content})
		const response = await (await fetch("/post", {method:"POST", credentials: "include", body})).text()
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
	const usersDiv = document.getElementById("users")
	clear(usersDiv)
	const {users} = await (await fetch("/users")).json()
	for (const {user, "user-name":userName} of users) {
		const node = document.createElement("div")
		node.textContent = `${user}: ${userName}`
		usersDiv.append(node)
	}
}

/** @type {function(): Promise<void>} */
const loadPosts = async () => {
	const postsDiv = document.getElementById("posts")
	clear(postsDiv)
	const {posts} = await (await fetch("/posts")).json()
	for (const {post, "user-name":userName, content} of posts) {
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
