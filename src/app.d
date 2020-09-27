@safe @nogc nothrow: // not pure

import cli : cli;

extern(C) int main(immutable size_t argc, immutable char** argv) {
	if (false) { debug {
		import core.stdc.stdio : printf;
		import frontend.ast : CallAst, CreateArrAst,
			CreateRecordAst,
			CreateRecordMultiLineAst,
			ExprAst,
			ExprAstKind,
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
		import util.collection.arrBuilder : ArrBuilder;
		import util.result : Result;
		printf("ExprAst: %lu\n", ExprAst.sizeof);
		printf("ExprAstKind: %lu\n", ExprAstKind.sizeof);
		printf("	CallAst: %lu\n", CallAst.sizeof);
		printf("	CreateArrAst: %lu\n", CreateArrAst.sizeof);
		printf("	CreateRecordAst: %lu\n", CreateRecordAst.sizeof);
		printf("	CreateRecordMultiLineAst: %lu\n", CreateRecordMultiLineAst.sizeof);
		printf("	IdentifierAst: %lu\n", IdentifierAst.sizeof);
		printf("	LambdaAst: %lu\n", LambdaAst.sizeof);
		printf("	LetAst: %lu\n", LetAst.sizeof);
		printf("	LiteralAst: %lu\n", LiteralAst.sizeof);
		printf("	LiteralInnerAst: %lu\n", LiteralInnerAst.sizeof);
		printf("	MatchAst: %lu\n", MatchAst.sizeof);
		printf("	RecordFieldSetAst: %lu\n", RecordFieldSetAst.sizeof);
		printf("	SeqAst: %lu\n", SeqAst.sizeof);
		printf("	ThenAst: %lu\n", ThenAst.sizeof);
		printf("	WhenAst: %lu\n", WhenAst.sizeof);

		alias ThisThing = Result!(FileAst, ParseDiagnostic);
		printf("FileAst: %lu\n", FileAst.sizeof);
		printf("ParseDiagnostic: %lu\n", ParseDiagnostic.sizeof);
		printf("ThisThing: %lu\n", ThisThing.sizeof);

		printf("SigAst: %lu\n", SigAst.sizeof);
		printf("TypeAst: %lu\n", TypeAst.sizeof);
		printf("FunDeclAst: %lu\n", FunDeclAst.sizeof);
		printf("FunBodyAst: %lu\n", FunBodyAst.sizeof);

		printf("WhenAst.Case: %lu\n", WhenAst.Case.sizeof);
		return 0;
	} }

	return cli(argc, argv);
}

private:

pure void trustedPrint(int i) {
	import core.stdc.stdio : printf;
	debug {
		printf("%d\n", i);
	}
}
