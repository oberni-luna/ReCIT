package studio.lunabee.nouveaurecit.ui.lists

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material3.Icon
import androidx.compose.material3.SwipeToDismissBox
import androidx.compose.material3.SwipeToDismissBoxState
import androidx.compose.material3.SwipeToDismissBoxValue
import androidx.compose.material3.Text
import androidx.compose.material3.rememberSwipeToDismissBoxState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.Spacing

/**
 * `.swipeActions { Button("action.delete", systemImage: "trash") }`: swiping from the end reveals
 * « Supprimer » and runs [onDelete]. The writes behind it are server-first, so the row stays swiped
 * while it runs and comes back when [onDelete] answers `false`; on success Room drops the row.
 */
@Composable
internal fun SwipeToDeleteRow(
    key: String,
    onDelete: suspend () -> Boolean,
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit,
) {
    val state: SwipeToDismissBoxState = rememberSwipeToDismissBoxState()

    LaunchedEffect(key, state.currentValue) {
        if (state.currentValue == SwipeToDismissBoxValue.EndToStart && !onDelete()) {
            state.reset()
        }
    }

    SwipeToDismissBox(
        state = state,
        modifier = modifier,
        enableDismissFromStartToEnd = false,
        backgroundContent = {
            Row(
                modifier = Modifier
                    .fillMaxSize()
                    .background(RecitTheme.colors.backgroundError)
                    .padding(horizontal = Spacing.medium),
                horizontalArrangement = Arrangement.spacedBy(Spacing.xSmall, Alignment.End),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Icon(Icons.Default.Delete, contentDescription = null, tint = RecitTheme.colors.foregroundError, modifier = Modifier.size(20.dp))
                Text(stringResource(R.string.action_delete), style = RecitTheme.typography.action300, color = RecitTheme.colors.foregroundError)
            }
        },
    ) {
        content()
    }
}
