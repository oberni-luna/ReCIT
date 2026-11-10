package studio.lunabee.nouveaurecit.data.user

import java.util.Locale

/**
 * `AccountLanguage` (iOS feature 0055): a language inventaire.io can write its e-mails in and name works
 * in — one of the 29 codes `PUT /api/user` accepts for `language` — named in the phone's own language.
 */
data class AccountLanguage(val code: String, val name: String) {
    companion object {
        /** `translatedLanguagesData` in the server, as its API documentation lists it. */
        val codes: List<String> = listOf(
            "ar", "bn", "ca", "cs", "da", "de", "el", "en", "eo", "es", "fi", "fr", "hu", "id", "it",
            "ja", "nb", "nl", "pa", "pl", "pt", "ro", "ru", "sk", "sv", "th", "tr", "uk", "zh",
        )

        /** Every language, sorted by its name as [locale] spells it. */
        fun all(locale: Locale = Locale.getDefault()): List<AccountLanguage> =
            codes.map { AccountLanguage(it, name(it, locale)) }.sortedWith(compareBy(String.CASE_INSENSITIVE_ORDER) { it.name })

        /** The language's name in [locale], capitalised as a menu entry; the code itself when the phone knows no name for it. */
        fun name(code: String, locale: Locale = Locale.getDefault()): String {
            val name: String = Locale.forLanguageTag(code).getDisplayLanguage(locale)
            return if (name.isEmpty() || name == code) code else name.replaceFirstChar { it.titlecase(locale) }
        }
    }
}
