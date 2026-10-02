package studio.lunabee.nouveaurecit.ui.book

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
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
        containerColor = RecitTheme.colors.backgroundSecondary,
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

@Composable
private fun AuthorContent(author: AuthorEntity, state: AuthorUiState, navigator: Navigator) {
    LazyColumn(Modifier.fillMaxSize()) {
        item(key = "author") {
            CellSurface {
                Column(verticalArrangement = Arrangement.spacedBy(Spacing.small)) {
                    if (author.image != null) CellThumbnail(url = author.image, size = ThumbnailSize.Large, shape = ThumbnailShape.Circle)
                    Text(author.name, style = RecitTheme.typography.content400Bold, color = RecitTheme.colors.foregroundDefault)
                    author.subtitle?.takeIf { it.isNotBlank() }?.let {
                        Text(it, style = RecitTheme.typography.content300, color = RecitTheme.colors.foregroundDefault)
                    }
                    Formatting.wikidataDate(author.dateOfBirth)?.let {
                        Text(stringResource(R.string.author_birth_date, it), style = RecitTheme.typography.content300, color = RecitTheme.colors.foregroundDefault)
                    }
                }
            }
        }
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
