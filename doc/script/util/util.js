import { assert } from "./assert.js"

export const lateinit = /** @type {never} */ (null)

/**
 * @param {() => Promise<void>}cb
 * @return {void}
 */
export const launch = cb => {
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
 * @template V
 * @param {Record<string, V>} obj
 * @return {Iterable<[string, V]>}
 */
export const entries = Object.entries

/**
 * @template T
 * @param {T | null | undefined} x
 * @return {T}
 */
export const nonNull = x => {
	if (x == null)
		throw new Error("Null value")
	return x
}
