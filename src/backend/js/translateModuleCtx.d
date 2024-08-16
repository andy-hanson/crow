module backend.js.translateModuleCtx;

@safe @nogc pure nothrow:

import backend.js.allUsed : AllUsed, allUsed, AnyDecl;
import backend.js.jsAst : JsDecl, JsDeclKind, JsExpr, JsName;
import frontend.showModel : ShowCtx;
import frontend.storage : FileContentGetters;
import model.model :
	CommonTypes,
	FunDecl,
	Local,
	Program,
	ProgramWithMain,
	SpecDecl,
	StructAlias,
	StructDecl,
	Test,
	VarDecl,
	Visibility;
import util.alloc.alloc : Alloc;
import util.col.array : map;
import util.col.map : Map;
import util.opt : Opt, some;
import util.symbol : Symbol, symbol;
import util.symbolSet : SymbolSet;
import util.uri : Uri;
import versionInfo : VersionInfo;

struct TranslateProgramCtx {
	@safe @nogc pure nothrow:

	Alloc* allocPtr;
	const ShowCtx showCtx;
	const FileContentGetters* fileContentGetters;
	immutable ProgramWithMain* programWithMainPtr;
	immutable VersionInfo version_;
	immutable SymbolSet allExterns;
	immutable AllUsed allUsed;
	immutable ModuleExportMangledNames exportMangledNames;

	ref Program program() return scope const =>
		programWithMainPtr.program;
	ref Alloc alloc() =>
		*allocPtr;
}

struct TranslateModuleCtx {
	@safe @nogc pure nothrow:
	TranslateProgramCtx* ctx;
	Uri curUri;
	immutable Map!(AnyDecl, ushort) privateMangledNames;
	immutable Map!(StructDecl*, StructAlias*) aliases;

	ref Alloc alloc() =>
		ctx.alloc;
	ref ShowCtx showCtx() return scope const =>
		ctx.showCtx;
	ref Program program() return scope const =>
		ctx.program;
	ref CommonTypes commonTypes() return scope const =>
		*program.commonTypes;
	VersionInfo version_() scope const =>
		ctx.version_;
	SymbolSet allExterns() scope const =>
		ctx.allExterns;
	AllUsed allUsed() return scope const =>
		ctx.allUsed;
	ModuleExportMangledNames exportMangledNames() return scope const =>
		ctx.exportMangledNames;

	bool isBrowser() const =>
		symbol!"browser" in allExterns;
}

immutable struct ModuleExportMangledNames {
	// Maps any kind of declaration to its name index.
	// So 'foo' will be renamed 'foo__1'
	// If no mangling is necessary, it won't be in here.
	// This is used to get the first index for local names.
	Map!(Symbol, ushort) lastIndexForName;
	// Key is some decl, e.g. StructDecl*.
	// If it's not in the map, don't mangle it.
	Map!(AnyDecl, ushort) mangledNames;
}

JsDecl makeDecl(in TranslateModuleCtx ctx, AnyDecl source, JsDeclKind value) =>
	JsDecl(
		source,
		source.visibility == Visibility.private_ ? JsDecl.Exported.private_ : JsDecl.Exported.export_,
		mangledNameForDecl(ctx, source),
		value);

JsName jsNameForDecl(in AnyDecl a, Opt!ushort index) {
	JsName.Kind kind = a.matchIn!(JsName.Kind)(
		(in FunDecl _) =>
			JsName.Kind.function_,
		(in SpecDecl _) =>
			// Specs don't compile to named entities; their sigs become function parameters
			assert(false),
		(in StructAlias _) =>
			JsName.Kind.type,
		(in StructDecl _) =>
			JsName.Kind.type,
		(in Test _) =>
			JsName.Kind.function_,
		(in VarDecl _) =>
			JsName.Kind.function_);
	return JsName(kind, a.name, index);
}

private JsName mangledNameForDecl(in TranslateModuleCtx ctx, in AnyDecl a) =>
	jsNameForDecl(
		a,
		(a.visibility == Visibility.private_ ? ctx.privateMangledNames : ctx.exportMangledNames.mangledNames)[a]);
private JsName funName(in TranslateModuleCtx ctx, in FunDecl* a) =>
	mangledNameForDecl(ctx, AnyDecl(a));
JsExpr translateFunReference(in TranslateModuleCtx ctx, in FunDecl* a) =>
	JsExpr(funName(ctx, a));
private JsName testName(in TranslateModuleCtx ctx, in Test* a) =>
	mangledNameForDecl(ctx, AnyDecl(a));
JsExpr translateTestReference(in TranslateModuleCtx ctx, in Test* a) =>
	JsExpr(testName(ctx, a));
private JsName structName(in TranslateModuleCtx ctx, in StructDecl* a) =>
	mangledNameForDecl(ctx, AnyDecl(a));
JsExpr translateStructReference(in TranslateModuleCtx ctx, in StructDecl* a) =>
	JsExpr(structName(ctx, a));
private JsName varName(in TranslateModuleCtx ctx, in VarDecl* a) =>
	mangledNameForDecl(ctx, AnyDecl(a));
JsExpr translateVarReference(in TranslateModuleCtx ctx, in VarDecl* a) =>
	JsExpr(varName(ctx, a));

JsName localName(in Local a) =>
	JsName.local(a.name);