package studio.lunabee.nouveaurecit.ui.book

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.lazy.LazyListScope
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.SectionHeader
import studio.lunabee.nouveaurecit.ui.lists.ListRow
import studio.lunabee.nouveaurecit.ui.lists.ListRowDivider
import studio.lunabee.nouveaurecit.ui.lists.ListRowModel
import studio.lunabee.nouveaurecit.ui.navigation.Destination
import studio.lunabee.nouveaurecit.ui.navigation.Navigator

/** One row of « Dans les listes »: the list as the Lists tab draws it, and the work it opens on. */
data class BookListRow(val row: ListRowModel, val focusUri: String)

/**
 * `BookListsSection` (iOS feature 0079): « Dans les listes » — every list of works, mine or a friend's,
 * holding one of the edition's works, as the Lists tab draws it. Absent when there is none. A row opens the
 * list on that work; a friend's opens read-only, as from the Lists tab.
 */
internal fun LazyListScope.bookLists(rows: List<BookListRow>, navigator: Navigator) {
    if (rows.isEmpty()) return
    item(key = "in-lists-header") { SectionHeader(title = stringResource(R.string.book_in_lists)) }
    itemsIndexed(rows, key = { _, entry -> "in-list:${entry.row.id}" }) { index, entry ->
        // The cell's ground under the row and its divider alike: in dark it is a veil, laid once.
        Column(Modifier.background(RecitTheme.colors.backgroundFormCell)) {
            ListRow(row = entry.row, background = Color.Transparent) {
                navigator.push(Destination.EntityList(entry.row.id, entry.focusUri))
            }
            if (index < rows.lastIndex) ListRowDivider()
        }
    }
}
