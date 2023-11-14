declare namespace crow {
	type Uri = string

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
		uri: Uri
		position: LineAndCharacter
	}

	type UriAndRange = {
		uri: Uri
		range: RangeWithinFile
	}

	type Diagnostic = {
		range: RangeWithinFile
		message: string
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
		uri: Uri
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

	function makeCompiler(bytes: ArrayBuffer, includeDir: Uri, cwd: Uri): Promise<Compiler>
	interface Compiler {
		version(): string
		setFileSuccess(uri: Uri, content: string): void
		setFileIssue(uri: Uri, issue: "notFound" | "unknown" | "loading" | "error"): void
		// For debug/test
		getFile(uri: Uri): string
		searchImportsFromUri(uri: Uri): void
		// All file URIs, whether the file has content or has an issue.
		allStorageUris(): ReadonlyArray<Uri>
		allUnknownUris(): ReadonlyArray<Uri>
		allLoadingUris(): ReadonlyArray<Uri>
		getTokensAndParseDiagnostics(uri: Uri): TokensAndParseDiagnostics
		getAllDiagnostics(): AllDiagnosticsResult
		getDefinition(where: UriLineAndCharacter): ReadonlyArray<UriAndRange>
		getReferences(where: UriLineAndCharacter, roots: ReadonlyArray<Uri>): ReadonlyArray<UriAndRange>
		getHover(where: UriLineAndCharacter): string
		run(uri: Uri): RunOutput
	}
}
