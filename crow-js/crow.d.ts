declare namespace crow {
	type RangeWithinFile = {
		start: number
		end: number
	}

	type UriAndPosition = {
		uri: string
		position: number
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
		definition: UriAndRange | null
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
		addOrChangeFile(uri: string, content: string): void
		deleteFile(uri: string): void
		// For debug/test
		getFile(uri: string): string
		allUnknownUris(): ReadonlyArray<string>
		getTokensAndParseDiagnostics(uri: string): TokensAndParseDiagnostics
		getAllDiagnostics(): AllDiagnosticsResult
		getDefinition(where: UriAndPosition): Definition
		getHover(where: UriAndPosition): string
		run(uri: string): RunOutput
	}
}
