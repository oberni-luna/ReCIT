package studio.lunabee.nouveaurecit.ui.lists

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.model.EntityListType
import studio.lunabee.nouveaurecit.designsystem.CellThumbnail
import studio.lunabee.nouveaurecit.designsystem.EmptyState
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.designsystem.ThumbnailShape
import studio.lunabee.nouveaurecit.designsystem.ThumbnailSize
import studio.lunabee.nouveaurecit.ui.common.LocalMessenger
import studio.lunabee.nouveaurecit.ui.common.Messenger
import studio.lunabee.nouveaurecit.ui.common.RecitTopBar
import studio.lunabee.nouveaurecit.ui.common.recitViewModel
import studio.lunabee.nouveaurecit.ui.navigation.Destination
import studio.lunabee.nouveaurecit.ui.navigation.Navigator

/**
 * `EntityListDetail`: a list's works (portraits, pushing the work) or authors (rounds, pushing the
 * author), each with its comment, swiped to take it out. « Modifier » opens the form; the screen
 * leaves by itself when the list stops existing.
 */
@Composable
fun EntityListScreen(destination: Destination.EntityList, navigator: Navigator) {
    val viewModel: EntityListViewModel = recitViewModel(key = destination.id) {
        EntityListViewModel(destination.id, it.lists, it.entities)
    }
    val state: EntityListViewModel.State by viewModel.state.collectAsState()
    var showsForm: Boolean by rememberSaveable { mutableStateOf(false) }
    val messenger: Messenger = LocalMessenger.current
    val genericError: String = stringResource(R.string.error_generic)

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
                actions = {
                    if (state.list != null) {
                        IconButton(onClick = { showsForm = true }) {
                            Icon(Icons.Default.Edit, contentDescription = stringResource(R.string.action_edit))
                        }
                    }
                },
            )
        },
        containerColor = RecitTheme.colors.backgroundSecondary,
    ) { padding ->
        Box(Modifier.fillMaxSize().padding(padding)) {
            val list = state.list
            when {
                !state.isLoaded -> Unit
                list == null -> EmptyState(title = stringResource(R.string.list_empty), modifier = Modifier.align(Alignment.Center))
                // A publisher list shows no rows on iOS either: it says it is empty.
                state.rows.isEmpty() -> EmptyState(title = stringResource(R.string.list_empty), modifier = Modifier.align(Alignment.Center))
                else -> LazyColumn(Modifier.fillMaxSize()) {
                    items(state.rows, key = { it.uri }) { row ->
                        SwipeToDeleteRow(
                            key = row.uri,
                            onDelete = { viewModel.remove(row.uri) { messenger.showError(genericError, it.localizedMessage) } },
                            modifier = Modifier.animateItem(),
                        ) {
                            ListElementRow(
                                row = row,
                                isAuthor = list.type == EntityListType.Author,
                                onClick = {
                                    navigator.push(
                                        if (list.type == EntityListType.Author) Destination.Author(row.uri) else Destination.Work(row.uri),
                                    )
                                },
                            )
                        }
                        HorizontalDivider(color = RecitTheme.colors.borderDefault, modifier = Modifier.padding(start = Spacing.medium))
                    }
                }
            }
        }
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

/** `ListItemCellView`: the thumbnail, then title, subtitle and the element's comment. */
@Composable
private fun ListElementRow(row: ListElementRowModel, isAuthor: Boolean, onClick: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(RecitTheme.colors.backgroundDefault)
            .clickable(onClick = onClick)
            .padding(horizontal = Spacing.medium, vertical = Spacing.small),
        horizontalArrangement = Arrangement.spacedBy(Spacing.sMedium),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        CellThumbnail(
            url = row.image,
            size = ThumbnailSize.Medium,
            shape = if (isAuthor) ThumbnailShape.Circle else ThumbnailShape.Portrait,
        )
        Column(verticalArrangement = Arrangement.spacedBy(Spacing.xSmall)) {
            Text(row.title, style = RecitTheme.typography.content300, color = RecitTheme.colors.foregroundDefault)
            row.subtitle?.takeIf { it.isNotEmpty() }?.let {
                Text(it, style = RecitTheme.typography.content300, color = RecitTheme.colors.foregroundSecondary)
            }
            if (row.comment.isNotEmpty()) {
                Text(row.comment, style = RecitTheme.typography.content300, color = RecitTheme.colors.foregroundDefault)
            }
        }
    }
}
