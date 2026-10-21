package studio.lunabee.nouveaurecit.ui.search

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class FriendsCarouselStateTest {
    @Test
    fun hiddenAsSoonAsSomethingIsTyped() {
        assertEquals(FriendsCarouselState.Hidden, FriendsCarouselState.current(SearchPhase.Typing("z"), hasFriends = true, friendsBookCount = 4))
        assertEquals(FriendsCarouselState.Hidden, FriendsCarouselState.current(SearchPhase.Results("zola"), hasFriends = false, friendsBookCount = 0))
    }

    @Test
    fun noFriendIsAnInvitation() {
        assertEquals(FriendsCarouselState.Invitation, FriendsCarouselState.current(SearchPhase.Recents, hasFriends = false, friendsBookCount = 0))
    }

    @Test
    fun friendsWithoutBooksDrawNothing() {
        assertEquals(FriendsCarouselState.Hidden, FriendsCarouselState.current(SearchPhase.Recents, hasFriends = true, friendsBookCount = 0))
    }

    @Test
    fun tenAtMostAndSeeAllOnlyPastTen() {
        assertEquals(FriendsCarouselState.Recent(3, false), FriendsCarouselState.current(SearchPhase.Recents, hasFriends = true, friendsBookCount = 3))
        assertEquals(FriendsCarouselState.Recent(10, false), FriendsCarouselState.current(SearchPhase.Recents, hasFriends = true, friendsBookCount = 10))
        assertEquals(FriendsCarouselState.Recent(10, true), FriendsCarouselState.current(SearchPhase.Recents, hasFriends = true, friendsBookCount = 11))
    }

    @Test
    fun theRowLeavesRoomForAPeekAtEveryWidth() {
        for (width in listOf(320f, 360f, 393f, 430f)) {
            val metrics = FriendsCarouselMetrics(width)
            val laidOut: Float = FriendsCarouselMetrics.MARGIN + (metrics.cardWidth + FriendsCarouselMetrics.SPACING) * 3
            assertTrue(width - laidOut > FriendsCarouselMetrics.PEEK - 0.01f)
        }
    }

    @Test
    fun theCardMatchesTheMockupOnAThreeNinetyThreeScreen() {
        assertEquals(100.333f, FriendsCarouselMetrics(393f).cardWidth, 0.01f)
    }

    @Test
    fun aCoverIsCappedAtTheArtsHeightAndNeverNegative() {
        assertTrue(FriendsCarouselMetrics(2000f).coverHeight <= FriendsCarouselMetrics.ART_HEIGHT)
        assertEquals(0f, FriendsCarouselMetrics(8f).cardWidth)
    }
}
