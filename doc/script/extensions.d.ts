interface CSSStyleSheet {
    // https://wicg.github.io/construct-stylesheets/#dom-cssstylesheet-replacesync
    replaceSync(style: string): void
    replace(style: string): Promise<void>
}

interface ShadowRoot {
    // https://wicg.github.io/construct-stylesheets/#dom-documentorshadowroot-adoptedstylesheets
    adoptedStyleSheets: ReadonlyArray<CSSStyleSheet>
}

interface ErrorConstructor {
    stackTraceLimit: number
}
