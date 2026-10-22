package studio.lunabee.nouveaurecit.ui.auth

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.consumeWindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ErrorOutline
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.unit.dp
import studio.lunabee.nouveaurecit.designsystem.CornerRadius
import studio.lunabee.nouveaurecit.designsystem.Primitive
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.ui.common.RecitTopBar

/**
 * The green chrome of the account screens: a transparent bar on the green, then one scrolling
 * column — the form, then its actions under the last field, never pinned over it. With the
 * keyboard up, the column shrinks above it and the focused field scrolls into view.
 */
@Composable
fun AuthScaffold(
    title: String,
    onBack: (() -> Unit)?,
    bottomBar: @Composable ColumnScope.() -> Unit,
    content: @Composable ColumnScope.() -> Unit,
) {
    Scaffold(
        topBar = { RecitTopBar(title = title, onBack = onBack, containerColor = Color.Transparent) },
        containerColor = RecitTheme.colors.backgroundTinted,
        contentWindowInsets = WindowInsets.safeDrawing,
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .consumeWindowInsets(padding)
                .imePadding()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = Spacing.medium, vertical = Spacing.large),
            verticalArrangement = Arrangement.spacedBy(Spacing.large),
        ) {
            content()
            Column(
                modifier = Modifier.fillMaxWidth().padding(top = Spacing.small),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(Spacing.medium),
                content = bottomBar,
            )
        }
    }
}

/** An error on the green: light text after a red glyph, since red text on green does not read. */
@Composable
fun AuthError(text: String, modifier: Modifier = Modifier) {
    Row(modifier = modifier, verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(Spacing.xSmall)) {
        Icon(Icons.Filled.ErrorOutline, contentDescription = null, tint = Primitive.Red400, modifier = Modifier.size(16.dp))
        Text(text, style = RecitTheme.typography.footnote200, color = RecitTheme.colors.foregroundDefault)
    }
}

/**
 * `AuthField`: a footnote label, a light input box (pinned to light on the green screens), and the
 * field's own error under it. [checking] shows the live availability spinner beside the label.
 */
@Composable
fun AuthField(
    label: String,
    value: String,
    onValueChange: (String) -> Unit,
    modifier: Modifier = Modifier,
    isSecure: Boolean = false,
    keyboardType: KeyboardType = KeyboardType.Text,
    checking: Boolean = false,
    error: String? = null,
) {
    Column(modifier = modifier, verticalArrangement = Arrangement.spacedBy(Spacing.xSmall)) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(Spacing.small)) {
            Text(label, style = RecitTheme.typography.footnote200, color = RecitTheme.colors.foregroundDefault)
            if (checking) {
                CircularProgressIndicator(modifier = Modifier.size(12.dp), strokeWidth = 1.5.dp, color = RecitTheme.colors.foregroundDefault)
            }
        }
        TextField(
            value = value,
            onValueChange = onValueChange,
            singleLine = true,
            textStyle = RecitTheme.typography.content300,
            visualTransformation = if (isSecure) PasswordVisualTransformation() else VisualTransformation.None,
            keyboardOptions = KeyboardOptions(
                keyboardType = if (isSecure) KeyboardType.Password else keyboardType,
                autoCorrectEnabled = false,
            ),
            shape = RoundedCornerShape(CornerRadius.medium),
            colors = TextFieldDefaults.colors(
                focusedContainerColor = Primitive.Gray50,
                unfocusedContainerColor = Primitive.Gray50,
                focusedTextColor = Primitive.Gray900,
                unfocusedTextColor = Primitive.Gray900,
                cursorColor = Primitive.Green700,
                focusedIndicatorColor = Color.Transparent,
                unfocusedIndicatorColor = Color.Transparent,
            ),
            modifier = Modifier.fillMaxWidth(),
        )
        if (error != null) {
            AuthError(error)
        }
    }
}
