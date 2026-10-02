package studio.lunabee.nouveaurecit.ui.book

import android.content.Context
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyListScope
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.LibraryBooks
import androidx.compose.material.icons.automirrored.filled.List
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.WifiOff
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.designsystem.EmptyState
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.SectionHeader
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.ui.common.LocalMessenger
import studio.lunabee.nouveaurecit.ui.common.Messenger
import studio.lunabee.nouveaurecit.ui.common.RecitTopBar
import studio.lunabee.nouveaurecit.ui.common.recitViewModel
import studio.lunabee.nouveaurecit.ui.inventory.ShelfFormSheet
import studio.lunabee.nouveaurecit.ui.lists.ListFormSheet
import studio.lunabee.nouveaurecit.ui.navigation.BookAnchor
import studio.lunabee.nouveaurecit.ui.navigation.Destination
import studio.lunabee.nouveaurecit.ui.navigation.Navigator

/**
 * `Features/Book/BookDetailView.swift` (ADR 0002): the unified book screen, for an edition, a copy,
 * or the best edition of a searched work. Borrowing (« Emprunter à ») and the full-screen cover are
 * not ported.
 */
@Composable
fun BookScreen(destination: Destination.Book, navigator: Navigator) {
    BookDetail(anchor = destination.anchor, navigator = navigator)
}

/** The whole book screen — top bar included — so the work gateway can show it inline. */
@Composable
internal fun BookDetail(anchor: BookAnchor, navigator: Navigator) {
    val viewModel: BookViewModel = recitViewModel(key = "book:${anchor.stableId}") { BookViewModel(it, anchor) }
    val state: BookUiState by viewModel.state.collectAsStateWithLifecycle()
    val messenger: Messenger = LocalMessenger.current
    val context: Context = LocalContext.current
    val scope: CoroutineScope = rememberCoroutineScope()
    var confirmsRemoval: Boolean by rememberSaveable { mutableStateOf(false) }
    var createsShelfFor: String? by rememberSaveable { mutableStateOf(null) }
    var createsListFor: String? by rememberSaveable { mutableStateOf(null) }

    Scaffold(
        topBar = {
            RecitTopBar(
                title = "",
                onBack = navigator::pop,
                actions = {
                    if (state.phase is BookPhase.Loaded && state.edition != null) {
                        MoreActionsMenu(
                            bookMenuLines(
                                state = state,
                                context = context,
                                onShelf = { entry ->
                                    viewModel.toggleShelf(entry)
                                    messenger.show(membershipMessage(context, entry))
                                },
                                onNewShelf = { createsShelfFor = state.myItem?.item?.id },
                                onList = { entry ->
                                    scope.launch { if (viewModel.toggleList(entry)) messenger.show(membershipMessage(context, entry)) }
                                },
                                onNewList = { createsListFor = state.singleWorkUri },
                                onRemove = { confirmsRemoval = true },
                                onAdd = {
                                    scope.launch {
                                        when (viewModel.addToInventory()) {
                                            BookViewModel.AddOutcome.Added -> messenger.show(context.getString(R.string.edition_added_to_inventory))
                                            BookViewModel.AddOutcome.NoUser -> messenger.show(context.getString(R.string.edition_error_no_user))
                                            BookViewModel.AddOutcome.Failed -> Unit
                                        }
                                    }
                                },
                            ),
                        )
                    }
                },
            )
        },
        containerColor = RecitTheme.colors.backgroundSecondary,
    ) { padding: PaddingValues ->
        Box(Modifier.fillMaxSize().padding(padding)) {
            when (state.phase) {
                BookPhase.Loading -> BookLoading(viewModel.placeholder)
                BookPhase.Error -> Absence(
                    title = stringResource(R.string.book_resolve_error_title),
                    message = stringResource(R.string.book_resolve_error_message),
                    actionTitle = stringResource(R.string.action_retry),
                    onAction = viewModel::load,
                )
                BookPhase.NoResult -> Absence(
                    title = stringResource(R.string.book_no_edition_title),
                    message = stringResource(R.string.book_no_edition_message),
                )
                is BookPhase.Loaded -> BookContent(state, viewModel, navigator)
            }
        }
    }

    if (confirmsRemoval) {
        AlertDialog(
            onDismissRequest = { confirmsRemoval = false },
            title = { Text(stringResource(R.string.inventory_item_delete_confirm), style = RecitTheme.typography.title50) },
            confirmButton = {
                TextButton(
                    onClick = {
                        confirmsRemoval = false
                        scope.launch {
                            if (viewModel.removeMyItem()) {
                                messenger.show(context.getString(R.string.inventory_item_deleted))
                                navigator.pop()
                            }
                        }
                    },
                ) {
                    Text(stringResource(R.string.inventory_item_remove_from_inventory), color = RecitTheme.colors.foregroundError)
                }
            },
            dismissButton = {
                TextButton(onClick = { confirmsRemoval = false }) {
                    Text(stringResource(R.string.action_cancel), color = RecitTheme.colors.foregroundDefault)
                }
            },
            containerColor = RecitTheme.colors.backgroundDefault,
        )
    }
    createsShelfFor?.let { itemId -> ShelfFormSheet(shelfId = null, fileItemId = itemId, onDismiss = { createsShelfFor = null }) }
    createsListFor?.let { workUri -> ListFormSheet(listId = null, fileWorkUri = workUri, onDismiss = { createsListFor = null }) }
}

/** `BookActions.menuContent`: one menu for my copy, another for somebody else's book. */
private fun bookMenuLines(
    state: BookUiState,
    context: Context,
    onShelf: (MembershipEntry) -> Unit,
    onNewShelf: () -> Unit,
    onList: (MembershipEntry) -> Unit,
    onNewList: () -> Unit,
    onRemove: () -> Unit,
    onAdd: () -> Unit,
): List<MenuLine> {
    val listLine: MenuLine? = state.singleWorkUri?.let { listMenuLine(context, state.myLists, onList, onNewList) }
    return if (state.myItem != null) {
        listOfNotNull(
            MenuLine.Membership(
                label = context.getString(R.string.action_shelf),
                icon = Icons.AutoMirrored.Filled.LibraryBooks,
                entries = state.myShelves,
                creationLabel = context.getString(R.string.action_add_to_new_shelf),
                onToggle = onShelf,
                onCreate = onNewShelf,
            ),
            listLine,
            MenuLine.Action(context.getString(R.string.inventory_item_remove_from_inventory), Icons.Filled.Delete, onRemove),
        )
    } else {
        listOfNotNull(listLine, MenuLine.Action(context.getString(R.string.action_add_to_inventory), Icons.Filled.Add, onAdd))
    }
}

/** `EntityListMenu`: my work lists, each with « Ajouter à » / « Retirer de », then a new one. */
internal fun listMenuLine(
    context: Context,
    entries: List<MembershipEntry>,
    onToggle: (MembershipEntry) -> Unit,
    onCreate: () -> Unit,
): MenuLine = MenuLine.Membership(
    label = context.getString(R.string.action_list),
    icon = Icons.AutoMirrored.Filled.List,
    entries = entries,
    creationLabel = context.getString(R.string.action_add_to_new_list),
    onToggle = onToggle,
    onCreate = onCreate,
)

/** « Ajouté à %s » / « Retiré de %s », said as the write goes out. */
internal fun membershipMessage(context: Context, entry: MembershipEntry): String =
    if (entry.isMember) context.getString(R.string.list_removed_from_named, entry.name) else context.getString(R.string.list_added_to_named, entry.name)

/** `BookResolvingView`: the search result's header already drawn, a spinner under it. */
@Composable
private fun BookLoading(placeholder: BookAnchor.BestEditionOfWork?) {
    if (placeholder == null) {
        Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            CircularProgressIndicator(color = RecitTheme.colors.foregroundSecondary)
        }
        return
    }
    LazyColumn(Modifier.fillMaxSize()) {
        item { EntityHeader(title = placeholder.title, subtitle = null, imageUrl = placeholder.imageUrl) }
        item { LoadingCell() }
    }
}

/** `BookAbsenceView`: the failed call (with « Réessayer ») and the work without an edition. */
@Composable
internal fun Absence(title: String, message: String, actionTitle: String? = null, onAction: (() -> Unit)? = null) {
    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        EmptyState(
            title = title,
            message = message,
            icon = if (onAction != null) Icons.Filled.WifiOff else Icons.AutoMirrored.Filled.LibraryBooks,
            actionTitle = actionTitle,
            onAction = onAction,
        )
    }
}

@Composable
private fun BookContent(state: BookUiState, viewModel: BookViewModel, navigator: Navigator) {
    val edition = state.edition ?: return
    LazyColumn(Modifier.fillMaxSize()) {
        item(key = "header") { EntityHeader(title = edition.title, subtitle = edition.subtitle, imageUrl = edition.image) }
        item(key = "summary") { SummaryRow(state.summary) }
        item(key = "authors") { AuthorsRow(state.authors) { navigator.push(Destination.Author(it)) } }
        otherEditions(state, navigator)
        community(state, navigator)
        myCopy(state, viewModel)
    }
}

private fun LazyListScope.otherEditions(state: BookUiState, navigator: Navigator) {
    if (state.worksWithOtherEditions.isEmpty()) return
    item(key = "other-editions-gap") { Spacer(Modifier.height(Spacing.large)) }
    items(state.worksWithOtherEditions, key = { "work:${it.uri}" }) { work ->
        OtherEditionsRow(work) { navigator.push(Destination.Work(work.uri)) }
    }
}

private fun LazyListScope.community(state: BookUiState, navigator: Navigator) {
    if (state.othersItems.isEmpty()) return
    item(key = "community-header") { SectionHeader(title = stringResource(R.string.nav_community)) }
    items(state.othersItems, key = { "item:${it.item.id}" }) { row ->
        CommunityItemRow(row) { navigator.push(Destination.User(row.item.ownerId)) }
    }
}

private fun LazyListScope.myCopy(state: BookUiState, viewModel: BookViewModel) {
    val mine = state.myItem ?: return
    item(key = "mine-header") { SectionHeader(title = stringResource(R.string.edition_my_inventory)) }
    item(key = "mine-notes:${mine.item.id}") { MyNotesCell(mine) { viewModel.commitNotes(mine.item.id, it) } }
    item(key = "mine-details:${mine.item.id}") { MyCopyDetailsCell(mine) { viewModel.updateTransaction(mine.item.id, it) } }
}

/** `BookAnchor.stableId`: the same book is one entry however it was labelled. */
internal val BookAnchor.stableId: String
    get() = when (this) {
        is BookAnchor.Edition -> "edition:$uri"
        is BookAnchor.Item -> "item:$itemId"
        is BookAnchor.BestEditionOfWork -> "work:$uri"
    }
