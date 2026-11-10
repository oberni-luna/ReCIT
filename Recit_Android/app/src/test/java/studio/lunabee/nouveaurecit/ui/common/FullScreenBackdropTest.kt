package studio.lunabee.nouveaurecit.ui.common

import androidx.compose.ui.graphics.luminance
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import studio.lunabee.nouveaurecit.designsystem.RecitColors

/*
 * What the Plein écran lies on (iOS feature 0085): the screen behind blurred under a translucent veil
 * where Android can blur another window — Android 12 and later, while the system allows it — and an
 * opaque veil of the theme everywhere else, never black in light mode.
 */
class FullScreenBackdropTest {
    private val android11: Int = 30
    private val android12: Int = 31
    private val android16: Int = 36

    @Test
    fun android12WithCrossWindowBlurIsBlurred() {
        assertEquals(FullScreenBackdrop.Blurred, FullScreenBackdrop.of(android12, isCrossWindowBlurEnabled = true))
        assertEquals(FullScreenBackdrop.Blurred, FullScreenBackdrop.of(android16, isCrossWindowBlurEnabled = true))
    }

    @Test
    fun blurTurnedOffBySystemIsOpaque() {
        assertEquals(FullScreenBackdrop.Opaque, FullScreenBackdrop.of(android12, isCrossWindowBlurEnabled = false))
    }

    @Test
    fun beforeAndroid12IsOpaque() {
        assertEquals(FullScreenBackdrop.Opaque, FullScreenBackdrop.of(android11, isCrossWindowBlurEnabled = true))
        assertEquals(FullScreenBackdrop.Opaque, FullScreenBackdrop.of(android11, isCrossWindowBlurEnabled = false))
    }

    @Test
    fun blurredVeilIsTheThemesTranslucentMaterial() {
        assertEquals(RecitColors.Light.backgroundMaterial, FullScreenBackdrop.Blurred.veil(RecitColors.Light))
        assertEquals(RecitColors.Dark.backgroundMaterial, FullScreenBackdrop.Blurred.veil(RecitColors.Dark))
        assertTrue(RecitColors.Light.backgroundMaterial.alpha < 1f)
        assertTrue(RecitColors.Dark.backgroundMaterial.alpha < 1f)
    }

    @Test
    fun opaqueVeilIsTheThemesGroundLightInLightMode() {
        assertEquals(RecitColors.Light.backgroundDefault, FullScreenBackdrop.Opaque.veil(RecitColors.Light))
        assertEquals(RecitColors.Dark.backgroundDefault, FullScreenBackdrop.Opaque.veil(RecitColors.Dark))
        assertEquals(1f, FullScreenBackdrop.Opaque.veil(RecitColors.Light).alpha, 0f)
        assertTrue(FullScreenBackdrop.Opaque.veil(RecitColors.Light).luminance() > 0.5f)
    }
}
