import {assert, assertBoolean} from "./assert.js"
import {len} from "./collection.js"
import {Duration, sleep} from "./Duration.js"
import {NonOptionalObserver, Observable, Observer, Subscription} from "./Observable.js"
import {ObservableValue} from "./ObservableValue.js"
import {int} from "./types.js"
import {launch} from "./util.js"

/**
 * @template T
 * @typedef FireableObservable
 * @property {NonOptionalObserver<T>} fire
 * @property {Observable<T>} observable
 */
export const FireableObservable = {}

/**
 * @template T
 * @typedef FireableObservableValue
 * @property {NonOptionalObserver<T>} fire
 * @property {ObservableValue<T>} observable
 */
export const FireableObservableValue = {}

/**
 * @template T
 * @param {T} initial
 * @return {FireableObservableValue<T>}
 */
export function createFireableObservableValue(initial) {
	/** @type {FireableObservable<T>} */
	const { fire, observable } = createFireableObservable()
	return { fire, observable: ObservableValue.fromObservable(initial, observable) }
}

/**
 * @template T
 * @return {FireableObservable<T>}
 */
export function createFireableObservable() {
	/** @type {Array<Observer<T>>} */
	const observers = []
	const observable = new Observable(observer => {
		observers.push(observer)
	})
	/** @type {NonOptionalObserver<T>} */
	const fire = {
		start: (subscriber) => {
			for (const o of observers) if (o.start) o.start(subscriber)
		},
		next: v => {
			for (const o of observers) o.next(v)
		},
		error: e => {
			for (const o of observers) if (o.error) o.error(e)
		},
		complete: () => {
			for (const o of observers) if (o.complete) o.complete()
		},
	}
	return {fire, observable}
}

/**
 * @template T
 * @param {Iterable<Observable<T>>} observables
 * @return {Observable<T>}
 */
export const anyObservable = observables =>
	new Observable(fire => {
		for (const obs of observables)
			obs.subscribe(fire)
	})

/**
 * Won't fire any more events for <duration> after an event has fired.
 *
 * @template T
 * @param {Observable<T>} obs
 * @param {Duration} duration
 * @return {Observable<T>}
 */
export function debounce(obs, duration) {
	let last = 0
	return filterObservable(obs, x => {
		const now = Date.now()
		if (now - last >= duration.msec) {
			last = now
			return true
		} else
			return false
	})
}

/**
 * @template T
 * @param {Observable<T>} obs
 * @param {Duration} delayAmount
 * @return {Observable<T>}
 */
export const delay = (obs, delayAmount) =>
	mapObservableAsync(obs, async x => {
		await sleep(delayAmount)
		return x
	})

//TODO:TEST
/**
 * @template T
 * @param {ObservableValue<T>} obs
 * @param {Duration} delayAmount
 * @return {ObservableValue<T>}
 */
export const delayObservableValue = (obs, delayAmount) =>
	ObservableValue.fromObservable(obs.current, delay(obs.observable, delayAmount))

/**
 * @template T
 * @param {Observable<T>} obs
 * @param {NonOptionalObserver<T>} fire
 * @return {void}
 */
export const pipe = (obs, fire) => {
	obs.subscribe(fire)
}

/**
 * @template T, U
 * @param {Observable<T>} obs
 * @param {(t: T) => U} cb
 * @return {Observable<U>}
 */
export const mapObservable = (obs, cb) =>
	mapObservableAsync(obs,async v => cb(v))

/**
 * @template T
 * @param {Observable<T>} obs
 * @param {(t: T) => boolean} cb
 * @return {Observable<T>}
 */
export const filterObservable = (obs, cb) =>
	filterObservableAsync(obs, async x => cb(x))

/**
 * @template T
 * @param {Observable<T>} obs
 * @param {(t: T) => Promise<boolean>} cb
 * @return {Observable<T>}
 */
export const filterObservableAsync = (obs, cb) =>
	flatMapObservableAsync(obs, async x =>
		assertBoolean(await cb(x)) ? [x] : [])

/**
 * @template T, U
 * @param {Observable<T>} obs
 * @param {(t: T) => Promise<U>} cb
 * @return {Observable<U>}
 */
export const mapObservableAsync = (obs, cb) =>
	flatMapObservableAsync(obs, async x => [await cb(x)])

/**
 * @template T, U
 * @param {Observable<T>} obs
 * @param {(t: T) => Promise<Iterable<U>>} cb
 * @return {Observable<U>}
 */
export const flatMapObservableAsync = (obs, cb) =>
	new Observable(fire => {
		let inputCompleted = false
		let incomplete = 0n
		obs.subscribe({
			//TODO: fishy cast
			start: v => { if (fire.start) fire.start(/** @type {any} */ (v)) },
			next: v => {
				incomplete += 1n
				cb(v).
					then(xs => {
						for (const x of xs)
							fire.next(x)
					}).
					catch(fire.error).
					then(() => {
						incomplete -= 1n
						if (incomplete === 0n && inputCompleted && fire.complete) fire.complete()
					})
			},
			//TODO: this drops errors!
			error: v => { if (fire.error) fire.error(v) },
			complete: () => {
				// input may be complete, but this isn't complete until all promises are complete
				inputCompleted = true
				if (incomplete === 0n && fire.complete) fire.complete()
			},
		})
	})

/**
 * Not just the composition of delay and debounce.
 * If user is still typing, don't bother performing updates.
 *
 * @template T
 * @param {Observable<T>} obs
 * @param {Duration} duration
 * @return {Observable<T>}
 */
export function waitForLull(obs, duration) {
	let last = Date.now()
	return filterObservableAsync(obs, async _ => {
		const now = Date.now()
		last = now
		// Note: filtering happens in parallel. So other events can change 'last' while we sleep.
		await sleep(duration)
		return last === now
	})
}

/**
 * @template T
 * @param {Observable<T>} obs
 * @param {(t: T) => Promise<void>} cb
 */
export function subscribeAsync(obs, cb) {
	obs.subscribe(v => {
		launch(() => cb(v))
	})
}

/**
 * @template T
 * @param {Observable<T>} obs
 * @param {int} n
 * @return {Promise<ReadonlyArray<T>>}
 */
export function take(obs, n) {
	/** @type {Array<T>} */
	const values = []
	return new Promise((resolve, reject) => {
		//TODO: test error case
		//TODO: test 'complete' case
		/** @type {Subscription<T>} */
		let subscription
		obs.subscribe({
			start: s => { subscription = s },
			next: v => {
				values.push(v)
				assert(len(values) <= n)
				if (len(values) === n) {
					subscription.unsubscribe()
					resolve(values)
				}
			},
			error: reject,
			complete: () => {
				resolve(values)
			},
		})
	})
}

/**
 * @template T
 * @param {Observable<T>} obs
 * @return {Promise<ReadonlyArray<T>>}
 */
export function takeUntilComplete(obs) {
	/** @type {Array<T>} */
	const values = []
	return new Promise((resolve, reject) => {
		obs.subscribe({
			next: v => {
				values.push(v)
			},
			error: reject,
			complete: () => {
				resolve(values)
			},
		})
	})
}

//TODO:TEST
/**
 * @template T
 * @return {Observable<T>}
 */
export const neverObservable = () => new Observable(() => {})

/**
 * @template T
 * @param {T} value
 * @return {ObservableValue<T>}
 */
export const constantObservableValue = value => ObservableValue.fromObservable(value, neverObservable())
