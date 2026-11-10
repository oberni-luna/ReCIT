package studio.lunabee.nouveaurecit.designsystem

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.selection.toggleable
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TextFieldColors
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.unit.dp

/**
 * The head of every form sheet: the title on the leading edge, the close cross on the trailing
 * one. One layout, so that creating an étagère and creating a list read as the same gesture.
 */
@Composable
fun SheetHeader(
    title: String,
    closeLabel: String,
    onClose: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Row(modifier = modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
        Text(
            text = title,
            style = RecitTheme.typography.title50,
            color = RecitTheme.colors.foregroundDefault,
            modifier = Modifier.weight(1f),
        )
        IconButton(onClick = onClose) {
            Icon(Icons.Default.Close, contentDescription = closeLabel, tint = RecitTheme.colors.foregroundSecondary)
        }
    }
}

/** The one text field of the forms: outlined, its label floating. */
@Composable
fun FormTextField(
    value: String,
    onValueChange: (String) -> Unit,
    label: String,
    modifier: Modifier = Modifier,
    singleLine: Boolean = true,
    minLines: Int = 1,
    maxLines: Int = if (singleLine) 1 else Int.MAX_VALUE,
    readOnly: Boolean = false,
    trailingIcon: (@Composable () -> Unit)? = null,
) {
    OutlinedTextField(
        value = value,
        onValueChange = onValueChange,
        label = { Text(label) },
        singleLine = singleLine,
        minLines = minLines,
        maxLines = maxLines,
        readOnly = readOnly,
        trailingIcon = trailingIcon,
        textStyle = RecitTheme.typography.content300,
        keyboardOptions = KeyboardOptions(capitalization = KeyboardCapitalization.Sentences),
        colors = formFieldColors(),
        modifier = modifier.fillMaxWidth(),
    )
}

/** Outlined fields take the surface they sit on: a sheet in dark mode is lighter than the screen. */
@Composable
fun formFieldColors(): TextFieldColors = OutlinedTextFieldDefaults.colors(
    focusedContainerColor = Color.Transparent,
    unfocusedContainerColor = Color.Transparent,
    focusedBorderColor = RecitTheme.colors.borderTinted,
    unfocusedBorderColor = RecitTheme.colors.foregroundDisable,
    focusedLabelColor = RecitTheme.colors.foregroundTinted,
    unfocusedLabelColor = RecitTheme.colors.foregroundSecondary,
    focusedTextColor = RecitTheme.colors.foregroundDefault,
    unfocusedTextColor = RecitTheme.colors.foregroundDefault,
    cursorColor = RecitTheme.colors.foregroundTinted,
)

/**
 * The destructive action at the foot of a sheet or screen: red text, no fill, so that it never
 * weighs as much as the primary action above it.
 */
@Composable
fun DestructiveTextButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    isLoading: Boolean = false,
) {
    TextButton(
        onClick = onClick,
        modifier = modifier.fillMaxWidth(),
        enabled = enabled && !isLoading,
        colors = ButtonDefaults.textButtonColors(
            contentColor = RecitTheme.colors.foregroundError,
            disabledContentColor = RecitTheme.colors.foregroundDisable,
        ),
    ) {
        if (isLoading) {
            CircularProgressIndicator(modifier = Modifier.size(18.dp), color = RecitTheme.colors.foregroundError, strokeWidth = 2.dp)
        } else {
            Text(text = text, style = RecitTheme.typography.action300)
        }
    }
}

/**
 * A title, what it does under it, and the switch — `Row / Toggle` in the Figma file (`GroupAccessSection`,
 * `AccountToggleLabel`). The whole row toggles, as one control for TalkBack; the switch takes the primary
 * button's green.
 */
@Composable
fun SwitchRow(
    title: String,
    detail: String?,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit,
    modifier: Modifier = Modifier,
    contentPadding: PaddingValues = PaddingValues(),
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .toggleable(value = checked, role = Role.Switch, onValueChange = onCheckedChange)
            .padding(contentPadding),
        horizontalArrangement = Arrangement.spacedBy(Spacing.sMedium),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(Spacing.xxSmall)) {
            Text(title, style = RecitTheme.typography.content300, color = RecitTheme.colors.foregroundDefault)
            detail?.let { Text(it, style = RecitTheme.typography.footnote200, color = RecitTheme.colors.foregroundSecondary) }
        }
        Switch(
            checked = checked,
            onCheckedChange = null,
            colors = SwitchDefaults.colors(
                checkedThumbColor = RecitTheme.colors.foregroundTintedInverse,
                checkedTrackColor = RecitTheme.colors.backgroundTintedInverse,
                checkedBorderColor = RecitTheme.colors.backgroundTintedInverse,
                uncheckedThumbColor = RecitTheme.colors.foregroundSecondary,
                uncheckedTrackColor = RecitTheme.colors.backgroundSecondary,
                uncheckedBorderColor = RecitTheme.colors.foregroundDisable,
            ),
        )
    }
}
