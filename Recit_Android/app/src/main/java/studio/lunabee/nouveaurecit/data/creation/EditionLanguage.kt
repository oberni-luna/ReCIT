package studio.lunabee.nouveaurecit.data.creation

import java.util.Locale

/**
 * What the ISBN says about the language a book is written in (feature 0020). The registration group of
 * an ISBN is handed out by language area — `978-2` is the French-language group — so the barcode
 * already answers a question the form would otherwise have to ask.
 *
 * Two spellings of one fact: [uri] goes into the edition's `wdt:P407` claim, [code] names the labels
 * of the entities being created.
 */
data class EditionLanguage(
    /** The wikidata entity of the language — `wd:Q150` for French. */
    val uri: String,
    /** The two-letter code — `fr`. */
    val code: String,
) {
    /** The language's name in the reader's language, or `null` rather than a bare code. */
    fun displayName(locale: Locale = Locale.getDefault()): String? =
        Locale.forLanguageTag(code).getDisplayLanguage(locale).takeIf { it.isNotBlank() && it != code }
}
