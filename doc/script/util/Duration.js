import { float } from "./types.js"

export class Duration {
	/** @type {function(float): Duration} */
	static days = days =>
		Duration.hours(days * 24)

	/** @type {function(float): Duration} */
	static hours = hours =>
		Duration.minutes(hours * 60)

	/** @type {function(float): Duration} */
	static minutes = minutes =>
		Duration.seconds(minutes * 60)

	/** @type {function(float): Duration} */
	static seconds = seconds =>
		Duration.msec(seconds * 1000)

	/** @type {function(float): Duration} */
	static msec = msec =>
		new Duration(msec)

	static zero = Duration.msec(0)

	msec_ = 0

	/**
	 * @private
	 * @param {float} msec
	 */
	constructor(msec) {
		this.msec_ = msec
	}

	/** @type {float} */
	get msec() { return this.msec_ }

	/** @return {Date} */
	addToNow() {
		return new Date(Date.now() + this.msec_)
	}
}

/** @type {function(Duration): Promise<void>} */
export const sleep = duration =>
	new Promise((resolve) => setTimeout(resolve, duration.msec))

/**
 * Await this to get to the next tick
 * @return {Promise<void>}
 */
export const nextTick = () => sleep(Duration.zero)
