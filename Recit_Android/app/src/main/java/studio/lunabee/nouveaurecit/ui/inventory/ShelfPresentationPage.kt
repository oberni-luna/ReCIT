package studio.lunabee.nouveaurecit.ui.inventory

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.db.ShelfEntity
import studio.lunabee.nouveaurecit.ui.common.Formatting
import studio.lunabee.nouveaurecit.ui.lists.PresentationPage

/**
 * `ShelfPresentationPage` (iOS feature 0089): the étagère's description, links live, or « Cette étagère n'a pas
 * de description »; then who may see it, the day it was made, and the day it last changed once it has changed
 * since. A list's « Présentation », less the type an étagère does not have. Editing stays behind the bar's pencil.
 */
@Composable
internal fun ShelfPresentationPage(shelf: ShelfEntity, modifier: Modifier = Modifier) {
    PresentationPage(
        description = shelf.description,
        emptyTitle = stringResource(R.string.shelf_presentation_empty),
        facts = listOfNotNull(
            stringResource(R.string.shelf_info_visibility) to stringResource(ShelfVisibility.from(shelf.visibility).label),
            shelf.created.takeIf { it > 0 }?.let { stringResource(R.string.shelf_info_created) to Formatting.longDate(it) },
            shelf.updated?.takeIf { it > shelf.created }?.let { stringResource(R.string.shelf_info_updated) to Formatting.longDate(it) },
        ),
        modifier = modifier,
    )
}
