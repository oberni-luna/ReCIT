package studio.lunabee.nouveaurecit.data.search

/**
 * `Model/SearchResult/IsbnQuery.swift`: whether what was typed in Recherche is an ISBN, and which one.
 *
 * `/api/search` is a full-text search over labels: it cannot find an edition, and it reads
 * « 978-2-234-09688-2 » as the words `978`, `2`, `234`… — which brought back « Divergente 2 » rather
 * than the book. inventaire.io's website recognises an ISBN before it searches and asks for the
 * edition by its `isbn:` uri instead; this is the app's half of that recognition.
 *
 * **Strict on purpose.** The query has to be nothing but digits, hyphens and spaces (and the `X` an
 * ISBN-10 may end on), and its check digit has to be right: « Dune 1965 » is not a number to look up,
 * and a thirteen-digit number that is not an ISBN goes to the text search like any other query.
 */
object IsbnQuery {
    /** The thirteen-digit ISBN [query] is, or `null` when it is not one. */
    fun isbn(query: String): String? {
        val trimmed: String = query.trim()
        if (trimmed.isEmpty() || !trimmed.all { it in '0'..'9' || it in "- Xx" }) return null
        val characters: String = trimmed.uppercase().filter { it.isDigit() || it == 'X' }
        return when (characters.length) {
            13 -> characters.takeIf {
                it.all(Char::isDigit) && (it.startsWith("978") || it.startsWith("979")) && hasValidIsbn13CheckDigit(it)
            }
            10 -> if (hasValidIsbn10CheckDigit(characters)) isbn13Of(characters) else null
            else -> null
        }
    }

    private fun hasValidIsbn13CheckDigit(digits: String): Boolean =
        digits.mapIndexed { index, char -> char.digitToInt() * if (index % 2 == 0) 1 else 3 }.sum() % 10 == 0

    /** Nine digits, then a digit or an `X` worth ten, weighted 10 down to 1 — a multiple of 11. */
    private fun hasValidIsbn10CheckDigit(characters: String): Boolean {
        if (!characters.take(9).all(Char::isDigit)) return false
        val values: List<Int> = characters.map { if (it == 'X') 10 else it.digitToInt() }
        return values.mapIndexed { index, value -> value * (10 - index) }.sum() % 11 == 0
    }

    /** `978`, the first nine digits, and the ISBN-13 check digit worked out again. */
    private fun isbn13Of(isbn10: String): String {
        val stem: String = "978" + isbn10.take(9)
        val sum: Int = stem.mapIndexed { index, char -> char.digitToInt() * if (index % 2 == 0) 1 else 3 }.sum()
        return stem + (10 - sum % 10) % 10
    }
}
