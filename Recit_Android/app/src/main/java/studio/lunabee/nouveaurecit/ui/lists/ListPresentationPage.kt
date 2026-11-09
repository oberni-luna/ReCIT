package studio.lunabee.nouveaurecit.ui.lists

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.db.EntityListEntity
import studio.lunabee.nouveaurecit.ui.common.Formatting

/**
 * `ListPresentationPage` (iOS feature 0073): a list's description, whole, in one card — the list's own words,
 * selectable, an address in it opening — then a card of what the list is: its type, who may see it, the day
 * it was made and the day it last changed. The same for a friend's list as for mine; editing stays behind the
 * bar's pencil. Its own scroll, as the other page keeps its own.
 */
@Composable
internal fun ListPresentationPage(list: EntityListEntity, modifier: Modifier = Modifier) {
    PresentationPage(
        description = list.explanation,
        emptyTitle = stringResource(R.string.list_presentation_empty),
        facts = listOfNotNull(
            stringResource(R.string.list_info_type) to stringResource(list.type.label),
            stringResource(R.string.list_info_visibility) to stringResource(ListVisibility.from(list.visibility).label),
            list.created.takeIf { it > 0 }?.let { stringResource(R.string.list_info_created) to Formatting.longDate(it) },
            list.updated?.takeIf { it > list.created }?.let { stringResource(R.string.list_info_updated) to Formatting.longDate(it) },
        ),
        modifier = modifier,
    )
}
