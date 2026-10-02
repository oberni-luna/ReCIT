package studio.lunabee.nouveaurecit.ui.common

import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.time.format.FormatStyle
import java.util.Locale

/** Dates as the iOS screens print them, from the server's epoch milliseconds or ISO strings. */
object Formatting {
    private val zone: ZoneId get() = ZoneId.systemDefault()

    /** « 3 octobre 2026 » — `Depuis le %@`, `Créé le %@`. */
    fun longDate(epochMillis: Double): String =
        Instant.ofEpochMilli(epochMillis.toLong()).atZone(zone).toLocalDate()
            .format(DateTimeFormatter.ofLocalizedDate(FormatStyle.LONG).withLocale(Locale.FRENCH))

    /** « octobre 2026 » — `Membre depuis %@`. */
    fun monthYear(epochMillis: Double): String =
        Instant.ofEpochMilli(epochMillis.toLong()).atZone(zone).toLocalDate()
            .format(DateTimeFormatter.ofPattern("LLLL yyyy", Locale.FRENCH))

    /** A Wikidata date (`1952-03-11`, `1952-03`, `1952`) as a long date, or the raw value when it is partial. */
    fun wikidataDate(value: String?): String? {
        if (value.isNullOrBlank()) return null
        return runCatching {
            LocalDate.parse(value.take(10)).format(DateTimeFormatter.ofLocalizedDate(FormatStyle.LONG).withLocale(Locale.FRENCH))
        }.getOrElse { value.take(4) }
    }
}
