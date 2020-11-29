import {assert, nonNull} from "./assert.js"
import {join, map, objectToMap} from "./collection.js"
import {CustomElementClass} from "./CustomElement.js"
import {InputType} from "./html.js"
import {float} from "./types.js"
import {entries} from "./util.js"

/** @type {function(CSSStyleSheet): string} */
export const showStyleSheet = s =>
	join(map(s.rules, r => r.cssText), '\n')

export class FontFamily {
	// Everything here must correspond to a font family in index.css
	static monospace = new FontFamily("monospace", null)
	static montserrat = new FontFamily("Montserrat", "font/montserrat/Montserrat.css")

	/**
	 * @private
	 * @param {string} show
	 * @param {string | null} cssUrl
	 */
	constructor(show, cssUrl) {
		this.show = show
		this.cssUrl = cssUrl
	}
}

const expandNames = objectToMap({
	margin_x: ["margin-left", "margin-right"],
	margin_y: ["margin-top", "margin-bottom"],
	padding_x: ["padding-left", "padding-right"],
	padding_y: ["padding-top", "padding-bottom"],
	border_radius_bottom: ["border-bottom-left-radius", "border-bottom-right-radius"],
	border_radius_top: ["border-top-left-radius", "border-top-right-radius"],
})

export class Selector {
	/** @type {function(Selector): Selector} */
	static before = s =>
		new Selector(`${s.show}::before`)

	/** @type {function(Selector): Selector} */
	static after = s =>
		new Selector(`${s.show}::after`)

	/** @type {function(Selector): Selector} */
	static active = s =>
		new Selector(`${s.show}:active`)
	/** @type {function(Selector): Selector} */
	static hover = s =>
		new Selector(`${s.show}:hover`)
	/** @type {function(Selector): Selector} */
	static focus = s =>
		new Selector(`${s.show}:focus`)

	/** @type {Selector} */
	static all = new Selector("*")

	/** @type {function(ReadonlyArray<Selector>): Selector} */
	static and = (names) =>
		new Selector(names.map(n => n.show).join(''))

	/** @type {function(CSSClass): Selector} */
	static class = cls =>
		new Selector(`.${cls.name}`)

	/** @type {function(CSSId): Selector} */
	static id = name =>
		new Selector(`#${name}`)

	/** @type {function(ReadonlyArray<Selector>): Selector} */
	static or = names =>
		new Selector(names.map(n => n.show).join(', '))

	/** @type {function(string): Selector} */
	static tag = name =>
		new Selector(name)

	/** @type {function(Selector, Selector): Selector} */
	static child = (a, b) =>
		new Selector(`${a.show} ${b.show}`)

	/**
	 * @param {string} tag
	 * @param {Record<string, string>} attributes
	 * @return {Selector}
	 */
	static tagWithAttributes = (tag, attributes) => {
		const attrs = join(map(entries(attributes), ([k, v]) => `${k}=${JSON.stringify(v)}`), ',')
		return new Selector(`${tag}[${attrs}]`)
	}

	/** @type {function(string, string): Selector} */
	static tagWithState = (name, state) =>
		new Selector(`${name}:${state}`)

	show_ = ""

	/**
	 * @private
	 * @param {string} show
	 */
	constructor(show) {
		this.show_ = show
	}

	get show() { return this.show_ }
}

/** @type {function(string): CSSClass} */
export const cssClass = name =>
	new CSSClass(name)

/** @type {function(string): CSSId} */
export const cssId = name =>
	new CSSId(name)

export class CSSId {
	id_ = ""

	/** @param {string} id */
	constructor(id) {
		this.id_ = id
	}

	/** @return {string} */
	get id() { return this.id_ }
}

export class CSSClass {
	name_ = ""

	/** @param {string} name */
	constructor(name) {
		this.name_ = name
	}

	/** @return {string} */
	get name() { return this.name_ }
}

/** @type {function(string): Promise<CSSStyleSheet>} */
export const styleSheetFromString = css => {
	const sheet = new CSSStyleSheet()
	return sheet.replace(css).then(() => sheet)
}

export class StyleBuilder {
	out_ = new StringBuilder()
	/** @type {Set<FontFamily>} */
	importedFonts_ = new Set()

	/**
	 * @param {string} s
	 * @return {this}
	 */
	raw(s) {
		this.out_.append(s)
		return this
	}

	/**
	 * @param {Selector} selector
	 * @param {RuleOptions} options
	 * @return {this}
	 */
	rule(selector, options) {
		this.out_.append(selector.show)
		this.out_.append(" {")

		if (options.font_family !== undefined)
			assert(options.font_family.cssUrl === null || this.importedFonts_.has(options.font_family), () =>
				`Should have imported font ${nonNull(options.font_family).show}`)

		const keys = (/** @type {ReadonlyArray<keyof RuleOptions>} */ Object.keys(options))
		for (const optionsKey of keys) {
			const anyOptions = toAny(options)
			/** @type {string | {show: string}} */
			const value = anyOptions[optionsKey]
			//TODO: don't allow strings
			if (typeof value !== "string" && typeof value !== "number" && !value.show) {
				throw new Error(`Bad value for ${optionsKey}: ${JSON.stringify(value)}`)
			}
			const show = typeof value === "string" ? value : typeof value === "number" ? String(value) : value.show
			for (const cssKey of expandNames.get(optionsKey) || [optionsKey.replace(/_/g, "-")])
				this.out_.append(` ${cssKey}: ${show};`)
		}
		this.out_.append(" }\n")
		return this
	}

	/** @return {Promise<CSSStyleSheet>} */
	end() {
		return styleSheetFromString(this.out_.end())
	}

	/**
	 * @private
	 * @param {string} imp
	 * @return {this}
	 */
	import(imp) {
		this.out_.append(`@import ${JSON.stringify(imp)};\n`)
		return this
	}

	/**
	 * @param {FontFamily & {cssUrl: string}} font
	 * @return {this}
	 */
	importFont(font) {
		assert(!this.importedFonts_.has(font))
		this.importedFonts_.add(font)
		return this.import(font.cssUrl)
	}

	/**
	 * @param {RuleOptions} options
	 * @return {this}
	 */
	all(options) { return this.rule(Selector.all, options) }

	/**
	 * @param {CSSClass} cls
	 * @param {RuleOptions} options
	 * @return {this}
	 */
	class(cls, options) { return this.rule(Selector.class(cls), options) }

	/**
	 * @param {ReadonlyArray<CSSClass>} classes
	 * @param {RuleOptions} options
	 * @return {this}
	 */
	classOr(classes, options) {
		return this.rule(Selector.or(classes.map(Selector.class)), options)
	}

	/**
	 * @param {CSSId} name
	 * @param {RuleOptions} options
	 * @return {this}
	 */
	id(name, options) { return this.rule(Selector.id(name), options) }

	/**
	 * @param {CSSId} id
	 * @param {CSSClass} cls
	 * @param {RuleOptions} options
	 * @return {this}
	 */
	idAndClass(id, cls, options) {
		return this.rule(Selector.and([Selector.id(id), Selector.class(cls)]), options)
	}

	/**
	 * @param {RuleOptions} options
	 * @return {this}
	 */
	button(options) { return this.rule(Selector.tag("button"), options) }

	/**
	 * @param {RuleOptions} options
	 * @return {this}
	 */
	buttonHover(options) { return this.rule(Selector.tagWithState("button", "hover"), options) }

	/**
	 * @param {RuleOptions} options
	 * @return {this}
	 */
	buttonActive(options) { return this.rule(Selector.tagWithState("button", "active"), options) }

	/**
	 * @param {RuleOptions} options
	 * @return {this}
	 */
	buttonFocus(options) { return this.rule(Selector.tagWithState("button", "focus"), options) }

	/**
	 * @param {RuleOptions} options
	 * @return {this}
	 */
	details(options) { return this.rule(Selector.tag("details"), options) }

	/**
	 * @param {RuleOptions} options
	 * @return {this}
	 */
	footer(options) { return this.rule(Selector.tag("footer"), options) }

	/**
	 * @param {RuleOptions} options
	 * @return {this}
	 */
	header(options) { return this.rule(Selector.tag("header"), options) }

	/**
	 * @param {RuleOptions} options
	 * @return {this}
	 */
	img(options) { return this.rule(Selector.tag("img"), options) }

	/**
	 * @param {RuleOptions} options
	 * @returns {this}
	 */
	input(options) { return this.rule(Selector.tag("input"), options) }

	/**
	 * @param {InputType} type
	 * @param {RuleOptions} options
	 * @returns {this}
	 */
	inputType(type, options) {
		return this.rule(Selector.tagWithAttributes("input", {type}), options)
	}

	/**
	 * @param {RuleOptions} options
	 * @returns {this}
	 */
	inputValid(options) { return this.rule(Selector.tagWithState("input", "valid"), options) }

	/**
	 * @param {RuleOptions} options
	 * @returns {this}
	 */
	inputInvalid(options) { return this.rule(Selector.tagWithState("input", "invalid"), options) }

	/**
	 * @param {RuleOptions} options
	 * @returns {this}
	 */
	inputFocus(options) { return this.rule(Selector.tagWithState("input", "focus"), options) }

	/**
	 * @param {RuleOptions} options
	 * @returns {this}
	 */
	inputActive(options) { return this.rule(Selector.tagWithState("input", "active"), options) }

	/**
	 * @param {RuleOptions} options
	 * @return {this}
	 */
	ionIcon(options) { return this.rule(Selector.tag("ion-icon"), options) }

	/**
	 * @param {RuleOptions} options
	 * @return {this}
	 */
	main(options) { return this.rule(Selector.tag("main"), options) }

	/**
	 * @param {RuleOptions} options
	 * @return {this}
	 */
	pre(options) { return this.rule(Selector.tag("pre"), options) }

	/**
	 * @param {RuleOptions} options
	 * @return {this}
	 */
	section(options) { return this.rule(Selector.tag("section"), options) }

	/**
	 * @param {RuleOptions} options
	 * @return {this}
	 */
	table(options) { return this.rule(Selector.tag("table"), options) }

	/**
	 * @param {RuleOptions} options
	 * @return {this}
	 */
	thead(options) { return this.rule(Selector.tag("thead"), options) }

	/**
	 * @param {RuleOptions} options
	 * @return {this}
	 */
	th(options) { return this.rule(Selector.tag("th"), options) }

	/**
	 * @param {RuleOptions} options
	 * @return {this}
	 */
	td(options) { return this.rule(Selector.tag("td"), options) }

	/**
	 * @param {RuleOptions} options
	 * @return {this}
	 */
	thOrTd(options) { return this.rule(Selector.or([Selector.tag("th"), Selector.tag("td")]), options) }

	/**
	 * @param {RuleOptions} options
	 * @return {this}
	 */
	textarea(options) { return this.rule(Selector.tag("textarea"), options) }

	/**
	 * @param {RuleOptions} options
	 * @return {this}
	 */
	textareaFocus(options) { return this.rule(Selector.tagWithState("textarea", "focus"), options) }

	/**
	 * @template T, U, V
	 * @param {CustomElementClass<T, U, V>} cls
	 * @param {RuleOptions} options
	 * @return {this}
	 */
	custom(cls, options) { return this.rule(Selector.tag(cls.tagName), options) }
}

/**
 * @param {any} o
 * @return {any}
 */
function toAny(o) {
	return o
}

export class Border {
	static none = new Border("none")

	/**
	 * @param {Measure} measure
	 * @param {Color} color
	 * @returns {Border}
	 */
	static solid(measure, color) {
		return new Border(`${measure.show} solid ${color.show}`)
	}

	/**
	 * @param {Measure} measure
	 * @param {Color} color
	 * @returns {Border}
	 */
	static dotted(measure, color) {
		return new Border(`${measure.show} dotted ${color.show}`)
	}

	/**
	 * @readonly
	 * @type {string}
	 */
	show_ = ""

	/**
	 * @private
	 * @param {string} show
	 */
	constructor(show) {
		this.show_ = show
	}

	get show() { return this.show_ }
}
export const Outline = Border

export class BoxShadow {
	static none = new BoxShadow("none")

	/**
	 * @param {Measure} measure
	 * @param {Color} color
	 */
	static make(measure, color) {
		return new this(`0 0 ${measure.show} ${color.show}`)
	}

	/**
	 * @param {Measure} measure
	 * @param {Color} color
	 * @returns {BoxShadow}
	 */
	static downRight(measure, color) {
		return new this(`${measure.show} ${measure.show} 0 0 ${color.show}`)
	}

	/**
	 * @readonly
	 * @type {string}
	 */
	show_ = ""

	/**
	 * @private
	 * @param {string} show
	 */
	constructor(show) {
		this.show_ = show
	}

	get show() { return this.show_ }
}

export class LinearGradient {
	/**
	 * @param {Color} a
	 * @param {Color} b
	 * @return {LinearGradient}
	 */
	static topToBottom(a, b) {
		return new this(`linear-gradient(to bottom, ${a.show} 0%, ${b.show} 100%)`)
	}

	/**
	 * @readonly
	 * @type {string}
	 */
	show_ = ""

	/** @param {string} show */
	constructor(show) {
		this.show_ = show
	}

	get show() { return this.show_ }
}

/**
 * @typedef RuleOptions
 * @property {Align} [align_items]
 * @property {Animation} [animation]
 * @property {string} [animation_timing_function]
 * @property {Background | Color | LinearGradient} [background]
 * @property {Border} [border]
 * @property {Border} [border_bottom]
 * @property {Border} [border_right]
 * @property {Measure} [border_radius]
 * @property {Measure} [border_radius_bottom]
 * @property {Measure} [border_radius_top]
 * @property {BoxShadow} [box_shadow]
 * @property {Color} [caret_color]
 * @property {Color} [color]
 * @property {Content} [content]
 * @property {Cursor} [cursor]
 * @property {Display} [display]
 * @property {string} [filter]
 * @property {string} [flex]
 * @property {string} [flex_direction]
 * @property {string} [flex_grow]
 * @property {string} [flex_wrap]
 * @property {Float} [float]
 * @property {FontFamily} [font_family]
 * @property {Measure} [font_size]
 * @property {FontStyle} [font_style]
 * @property {FontWeight} [font_weight]
 * @property {Measure} [height]
 * @property {Measure} [left]
 * @property {Measure} [line_height]
 * @property {MarginOrMeasure} [margin]
 * @property {MarginOrMeasure} [margin_left]
 * @property {MarginOrMeasure} [margin_right]
 * @property {MarginOrMeasure} [margin_top]
 * @property {MarginOrMeasure} [margin_x]
 * @property {MarginOrMeasure} [margin_y]
 * @property {Measure} [margin_bottom]
 * @property {Measure} [max_width]
 * @property {Measure} [min_height]
 * @property {Border} [outline]
 * @property {Overflow} [overflow]
 * @property {Position} [position]
 * @property {Measure} [padding]
 * @property {Measure} [padding_x]
 * @property {Measure} [padding_y]
 * @property {Measure} [padding_bottom]
 * @property {Measure} [padding_right]
 * @property {Resize} [resize]
 * @property {number} [tab_size]
 * @property {Align} [text_align]
 * @property {Measure} [top]
 * @property {Visibility} [visibility]
 * @property {WhiteSpace} [white_space]
 * @property {Measure} [width]
 * @property {number} [z_index]
 */
export const RuleOptions = {}

export class Align {
	static center = new Align("center")
	static right = new Align("right")

	show_ = ""

	/**
	 * @private
	 * @param {string} show
	 */
	constructor(show) {
		this.show_ = show
	}

	get show() { return this.show_ }
}


export class Background {
	static none = new Background("none")

	/**
	 * @readonly
	 * @type {string}
	 */
	show_ = ""

	/**
	 * @private
	 * @param {string} show
	 */
	constructor(show) {
		this.show_ = show
	}

	get show() { return this.show_ }
}

export class Cursor {
	/** @return {Cursor} */
	static pointer = new Cursor("pointer")

	/**
	 * @readonly
	 * @type {string}
	 */
	show_ = ""

	/**
	 * @private
	 * @param {string} show
	 */
	constructor(show) {
		this.show_ = show
	}

	get show() { return this.show_ }
}

export class FontStyle {
	static italic = new FontStyle("italic")

	/**
	 * @private
	 * @param {string} show
	 */
	constructor(show) {
		this.show_ = show
	}

	get show() { return this.show_ }
}

export class FontWeight {
	static bold = new FontWeight("bold")
	static light = new FontWeight("light")

	/**
	 * @readonly
	 * @type {string}
	 */
	show_ = ""

	/**
	 * @private
	 * @param {string} show
	 */
	constructor(show) {
		this.show_ = show
	}

	get show() { return this.show_ }
}

export class Position {
	static absolute = new Position("absolute")
	static relative = new Position("relative")

	/**
	 * @readonly
	 * @type {string}
	 */
	show_ = ""

	/**
	 * @private
	 * @param {string} show
	 */
	constructor(show) {
		this.show_ = show
	}

	get show() { return this.show_ }
}


export class StringBuilder {
	out_ = ""

	/** @return {string} */
	end() {
		return this.out_
	}

	/**
	 * @param {string} s
	 * @return {void}
	 */
	append(s) {
		this.out_ += s
	}
}

export class BiMeasure {
	/** @param {{ readonly x: Measure, readonly y: Measure }} options */
	constructor(options) {
		this.x = options.x
		this.y = options.y
	}

	get show() {
		return `${this.y.show} ${this.x.show}`
	}
}

/** @typedef {Margin | Measure} MarginOrMeasure */

export class Margin {
	/**
	 * @readonly
	 * @type {Margin}
	 */
	static auto = new Margin("auto")

	show_ = ""

	/**
	 * @private
	 * @param {string} s
	 */
	constructor(s) {
		/** @readonly */
		this.show_ = s
	}

	/** @return {string} */
	get show() { return this.show_ }
}

export class Measure {
	/**
	 * @param {Measure} a
	 * @param {Measure} b
	 * @return {Measure}
	 */
	static subtract = (a, b) =>
		new Measure(`calc(${a.show} - ${b.show})`)

	/** @type {function(float): Measure} */
	static em = n =>
		new Measure(`${n}em`)

	/** @type {function(float): Measure} */
	static ex = n =>
		new Measure(`${n}ex`)

	/** @type {function(float): Measure} */
	static pct = n =>
		new Measure(`${n}%`)

	/** @type {function(float): Measure} */
	static px = n =>
		new Measure(`${n}px`)

	static pct50 = Measure.pct(50)
	static pct100 = Measure.pct(100)
	static zero = new Measure("0")

	/**
	 * @private
	 * @param {string} s
	 */
	constructor(s) {
		/** @readonly */
		this.show = s
	}
}

export class Color {
	static black = new Color("#000000")
	static transparent = new Color("#00000000")

	// stolen from https://monokai.pro/
	static white = new Color("#fdf9f3")
	static pink = new Color("#ff6188")
	static peach = new Color("#fc9867")
	static yellow = new Color("#ffd866")
	static lightYellow = new Color("#ffebbd") // mine
	static green = new Color("#a9dc76")
	static greenDarker = new Color("#89bc56") //mine
	static greenDarker2 = new Color("#699c36") //mine
	static blue = new Color("#78dce8")
	static lavender = new Color("#ab9df2")
	static darkGray = new Color("#2c292d")
	//half of darkGray
	static darkerGray = new Color("#161517")
	static midGray = new Color("#423e44")
	static lightGray = new Color("#6c696d")
	static lighterGray = new Color("#aaa")
	static lightestGray = new Color("#ddd")

	//I made this
	static red = new Color("#e87878")
	//I made this
	static lightRed = new Color("#f898fc")

	/** @param {string} show */
	constructor(show) {
		/**
		 * @readonly
		 * @type {string}
		 */
		this.show_ = show
	}

	/** @return {string} */
	get show() {
		return this.show_
	}
}

export class Display {
	static block = new Display("block")
	static flex = new Display("flex")
	static inline = new Display("inline")
	static inlineBlock = new Display("inline-block")
	static none = new Display("none")

	show_ = ""

	/**
	 * @private
	 * @param {string} show
	 */
	constructor(show) {
		this.show_ = show
	}

	/** @return {string} */
	get show() {
		return this.show_
	}
}

export class Visibility {
	static hidden = new Visibility("hidden")

	/**
	 * @private
	 * @param {string} show
	 */
	constructor(show) {
		this.show_ = show
	}

	/** @return {string} */
	get show() {
		return this.show_
	}
}

export class Float {
	static left = new Float("left")
	static right = new Float("right")

	show_ = ""

	/**
	 * @private
	 * @param {string} show
	 */
	constructor(show) {
		this.show_ = show
	}

	/** @return {string} */
	get show() {
		return this.show_
	}
}

export class WhiteSpace {
	static pre = new WhiteSpace("pre")
	static noWrap = new WhiteSpace("nowrap")

	/**
	 * @private
	 * @param {string} show
	 */
	constructor(show) {
		this.show_ = show
	}

	/** @return {string} */
	get show() { return this.show_ }
}

export class Content {
	/**
	 * @param {string} attr
	 * @return {Content}
	 */
	static attr(attr) {
		return new Content(`attr(${attr})`)
	}

	/**
	 * @param {string} text
	 * @return {Content}
	 */
	static text(text) {
		return new Content(JSON.stringify(text))
	}

	/**
	 * @private
	 * @param {string} show
	 */
	constructor(show) {
		this.show_ = show
	}


	/** @return {string} */
	get show() { return this.show_ }
}

export class Resize {
	static none = new Resize("none")

	/** @param {string} show */
	constructor(show) {
		this.show = show
	}
}

export class Overflow {
	static auto = new Overflow("auto")

	/** @param {string} show */
	constructor(show) {
		this.show = show
	}
}

export class Animation {
	/** @type {function(string, float): Animation} */
	static infinite = (name, seconds) =>
		new Animation(`${name} ${seconds}s infinite`)

	/** @param {string} show */
	constructor(show) {
		this.show = show
	}
}
