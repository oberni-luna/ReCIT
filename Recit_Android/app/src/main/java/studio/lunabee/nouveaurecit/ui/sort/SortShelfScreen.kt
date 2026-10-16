package studio.lunabee.nouveaurecit.ui.sort

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Outbox
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SwipeToDismissBox
import androidx.compose.material3.SwipeToDismissBoxState
import androidx.compose.material3.SwipeToDismissBoxValue
import androidx.compose.material3.Text
import androidx.compose.material3.rememberSwipeToDismissBoxState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextOverflow
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import studio.lunabee.nouveaurecit.AppContainer
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.sorting.SortBook
import studio.lunabee.nouveaurecit.data.sorting.SortSection
import studio.lunabee.nouveaurecit.data.sorting.SortSectionId
import studio.lunabee.nouveaurecit.data.sorting.SortSession
import studio.lunabee.nouveaurecit.data.sorting.SortSessionState
import studio.lunabee.nouveaurecit.designsystem.CellThumbnail
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.designsystem.ThumbnailSize
import studio.lunabee.nouveaurecit.ui.common.LocalAppContainer
import studio.lunabee.nouveaurecit.ui.common.RecitTopBar

/**
 * `SortShelfDetailView` (feature 0010): an étagère as it *will* be — drafts and pending books
 * included — read from the session, not from Room. A swipe takes a book back off it, which only
 * changes the stack; nothing is written. The screen pops itself when its section leaves the
 * projection: after a discard, or once a draft lands under its server id.
 */
@Composable
fun SortShelfScreen(sectionId: SortSectionId, onBack: () -> Unit) {
    val container: AppContainer = LocalAppContainer.current
    val session: SortSession = container.sortSession
    val state: SortSessionState by session.state.collectAsStateWithLifecycle()
    val section: SortSection? = state.projection.sections.firstOrNull { it.id == sectionId }

    LaunchedEffect(section == null) {
        if (section == null) onBack()
    }

    Scaffold(
        topBar = { RecitTopBar(title = section?.name.orEmpty(), onBack = onBack) },
        containerColor = RecitTheme.colors.backgroundDefault,
    ) { padding ->
        val books: List<SortBook> = section?.books.orEmpty()
        LazyColumn(Modifier.fillMaxSize().padding(padding)) {
            if (books.isEmpty()) {
                item(key = "empty") {
                    Text(
                        text = stringResource(R.string.sort_shelf_detail_empty),
                        style = RecitTheme.typography.content300,
                        color = RecitTheme.colors.foregroundSecondary,
                        modifier = Modifier.padding(Spacing.medium),
                    )
                }
            }
            items(books, key = { it.id }) { book ->
                RemovableBookRow(
                    book = book,
                    shelfName = section?.name.orEmpty(),
                    enabled = !state.isBusy,
                    onRemove = {
                        // Re-read from the session: a list can re-diff under its own swipe and fire twice.
                        if (session.state.value.sectionHolding(book.id) == sectionId) {
                            session.moveBook(book.id, SortSectionId.Unshelved)
                        }
                    },
                )
                HorizontalDivider(Modifier.padding(start = Spacing.medium), color = RecitTheme.colors.borderDefault)
            }
            if (books.isNotEmpty()) {
                item(key = "hint") {
                    Text(
                        text = stringResource(R.string.sort_shelf_detail_swipe_hint),
                        style = RecitTheme.typography.footnote200,
                        color = RecitTheme.colors.foregroundSecondary,
                        modifier = Modifier.padding(Spacing.medium).navigationBarsPadding(),
                    )
                }
            }
        }
    }
}

/** `.swipeActions(edge: .trailing, allowsFullSwipe: true)` — « Retirer de %@ », not destructive. */
@Composable
private fun RemovableBookRow(book: SortBook, shelfName: String, enabled: Boolean, onRemove: () -> Unit) {
    val dismissState: SwipeToDismissBoxState = rememberSwipeToDismissBoxState()
    SwipeToDismissBox(
        state = dismissState,
        enableDismissFromStartToEnd = false,
        enableDismissFromEndToStart = enabled,
        onDismiss = { value -> if (value == SwipeToDismissBoxValue.EndToStart) onRemove() },
        backgroundContent = {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(RecitTheme.colors.backgroundTintedInverse)
                    .padding(horizontal = Spacing.medium),
                contentAlignment = Alignment.CenterEnd,
            ) {
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(Spacing.small)) {
                    Icon(Icons.Outlined.Outbox, contentDescription = null, tint = RecitTheme.colors.foregroundTintedInverse)
                    Text(
                        text = stringResource(R.string.shelf_remove_from_named, shelfName),
                        style = RecitTheme.typography.action200,
                        color = RecitTheme.colors.foregroundTintedInverse,
                    )
                }
            }
        },
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .background(RecitTheme.colors.backgroundDefault)
                .padding(horizontal = Spacing.medium, vertical = Spacing.small),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(Spacing.sMedium),
        ) {
            CellThumbnail(url = book.coverImageUrl, size = ThumbnailSize.Small)
            Column(Modifier.weight(1f)) {
                Text(book.title, style = RecitTheme.typography.content300, color = RecitTheme.colors.foregroundDefault, maxLines = 2, overflow = TextOverflow.Ellipsis)
                if (book.authors.isNotEmpty()) {
                    Text(book.authors, style = RecitTheme.typography.footnote200, color = RecitTheme.colors.foregroundSecondary, maxLines = 1, overflow = TextOverflow.Ellipsis)
                }
            }
        }
    }
}
