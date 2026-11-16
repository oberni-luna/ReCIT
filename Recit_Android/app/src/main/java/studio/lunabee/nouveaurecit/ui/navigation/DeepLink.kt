package studio.lunabee.nouveaurecit.ui.navigation

import kotlinx.coroutines.CancellationException
import studio.lunabee.nouveaurecit.data.EntityRepository
import studio.lunabee.nouveaurecit.data.GroupRepository
import studio.lunabee.nouveaurecit.data.InventoryRepository
import studio.lunabee.nouveaurecit.data.ListRepository
import studio.lunabee.nouveaurecit.data.ShelfRepository
import studio.lunabee.nouveaurecit.data.UserRepository
import studio.lunabee.nouveaurecit.data.db.ListWithElements
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

    /** A list, opened on its first element, or on the element [elementId] names when it has one. */
    data class EntityList(val id: String, val elementId: String? = null) : DeepLink {
        override val webUrl: String
            get() = "https://inventaire.io/lists/$id" + elementId?.let { "/element/$it" }.orEmpty()
    }

    /** A copy of a book, mine, a friend's or a stranger's, by its id. */
    data class Item(val id: String) : DeepLink {
        override val webUrl: String get() = "https://inventaire.io/items/$id"
    }

    /** An étagère, by its id. */
    data class Shelf(val id: String) : DeepLink {
        override val webUrl: String get() = "https://inventaire.io/shelves/$id"
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

        /** A document id in inventaire.io's CouchDB: 32 lower-case hexadecimal digits. */
        private val COUCH_ID: Regex = Regex("[0-9a-f]{32}")

        /** The link [url] is, or `null` for any URL that is not one of the app's links, or one of a shape it does not open. */
        fun parse(url: String): DeepLink? {
            val parsed: URI = runCatching { URI(url) }.getOrNull() ?: return null
            if (parsed.scheme != "https" || parsed.host != HOST) return null
            val components: List<String> = parsed.path.orEmpty().split("/").filter { it.isNotEmpty() }
            return list(components) ?: page(components)
        }

        /** `lists/<id>`, or `lists/<id>/element/<elementId>`: the two paths inventaire.io's web client gives a list. */
        private fun list(components: List<String>): DeepLink? {
            if (components.firstOrNull() != "lists" || components.size < 2 || !COUCH_ID.matches(components[1])) return null
            return when {
                components.size == 2 -> EntityList(components[1])
                components.size == 4 && components[2] == "element" && COUCH_ID.matches(components[3]) ->
                    EntityList(components[1], components[3])
                else -> null
            }
        }

        /** `entity/<uri>`, `users/<username>`, `groups/<slug>`, `items/<id>`, `shelves/<id>`: a page named by one segment. */
        private fun page(components: List<String>): DeepLink? {
            if (components.size != 2) return null
            val value: String = components[1]
            return when (components[0]) {
                "entity" -> Entity(value).takeIf { ENTITY_URI.matches(value) }
                "users" -> User(value).takeIf { USERNAME.matches(value) }
                "groups" -> Group(value).takeIf { SLUG.matches(value) }
                "items" -> Item(value).takeIf { COUCH_ID.matches(value) }
                "shelves" -> Shelf(value).takeIf { COUCH_ID.matches(value) }
                else -> null
            }
        }

        /**
         * Where [link] lands, or `null` when inventaire.io knows no such entity, reader, group, list, copy or étagère,
         * the entity is of a type the app has no screen for, or the étagère is a stranger's. Books and authors on
         * Recherche, readers and groups on Réseau, lists on Listes, copies and étagères on Inventaire.
         */
        suspend fun target(
            link: DeepLink,
            entities: EntityRepository,
            users: UserRepository,
            groups: GroupRepository,
            lists: ListRepository,
            inventory: InventoryRepository,
            shelves: ShelfRepository,
        ): LinkTarget? = when (link) {
            is Entity -> destination(link.uri, entities)?.let { LinkTarget.Screen(AppTab.Search, it) }
            is User -> users.getOrFetchUser(link.username)?.let { userTarget(it.id, users.myUserId.value) }
            is Group -> LinkTarget.Screen(AppTab.Network, Destination.Group(groups.groupId(link.slug)))
            is EntityList -> linkedList(link.id, lists, users)?.let {
                LinkTarget.Screen(AppTab.Lists, listDestination(it, link.elementId))
            }
            is Item -> itemDestination(link.id, inventory)?.let { LinkTarget.Screen(AppTab.Inventory, it) }
            is Shelf -> shelfDestination(link.id, shelves, users)?.let { LinkTarget.Screen(AppTab.Inventory, it) }
        }

        /**
         * A linked copy: the Fiche livre anchored on it when Room holds it, mine or a friend's, which says whose it is
         * and offers « Emprunter à… » on a friend's; else the Fiche livre of its edition, which neither shows nor
         * stores anything of a stranger's copy.
         */
        private suspend fun itemDestination(id: String, inventory: InventoryRepository): Destination? =
            if (inventory.isStored(id)) {
                Destination.Book(BookAnchor.Item(id))
            } else {
                inventory.fetchEditionUri(id)?.let { Destination.Book(BookAnchor.Edition(it)) }
            }

        /** A linked étagère, mine or a friend's: from Room, else loaded into it. Anyone else's stays out, and `null`. */
        private suspend fun shelfDestination(id: String, shelves: ShelfRepository, users: UserRepository): Destination? {
            if (shelves.isStored(id)) return Destination.Shelf(id)
            val owners: Set<String> = (users.friends().map { it.id } + listOfNotNull(users.myUserId.value)).toSet()
            return shelves.fetchShelf(id, owners)?.let { Destination.Shelf(it.id) }
        }

        /**
         * The list Room holds, mine or a friend's; else inventaire.io's, stored with its creator read alongside, so
         * that it opens read-only like a friend's. The creator failing to come leaves the list to open all the same.
         */
        private suspend fun linkedList(id: String, lists: ListRepository, users: UserRepository): ListWithElements? =
            lists.storedList(id) ?: lists.fetchList(id)?.also { fetched ->
                val creatorId: String = fetched.list.creatorId ?: return@also
                try {
                    users.getOrFetchUsers(listOf(creatorId))
                } catch (cancellation: CancellationException) {
                    throw cancellation
                } catch (_: Exception) {
                }
            }

        /**
         * A linked list, springing to the element linked as « Dans les listes » does, by that element's entity uri.
         * An element no longer in the list, or none linked, opens the list on its first element.
         */
        fun listDestination(list: ListWithElements, elementId: String?): Destination =
            Destination.EntityList(list.list.id, list.elements.firstOrNull { it.id == elementId }?.uri)

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
