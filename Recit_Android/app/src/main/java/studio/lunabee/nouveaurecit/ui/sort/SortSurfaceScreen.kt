package studio.lunabee.nouveaurecit.ui.sort

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.GridItemSpan
import androidx.compose.foundation.lazy.grid.LazyGridState
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.grid.rememberLazyGridState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshotFlow
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.hapticfeedback.HapticFeedback
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.layout.onGloballyPositioned
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.layout.positionInRoot
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.filterNotNull
import kotlinx.coroutines.launch
import studio.lunabee.nouveaurecit.AppContainer
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.sorting.SortBook
import studio.lunabee.nouveaurecit.data.sorting.SortGridMetrics
import studio.lunabee.nouveaurecit.data.sorting.SortLeaveConfirmation
import studio.lunabee.nouveaurecit.data.sorting.SortSection
import studio.lunabee.nouveaurecit.data.sorting.SortSectionId
import studio.lunabee.nouveaurecit.data.sorting.SortSession
import studio.lunabee.nouveaurecit.data.sorting.SortSessionState
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.designsystem.SyncingPlaceholder
import studio.lunabee.nouveaurecit.ui.common.LocalAppContainer
import studio.lunabee.nouveaurecit.ui.common.RecitTopBar
import kotlin.math.roundToInt

/** Per device, like the Profil's dismissed tag: about how the app behaves, not about an account (feature 0032). */
const val SORT_LEAVE_ACKNOWLEDGED_KEY: String = "sort.leaveWithoutSaving.acknowledged"

/**
 * `ManualSortView` (features 0010 and 0032): every étagère as a card on a scrolling grid, the books
 * on no étagère anchored beneath, and nothing written until « Enregistrer ». The session is
 * app-scoped ([SortSession]), so the close cross steps out and keeps the draft; it asks
 * « Quitter sans enregistrer ? » over unsaved changes, until answered « Quitter » once.
 *
 * The projection and the plan are read once per state, here, and values go down.
 */
@Composable
fun SortSurfaceScreen(onClose: () -> Unit, onOpenSection: (SortSectionId) -> Unit) {
    val container: AppContainer = LocalAppContainer.current
    val session: SortSession = container.sortSession
    val state: SortSessionState by session.state.collectAsStateWithLifecycle()
    val isAcknowledged: Boolean by container.preferences.observeBoolean(SORT_LEAVE_ACKNOWLEDGED_KEY)
        .collectAsStateWithLifecycle(initialValue = false)
    val scope: CoroutineScope = rememberCoroutineScope()
    val haptics: HapticFeedback = LocalHapticFeedback.current
    val dragState: SortDragState = remember { SortDragState() }
    val gridState: LazyGridState = rememberLazyGridState()
    var confirmsLeave: Boolean by rememberSaveable { mutableStateOf(false) }
    var confirmsDiscard: Boolean by rememberSaveable { mutableStateOf(false) }
    var createsShelf: Boolean by rememberSaveable { mutableStateOf(false) }
    // The book dropped on « + », held until the étagère is named; nothing is recorded before.
    var bookAwaitingNewShelf: String? by rememberSaveable { mutableStateOf(null) }

    LaunchedEffect(session) { session.load() }
    // A soft tick as a carried book enters a target, not on every move inside it.
    LaunchedEffect(dragState) {
        snapshotFlow { dragState.hovered }.distinctUntilChanged().filterNotNull().collect {
            haptics.performHapticFeedback(HapticFeedbackType.SegmentTick)
        }
    }

    val close: () -> Unit = {
        if (SortLeaveConfirmation.isNeeded(state.hasPendingChanges, state.isApplying, isAcknowledged)) confirmsLeave = true else onClose()
    }
    BackHandler(onBack = close)

    // Every drop and every « Ranger dans… » lands here: a move to where the book already is records nothing.
    val file: (String, SortSectionId) -> Unit = { bookId, destination ->
        if (!state.isBusy && state.sectionHolding(bookId) != null && state.sectionHolding(bookId) != destination) {
            session.moveBook(bookId, destination)
            haptics.performHapticFeedback(HapticFeedbackType.Confirm)
        }
    }
    val onDrop: (SortBook, SortDropKey) -> Unit = { book, target ->
        when (target) {
            is SortDropKey.Section -> file(book.id, target.id)
            SortDropKey.NewShelf -> {
                bookAwaitingNewShelf = book.id
                createsShelf = true
            }
        }
    }

    CompositionLocalProvider(LocalSortDragState provides dragState) {
        Box(Modifier.fillMaxSize()) {
            Scaffold(
                topBar = {
                    RecitTopBar(
                        title = stringResource(R.string.sort_title),
                        onBack = null,
                        navigationIcon = {
                            IconButton(onClick = close) {
                                Icon(Icons.Default.Close, contentDescription = stringResource(R.string.action_close))
                            }
                        },
                    )
                },
                containerColor = RecitTheme.colors.backgroundDefault,
            ) { padding ->
                if (state.phase == SortSessionState.Phase.Syncing) {
                    SyncingPlaceholder(message = stringResource(R.string.sort_syncing), modifier = Modifier.padding(padding))
                    return@Scaffold
                }
                SortSurfaceContent(
                    state = state,
                    gridState = gridState,
                    modifier = Modifier.padding(top = padding.calculateTopPadding()),
                    onOpenSection = onOpenSection,
                    onDrop = onDrop,
                    onFile = { book, destination -> file(book.id, destination) },
                    onCreateShelf = { bookId ->
                        bookAwaitingNewShelf = bookId
                        createsShelf = true
                    },
                    onDiscard = {
                        if (state.changes.size <= 1) session.discardChanges() else confirmsDiscard = true
                    },
                    onApply = session::apply,
                )
            }
            DraggedCover(dragState)
        }
    }

    if (createsShelf) {
        SortNewShelfDialog(
            nameRule = state.draftNameRule,
            onCreate = { name ->
                session.createShelf(named = name, filling = bookAwaitingNewShelf)
                bookAwaitingNewShelf = null
                createsShelf = false
                // The new étagère is the last card, just before the tile: bring it into view.
                scope.launch { gridState.animateScrollToItem(maxOf(0, gridState.layoutInfo.totalItemsCount - 1)) }
            },
            onDismiss = {
                bookAwaitingNewShelf = null
                createsShelf = false
            },
        )
    }
    if (confirmsDiscard) {
        AlertDialog(
            onDismissRequest = { confirmsDiscard = false },
            title = { Text(stringResource(R.string.sort_discard_confirm_title)) },
            confirmButton = {
                TextButton(
                    onClick = {
                        confirmsDiscard = false
                        session.discardChanges()
                    },
                ) { Text(stringResource(R.string.sort_discard_confirm_action), color = RecitTheme.colors.foregroundError) }
            },
            dismissButton = {
                TextButton(onClick = { confirmsDiscard = false }) { Text(stringResource(R.string.action_cancel)) }
            },
        )
    }
    if (confirmsLeave) {
        // Not styled destructive: closing keeps the draft, and the message says so.
        AlertDialog(
            onDismissRequest = { confirmsLeave = false },
            title = { Text(stringResource(R.string.sort_leave_confirm_title)) },
            text = { Text(stringResource(R.string.sort_leave_confirm_message)) },
            confirmButton = {
                TextButton(
                    onClick = {
                        confirmsLeave = false
                        container.applicationScope.launch { container.preferences.setBoolean(SORT_LEAVE_ACKNOWLEDGED_KEY, true) }
                        onClose()
                    },
                ) { Text(stringResource(R.string.sort_leave_confirm_action)) }
            },
            dismissButton = {
                TextButton(onClick = { confirmsLeave = false }) { Text(stringResource(R.string.action_cancel)) }
            },
        )
    }
}

@Composable
private fun SortSurfaceContent(
    state: SortSessionState,
    gridState: LazyGridState,
    modifier: Modifier,
    onOpenSection: (SortSectionId) -> Unit,
    onDrop: (SortBook, SortDropKey) -> Unit,
    onFile: (SortBook, SortSectionId) -> Unit,
    onCreateShelf: (String?) -> Unit,
    onDiscard: () -> Unit,
    onApply: () -> Unit,
) {
    val density: Density = LocalDensity.current
    var panelHeight: Int by remember { mutableIntStateOf(0) }
    val shelves: List<SortSection> = state.projection.sections.filter { !it.isUnshelved }
    val filingOptions: List<SortFilingOption> = shelves.map { SortFilingOption(it.id, it.name.orEmpty()) }

    BoxWithConstraints(modifier.fillMaxSize()) {
        val metrics = SortGridMetrics(maxWidth.value)
        val columns: Int = SortGridMetrics.columnCount(shelves.size)
        val cardWidth: Dp = metrics.shelfColumnWidth(columns).dp
        val panelHeightDp: Dp = with(density) { panelHeight.toDp() }

        // The grid scrolls *underneath* the panel and dissolves into it, so nothing is cut off on a line.
        LazyVerticalGrid(
            columns = GridCells.Fixed(columns),
            state = gridState,
            contentPadding = PaddingValues(
                start = SortGridMetrics.SHELF_SPACING.dp,
                end = SortGridMetrics.SHELF_SPACING.dp,
                bottom = panelHeightDp + SortGridMetrics.SHELF_SPACING.dp,
            ),
            horizontalArrangement = Arrangement.spacedBy(SortGridMetrics.SHELF_SPACING.dp),
            verticalArrangement = Arrangement.spacedBy(SortGridMetrics.SHELF_SPACING.dp),
            modifier = Modifier.fillMaxSize(),
        ) {
            item(key = "header", span = { GridItemSpan(maxLineSpan) }) {
                Text(
                    text = stringResource(R.string.sort_shelves_header),
                    style = RecitTheme.typography.action200,
                    color = RecitTheme.colors.foregroundDefault,
                    modifier = Modifier.padding(top = Spacing.medium),
                )
            }
            items(shelves, key = { SortSessionState.ledgerKey(it.id) }) { section ->
                SortShelfCard(
                    section = section,
                    status = state.writePlan.status(section.id),
                    outcome = state.applyOutcome(section.id),
                    isApplying = state.isApplying,
                    width = cardWidth,
                    onOpen = { onOpenSection(section.id) },
                    onDrop = onDrop,
                    onUnshelve = { book -> onFile(book, SortSectionId.Unshelved) },
                )
            }
            item(key = "newShelf") {
                SortNewShelfTile(width = cardWidth, enabled = !state.isBusy, onClick = { onCreateShelf(null) })
            }
        }

        SortUnshelvedPanel(
            unshelved = state.projection.unshelved,
            bookColumnWidth = metrics.bookColumnWidth.dp,
            filingOptions = filingOptions,
            footer = state.footer,
            hasPendingChanges = state.hasPendingChanges,
            isApplying = state.isApplying,
            onDrop = onDrop,
            onFile = onFile,
            onFileIntoNewShelf = { book -> onCreateShelf(book.id) },
            onDiscard = onDiscard,
            onApply = onApply,
            modifier = Modifier.align(Alignment.BottomCenter).onSizeChanged { panelHeight = it.height },
        )
    }
}

/** The cover the finger carries, drawn over everything, square and whole. */
@Composable
private fun DraggedCover(dragState: SortDragState) {
    val book: SortBook = dragState.dragged ?: return
    val density: Density = LocalDensity.current
    var origin: Offset by remember { mutableStateOf(Offset.Zero) }
    Box(Modifier.fillMaxSize().onGloballyPositioned { origin = it.positionInRoot() }) {
        val width: Dp = with(density) { dragState.coverSize.width.toDp() }
        val height: Dp = with(density) { dragState.coverSize.height.toDp() }
        SortCover(
            book = book,
            width = width,
            height = height,
            modifier = Modifier
                .offset {
                    val topLeft: Offset = dragState.pointer - dragState.grabOffset - origin
                    IntOffset(topLeft.x.roundToInt(), topLeft.y.roundToInt())
                }
                .shadow(elevation = 8.dp),
        )
    }
}
