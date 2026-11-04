package studio.lunabee.nouveaurecit.data.book

import java.util.Locale

/**
 * `Model/Books/EditionLanguageFilter.swift`: which editions of a work « Éditions » shows — all of them,
 * those in one language, or those whose language nobody has said. A work can have thousands of
 * editions — « L'Appel de la forêt » has 7 742 —, and the list is read in one language at a time.
 *
 * The language is the edition's own, `EditionEntity.lang` (`wdt:P407`, which inventaire.io answers as
 * `originalLang`), never guessed: most Wikidata editions have none, and they are listed under
 * [Unspecified] rather than counted where they probably belong.
 */
sealed interface EditionLanguageFilter {
    data object All : EditionLanguageFilter

    data class Code(val code: String) : EditionLanguageFilter

    data object Unspecified : EditionLanguageFilter

    fun admits(lang: String?): Boolean = when (this) {
        All -> true
        is Code -> normalized(lang) == code
        Unspecified -> normalized(lang) == null
    }

    /** One entry of the menu: a language, and how many editions it holds. */
    data class Option(val language: EditionLanguageFilter, val count: Int)

    companion object {
        /** The language an edition carries, as the filter reads it: lowercased, and none when empty. */
        fun normalized(lang: String?): String? = lang?.trim()?.lowercase()?.takeIf { it.isNotEmpty() }

        /**
         * What the menu offers for editions in [langs]: every edition first, then each language present,
         * the one with the most editions first, then the editions without a language when there are some.
         */
        fun options(langs: List<String?>): List<Option> {
            val counts: MutableMap<String, Int> = mutableMapOf()
            var unspecified = 0
            for (lang in langs) {
                val code: String? = normalized(lang)
                if (code == null) unspecified += 1 else counts[code] = (counts[code] ?: 0) + 1
            }
            val languages: List<Option> = counts.entries
                .sortedWith(compareByDescending<Map.Entry<String, Int>> { it.value }.thenBy { it.key })
                .map { Option(Code(it.key), it.value) }
            val rest: List<Option> = if (unspecified > 0) listOf(Option(Unspecified, unspecified)) else emptyList()
            return listOf(Option(All, langs.size)) + languages + rest
        }

        /** The language shown until somebody picks one: the phone's, when the work has editions in it, every edition otherwise. */
        fun preferred(phoneLanguage: String?, options: List<Option>): EditionLanguageFilter {
            val code: String = normalized(phoneLanguage) ?: return All
            return Code(code).takeIf { preferred -> options.any { it.language == preferred } } ?: All
        }

        /** The language's name in [locale], capitalised as the start of a label: « Français », « Anglais ». */
        fun name(code: String, locale: Locale): String {
            val name: String = Locale.forLanguageTag(code).getDisplayLanguage(locale).ifEmpty { code }
            return name.replaceFirstChar { it.titlecase(locale) }
        }
    }
}
