package studio.lunabee.nouveaurecit.ui.common

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
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
import studio.lunabee.nouveaurecit.data.model.TransactionType
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.designsystem.TagLabel

/**
 * `InventoryCell`, drawn as a [BookRow]: cover, title, authors, subtitle, and under them only what
 * says something — a transaction other than « Inventorié », and for somebody else's copy
 * « Appartient à **name** ». Shared by every list of copies (inventory, shelf, search, a friend's
 * profile).
 */
@Composable
fun InventoryItemRow(
    row: ItemRow,
    showsOwner: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val transaction: TransactionType = row.item.transaction
    val owner: String? = row.owner?.username?.takeIf { showsOwner }
    val showsTransaction: Boolean = transaction != TransactionType.Inventorying
    BookRow(
        title = row.title,
        imageUrl = row.image,
        onClick = onClick,
        modifier = modifier,
        authors = row.authorNames.joinToString(", "),
        subtitle = row.subtitle,
        footer = if (showsTransaction || owner != null) {
            {
                Row(horizontalArrangement = Arrangement.spacedBy(Spacing.small), verticalAlignment = Alignment.CenterVertically) {
                    if (showsTransaction) {
                        TagLabel(text = stringResource(transaction.label), painter = painterResource(transaction.icon))
                    }
                    if (owner != null) {
                        Text(
                            ownedBy(stringResource(R.string.inventory_owned_by_prefix), owner),
                            style = RecitTheme.typography.footnote200,
                            color = RecitTheme.colors.foregroundSecondary,
                        )
                    }
                }
            }
        } else {
            null
        },
    )
}

private fun ownedBy(prefix: String, owner: String): AnnotatedString = buildAnnotatedString {
    append(prefix)
    append(" ")
    withStyle(SpanStyle(fontWeight = FontWeight.Bold)) { append(owner) }
}
