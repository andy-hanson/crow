import { assert } from "./assert.js"

/** @type {function(uint): float} */
export const toFloat = Number

/** @typedef {bigint} Byte */
export const Byte = {}

/** @typedef {bigint} uint */
export const uint = {}

/** @typedef {bigint} Nat64 */
export const Nat64 = {}

/** @typedef {bigint} int */
export const int = {}

/** @typedef {number} float */
export const float = {}

/** @type {function(boolean): uint} */
export const boolToNat = BigInt

/** @type {function(uint): boolean} */
export const bitToBool = b => {
	assert(b === 0n || b === 1n)
	return b === 1n
}

//TODO:MOVE

/**
 * WARN: Returns 0 for 0
 * @type {function(uint): uint}
 */
export function numberOfBits(n) {
	let res = 0n
	while (n !== 0n) {
		n = n / 2n
		res++
	}
	return res
}

/** @type {function(uint): boolean} */
export const isAllOnes = u =>
	(u & (u + 1n)) === 0n

