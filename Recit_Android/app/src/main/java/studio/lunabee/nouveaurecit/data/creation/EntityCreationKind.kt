package studio.lunabee.nouveaurecit.data.creation

/**
 * `EntityCreationKind` (iOS feature 0050): what an entity created from the form is, and so what
 * `POST /api/entities` is sent for it — the class inventaire.io's website gives it (`wdt:P31`), and what
 * else it needs.
 *
 * A collection is the odd one: it has no label, its name is a title (`wdt:P1476`, as an edition's), and
 * the website will not create one without its publisher (`wdt:P123`).
 */
sealed interface EntityCreationKind {
    data object Human : EntityCreationKind

    data object Publisher : EntityCreationKind

    data class Collection(val publisherUri: String) : EntityCreationKind

    companion object {
        /**
         * The kind of entity the values of [property] are, when one can be created from the form — `null`
         * for a language, chosen and never created, and for a collection while no publisher exists.
         */
        fun of(property: EditionProperty, publisherUri: String?): EntityCreationKind? = when (property.searchType) {
            EntitySearchType.Humans -> Human
            EntitySearchType.Publishers -> Publisher
            EntitySearchType.Collections -> publisherUri?.let(::Collection)
            else -> null
        }
    }
}
