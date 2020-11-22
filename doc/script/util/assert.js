import { uint } from "./types.js"

/** @type {function(boolean, () => string): void} */
export function assert(b, msg = () => "Assertion failed") {
	if (!b)
		throw new Error(msg())
}

/** @type {function(never): never} */
export const assertNever = n =>
	raise(`Should never get a value here, but got: ${JSON.stringify(n)}`)

/** @return {never} */
export const assertUnreachable = () => raise("Unreachable")

/** @type {<T>(t: T | null | undefined) => T} */
export const nonNull = t =>
	t != null ? t : raise("Should be non-null")

/** @type {function(unknown): string} */
export const assertNonEmptyString = s =>
	typeof s === "string" && s.length !== 0 ? s : raise("Expected a non-empty string, got: " + JSON.stringify(s))

/** @type {function(unknown): boolean} */
export const assertBoolean = b =>
	typeof b === "boolean" ? b : raise("Expected a boolean, got: " + JSON.stringify(b))

/** @type {function(unknown): string} */
export const assertString = s =>
	typeof s === "string" ? s : raise("Expected a string, got: " + JSON.stringify(s))

/** @type {function(Error | string): never} */
export const raise = message => {
	throw message instanceof Error ? message : new Error(message)
}
