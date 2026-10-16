package studio.lunabee.nouveaurecit.ui.scan

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.QrCodeScanner
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.FilledIconButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButtonDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import coil3.compose.AsyncImage
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.scan.BatchScanState
import studio.lunabee.nouveaurecit.data.scan.ScannedBook
import studio.lunabee.nouveaurecit.designsystem.CornerRadius
import studio.lunabee.nouveaurecit.designsystem.Primitive
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.Spacing

/**
 * `ScanOverlayPalette`: fixed colours, not mode-aware. The overlay sits on a camera feed, which is
 * dark whatever the appearance setting says — the mirror of why the shelf label is fixed light.
 */
object ScanOverlayPalette {
    val Ink: Color = Primitive.Gray50
    val Tint: Color = Primitive.Green200
    val Alert: Color = Primitive.Red400
    val TintedSurface: Color = Primitive.Green900
    val CoverBacking: Color = Color.Black.copy(alpha = 0.35f)
    val Ground: Color = Color.Black

    /** Light text stays legible over an arbitrary image; it fades out above the slot rather than ending on an edge. */
    val Scrim: Brush = Brush.verticalGradient(
        0f to Color.Black.copy(alpha = 0f),
        0.25f to Color.Black.copy(alpha = 0.24f),
        0.6f to Color.Black.copy(alpha = 0.64f),
        1f to Color.Black.copy(alpha = 0.88f),
    )
}

/**
 * `ScanResultRowView`: the cover, the title and a caption that says where the book stands, and the
 * round button that files it. While the lookup runs, a placeholder book is drawn as a skeleton so the
 * row keeps its height. Tapping the text opens the book once there is one.
 *
 * An unknown edition says so and offers nothing: creating a book (feature 0020) is not ported.
 */
@Composable
fun ScanResultRow(
    state: BatchScanState,
    onOpen: (ScannedBook) -> Unit,
    onAdd: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val book: ScannedBook = state.book ?: ScannedBook.Placeholder
    val isLookingUp: Boolean = state is BatchScanState.LookingUp
    Row(
        modifier = modifier.fillMaxWidth().padding(horizontal = Spacing.medium, vertical = Spacing.small),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(Spacing.sMedium),
    ) {
        Box(
            Modifier
                .size(width = 48.dp, height = 75.dp)
                .clip(RoundedCornerShape(CornerRadius.minimal))
                .background(ScanOverlayPalette.CoverBacking),
        ) {
            if (book.coverImageUrl != null && !isLookingUp) {
                AsyncImage(
                    model = book.coverImageUrl,
                    contentDescription = null,
                    contentScale = ContentScale.Crop,
                    modifier = Modifier.matchParentSize(),
                )
            }
        }
        Column(
            modifier = Modifier
                .weight(1f)
                .clickable(enabled = book.uri.isNotEmpty()) { onOpen(book) },
            verticalArrangement = Arrangement.spacedBy(Spacing.xxSmall),
        ) {
            Text(
                text = if (state is BatchScanState.NotFound) state.code else book.title,
                style = RecitTheme.typography.content400Bold,
                color = if (isLookingUp) Color.Transparent else ScanOverlayPalette.Ink,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
                modifier = Modifier.redacted(isLookingUp),
            )
            Text(
                text = caption(state, book),
                style = RecitTheme.typography.content300,
                color = when (state) {
                    is BatchScanState.LookingUp -> Color.Transparent
                    is BatchScanState.NotFound -> ScanOverlayPalette.Alert
                    is BatchScanState.AlreadyOwned, is BatchScanState.Added -> ScanOverlayPalette.Tint
                    else -> ScanOverlayPalette.Ink
                },
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
                modifier = Modifier.redacted(isLookingUp),
            )
        }
        if (state !is BatchScanState.NotFound) ScanAddButton(state = state, onClick = onAdd)
    }
}

@Composable
private fun caption(state: BatchScanState, book: ScannedBook): String = when (state) {
    is BatchScanState.NotFound -> stringResource(R.string.scan_caption_not_found)
    is BatchScanState.AlreadyOwned -> stringResource(R.string.scan_caption_owned)
    is BatchScanState.Added -> stringResource(R.string.edition_added_to_inventory)
    else -> book.authorsLine
}

/** `.redacted(reason: .placeholder)`: the text's place, as a block — its colour goes transparent. */
private fun Modifier.redacted(isRedacted: Boolean): Modifier =
    if (isRedacted) {
        clip(RoundedCornerShape(CornerRadius.minimal)).background(ScanOverlayPalette.Ink.copy(alpha = 0.3f))
    } else {
        this
    }

/** `ScanAddButton`: + to file, a spinner while it is written, ✓ once it is. */
@Composable
private fun ScanAddButton(state: BatchScanState, onClick: () -> Unit) {
    val enabled: Boolean = state is BatchScanState.Resolved || state is BatchScanState.Added
    FilledIconButton(
        onClick = onClick,
        enabled = enabled,
        shape = CircleShape,
        colors = IconButtonDefaults.filledIconButtonColors(
            containerColor = ScanOverlayPalette.TintedSurface,
            contentColor = ScanOverlayPalette.Tint,
            disabledContainerColor = ScanOverlayPalette.TintedSurface.copy(alpha = 0.5f),
            disabledContentColor = ScanOverlayPalette.Tint.copy(alpha = 0.5f),
        ),
        modifier = Modifier.size(56.dp),
    ) {
        if (state is BatchScanState.Adding) {
            CircularProgressIndicator(color = ScanOverlayPalette.Tint, strokeWidth = 2.dp, modifier = Modifier.size(20.dp))
        } else {
            Icon(
                imageVector = if (state is BatchScanState.Added) Icons.Default.Check else Icons.Default.Add,
                contentDescription = stringResource(R.string.action_add_to_inventory),
            )
        }
    }
}

/** `ScanHintView`: what to point the phone at, in the place the book will take. */
@Composable
fun ScanHint(modifier: Modifier = Modifier) {
    Column(
        modifier = modifier.fillMaxWidth().padding(horizontal = Spacing.xLarge, vertical = Spacing.small),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(Spacing.sMedium),
    ) {
        Icon(Icons.Default.QrCodeScanner, contentDescription = null, tint = ScanOverlayPalette.Tint, modifier = Modifier.size(32.dp))
        Text(
            text = stringResource(R.string.scan_hint),
            style = RecitTheme.typography.content300,
            color = ScanOverlayPalette.Ink,
            textAlign = TextAlign.Center,
        )
    }
}
