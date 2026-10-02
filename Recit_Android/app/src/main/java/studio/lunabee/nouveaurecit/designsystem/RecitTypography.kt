package studio.lunabee.nouveaurecit.designsystem

import androidx.compose.runtime.Immutable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp
import studio.lunabee.nouveaurecit.R

/**
 * `DesignSystem/Tokens/TextStyle.swift`. Sizes are in `sp`, so they follow the system font
 * scale the way `UIFontMetrics` follows Dynamic Type.
 */
@Immutable
data class RecitTypography(
    val title200: TextStyle,
    val title50: TextStyle,
    val content400Bold: TextStyle,
    val content400: TextStyle,
    val content300: TextStyle,
    val footnote200: TextStyle,
    val footnote200Bold: TextStyle,
    val action300: TextStyle,
    val action200: TextStyle,
    val caption200: TextStyle,
) {
    companion object {
        val Alegreya: FontFamily = FontFamily(
            Font(R.font.alegreya_regular, FontWeight.Normal),
            Font(R.font.alegreya_medium, FontWeight.Medium),
            Font(R.font.alegreya_semibold, FontWeight.SemiBold),
            Font(R.font.alegreya_bold, FontWeight.Bold),
            Font(R.font.alegreya_extrabold, FontWeight.ExtraBold),
        )

        val OpenSans: FontFamily = FontFamily(
            Font(R.font.opensans_regular, FontWeight.Normal),
            Font(R.font.opensans_semibold, FontWeight.SemiBold),
            Font(R.font.opensans_bold, FontWeight.Bold),
            Font(R.font.opensans_extrabold, FontWeight.ExtraBold),
        )

        val Default: RecitTypography = RecitTypography(
            title200 = TextStyle(fontFamily = OpenSans, fontWeight = FontWeight.ExtraBold, fontSize = 32.sp),
            title50 = TextStyle(fontFamily = OpenSans, fontWeight = FontWeight.ExtraBold, fontSize = 18.sp),
            content400Bold = TextStyle(fontFamily = Alegreya, fontWeight = FontWeight.Bold, fontSize = 19.sp),
            content400 = TextStyle(fontFamily = Alegreya, fontWeight = FontWeight.Medium, fontSize = 19.sp),
            content300 = TextStyle(fontFamily = Alegreya, fontWeight = FontWeight.Medium, fontSize = 17.sp),
            footnote200 = TextStyle(fontFamily = Alegreya, fontWeight = FontWeight.Normal, fontSize = 12.sp),
            footnote200Bold = TextStyle(fontFamily = Alegreya, fontWeight = FontWeight.Bold, fontSize = 12.sp),
            action300 = TextStyle(fontFamily = OpenSans, fontWeight = FontWeight.SemiBold, fontSize = 17.sp),
            action200 = TextStyle(fontFamily = OpenSans, fontWeight = FontWeight.SemiBold, fontSize = 12.sp),
            caption200 = TextStyle(fontFamily = OpenSans, fontWeight = FontWeight.Normal, fontSize = 12.sp),
        )
    }
}

val LocalRecitTypography = staticCompositionLocalOf { RecitTypography.Default }
