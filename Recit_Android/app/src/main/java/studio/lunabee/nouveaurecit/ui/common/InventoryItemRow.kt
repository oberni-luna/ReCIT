package studio.lunabee.nouveaurecit.ui.common

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.withStyle
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.db.ItemRow
import studio.lunabee.nouveaurecit.designsystem.CellThumbnail
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.designsystem.TagLabel
import studio.lunabee.nouveaurecit.designsystem.ThumbnailShape
import studio.lunabee.nouveaurecit.designsystem.ThumbnailSize

/**
 * `InventoryCell`: cover, title, subtitle, authors, the transaction tag, and — for somebody else's
 * copy — « Appartient à **name** ». Shared by every list of copies (inventory, shelf, search, a
 * friend's profile).
 */
@Composable
fun InventoryItemRow(
    row: ItemRow,
    showsOwner: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(horizontal = Spacing.medium, vertical = Spacing.small),
        horizontalArrangement = Arrangement.spacedBy(Spacing.sMedium),
        verticalAlignment = Alignment.Top,
    ) {
        CellThumbnail(url = row.image, size = ThumbnailSize.Medium, shape = ThumbnailShape.Portrait)
        Column(verticalArrangement = Arrangement.spacedBy(Spacing.xSmall)) {
            Text(row.title, style = RecitTheme.typography.content400Bold, color = RecitTheme.colors.foregroundDefault)
            row.subtitle?.let { Text(it, style = RecitTheme.typography.content300, color = RecitTheme.colors.foregroundDefault) }
            if (row.authorNames.isNotEmpty()) {
                Text(row.authorNames.joinToString(", "), style = RecitTheme.typography.footnote200, color = RecitTheme.colors.foregroundDefault)
            }
            Row(horizontalArrangement = Arrangement.spacedBy(Spacing.small), verticalAlignment = Alignment.CenterVertically) {
                TagLabel(
                    text = stringResource(row.item.transaction.label),
                    painter = painterResource(row.item.transaction.icon),
                )
                val owner: String? = row.owner?.username
                if (showsOwner && owner != null) {
                    Text(ownedBy(stringResource(R.string.inventory_owned_by_prefix), owner), style = RecitTheme.typography.footnote200, color = RecitTheme.colors.foregroundDefault)
                }
            }
        }
    }
}

private fun ownedBy(prefix: String, owner: String): AnnotatedString = buildAnnotatedString {
    append(prefix)
    append(" ")
    withStyle(SpanStyle(fontWeight = FontWeight.Bold)) { append(owner) }
}
