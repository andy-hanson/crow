import {Compiler, getGlobalCompiler} from "./Compiler.js"
import {NozeText} from "./NozeText.js"
import {Background, Border, cssClass, Color, Measure, StyleBuilder, WhiteSpace} from "./util/css.js"
import {button, div} from "./util/html.js"
import {CustomElementClass, makeCustomElement} from "./util/CustomElement.js"
import {MutableObservable} from "./util/MutableObservable.js"

const TEXT = "aaa"/*`import
	io

main fut exit-code(args arr str) summon trusted
	print-sync: "now sleep:"
	0 resolved`*/

const outputClass = cssClass('output')

//TODO: just style NozeText?
const nozeTextContainerClass = cssClass('noze-text-container')

/** @type {CustomElementClass<null, null, null>} */
export const NozeRunnable = makeCustomElement({
	tagName: "noze-runnable",
	styleSheet: new StyleBuilder()
		.class(nozeTextContainerClass, {
			background: Color.yellow,
			border_radius_top: Measure.ex(1),
		})
		.class(outputClass, {
			width: Measure.pct100,
			background: Color.green,
			white_space: WhiteSpace.pre,
		})
		.button({
			width: Measure.em(3),
			border: Border.none,
			border_radius_bottom: Measure.ex(1),
			background: Color.yellow,
			margin: Measure.zero,
			padding: Measure.ex(0.25),
		})
		.end(),
	init: () => ({state:null, out:null}),
	connected: async ({ props, state, root }) => {
		const compiler = await getGlobalCompiler()

		console.log("CONNECTED!")
		/** @type {MutableObservable<string>} */
		const text = new MutableObservable(TEXT)
		const nozeText = NozeText.create({compiler, text})
		const nozeTextContainer = div({class:nozeTextContainerClass}, [nozeText])

		const output = div({class:outputClass})
		output.style.height = '0'

		const b = button("Run")
		b.onclick = () => {
			output.textContent = 'abc\ndef\nghi'
			output.style.height = '100%'
		}

		root.append(nozeTextContainer, output, b)
	},
})
