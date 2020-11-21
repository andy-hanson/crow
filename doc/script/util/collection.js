import { assert } from "./assert.js"
import { Byte, uint } from "./types.js"

/**
 * @template K, V
 * @param {Map<K, V>} map
 * @param {K} key
 * @param {() => V} getValue
 */
export const getOrSet = (map, key, getValue) => {
	const got = map.get(key)
	if (got !== undefined)
		return got
	else {
		const value = getValue()
		map.set(key, value)
		return value
	}
}

/**
 * @template K, V
 */
export class AsyncCache {
	//TODO: as an optimization, just store a plain value in the map.
	// But need a way to avoid computing the same value twice in parallel.
	/**
	 * @readonly
	 * @type {Map<K, Promise<V>>}
	 */
	#map = new Map()

	/**
	 * @param {K} key
	 * @param {() => Promise<V>} getValue
	 * @return {Promise<V>}
	 */
	getOrSet(key, getValue) {
		// TODO: should not need a cast
		return /** @type {any} */ (getOrSet(/** @type {any} */ (this.#map), key, /** @type {any} */ (getValue)))
	}
}

/**
 * @param {ArrayLike<unknown>} xs
 * @return {bigint}
 */
export const len = xs => BigInt(xs.length)

/**
 * @param {bigint} n
 * @return {Iterable<bigint>}
 */
export function* rangeUpTo(n) {
	for (let i = 0n; i < n; i++)
		yield i
}

/** @type {function(string, bigint): string} */
export function stringAt(s, index) {
	assert(index < len(s))
	return s[/** @type {any} */ (index)]
}

/**
 * @template T
 * @param {ArrayLike<T>} xs
 * @param {uint} index
 * @return T
 */
export function at(xs, index) {
	assert(index < len(xs))
	return xs[/** @type {any} */ (index)]
}

/** @type {function(Uint8Array, uint): Byte} */
export const byteAt = (xs, index) =>
	BigInt(at(xs, index))

/**
 * @template T
 * @typedef {{ readonly length: number, [n: number]: T }} MutableArrayLike
 */

/**
 * @template T
 * @param {MutableArrayLike<T>} xs
 * @param {uint} index
 * @param {T} value
 * @return {void}
 */
export function setAt(xs, index, value) {
	assert(index < len(xs))
	xs[/** @type {any} */ (index)] = value
}

/** @type {function(Uint8Array, uint, Byte): void} */
export const setByteAt = (xs, index, value) => {
	setAt(xs, index, Number(value))
}

/**
 * @template T
 * @param {boolean} b
 * @param {() => T} cb
 * @return {ReadonlyArray<T>}
 */
export const optionIf = (b, cb) => b ? [cb()] : []

/**
 * @template T
 * @param {T | null} x
 * @return {Iterable<T>}
 */
export const optIter = x => x === null ? [] : [x]

/**
 * @template T
 * @param {Record<string, T>} obj
 * @return {Map<string, T>}
 */
export function objectToMap(obj) {
	const res = new Map()
	for (const key of Object.getOwnPropertyNames(obj))
		res.set(key, obj[key])
	return res
}

/**
 * @param {Iterable<string>} it
 * @param {String} joiner
 */
export function join(it, joiner) {
	let s = ""
	let first = true
	for (const x of it) {
		if (first)
			first = false
		else
			s += joiner
		s += x
	}
	return s
}

/** @type {function(string): string} */
export function reverse(s) {
	let out = ''
	for (let i = s.length - 1; i >= 0; i--)
		out += s[i]
	return out
}
/**
 * @template In, Out
 * @param {Iterable<In>} xs
 * @param {(x: In) => Out} cb
 * @return {Out | null}
 */
export const findAndReturn = (xs, cb) =>
	first(mapNotNull(xs, cb))

/**
 * @template In, Out
 * @param {Iterable<In>} xs
 * @param {(t: In) => Out | null} cb
 * @return {Iterable<Out>}
 */
export const mapNotNull = (xs, cb) =>
	filterNotNull(map(xs, cb))

/**
 * @template T
 * @param {Iterable<T>} xs
 * @param {(t: T) => boolean} cb
 * @return {Iterable<T>}
 */
export function* filter(xs, cb) {
	for (const x of xs)
		if (cb(x))
			yield x
}

/**
 * @template T, U
 * @param {Iterable<T>} xs
 * @param {(t: T) => U} cb
 * @return {Iterable<U>}
 */
export function* map(xs, cb) {
	for (const x of xs)
		yield cb(x)
}

/**
 * @template T, U
 * @param {Iterable<T>} xs
 * @param {(t: T) => Iterable<U>}cb
 * @return {Generator<*, void, ?>}
 */
export function* flatMap(xs, cb) {
	for (const x of xs)
		yield* cb(x)
}

/**
 * @template T
 * @param {Iterable<T>} xs
 * @param {(t: T) => boolean} cb
 * @return {boolean}
 */
export const some = (xs, cb) => {
	for (const x of xs)
		if (cb(x))
			return true
	return false
}

/**
 * WARN: I made the inner iterable a 'ReadonlyArray<T>' or else 'T' is inferred as 'any'
 * @template T
 * @param {Iterable<ReadonlyArray<T>>} xs
 * @return {Iterable<T>}
 */
export const flatten = xs =>
	flatMap(xs, x => x)

/**
 * @template T
 * @param {Iterable<T | null>} xs
 * @return {Iterable<T>}
 */
export const filterNotNull = xs =>
	/** @type {Iterable<T>} */ (filter(xs, x => x !== null))

/**
 * @template T
 * @param {Iterable<T>} xs
 * @return {T | null}
 */
export const first = xs => {
	for (const x of xs)
		return x
	return null
}



//TODO:MOVE
/**
 * @param {Iterable<[string, string]>} pairs
 * @return {ReadonlyMap<string, string>}
 */
export const toMap = pairs =>
	new Map(pairs)

/** @type {function(uint): Iterable<uint>} */
export function* range(n) {
	for (let i = 0n; i < n; i++)
		yield i
}

/**
 * @template T
 * @param {uint} n
 * @param {() => T} cb
 * @return {ReadonlyArray<T>}
 */
export const fillArray = (n, cb) =>
	Array.from(map(range(n), cb))

/**
 * @template K, V
 * @param {Iterable<[K, V]>} pairs
 * @return {Map<K, V>}
 */
export const mapFrom = pairs =>
	new Map(pairs)

/**
 * @template T
 * @param {ReadonlyArray<T>} xs
 * @param {(t: T) => boolean} cb
 * @return {uint | null}
 */
export const findIndex = (xs, cb) => {
	const res = xs.findIndex(cb)
	return res === -1 ? null : BigInt(res)
}

/**
 * @template T
 * @param {Iterable<T>} xs
 * @param {(t: T) => boolean} cb
 * @return {T | null}
 */
export const find = (xs, cb) => {
	for (const x of xs)
		if (cb(x))
			return x
	return null
}

/**
 * @template T
 * @param {Iterable<T>} xs
 * @return {Iterable<[uint, T]>}
 */
export function* enumerate(xs) {
	let i = 0n
	for (const x of xs) {
		yield [i, x]
		i++
	}
}
