package studio.lunabee.nouveaurecit.ui.book

import android.content.res.Resources
import androidx.compose.foundation.layout.Box
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.LibraryBooks
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Delete
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.hapticfeedback.HapticFeedback
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.platform.LocalResources
import androidx.compose.ui.res.stringResource
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Deferred
import kotlinx.coroutines.async
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.launch
import studio.lunabee.nouveaurecit.AppContainer
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.db.ItemRow
import studio.lunabee.nouveaurecit.designsystem.ConfirmDialog
import studio.lunabee.nouveaurecit.ui.common.InventoryItemRow
import studio.lunabee.nouveaurecit.ui.common.LocalAppContainer
import studio.lunabee.nouveaurecit.ui.common.LocalMessenger
import studio.lunabee.nouveaurecit.ui.common.Messenger
import studio.lunabee.nouveaurecit.ui.inventory.ShelfFormSheet
import studio.lunabee.nouveaurecit.ui.lists.ListFormSheet
import studio.lunabee.nouveaurecit.ui.navigation.Destination

/**
 * `BookActionsModifier`: words [state]'s [BookMenuLine]s into [MenuLine]s for [content] to place —
 * the toolbar's « … » or a row's long press — and owns what the lines lead to: the delete
 * confirmation and the new-étagère / new-list sheets, so they outlive the menu that opened them.
 *
 * Writes run on the application scope and say their snackbar from there: a row scrolled away, or
 * removed by its own deletion, does not cancel them. [onRemoved] runs once my copy is gone on the
 * server — the book screen pops; a row has nothing to do, it disappears on its own.
 */
@Composable
internal fun BookActionsHost(
    actions: BookActions,
    state: BookActionsState?,
    onPush: (Destination) -> Unit,
    onRemoved: () -> Unit = {},
    content: @Composable (lines: List<MenuLine>) -> Unit,
) {
    val container: AppContainer = LocalAppContainer.current
    val messenger: Messenger = LocalMessenger.current
    val resources: Resources = LocalResources.current
    val scope: CoroutineScope = rememberCoroutineScope()
    val currentOnRemoved: () -> Unit by rememberUpdatedState(onRemoved)
    var removesItem: String? by rememberSaveable { mutableStateOf(null) }
    var createsShelfFor: String? by rememberSaveable { mutableStateOf(null) }
    var createsListFor: String? by rememberSaveable { mutableStateOf(null) }

    val lines: List<MenuLine> = state?.lines.orEmpty().map { line ->
        when (line) {
            is BookMenuLine.Shelves -> MenuLine.Membership(
                label = resources.getString(R.string.action_shelf),
                icon = Icons.AutoMirrored.Filled.LibraryBooks,
                entries = line.entries,
                creationLabel = resources.getString(R.string.action_add_to_new_shelf),
                onToggle = { entry ->
                    state?.myItemId?.let { itemId ->
                        actions.toggleShelf(itemId, entry)
                        showMembership(messenger, resources, entry) { onPush(Destination.Shelf(entry.id)) }
                    }
                },
                onCreate = { createsShelfFor = state?.myItemId },
            )
            is BookMenuLine.Lists -> listMenuLine(
                resources = resources,
                entries = line.entries,
                onToggle = { entry ->
                    state?.singleWorkUri?.let { workUri ->
                        container.applicationScope.launch {
                            if (actions.toggleList(workUri, entry)) {
                                showMembership(messenger, resources, entry) { onPush(Destination.EntityList(entry.id)) }
                            }
                        }
                    }
                },
                onCreate = { createsListFor = state?.singleWorkUri },
            )
            BookMenuLine.Remove -> MenuLine.Action(
                label = resources.getString(R.string.inventory_item_remove_menu),
                icon = Icons.Filled.Delete,
                onClick = { removesItem = state?.myItemId },
                isDestructive = true,
            )
            BookMenuLine.AddToInventory -> MenuLine.Action(
                label = resources.getString(R.string.action_add_to_inventory),
                icon = Icons.Filled.Add,
                onClick = {
                    state?.editionUri?.let { editionUri ->
                        container.applicationScope.launch {
                            when (actions.addToInventory(editionUri)) {
                                BookActions.AddOutcome.Added -> messenger.show(resources.getString(R.string.edition_added_to_inventory))
                                BookActions.AddOutcome.NoUser -> messenger.show(resources.getString(R.string.edition_error_no_user))
                                BookActions.AddOutcome.Failed -> Unit
                            }
                        }
                    }
                },
            )
        }
    }

    content(lines)

    removesItem?.let { itemId ->
        ConfirmDialog(
            title = stringResource(R.string.inventory_item_delete_confirm),
            message = null,
            confirmLabel = stringResource(R.string.action_delete),
            cancelLabel = stringResource(R.string.action_cancel),
            onConfirm = {
                removesItem = null
                val removal: Deferred<Boolean> = container.applicationScope.async {
                    actions.removeItem(itemId).also { removed ->
                        if (removed) messenger.show(resources.getString(R.string.inventory_item_deleted))
                    }
                }
                scope.launch {
                    if (removal.await()) currentOnRemoved()
                }
            },
            onDismiss = { removesItem = null },
        )
    }
    createsShelfFor?.let { itemId -> ShelfFormSheet(shelfId = null, fileItemId = itemId, onDismiss = { createsShelfFor = null }) }
    createsListFor?.let { workUri -> ListFormSheet(listId = null, fileWorkUri = workUri, onDismiss = { createsListFor = null }) }
}

/**
 * `bookActions(edition:placement: .contextMenu)`: an [InventoryItemRow] that opens the book
 * screen's « … » menu for its edition on a long press, anchored on the row. A tap still opens the
 * book ([onClick]); [onPush] serves the snackbars' « Voir ».
 *
 * The row's [BookActions] reads Room only while its menu is open.
 */
@Composable
fun InventoryItemRowWithActions(
    row: ItemRow,
    showsOwner: Boolean,
    onClick: () -> Unit,
    onPush: (Destination) -> Unit,
    modifier: Modifier = Modifier,
) {
    val container: AppContainer = LocalAppContainer.current
    val haptics: HapticFeedback = LocalHapticFeedback.current
    val editionUri: String = row.item.editionUri
    val actions: BookActions = remember(container, editionUri) { BookActions(container, flowOf(editionUri)) }
    var expanded: Boolean by remember { mutableStateOf(false) }
    // Kept once the menu closes, so its fade-out still shows its lines.
    val state: BookActionsState? by produceState<BookActionsState?>(initialValue = null, actions, expanded) {
        if (expanded) actions.state.collect { value = it }
    }

    BookActionsHost(actions = actions, state = state, onPush = onPush) { lines ->
        Box(modifier) {
            InventoryItemRow(
                row = row,
                showsOwner = showsOwner,
                onClick = onClick,
                onLongClick = {
                    haptics.performHapticFeedback(HapticFeedbackType.LongPress)
                    expanded = true
                },
                onLongClickLabel = stringResource(R.string.action_more),
            )
            ActionsDropdown(
                expanded = expanded && state?.editionUri == editionUri,
                onDismiss = { expanded = false },
                lines = lines,
            )
        }
    }
}
