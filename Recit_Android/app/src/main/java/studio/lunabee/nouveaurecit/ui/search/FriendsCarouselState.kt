package studio.lunabee.nouveaurecit.ui.search

/**
 * `Model/SearchResult/FriendsCarouselState.swift`: what « Chez mes amis » draws in the Recherche tab
 * — nothing, an invitation to find readers, or my friends' latest books. Pure, so the rule is driven
 * by values in a test.
 *
 * Three decisions live here:
 * 1. **Rest only.** The carousel is discovery, not an answer: from the first character typed, my
 *    friends' copies answer in the local section, next to mine.
 * 2. **No friend is an invitation, friends without books are silence.**
 * 3. **Ten at most, and « Tout voir » past ten** — never at exactly ten, so the action always leads
 *    to something the row did not show.
 */
sealed interface FriendsCarouselState {
    data object Hidden : FriendsCarouselState

    data object Invitation : FriendsCarouselState

    data class Recent(val shownCount: Int, val showsSeeAll: Boolean) : FriendsCarouselState

    companion object {
        /** How many of my friends' books the carousel shows. */
        const val LIMIT: Int = 10

        fun current(phase: SearchPhase, hasFriends: Boolean, friendsBookCount: Int): FriendsCarouselState = when {
            phase != SearchPhase.Recents -> Hidden
            !hasFriends -> Invitation
            friendsBookCount <= 0 -> Hidden
            else -> Recent(shownCount = minOf(LIMIT, friendsBookCount), showsSeeAll = friendsBookCount > LIMIT)
        }
    }
}

/**
 * `SortGridMetrics`' book column, which « Chez mes amis » shares with « Ranger mes livres » on iOS:
 * three cards, three gutters, one margin, and 40 dp of the fourth card showing — the peek is the only
 * thing that says the row scrolls. Plain numbers (dp as `Float`), so they test without Compose.
 */
data class FriendsCarouselMetrics(val containerWidth: Float) {
    val cardWidth: Float
        get() = ((containerWidth - (MARGIN + SPACING * COLUMNS + PEEK)) / COLUMNS).coerceAtLeast(0f)

    /** As wide as the card allows without touching its neighbour, capped at the art's height. */
    val coverWidth: Float get() = cardWidth * COVER_WIDTH_SHARE
    val coverHeight: Float get() = minOf(ART_HEIGHT, coverWidth / COVER_ASPECT_RATIO)

    companion object {
        const val MARGIN: Float = 16f
        const val SPACING: Float = 12f
        const val PEEK: Float = 40f
        const val COLUMNS: Int = 3
        const val CARD_HEIGHT: Float = 158f
        const val ART_HEIGHT: Float = 100f
        const val COVER_WIDTH_SHARE: Float = 0.62f
        const val COVER_ASPECT_RATIO: Float = 2f / 3f
    }
}
