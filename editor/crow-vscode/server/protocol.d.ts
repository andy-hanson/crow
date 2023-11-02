declare namespace crowProtocol {
	// For "custom/readFileResult"
	type ReadFileResult = {
		uri: string
		type: "notFound" | "error"
	}

	type UnknownUris = {
		unknownUris: ReadonlyArray<string>
	}
}
