package studio.lunabee.nouveaurecit.designsystem

import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.unit.dp

/**
 * The one search field of the app: the grey pill of the inventory's `SearchBar`, its magnifier,
 * and a clear button once something is typed. Every screen that filters or looks something up
 * uses it, so a search always looks the same.
 */
@Composable
fun RecitSearchField(
    query: String,
    onQueryChange: (String) -> Unit,
    placeholder: String,
    clearLabel: String,
    modifier: Modifier = Modifier,
    autoCorrect: Boolean = true,
) {
    TextField(
        value = query,
        onValueChange = onQueryChange,
        modifier = modifier
            .fillMaxWidth()
            .heightIn(min = 56.dp),
        placeholder = { Text(placeholder, style = RecitTheme.typography.content300) },
        leadingIcon = { Icon(Icons.Default.Search, contentDescription = null) },
        trailingIcon = {
            if (query.isNotEmpty()) {
                IconButton(onClick = { onQueryChange("") }) {
                    Icon(Icons.Default.Close, contentDescription = clearLabel)
                }
            }
        },
        singleLine = true,
        textStyle = RecitTheme.typography.content300,
        keyboardOptions = KeyboardOptions(
            capitalization = KeyboardCapitalization.None,
            autoCorrectEnabled = autoCorrect,
            imeAction = ImeAction.Search,
        ),
        shape = CircleShape,
        colors = TextFieldDefaults.colors(
            focusedContainerColor = RecitTheme.colors.backgroundSecondary,
            unfocusedContainerColor = RecitTheme.colors.backgroundSecondary,
            focusedIndicatorColor = Color.Transparent,
            unfocusedIndicatorColor = Color.Transparent,
            cursorColor = RecitTheme.colors.foregroundTinted,
            focusedTextColor = RecitTheme.colors.foregroundDefault,
            unfocusedTextColor = RecitTheme.colors.foregroundDefault,
            focusedPlaceholderColor = RecitTheme.colors.foregroundPlaceholder,
            unfocusedPlaceholderColor = RecitTheme.colors.foregroundPlaceholder,
            focusedLeadingIconColor = RecitTheme.colors.foregroundSecondary,
            unfocusedLeadingIconColor = RecitTheme.colors.foregroundSecondary,
            focusedTrailingIconColor = RecitTheme.colors.foregroundSecondary,
            unfocusedTrailingIconColor = RecitTheme.colors.foregroundSecondary,
        ),
    )
}
