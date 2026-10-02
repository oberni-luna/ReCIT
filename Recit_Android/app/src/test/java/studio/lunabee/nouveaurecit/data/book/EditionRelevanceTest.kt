package studio.lunabee.nouveaurecit.data.book

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import studio.lunabee.nouveaurecit.data.book.EditionRelevance.Candidate

/** `EditionRelevance`'s five decisions: the ladder, its two tie-breaks, and its floor. */
class EditionRelevanceTest {
    private fun best(vararg candidates: Candidate, originalLang: String? = null): String? =
        EditionRelevance.best(candidates.toList(), preferredLang = "fr", originalLang = originalLang)?.id

    @Test
    fun noCandidateAnswersNull() {
        assertNull(best())
    }

    @Test
    fun preferredLanguageWithTitleAndCoverWins() {
        assertEquals(
            "fr-complete",
            best(
                Candidate("en-complete", "en", hasTitle = true, hasCover = true),
                Candidate("fr-titled", "fr", hasTitle = true, hasCover = false),
                Candidate("fr-complete", "fr", hasTitle = true, hasCover = true),
            ),
        )
    }

    @Test
    fun preferredLanguageWithoutCoverBeatsAnotherLanguageWithOne() {
        assertEquals(
            "fr-titled",
            best(
                Candidate("en-complete", "en", hasTitle = true, hasCover = true),
                Candidate("fr-titled", "fr", hasTitle = true, hasCover = false),
            ),
        )
    }

    @Test
    fun originalLanguageCompleteBeatsAnyTitledEdition() {
        assertEquals(
            "ja-complete",
            best(
                Candidate("en-titled", "en", hasTitle = true, hasCover = false),
                Candidate("ja-complete", "ja", hasTitle = true, hasCover = true),
                originalLang = "ja",
            ),
        )
    }

    @Test
    fun unknownOriginalLanguageDoesNotMatchUnknownEditionLanguage() {
        // Both rungs above "titled" miss; the first titled candidate answers, in order.
        assertEquals(
            "en",
            best(
                Candidate("en", "en", hasTitle = true, hasCover = false),
                Candidate("unknown", null, hasTitle = true, hasCover = true),
                originalLang = null,
            ),
        )
    }

    @Test
    fun anUntitledEditionIsNeverOpened() {
        assertNull(
            best(
                Candidate("fr-nameless", "fr", hasTitle = false, hasCover = true),
                Candidate("en-nameless", "en", hasTitle = false, hasCover = false),
            ),
        )
    }

    @Test
    fun aSingleBookBeatsABoxInsideTheWinningTier() {
        assertEquals(
            "single",
            best(
                Candidate("box", "fr", hasTitle = true, hasCover = true, isHeld = true, isSingleWork = false),
                Candidate("single", "fr", hasTitle = true, hasCover = true),
            ),
        )
    }

    @Test
    fun aBoxStillAnswersWhenItIsAllTheTierHolds() {
        assertEquals(
            "box",
            best(
                Candidate("box", "fr", hasTitle = true, hasCover = true, isSingleWork = false),
                Candidate("en-single", "en", hasTitle = true, hasCover = true),
            ),
        )
    }

    @Test
    fun beingHeldBreaksTiesInsideTheTier() {
        assertEquals(
            "held",
            best(
                Candidate("first", "fr", hasTitle = true, hasCover = true),
                Candidate("held", "fr", hasTitle = true, hasCover = true, isHeld = true),
            ),
        )
    }

    @Test
    fun beingHeldDoesNotLiftALowerTier() {
        assertEquals(
            "fr",
            best(
                Candidate("es-held", "es", hasTitle = true, hasCover = true, isHeld = true),
                Candidate("fr", "fr", hasTitle = true, hasCover = true),
            ),
        )
    }

    @Test
    fun theFirstCandidateAnswersATie() {
        assertEquals(
            "a",
            best(
                Candidate("a", "fr", hasTitle = true, hasCover = true),
                Candidate("b", "fr", hasTitle = true, hasCover = true),
            ),
        )
    }
}
