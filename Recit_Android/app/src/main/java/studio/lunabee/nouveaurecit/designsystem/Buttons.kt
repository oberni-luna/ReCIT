package studio.lunabee.nouveaurecit.designsystem

import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp

/** `.buttonStyle(.primary())` — the capsule. `isLoading` replaces the label with a spinner (`AsyncButton`). */
@Composable
fun PrimaryButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    isLoading: Boolean = false,
    icon: ImageVector? = null,
) {
    LargeButton(
        text = text,
        onClick = onClick,
        modifier = modifier,
        enabled = enabled,
        isLoading = isLoading,
        icon = icon,
        container = RecitTheme.colors.backgroundTintedInverse,
        content = RecitTheme.colors.foregroundTintedInverse,
    )
}

/** `.buttonStyle(.destructive())`. */
@Composable
fun DestructiveButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    isLoading: Boolean = false,
) {
    LargeButton(
        text = text,
        onClick = onClick,
        modifier = modifier,
        enabled = enabled,
        isLoading = isLoading,
        icon = null,
        container = RecitTheme.colors.backgroundError,
        content = RecitTheme.colors.foregroundError,
    )
}

/** `.buttonStyle(.secondary())` — clear, tinted text. */
@Composable
fun SecondaryButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
) {
    TextButton(
        onClick = onClick,
        modifier = modifier,
        enabled = enabled,
        contentPadding = PaddingValues(horizontal = Spacing.large, vertical = Spacing.medium),
        colors = ButtonDefaults.textButtonColors(
            contentColor = RecitTheme.colors.foregroundTinted,
            disabledContentColor = RecitTheme.colors.foregroundDisable,
        ),
    ) {
        Text(text = text, style = RecitTheme.typography.action300)
    }
}

/** A text-only tinted action, as the plain buttons of the iOS lists (« Effacer », « Tout voir »). */
@Composable
fun TintedTextButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    color: Color = RecitTheme.colors.foregroundTinted,
    icon: ImageVector? = null,
) {
    TextButton(
        onClick = onClick,
        modifier = modifier,
        colors = ButtonDefaults.textButtonColors(contentColor = color),
    ) {
        if (icon != null) {
            Icon(imageVector = icon, contentDescription = null, modifier = Modifier.size(18.dp))
            Spacer(Modifier.width(Spacing.xSmall))
        }
        Text(text = text, style = RecitTheme.typography.action300)
    }
}

enum class PillStyle { Prominent, Tinted }

/** `.buttonStyle(.pill(.prominent | .tinted))`. */
@Composable
fun PillButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    style: PillStyle = PillStyle.Tinted,
    icon: ImageVector? = null,
    enabled: Boolean = true,
) {
    val colors: RecitColors = RecitTheme.colors
    val container: Color = if (style == PillStyle.Prominent) colors.backgroundTintedInverse else colors.backgroundTinted
    val content: Color = if (style == PillStyle.Prominent) colors.foregroundTintedInverse else colors.foregroundTinted
    Button(
        onClick = onClick,
        modifier = modifier,
        enabled = enabled,
        shape = CircleShape,
        contentPadding = PaddingValues(horizontal = Spacing.medium, vertical = Spacing.small),
        colors = ButtonDefaults.buttonColors(
            containerColor = container,
            contentColor = content,
            disabledContainerColor = colors.backgroundDisable,
            disabledContentColor = colors.foregroundDisable,
        ),
    ) {
        ButtonLabel(text = text, icon = icon)
    }
}

@Composable
private fun LargeButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier,
    enabled: Boolean,
    isLoading: Boolean,
    icon: ImageVector?,
    container: Color,
    content: Color,
) {
    Button(
        onClick = onClick,
        modifier = modifier.fillMaxWidth(),
        enabled = enabled && !isLoading,
        shape = CircleShape,
        contentPadding = PaddingValues(horizontal = Spacing.large, vertical = Spacing.medium),
        colors = ButtonDefaults.buttonColors(
            containerColor = container,
            contentColor = content,
            disabledContainerColor = if (isLoading) container else RecitTheme.colors.backgroundDisable,
            disabledContentColor = if (isLoading) content else RecitTheme.colors.foregroundDisable,
        ),
    ) {
        if (isLoading) {
            CircularProgressIndicator(
                modifier = Modifier.size(20.dp),
                color = content,
                strokeWidth = 2.dp,
            )
        } else {
            ButtonLabel(text = text, icon = icon)
        }
    }
}

@Composable
private fun RowScope.ButtonLabel(text: String, icon: ImageVector?) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        if (icon != null) {
            Icon(imageVector = icon, contentDescription = null, modifier = Modifier.size(18.dp))
            Spacer(Modifier.width(Spacing.small))
        }
        Text(text = text, style = RecitTheme.typography.action300)
    }
}
