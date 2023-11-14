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
	immutable struct LocalInFunction {
		FunDecl* containingFun;
		Local* local;
	}
	immutable struct RecordFieldMutability {
		FieldMutabilityAst.Kind kind;
	}
	immutable struct RecordFieldPosition {
		StructDecl* struct_;
		RecordField* field;
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
		LocalInFunction,
		RecordFieldMutability,
		RecordFieldPosition,
		SpecDecl*,
		SpecInst*,
		StructDecl*,
		TypeWithContainer,
		TypeParamWithContainer,
		Visibility);
}
