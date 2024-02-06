module frontend.ide.position;

@safe @nogc pure nothrow:

import model.ast : ModifierKeyword, NameAndRange;
import model.diag : TypeContainer, TypeWithContainer;
import model.model :
	EnumMember,
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
	StructAlias,
	StructDecl,
	Test,
	TypeParamIndex,
	UnionMember,
	VarDecl,
	Visibility;
import util.opt : Opt;
import util.symbol : Symbol;
import util.union_ : TaggedUnion, Union;
import util.uri : Uri;

immutable struct Position {
	Module* module_;
	PositionKind kind;
}

immutable struct ExprContainer {
	@safe @nogc pure nothrow:

	mixin TaggedUnion!(FunDecl*, Test*);

	LocalContainer toLocalContainer() return scope =>
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
	mixin TaggedUnion!(FunDecl*, Test*, SpecDecl*);

	TypeContainer toTypeContainer() return scope =>
		matchWithPointers!TypeContainer(
			(FunDecl* x) =>
				TypeContainer(x),
			(Test* x) =>
				TypeContainer(x),
			(SpecDecl* x) =>
				TypeContainer(x));

	Uri moduleUri() scope =>
		toTypeContainer.moduleUri;

	NameAndRange[] typeParams() =>
		toTypeContainer.typeParams;
}

immutable struct VisibilityContainer {
	@safe @nogc pure nothrow:

	mixin TaggedUnion!(FunDecl*, RecordField*, SpecDecl*, StructAlias*, StructDecl*, VarDecl*);

	Symbol name() scope =>
		matchIn!Symbol(
			(in FunDecl x) => x.name,
			(in RecordField x) => x.name,
			(in SpecDecl x) => x.name,
			(in StructAlias x) => x.name,
			(in StructDecl x) => x.name,
			(in VarDecl x) => x.name);

	Visibility visibility() scope =>
		matchIn!Visibility(
			(in FunDecl x) => x.visibility,
			(in RecordField x) => x.visibility,
			(in SpecDecl x) => x.visibility,
			(in StructAlias x) => x.visibility,
			(in StructDecl x) => x.visibility,
			(in VarDecl x) => x.visibility);
}

immutable struct PositionKind {
	immutable struct None {}

	immutable struct EnumOrFlagsMemberPosition {
		StructDecl* struct_;
		EnumMember* member;
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
	// non-Modifier
	immutable struct Keyword {
		enum Kind {
			alias_,
			builtin,
			enum_,
			extern_,
			flags,
			global,
			localMut,
			record,
			spec,
			threadLocal,
			underscore,
			union_,
		}
		Kind kind;
	}
	immutable struct LocalPosition {
		LocalContainer container;
		Local* local;
	}
	immutable struct MatchEnumCase {
		EnumMember* member;
	}
	immutable struct MatchUnionCase {
		UnionMember* member;
	}
	immutable struct Modifier {
		TypeContainer container;
		ModifierKeyword modifier;
	}
	immutable struct ModifierExtern {
		Symbol libraryName;
	}
	immutable struct RecordFieldMutability {
		Opt!Visibility visibility;
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
	immutable struct UnionMemberPosition {
		StructDecl* struct_;
		UnionMember* member;
	}
	immutable struct VisibilityMark {
		VisibilityContainer container;
	}

	mixin Union!(
		None,
		EnumOrFlagsMemberPosition,
		Expression,
		FunDecl*,
		ImportedModule,
		ImportedName,
		Keyword,
		LocalPosition,
		MatchEnumCase,
		MatchUnionCase,
		Modifier,
		ModifierExtern,
		RecordFieldMutability,
		RecordFieldPosition,
		SpecDecl*,
		SpecSig,
		SpecUse,
		StructAlias*,
		StructDecl*,
		Test*,
		TypeWithContainer,
		TypeParamWithContainer,
		UnionMemberPosition,
		VarDecl*,
		VisibilityMark);
}
