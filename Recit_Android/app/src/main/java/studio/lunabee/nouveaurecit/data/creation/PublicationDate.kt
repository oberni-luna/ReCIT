package studio.lunabee.nouveaurecit.data.creation

import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.Locale

/**
 * `PublicationDate` (iOS feature 0050): an edition's `wdt:P577` as inventaire.io stores it — a year, a
 * month or a day, `2023`, `2023-03`, `2023-03-15` — never more precise than what the book prints. The
 * website's `isSimpleDay` accepts exactly those three shapes.
 */
data class PublicationDate(
    val year: Int,
    /** 1 to 12; ignored below [Precision.Month]. */
    val month: Int = 1,
    /** 1 to 31; ignored below [Precision.Day]. */
    val day: Int = 1,
    val precision: Precision,
) {
    enum class Precision { Year, Month, Day }

    /** The value as it goes on the wire. */
    val claim: String
        get() {
            val year: String = year.toString().padStart(4, '0')
            return when (precision) {
                Precision.Year -> year
                Precision.Month -> "$year-${month.toString().padStart(2, '0')}"
                Precision.Day -> "$year-${month.toString().padStart(2, '0')}-${day.toString().padStart(2, '0')}"
            }
        }

    /** The date as the form prints it, at its own precision: « 2023 », « mars 2023 », « 15 mars 2023 ». */
    fun displayed(locale: Locale = Locale.getDefault()): String {
        val date: LocalDate = toLocalDate() ?: return claim
        return when (precision) {
            Precision.Year -> year.toString()
            Precision.Month -> DateTimeFormatter.ofPattern("LLLL yyyy", locale).format(date)
            Precision.Day -> DateTimeFormatter.ofPattern("d MMMM yyyy", locale).format(date)
        }
    }

    /** The day, for the date picker; `null` for a day the calendar does not have (31 February). */
    fun toLocalDate(): LocalDate? = runCatching { LocalDate.of(year, month, day) }.getOrNull()

    /** The date set from the picker, keeping the precision. */
    fun with(date: LocalDate): PublicationDate = copy(year = date.year, month = date.monthValue, day = date.dayOfMonth)

    companion object {
        /** Reads a claim: `null` for anything but the three shapes, or a month or a day out of range. */
        fun parse(claim: String): PublicationDate? {
            val parts: List<Int?> = claim.split("-").map { part -> part.takeIf { it.all(Char::isDigit) }?.toIntOrNull() }
            if (parts.size !in 1..3 || parts.any { it == null }) return null
            val year: Int = parts[0] ?: return null
            if (year !in 1..9_999) return null
            val month: Int = parts.getOrNull(1) ?: 1
            val day: Int = parts.getOrNull(2) ?: 1
            if (month !in 1..12 || day !in 1..31) return null
            return PublicationDate(year, month, day, Precision.entries[parts.size - 1])
        }
    }
}
