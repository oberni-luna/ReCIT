package studio.lunabee.nouveaurecit.designsystem

import android.app.Activity
import android.view.View
import android.view.Window
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.ColorScheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Typography
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.ReadOnlyComposable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

/**
 * The app theme. The tokens are the source of truth; the Material colour scheme and typography
 * are derived from them so that framework components — `TopAppBar`, `NavigationBar`,
 * `SearchBar`, dialogs — wear the same palette without each screen restating it.
 *
 * `darkTheme` is forced to `true` by the signed-out flow, which iOS pins to dark mode.
 */
@Composable
fun RecitTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit,
) {
    val colors: RecitColors = if (darkTheme) RecitColors.Dark else RecitColors.Light
    val typography: RecitTypography = RecitTypography.Default
    val view: View = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window: Window = (view.context as? Activity)?.window ?: return@SideEffect
            WindowCompat.getInsetsController(window, view).apply {
                isAppearanceLightStatusBars = !darkTheme
                isAppearanceLightNavigationBars = !darkTheme
            }
        }
    }

    CompositionLocalProvider(
        LocalRecitColors provides colors,
        LocalRecitTypography provides typography,
    ) {
        MaterialTheme(
            colorScheme = colors.toMaterial(),
            typography = typography.toMaterial(),
            content = content,
        )
    }
}

object RecitTheme {
    val colors: RecitColors
        @Composable @ReadOnlyComposable get() = LocalRecitColors.current

    val typography: RecitTypography
        @Composable @ReadOnlyComposable get() = LocalRecitTypography.current
}

private fun RecitColors.toMaterial(): ColorScheme {
    val base: ColorScheme = if (isDark) darkColorScheme() else lightColorScheme()
    return base.copy(
        primary = foregroundTinted,
        onPrimary = foregroundTintedInverse,
        primaryContainer = backgroundTinted,
        onPrimaryContainer = foregroundTinted,
        secondaryContainer = backgroundTinted,
        onSecondaryContainer = foregroundTinted,
        background = backgroundDefault,
        onBackground = foregroundDefault,
        surface = backgroundDefault,
        onSurface = foregroundDefault,
        surfaceVariant = backgroundSecondary,
        onSurfaceVariant = foregroundSecondary,
        surfaceContainerLowest = backgroundDefault,
        surfaceContainerLow = backgroundSecondary,
        surfaceContainer = backgroundSecondary,
        surfaceContainerHigh = backgroundSecondary,
        surfaceContainerHighest = backgroundDisable,
        inverseSurface = backgroundInverse,
        inverseOnSurface = foregroundInverse,
        error = foregroundError,
        errorContainer = backgroundError,
        onErrorContainer = foregroundError,
        outline = foregroundSecondary,
        outlineVariant = borderDefault,
    )
}

private fun RecitTypography.toMaterial(): Typography = Typography(
    displaySmall = title200,
    headlineMedium = title200,
    headlineSmall = title50,
    titleLarge = title50,
    titleMedium = content400Bold,
    titleSmall = action200,
    bodyLarge = content400,
    bodyMedium = content300,
    bodySmall = footnote200,
    labelLarge = action300,
    labelMedium = action200,
    labelSmall = caption200,
)
