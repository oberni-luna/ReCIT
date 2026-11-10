package studio.lunabee.nouveaurecit.ui.editedition

import androidx.compose.foundation.layout.Box
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import studio.lunabee.nouveaurecit.designsystem.DISABLED_ALPHA
import studio.lunabee.nouveaurecit.designsystem.RecitTheme

/**
 * An [EditionPropertyRow] whose value is picked from a menu of [options], [selected] checked. The menu closes
 * before [onPick] runs. Not [enabled], the row fades to [DISABLED_ALPHA] and the menu does not open.
 */
@Composable
fun <T> MenuPropertyRow(
    label: String,
    value: String?,
    options: List<T>,
    optionLabel: @Composable (T) -> String,
    selected: T?,
    onPick: (T) -> Unit,
    modifier: Modifier = Modifier,
    rowModifier: Modifier = Modifier,
    enabled: Boolean = true,
) {
    var expanded: Boolean by rememberSaveable { mutableStateOf(false) }
    Box(modifier.alpha(if (enabled) 1f else DISABLED_ALPHA)) {
        EditionPropertyRow(
            label = label,
            value = value,
            placeholder = "",
            trailing = PropertyRowTrailing.Menu,
            onClick = if (enabled) ({ expanded = true }) else null,
            modifier = rowModifier,
        )
        DropdownMenu(
            expanded = expanded && enabled,
            onDismissRequest = { expanded = false },
            containerColor = RecitTheme.colors.backgroundRaised,
        ) {
            options.forEach { option: T ->
                DropdownMenuItem(
                    text = { Text(text = optionLabel(option), style = RecitTheme.typography.content300) },
                    trailingIcon = {
                        if (option == selected) Icon(Icons.Default.Check, contentDescription = null, tint = RecitTheme.colors.foregroundTinted)
                    },
                    onClick = {
                        expanded = false
                        onPick(option)
                    },
                )
            }
        }
    }
}
