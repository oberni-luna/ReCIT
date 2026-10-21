package studio.lunabee.nouveaurecit.ui.search

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyListScope
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.MenuBook
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.outlined.HistoryEdu
import androidx.compose.material.icons.outlined.Schedule
import androidx.compose.material.icons.outlined.WifiOff
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.SearchResult
import studio.lunabee.nouveaurecit.data.db.ItemRow
import studio.lunabee.nouveaurecit.designsystem.CellThumbnail
import studio.lunabee.nouveaurecit.designsystem.CornerRadius
import studio.lunabee.nouveaurecit.designsystem.EmptyState
import studio.lunabee.nouveaurecit.designsystem.RecitColors
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.SectionHeader
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.designsystem.SyncingInlineRow
import studio.lunabee.nouveaurecit.designsystem.ThumbnailShape
import studio.lunabee.nouveaurecit.designsystem.ThumbnailSize
import studio.lunabee.nouveaurecit.designsystem.TintedTextButton
import studio.lunabee.nouveaurecit.ui.common.InventoryItemRow
import studio.lunabee.nouveaurecit.ui.navigation.BookAnchor
import studio.lunabee.nouveaurecit.ui.navigation.Destination

/**
 * `SearchContent` (features 0014, 0037): what the Recherche tab shows for each [SearchPhase] — at
 * rest the recents and « Chez mes amis », then the local matches, the three suggestions, and
 * inventaire.io's results.
 *
 * Every section but « Chez mes amis » is an inset-grouped card on [RecitColors.backgroundGrouped]
 * (feature 0039); the carousel runs edge to edge on the list's own background.
 *
 * The empty recent-searches state only shows when there is nothing else: with the carousel or its
 * invitation on screen, a rest state saying "nothing here" would contradict itself.
 */
@Composable
internal fun SearchContent(
    phase: SearchPhase,
    recents: List<String>,
    allItems: List<ItemRow>,
    myUserId: String,
    friends: FriendsCarouselState,
    friendsItems: List<ItemRow>,
    remoteState: RemoteSearchState,
    onSelectRecent: (String) -> Unit,
    onClearRecents: () -> Unit,
    onSuggestion: (SearchSuggestion) -> Unit,
    onRetry: () -> Unit,
    onInvite: () -> Unit,
    onPush: (Destination) -> Unit,
) {
    val shownRecents: List<String> = if (phase == SearchPhase.Recents) recents else emptyList()
    if (phase == SearchPhase.Recents && shownRecents.isEmpty() && friends == FriendsCarouselState.Hidden) {
        Box(Modifier.fillMaxSize().background(RecitTheme.colors.backgroundGrouped), contentAlignment = Alignment.Center) {
            EmptyState(
                title = stringResource(R.string.inventory_search_recents_empty_title),
                message = stringResource(R.string.inventory_search_recents_empty_message),
                icon = Icons.Default.Search,
            )
        }
        return
    }
    val localQuery: String? = phase.localQuery
    val local: InventorySearchRanking.ItemOutcome? = remember(allItems, localQuery, myUserId) {
        localQuery?.let { InventorySearchRanking.rankItems(allItems, it, myUserId) }
    }
    PullToRefreshBox(
        isRefreshing = false,
        onRefresh = onRetry,
        modifier = Modifier.fillMaxSize().background(RecitTheme.colors.backgroundGrouped),
    ) {
        LazyColumn(Modifier.fillMaxSize()) {
            if (shownRecents.isNotEmpty()) {
                item(key = "recents.header") {
                    SectionHeader(
                        title = stringResource(R.string.inventory_search_recents_section),
                        modifier = Modifier.padding(horizontal = Spacing.medium),
                        trailing = { TintedTextButton(text = stringResource(R.string.inventory_search_recents_clear), onClick = onClearRecents) },
                    )
                }
                itemsIndexed(shownRecents, key = { _, recent -> "recent.$recent" }) { index, recent ->
                    SearchQueryRow(
                        icon = Icons.Outlined.Schedule,
                        label = AnnotatedString(recent),
                        onClick = { onSelectRecent(recent) },
                        modifier = Modifier.groupedCell(index, shownRecents.size, RecitTheme.colors.backgroundGroupedCell),
                    )
                }
            }
            searchFriendsSection(state = friends, items = friendsItems, onInvite = onInvite, onPush = onPush)
            if (local != null && localQuery != null && local.items.isNotEmpty()) {
                item(key = "local.header") {
                    SectionHeader(
                        title = stringResource(R.string.inventory_search_local_section),
                        modifier = Modifier.padding(horizontal = Spacing.medium),
                        trailing = if (local.totalCount > InventorySearchRanking.DISPLAY_LIMIT) {
                            {
                                TintedTextButton(
                                    text = stringResource(R.string.inventory_search_see_all),
                                    onClick = { onPush(Destination.LocalSearchResults(localQuery)) },
                                )
                            }
                        } else {
                            null
                        }
                    )
                }
                itemsIndexed(local.items, key = { _, row -> "local.${row.item.id}" }) { index, row ->
                    Column(Modifier.groupedCell(index, local.items.size, RecitTheme.colors.backgroundGroupedCell)) {
                        InventoryItemRow(
                            row = row,
                            showsOwner = row.item.ownerId != myUserId,
                            onClick = { onPush(Destination.Book(BookAnchor.Item(row.item.id))) },
                        )
                        if (index < local.items.lastIndex) {
                            HorizontalDivider(Modifier.padding(start = Spacing.medium), color = RecitTheme.colors.borderDefault)
                        }
                    }
                }
            }
            if (phase is SearchPhase.Suggesting) {
                suggestions(phase.query, onSuggestion)
            }
            if (phase is SearchPhase.Results) {
                remote(remoteState, phase.query, onRetry, onPush)
            }
        }
    }
}

private fun LazyListScope.suggestions(query: String, onSuggestion: (SearchSuggestion) -> Unit) {
    val suggestions: List<SearchSuggestion> = SearchSuggestion.suggestions(query)
    if (suggestions.isEmpty()) return
    item(key = "suggestions.header") {
        SectionHeader(title = stringResource(R.string.inventory_search_remote_section), modifier = Modifier.padding(horizontal = Spacing.medium))
    }
    itemsIndexed(suggestions, key = { _, suggestion -> "suggestion.${suggestion.kind}" }) { index, suggestion ->
        val sentence: String = when (suggestion.kind) {
            SearchSuggestion.Kind.Works -> stringResource(R.string.inventory_search_suggestion_works, suggestion.query)
            SearchSuggestion.Kind.Humans -> stringResource(R.string.inventory_search_suggestion_humans, suggestion.query)
            SearchSuggestion.Kind.Everything -> suggestion.query
        }
        val spoken: String = when (suggestion.kind) {
            SearchSuggestion.Kind.Everything -> stringResource(R.string.inventory_search_suggestion_everything, suggestion.query)
            else -> sentence
        }
        SearchQueryRow(
            icon = when (suggestion.kind) {
                SearchSuggestion.Kind.Works -> Icons.AutoMirrored.Outlined.MenuBook
                SearchSuggestion.Kind.Humans -> Icons.Outlined.HistoryEdu
                SearchSuggestion.Kind.Everything -> Icons.Default.Search
            },
            label = emphasised(suggestion.query, sentence),
            spokenLabel = spoken,
            onClick = { onSuggestion(suggestion) },
            modifier = Modifier.groupedCell(index, suggestions.size, RecitTheme.colors.backgroundGroupedCell),
        )
    }
}

private fun LazyListScope.remote(
    state: RemoteSearchState,
    query: String,
    onRetry: () -> Unit,
    onPush: (Destination) -> Unit,
) {
    when (state.sign) {
        RemoteSearchState.Sign.Loading -> item(key = "remote.loading") {
            SyncingInlineRow(
                message = stringResource(R.string.inventory_search_loading),
                modifier = Modifier.padding(horizontal = Spacing.medium, vertical = Spacing.small),
            )
        }
        RemoteSearchState.Sign.NoResult -> item(key = "remote.empty") {
            EmptyState(
                title = stringResource(R.string.inventory_search_results_empty_title),
                message = stringResource(R.string.inventory_search_results_empty_message, query),
                icon = Icons.Default.Search,
                modifier = Modifier.fillMaxWidth().padding(vertical = Spacing.large),
            )
        }
        RemoteSearchState.Sign.Failure -> item(key = "remote.failure") {
            EmptyState(
                title = stringResource(R.string.inventory_search_error_title),
                message = stringResource(R.string.inventory_search_error_message),
                icon = Icons.Outlined.WifiOff,
                actionTitle = stringResource(R.string.inventory_search_error_retry),
                onAction = onRetry,
                modifier = Modifier.fillMaxWidth().padding(vertical = Spacing.large),
            )
        }
        null -> {
            val works: List<SearchResult> = state.results.filter { it.type == SearchResult.Type.Works }
            val humans: List<SearchResult> = state.results.filter { it.type == SearchResult.Type.Humans }
            resultGroup("works", R.string.inventory_search_results_works, works, onPush)
            resultGroup("humans", R.string.inventory_search_results_humans, humans, onPush)
        }
    }
}

private fun LazyListScope.resultGroup(
    key: String,
    title: Int,
    results: List<SearchResult>,
    onPush: (Destination) -> Unit,
) {
    if (results.isEmpty()) return
    item(key = "results.$key.header") {
        SectionHeader(title = stringResource(title, results.size), modifier = Modifier.padding(horizontal = Spacing.medium))
    }
    itemsIndexed(results, key = { _, result -> "result.$key.${result.id}" }) { index, result ->
        SearchResultRow(
            result = result,
            onClick = { onPush(destinationFor(result)) },
            modifier = Modifier.groupedCell(index, results.size, RecitTheme.colors.backgroundGroupedCell),
        )
    }
}

private fun destinationFor(result: SearchResult): Destination = when (result.type) {
    SearchResult.Type.Works -> Destination.Book(BookAnchor.BestEditionOfWork(result.uri, result.label, result.image))
    SearchResult.Type.Humans -> Destination.Author(result.uri)
}

/** `SearchResultCell`: a work's portrait cover or an author's round portrait, the label and the description. */
@Composable
private fun SearchResultRow(result: SearchResult, onClick: () -> Unit, modifier: Modifier = Modifier) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(horizontal = Spacing.medium, vertical = Spacing.sMedium),
        horizontalArrangement = Arrangement.spacedBy(Spacing.sMedium),
        verticalAlignment = Alignment.Top,
    ) {
        CellThumbnail(
            url = result.image,
            size = ThumbnailSize.Small,
            shape = if (result.type == SearchResult.Type.Humans) ThumbnailShape.Circle else ThumbnailShape.Portrait,
        )
        Column(verticalArrangement = Arrangement.spacedBy(Spacing.xSmall)) {
            Text(result.label, style = RecitTheme.typography.content400Bold, color = RecitTheme.colors.foregroundDefault)
            result.description?.takeIf { it.isNotBlank() }?.let {
                Text(it, style = RecitTheme.typography.content300, color = RecitTheme.colors.foregroundSecondary)
            }
        }
    }
}

/** `SearchQueryRow`: a 24-wide tinted glyph and a content300 label. */
@Composable
private fun SearchQueryRow(
    icon: ImageVector,
    label: AnnotatedString,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    spokenLabel: String? = null,
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(horizontal = Spacing.medium, vertical = Spacing.sMedium)
            .then(if (spokenLabel != null) Modifier.semantics(mergeDescendants = true) { contentDescription = spokenLabel } else Modifier),
        horizontalArrangement = Arrangement.spacedBy(Spacing.sMedium),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(icon, contentDescription = null, tint = RecitTheme.colors.foregroundTinted, modifier = Modifier.width(24.dp))
        Text(label, style = RecitTheme.typography.content300, color = RecitTheme.colors.foregroundDefault)
    }
}

/** The sentence with the query in bold inside it; the bare query is bold end to end. */
private fun emphasised(query: String, sentence: String): AnnotatedString = buildAnnotatedString {
    append(sentence)
    SearchSuggestion.emphasisRange(query, sentence)?.let { range ->
        addStyle(SpanStyle(fontWeight = FontWeight.Bold), range.first, range.last + 1)
    }
}

/**
 * One row of an inset-grouped section (feature 0039): the cell colour, inset by the screen's margin,
 * rounded at the section's two ends — so the section reads as one card on the list's background.
 */
private fun Modifier.groupedCell(index: Int, count: Int, color: Color): Modifier {
    val radius = CornerRadius.rounded
    val shape = RoundedCornerShape(
        topStart = if (index == 0) radius else CornerRadius.none,
        topEnd = if (index == 0) radius else CornerRadius.none,
        bottomStart = if (index == count - 1) radius else CornerRadius.none,
        bottomEnd = if (index == count - 1) radius else CornerRadius.none,
    )
    return padding(horizontal = Spacing.medium).clip(shape).background(color)
}
