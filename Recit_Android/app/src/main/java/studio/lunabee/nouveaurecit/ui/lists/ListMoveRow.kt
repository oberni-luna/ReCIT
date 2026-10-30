package studio.lunabee.nouveaurecit.ui.lists

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.size
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.lists.ListMoveDestination
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.Spacing

/**
 * `ListMoveRow` (iOS feature 0061): « Déplacer dans une autre liste » on the selected element — a menu of
 * the user's other lists of the same type, sorted by name, those that already hold the element greyed with
 * « Déjà dans cette liste ». The row spins while the move runs, and is inert while the comment is written
 * (its draft is only saved when the field is left) and for an element the server has not created yet.
 */
@Composable
internal fun ListMoveRow(
    destinations: List<ListMoveDestination>,
    isMoving: Boolean,
    enabled: Boolean,
    onMove: (ListMoveDestination) -> Unit,
) {
    var expanded: Boolean by remember { mutableStateOf(false) }
    val isActive: Boolean = enabled && !isMoving
    Box {
        ListCard(onClick = if (isActive) ({ expanded = true }) else null) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(Spacing.small),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(
                    stringResource(R.string.list_detail_move),
                    style = RecitTheme.typography.action300,
                    color = if (isActive) RecitTheme.colors.foregroundTinted else RecitTheme.colors.foregroundDisable,
                    modifier = Modifier.weight(1f),
                )
                if (isMoving) CircularProgressIndicator(color = RecitTheme.colors.foregroundSecondary, strokeWidth = 2.dp, modifier = Modifier.size(18.dp))
            }
        }
        DropdownMenu(
            expanded = expanded,
            onDismissRequest = { expanded = false },
            containerColor = RecitTheme.colors.backgroundRaised,
        ) {
            destinations.forEach { destination ->
                DropdownMenuItem(
                    enabled = !destination.alreadyHolds,
                    text = {
                        Column {
                            Text(destination.name, style = RecitTheme.typography.content300)
                            if (destination.alreadyHolds) {
                                Text(
                                    stringResource(R.string.list_detail_move_already),
                                    style = RecitTheme.typography.footnote200,
                                    color = RecitTheme.colors.foregroundSecondary,
                                )
                            }
                        }
                    },
                    onClick = {
                        expanded = false
                        onMove(destination)
                    },
                )
            }
        }
    }
}
