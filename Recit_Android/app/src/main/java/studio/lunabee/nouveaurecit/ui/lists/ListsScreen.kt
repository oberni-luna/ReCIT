package studio.lunabee.nouveaurecit.ui.lists

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.List
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.TopAppBarScrollBehavior
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.res.pluralStringResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.model.EntityListType
import studio.lunabee.nouveaurecit.designsystem.CellThumbnail
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.ShelfPalette
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.designsystem.SyncingPlaceholder
import studio.lunabee.nouveaurecit.designsystem.ThumbnailShape
import studio.lunabee.nouveaurecit.designsystem.ThumbnailSize
import studio.lunabee.nouveaurecit.designsystem.shelfPaper
import studio.lunabee.nouveaurecit.ui.common.LocalMessenger
import studio.lunabee.nouveaurecit.ui.common.Messenger
import studio.lunabee.nouveaurecit.ui.common.RecitLargeTopBar
import studio.lunabee.nouveaurecit.ui.common.recitViewModel
import studio.lunabee.nouveaurecit.ui.navigation.Destination
import studio.lunabee.nouveaurecit.ui.navigation.Navigator

/**
 * `EntityListView` — the Listes tab: the placeholder until the first lists sync, the empty state of
 * feature 0022 (`ListsEmptyStateView`), or the lists by name with their covers (feature 0024),
 * filtered by the search field, swiped to delete, pulled to refresh.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ListsScreen(navigator: Navigator) {
    val viewModel: ListsViewModel = recitViewModel { ListsViewModel(it.lists, it.entities, it.session, it.syncStatus) }
    val hasSynced: Boolean by viewModel.hasSynced.collectAsState()
    val hasNoList: Boolean by viewModel.hasNoList.collectAsState()
    val rows: List<ListRowModel> by viewModel.rows.collectAsState()
    val query: String by viewModel.query.collectAsState()
    val isRefreshing: Boolean by viewModel.isRefreshing.collectAsState()
    var showsForm: Boolean by rememberSaveable { mutableStateOf(false) }
    val scrollBehavior: TopAppBarScrollBehavior = TopAppBarDefaults.exitUntilCollapsedScrollBehavior()
    val messenger: Messenger = LocalMessenger.current
    val genericError: String = stringResource(R.string.error_generic)

    Scaffold(
        modifier = Modifier.nestedScroll(scrollBehavior.nestedScrollConnection),
        topBar = {
            RecitLargeTopBar(
                title = stringResource(R.string.nav_lists),
                scrollBehavior = scrollBehavior,
                actions = {
                    IconButton(onClick = { showsForm = true }) {
                        Icon(Icons.Default.Add, contentDescription = stringResource(R.string.action_add))
                    }
                },
            )
        },
        containerColor = RecitTheme.colors.backgroundSecondary,
    ) { padding ->
        PullToRefreshBox(
            isRefreshing = isRefreshing,
            onRefresh = viewModel::refresh,
            modifier = Modifier.fillMaxSize().padding(padding),
        ) {
            when {
                !hasSynced -> SyncingPlaceholder(message = stringResource(R.string.sync_loading))
                hasNoList && query.isEmpty() -> ListsEmptyState(onCreate = { showsForm = true })
                else -> LazyColumn(modifier = Modifier.fillMaxSize()) {
                    item(key = "search") {
                        ListsSearchField(query = query, onQueryChange = viewModel::setQuery)
                    }
                    items(rows, key = { it.id }) { row ->
                        SwipeToDeleteRow(
                            key = row.id,
                            onDelete = { viewModel.deleteList(row.id) { messenger.showError(genericError, it.localizedMessage) } },
                            modifier = Modifier.animateItem(),
                        ) {
                            ListRow(row = row, onClick = { navigator.push(Destination.EntityList(row.id)) })
                        }
                        HorizontalDivider(color = RecitTheme.colors.borderDefault, modifier = Modifier.padding(start = Spacing.medium))
                    }
                }
            }
        }
    }

    if (showsForm) {
        ListFormSheet(listId = null, fileWorkUri = null, onDismiss = { showsForm = false })
    }
}

/** `.searchable(text:)`: filters the lists by name. */
@Composable
private fun ListsSearchField(query: String, onQueryChange: (String) -> Unit) {
    OutlinedTextField(
        value = query,
        onValueChange = onQueryChange,
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = Spacing.medium, vertical = Spacing.small),
        placeholder = { Text(stringResource(R.string.lists_search_prompt), style = RecitTheme.typography.content300) },
        leadingIcon = { Icon(Icons.Default.Search, contentDescription = null) },
        trailingIcon = {
            if (query.isNotEmpty()) {
                IconButton(onClick = { onQueryChange("") }) {
                    Icon(Icons.Default.Close, contentDescription = stringResource(R.string.lists_search_clear))
                }
            }
        },
        singleLine = true,
        textStyle = RecitTheme.typography.content300,
        shape = CircleShape,
        keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
        colors = OutlinedTextFieldDefaults.colors(
            focusedContainerColor = RecitTheme.colors.backgroundDefault,
            unfocusedContainerColor = RecitTheme.colors.backgroundDefault,
            focusedBorderColor = RecitTheme.colors.borderTinted,
            unfocusedBorderColor = RecitTheme.colors.borderDefault,
            focusedTextColor = RecitTheme.colors.foregroundDefault,
            unfocusedTextColor = RecitTheme.colors.foregroundDefault,
            focusedLeadingIconColor = RecitTheme.colors.foregroundSecondary,
            unfocusedLeadingIconColor = RecitTheme.colors.foregroundSecondary,
            focusedPlaceholderColor = RecitTheme.colors.foregroundPlaceholder,
            unfocusedPlaceholderColor = RecitTheme.colors.foregroundPlaceholder,
        ),
    )
}

/** `ListRowView`: the cover fan, then the name, what the list is for, and how much it holds. */
@Composable
private fun ListRow(row: ListRowModel, onClick: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(RecitTheme.colors.backgroundDefault)
            .clickable(onClick = onClick)
            .padding(horizontal = Spacing.medium, vertical = Spacing.sMedium),
        horizontalArrangement = Arrangement.spacedBy(Spacing.sMedium),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        ListCoverFan(covers = row.covers, type = row.type)
        Column(verticalArrangement = Arrangement.spacedBy(Spacing.xxSmall)) {
            Text(
                text = row.name,
                style = RecitTheme.typography.content400Bold,
                color = RecitTheme.colors.foregroundDefault,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
            if (row.explanation.isNotEmpty()) {
                Text(
                    text = row.explanation,
                    style = RecitTheme.typography.content300,
                    color = RecitTheme.colors.foregroundSecondary,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
            }
            Text(
                text = pluralStringResource(ListsPresentation.countPlural(row.type), row.count, row.count),
                style = RecitTheme.typography.footnote200,
                color = RecitTheme.colors.foregroundSecondary,
            )
        }
    }
}

/** `ListCoverFan`: up to three covers, 13dp apart, the first in front; always as wide as a full fan. */
@Composable
private fun ListCoverFan(covers: List<String?>, type: EntityListType) {
    val size: ThumbnailSize = ThumbnailSize.Small
    val step: Dp = 13.dp
    val shape: ThumbnailShape = if (type == EntityListType.Author) ThumbnailShape.Circle else ThumbnailShape.Portrait
    Box(modifier = Modifier.width(size.width + step * (ListsPresentation.COVER_LIMIT - 1))) {
        // Drawn back to front, so the first cover lands on top.
        covers.indices.reversed().forEach { index ->
            CellThumbnail(
                url = covers[index],
                size = size,
                shape = shape,
                modifier = Modifier.offset(x = step * index),
            )
        }
    }
}

/** `ListsEmptyStateView`: the step in words, the tag that says what a list is, the tag that makes one. */
@Composable
private fun ListsEmptyState(onCreate: () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = Spacing.xLarge, vertical = Spacing.xLarge),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(Spacing.xLarge, Alignment.CenterVertically),
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(Spacing.xSmall),
        ) {
            Text(
                text = stringResource(R.string.lists_empty_heading),
                style = RecitTheme.typography.content400Bold,
                color = RecitTheme.colors.foregroundDefault,
                textAlign = TextAlign.Center,
            )
            Text(
                text = stringResource(R.string.lists_empty_body),
                style = RecitTheme.typography.content300,
                color = RecitTheme.colors.foregroundSecondary,
                textAlign = TextAlign.Center,
            )
        }
        ListsExplanationTag()
        ListsCreateTag(onClick = onCreate)
    }
}

/** `ListsExplanationTag`: the one paper in the app that is not a button. */
@Composable
private fun ListsExplanationTag() {
    val title: String = stringResource(R.string.lists_empty_explain_title)
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .shelfPaper(title)
            .padding(horizontal = Spacing.medium, vertical = Spacing.sMedium),
        verticalArrangement = Arrangement.spacedBy(Spacing.small),
    ) {
        Row(horizontalArrangement = Arrangement.spacedBy(Spacing.small), verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.AutoMirrored.Filled.List, contentDescription = null, tint = ShelfPalette.LabelInk, modifier = Modifier.size(20.dp))
            Text(title, style = RecitTheme.typography.content400Bold, color = ShelfPalette.LabelInk)
        }
        Text(
            text = ListsPresentation.boldMarkdown(stringResource(R.string.lists_empty_explain_shelf)),
            style = RecitTheme.typography.content300,
            color = ShelfPalette.LabelInk,
        )
        Text(
            text = ListsPresentation.boldMarkdown(stringResource(R.string.lists_empty_explain_list)),
            style = RecitTheme.typography.content300,
            color = ShelfPalette.LabelInk,
        )
    }
}

/** `ListsCreateTag`: « Créer une liste », on the same paper — the same form as the « + » of the bar. */
@Composable
private fun ListsCreateTag(onClick: () -> Unit) {
    val title: String = stringResource(R.string.lists_empty_action_create_title)
    Column(
        modifier = Modifier
            .shelfPaper(title)
            .clickable(onClick = onClick)
            .padding(horizontal = Spacing.medium, vertical = Spacing.sMedium),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(Spacing.xSmall),
    ) {
        Row(horizontalArrangement = Arrangement.spacedBy(Spacing.xSmall), verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Default.Add, contentDescription = null, tint = ShelfPalette.LabelInk, modifier = Modifier.size(20.dp))
            Text(title, style = RecitTheme.typography.content400Bold, color = ShelfPalette.LabelInk, maxLines = 1)
        }
        Text(
            text = stringResource(R.string.lists_empty_action_create_detail),
            style = RecitTheme.typography.footnote200,
            color = ShelfPalette.LabelInk,
            textAlign = TextAlign.Center,
            maxLines = 2,
        )
    }
}
