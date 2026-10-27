package studio.lunabee.nouveaurecit.ui.book

import androidx.compose.foundation.layout.Box
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.AddCircleOutline
import androidx.compose.material.icons.filled.RemoveCircleOutline
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextOverflow
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.designsystem.RecitTheme

/** One line of the « … » menu: an action, or a submenu of étagères / lists (`MembershipMenu`). */
internal sealed interface MenuLine {
    val label: String
    val icon: ImageVector

    data class Action(
        override val label: String,
        override val icon: ImageVector,
        val onClick: () -> Unit,
        val isDestructive: Boolean = false,
    ) : MenuLine

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
 * The toolbar's « … » (`Menu` labelled `action.more`): an icon button over an [ActionsDropdown].
 */
@Composable
internal fun MoreActionsMenu(lines: List<MenuLine>) {
    var expanded: Boolean by remember { mutableStateOf(false) }

    Box {
        IconButton(onClick = { expanded = true }) {
            Icon(painterResource(R.drawable.ic_more), contentDescription = stringResource(R.string.action_more))
        }
        ActionsDropdown(expanded = expanded, onDismiss = { expanded = false }, lines = lines)
    }
}

/**
 * The menu itself, anchored on whatever it is placed beside — the toolbar's « … » or a book row
 * held down. A `DropdownMenu`, whose submenus open as a second `DropdownMenu` on the same anchor,
 * headed by the submenu's name and a way back — « Ajouter à %s » / « Retirer de %s » per entry,
 * then the creation line. Glyphs in the label colour, as on iOS; a destructive action is red,
 * glyph included.
 *
 * [expanded] stays `true` while either level is open; [onDismiss] runs once the whole menu closes,
 * whether a line was picked or the user tapped away.
 */
@Composable
internal fun ActionsDropdown(expanded: Boolean, onDismiss: () -> Unit, lines: List<MenuLine>) {
    var submenu: MenuLine.Membership? by remember { mutableStateOf(null) }
    val iconTint = RecitTheme.colors.foregroundDefault
    val close: () -> Unit = {
        submenu = null
        onDismiss()
    }
    // Closed from outside: the next opening starts on the first level.
    LaunchedEffect(expanded) {
        if (!expanded) submenu = null
    }

    DropdownMenu(expanded = expanded && submenu == null, onDismissRequest = close, containerColor = RecitTheme.colors.backgroundRaised) {
        lines.forEach { line ->
            val tint: Color = if ((line as? MenuLine.Action)?.isDestructive == true) RecitTheme.colors.foregroundError else iconTint
            DropdownMenuItem(
                text = { Text(line.label, style = RecitTheme.typography.content400, color = tint, maxLines = 1, overflow = TextOverflow.Ellipsis) },
                leadingIcon = { Icon(line.icon, contentDescription = null, tint = tint) },
                trailingIcon = if (line is MenuLine.Membership) {
                    { Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, contentDescription = null, tint = iconTint) }
                } else {
                    null
                },
                onClick = {
                    when (line) {
                        is MenuLine.Action -> {
                            close()
                            line.onClick()
                        }
                        is MenuLine.Membership -> submenu = line
                    }
                },
            )
        }
    }
    val open: MenuLine.Membership? = submenu.takeIf { expanded }
    DropdownMenu(expanded = open != null, onDismissRequest = close, containerColor = RecitTheme.colors.backgroundRaised) {
        if (open != null) {
            DropdownMenuItem(
                text = { Text(open.label, style = RecitTheme.typography.content400Bold, color = RecitTheme.colors.foregroundDefault) },
                leadingIcon = {
                    Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = stringResource(R.string.action_back), tint = iconTint)
                },
                onClick = { submenu = null },
            )
            HorizontalDivider()
            open.entries.forEach { entry ->
                val label: String = if (entry.isMember) {
                    stringResource(R.string.action_remove_from_named, entry.name)
                } else {
                    stringResource(R.string.action_add_to_named, entry.name)
                }
                DropdownMenuItem(
                    text = { Text(label, style = RecitTheme.typography.content400, color = RecitTheme.colors.foregroundDefault, maxLines = 2) },
                    leadingIcon = {
                        Icon(if (entry.isMember) Icons.Filled.RemoveCircleOutline else Icons.Filled.Add, contentDescription = null, tint = iconTint)
                    },
                    onClick = {
                        close()
                        open.onToggle(entry)
                    },
                )
            }
            if (open.entries.isNotEmpty()) HorizontalDivider()
            DropdownMenuItem(
                text = { Text(open.creationLabel, style = RecitTheme.typography.content400, color = RecitTheme.colors.foregroundDefault) },
                leadingIcon = { Icon(Icons.Filled.AddCircleOutline, contentDescription = null, tint = iconTint) },
                onClick = {
                    close()
                    open.onCreate()
                },
            )
        }
    }
}
