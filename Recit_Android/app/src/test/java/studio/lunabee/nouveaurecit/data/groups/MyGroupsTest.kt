package studio.lunabee.nouveaurecit.data.groups

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/** `MyGroupsTests`: the sections of the Groupes segment, and what the tab's badge counts. */
class MyGroupsTest {
    @Test
    fun eachGroupGoesToTheSectionOfMyRoleByName() {
        val groups: MyGroups = MyGroups.of(
            listOf(
                group(id = "b", name = "Polars", admins = listOf("me")),
                group(id = "a", name = "Bédés", members = listOf("me")),
                group(id = "c", name = "Voisins", invited = listOf("me")),
                group(id = "d", name = "Poésie", requested = listOf("me")),
                group(id = "e", name = "Déclinés", declined = listOf("me")),
                group(id = "f", name = "Inconnus"),
            ),
            me = "me",
        )
        assertEquals(listOf("a", "b"), groups.mine.map { it.id })
        assertEquals(listOf("c"), groups.invitations.map { it.id })
        assertEquals(listOf("d"), groups.sentRequests.map { it.id })
    }

    @Test
    fun theRequestsToReviewCountOnlyInTheGroupsIAdminister() {
        val groups: MyGroups = MyGroups.of(
            listOf(
                group(id = "a", admins = listOf("me"), requested = listOf("x", "y")),
                group(id = "b", members = listOf("me"), requested = listOf("z")),
                group(id = "c", invited = listOf("me")),
            ),
            me = "me",
        )
        assertEquals(2, groups.requestsToReview)
        assertEquals(3, groups.pendingCount)
    }

    @Test
    fun withoutASignedInReaderNothingIsMine() {
        val groups: MyGroups = MyGroups.of(listOf(group(admins = listOf("me"))), me = null)
        assertTrue(groups.isEmpty)
        assertEquals(0, groups.pendingCount)
    }

    @Test
    fun twoGroupsOfTheSameNameKeepOneOrder() {
        val groups: List<ReaderGroup> = listOf(group(id = "b", members = listOf("me")), group(id = "a", members = listOf("me")))
        assertEquals(listOf("a", "b"), MyGroups.of(groups, me = "me").mine.map { it.id })
        assertEquals(listOf("a", "b"), MyGroups.of(groups.reversed(), me = "me").mine.map { it.id })
    }
}
