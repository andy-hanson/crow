// https://github.com/tc39/proposal-observable/blob/master/src/Observable.js
// And I added types

import {assert, nonNull} from "./assert.js"

// === Symbol Polyfills ===

/** @type {function(string): void} */
function polyfillSymbol(name) {
	if (!/** @type {any} */ (Symbol)[name])
		Object.defineProperty(Symbol, name, { value: Symbol(name) })
}
polyfillSymbol("observable")

/**
 * @template T
 * @template {keyof Observer<T>} K
 * @param {Observer<T>} obj
 * @param {K} key
 * @return {Observer<T>[K] | undefined}
 */
function getMethod(obj, key) {
	const value = obj[key]
	if (value == null)
		return undefined
	if (typeof value !== "function")
		throw new TypeError(`${value} is not a function`)
	return value
}

/**
 * @template T
 * @param {Subscription<T>} subscription
 * @return {void}
 */
function cleanupSubscription(subscription) {
	// Assert:  observer._observer is undefined
	const cleanup = subscription._cleanup
	if (!cleanup)
		return

	// Drop the reference to the cleanup function so that we won't call it
	// more than once
	subscription._cleanup = undefined

	// Call the cleanup function
	try {
		cleanup()
	} catch (e) {
		console.error("CLEANUPSUBSCRIPTION ERROR: ", e)
	}
}

/**
 * @template T
 * @param {Subscription<T>} subscription
 * @return {boolean}
 */
function subscriptionClosed(subscription) {
	return subscription._observer === undefined
}

/**
 * @template T
 * @param {Subscription<T>} subscription
 * @return {void}
 */
function closeSubscription(subscription) {
	if (subscriptionClosed(subscription))
		return

	subscription._observer = undefined
	cleanupSubscription(subscription)
}

/**
 * https://github.com/tc39/proposal-observable#observer
 * @template T
 * @typedef Observer
 * @property {(function(Subscription<T>): void) | undefined} [start]
 * @property {function(T): void} next
 * @property {(function(unknown): void) | undefined} [error]
 * @property {(function(): void) | undefined} [complete]
 * @property {boolean | undefined} [closed]
 */
export const Observer = {}

/**
 * https://github.com/tc39/proposal-observable#observer
 * @template T
 * @typedef NonOptionalObserver
 * @property {function(Subscription<T>): void} start
 * @property {function(T): void} next
 * @property {function(unknown): void} error
 * @property {function(): void} complete
 */
export const NonOptionalObserver = {}

/**
 * @template T
 * @typedef {function(Observer<T>): Cleanup | void} Subscriber
 */

/**
 * @typedef {() => void} Cleanup
 */

/**
 * https://github.com/tc39/proposal-observable#observable
 * @template T
 */
export class Subscription {
	/**
	 * @param {Observer<T>} observer
	 * @param {Subscriber<T>} subscriber TODO: What is the type?
	 */
	constructor(observer, subscriber) {
		// Assert: subscriber is callable
		// The observer must be an object
		/** @typedef {Cleanup | undefined} */
		this._cleanup = undefined
		/** @type {Observer<T> | undefined} */
		this._observer = observer

		// If the observer has a start method, call it with the subscription object
		try {
			const start = getMethod(observer, "start")
			if (start) start.call(observer, this)
		} catch (e) {
			console.error("SUBSCRIPTION CONSTRUCTOR ERROR", e)
		}

		// If the observer has unsubscribed from the start method, exit
		if (subscriptionClosed(this))
			return

		const subscriptionObserver = new SubscriptionObserver(this)

		try {
			// Call the subscriber function
			/** @type {Cleanup | void} */
			const cleanup = subscriber.call(undefined, observer)

			// The return value must be undefined, null, a subscription object, or a function
			if (cleanup != null) {
				//if (typeof cleanup.unsubscribe === "function")
				//	cleanup = cleanupFromSubscription(cleanup)
				//else
				if (typeof cleanup !== "function")
					throw new TypeError(cleanup + " is not a function")

				this._cleanup = cleanup
			}

		} catch (e) {
			// If an error occurs during startup, then send the error
			// to the observer.
			subscriptionObserver.error(e)
			return
		}

		// If the stream is already finished, then perform cleanup
		if (subscriptionClosed(this))
			cleanupSubscription(this)
	}

	/** @return {boolean} */
	get closed() {
		return subscriptionClosed(this)
	}

	/** @return {void} */
	unsubscribe() {
		closeSubscription(this)
	}
}

/**
 * https://github.com/tc39/proposal-observable#observer
 * @template T
 */
class SubscriptionObserver {
	/** @param {Subscription<T>} subscription */
	constructor(subscription) {
		this._subscription = subscription
	}

	/** @return {boolean} */
	get closed() {
		return subscriptionClosed(this._subscription)
	}

	/**
	 * @param {T} value
	 * @return {void}
	 */
	next(value) {
		let subscription = this._subscription
		if (subscriptionClosed(subscription))
			return

		let observer = nonNull(subscription._observer)
		try {
			let m = getMethod(observer, "next")
			// If the observer doesn't support "next", then return undefined
			if (!m)
				return
			// Send the next value to the sink
			m.call(observer, value)
		}
		catch(e) {
			console.error("SUBSCRIPTIONOBSERVER NEXT", e)
		}
	}

	/**
	 * @param {unknown} value
	 * @return {void}
	 */
	error(value) {
		let subscription = this._subscription

		// If the stream is closed, throw the error to the caller
		if (subscriptionClosed(subscription))
			return

		let observer = nonNull(subscription._observer)
		subscription._observer = undefined

		try {
			let m = getMethod(observer, "error")

			// If the sink does not support "complete", then return undefined
			if (m) {
				m.call(observer, value)
			}
			else {
				console.error("Error in error in error!")
			}
		} catch (e) {
			console.error("Errir in error", e)
		}

		cleanupSubscription(subscription)
	}

	/** @return {void} */
	complete() {
		let subscription = this._subscription

		// If the stream is closed, then return undefined
		if (subscriptionClosed(subscription))
			return undefined

		let observer = nonNull(subscription._observer)
		subscription._observer = undefined

		try {
			let m = getMethod(observer, "complete")
			// If the sink does not support "complete", then return undefined
			if (m)
				/** @type {any} */ (m).call(observer)
		} catch (e) {
			console.error("error in complete", e)
		}

		cleanupSubscription(subscription)
	}
}

/** @template T */
export class Observable {
	/** @param {Subscriber<T>} subscriber */
	constructor(subscriber) {
		// The stream subscriber must be a function
		if (typeof subscriber !== "function")
			throw new TypeError("Observable initializer must be a function")
		this._subscriber = subscriber
	}

	/**
	 * @param {((t: T) => void) | Observer<T>} observer
	 * @param {Observer<T>} observer
	 * @return {Subscription<T>}
	 */
	subscribe(observer) {
		if (typeof observer === "function") {
			observer = {
				next: observer,
				error: undefined,
				complete: undefined,
			}
		}
		else if (typeof observer !== "object") {
			throw new Error("Oh no!")
		}

		return new Subscription(observer, this._subscriber);
	}

	[/** @type {any} */ (Symbol).observable]() { return this }

	/**
	 * @template T
	 * @param {Iterable<T>} xs
	 * @return {Observable<T>}
	 */
	static from(xs) {
		if (/** @type {any} */ (xs)[/** @type {any} */ (Symbol).observable])
			throw new Error("TODO")
		return new Observable(fire => {
			for (const x of xs) {
				fire.next(x)
				if (fire.closed) return
			}
			if (fire.complete) fire.complete()
		})
	}

	/**
	 * @template T
	 * @param {ReadonlyArray<T>} xs
	 * @return {Observable<T>}
	 */
	static of(...xs) {
		return this.from(xs)
	}
}
