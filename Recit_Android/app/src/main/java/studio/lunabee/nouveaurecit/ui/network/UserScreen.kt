package studio.lunabee.nouveaurecit.ui.network

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.Logout
import androidx.compose.material.icons.outlined.Person
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.pluralStringResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.lifecycle.ViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import studio.lunabee.nouveaurecit.AppContainer
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.SyncStatus
import studio.lunabee.nouveaurecit.data.db.ItemRow
import studio.lunabee.nouveaurecit.data.db.ShelfWithItems
import studio.lunabee.nouveaurecit.data.db.UserEntity
import studio.lunabee.nouveaurecit.data.model.UserRelation
import studio.lunabee.nouveaurecit.designsystem.CellThumbnail
import studio.lunabee.nouveaurecit.designsystem.CornerRadius
import studio.lunabee.nouveaurecit.designsystem.DestructiveButton
import studio.lunabee.nouveaurecit.designsystem.EmptyState
import studio.lunabee.nouveaurecit.designsystem.PrimaryButton
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.SecondaryButton
import studio.lunabee.nouveaurecit.designsystem.SectionHeader
import studio.lunabee.nouveaurecit.designsystem.ShelfPalette
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.designsystem.ThumbnailShape
import studio.lunabee.nouveaurecit.designsystem.ThumbnailSize
import studio.lunabee.nouveaurecit.designsystem.shelfPaper
import studio.lunabee.nouveaurecit.ui.common.InventoryItemRow
import studio.lunabee.nouveaurecit.ui.common.LocalMessenger
import studio.lunabee.nouveaurecit.ui.common.Messenger
import studio.lunabee.nouveaurecit.ui.common.RecitTopBar
import studio.lunabee.nouveaurecit.ui.common.recitViewModel
import studio.lunabee.nouveaurecit.ui.navigation.BookAnchor
import studio.lunabee.nouveaurecit.ui.navigation.Destination
import studio.lunabee.nouveaurecit.ui.navigation.Navigator

class UserViewModel(private val container: AppContainer, val userId: String) : ViewModel() {
    val user: StateFlow<UserEntity?> = container.users.observeUser(userId).stateIn(viewModelScope, SharingStarted.Eagerly, null)

    val myUserId: StateFlow<String?> = container.users.myUserId

    val items: StateFlow<List<ItemRow>> = container.inventory.observeItemsOf(userId)
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    val shelves: StateFlow<List<ShelfWithItems>> = container.shelves.observeShelvesOf(userId)
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    /** `OwnedItemCountText`: my own count, read from the store so it moves with every add and delete. */
    val localItemCount: StateFlow<Int> = container.inventory.observeCountOf(userId)
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), 0)

    val firstSyncProgress: StateFlow<Map<String, SyncStatus.Progress>> = container.syncStatus.firstSyncProgress

    val actions: RelationActions = RelationActions(container, viewModelScope)

    init {
        // A reader met through a link the store has never held: fetch them once, the Flow does the rest.
        viewModelScope.launch {
            val stored: Flow<UserEntity?> = container.users.observeUser(userId)
            if (stored.first() == null) runCatching { container.users.getOrFetchUsers(listOf(userId)) }
        }
    }
}

/**
 * `UserDetailView`: who a reader is, and — for a friend, or me — their étagères and books. For
 * anyone else the books stay closed, and the screen offers what can be done about the relation
 * (`RelationActionsView`). Unfriending sits behind the « … » and a confirmation: it is the one
 * gesture of the flow that loses something.
 */
@Composable
fun UserScreen(destination: Destination.User, navigator: Navigator) {
    val viewModel: UserViewModel = recitViewModel(key = destination.id) { UserViewModel(it, destination.id) }
    val user: UserEntity? by viewModel.user.collectAsStateWithLifecycle()
    val myUserId: String? by viewModel.myUserId.collectAsStateWithLifecycle()
    var isConfirmingRemoval: Boolean by rememberSaveable { mutableStateOf(false) }
    var isConfirmingRequest: Boolean by rememberSaveable { mutableStateOf(false) }

    val current: UserEntity? = user
    val isMe: Boolean = destination.id == myUserId

    Scaffold(
        topBar = {
            RecitTopBar(
                title = stringResource(R.string.network_nav_user),
                onBack = navigator::pop,
                actions = {
                    if (current != null && !isMe && current.relation == UserRelation.Friend) {
                        UserMenu(onRemove = { isConfirmingRemoval = true })
                    }
                },
            )
        },
        containerColor = RecitTheme.colors.backgroundSecondary,
    ) { padding ->
        if (current == null) {
            Box(Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.Center) {
                CircularProgressIndicator(color = RecitTheme.colors.foregroundTinted)
            }
        } else {
            UserContent(
                user = current,
                myUserId = myUserId,
                viewModel = viewModel,
                navigator = navigator,
                onAskToAdd = { isConfirmingRequest = true },
                modifier = Modifier.padding(padding),
            )
        }
    }

    if (isConfirmingRemoval && current != null) {
        AlertDialog(
            onDismissRequest = { isConfirmingRemoval = false },
            text = {
                Text(
                    stringResource(R.string.network_remove_confirm, current.username),
                    style = RecitTheme.typography.content300,
                    color = RecitTheme.colors.foregroundDefault,
                )
            },
            confirmButton = {
                TextButton(
                    onClick = {
                        isConfirmingRemoval = false
                        viewModel.actions.unfriend(current.id)
                    },
                ) {
                    Text(stringResource(R.string.network_remove), color = RecitTheme.colors.foregroundError)
                }
            },
            dismissButton = {
                TextButton(onClick = { isConfirmingRemoval = false }) {
                    Text(stringResource(R.string.action_cancel), color = RecitTheme.colors.foregroundTinted)
                }
            },
            containerColor = RecitTheme.colors.backgroundDefault,
        )
    }

    if (isConfirmingRequest && current != null) {
        RelationRequestSheet(
            user = current,
            onSend = {
                isConfirmingRequest = false
                viewModel.actions.request(current.id)
            },
            onDismiss = { isConfirmingRequest = false },
        )
    }
}

@Composable
private fun UserMenu(onRemove: () -> Unit) {
    var expanded: Boolean by rememberSaveable { mutableStateOf(false) }
    Box {
        IconButton(onClick = { expanded = true }) {
            Icon(painterResource(R.drawable.ic_more), contentDescription = stringResource(R.string.action_more))
        }
        DropdownMenu(
            expanded = expanded,
            onDismissRequest = { expanded = false },
            containerColor = RecitTheme.colors.backgroundDefault,
        ) {
            DropdownMenuItem(
                text = { Text(stringResource(R.string.network_remove), color = RecitTheme.colors.foregroundDefault) },
                leadingIcon = {
                    Icon(Icons.AutoMirrored.Outlined.Logout, contentDescription = null, tint = RecitTheme.colors.foregroundDefault)
                },
                onClick = {
                    expanded = false
                    onRemove()
                },
            )
        }
    }
}

@Composable
private fun UserContent(
    user: UserEntity,
    myUserId: String?,
    viewModel: UserViewModel,
    navigator: Navigator,
    onAskToAdd: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val items: List<ItemRow> by viewModel.items.collectAsStateWithLifecycle()
    val shelves: List<ShelfWithItems> by viewModel.shelves.collectAsStateWithLifecycle()
    val localCount: Int by viewModel.localItemCount.collectAsStateWithLifecycle()
    val progress: Map<String, SyncStatus.Progress> by viewModel.firstSyncProgress.collectAsStateWithLifecycle()
    val messenger: Messenger = LocalMessenger.current
    val acceptedMessage: String = stringResource(R.string.network_invitation_accepted, user.username)
    val refusedMessage: String = stringResource(R.string.network_invitation_refused, user.username)
    val syncState: FirstSyncState = FirstSyncState.of(user.lastInventorySync, progress[user.id])
    val isMe: Boolean = user.id == myUserId
    // Mine is synced whole and kept in step locally; anyone else's count is the server's snapshot.
    val itemCount: Int = if (isMe && user.lastInventorySync != null) localCount else user.itemCount

    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(top = Spacing.small, bottom = Spacing.large),
    ) {
        item(key = "header") {
            SectionCard { UserHeader(user, itemCount) }
        }

        if (showsInventory(user.id, myUserId, user.relation)) {
            if (shelves.isNotEmpty()) {
                item(key = "shelves-header") {
                    SectionHeader(stringResource(R.string.network_user_shelves_header, user.username), Modifier.padding(horizontal = Spacing.medium))
                }
                item(key = "shelves") {
                    ShelvesCarousel(shelves = shelves, onOpen = { navigator.push(Destination.Shelf(it)) })
                }
            }

            item(key = "inventory-header") {
                SectionHeader(stringResource(R.string.network_user_inventory_header, user.username), Modifier.padding(horizontal = Spacing.medium))
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
                        if (index > 0 || syncState != FirstSyncState.Synced) HorizontalDivider(color = RecitTheme.colors.borderDefault)
                        InventoryItemRow(
                            row = row,
                            showsOwner = false,
                            onClick = { navigator.push(Destination.Book(BookAnchor.Item(row.item.id))) },
                        )
                    }
                }
            }
        } else {
            item(key = "relation-actions") {
                RelationActionsPanel(
                    user = user,
                    onAskToAdd = onAskToAdd,
                    onCancel = { viewModel.actions.cancel(user.id) },
                    onAccept = {
                        viewModel.actions.accept(user.id)
                        messenger.show(acceptedMessage)
                    },
                    onRefuse = {
                        viewModel.actions.refuse(user.id)
                        messenger.show(refusedMessage)
                    },
                )
            }
            item(key = "private") {
                EmptyState(
                    title = stringResource(R.string.network_private_inventory_title),
                    message = stringResource(R.string.network_private_inventory_message, user.username),
                    icon = Icons.Outlined.Person,
                    modifier = Modifier.fillMaxWidth().padding(vertical = Spacing.large),
                )
            }
        }
    }
}

/** `UserHeaderView`: the 64 dp avatar, the username, how many books. */
@Composable
private fun UserHeader(user: UserEntity, itemCount: Int) {
    Column(
        modifier = Modifier.fillMaxWidth().padding(Spacing.medium),
        verticalArrangement = Arrangement.spacedBy(Spacing.small),
    ) {
        if (user.avatarUrl != null) {
            CellThumbnail(url = user.avatarUrl, size = ThumbnailSize.Large, shape = ThumbnailShape.Circle)
        }
        Text(user.username, style = RecitTheme.typography.content400Bold, color = RecitTheme.colors.foregroundDefault)
        Text(
            pluralStringResource(R.plurals.network_user_item_count, itemCount, itemCount),
            style = RecitTheme.typography.content300,
            color = RecitTheme.colors.foregroundDefault,
        )
    }
}

/**
 * `UserShelvesSection`, read-only: the étagères a friend shares, as a horizontal row of cards —
 * the paper label and the first covers. Tapping a card opens the étagère, which stands its editing
 * down for a shelf that is not mine.
 */
@Composable
private fun ShelvesCarousel(shelves: List<ShelfWithItems>, onOpen: (String) -> Unit) {
    LazyRow(
        contentPadding = PaddingValues(horizontal = Spacing.medium),
        horizontalArrangement = Arrangement.spacedBy(Spacing.sMedium),
    ) {
        items(shelves, key = { it.shelf.id }) { shelf ->
            ShelfCard(shelf = shelf, onClick = { onOpen(shelf.shelf.id) })
        }
    }
}

@Composable
private fun ShelfCard(shelf: ShelfWithItems, onClick: () -> Unit) {
    Column(
        modifier = Modifier
            .width(ShelfCardWidth)
            .clip(RoundedCornerShape(CornerRadius.rounded))
            .background(ShelfPalette.Parchment)
            .clickable(onClick = onClick)
            .padding(Spacing.sMedium),
        verticalArrangement = Arrangement.spacedBy(Spacing.sMedium),
    ) {
        Text(
            text = shelf.shelf.name,
            style = RecitTheme.typography.action300,
            color = ShelfPalette.LabelInk,
            maxLines = 1,
            modifier = Modifier.shelfPaper(shelf.shelf.id).padding(horizontal = Spacing.small, vertical = Spacing.xSmall),
        )
        Row(horizontalArrangement = Arrangement.spacedBy(Spacing.small)) {
            shelf.items.take(ShelfCardCovers).forEach { row ->
                CellThumbnail(url = row.image, size = ThumbnailSize.Medium, shape = ThumbnailShape.Portrait)
            }
        }
    }
}

/**
 * `RelationActionsView`: what can be done about a reader one is not (yet) close to — ask, take the
 * asking back, or answer — each with the sentence saying what the gesture costs.
 */
@Composable
private fun RelationActionsPanel(
    user: UserEntity,
    onAskToAdd: () -> Unit,
    onCancel: () -> Unit,
    onAccept: () -> Unit,
    onRefuse: () -> Unit,
) {
    Column(
        modifier = Modifier.fillMaxWidth().padding(horizontal = Spacing.medium, vertical = Spacing.medium),
        verticalArrangement = Arrangement.spacedBy(Spacing.medium),
    ) {
        when (user.relation) {
            UserRelation.None -> {
                PrimaryButton(text = stringResource(R.string.network_add_to_network), onClick = onAskToAdd)
                Note(stringResource(R.string.network_reciprocal))
            }
            UserRelation.RequestSent -> {
                SecondaryButton(
                    text = stringResource(R.string.network_request_awaiting),
                    onClick = {},
                    enabled = false,
                    modifier = Modifier.fillMaxWidth(),
                )
                DestructiveButton(text = stringResource(R.string.network_request_cancel), onClick = onCancel)
                Note(stringResource(R.string.network_request_no_notification, user.username))
            }
            UserRelation.RequestReceived -> {
                PrimaryButton(text = stringResource(R.string.network_invitation_accept_request), onClick = onAccept)
                SecondaryButton(
                    text = stringResource(R.string.network_invitation_refuse),
                    onClick = onRefuse,
                    modifier = Modifier.fillMaxWidth(),
                )
                Note(stringResource(R.string.network_invitation_explanation, user.username))
            }
            UserRelation.Friend -> Unit
        }
    }
}

@Composable
private fun Note(text: String) {
    Text(
        text = text,
        style = RecitTheme.typography.footnote200,
        color = RecitTheme.colors.foregroundSecondary,
        modifier = Modifier.fillMaxWidth(),
    )
}

/**
 * `RelationRequestSheet`: it only confirms — `POST /api/relations/request` takes a user id and
 * nothing else, so there is no message to type.
 */
@Composable
private fun RelationRequestSheet(user: UserEntity, onSend: () -> Unit, onDismiss: () -> Unit) {
    ModalBottomSheet(
        onDismissRequest = onDismiss,
        containerColor = RecitTheme.colors.backgroundDefault,
    ) {
        Column(
            modifier = Modifier.fillMaxWidth().padding(horizontal = Spacing.medium).padding(bottom = Spacing.large),
            verticalArrangement = Arrangement.spacedBy(Spacing.medium),
        ) {
            Text(
                text = stringResource(R.string.network_request_title),
                style = RecitTheme.typography.title50,
                color = RecitTheme.colors.foregroundDefault,
                modifier = Modifier.align(Alignment.CenterHorizontally),
            )
            ReaderCell(user = user, syncState = FirstSyncState.Synced)
            Text(
                text = stringResource(R.string.network_request_explanation, user.username),
                style = RecitTheme.typography.content300,
                color = RecitTheme.colors.foregroundSecondary,
            )
            PrimaryButton(text = stringResource(R.string.network_request_send), onClick = onSend)
            SecondaryButton(
                text = stringResource(R.string.action_cancel),
                onClick = onDismiss,
                modifier = Modifier.fillMaxWidth(),
            )
        }
    }
}

/** Fixed artwork geometry of a shelf card. */
private val ShelfCardWidth: Dp = 260.dp
private const val ShelfCardCovers: Int = 4
