/** @template T */
export class Observable {
	value_ = /** @type {T} */ (/** @type {unknown} */ (null))
	subscribers_ = /** @type {Array<(t: T) => void>} */ ([])

	/** @param {T} init */
	constructor(init) {
		this.value_ = init
	}

	'get'() {
		return this.value_
	}

	/**
	 * @param {(t: T) => void} cb
	 * @return {() => void}
	 */
	nowAndSubscribe(cb) {
		cb(this.get())
		return this.subscribe(cb)
	}

	/**
	 * @param {(t: T) => void} cb
	 * @return {() => void}
	 */
	subscribe(cb) {
		this.subscribers_.push(cb)
		return () => {
			remove(this.subscribers_, cb)
		}
	}
}

/**
 * @template T
 * @extends {Observable<T>}
 */
export class MutableObservable extends Observable {
	/**
	 * @param {T} value
	 */
	set(value) {
		this.value_ = value
		for (const subscriber of this.subscribers_)
			subscriber(value)
	}
}

/**
 * @template T
 * @param {Array<T>} xs
 * @param {T} x
 * @return {void}
 */
const remove = (xs, x) => {
	const index = xs.indexOf(x)
	xs.splice(index, 1)
}

