package studio.lunabee.nouveaurecit.ui.profile

import androidx.annotation.StringRes
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.ArrowOutward
import androidx.compose.material.icons.outlined.Book
import androidx.compose.material.icons.outlined.Hub
import androidx.compose.material.icons.outlined.Person
import androidx.compose.material.icons.outlined.WavingHand
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.platform.UriHandler
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.db.ItemRow
import studio.lunabee.nouveaurecit.designsystem.CornerRadius
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.ShelfPalette
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.designsystem.shelfPaper
import studio.lunabee.nouveaurecit.ui.common.RecitTopBar
import studio.lunabee.nouveaurecit.ui.common.recitViewModel
import studio.lunabee.nouveaurecit.ui.inventory.Plank
import studio.lunabee.nouveaurecit.ui.inventory.ShelfCardMetrics
import studio.lunabee.nouveaurecit.ui.inventory.StandingCover
import studio.lunabee.nouveaurecit.ui.navigation.Navigator

/**
 * `AboutInventaireView` (feature 0034): what the library behind the app is, said once and plainly.
 * An étagère carrying my three latest books under an « inventaire.io » tag, the sentence that ties
 * the two together, the four things inventaire.io is, four pages to go further, and the note that
 * the app is independent of it.
 *
 * On white (`backgroundDefault`): a page to read rather than a list to act on. It took over from
 * the paper tag that used to sit under the account (feature 0026).
 */
@Composable
fun AboutInventaireScreen(navigator: Navigator) {
    val viewModel: AboutInventaireViewModel = recitViewModel { container -> AboutInventaireViewModel(container) }
    val latestBooks: List<ItemRow> by viewModel.latestBooks.collectAsStateWithLifecycle()

    Scaffold(
        topBar = { RecitTopBar(title = stringResource(R.string.about_title), onBack = navigator::pop) },
        containerColor = RecitTheme.colors.backgroundDefault,
    ) { padding: PaddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(top = Spacing.small, bottom = Spacing.large),
            verticalArrangement = Arrangement.spacedBy(Spacing.large),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            AboutInventaireShelf(books = latestBooks, modifier = Modifier.padding(horizontal = Spacing.medium))
            Column(
                modifier = Modifier.padding(horizontal = Spacing.large),
                verticalArrangement = Arrangement.spacedBy(Spacing.small),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Text(
                    text = stringResource(R.string.about_headline),
                    style = RecitTheme.typography.title200,
                    color = RecitTheme.colors.foregroundDefault,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.semantics { heading() },
                )
                Text(
                    text = stringResource(R.string.about_tagline),
                    style = RecitTheme.typography.content300,
                    color = RecitTheme.colors.foregroundSecondary,
                    textAlign = TextAlign.Center,
                )
            }
            Column(
                modifier = Modifier.padding(horizontal = Spacing.medium),
                verticalArrangement = Arrangement.spacedBy(Spacing.large),
            ) {
                AboutValueRow(Icons.Outlined.Book, R.string.about_value_commons_title, R.string.about_value_commons_body)
                AboutValueRow(Icons.Outlined.Person, R.string.about_value_account_title, R.string.about_value_account_body)
                AboutValueRow(Icons.Outlined.Hub, R.string.about_value_data_title, R.string.about_value_data_body)
                AboutValueRow(Icons.Outlined.WavingHand, R.string.about_value_software_title, R.string.about_value_software_body)
            }
            AboutLinks(modifier = Modifier.padding(horizontal = Spacing.medium))
            Column(
                modifier = Modifier.padding(horizontal = Spacing.xLarge),
                verticalArrangement = Arrangement.spacedBy(Spacing.small),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                AppIconTile(size = 44.dp)
                Text(
                    text = stringResource(R.string.about_independence),
                    style = RecitTheme.typography.footnote200,
                    color = RecitTheme.colors.foregroundSecondary,
                    textAlign = TextAlign.Center,
                )
            }
        }
    }
}

/**
 * `AboutInventaireShelf`: a plank as the inventory draws one, my latest books standing on it, and a
 * paper tag under it naming the shelf « inventaire.io ». An illustration, not a shelf: nothing on
 * it answers a tap, and TalkBack skips it — the title under it says what it says.
 */
@Composable
private fun AboutInventaireShelf(books: List<ItemRow>, modifier: Modifier = Modifier) {
    BoxWithConstraints(modifier.fillMaxWidth().clearAndSetSemantics {}, contentAlignment = Alignment.TopCenter) {
        val width: Dp = maxWidth
        val metrics = ShelfCardMetrics(width.value)
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Box(
                modifier = Modifier
                    .width(width)
                    .height(metrics.zoneHeight.dp)
                    .padding(horizontal = ShelfCardMetrics.HORIZONTAL_MARGIN.dp),
                contentAlignment = Alignment.BottomCenter,
            ) {
                Row(horizontalArrangement = Arrangement.spacedBy(ShelfCardMetrics.COVER_GAP.dp), verticalAlignment = Alignment.Bottom) {
                    books.forEach { row ->
                        StandingCover(row = row, width = metrics.coverWidth.dp, height = metrics.coverHeight.dp, onClick = null)
                    }
                }
            }
            Plank(width = width, height = metrics.plankHeight.dp)
            AboutInventaireShelfTag(modifier = Modifier.offset(y = -ShelfCardMetrics.LABEL_OVERLAP.dp))
        }
    }
}

/** `AboutInventaireShelfTag`: inventaire.io's logo and its name, on an étagère's paper. A name, so not translated. */
@Composable
private fun AboutInventaireShelfTag(modifier: Modifier = Modifier) {
    Row(
        modifier = modifier
            .shelfPaper(INVENTAIRE_NAME)
            .padding(horizontal = Spacing.small, vertical = Spacing.xSmall),
        horizontalArrangement = Arrangement.spacedBy(Spacing.xSmall),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Image(
            painter = painterResource(R.drawable.inventaire_io),
            contentDescription = null,
            modifier = Modifier.size(20.dp).clip(RoundedCornerShape(CornerRadius.minimal)),
        )
        Text(INVENTAIRE_NAME, style = RecitTheme.typography.content300, color = ShelfPalette.LabelInk, maxLines = 1)
    }
}

/** `AboutInventaireValueRow`: a glyph in a pale green disc, a bold line, and the sentence that explains it. */
@Composable
private fun AboutValueRow(icon: ImageVector, @StringRes title: Int, @StringRes detail: Int) {
    Row(
        modifier = Modifier.fillMaxWidth().semantics(mergeDescendants = true) {},
        horizontalArrangement = Arrangement.spacedBy(Spacing.sMedium),
        verticalAlignment = Alignment.Top,
    ) {
        Box(
            modifier = Modifier.size(VALUE_BADGE_SIDE).background(RecitTheme.colors.backgroundTinted, CircleShape),
            contentAlignment = Alignment.Center,
        ) {
            Icon(icon, contentDescription = null, tint = RecitTheme.colors.foregroundTinted)
        }
        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(Spacing.xxSmall)) {
            Text(stringResource(title), style = RecitTheme.typography.content400Bold, color = RecitTheme.colors.foregroundDefault)
            Text(stringResource(detail), style = RecitTheme.typography.content300, color = RecitTheme.colors.foregroundSecondary)
        }
    }
}

/**
 * `AboutInventaireLinks`: « Aller plus loin », four pages of inventaire.io opened in the browser,
 * outlined by a hairline rather than filled — on a white screen a grey fill would read as a hole.
 */
@Composable
private fun AboutLinks(modifier: Modifier = Modifier) {
    val uriHandler: UriHandler = LocalUriHandler.current
    val shape = RoundedCornerShape(CornerRadius.rounded)
    Column(modifier = modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(Spacing.small)) {
        Text(
            text = stringResource(R.string.about_links),
            style = RecitTheme.typography.caption200,
            color = RecitTheme.colors.foregroundSecondary,
            modifier = Modifier.semantics { heading() },
        )
        Column(Modifier.fillMaxWidth().clip(shape).border(1.dp, RecitTheme.colors.borderDefault, shape)) {
            LINKS.forEachIndexed { index, (title, url) ->
                if (index > 0) HorizontalDivider(Modifier.padding(start = Spacing.medium), color = RecitTheme.colors.borderDefault)
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable { uriHandler.openUri(url) }
                        .padding(horizontal = Spacing.medium, vertical = Spacing.sMedium),
                    horizontalArrangement = Arrangement.spacedBy(Spacing.small),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text(
                        text = stringResource(title),
                        style = RecitTheme.typography.action300,
                        color = RecitTheme.colors.foregroundTinted,
                        modifier = Modifier.weight(1f),
                    )
                    Icon(Icons.Outlined.ArrowOutward, contentDescription = null, tint = RecitTheme.colors.foregroundTinted)
                }
            }
        }
    }
}

/**
 * `AppIconTile`: the app's icon drawn as a tile — the cream gradient of `AppIcon.icon` and its
 * books-on-a-shelf illustration, at the icon's own scale and lift. Its colours hold in both
 * appearances, as the icon's do.
 */
@Composable
internal fun AppIconTile(size: Dp, modifier: Modifier = Modifier) {
    Box(
        modifier = modifier
            .size(size)
            .clip(RoundedCornerShape(size * ICON_CORNER_SHARE))
            .background(Brush.verticalGradient(0f to IconTop, 0.7f to IconBottom)),
        contentAlignment = Alignment.Center,
    ) {
        Image(
            painter = painterResource(R.drawable.books_on_shelf),
            contentDescription = null,
            modifier = Modifier.size(size * ICON_ART_SCALE).offset(y = -size * ICON_ART_LIFT),
        )
    }
}

private val LINKS: List<Pair<Int, String>> = listOf(
    R.string.about_link_website to "https://inventaire.io",
    R.string.about_link_data to "https://data.inventaire.io",
    R.string.about_link_source to "https://codeberg.org/inventaire/inventaire",
    R.string.about_link_donate to "https://inventaire.io/donate",
)

private const val INVENTAIRE_NAME: String = "inventaire.io"
private val VALUE_BADGE_SIDE: Dp = 40.dp

private val IconTop: Color = Color(red = 0.998f, green = 0.992f, blue = 0.971f)
private val IconBottom: Color = Color(red = 0.962f, green = 0.936f, blue = 0.781f)
private const val ICON_ART_SCALE: Float = 0.75f
private const val ICON_ART_LIFT: Float = 20.75f / 1024f
private const val ICON_CORNER_SHARE: Float = 0.2237f
