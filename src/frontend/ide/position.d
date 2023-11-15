module frontend.ide.position;

@safe @nogc pure nothrow:

import frontend.parse.ast : FieldMutabilityAst, FunModifierAst;
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
	Type,
	TypeParam,
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

immutable struct TypeParamContainer {
	mixin Union!(FunDecl*, SpecDecl*, StructDecl*);
}
alias TypeContainer = TypeParamContainer;

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
	immutable struct TypeWithContainer {
		TypeContainer container;
		Type type;
	}
	immutable struct TypeParamWithContainer {
		TypeParamContainer container;
		TypeParam* typeParam;
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
		SpecInst*,
		SpecSig,
		StructDecl*,
		TypeWithContainer,
		TypeParamWithContainer,
		Visibility);
}
