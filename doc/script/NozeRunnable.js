import {NozeText} from "./NozeText.js"
import {LoadingIcon} from "./LoadingIcon.js"
import {Border, cssClass, Color, FontFamily, Margin, Measure, Outline, StyleBuilder, WhiteSpace} from "./util/css.js"
import {button, div} from "./util/html.js"
import {CustomElementClass, makeCustomElement} from "./util/CustomElement.js"
import {removeAllChildren} from "./util/dom.js"
import {MutableObservable} from "./util/MutableObservable.js"
import {launch} from "./util/util.js"

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
	print-sync: "now sleep:"
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

		console.log("CONNECTED!")
		/** @type {MutableObservable<string>} */
		const text = new MutableObservable(TEXT)
		const nozeText = NozeText.create({compiler:comp, text})
		const nozeTextContainer = div({class:nozeTextContainerClass}, [nozeText])

		const output = div({class:outputClass})
		//output.style.height = '0'

		const b = button("Run")
		b.onclick = () => launch(async () => {
			output.className = outputClass.name
			removeAllChildren(output)
			output.append(LoadingIcon.create(null))
			output.append(div(), div(), div(), div())

			const result = await comp.runFile(text.get())
			output.textContent = result.stdout === "" && result.stderr === ""
				? "no output"
				: result.stdout === "" || result.stderr === ""
				? result.stdout + result.stderr
				: `stderr:\n${result.stderr}\nstdout:\n${result.stdout}`
			output.className = result.err === 0
				? `${outputClass.name} ${outputOkClass.name}`
				: `${outputClass.name} ${outputErrClass.name}`
		})

		const outerContainer = div({class:outerContainerClass}, [nozeTextContainer, output, b])
		root.append(outerContainer)
	},
})
