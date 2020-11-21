import { assert } from "./assert.js"
import { getOrSet } from "./collection.js"

export const lateinit = /** @type {never} */ (null)

/**
 * @param {() => Promise<void>}cb
 * @return {void}
 */
export function launch(cb) {
	cb().catch(console.error)
}

/**
 * @template T
 * @param {unknown} x
 * @param {new() => T} t
 * @return {T}
 */
export function safeCast(x, t) {
	assert(x instanceof t)
	return /** @type {T} */ (x)
}

/**
 * @template T
 * @param {T | undefined} t
 * @return {T | null}
 */
export const undefinedToNull = t =>
	t === undefined ? null : t

/**
 * @template K, V
 * @param  {(k: K) => V} fn
 * @return {(k: K) => V}
 */
export const memoize1 = (fn) => {
	/** @type {Map<K, V>} */
	const map = new Map()
	// TODO: should not need a cast
	return k => getOrSet(/** @type {any} */ (map), k, () => fn(k))
}

/**
 * @template T
 * @param {T} a
 * @param {T} b
 * @return {T}
 */
export function combineObjects(a, b) {
	/** @type {any} */
	const out = {}
	for (const key of Object.getOwnPropertyNames(a))
		out[key] = /** @type {any} */ (a)[key]
	for (const key of Object.getOwnPropertyNames(b)) {
		assert(!Object.prototype.hasOwnProperty.call(out, key))
		out[key] = /** @type {any} */ (b)[key]
	}
	return out
}

/**
 * @template V
 * @param {Record<string, V>} obj
 * @return {Iterable<[string, V]>}
 */
export const entries = Object.entries

/**
 * @template V
 * @param {Record<string, V>} obj
 * @return {Iterable<V>}
 */
export const values = Object.values

/**
 * @template T
 * @param {T | null} t
 * @param {() => T} cb
 */
export const optionOr = (t, cb) =>
	t === null ? cb() : t

/**
 * @template T, U
 * @param {T | null} op
 * @param {(t: T) => U} cb
 * @return {U | null}
 */
export const mapOption = (op, cb) =>
	op === null ? null : cb(op)
