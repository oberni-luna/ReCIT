package studio.lunabee.nouveaurecit.ui.network

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyListScope
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.List
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.HorizontalDivider
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.db.UserEntity
import studio.lunabee.nouveaurecit.designsystem.EmptyState
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.ui.lists.ListRow
import studio.lunabee.nouveaurecit.ui.lists.ListRowModel

/**
 * `UserListsTab`: the lists the reader lets me see, in the rows of my own Lists tab, nothing that writes.
 * With none, a spinner while the first fetch runs, then that there is none — or that they could not be
 * loaded.
 */
internal fun LazyListScope.userListsItems(
    user: UserEntity,
    rows: List<ListRowModel>,
    load: UserListsLoad,
    onOpen: (String) -> Unit,
) {
    if (rows.isEmpty()) {
        item(key = "lists-empty") {
            val modifier: Modifier = Modifier.fillMaxWidth().padding(vertical = Spacing.large)
            when (load) {
                UserListsLoad.Loading -> Box(modifier, contentAlignment = Alignment.Center) {
                    CircularProgressIndicator(color = RecitTheme.colors.foregroundTinted)
                }
                UserListsLoad.Loaded -> EmptyState(
                    title = stringResource(R.string.network_user_lists_empty_title, user.username),
                    message = stringResource(R.string.network_user_lists_empty_message),
                    icon = Icons.AutoMirrored.Filled.List,
                    modifier = modifier,
                )
                UserListsLoad.Failed -> EmptyState(
                    title = stringResource(R.string.network_user_lists_failed, user.username),
                    icon = Icons.AutoMirrored.Filled.List,
                    modifier = modifier,
                )
            }
        }
    } else {
        items(rows, key = { it.id }) { row ->
            ListRow(row = row, onClick = { onOpen(row.id) })
            HorizontalDivider(color = RecitTheme.colors.borderDefault, modifier = Modifier.padding(start = Spacing.medium))
        }
    }
}
