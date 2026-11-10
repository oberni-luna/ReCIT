package studio.lunabee.nouveaurecit.ui.lists

import androidx.compose.animation.Crossfade
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.consumeWindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.PagerState
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.OptimisticRunner
import studio.lunabee.nouveaurecit.data.db.EntityListEntity
import studio.lunabee.nouveaurecit.data.model.EntityListType
import studio.lunabee.nouveaurecit.designsystem.EmptyState
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.ui.common.CapsuleTab
import studio.lunabee.nouveaurecit.ui.common.CapsuleTabs
import studio.lunabee.nouveaurecit.ui.common.Formatting
import studio.lunabee.nouveaurecit.ui.common.ListCard
import studio.lunabee.nouveaurecit.ui.common.LocalMessenger
import studio.lunabee.nouveaurecit.ui.common.Messenger
import studio.lunabee.nouveaurecit.ui.common.RecitTopBar
import studio.lunabee.nouveaurecit.ui.common.recitViewModel
import studio.lunabee.nouveaurecit.ui.navigation.Destination
import studio.lunabee.nouveaurecit.ui.navigation.Navigator

/**
 * `EntityListDetail` + `ListCoverFlowScreen` (iOS feature 0060): a list of works or of authors as one
 * screen in two halves — the cover flow on top, the element facing the reader below: its title and
 * authors, « Mon commentaire », « Retirer de la liste » and the day it was added. Moving to another book
 * cross-fades that block while the covers follow the finger.
 *
 * A friend's list (iOS feature 0064) opens read-only: no « Modifier », no add bar, no « Déplacer », no
 * « Retirer de la liste »; their comment, when they wrote one, reads as text.
 *
 * The screen is two pages, « Livres • 8 » | « Présentation » (iOS features 0073 and 0075, without the
 * lens): see [ListDetailPages].
 *
 * « Modifier » opens the form; the screen leaves by itself when the list stops existing. The « Livres »
 * page of a list of publishers says it is empty, as on iOS; its « Présentation » reads as any other's.
 */
@Composable
fun EntityListScreen(destination: Destination.EntityList, navigator: Navigator) {
    val viewModel: EntityListViewModel = recitViewModel(key = destination.id) {
        EntityListViewModel(destination.id, it.lists, it.entities, it.users.myUserId)
    }
    val state: EntityListViewModel.State by viewModel.state.collectAsStateWithLifecycle()
    var showsForm: Boolean by rememberSaveable { mutableStateOf(false) }
    var showsSearch: Boolean by rememberSaveable { mutableStateOf(false) }
    var showsScanner: Boolean by rememberSaveable { mutableStateOf(false) }
    var isCommentFocused: Boolean by remember { mutableStateOf(false) }
    val list: EntityListEntity? = state.list
    val isAuthor: Boolean = list?.type == EntityListType.Author
    val canAdd: Boolean = list != null && list.type != EntityListType.Publisher && !state.isReadOnly

    // Deleting from the form pops, and so does the list vanishing from Room: leave only once.
    var hasLeft: Boolean by remember { mutableStateOf(false) }
    val leave: () -> Unit = {
        if (!hasLeft) {
            hasLeft = true
            navigator.pop()
        }
    }
    var wasMissing: Boolean by remember { mutableStateOf(true) }
    val isMissing: Boolean = state.isLoaded && state.list == null
    LaunchedEffect(state.isLoaded, isMissing) {
        if (!state.isLoaded) return@LaunchedEffect
        if (ListsPresentation.shouldLeave(wasMissing, isMissing)) leave()
        wasMissing = isMissing
    }

    Scaffold(
        topBar = {
            RecitTopBar(
                title = state.list?.name.orEmpty(),
                onBack = navigator::pop,
                containerColor = RecitTheme.colors.backgroundGrouped,
                actions = {
                    if (state.list != null && !state.isReadOnly) {
                        IconButton(onClick = { showsForm = true }) {
                            Icon(Icons.Default.Edit, contentDescription = stringResource(R.string.action_edit))
                        }
                    }
                },
            )
        },
        containerColor = RecitTheme.colors.backgroundGrouped,
    ) { padding ->
        // Consumed, so that the keyboard's inset under the comment does not count the system bar twice.
        Box(Modifier.fillMaxSize().padding(padding).consumeWindowInsets(padding)) {
            when {
                !state.isLoaded -> Unit
                list == null ->
                    EmptyState(title = stringResource(R.string.list_empty), modifier = Modifier.align(Alignment.Center))
                else -> ListDetailPages(
                    list = list,
                    state = state,
                    viewModel = viewModel,
                    navigator = navigator,
                    canAdd = canAdd,
                    isCommentFocused = isCommentFocused,
                    onCommentFocusChange = { isCommentFocused = it },
                    onScan = { showsScanner = true },
                    onSearch = { showsSearch = true },
                )
            }
        }
    }

    if (showsScanner && list != null) {
        ListScanScreen(
            listName = list.name,
            existingUris = state.rows.map { it.uri }.toSet(),
            onAdd = viewModel::add,
            onShow = viewModel::requestSelection,
            onDismiss = { showsScanner = false },
        )
    }

    if (showsSearch && list != null) {
        ListAddSearchSheet(
            listName = list.name,
            isAuthor = isAuthor,
            existingUris = state.rows.map { it.uri }.toSet(),
            onAdd = viewModel::add,
            onShow = viewModel::requestSelection,
            onDismiss = { showsSearch = false },
        )
    }

    if (showsForm) {
        ListFormSheet(
            listId = destination.id,
            fileWorkUri = null,
            onDismiss = { showsForm = false },
            onDeleted = leave,
        )
    }
}

/**
 * `ListCoverFlowScreen`'s `TabPager`: the tabs pinned under the bar, over two pages side by side, each keeping
 * its own scroll. A swipe on the covers moves the covers; anywhere else on « Livres » it turns the page. The
 * add bar belongs to « Livres » and slides with it; it steps aside while the comment is written, so the
 * keyboard is not topped with two buttons that have nothing to do with typing — and the pager holds still,
 * so the field does not leave with the keyboard up.
 */
@Composable
private fun ListDetailPages(
    list: EntityListEntity,
    state: EntityListViewModel.State,
    viewModel: EntityListViewModel,
    navigator: Navigator,
    canAdd: Boolean,
    isCommentFocused: Boolean,
    onCommentFocusChange: (Boolean) -> Unit,
    onScan: () -> Unit,
    onSearch: () -> Unit,
) {
    val pagerState: PagerState = rememberPagerState { ListDetailTab.entries.size }
    Column(Modifier.fillMaxSize()) {
        CapsuleTabs(
            tabs = listDetailTabs(list.type, if (list.type == EntityListType.Publisher) 0 else state.elementCount),
            pagerState = pagerState,
            modifier = Modifier
                .align(Alignment.CenterHorizontally)
                .padding(top = Spacing.xxSmall, bottom = Spacing.small),
        )
        HorizontalPager(
            state = pagerState,
            modifier = Modifier.weight(1f),
            userScrollEnabled = !isCommentFocused,
            verticalAlignment = Alignment.Top,
        ) { page ->
            when (ListDetailTab.entries[page]) {
                ListDetailTab.Elements -> Column(Modifier.fillMaxSize()) {
                    Box(Modifier.weight(1f).fillMaxWidth()) {
                        if (state.rows.isEmpty() || list.type == EntityListType.Publisher) {
                            EmptyState(title = stringResource(R.string.list_empty), modifier = Modifier.align(Alignment.Center))
                        } else {
                            ListCoverFlowContent(
                                list = list,
                                state = state,
                                viewModel = viewModel,
                                navigator = navigator,
                                isCommentFocused = isCommentFocused,
                                onCommentFocusChange = onCommentFocusChange,
                            )
                        }
                    }
                    if (canAdd && !isCommentFocused) {
                        ListAddBar(isAuthor = list.type == EntityListType.Author, onScan = onScan, onSearch = onSearch)
                    }
                }
                ListDetailTab.Presentation -> ListPresentationPage(list)
            }
        }
    }
}

/** `ListDetailTabPicker`'s words: « Livres • 8 » or « Auteur·ices • 3 », then « Présentation ». */
@Composable
private fun listDetailTabs(type: EntityListType, count: Int): List<CapsuleTab> = ListDetailTab.entries.map { tab ->
    when (tab) {
        ListDetailTab.Elements -> if (type == EntityListType.Author) {
            CapsuleTab(stringResource(R.string.list_tab_authors, count), stringResource(R.string.list_tab_authors_description, count))
        } else {
            CapsuleTab(stringResource(R.string.list_tab_works, count), stringResource(R.string.list_tab_works_description, count))
        }
        ListDetailTab.Presentation -> CapsuleTab(stringResource(R.string.list_tab_presentation))
    }
}

@Composable
private fun ListCoverFlowContent(
    list: EntityListEntity,
    state: EntityListViewModel.State,
    viewModel: EntityListViewModel,
    navigator: Navigator,
    isCommentFocused: Boolean,
    onCommentFocusChange: (Boolean) -> Unit,
) {
    val isAuthor: Boolean = list.type == EntityListType.Author
    val messenger: Messenger = LocalMessenger.current
    val genericError: String = stringResource(R.string.error_generic)
    val movedTo: String = stringResource(R.string.list_detail_moved_to_named)
    val scope: CoroutineScope = rememberCoroutineScope()
    val open: (String) -> Unit = { uri -> navigator.push(if (isAuthor) Destination.Author(uri) else Destination.Work(uri)) }
    LazyColumn(
        modifier = Modifier.fillMaxSize().imePadding(),
        verticalArrangement = Arrangement.spacedBy(Spacing.medium),
    ) {
        item(key = "cover-flow") {
            Column(verticalArrangement = Arrangement.spacedBy(Spacing.small)) {
                ListCoverFlow(
                    rows = state.rows,
                    isAuthor = isAuthor,
                    selectedUri = state.selectedUri,
                    onSelect = viewModel::select,
                    onOpen = open,
                )
                Crossfade(targetState = state.selectedRow, label = "list.title") { row ->
                    if (row != null) ListSelectedTitle(row)
                }
            }
        }
        item(key = "comment") {
            Crossfade(targetState = state.selectedRow?.uri, label = "list.comment") { uri ->
                val row: ListElementRowModel = state.rows.firstOrNull { it.uri == uri } ?: return@Crossfade
                when {
                    !state.isReadOnly -> ListCard {
                        ListCommentField(
                            row = row,
                            isAuthor = isAuthor,
                            onFocusChange = onCommentFocusChange,
                            onSave = { viewModel.updateComment(row, it) },
                        )
                    }
                    row.comment.isNotBlank() -> ListCard { ListReadOnlyComment(row.comment) }
                }
            }
        }
        val selected: ListElementRowModel? = state.selectedRow
        if (selected != null && state.destinations.isNotEmpty()) {
            item(key = "move") {
                // No way to the element's page here: the cover in front opens it.
                ListMoveRow(
                    destinations = state.destinations,
                    isMoving = state.isMoving,
                    enabled = !isCommentFocused && !OptimisticRunner.isOptimistic(selected.elementId),
                    onMove = { destination ->
                        scope.launch {
                            if (viewModel.move(selected, destination) { messenger.showError(genericError, it.localizedMessage) }) {
                                messenger.show(movedTo.format(destination.name))
                            }
                        }
                    },
                )
            }
        }
        item(key = "remove") {
            val row: ListElementRowModel? = state.selectedRow
            Column(verticalArrangement = Arrangement.spacedBy(Spacing.small)) {
                if (!state.isReadOnly) {
                    ListCard(
                        onClick = {
                            if (row != null) {
                                scope.launch { viewModel.remove(row.uri) { messenger.showError(genericError, it.localizedMessage) } }
                            }
                        },
                    ) {
                        Text(stringResource(R.string.list_detail_remove), style = RecitTheme.typography.action300, color = RecitTheme.colors.foregroundError)
                    }
                }
                Crossfade(targetState = row, label = "list.added") { shown ->
                    if (shown != null && shown.created > 0) {
                        Text(
                            stringResource(R.string.list_detail_added, Formatting.longDate(shown.created)),
                            style = RecitTheme.typography.footnote200,
                            color = RecitTheme.colors.foregroundSecondary,
                            textAlign = TextAlign.Center,
                            modifier = Modifier.fillMaxWidth().padding(bottom = Spacing.large),
                        )
                    }
                }
            }
        }
    }
}

/** `ListSelectedTitle`: the element's title, and who wrote it — or what inventaire.io says an author is. */
@Composable
private fun ListSelectedTitle(row: ListElementRowModel) {
    Column(
        modifier = Modifier.fillMaxWidth().padding(horizontal = Spacing.medium),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(Spacing.xxSmall),
    ) {
        Text(row.title, style = RecitTheme.typography.content400Bold, color = RecitTheme.colors.foregroundDefault, textAlign = TextAlign.Center)
        (row.authors ?: row.subtitle)?.takeIf { it.isNotBlank() }?.let {
            Text(it, style = RecitTheme.typography.content300, color = RecitTheme.colors.foregroundSecondary, textAlign = TextAlign.Center)
        }
    }
}
