package studio.lunabee.nouveaurecit.data

import java.util.Locale

/**
 * The language the app's own words are written in: French, `res/values` being its only translation. Language names,
 * months and dates are spelt in it, so that « Langue du compte » reads « Français » and not « French » on a phone set
 * to English. A book's content follows the phone instead (`Locale.getDefault()`), as on iOS (0063).
 */
object TextLocale {
    val current: Locale = Locale.FRENCH
}
