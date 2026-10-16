package studio.lunabee.nouveaurecit.data.sorting

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import kotlin.math.abs

/**
 * `DeterministicTiltTests`: the two failures invisible by eye at any amplitude — a process-seeded hash,
 * which looks perfect within one run and re-rolls on the next, and a fold that drops accents, which would
 * give a shelf of accented French names one shared angle. The pinned values are the iOS suite's: the two
 * apps lean the same text the same way.
 */
class DeterministicTiltTest {
    private val texts: List<String> = listOf(
        "Classiques français",
        "Littérature étrangère",
        "Le ministère des rêves",
        "Étincelles écosocialistes",
        "Le chaos qui vient",
        "Théâtre",
        "Poésie",
    )

    @Test
    fun everyAngleStaysWithinItsAmplitude() {
        for (amplitude in listOf(1.0, 10.0)) {
            for (text in texts + listOf("", " ", "A", "📚", "é".repeat(500))) {
                val angle: Double = DeterministicTilt.degrees(text, amplitude)
                assertTrue("$text: $angle", angle >= -amplitude && angle <= amplitude)
            }
        }
    }

    @Test
    fun theSameTextAlwaysLeansTheSameWay() {
        for (text in texts) {
            assertEquals(DeterministicTilt.degrees(text, 10.0), DeterministicTilt.degrees(text, 10.0), 0.0)
        }
    }

    /** Pinned to the iOS values: change the hash and this fails — which would re-roll every pile in the app. */
    @Test
    fun theFoldIsPinnedAcrossLaunches() {
        assertEquals(-2.90, DeterministicTilt.degrees("Science-fiction", 10.0), 0.01)
        assertEquals(3.69, DeterministicTilt.degrees("Poésie", 10.0), 0.01)
    }

    /** A fold that dropped the accents would hand these two the same angle. */
    @Test
    fun accentsChangeTheAngle() {
        assertNotEquals(DeterministicTilt.degrees("Poésie", 10.0), DeterministicTilt.degrees("Poesie", 10.0), 0.0)
    }

    /** Amplitude scales the same angle rather than picking a different one. */
    @Test
    fun amplitudeScalesTheSameLean() {
        for (text in texts) {
            val small: Double = DeterministicTilt.degrees(text, 1.0)
            val large: Double = DeterministicTilt.degrees(text, 10.0)
            assertTrue(abs(large - small * 10) < 0.0001)
        }
    }

    @Test
    fun neighbouringTextsDoNotShareAnAngle() {
        val angles: List<Double> = listOf("Livre 1", "Livre 2", "Livre 3", "Livre 4").map { DeterministicTilt.degrees(it, 10.0) }

        assertEquals(4, angles.toSet().size)
    }
}
