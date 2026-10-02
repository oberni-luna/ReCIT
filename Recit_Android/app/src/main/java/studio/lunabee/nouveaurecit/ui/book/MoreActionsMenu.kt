package studio.lunabee.nouveaurecit.ui.book

import androidx.compose.foundation.layout.Box
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.AddCircleOutline
import androidx.compose.material.icons.filled.RemoveCircleOutline
import androidx.compose.material.icons.filled.Add
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.designsystem.RecitTheme

/** One line of the « … » menu: an action, or a submenu of étagères / lists (`MembershipMenu`). */
internal sealed interface MenuLine {
    val label: String
    val icon: ImageVector

    data class Action(override val label: String, override val icon: ImageVector, val onClick: () -> Unit) : MenuLine

    data class Membership(
        override val label: String,
        override val icon: ImageVector,
        val entries: List<MembershipEntry>,
        val creationLabel: String,
        val onToggle: (MembershipEntry) -> Unit,
        val onCreate: () -> Unit,
    ) : MenuLine
}

/**
 * The toolbar's « … » (`Menu` labelled `action.more`): a `DropdownMenu`, whose submenus open as a
 * second `DropdownMenu` on the same anchor — « Ajouter à %s » / « Retirer de %s » per entry, then
 * the creation line. Glyphs in the label colour, as on iOS.
 */
@Composable
internal fun MoreActionsMenu(lines: List<MenuLine>) {
    var expanded: Boolean by remember { mutableStateOf(false) }
    var submenu: MenuLine.Membership? by remember { mutableStateOf(null) }
    val iconTint = RecitTheme.colors.foregroundDefault

    Box {
        IconButton(onClick = { expanded = true }) {
            Icon(painterResource(R.drawable.ic_more), contentDescription = stringResource(R.string.action_more))
        }
        DropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }, containerColor = RecitTheme.colors.backgroundDefault) {
            lines.forEach { line ->
                DropdownMenuItem(
                    text = { Text(line.label, style = RecitTheme.typography.content400, color = RecitTheme.colors.foregroundDefault) },
                    leadingIcon = { Icon(line.icon, contentDescription = null, tint = iconTint) },
                    trailingIcon = if (line is MenuLine.Membership) {
                        { Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, contentDescription = null, tint = iconTint) }
                    } else {
                        null
                    },
                    onClick = {
                        expanded = false
                        when (line) {
                            is MenuLine.Action -> line.onClick()
                            is MenuLine.Membership -> submenu = line
                        }
                    },
                )
            }
        }
        val open: MenuLine.Membership? = submenu
        DropdownMenu(expanded = open != null, onDismissRequest = { submenu = null }, containerColor = RecitTheme.colors.backgroundDefault) {
            if (open != null) {
                open.entries.forEach { entry ->
                    val label: String = if (entry.isMember) {
                        stringResource(R.string.action_remove_from_named, entry.name)
                    } else {
                        stringResource(R.string.action_add_to_named, entry.name)
                    }
                    DropdownMenuItem(
                        text = { Text(label, style = RecitTheme.typography.content400, color = RecitTheme.colors.foregroundDefault) },
                        leadingIcon = {
                            Icon(if (entry.isMember) Icons.Filled.RemoveCircleOutline else Icons.Filled.Add, contentDescription = null, tint = iconTint)
                        },
                        onClick = {
                            submenu = null
                            open.onToggle(entry)
                        },
                    )
                }
                if (open.entries.isNotEmpty()) HorizontalDivider()
                DropdownMenuItem(
                    text = { Text(open.creationLabel, style = RecitTheme.typography.content400, color = RecitTheme.colors.foregroundDefault) },
                    leadingIcon = { Icon(Icons.Filled.AddCircleOutline, contentDescription = null, tint = iconTint) },
                    onClick = {
                        submenu = null
                        open.onCreate()
                    },
                )
            }
        }
    }
}
