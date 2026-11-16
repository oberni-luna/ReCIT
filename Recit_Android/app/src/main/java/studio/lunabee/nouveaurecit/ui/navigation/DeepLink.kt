package studio.lunabee.nouveaurecit.ui.navigation

import studio.lunabee.nouveaurecit.data.EntityRepository
import studio.lunabee.nouveaurecit.data.model.EntityLabel
import studio.lunabee.nouveaurecit.network.dto.EntityResultDto
import java.net.URI

/**
 * iOS `DeepLink` and `EntityModel+DeepLink`: an Ex-libris link, `https://link.exlibris.lunabee.ovh/entity/<uri>`,
 * and the screen it opens. The path is inventaire.io's own, so the link's server only has to send the same path to
 * inventaire.io when the app is not installed (`scripts/deeplinks/`). The manifest claims the domain, and its
 * `assetlinks.json` vouches for the app.
 */
object DeepLink {
    const val HOST: String = "link.exlibris.lunabee.ovh"

    /** The inventaire.io uri a link names — `isbn:…`, `wd:Q…`, `inv:…` — or `null` for any other URL. */
    fun entityUri(url: String): String? {
        val parsed: URI = runCatching { URI(url) }.getOrNull() ?: return null
        if (parsed.scheme != "https" || parsed.host != HOST) return null
        val components: List<String> = parsed.path.orEmpty().split("/").filter { it.isNotEmpty() }
        if (components.size != 2 || components[0] != "entity") return null
        val uri: String = components[1]
        val separator: Int = uri.indexOf(':')
        return uri.takeIf { separator > 0 && separator < uri.lastIndex }
    }

    /** The same page on inventaire.io: where the link goes when the app cannot open it. */
    fun webUrl(entityUri: String): String = "https://inventaire.io/entity/$entityUri"

    /**
     * The screen a link to [entityUri] opens, or `null` when inventaire.io has no such entity, or one of a type the
     * app has no screen for. An `isbn:` uri is an edition by construction; any other may be a work, an edition or a
     * person, and only `by-uris` says which.
     */
    suspend fun destination(entityUri: String, entities: EntityRepository): Destination? =
        if (entityUri.startsWith("isbn:")) {
            Destination.Book(BookAnchor.Edition(entityUri))
        } else {
            entities.fetchEntities(listOf(entityUri)).firstOrNull()?.let(::destination)
        }

    /** The screen for an entity inventaire.io described, under its own uri: a merged `inv:` answers under another. */
    fun destination(entity: EntityResultDto): Destination? = when (entity.type) {
        "edition" -> Destination.Book(BookAnchor.Edition(entity.uri))
        // A work is not a book: the book screen picks the edition, as it does for a search result.
        "work" -> Destination.Book(
            BookAnchor.BestEditionOfWork(
                uri = entity.uri,
                title = EntityLabel.resolve(entity.labels, entity.originalLang).orEmpty(),
                imageUrl = null,
            ),
        )
        "human" -> Destination.Author(entity.uri)
        else -> null
    }
}
