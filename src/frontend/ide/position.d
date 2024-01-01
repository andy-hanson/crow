module frontend.ide.position;

@safe @nogc pure nothrow:

import model.ast : FieldMutabilityAst, FunModifierAst, NameAndRange;
import model.diag : TypeContainer, TypeWithContainer;
import model.model :
	Expr,
	FunDecl,
	ImportOrExport,
	Local,
	Module,
	NameReferents,
	RecordField,
	SpecDecl,
	SpecDeclSig,
	SpecInst,
	StructDecl,
	Test,
	TypeParamIndex,
	VarDecl,
	Visibility;
import util.opt : Opt;
import util.symbol : Symbol;
import util.union_ : Union;
import util.uri : Uri;

immutable struct Position {
	Module* module_;
	PositionKind kind;
}

immutable struct ExprContainer {
	@safe @nogc pure nothrow:

	mixin Union!(FunDecl*, Test*);

	LocalContainer toLocalContainer() =>
		matchWithPointers!LocalContainer(
			(FunDecl* x) =>
				LocalContainer(x),
			(Test* x) =>
				LocalContainer(x));

	TypeContainer toTypeContainer() =>
		toLocalContainer.toTypeContainer;

	Uri moduleUri() =>
		toTypeContainer.moduleUri;
}

immutable struct LocalContainer {
	@safe @nogc pure nothrow:
	mixin Union!(FunDecl*, Test*, SpecDecl*);

	TypeContainer toTypeContainer() =>
		matchWithPointers!TypeContainer(
			(FunDecl* x) =>
				TypeContainer(x),
			(Test* x) =>
				TypeContainer(x),
			(SpecDecl* x) =>
				TypeContainer(x));

	Uri moduleUri() =>
		toTypeContainer.moduleUri;

	NameAndRange[] typeParams() =>
		toTypeContainer.typeParams;
}

immutable struct VisibilityContainer {
	@safe @nogc pure nothrow:

	mixin Union!(FunDecl*, RecordField*, SpecDecl*, StructDecl*, VarDecl*);

	Symbol name() scope =>
		matchIn!Symbol(
			(in FunDecl x) => x.name,
			(in RecordField x) => x.name,
			(in SpecDecl x) => x.name,
			(in StructDecl x) => x.name,
			(in VarDecl x) => x.name);

	Visibility visibility() scope =>
		matchIn!Visibility(
			(in FunDecl x) => x.visibility,
			(in RecordField x) => x.visibility,
			(in SpecDecl x) => x.visibility,
			(in StructDecl x) => x.visibility,
			(in VarDecl x) => x.visibility);
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
	immutable struct Expression {
		ExprContainer container;
		Expr* expr;
	}
	immutable struct ImportedModule {
		@safe @nogc pure nothrow:
		ImportOrExport* import_;

		Module* modulePtr() =>
			import_.modulePtr;
		ref Module module_() scope =>
			import_.module_;
	}
	immutable struct ImportedName {
		Module* exportingModule;
		Symbol name;
		Opt!(NameReferents*) referents;
	}
	immutable struct Keyword {
		enum Kind {
			builtin,
			enum_,
			extern_,
			flags,
			global,
			localMut,
			record,
			spec,
			threadLocal,
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
	immutable struct VisibilityMark {
		VisibilityContainer container;
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
		Test*,
		TypeWithContainer,
		TypeParamWithContainer,
		VarDecl*,
		VisibilityMark);
}
