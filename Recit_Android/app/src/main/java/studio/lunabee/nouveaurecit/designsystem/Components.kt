package studio.lunabee.nouveaurecit.designsystem

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.painter.Painter
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import coil3.compose.AsyncImage
import kotlin.math.abs

/** `EmptyStateView`. */
@Composable
fun EmptyState(
    title: String,
    modifier: Modifier = Modifier,
    message: String? = null,
    icon: ImageVector? = null,
    actionTitle: String? = null,
    onAction: (() -> Unit)? = null,
) {
    Column(
        modifier = modifier.padding(horizontal = Spacing.large, vertical = Spacing.large),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(Spacing.medium),
    ) {
        if (icon != null) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = RecitTheme.colors.foregroundSecondary,
                modifier = Modifier.size(40.dp),
            )
        }
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(Spacing.small),
        ) {
            Text(
                text = title,
                style = RecitTheme.typography.title50,
                color = RecitTheme.colors.foregroundDefault,
                textAlign = TextAlign.Center,
            )
            if (message != null) {
                Text(
                    text = message,
                    style = RecitTheme.typography.content300,
                    color = RecitTheme.colors.foregroundSecondary,
                    textAlign = TextAlign.Center,
                )
            }
        }
        if (actionTitle != null && onAction != null) {
            PrimaryButton(text = actionTitle, onClick = onAction)
        }
    }
}

/** `SyncingPlaceholderView` — full screen, until a domain's first sync lands. */
@Composable
fun SyncingPlaceholder(message: String, modifier: Modifier = Modifier) {
    Column(
        modifier = modifier.fillMaxSize(),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        CircularProgressIndicator(color = RecitTheme.colors.foregroundTinted)
        Spacer(Modifier.height(Spacing.medium))
        Text(
            text = message,
            style = RecitTheme.typography.content300,
            color = RecitTheme.colors.foregroundSecondary,
        )
    }
}

/** `SyncingInlineRow`. */
@Composable
fun SyncingInlineRow(message: String, modifier: Modifier = Modifier) {
    Row(
        modifier = modifier.padding(vertical = Spacing.small),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(Spacing.small),
    ) {
        CircularProgressIndicator(
            modifier = Modifier.size(18.dp),
            strokeWidth = 2.dp,
            color = RecitTheme.colors.foregroundSecondary,
        )
        Text(
            text = message,
            style = RecitTheme.typography.content300,
            color = RecitTheme.colors.foregroundSecondary,
        )
    }
}

enum class TagStyle { Tinted, Secondary }

/** `.labelStyle(.tag)` / `.secondaryTag`. Pass either a vector or a painter (the custom transaction icons). */
@Composable
fun TagLabel(
    text: String,
    modifier: Modifier = Modifier,
    style: TagStyle = TagStyle.Tinted,
    icon: ImageVector? = null,
    painter: Painter? = null,
) {
    val colors: RecitColors = RecitTheme.colors
    val background: Color = if (style == TagStyle.Tinted) colors.backgroundTinted else colors.backgroundSecondary
    val content: Color = if (style == TagStyle.Tinted) colors.foregroundTinted else colors.foregroundSecondary
    Row(
        modifier = modifier
            .clip(RoundedCornerShape(CornerRadius.minimal))
            .background(background)
            .padding(horizontal = Spacing.small, vertical = Spacing.xSmall),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(Spacing.xSmall),
    ) {
        when {
            icon != null -> Icon(icon, contentDescription = null, tint = content, modifier = Modifier.size(16.dp))
            painter != null -> Icon(painter, contentDescription = null, tint = content, modifier = Modifier.size(16.dp))
        }
        Text(text = text, style = RecitTheme.typography.action200, color = content)
    }
}

/** `withLabel(label:)` — a caption over its content. */
@Composable
fun WithLabel(
    label: String,
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit,
) {
    Column(modifier = modifier, verticalArrangement = Arrangement.spacedBy(Spacing.xSmall)) {
        Text(
            text = label,
            style = RecitTheme.typography.caption200,
            color = RecitTheme.colors.foregroundSecondary,
        )
        content()
    }
}

/** A list section header, as `Section(header:)` renders on iOS: action200, secondary, with an optional trailing action. */
@Composable
fun SectionHeader(
    title: String,
    modifier: Modifier = Modifier,
    trailing: @Composable (() -> Unit)? = null,
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(start = Spacing.medium, end = Spacing.xSmall, top = Spacing.large, bottom = Spacing.xSmall),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            text = title,
            style = RecitTheme.typography.action200,
            color = RecitTheme.colors.foregroundSecondary,
            modifier = Modifier.weight(1f),
        )
        trailing?.invoke()
    }
}

enum class ThumbnailSize(val width: Dp) {
    XSmall(24.dp),
    Small(36.dp),
    Medium(48.dp),
    Large(64.dp),
}

enum class ThumbnailShape { Square, Portrait, Circle }

/** `CellThumbnail` — a remote image with the placeholder background and the light shadow. */
@Composable
fun CellThumbnail(
    url: String?,
    modifier: Modifier = Modifier,
    size: ThumbnailSize = ThumbnailSize.Medium,
    shape: ThumbnailShape = ThumbnailShape.Portrait,
    cornerRadius: Dp = CornerRadius.minimal,
) {
    val height: Dp = if (shape == ThumbnailShape.Portrait) size.width * 4 / 3 else size.width
    val clip: Shape = if (shape == ThumbnailShape.Circle) CircleShape else RoundedCornerShape(cornerRadius)
    Box(
        modifier = modifier
            .size(width = size.width, height = height)
            .shadow(elevation = 1.dp, shape = clip)
            .clip(clip)
            .background(RecitTheme.colors.backgroundDisable),
    ) {
        if (url != null) {
            AsyncImage(
                model = url,
                contentDescription = null,
                contentScale = ContentScale.Crop,
                modifier = Modifier.fillMaxSize(),
            )
        }
    }
}

/**
 * `ShelfPaperModifier` — white paper, radius 4, the light shadow, and a tilt of about ±1° that is
 * deterministic in `seed`, so the same label always leans the same way.
 */
fun Modifier.shelfPaper(seed: String): Modifier {
    val tilt: Float = deterministicTilt(seed)
    return this
        .rotate(tilt)
        .shadow(elevation = 2.dp, shape = RoundedCornerShape(CornerRadius.minimal))
        .background(ShelfPalette.LabelPaper, RoundedCornerShape(CornerRadius.minimal))
}

/** `Model/Utils/DeterministicTilt.swift`, in spirit: a stable angle in [-1°, 1°] from a string. */
fun deterministicTilt(seed: String): Float {
    val hash: Int = seed.fold(17) { accumulator, character -> accumulator * 31 + character.code }
    return ((abs(hash) % 201) - 100) / 100f
}

/** A fixed-width spacer, for rows that line their text up behind a glyph. */
@Composable
fun HorizontalGap(width: Dp) {
    Spacer(Modifier.width(width))
}
