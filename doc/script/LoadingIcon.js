import {Animation, cssClass, Color, Display, Measure, Position, Selector, StyleBuilder} from "./util/css.js"
import {CustomElementClass, makeCustomElement} from "./util/CustomElement.js"
import {div} from "./util/html.js"

const rootClass = cssClass("root")
const child0Class = cssClass("child-0")
const child1Class = cssClass("child-1")
const child2Class = cssClass("child-2")
const child3Class = cssClass("child-3")

const time = 0.8

/** @type {CustomElementClass<null, null, null>} */
export const LoadingIcon = makeCustomElement({
	tagName: "noze-loading-spinner",
	styleSheet: new StyleBuilder()
		.class(rootClass, {
			display: Display.inlineBlock,
			position: Position.relative,
			height: Measure.em(2),
		})
		.rule(Selector.or([child0Class, child1Class, child2Class, child3Class].map(Selector.class)), {
			position: Position.absolute,
			top: Measure.em(0.75),
			width: Measure.em(0.666),
			height: Measure.em(0.666),
			border_radius: Measure.pct50,
			background: Color.lavender,
			animation_timing_function: "cubic-bezier(0, 1, 1, 0)",
		})
		.class(child0Class, {
			left: Measure.em(1),
			animation: Animation.infinite("ani0", time),
		})
		.class(child1Class, {
			left: Measure.em(1),
			animation: Animation.infinite("ani1", time),
		})
		.class(child2Class, {
			left: Measure.em(2),
			animation: Animation.infinite("ani1", time),
		})
		.class(child3Class, {
			left: Measure.em(3),
			animation: Animation.infinite("ani2", time),
		})
		.raw(`
			@keyframes ani0 {
				0% { transform: scale(0); }
				100% { transform: scale(1); }
			}
			@keyframes ani1 {
				0% { transform: translate(0, 0); }
				100% { transform: translate(1em, 0); }
			}
			@keyframes ani2 {
				0% { transform: scale(1); }
				100% { transform: scale(0); }
			}
		`)
		.end(),
	init: () => ({state:null, out:null}),
	connected: async ({root}) => {
		root.append(div({class:rootClass}, [
			div({class:child0Class}),
			div({class:child1Class}),
			div({class:child2Class}),
			div({class:child3Class}),
		]))
	},
})
