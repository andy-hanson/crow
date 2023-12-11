module frontend.ide.position;

@safe @nogc pure nothrow:

import frontend.parse.ast : FieldMutabilityAst, FunModifierAst, NameAndRange;
import model.diag : TypeContainer, typeParamAsts, TypeWithContainer;
import model.model :
	Expr,
	FunDecl,
	ImportOrExport,
	Local,
	Module,
	RecordField,
	SpecDecl,
	SpecDeclSig,
	SpecInst,
	StructDecl,
	TypeParamIndex,
	VarDecl,
	Visibility;
import util.sym : Sym;
import util.union_ : Union;

immutable struct Position {
	Module* module_;
	PositionKind kind;
}

immutable struct LocalContainer {
	@safe @nogc pure nothrow:
	mixin Union!(FunDecl*, SpecDecl*);

	TypeContainer toTypeContainer() =>
		matchWithPointers!TypeContainer(
			(FunDecl* x) =>
				TypeContainer(x),
			(SpecDecl* x) =>
				TypeContainer(x));
}
NameAndRange[] typeParamAsts(LocalContainer a) =>
	.typeParamAsts(a.toTypeContainer);

immutable struct PositionKind {
	immutable struct None {}

	immutable struct FunExtern {
		FunDecl* funDecl;
	}
	immutable struct FunSpecialModifier {
		FunDecl* funDecl;
		FunModifierAst.Special.Flags flag;
	}
	immutable struct Expression {
		FunDecl* containingFun;
		Expr* expr;
	}
	immutable struct ImportedModule {
		ImportOrExport* import_;
		Module* module_;
	}
	immutable struct ImportedName {
		ImportOrExport* import_;
		Sym name;
	}
	immutable struct Keyword {
		enum Kind {
			builtin,
			enum_,
			extern_,
			flags,
			localMut,
			record,
			union_,
		}
		Kind kind;
	}
	immutable struct LocalPosition {
		LocalContainer container;
		Local* local;
	}
	immutable struct RecordFieldMutability {
		FieldMutabilityAst.Kind kind;
	}
	immutable struct RecordFieldPosition {
		StructDecl* struct_;
		RecordField* field;
	}
	immutable struct SpecSig {
		SpecDecl* spec;
		SpecDeclSig* sig;
	}
	immutable struct SpecUse {
		TypeContainer container;
		SpecInst* spec;
	}
	immutable struct TypeParamWithContainer {
		TypeParamIndex typeParam;
		TypeContainer container;
	}

	mixin Union!(
		None,
		Expression,
		FunDecl*,
		FunExtern,
		FunSpecialModifier,
		ImportedModule,
		ImportedName,
		Keyword,
		LocalPosition,
		RecordFieldMutability,
		RecordFieldPosition,
		SpecDecl*,
		SpecSig,
		SpecUse,
		StructDecl*,
		TypeWithContainer,
		TypeParamWithContainer,
		VarDecl*,
		Visibility);
}
