declare namespace crow {
	type LineAndCharacter = {
		// 0-indexed
		line: number
		character: number
	}

	type RangeWithinFile = {
		start: LineAndCharacter
		end: LineAndCharacter
	}

	type UriLineAndCharacter = {
		uri: string
		position: LineAndCharacter
	}

	type UriAndRange = {
		uri: string
		range: RangeWithinFile
	}

	type Diagnostic = {
		range: RangeWithinFile
		message: string
	}

	type Definition = {
		definition: UriAndRange | undefined
	}

	type Token = {
		token: TokenKind
		range: RangeWithinFile
	}

	type TokenKind =
		| "fun"
		| "identifier"
		| "import"
		| "keyword"
		| "lit-num"
		| "lit-str"
		| "local"
		| "member"
		| "modifier"
		| "param"
		| "spec"
		| "struct"
		| "type-param"
		| "var-decl"

	type TokensAndParseDiagnostics = {
		tokens: ReadonlyArray<Token>
		parseDiagnostics: ReadonlyArray<Diagnostic>
	}

	type UriAndDiagnostics = {
		uri: string
		diagnostics: ReadonlyArray<Diagnostic>
	}

	type AllDiagnosticsResult = {
		diagnostics: ReadonlyArray<UriAndDiagnostics>
	}

	namespace Write {
		type Pipe = "stdout" | "stderr"
	}
	type Write = {pipe:Write.Pipe, text:string}

	type RunOutput = {exitCode:number, writes:ReadonlyArray<Write>}

	function makeCompiler(bytes: ArrayBuffer, includeDir: string, cwd: string): Promise<Compiler>
	interface Compiler {
		version(): string
		setFileSuccess(uri: string, content: string): void
		setFileIssue(uri: string, issue: "notFound" | "unknown" | "loading" | "error"): void
		// For debug/test
		getFile(uri: string): string
		searchImportsFromUri(uri: string): void
		// All file URIs, whether the file has content or has an issue.
		allStorageUris(): ReadonlyArray<string>
		allUnknownUris(): ReadonlyArray<string>
		allLoadingUris(): ReadonlyArray<string>
		getTokensAndParseDiagnostics(uri: string): TokensAndParseDiagnostics
		getAllDiagnostics(): AllDiagnosticsResult
		getDefinition(where: UriLineAndCharacter): Definition
		getReferences(where: UriLineAndCharacter): ReadonlyArray<UriAndRange>
		getHover(where: UriLineAndCharacter): string
		run(uri: string): RunOutput
	}
}
