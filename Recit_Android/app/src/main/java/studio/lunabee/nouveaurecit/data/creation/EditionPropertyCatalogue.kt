package studio.lunabee.nouveaurecit.data.creation

/**
 * `EditionProperty.Catalogue` (iOS feature 0057): which properties a form shows — an edition's, a work's
 * or a person's. A uri means a property only within its catalogue: a work's `wdt:P407` is its original
 * language, an edition's the language it is printed in, and a work's `wdt:P648` takes an `OL…W` where an
 * edition's takes an `OL…M`. So a form's values ([EditionProperties]) carry theirs, and the pages a
 * property pushes look the uri up there.
 */
enum class EditionPropertyCatalogue {
    Edition,
    Work,
    Human,
    ;

    /** Every property of the catalogue, in the order the form shows them. */
    val properties: List<EditionProperty>
        get() = when (this) {
            Edition -> EditionProperty.all
            Work -> WorkProperties.all
            Human -> HumanProperties.all
        }

    fun property(uri: String): EditionProperty? = properties.firstOrNull { it.uri == uri }

    fun inGroup(group: EditionProperty.Group): List<EditionProperty> = properties.filter { it.group == group }

    companion object {
        /** The catalogue of an entity of [type], as `by-uris` answers it with `info`. */
        fun of(type: String?): EditionPropertyCatalogue? = when (type) {
            "edition" -> Edition
            "work" -> Work
            "human" -> Human
            else -> null
        }
    }
}
