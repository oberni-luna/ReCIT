package studio.lunabee.nouveaurecit.data.sorting

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * `SortDraftNameRuleTests`: what may become a new étagère, and what is refused before it reaches the
 * stack. The rule exists so that applying can never produce two étagères the user *reads* as the same —
 * hence the accents and the capitals below.
 */
class SortDraftNameRuleTest {
    private val library: SortSnapshot = SortSnapshot(
        shelves = listOf(SortSnapshot.Shelf("s1", "Romans", listOf("1")), SortSnapshot.Shelf("s2", "Poésie", emptyList())),
        books = listOf(SortBook("1", "Livre 1"), SortBook("2", "Livre 2")),
    )

    private fun rule(changes: List<SortChange> = emptyList()): SortDraftNameRule = SortDraftNameRule(SortProjection(library, changes).sections)

    // A name already on the shelf

    @Test
    fun aNameNothingUsesIsAccepted() {
        assertTrue(rule().accepts("Science-fiction"))
        assertNull(rule().refusal("Science-fiction"))
    }

    /** However it is typed, a name the user already has is refused — naming their étagère in its own spelling. */
    @Test
    fun aNameMatchingAnEtagereTheUserAlreadyHasIsRefused() {
        for (typed in listOf("Romans", "romans", "ROMANS", "Rômans", " Romans ", "  rOmAnS  ")) {
            assertFalse(typed, rule().accepts(typed))
            assertEquals(typed, SortDraftNameRule.Refusal.AlreadyUsed("Romans"), rule().refusal(typed))
        }
    }

    /** Accents are not a second étagère, either way round. */
    @Test
    fun anAccentIsNotASecondEtagere() {
        for (typed in listOf("Poésie", "poesie", "POESIE", "Poesie ")) {
            assertEquals(typed, SortDraftNameRule.Refusal.AlreadyUsed("Poésie"), rule().refusal(typed))
        }
    }

    // A name already on the stack

    /** A draft made a moment ago is refused exactly as an étagère the server holds. */
    @Test
    fun aNameMatchingAnotherDraftIsRefused() {
        val taken: SortDraftNameRule = rule(listOf(SortChange.CreateShelf(SortDraftId.make(), "Science-fiction")))
        for (typed in listOf("Science-fiction", "science-fiction", "SCIENCE-FICTION", " Science-Fiction ")) {
            assertFalse(typed, taken.accepts(typed))
            assertEquals(typed, SortDraftNameRule.Refusal.AlreadyUsed("Science-fiction"), taken.refusal(typed))
        }
    }

    /** A draft holding no books is still a section on screen, so its name is still taken. */
    @Test
    fun anEmptyDraftStillTakesItsName() {
        val taken: SortDraftNameRule = rule(listOf(SortChange.CreateShelf(SortDraftId.make(), "Essais")))

        assertFalse(taken.accepts("essais"))
    }

    /** The étagères the server holds and the drafts on the stack are one list of taken names. */
    @Test
    fun existingEtageresAndDraftsAreRefusedByTheSameRule() {
        val taken: SortDraftNameRule = rule(listOf(SortChange.CreateShelf(SortDraftId.make(), "Essais")))

        assertFalse(taken.accepts("romans"))
        assertFalse(taken.accepts("essais"))
        assertTrue(taken.accepts("Bandes dessinées"))
    }

    // Nothing typed, and the pile

    @Test
    fun aBlankNameIsNotAName() {
        for (typed in listOf("", " ", "\n", "   \t ")) {
            assertFalse(rule().accepts(typed))
            assertEquals(SortDraftNameRule.Refusal.Blank, rule().refusal(typed))
        }
    }

    /** « À ranger » is not an étagère and has no name of its own, so nothing collides with it. */
    @Test
    fun thePileIsNotANameAnythingCollidesWith() {
        assertTrue(rule().accepts("À ranger"))
    }
}
