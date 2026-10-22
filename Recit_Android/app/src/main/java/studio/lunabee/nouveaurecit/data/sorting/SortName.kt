package studio.lunabee.nouveaurecit.data.sorting

import java.text.Normalizer
import java.util.Locale

/**
 * `AutoSortName`, kept for what the manual surface needs of it: one place that decides when two
 * étagère names are the same name.
 *
 * Folding case *and* diacritics is deliberate. « Poésie » and « poesie » are the same étagère to a
 * reader. French, because the folding of a French name should not depend on the device's locale.
 */
object SortName {
    private val combiningMarks: Regex = Regex("\\p{Mn}+")

    /**
     * The name as it should be shown: surrounding whitespace gone, `null` when nothing is left. A blank
     * name is not a name, and treating it as one is how an unnamed étagère reaches a plan.
     */
    fun trimmed(raw: String): String? = raw.trim().ifEmpty { null }

    /** The identity two names are compared on. `null` for a blank name, so callers get one guard instead of two. */
    fun key(raw: String): String? {
        val trimmed: String = trimmed(raw) ?: return null
        return Normalizer.normalize(trimmed, Normalizer.Form.NFD)
            .replace(combiningMarks, "")
            .lowercase(Locale.FRENCH)
    }
}
