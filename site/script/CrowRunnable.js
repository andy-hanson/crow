import {CrowText} from "./CrowText.js"
import {LoadingIcon} from "./LoadingIcon.js"
import {
	Border,
	cssClass,
	Color,
	Cursor,
	FontFamily,
	Margin,
	Measure,
	Outline,
	Selector,
	StyleBuilder,
	WhiteSpace,
} from "./util/css.js"
import {button, div} from "./util/html.js"
import {CustomElementClass, makeCustomElement} from "./util/CustomElement.js"
import {removeAllChildren} from "./util/dom.js"
import {MutableObservable} from "./util/MutableObservable.js"
import {nonNull} from "./util/util.js"

const outputClass = cssClass("output")
const outputOkClass = cssClass("ok")
const outputErrClass = cssClass("err")
const bottomClass = cssClass("bottom")
const iconClass = cssClass("copy-icon")

//TODO: just style CrowText?
const crowTextContainerClass = cssClass("crow-text-container")
const outerContainerClass = cssClass("outer-container")

/** @type {CustomElementClass<{src:string}, null, null>} */
export const CrowRunnable = makeCustomElement({
	tagName: "crow-runnable",
	styleSheet: new StyleBuilder()
		.class(outerContainerClass, {
			margin: Measure.em(1),
			max_width: Measure.em(40),
			margin_x: Margin.auto,
		})
		.class(crowTextContainerClass, {
			border_radius_top: Measure.ex(1),
		})
		.class(outputClass, {
			width: Measure.pct100,
			color: Color.white,
			background: Color.darkerGray,
			font_family: FontFamily.monospace,
			white_space: WhiteSpace.pre,
			tab_size: 4,
		})
		.button({
			border: Border.none,
			outline: Outline.none,
			background: Color.yellow,
			cursor: Cursor.pointer,
		})
		.class(bottomClass, {
			border_radius_bottom: Measure.ex(1),
			background: Color.yellow,
			margin: Measure.zero,
			padding: Measure.ex(0.25),
		})
		.rule(Selector.child(Selector.class(iconClass), Selector.tag("svg")), {
			height: Measure.em(1.25),
		})
		.end(),
	init: () => ({state:null, out:null}),
	connected: async ({ getAttribute, root }) => {

		const comp = await compiler.getGlobalCompiler()
		const src = nonNull(getAttribute("src"))
		const noRun = getAttribute("no-run") !== null
		const initialText = await (await fetch(`/example/${src}.crow`)).text()
		const MAIN = src

		/** @type {MutableObservable<string>} */
		const text = new MutableObservable(initialText)
		/** @type {MutableObservable<ReadonlyArray<Token>>} */
		const tokens = new MutableObservable(/** @type {ReadonlyArray<Token>} */ ([]))
		/** @type {function(number): string} */
		const getHover = pos =>
			comp.getHover(StorageKind.local, src, pos)
		const crowText = CrowText.create({getHover, tokens, text})
		const crowTextContainer = div({class:crowTextContainerClass}, [crowText])

		// TODO: less hacky way of doing this
		const includeFiles = await getIncludeFiles()
		for (const file of includeFiles)
			comp.addOrChangeFile(StorageKind.global, file.name, file.content)

		text.nowAndSubscribe(value => {
			comp.addOrChangeFile(StorageKind.local, MAIN, value)
			tokens.set(comp.getTokens(StorageKind.local, MAIN))
		})

		const output = div({class:outputClass})

		const runButton = noRun ? null : button(playIcon())
		if (runButton) runButton.onclick = () => {
			try {
				output.className = outputClass.name
				removeAllChildren(output)
				output.append(LoadingIcon.create(null))
				output.append(div(), div(), div(), div())
				// Put behind a timeout so loading will show
				setTimeout(() => {
					const result = comp.run(MAIN)
					output.textContent = result.stdout === "" && result.stderr === ""
						? "no output"
						: result.stdout === "" || result.stderr === ""
						? result.stdout + result.stderr
						: `stderr:\n${result.stderr}\nstdout:\n${result.stdout}`
					output.className = result.err === 0
						? `${outputClass.name} ${outputOkClass.name}`
						: `${outputClass.name} ${outputErrClass.name}`
				}, 0)
			} catch (e) {
				console.error("ERROR WHILE RUNNING", e)
				throw e
			}
		}

		const copyButton = button(copyIcon())
		copyButton.onclick = () => {
			navigator.clipboard.writeText(text.get()).catch(e => {
				console.error(e)
			})
		}

		const downloadButton = button(downloadIcon())
		downloadButton.onclick = () => {
			console.log("Clicked download!")
			const a = document.createElement("a")
			a.href = "data:text/csv;charset=utf-8," + encodeURI(text.get())
			a.target = "_blank"
			a.download = "hello.crow"
			a.click()
			console.log("Clicked???")
		}

		const bottom = div({class:bottomClass}, [...(runButton ? [runButton] : []), copyButton, downloadButton])

		const outerContainer = div({class:outerContainerClass}, [crowTextContainer, output, bottom])
		root.append(outerContainer)
	},
})

// Icons from https://heroicons.com/

const playIcon = () =>
	icon(`
		<path
			stroke-linecap="round"
			stroke-linejoin="round"
			stroke-width="2"
			d="M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z" />
		<path
			stroke-linecap="round"
			stroke-linejoin="round"
			stroke-width="2"
			d="M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />`)

const downloadIcon = () =>
	icon(`<path
		stroke-linecap="round"
		stroke-linejoin="round"
		stroke-width="2"
		d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"
	/>`)

/** @return {HTMLElement} */
const copyIcon = () => {
	const data =
		"M8 5H6a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2v-1M8 5a2 2 0 002 2h2a2 2 " +
		"0 002-2M8 5a2 2 0 012-2h2a2 2 0 012 2m0 0h2a2 2 0 012 2v3m2 4H10m0 0l3-3m-3 3l3 3"
	return icon(`<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="${data}"/>`)
}

/** @type {function(string): HTMLElement} */
const icon = content => {
	const res = div({class:iconClass})
	res.innerHTML = `<svg
		xmlns="http://www.w3.org/2000/svg"
		fill="none"
		viewBox="0 0 24 24"
		stroke="currentColor">
		${content}
	</svg>`
	return res
}

/**
 * @typedef FileNameAndContent
 * @property {string} name
 * @property {string} content
 */

/** @type {function(): Promise<ReadonlyArray<FileNameAndContent>>} */
const getIncludeFiles = async () =>
	await Promise.all((await listInclude()).map(async name => {
		/** @type {FileNameAndContent} */
		const res = {
			name,
			content: await (await fetch(`../include/${name}.crow`)).text(),
		}
		return res
	}))

/** @type {function(): Promise<ReadonlyArray<string>>} */
const listInclude = async () =>
	(await (await fetch('/include-list.txt')).text()).trim().split('\n')

const Icon = makeCustomElement({
	tagName: "crow-icon",
	styleSheet: new StyleBuilder()
		.rule(Selector.child(Selector.class(iconClass), Selector.tag("svg")), {
			height: Measure.em(1.25),
		})
		.end(),
	init: () => ({state:null, out:null}),
	connected: async ({ getAttribute, root }) => {
		const icon = getAttribute("icon")
		const theIcon = nonNull({
			copy: copyIcon,
			download: downloadIcon,
			play: playIcon,
		}[icon])()
		root.appendChild(theIcon)
	},
})
