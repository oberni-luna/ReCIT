package studio.lunabee.nouveaurecit.ui.network

import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyListScope
import androidx.compose.material3.HorizontalDivider
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.db.ItemRow
import studio.lunabee.nouveaurecit.data.db.ShelfWithItems
import studio.lunabee.nouveaurecit.data.db.UserEntity
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.SectionHeader
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.ui.book.InventoryItemRowWithActions
import studio.lunabee.nouveaurecit.ui.inventory.ShelfCarousel
import studio.lunabee.nouveaurecit.ui.navigation.BookAnchor
import studio.lunabee.nouveaurecit.ui.navigation.Destination
import studio.lunabee.nouveaurecit.ui.navigation.Navigator

/**
 * `UserInventoryTab`: the reader's étagères, when they share any, then their books — the first-sync bar
 * while they arrive, « Emprunter à … » on a long press. The tab names the page, so no header says whose.
 */
internal fun LazyListScope.userInventoryItems(
    user: UserEntity,
    shelves: List<ShelfWithItems>,
    items: List<ItemRow>,
    syncState: FirstSyncState,
    navigator: Navigator,
) {
    if (shelves.isNotEmpty()) {
        item(key = "shelves-header") {
            SectionHeader(stringResource(R.string.network_user_shelves_header, user.username))
        }
        item(key = "shelves") {
            // The same planks and paper labels as my own étagères, read-only.
            ShelfCarousel(
                shelves = shelves,
                onOpenShelf = { navigator.push(Destination.Shelf(it)) },
                onOpenItem = { navigator.push(Destination.Book(BookAnchor.Item(it))) },
            )
        }
    }
    item(key = "inventory") {
        SectionCard {
            if (syncState != FirstSyncState.Synced) {
                InventorySyncBanner(
                    title = stringResource(R.string.network_sync_inventory_friend_title, user.username),
                    state = syncState,
                )
            }
            if (syncState == FirstSyncState.Synced && items.isEmpty()) {
                PlainRow(stringResource(R.string.network_inventory_empty))
            }
            items.forEachIndexed { index, row ->
                if (index > 0 || syncState != FirstSyncState.Synced) HorizontalDivider(Modifier.padding(start = Spacing.medium), color = RecitTheme.colors.borderDefault)
                InventoryItemRowWithActions(
                    row = row,
                    showsOwner = false,
                    onClick = { navigator.push(Destination.Book(BookAnchor.Item(row.item.id))) },
                    onPush = navigator::push,
                )
            }
        }
    }
}
