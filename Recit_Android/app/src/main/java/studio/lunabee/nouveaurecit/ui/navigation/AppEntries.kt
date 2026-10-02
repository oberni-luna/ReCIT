package studio.lunabee.nouveaurecit.ui.navigation

import androidx.navigation3.runtime.EntryProviderScope
import androidx.navigation3.runtime.NavKey
import studio.lunabee.nouveaurecit.ui.book.AuthorScreen
import studio.lunabee.nouveaurecit.ui.book.BookScreen
import studio.lunabee.nouveaurecit.ui.book.WorkScreen
import studio.lunabee.nouveaurecit.ui.inventory.InventoryScreen
import studio.lunabee.nouveaurecit.ui.inventory.LocalSearchResultsScreen
import studio.lunabee.nouveaurecit.ui.inventory.ShelfScreen
import studio.lunabee.nouveaurecit.ui.lists.EntityListScreen
import studio.lunabee.nouveaurecit.ui.lists.ListsScreen
import studio.lunabee.nouveaurecit.ui.network.AddFriendsScreen
import studio.lunabee.nouveaurecit.ui.network.InvitationsScreen
import studio.lunabee.nouveaurecit.ui.network.NetworkScreen
import studio.lunabee.nouveaurecit.ui.network.UserScreen
import studio.lunabee.nouveaurecit.ui.profile.DeleteAccountScreen
import studio.lunabee.nouveaurecit.ui.profile.ProfileScreen

/**
 * `viewForDestination(_:)`: the one place a [Destination] becomes a screen. Every tab's
 * `NavDisplay` uses it, so any screen can be pushed from any tab.
 */
fun EntryProviderScope<NavKey>.appEntries(navigator: Navigator) {
    entry<Destination.InventoryRoot> { InventoryScreen(navigator) }
    entry<Destination.ListsRoot> { ListsScreen(navigator) }
    entry<Destination.NetworkRoot> { NetworkScreen(navigator) }
    entry<Destination.ProfileRoot> { ProfileScreen(navigator) }
    entry<Destination.Author> { AuthorScreen(it, navigator) }
    entry<Destination.Work> { WorkScreen(it, navigator) }
    entry<Destination.Book> { BookScreen(it, navigator) }
    entry<Destination.User> { UserScreen(it, navigator) }
    entry<Destination.EntityList> { EntityListScreen(it, navigator) }
    entry<Destination.Shelf> { ShelfScreen(it, navigator) }
    entry<Destination.LocalSearchResults> { LocalSearchResultsScreen(it, navigator) }
    entry<Destination.AddFriends> { AddFriendsScreen(navigator) }
    entry<Destination.Invitations> { InvitationsScreen(navigator) }
    entry<Destination.DeleteAccount> { DeleteAccountScreen(navigator) }
}
