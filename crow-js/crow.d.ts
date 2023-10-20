declare namespace crow {
	type DiagRange = {start:number, end:number}

	type Diagnostic = {message:string, range:DiagRange}

	type Token = {token:TokenKind, range:DiagRange}

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

	const includeDir: string

	function makeCompiler(bytes: ArrayBuffer): Promise<Compiler>
	interface Compiler {
		addOrChangeFile(path: string, content: string): void
		deleteFile(path: string): void
		getFile(path: string): string
		getTokensAndParseDiagnostics(path: string): TokensAndParseDiagnostics
		getHover(path: string, pos: number): string
		run(path: string): RunOutput
	}
}
