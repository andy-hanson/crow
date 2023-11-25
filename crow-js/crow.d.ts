declare namespace crow {
	type Uri = string

	type LineAndCharacter = {
		// 0-indexed
		line: number
		character: number
	}

	type Range = {
		start: LineAndCharacter
		end: LineAndCharacter
	}

	type UriLineAndCharacter = {
		uri: Uri
		position: LineAndCharacter
	}

	type UriAndRange = {
		uri: Uri
		range: Range
	}

	// Error = 1, Warning = 2, Information = 3, Hint = 4
	type DiagnosticSeverity = 1 | 2 | 3 | 4

	type Diagnostic = {
		range: Range
		severity: DiagnosticSeverity
		message: string
	}

	type Token = {
		token: TokenKind
		range: Range
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

	namespace Write {
		type Pipe = "stdout" | "stderr"
	}
	type Write = {pipe:Write.Pipe, text:string}

	type RunOutput = {exitCode:number, writes:ReadonlyArray<Write>}

	type ChangeEvent = {
		range?: Range
		text: string
	}

	type Logger = (arg0: string, arg1?: unknown) => void

	// For "custom/readFileResult"
	type ReadFileResult = {
		uri: string
		type: "notFound" | "error"
	}

	type UnknownUris = {
		unknownUris: ReadonlyArray<string>
	}

	function makeCompiler(bytes: ArrayBuffer, includeDir: Uri, cwd: Uri, logger: Logger): Promise<Compiler>
	interface Compiler {
		version(): string
		getTokens(uri: Uri): ReadonlyArray<Token>
		handleLspMessage(inputMessage: any): {messages:any[], exitCode?:number}
		run(uri: Uri): RunOutput
	}
}
