@safe @nogc nothrow: // not pure

import cli : cli;

extern(C) int main(immutable size_t argc, immutable char** argv) {
	if (false) { debug {
		import core.stdc.stdio : printf;
		import frontend.ast : CallAst, CreateArrAst,
			CreateRecordAst,
			CreateRecordMultiLineAst,
			IdentifierAst,
			LambdaAst,
			LetAst,
			LiteralAst,
			LiteralInnerAst,
			MatchAst,
			SeqAst,
			RecordFieldSetAst,
			ThenAst,
			ExprAstKind,
			FileAst,
			SigAst,
			TypeAst,
			WhenAst,
			FunDeclAst,
			FunBodyAst;
		import parseDiag : ParseDiagnostic;
		import util.result : Result;
		printf("Call: %lu\n", CallAst.sizeof);
		printf("When: %lu\n", WhenAst.sizeof);
		printf("CreateArr: %lu\n", CreateArrAst.sizeof);
		printf("CreateRecord: %lu\n", CreateRecordAst.sizeof);
		printf("CreateRecordMultiLine: %lu\n", CreateRecordMultiLineAst.sizeof);
		printf("Identifier: %lu\n", IdentifierAst.sizeof);
		printf("Lambda: %lu\n", LambdaAst.sizeof);
		printf("Let: %lu\n", LetAst.sizeof);
		printf("Literal: %lu\n", LiteralAst.sizeof);
		printf("LiteralInner: %lu\n", LiteralInnerAst.sizeof);
		printf("Match: %lu\n", MatchAst.sizeof);
		printf("Seq: %lu\n", SeqAst.sizeof);
		printf("RecordFieldSet: %lu\n", RecordFieldSetAst.sizeof);
		printf("Then: %lu\n", ThenAst.sizeof);


		alias ThisThing = Result!(FileAst, ParseDiagnostic);
		printf("FileAst: %lu\n", FileAst.sizeof);
		printf("ParseDiagnostic: %lu\n", ParseDiagnostic.sizeof);
		printf("ThisThing: %lu\n", ThisThing.sizeof);

		printf("SigAst: %lu\n", SigAst.sizeof);
		printf("TypeAst: %lu\n", TypeAst.sizeof);
		printf("FunDeclAst: %lu\n", FunDeclAst.sizeof);
		printf("FunBodyAst: %lu\n", FunBodyAst.sizeof);
		return 0;
	} }

	return cli(argc, argv);
}
