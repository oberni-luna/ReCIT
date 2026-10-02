package studio.lunabee.nouveaurecit.designsystem

import androidx.compose.runtime.Immutable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color

/**
 * The semantic colours of `DesignSystem/Tokens/Color.swift`, light and dark.
 *
 * Code is the source of truth, exactly as on iOS: a screen reads `RecitTheme.colors.foregroundTinted`,
 * never a literal `Color`.
 */
@Immutable
data class RecitColors(
    val foregroundDefault: Color,
    val foregroundInverse: Color,
    val foregroundDisable: Color,
    val foregroundSecondary: Color,
    val foregroundTinted: Color,
    val foregroundTintedInverse: Color,
    val foregroundError: Color,
    val foregroundPlaceholder: Color,
    val backgroundDefault: Color,
    val backgroundInverse: Color,
    val backgroundDisable: Color,
    val backgroundSecondary: Color,
    val backgroundTinted: Color,
    val backgroundTintedInverse: Color,
    val backgroundError: Color,
    val borderDefault: Color,
    val isDark: Boolean,
) {
    val borderTinted: Color get() = foregroundTinted
    val borderError: Color get() = foregroundError

    companion object {
        val Light: RecitColors = RecitColors(
            foregroundDefault = Primitive.Gray900,
            foregroundInverse = Primitive.Gray50,
            foregroundDisable = Primitive.Gray400,
            foregroundSecondary = Color.Black.copy(alpha = 0.5f),
            foregroundTinted = Primitive.Green700,
            foregroundTintedInverse = Primitive.Green100,
            foregroundError = Primitive.Red800,
            foregroundPlaceholder = Color.Black.copy(alpha = 0.4f),
            backgroundDefault = Primitive.Gray0,
            backgroundInverse = Primitive.Gray900,
            backgroundDisable = Primitive.Gray200,
            backgroundSecondary = Primitive.Gray50,
            backgroundTinted = Primitive.Green100,
            backgroundTintedInverse = Primitive.Green800,
            backgroundError = Primitive.Red100,
            borderDefault = Color.Black.copy(alpha = 0.1f),
            isDark = false,
        )

        val Dark: RecitColors = RecitColors(
            foregroundDefault = Primitive.Gray50,
            foregroundInverse = Primitive.Gray900,
            foregroundDisable = Color.White.copy(alpha = 0.5f),
            foregroundSecondary = Color.White.copy(alpha = 0.6f),
            foregroundTinted = Primitive.Green200,
            foregroundTintedInverse = Primitive.Green900,
            foregroundError = Primitive.Red400,
            foregroundPlaceholder = Color.White.copy(alpha = 0.3f),
            backgroundDefault = Primitive.Gray1000,
            backgroundInverse = Primitive.Gray200,
            backgroundDisable = Color.White.copy(alpha = 0.1f),
            backgroundSecondary = Primitive.Gray800,
            backgroundTinted = Primitive.Green900,
            backgroundTintedInverse = Primitive.Green200,
            backgroundError = Primitive.Gray700,
            borderDefault = Color.White.copy(alpha = 0.1f),
            isDark = true,
        )
    }
}

/** the colour sets of `Assets.xcassets`. Only the design system reads these. */
object Primitive {
    val Gray0: Color = Color(0xFFFFFFFF)
    val Gray50: Color = Color(0xFFF1F1F1)
    val Gray200: Color = Color(0xFFE8ECE6)
    val Gray400: Color = Color(0xFFAFAFAF)
    val Gray500: Color = Color(0xFF959A92)
    val Gray600: Color = Color(0xFF7E837C)
    val Gray700: Color = Color(0xFF2D2D2D)
    val Gray800: Color = Color(0xFF2A2A2A)
    val Gray900: Color = Color(0xFF191919)
    val Gray1000: Color = Color(0xFF000000)
    val Green100: Color = Color(0xFFF2FAE9)
    val Green200: Color = Color(0xFFE7FFCE)
    val Green300: Color = Color(0xFFD8FFB1)
    val Green400: Color = Color(0xFFB6DA9F)
    val Green500: Color = Color(0xFF90CF8E)
    val Green600: Color = Color(0xFF579F66)
    val Green700: Color = Color(0xFF558154)
    val Green800: Color = Color(0xFF3A5A40)
    val Green900: Color = Color(0xFF344E41)
    val Red100: Color = Color(0xFFF1E4DB)
    val Red400: Color = Color(0xFFE14D4D)
    val Red800: Color = Color(0xFF821F1F)
    val Yellow300: Color = Color(0xFFFDF1A8)
    val Yellow400: Color = Color(0xFFF5D36E)
}

/** `Features/Shelves/ShelfPalette.swift` — the paper labels, in both appearances. */
object ShelfPalette {
    val Parchment: Color = Color(0xFFE4DAC4)
    val LabelPaper: Color = Primitive.Gray0
    val LabelInk: Color = Primitive.Gray900
    val LabelInkSecondary: Color = Primitive.Gray900.copy(alpha = 0.5f)
    val LabelLink: Color = Primitive.Green700
}

val LocalRecitColors = staticCompositionLocalOf { RecitColors.Light }
