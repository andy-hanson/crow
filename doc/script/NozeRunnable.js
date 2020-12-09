import {NozeText} from "./NozeText.js"
import {LoadingIcon} from "./LoadingIcon.js"
import {Border, cssClass, Color, FontFamily, Margin, Measure, Outline, StyleBuilder, WhiteSpace} from "./util/css.js"
import {button, div} from "./util/html.js"
import {CustomElementClass, makeCustomElement} from "./util/CustomElement.js"
import {removeAllChildren} from "./util/dom.js"
import {MutableObservable} from "./util/MutableObservable.js"

const TEXT = `import
	io

point record
	x float
	y float

s<?t> spec
	+ ?t(a ?t, b ?t)

zero point()
	point: 0, 0

manhattan float(a point)
	a.x + a.y

main fut exit-code(args arr str) summon trusted
	print: "now sleep:"
	0 resolved`

const outputClass = cssClass("output")
const outputOkClass = cssClass("ok")
const outputErrClass = cssClass("err")

//TODO: just style NozeText?
const nozeTextContainerClass = cssClass("noze-text-container")
const outerContainerClass = cssClass("outer-container")

/** @type {CustomElementClass<null, null, null>} */
export const NozeRunnable = makeCustomElement({
	tagName: "noze-runnable",
	styleSheet: new StyleBuilder()
		.class(outerContainerClass, {
			max_width: Measure.em(40),
			margin_x: Margin.auto,
		})
		.class(nozeTextContainerClass, {
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
			width: Measure.em(3),
			border: Border.none,
			outline: Outline.none,
			border_radius_bottom: Measure.ex(1),
			background: Color.yellow,
			margin: Measure.zero,
			padding: Measure.ex(0.25),
		})
		.end(),
	init: () => ({state:null, out:null}),
	connected: async ({ root }) => {
		console.log("WE CONNECTED")
		const comp = await compiler.getGlobalCompiler()
		const MAIN = "main"

		/** @type {MutableObservable<string>} */
		const text = new MutableObservable(TEXT)
		/** @type {MutableObservable<ReadonlyArray<Token>>} */
		const tokens = new MutableObservable(/** @type {ReadonlyArray<Token>} */ ([]))
		/** @type {function(number): string} */
		const getHover = pos =>
			comp.getHover(StorageKind.local, "main", pos)
		const nozeText = NozeText.create({getHover, tokens, text})
		const nozeTextContainer = div({class:nozeTextContainerClass}, [nozeText])

		// TODO: less hacky way of doing this
		const includeFiles = await getIncludeFiles()
		for (const file of includeFiles)
			comp.addOrChangeFile(StorageKind.global, file.name, file.content)

		text.nowAndSubscribe(value => {
			comp.addOrChangeFile(StorageKind.local, MAIN, value)
			tokens.set(comp.getTokens(StorageKind.local, MAIN))
		})

		const output = div({class:outputClass})

		const b = button("Run")
		b.onclick = () => {
			try {
				console.log("LET's RUN!")
				output.className = outputClass.name
				removeAllChildren(output)
				output.append(LoadingIcon.create(null))
				output.append(div(), div(), div(), div())

				const result = comp.run(MAIN)
				output.textContent = result.stdout === "" && result.stderr === ""
					? "no output"
					: result.stdout === "" || result.stderr === ""
					? result.stdout + result.stderr
					: `stderr:\n${result.stderr}\nstdout:\n${result.stdout}`
				output.className = result.err === 0
					? `${outputClass.name} ${outputOkClass.name}`
					: `${outputClass.name} ${outputErrClass.name}`
			} catch (e) {
				console.error("ERROR WHILE RUNNING", e)
				throw e
			}
		}

		const outerContainer = div({class:outerContainerClass}, [nozeTextContainer, output, b])
		root.append(outerContainer)
	},
})

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
			content: await (await fetch(`../include/${name}.nz`)).text(),
		}
		return res
	}))

/** @type {function(): Promise<ReadonlyArray<string>>} */
const listInclude = async () =>
	(await (await fetch('includeList.txt')).text()).trim().split('\n')
