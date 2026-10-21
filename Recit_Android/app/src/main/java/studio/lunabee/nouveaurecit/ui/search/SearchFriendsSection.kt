package studio.lunabee.nouveaurecit.ui.search

import androidx.compose.foundation.background
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
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyListScope
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.People
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.onClick
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import coil3.compose.AsyncImage
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.db.ItemRow
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.SectionHeader
import studio.lunabee.nouveaurecit.designsystem.ShelfPalette
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.designsystem.TintedTextButton
import studio.lunabee.nouveaurecit.designsystem.shelfPaper
import studio.lunabee.nouveaurecit.ui.navigation.BookAnchor
import studio.lunabee.nouveaurecit.ui.navigation.Destination

/**
 * `SearchFriendsSection` (feature 0037): « Chez mes amis », a single row of my friends' books, most
 * recently added first — the news from their shelves, shown only while nothing is typed. Once a
 * query stands, my friends' copies answer next to mine in the local section, and the row leaves.
 *
 * With no friend at all, a paper tag toward Réseau stands in its place; what to draw is
 * [FriendsCarouselState]'s call.
 */
internal fun LazyListScope.searchFriendsSection(
    state: FriendsCarouselState,
    items: List<ItemRow>,
    onInvite: () -> Unit,
    onPush: (Destination) -> Unit,
) {
    when (state) {
        FriendsCarouselState.Hidden -> Unit
        FriendsCarouselState.Invitation -> {
            item(key = "friends.header") {
                SectionHeader(title = stringResource(R.string.inventory_search_friends_section), modifier = Modifier.padding(horizontal = Spacing.medium))
            }
            item(key = "friends.invite") {
                Box(Modifier.fillMaxWidth().padding(vertical = Spacing.small), contentAlignment = Alignment.Center) {
                    SearchFriendsInvitationTag(onClick = onInvite)
                }
            }
        }
        is FriendsCarouselState.Recent -> {
            item(key = "friends.header") {
                // Given the margin of the inset sections around it, so the titles line up.
                SectionHeader(
                    title = stringResource(R.string.inventory_search_friends_section),
                    modifier = Modifier.padding(horizontal = Spacing.medium),
                    trailing = if (state.showsSeeAll) {
                        {
                            TintedTextButton(
                                text = stringResource(R.string.inventory_search_see_all),
                                onClick = { onPush(Destination.FriendsLatestBooks) },
                            )
                        }
                    } else {
                        null
                    },
                )
            }
            item(key = "friends.carousel") {
                FriendsCarousel(items = items.take(state.shownCount), onOpen = { onPush(Destination.Book(BookAnchor.Item(it))) })
            }
        }
    }
}

/** The row itself, edge to edge; cards are sized from the row's width, as « Ranger mes livres » sizes them on iOS. */
@Composable
private fun FriendsCarousel(items: List<ItemRow>, onOpen: (String) -> Unit) {
    BoxWithConstraints(Modifier.fillMaxWidth()) {
        val metrics = FriendsCarouselMetrics(maxWidth.value)
        LazyRow(
            contentPadding = PaddingValues(horizontal = FriendsCarouselMetrics.MARGIN.dp),
            horizontalArrangement = Arrangement.spacedBy(FriendsCarouselMetrics.SPACING.dp),
        ) {
            items(items, key = { it.item.id }) { row ->
                FriendsCarouselCover(row = row, metrics = metrics, onOpen = { onOpen(row.item.id) })
            }
        }
    }
}

/**
 * `FriendsCarouselCover`: the card iOS's « Ranger mes livres » shows for a book waiting to be filed —
 * the cover face-on, its title under it, hanging from its top edge so one- and two-line titles keep
 * their covers on one line. Tapping it opens the book. TalkBack names the owner.
 */
@Composable
private fun FriendsCarouselCover(row: ItemRow, metrics: FriendsCarouselMetrics, onOpen: () -> Unit) {
    val owner: String? = row.owner?.username
    val spoken: String = if (owner != null) stringResource(R.string.inventory_search_friends_section_cover, row.title, owner) else row.title
    Column(
        modifier = Modifier
            .width(metrics.cardWidth.dp)
            .height(FriendsCarouselMetrics.CARD_HEIGHT.dp)
            .clickable(onClick = onOpen)
            .clearAndSetSemantics {
                contentDescription = spoken
                onClick {
                    onOpen()
                    true
                }
            }
            .padding(vertical = Spacing.xxSmall, horizontal = Spacing.small),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(Spacing.xSmall),
    ) {
        Box(Modifier.fillMaxWidth().height(FriendsCarouselMetrics.ART_HEIGHT.dp), contentAlignment = Alignment.Center) {
            CarouselCover(row = row, width = metrics.coverWidth.dp, height = metrics.coverHeight.dp)
        }
        Text(
            text = row.title,
            style = RecitTheme.typography.content300,
            color = RecitTheme.colors.foregroundDefault,
            textAlign = TextAlign.Center,
            maxLines = 2,
            overflow = TextOverflow.Ellipsis,
            modifier = Modifier.fillMaxWidth(),
        )
    }
}

/** A cover reserving its frame before the image lands, its title on parchment when there is none. */
@Composable
private fun CarouselCover(row: ItemRow, width: Dp, height: Dp) {
    val shape = RoundedCornerShape(2.dp)
    Box(
        modifier = Modifier
            .size(width = width, height = height)
            .shadow(elevation = 2.dp, shape = shape)
            .clip(shape)
            .background(ShelfPalette.Parchment),
    ) {
        if (!row.image.isNullOrEmpty()) {
            AsyncImage(model = row.image, contentDescription = null, contentScale = ContentScale.Crop, modifier = Modifier.fillMaxSize())
        } else {
            Text(
                text = row.title,
                style = RecitTheme.typography.footnote200,
                color = ShelfPalette.LabelInk,
                maxLines = 4,
                overflow = TextOverflow.Ellipsis,
                modifier = Modifier.padding(Spacing.xSmall),
            )
        }
    }
}

/**
 * `SearchFriendsInvitationTag`: for a reader with no friend yet, a paper tag — the empty shelf's and
 * the empty Lists tab's paper — that takes them to Réseau, the one place a friend can be found.
 */
@Composable
private fun SearchFriendsInvitationTag(onClick: () -> Unit) {
    val title: String = stringResource(R.string.inventory_search_friends_section_invite_title)
    val detail: String = stringResource(R.string.inventory_search_friends_section_invite_detail)
    Column(
        modifier = Modifier
            .shelfPaper(title)
            .clickable(onClickLabel = detail, onClick = onClick)
            .semantics(mergeDescendants = true) {}
            .padding(horizontal = Spacing.medium, vertical = Spacing.sMedium),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(Spacing.xSmall),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(Spacing.xSmall)) {
            Icon(Icons.Outlined.People, contentDescription = null, tint = ShelfPalette.LabelInk, modifier = Modifier.size(18.dp))
            Text(title, style = RecitTheme.typography.content400Bold, color = ShelfPalette.LabelInk, maxLines = 1)
        }
        Text(detail, style = RecitTheme.typography.footnote200, color = ShelfPalette.LabelInk, maxLines = 2, textAlign = TextAlign.Center)
    }
}
