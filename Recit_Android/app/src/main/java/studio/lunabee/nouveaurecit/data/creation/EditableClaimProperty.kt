package studio.lunabee.nouveaurecit.data.creation

/**
 * `EditableClaimProperty` (iOS feature 0049): the claims « Modifier l'édition » has always changed — on
 * the edition its title, subtitle, cover and work; on that work its authors. The rest of what an edition
 * says is the catalogue's ([EditionProperty]), named by its uri.
 *
 * `invp:P2` is not a Wikidata property: it is inventaire.io's own, and holds the hash a cover was filed
 * under, never a url.
 */
enum class EditableClaimProperty(val uri: String) {
    Title("wdt:P1476"),
    Subtitle("wdt:P1680"),
    Cover("invp:P2"),

    /** Edition or translation of — the work, on the edition. */
    Work("wdt:P629"),

    /** Author — on the work. */
    Author("wdt:P50"),
    ;

    companion object {
        fun from(uri: String): EditableClaimProperty? = entries.firstOrNull { it.uri == uri }
    }
}
