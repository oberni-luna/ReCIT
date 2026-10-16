package studio.lunabee.nouveaurecit.ui.sort

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.pluralStringResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import coil3.compose.AsyncImage
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.emptyFlow
import studio.lunabee.nouveaurecit.AppContainer
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.db.ItemRow
import studio.lunabee.nouveaurecit.data.sorting.DeterministicTilt
import studio.lunabee.nouveaurecit.designsystem.PrimaryButton
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.ShelfPalette
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.designsystem.TintedTextButton
import studio.lunabee.nouveaurecit.ui.common.LocalAppContainer

/**
 * `OnboardingScanTallyView`, without its automatic-sorting half: how many books the session added,
 * on a plank carrying their covers, and the step after — « Ranger mes livres » or carry on without.
 * Shown only when books were added and there is no étagère to put them on, so every book of the
 * inventory is one to file.
 *
 * It replaces the camera rather than covering it, which is what releases the lens.
 */
@Composable
fun ScanTallyScreen(addedBookCount: Int, onSort: () -> Unit, onClose: () -> Unit) {
    val container: AppContainer = LocalAppContainer.current
    val myUserId: String? by container.users.myUserId.collectAsStateWithLifecycle()
    val items: Flow<List<ItemRow>> = remember(myUserId) {
        myUserId?.let(container.inventory::observeItemsOf) ?: emptyFlow()
    }
    val books: List<ItemRow> by items.collectAsStateWithLifecycle(initialValue = emptyList())
    BackHandler(onBack = onClose)

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(RecitTheme.colors.backgroundDefault)
            .statusBarsPadding()
            .navigationBarsPadding()
            .padding(horizontal = Spacing.large, vertical = Spacing.large),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Spacer(Modifier.weight(1f))
        SettlingBooks(books = books.take(TALLY_COVER_LIMIT))
        Spacer(Modifier.height(Spacing.xLarge))
        Text(
            text = pluralStringResource(R.plurals.sort_tally_title, addedBookCount, addedBookCount),
            style = RecitTheme.typography.title50,
            color = RecitTheme.colors.foregroundDefault,
            textAlign = TextAlign.Center,
            modifier = Modifier.semantics { heading() },
        )
        Spacer(Modifier.height(Spacing.small))
        Text(
            text = stringResource(R.string.sort_tally_body),
            style = RecitTheme.typography.content300,
            color = RecitTheme.colors.foregroundSecondary,
            textAlign = TextAlign.Center,
        )
        Spacer(Modifier.weight(1f))
        PrimaryButton(text = stringResource(R.string.sort_tally_sort), onClick = onSort, modifier = Modifier.fillMaxWidth())
        TintedTextButton(text = stringResource(R.string.sort_tally_continue_without_sorting), onClick = onClose)
    }
}

/** `OnboardingSettlingBooksView`, still: the session's covers standing on a plank. */
@Composable
private fun SettlingBooks(books: List<ItemRow>) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Row(horizontalArrangement = Arrangement.spacedBy(Spacing.xSmall), verticalAlignment = Alignment.Bottom) {
            books.forEach { row ->
                val shape = RoundedCornerShape(topStart = 2.dp, topEnd = 2.dp)
                Box(
                    Modifier
                        .size(width = 48.dp, height = 72.dp)
                        .rotate(DeterministicTilt.degrees(row.title, amplitude = 3.0).toFloat())
                        .shadow(elevation = 2.dp, shape = shape)
                        .clip(shape)
                        .background(ShelfPalette.Parchment),
                ) {
                    if (!row.image.isNullOrEmpty()) {
                        AsyncImage(model = row.image, contentDescription = null, contentScale = ContentScale.Crop, modifier = Modifier.fillMaxSize())
                    }
                }
            }
        }
        Image(
            painter = painterResource(R.drawable.shelf_plank),
            contentDescription = null,
            contentScale = ContentScale.FillBounds,
            modifier = Modifier.size(width = 300.dp, height = 18.dp),
        )
    }
}

private const val TALLY_COVER_LIMIT: Int = 5
