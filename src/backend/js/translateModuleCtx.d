module backend.js.translateModuleCtx;

@safe @nogc pure nothrow:

import backend.js.allUsed : AllUsed, allUsed, AnyDecl;
import backend.js.jsAst : genLocalGet, JsDecl, JsDeclKind, JsExpr, JsName;
import backend.js.sourceMap : Source;
import frontend.showModel : ShowCtx;
import frontend.storage : FileContentGetters, LineAndCharacterGetters;
import model.model :
	CommonTypes,
	FunDecl,
	FunDeclSource,
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
import util.opt : force, has, Opt, some;
import util.sourceRange : UriAndRange;
import util.symbol : Symbol;
import util.symbolSet : SymbolSet;
import versionInfo : JsTarget, VersionInfo;

struct TranslateProgramCtx {
	@safe @nogc pure nothrow:

	Alloc* allocPtr;
	const ShowCtx showCtx;
	const LineAndCharacterGetters lineAndCharacterGetters;
	const FileContentGetters* fileContentGetters;
	immutable ProgramWithMain* programWithMainPtr;
	immutable VersionInfo version_;
	immutable JsTarget target;
	immutable SymbolSet allExterns;
	immutable AllUsed allUsed;
	immutable Opt!ModuleExportMangledNames exportMangledNames; // Only used for building to modules

	ref Program program() return scope const =>
		programWithMainPtr.program;
	ref CommonTypes commonTypes() return scope const =>
		program.commonTypes;
	ref Alloc alloc() =>
		*allocPtr;
	bool isBrowser() const =>
		target == JsTarget.browser;
}

struct TranslateModuleCtx {
	@safe @nogc pure nothrow:
	TranslateProgramCtx* ctx;
	immutable Map!(AnyDecl, ushort) privateMangledNames;
	immutable Map!(StructDecl*, StructAlias*) aliases;

	ref Alloc alloc() =>
		ctx.alloc;
	ref ShowCtx showCtx() return scope const =>
		ctx.showCtx;
	ref Program program() return scope const =>
		ctx.program;
	ref CommonTypes commonTypes() return scope const =>
		ctx.commonTypes;
	VersionInfo version_() scope const =>
		ctx.version_;
	SymbolSet allExterns() scope const =>
		ctx.allExterns;
	AllUsed allUsed() return scope const =>
		ctx.allUsed;
	Opt!ModuleExportMangledNames exportMangledNames() return scope const =>
		ctx.exportMangledNames;
	bool isBrowser() const =>
		ctx.isBrowser;
}

Source sourceAtRange(in TranslateModuleCtx ctx, in UriAndRange range, Symbol name) =>
	Source(range.uri, name, ctx.ctx.lineAndCharacterGetters[range].range.start);
Source aliasSource(in TranslateModuleCtx ctx, in StructAlias* a) =>
	declSource(ctx, AnyDecl(a));
Source declSource(in TranslateModuleCtx ctx, in AnyDecl a) =>
	sourceAtRange(ctx, a.range, a.name);
Source funSource(in TranslateModuleCtx ctx, in FunDecl* a) =>
	declSource(ctx, AnyDecl(a));
Source structSource(in TranslateModuleCtx ctx, in StructDecl* a) =>
	declSource(ctx, AnyDecl(a));
Source testSource(in TranslateModuleCtx ctx, in Test* a) =>
	declSource(ctx, AnyDecl(a));
Source variantMethodSource(in TranslateModuleCtx ctx, in FunDeclSource.VariantMethod a) =>
	sourceAtRange(ctx, a.method.range, a.method.name);

// This will be empty whne compiling to a bundle.
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
		declSource(ctx, source),
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
		(has(ctx.exportMangledNames) && a.visibility != Visibility.private_
			? force(ctx.exportMangledNames).mangledNames
			: ctx.privateMangledNames)[a]);
private JsName funName(in TranslateModuleCtx ctx, in FunDecl* a) =>
	mangledNameForDecl(ctx, AnyDecl(a));
JsExpr translateFunReference(in TranslateModuleCtx ctx, in Source source, in FunDecl* a) =>
	genLocalGet(source, funName(ctx, a));
private JsName testName(in TranslateModuleCtx ctx, in Test* a) =>
	mangledNameForDecl(ctx, AnyDecl(a));
JsExpr translateTestReference(in TranslateModuleCtx ctx, in Source source, in Test* a) =>
	genLocalGet(source, testName(ctx, a));
private JsName structName(in TranslateModuleCtx ctx, in StructDecl* a) =>
	mangledNameForDecl(ctx, AnyDecl(a));
JsExpr translateStructReference(in TranslateModuleCtx ctx, in Source source, in StructDecl* a) =>
	genLocalGet(source, structName(ctx, a));
private JsName varName(in TranslateModuleCtx ctx, in VarDecl* a) =>
	mangledNameForDecl(ctx, AnyDecl(a));
JsExpr translateVarReference(in TranslateModuleCtx ctx, in Source source, in VarDecl* a) =>
	genLocalGet(source, varName(ctx, a));

JsName localName(in Local a) =>
	JsName.local(a.name);
