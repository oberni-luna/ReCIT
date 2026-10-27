package studio.lunabee.nouveaurecit.ui.common

import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextOverflow
import studio.lunabee.nouveaurecit.designsystem.CellThumbnail
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.designsystem.ThumbnailShape
import studio.lunabee.nouveaurecit.designsystem.ThumbnailSize

/**
 * The one row for a book — or an author·ice — wherever the app lists them: the 2:3 cover, the
 * title, who wrote it, a grey line of subtitle or description, then [footer] for whatever state is
 * worth saying (a transaction, an owner). Inventory, shelves, lists, search and authors all draw
 * it, so a book looks the same from every screen.
 *
 * [trailing] sits at the end of the line, centred (a check mark in a picker).
 * [isPerson] swaps the cover for a round portrait that falls back on initials.
 * [onLongClick], when set, answers a long press — named [onLongClickLabel] for TalkBack.
 */
@Composable
fun BookRow(
    title: String,
    imageUrl: String?,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    authors: String? = null,
    subtitle: String? = null,
    isPerson: Boolean = false,
    footer: (@Composable () -> Unit)? = null,
    trailing: (@Composable () -> Unit)? = null,
    onLongClick: (() -> Unit)? = null,
    onLongClickLabel: String? = null,
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .combinedClickable(onLongClickLabel = onLongClickLabel, onLongClick = onLongClick, onClick = onClick)
            .padding(horizontal = Spacing.medium, vertical = Spacing.sMedium),
        horizontalArrangement = Arrangement.spacedBy(Spacing.sMedium),
        verticalAlignment = if (isPerson) Alignment.CenterVertically else Alignment.Top,
    ) {
        CellThumbnail(
            url = imageUrl,
            size = ThumbnailSize.Medium,
            shape = if (isPerson) ThumbnailShape.Circle else ThumbnailShape.Portrait,
            fallbackName = if (isPerson) title else null,
        )
        Column(verticalArrangement = Arrangement.spacedBy(Spacing.xxSmall), modifier = Modifier.weight(1f)) {
            Text(
                text = title,
                style = RecitTheme.typography.content400Bold,
                color = RecitTheme.colors.foregroundDefault,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
            )
            authors?.takeIf { it.isNotBlank() }?.let {
                Text(it, style = RecitTheme.typography.content300, color = RecitTheme.colors.foregroundDefault, maxLines = 1, overflow = TextOverflow.Ellipsis)
            }
            subtitle?.takeIf { it.isNotBlank() }?.let {
                Text(it, style = RecitTheme.typography.footnote200, color = RecitTheme.colors.foregroundSecondary, maxLines = 1, overflow = TextOverflow.Ellipsis)
            }
            footer?.let {
                Row(Modifier.padding(top = Spacing.xSmall)) { it() }
            }
        }
        trailing?.let { Box(Modifier.align(Alignment.CenterVertically)) { it() } }
    }
}
