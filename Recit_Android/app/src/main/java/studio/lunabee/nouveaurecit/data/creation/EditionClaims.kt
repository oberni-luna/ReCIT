package studio.lunabee.nouveaurecit.data.creation

import studio.lunabee.nouveaurecit.network.dto.EntityResultDto
import studio.lunabee.nouveaurecit.network.dto.WikidataProperty

/**
 * `EditionClaims` (iOS features 0049, 0050): what inventaire.io holds about an edition as « Modifier
 * l'édition » opens — the values the form starts from, and the old values every change has to name.
 * `update-claim` replaces a value only when told which one it replaces, so these are read fresh from the
 * server rather than taken from the local `EditionEntity`, which keeps a display title and an image url.
 *
 * The uri is the **canonical** one, `inv:…`: an edition opened from its ISBN is `isbn:…` in the store,
 * and `by-uris` redirects it. `update-claim` takes `inv:` and `wd:` uris only, and a `wd:` edition lives
 * on Wikidata, where editing needs an account this app does not hold — hence [canEdit].
 */
data class EditionClaims(
    val uri: String,
    val title: String,
    val subtitle: String? = null,
    /** The hash `invp:P2` holds, the cover's name in `/img/entities/`. */
    val coverHash: String? = null,
    /** As inventaire.io prints it, hyphens included: the ISBN-13, or the ISBN-10 when there is no other. */
    val isbn: String = "",
    /** The ISBN-10, when it is shown under an ISBN-13. Never sent: the server infers it. */
    val isbn10: String? = null,
    /** The works this is an edition of, `wdt:P629`: one, several for a collection of works, or none. */
    val workUris: List<String> = emptyList(),
    /** The language the edition's labels were written in: the one a work or author created from the form gets too. */
    val labelLanguage: String? = null,
    /** The rest of what the edition says: publisher, date, format, contributors, identifiers, links. */
    val properties: EditionProperties = EditionProperties(),
) {
    /** The ISBN without its separators. */
    val normalizedIsbn: String get() = NewBookDraft.normalizeIsbn(isbn)

    /** Where the cover the edition holds is served from, or `null` when it has none. */
    val coverUrl: String? get() = coverHash?.let(EntityImageHash::url)

    companion object {
        /**
         * Reads one entity of a `by-uris` answer, its entity values named with [labels]. `null` for anything
         * but an `inv:` edition: there is nothing the form could send about it.
         */
        fun from(dto: EntityResultDto, labels: Map<String, String> = emptyMap()): EditionClaims? {
            if (!dto.uri.startsWith("inv:") || (dto.type != null && dto.type != "edition")) return null
            val isbn13: String? = dto.claimString(WikidataProperty.ISBN_13)
            val isbn10: String? = dto.claimString(WikidataProperty.ISBN_10)
            return EditionClaims(
                uri = dto.uri,
                title = dto.claimString(EditableClaimProperty.Title.uri).orEmpty(),
                subtitle = dto.claimString(EditableClaimProperty.Subtitle.uri),
                coverHash = dto.claimString(EditableClaimProperty.Cover.uri),
                isbn = isbn13 ?: isbn10.orEmpty(),
                isbn10 = if (isbn13 == null) null else isbn10,
                workUris = dto.claimStrings(EditableClaimProperty.Work.uri),
                labelLanguage = dto.originalLang,
                properties = EditionProperties.fromClaims(dto.claims, labels),
            )
        }

        /** Whether the book screen offers to edit the edition behind this uri: every one but a Wikidata edition. */
        fun canEdit(uri: String): Boolean = !uri.startsWith("wd:")
    }
}
