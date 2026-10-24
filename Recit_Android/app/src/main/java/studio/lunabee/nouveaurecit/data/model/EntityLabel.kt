package studio.lunabee.nouveaurecit.data.model

/*
 * `EntityLabel.resolve`: the name a work or an author wears on screen, picked from the labels
 * inventaire.io relays from Wikidata.
 *
 * Wikidata has been moving names that read the same in every Latin-script language to the
 * multilingual `mul` label, and deleting the per-language copies. `wd:Q535` carries « Victor Hugo »
 * under `mul` and nowhere under `fr` or `en` (checked on 2026-10-24), so a name read as
 * `labels["fr"] ?: labels["en"] ?: labels.values.firstOrNull()` came out as whichever language the
 * JSON listed first — « Виктор Гюго » for him.
 *
 * The order: French and English first, as the app always read them; then `mul`, which is the name
 * itself rather than a translation of it; then the entity's original language; and, when none of
 * those exist, the smallest language code, so the same entity is named the same way on every sync.
 *
 * `null` means there is no non-empty label at all. Editions are named by [Merges.editionTitle],
 * whose `fromclaims` and title claim do not exist for works and authors.
 */
object EntityLabel {
    /** The label to display, or `null` when the entity has none. */
    fun resolve(labels: Map<String, String>?, originalLang: String? = null): String? {
        if (labels == null) return null
        val preferred: List<String> = listOfNotNull("fr", "en", "mul", originalLang)
        return preferred.firstNotNullOfOrNull { language -> labels[language]?.takeIf { it.isNotEmpty() } }
            ?: labels.filterValues { it.isNotEmpty() }.minByOrNull { it.key }?.value
    }
}
