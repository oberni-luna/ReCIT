package studio.lunabee.nouveaurecit.ui.lists

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.pluralStringResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.model.EntityListType
import studio.lunabee.nouveaurecit.designsystem.CellThumbnail
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.designsystem.ThumbnailShape
import studio.lunabee.nouveaurecit.designsystem.ThumbnailSize

/** `ListRowView`: the cover fan, then the name, what the list is for, and how much it holds. */
@Composable
internal fun ListRow(row: ListRowModel, onClick: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(RecitTheme.colors.backgroundDefault)
            .clickable(onClick = onClick)
            .padding(horizontal = Spacing.medium, vertical = Spacing.sMedium),
        horizontalArrangement = Arrangement.spacedBy(Spacing.sMedium),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        ListCoverFan(covers = row.covers, type = row.type)
        Column(verticalArrangement = Arrangement.spacedBy(Spacing.xxSmall)) {
            Text(
                text = row.name,
                style = RecitTheme.typography.content400Bold,
                color = RecitTheme.colors.foregroundDefault,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
            if (row.explanation.isNotEmpty()) {
                Text(
                    text = row.explanation,
                    style = RecitTheme.typography.content300,
                    color = RecitTheme.colors.foregroundSecondary,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
            }
            Text(
                // Plural rules follow the device's language; « 0 œuvres » showed on an English phone.
                text = if (row.count == 0) {
                    stringResource(R.string.list_count_empty)
                } else {
                    pluralStringResource(ListsPresentation.countPlural(row.type), row.count, row.count)
                },
                style = RecitTheme.typography.footnote200,
                color = RecitTheme.colors.foregroundSecondary,
            )
        }
    }
}

/** `ListCoverFan`: up to three 48 dp covers, 18dp apart, the first in front; always as wide as a full fan. */
@Composable
private fun ListCoverFan(covers: List<String?>, type: EntityListType) {
    val size: ThumbnailSize = ThumbnailSize.Medium
    val step: Dp = 18.dp
    val shape: ThumbnailShape = if (type == EntityListType.Author) ThumbnailShape.Circle else ThumbnailShape.Portrait
    Box(modifier = Modifier.width(size.width + step * (ListsPresentation.COVER_LIMIT - 1))) {
        // Drawn back to front, so the first cover lands on top.
        covers.indices.reversed().forEach { index ->
            CellThumbnail(
                url = covers[index],
                size = size,
                shape = shape,
                modifier = Modifier.offset(x = step * index),
            )
        }
    }
}
