package studio.lunabee.nouveaurecit.ui.navigation

import studio.lunabee.nouveaurecit.data.EntityRepository
import studio.lunabee.nouveaurecit.data.GroupRepository
import studio.lunabee.nouveaurecit.data.UserRepository
import studio.lunabee.nouveaurecit.data.model.EntityLabel
import studio.lunabee.nouveaurecit.network.dto.EntityResultDto
import java.net.URI

/**
 * iOS `DeepLink`, `NavigationDestination+DeepLink` and `DeepLinkHandling`: an Ex-libris link,
 * `https://link.exlibris.lunabee.ovh/<path>`, and where it lands. The paths are inventaire.io's own, so the link's
 * server only has to send the same path to inventaire.io when the app is not installed (`scripts/deeplinks/`). The
 * manifest claims the domain, and its `assetlinks.json` vouches for the app.
 *
 * A path segment is decoded before it is read, and ends up in a query string: a segment that is not a whole match of
 * what inventaire.io allows makes the URL no link at all.
 */
sealed interface DeepLink {
    /** The same page on inventaire.io: where the link goes when the app cannot open it. */
    val webUrl: String

    /** A book, a work or an author, by its inventaire.io uri: `isbn:…`, `wd:…`, `inv:…`. */
    data class Entity(val uri: String) : DeepLink {
        override val webUrl: String get() = "https://inventaire.io/entity/$uri"
    }

    /** A reader, by their username, in whatever case it was typed. */
    data class User(val username: String) : DeepLink {
        override val webUrl: String get() = "https://inventaire.io/users/$username"
    }

    /** A group, by its slug. */
    data class Group(val slug: String) : DeepLink {
        override val webUrl: String get() = "https://inventaire.io/groups/$slug"
    }

    companion object {
        const val HOST: String = "link.exlibris.lunabee.ovh"

        private val ENTITY_URI: Regex = Regex("(isbn|wd|inv):[A-Za-z0-9-]+")

        /** inventaire.io's rule, `Username` in `server/lib/regex.ts`: two to twenty letters, digits or `_`, in any script. */
        private val USERNAME: Regex = Regex("[\\p{L}\\p{N}_]{2,20}")

        /**
         * What inventaire.io's `slugify` leaves of a group's name — letters in any script and `-` — then the `.1`,
         * `.2`… it appends when the slug is taken. Digits as well, as in the uris.
         */
        private val SLUG: Regex = Regex("[\\p{L}0-9-]+(\\.[0-9]+)?")

        /** The link [url] is, or `null` for any URL that is not one of the app's links, or one of a shape it does not open. */
        fun parse(url: String): DeepLink? {
            val parsed: URI = runCatching { URI(url) }.getOrNull() ?: return null
            if (parsed.scheme != "https" || parsed.host != HOST) return null
            val components: List<String> = parsed.path.orEmpty().split("/").filter { it.isNotEmpty() }
            if (components.size != 2) return null
            val value: String = components[1]
            return when (components[0]) {
                "entity" -> Entity(value).takeIf { ENTITY_URI.matches(value) }
                "users" -> User(value).takeIf { USERNAME.matches(value) }
                "groups" -> Group(value).takeIf { SLUG.matches(value) }
                else -> null
            }
        }

        /**
         * Where [link] lands, or `null` when inventaire.io knows no such entity, reader or group, or the entity is of a
         * type the app has no screen for. Books and authors on Recherche, readers and groups on Réseau.
         */
        suspend fun target(
            link: DeepLink,
            entities: EntityRepository,
            users: UserRepository,
            groups: GroupRepository,
        ): LinkTarget? = when (link) {
            is Entity -> destination(link.uri, entities)?.let { LinkTarget.Screen(AppTab.Search, it) }
            is User -> users.getOrFetchUser(link.username)?.let { userTarget(it.id, users.myUserId.value) }
            is Group -> LinkTarget.Screen(AppTab.Network, Destination.Group(groups.groupId(link.slug)))
        }

        /**
         * A reader's profile on Réseau, or the Profil sheet when the reader is me. Told apart by id rather than by
         * name: inventaire.io still answers to a reader's former name, which a link may carry.
         */
        fun userTarget(userId: String, myUserId: String?): LinkTarget =
            if (userId == myUserId) LinkTarget.Profile else LinkTarget.Screen(AppTab.Network, Destination.User(userId))

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
}
