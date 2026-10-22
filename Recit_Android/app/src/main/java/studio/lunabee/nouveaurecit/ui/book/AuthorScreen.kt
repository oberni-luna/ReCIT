package studio.lunabee.nouveaurecit.ui.book

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.db.AuthorEntity
import studio.lunabee.nouveaurecit.designsystem.CellThumbnail
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.SectionHeader
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.designsystem.SyncingInlineRow
import studio.lunabee.nouveaurecit.designsystem.ThumbnailShape
import studio.lunabee.nouveaurecit.designsystem.ThumbnailSize
import studio.lunabee.nouveaurecit.ui.common.Formatting
import studio.lunabee.nouveaurecit.ui.common.RecitTopBar
import studio.lunabee.nouveaurecit.ui.common.recitViewModel
import studio.lunabee.nouveaurecit.ui.navigation.Destination
import studio.lunabee.nouveaurecit.ui.navigation.Navigator

/**
 * `AuthorDetailView`: the author's photo, name, description and birth date, then « Œuvres de %s »,
 * each work opening its gateway.
 */
@Composable
fun AuthorScreen(destination: Destination.Author, navigator: Navigator) {
    val viewModel: AuthorViewModel = recitViewModel(key = "author:${destination.uri}") { AuthorViewModel(it, destination.uri) }
    val state: AuthorUiState by viewModel.state.collectAsStateWithLifecycle()

    Scaffold(
        topBar = { RecitTopBar(title = stringResource(R.string.nav_author), onBack = navigator::pop) },
        containerColor = RecitTheme.colors.backgroundDefault,
    ) { padding: PaddingValues ->
        Box(Modifier.fillMaxSize().padding(padding)) {
            val author: AuthorEntity? = state.author
            val error: String? = state.error
            when {
                author != null -> AuthorContent(author, state, navigator)
                error != null -> CenteredText(stringResource(R.string.error_with_message, error.ifEmpty { stringResource(R.string.error_generic) }))
                else -> CenteredText(stringResource(R.string.author_loading))
            }
        }
    }
}

@Composable
private fun CenteredText(text: String) {
    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        Text(text, style = RecitTheme.typography.content300, color = RecitTheme.colors.foregroundSecondary)
    }
}

/** Who the author·ice is: the portrait (or initials), the name as the page's title, Wikidata's line, the dates. */
@Composable
private fun AuthorHeader(author: AuthorEntity) {
    val birth: String? = Formatting.wikidataDate(author.dateOfBirth)
    val death: String? = Formatting.wikidataDate(author.dateOfDeath)
    Column(
        modifier = Modifier.fillMaxWidth().padding(horizontal = Spacing.medium, vertical = Spacing.medium),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(Spacing.small),
    ) {
        CellThumbnail(url = author.image, size = ThumbnailSize.XLarge, shape = ThumbnailShape.Circle, fallbackName = author.name)
        Text(author.name, style = RecitTheme.typography.title200, color = RecitTheme.colors.foregroundDefault, textAlign = TextAlign.Center)
        author.subtitle?.takeIf { it.isNotBlank() }?.let {
            Text(it, style = RecitTheme.typography.content300, color = RecitTheme.colors.foregroundSecondary, textAlign = TextAlign.Center)
        }
        val dates: String? = when {
            birth != null && death != null -> stringResource(R.string.author_life_dates, birth, death)
            birth != null -> stringResource(R.string.author_birth_date, birth)
            else -> null
        }
        dates?.let { Text(it, style = RecitTheme.typography.footnote200, color = RecitTheme.colors.foregroundSecondary, textAlign = TextAlign.Center) }
    }
}

@Composable
private fun AuthorContent(author: AuthorEntity, state: AuthorUiState, navigator: Navigator) {
    LazyColumn(Modifier.fillMaxSize()) {
        item(key = "author") { AuthorHeader(author) }
        item(key = "works-header") { SectionHeader(title = stringResource(R.string.author_works_header, author.name)) }
        if (state.works.isEmpty() && state.worksLoading) {
            item(key = "works-loading") {
                CellSurface { SyncingInlineRow(stringResource(R.string.author_loading_works, author.name)) }
            }
        }
        items(state.works, key = { it.uri }) { work ->
            EntityResultRow(title = work.title, subtitle = work.subtitle, imageUrl = work.image) {
                navigator.push(Destination.Work(work.uri))
            }
        }
    }
}
