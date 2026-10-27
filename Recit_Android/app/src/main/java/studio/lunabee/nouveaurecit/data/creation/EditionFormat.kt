package studio.lunabee.nouveaurecit.data.creation

/**
 * `EditionFormat` (iOS feature 0050): the six values inventaire.io lets an edition's `wdt:P437` take —
 * the website's shortlist in `allowed_values_per_type_per_property.ts` —, each a Wikidata uri. Their
 * names are the screen's: `edition_format_*` strings.
 */
enum class EditionFormat(val uri: String) {
    Paperback("wd:Q193934"),
    Hardback("wd:Q193955"),
    Pocket("wd:Q17994250"),
    ComicAlbum("wd:Q2831984"),
    Ebook("wd:Q128093"),
    Audiobook("wd:Q106833"),
    ;

    companion object {
        fun from(uri: String?): EditionFormat? = entries.firstOrNull { it.uri == uri }
    }
}
