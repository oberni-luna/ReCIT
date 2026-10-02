package studio.lunabee.nouveaurecit.ui.navigation

import androidx.navigation3.runtime.NavKey
import kotlinx.serialization.Serializable

/**
 * `Features/EntityBrowser/NavigationDestination.swift`: every screen a tab can push. One sealed
 * hierarchy, one `entryProvider` ([appEntries]) — adding a destination is a case here and a branch
 * there, as on iOS.
 *
 * Keys are `@Serializable` so each tab's back stack survives process death.
 */
@Serializable
sealed interface Destination : NavKey {
    /** The four tab roots. */
    @Serializable data object InventoryRoot : Destination
    @Serializable data object ListsRoot : Destination
    @Serializable data object NetworkRoot : Destination
    @Serializable data object ProfileRoot : Destination

    @Serializable data class Author(val uri: String) : Destination

    /** A work: one edition opens the book, several open the edition picker. */
    @Serializable data class Work(val uri: String) : Destination

    @Serializable data class Book(val anchor: BookAnchor) : Destination

    @Serializable data class User(val id: String) : Destination

    @Serializable data class EntityList(val id: String) : Destination

    @Serializable data class Shelf(val id: String) : Destination

    @Serializable data class LocalSearchResults(val query: String) : Destination

    @Serializable data object AddFriends : Destination

    @Serializable data object Invitations : Destination

    @Serializable data object DeleteAccount : Destination
}

/** `Features/Book/BookAnchor.swift`: what a book screen is opened from. */
@Serializable
sealed interface BookAnchor {
    @Serializable data class Edition(val uri: String) : BookAnchor

    @Serializable data class Item(val itemId: String) : BookAnchor

    /** A work from search: the screen resolves its best edition, header already filled. */
    @Serializable data class BestEditionOfWork(val uri: String, val title: String, val imageUrl: String?) : BookAnchor
}
