@safe @nogc nothrow: // not pure

import cli : cli;

import core.stdc.stdio : printf;
import frontend.ast :
	CallAst,
	CreateArrAst,
	ExprAst,
	ExprAstKind,
	IdentifierAst,
	LambdaAst,
	LetAst,
	LiteralAst,
	LiteralInnerAst,
	MatchAst,
	SeqAst,
	ThenAst,
	FileAst,
	SigAst,
	StructDeclAst,
	TypeAst,
	WhenAst,
	FunDeclAst,
	FunBodyAst;
import model.parseDiag : ParseDiagnostic;
import util.result : Result;

extern(C) int main(immutable size_t argc, immutable char** argv) {
	if (false) { debug {
		printf("ExprAst: %lu\n", ExprAst.sizeof);
		printf("ExprAstKind: %lu\n", ExprAstKind.sizeof);
		printf("	CallAst: %lu\n", CallAst.sizeof);
		printf("	CreateArrAst: %lu\n", CreateArrAst.sizeof);
		printf("	IdentifierAst: %lu\n", IdentifierAst.sizeof);
		printf("	LambdaAst: %lu\n", LambdaAst.sizeof);
		printf("	LetAst: %lu\n", LetAst.sizeof);
		printf("	LiteralAst: %lu\n", LiteralAst.sizeof);
		printf("	LiteralInnerAst: %lu\n", LiteralInnerAst.sizeof);
		printf("	MatchAst: %lu\n", MatchAst.sizeof);
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
		printf("StructDeclAst: %lu\n", StructDeclAst.sizeof);
		printf("StructDeclAst.Body: %lu\n", StructDeclAst.Body.sizeof);
		printf("StructDeclAst.Body.Record.Field: %lu\n", StructDeclAst.Body.Record.Field.sizeof);

		printf("WhenAst.Case: %lu\n", WhenAst.Case.sizeof);
		return 0;
	} }

	return cli(argc, argv);
}
