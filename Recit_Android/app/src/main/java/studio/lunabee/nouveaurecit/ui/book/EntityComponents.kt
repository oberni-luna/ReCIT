package studio.lunabee.nouveaurecit.ui.book

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import coil3.compose.AsyncImage
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.db.AuthorEntity
import studio.lunabee.nouveaurecit.designsystem.CellThumbnail
import studio.lunabee.nouveaurecit.designsystem.CornerRadius
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.designsystem.ThumbnailShape
import studio.lunabee.nouveaurecit.designsystem.ThumbnailSize
import studio.lunabee.nouveaurecit.designsystem.WithLabel

/*
 * The pieces the book, work and author screens share: `EntityHeaderView` + `EntityImageView`,
 * `EntitySummaryView`, `EntityAuthorsView`, and the result row of `SearchResultCell`.
 */

/** Fixed artwork geometry of `EntityImageView`: a 256-tall cover. */
private val CoverHeight = 256.dp

/** `EntityImageView`'s background: the same cover, blurred (radius 80) at 20 %. */
private val CoverBlur = 80.dp
private const val CoverBlurAlpha: Float = 0.2f

/** `EntityHeaderView`: the cover over its blurred copy, the title in title200, the subtitle. */
@Composable
internal fun EntityHeader(title: String, subtitle: String?, imageUrl: String?, modifier: Modifier = Modifier) {
    Box(modifier.fillMaxWidth()) {
        if (imageUrl != null) {
            AsyncImage(
                model = imageUrl,
                contentDescription = null,
                contentScale = ContentScale.Crop,
                modifier = Modifier.matchParentSize().blur(CoverBlur).alpha(CoverBlurAlpha),
            )
        }
        Column(
            modifier = Modifier.fillMaxWidth().padding(horizontal = Spacing.medium, vertical = Spacing.medium),
            verticalArrangement = Arrangement.spacedBy(Spacing.xSmall),
        ) {
            if (imageUrl != null) {
                Box(Modifier.fillMaxWidth().padding(bottom = Spacing.sMedium), contentAlignment = Alignment.Center) {
                    AsyncImage(
                        model = imageUrl,
                        contentDescription = null,
                        contentScale = ContentScale.Fit,
                        modifier = Modifier.height(CoverHeight).clip(RoundedCornerShape(CornerRadius.minimal)),
                    )
                }
            }
            Column(verticalArrangement = Arrangement.spacedBy(Spacing.small)) {
                Text(title, style = RecitTheme.typography.title200, color = RecitTheme.colors.foregroundDefault)
                if (!subtitle.isNullOrBlank()) {
                    Text(subtitle, style = RecitTheme.typography.content300, color = RecitTheme.colors.foregroundSecondary)
                }
            }
        }
    }
}

/** A list cell: the iOS `List` row background, with the row's own padding. */
@Composable
internal fun CellSurface(
    modifier: Modifier = Modifier,
    onClick: (() -> Unit)? = null,
    content: @Composable () -> Unit,
) {
    Box(
        modifier
            .fillMaxWidth()
            .background(RecitTheme.colors.backgroundDefault)
            .then(if (onClick != null) Modifier.clickable(onClick = onClick) else Modifier)
            .padding(horizontal = Spacing.medium, vertical = Spacing.sMedium),
    ) {
        content()
    }
}

/**
 * `EntitySummaryView`: « Résumé » over three lines of the Wikipedia extract; a tap opens the whole
 * text in a sheet. Collapses when there is no extract. Genre tags are not ported (no genres yet).
 */
@Composable
internal fun SummaryRow(summary: SummaryState) {
    var showsAll: Boolean by rememberSaveable { mutableStateOf(false) }
    when (summary) {
        SummaryState.Empty -> Unit
        SummaryState.Loading -> CellSurface {
            CircularProgressIndicator(Modifier.size(24.dp), color = RecitTheme.colors.foregroundSecondary, strokeWidth = 2.dp)
        }
        is SummaryState.Loaded -> {
            CellSurface(onClick = { showsAll = true }) {
                WithLabel(label = stringResource(R.string.entity_summary_label)) {
                    Text(
                        summary.text,
                        style = RecitTheme.typography.content300,
                        color = RecitTheme.colors.foregroundDefault,
                        maxLines = 3,
                        overflow = TextOverflow.Ellipsis,
                    )
                }
            }
            if (showsAll) {
                ModalBottomSheet(
                    onDismissRequest = { showsAll = false },
                    sheetState = rememberModalBottomSheetState(),
                    containerColor = RecitTheme.colors.backgroundDefault,
                ) {
                    Text(
                        summary.text,
                        style = RecitTheme.typography.content400,
                        color = RecitTheme.colors.foregroundDefault,
                        modifier = Modifier.verticalScroll(rememberScrollState()).padding(Spacing.large),
                    )
                }
            }
        }
    }
}

/** `EntityAuthorsView`: « Auteur inconnu », one row, or a scroll of chips; each opens the author. */
@Composable
internal fun AuthorsRow(authors: List<AuthorEntity>, onAuthor: (String) -> Unit) {
    when (authors.size) {
        0 -> CellSurface {
            Text(stringResource(R.string.author_unknown), style = RecitTheme.typography.content400Bold, color = RecitTheme.colors.foregroundSecondary)
        }
        1 -> {
            val author: AuthorEntity = authors.first()
            CellSurface(onClick = { onAuthor(author.uri) }) {
                Row(horizontalArrangement = Arrangement.spacedBy(Spacing.small), verticalAlignment = Alignment.CenterVertically) {
                    CellThumbnail(url = author.image, size = ThumbnailSize.Medium, shape = ThumbnailShape.Circle)
                    Text(author.name, style = RecitTheme.typography.content400Bold, color = RecitTheme.colors.foregroundDefault)
                }
            }
        }
        else -> CellSurface {
            Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(Spacing.sMedium)) {
                authors.forEach { author ->
                    Row(
                        modifier = Modifier.widthIn(max = 200.dp).clickable { onAuthor(author.uri) },
                        horizontalArrangement = Arrangement.spacedBy(Spacing.small),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        CellThumbnail(url = author.image, size = ThumbnailSize.Small, shape = ThumbnailShape.Circle)
                        Text(author.name, style = RecitTheme.typography.content400Bold, color = RecitTheme.colors.foregroundDefault, maxLines = 2)
                    }
                }
            }
        }
    }
}

/** `SearchResultCell`'s work cell: a portrait cover, the title, and an optional secondary line. */
@Composable
internal fun EntityResultRow(title: String, subtitle: String?, imageUrl: String?, onClick: () -> Unit) {
    CellSurface(onClick = onClick) {
        Row(horizontalArrangement = Arrangement.spacedBy(Spacing.sMedium), verticalAlignment = Alignment.Top) {
            CellThumbnail(url = imageUrl, size = ThumbnailSize.Medium, shape = ThumbnailShape.Portrait)
            Column(verticalArrangement = Arrangement.spacedBy(Spacing.xSmall)) {
                Text(title, style = RecitTheme.typography.content400Bold, color = RecitTheme.colors.foregroundDefault)
                if (!subtitle.isNullOrBlank()) {
                    Text(subtitle, style = RecitTheme.typography.content300, color = RecitTheme.colors.foregroundSecondary)
                }
            }
        }
    }
}

/** A section's spinner row, while its content is on its way. */
@Composable
internal fun LoadingCell() {
    CellSurface {
        Box(Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
            CircularProgressIndicator(color = RecitTheme.colors.foregroundSecondary)
        }
    }
}
