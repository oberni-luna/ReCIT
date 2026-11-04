package studio.lunabee.nouveaurecit.ui.network

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/** `ProfileHeaderCollapseTests`. */
class ProfileHeaderCollapseTest {
    private val collapse: ProfileHeaderCollapse = ProfileHeaderCollapse(distance = 100f)

    @Test
    fun the_fold_runs_from_rest_to_folded_over_its_distance() {
        assertEquals(0f, collapse.progress(-20f), 0f)
        assertEquals(0.25f, collapse.progress(25f), 0f)
        assertEquals(1f, collapse.progress(400f), 0f)
    }

    @Test
    fun the_page_passes_under_the_header_only_past_the_fold() {
        assertFalse(collapse.isContentUnder(100f))
        assertTrue(collapse.isContentUnder(101f))
    }

    @Test
    fun a_scroll_ending_inside_the_fold_rests_on_the_nearer_end() {
        assertEquals(0f, collapse.restingOffset(49f), 0f)
        assertEquals(100f, collapse.restingOffset(50f), 0f)
        assertEquals(0f, collapse.restingOffset(0f), 0f)
        assertEquals(300f, collapse.restingOffset(300f), 0f)
    }

    @Test
    fun the_fold_is_blended_between_the_two_pages_on_screen() {
        val offsets: List<Float> = listOf(2_000f, 0f, 50f)
        assertEquals(1f, collapse.progress(offsets, 0f), 0f)
        assertEquals(0.5f, collapse.progress(offsets, 0.5f), 0f)
        assertEquals(0.25f, collapse.progress(offsets, 1.5f), 0f)
        assertEquals(0.5f, collapse.progress(offsets, 7f), 0f)
    }

    @Test
    fun blending_nothing_is_at_rest() {
        assertEquals(0f, ProfileHeaderCollapse.blend(emptyList(), 0.5f), 0f)
    }

    @Test
    fun a_short_page_gets_the_room_to_fold_whole() {
        assertEquals(300f, collapse.trailingRoom(contentHeight = 600f, viewportHeight = 800f), 0f)
        assertEquals(0f, collapse.trailingRoom(contentHeight = 2_000f, viewportHeight = 800f), 0f)
    }
}
