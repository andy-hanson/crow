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

immutable struct PositionKind {
	immutable struct None {}

	immutable struct FunExtern {
		FunDecl* funDecl;
	}
	immutable struct FunSpecialModifier {
		FunDecl* funDecl;
		FunModifierAst.Special.Flags flag;
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
	immutable struct LocalNonParameter {
		Local* local;
	}
	immutable struct LocalParameter {
		Local* local;
	}
	immutable struct RecordFieldMutability {
		FieldMutabilityAst.Kind kind;
	}
	immutable struct RecordFieldPosition {
		StructDecl* struct_;
		RecordField* field;
	}

	mixin Union!(
		None,
		Expr,
		FunDecl*,
		FunExtern,
		FunSpecialModifier,
		ImportedModule,
		ImportedName,
		Keyword,
		LocalNonParameter,
		LocalParameter,
		RecordFieldMutability,
		RecordFieldPosition,
		SpecDecl*,
		SpecInst*,
		StructDecl*,
		Type,
		TypeParam*,
		Visibility);
}
