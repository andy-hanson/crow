import { assert } from "./assert.js"
import {Observable, Observer} from "./Observable.js"
import {
	createFireableObservable,
	filterObservable,
	FireableObservable,
	mapObservable, neverObservable,
} from "./observableUtils.js"
import { lateinit } from "./util.js"

/** @template T */
export class ObservableValue {
	current_ = /** @type {T} */ (lateinit)
	observable_ = /** @type {Observable<T>} */ (lateinit)

	/**
	 * @template T
	 * @param {T} current
	 * @param {Observable<T>} observable
	 * @return {ObservableValue<T>}
	 */
	static fromObservable(current, observable) {
		return new ObservableValue(current, observable)
	}

	/**
	 * @private
	 * @param {T} current
	 * @param {Observable<T>} observable
	 */
	constructor(current, observable) {
		this.current_ = current
		this.observable_ = observable
		observable.subscribe(v => {
			this.current_ = v
		})
	}

	get current() { return this.current_ }
	get observable() { return this.observable_ }

	/** @param {(t: T) => void} cb */
	nowAndOnChange(cb) {
		cb(this.current)
		this.subscribe(cb)
	}

	/** @param {((t: T) => void) | Observer<T>} cb */
	subscribe(cb) {
		this.observable.subscribe(cb)
	}
}

/**
 * @template T, U
 * @param {ObservableValue<T>} obs
 * @param {(t: T) => U} cb
 * @return {ObservableValue<U>}
 */
export const mapObservableValue = ({ current, observable }, cb) =>
	ObservableValue.fromObservable(cb(current), mapObservable(observable, cb))

/**
 * An ObservableValue that only changes to valid values.
 * WARN: The initial state must be valid.
 *
 * @template T
 * @param {ObservableValue<T>} obs
 * @param {(t: T) => boolean} isValid
 * @return {ObservableValue<T>}
 */
export function validateObservableValue({ current, observable }, isValid) {
	assert(isValid(current), () => `Initial value of ${current} is invalid`)
	return ObservableValue.fromObservable(current, filterObservable(observable, isValid))
}

/**
 * @template T, U
 * @param {ObservableValue<T>} a
 * @param {ObservableValue<U>} b
 * @return {ObservableValue<[T, U]>}
 */
export function combineObservableValues(a, b) {
	/** @type {Observable<[T, U]>} */
	const observable = new Observable(fire => {
		a.subscribe({
			//TODO: fishy cast
			start: v => { if (fire.start) fire.start(/** @type {any} */ (v)) },
			next: v => {
				fire.next([v, res.current[1]])
			},
			error: v => { if (fire.error) fire.error(v) },
			complete: () => { throw new Error("TODO") },
		})
		b.subscribe({
			//TODO: fishy cast
			start: v => { if (fire.start) fire.start(/** @type {any} */ (v)) },
			next: v => {
				fire.next([res.current[0], v])
			},
			error: v => { if (fire.error) fire.error(v) },
			complete: () => { throw new Error("TODO") },
		})
	})
	/** @type {ObservableValue<[T, U]>} */
	const res = ObservableValue.fromObservable([a.current, b.current], observable)
	return res
}

/**
 * @template T, U, V
 * @param {ObservableValue<T>} a
 * @param {ObservableValue<U>} b
 * @param {function(T, U): V} cb
 * @return {ObservableValue<V>}
 */
export const combineObservableValuesWith = (a, b, cb) =>
	mapObservableValue(combineObservableValues(a, b), ([x, y]) => cb(x, y))

/**
 * @template T
 * @param {() => T} getter
 * @param {Observable<void>} onChange
 */
export function observableValueFromGetterAndOnChange(getter, onChange) {
	return ObservableValue.fromObservable(getter(), mapObservable(onChange, getter))
}

/** @template T */
export class ObservableArray {
	/** @type {Array<ObservableValue<T>>} */
	array_ = []
	fireableObservable_ = /** @type {FireableObservable<ReadonlyArray<T>>} */ (lateinit)
	observableValue_ = /** @type {ObservableValue<ReadonlyArray<T>>} */ (lateinit)

	constructor() {
		this.fireableObservable_ = createFireableObservable()
		this.observableValue_ = ObservableValue.fromObservable(
			/** @type {ReadonlyArray<T>} */ ([]),
			this.fireableObservable_.observable)
	}

	/**
	 * @param {ObservableValue<T>} obs
	 * @return {void}
	 */
	push(obs) {
		this.array_.push(obs)
		//TODO: also subscribe to errors!
		obs.subscribe(() => {
			this.fireableObservable_.fire.next(this.getCurrent())
		})
		this.fireableObservable_.fire.next(this.getCurrent())
	}

	/**
	 * @private
	 * @return {ReadonlyArray<T>}
	 */
	getCurrent() {
		return this.array_.map(x => x.current)
	}

	/** @return {ObservableValue<ReadonlyArray<T>>} */
	get observable() { return this.observableValue_ }
}
