package studio.lunabee.nouveaurecit.ui.common

import android.os.Build
import androidx.compose.ui.graphics.Color
import studio.lunabee.nouveaurecit.designsystem.RecitColors

/**
 * What the Plein écran lies on — iOS `FullScreenCoverView`'s Regular material (feature 0085). Android
 * blurs the window behind only from Android 12, and only while the system allows it: battery saver,
 * a low-end device or a developer option turns cross-window blur off at any time.
 */
enum class FullScreenBackdrop {
    /** The screen it opened from, blurred, under the theme's translucent [RecitColors.backgroundMaterial]. */
    Blurred,

    /** No blur to be had: the theme's ground, opaque. */
    Opaque,
    ;

    /** The veil drawn over the window behind, in [colors]' appearance. */
    fun veil(colors: RecitColors): Color = when (this) {
        Blurred -> colors.backgroundMaterial
        Opaque -> colors.backgroundDefault
    }

    companion object {
        /** Blurred on Android 12 and later ([sdkInt]) while [isCrossWindowBlurEnabled], opaque otherwise. */
        fun of(sdkInt: Int, isCrossWindowBlurEnabled: Boolean): FullScreenBackdrop =
            if (sdkInt >= Build.VERSION_CODES.S && isCrossWindowBlurEnabled) Blurred else Opaque
    }
}
