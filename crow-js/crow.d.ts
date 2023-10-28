declare namespace crow {
	type DiagRange = {
		start: number
		end: number
	}

	type Diagnostic = {
		message: string
		range: DiagRange
	}

	type UriAndRange = {
		uri: string
		range: DiagRange
	}

	type Definition = {
		definition: UriAndRange | null
	}

	type Token = {
		token: TokenKind
		range: DiagRange
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
		getTokensAndParseDiagnostics(uri: string): TokensAndParseDiagnostics
		getDefinition(uri: string, pos: number): Definition
		getHover(uri: string, pos: number): string
		run(uri: string): RunOutput
	}
}
