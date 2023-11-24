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

	type UriAndDiagnostics = {
		uri: Uri
		diagnostics: Diagnostic[]
	}

	type AllDiagnosticsResult = {
		diagnostics: UriAndDiagnostics[]
	}

	namespace Write {
		type Pipe = "stdout" | "stderr"
	}
	type Write = {pipe:Write.Pipe, text:string}

	type RunOutput = {exitCode:number, writes:ReadonlyArray<Write>}

	type TextEdit = {
		range: Range
		newText: string
	}

	type Rename = {
		changes: { [uri: Uri]: TextEdit[] }
	}

	type ChangeEvent = {
		range?: Range
		text: string
	}

	type Logger = (arg0: string, arg1?: unknown) => void

	function makeCompiler(bytes: ArrayBuffer, includeDir: Uri, cwd: Uri, logger: Logger): Promise<Compiler>
	interface Compiler {
		version(): string
		setFileSuccess(uri: Uri, content: string): void
		setFileIssue(uri: Uri, issue: "notFound" | "unknown" | "loading" | "error"): void
		changeFile(uri: Uri, changes: ReadonlyArray<ChangeEvent>): void
		// For debug/test
		getFile(uri: Uri): string
		searchImportsFromUri(uri: Uri): void
		// All file URIs, whether the file has content or has an issue.
		allStorageUris(): ReadonlyArray<Uri>
		allUnknownUris(): ReadonlyArray<Uri>
		allLoadingUris(): ReadonlyArray<Uri>
		getTokens(uri: Uri): ReadonlyArray<Token>
		getAllDiagnostics(): ReadonlyArray<UriAndDiagnostics>
		getDiagnosticsForUri(uri: Uri, minSeverity?: number): ReadonlyArray<Diagnostic>
		getReferences(where: UriLineAndCharacter): UriAndRange[]
		getRename(where: UriLineAndCharacter, newName: string): Rename | null
		handleLspMessage(kind: string, params: any): any
		run(uri: Uri): RunOutput
	}
}
