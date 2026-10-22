package studio.lunabee.nouveaurecit.data.sorting

/**
 * `SortPile`: what one étagère's card draws — its first few books laid one over another, each leaning
 * a little — and, crucially, **which of them the card hands over when it is dragged**.
 *
 * The card's drag source is a single cover, so position and rank have to agree: the book the user
 * grabs must be the book they see on top. **The top of the pile is the front of the pile is the first
 * of the section**: sections arrive ordered by [SortProjection], most recently filed first, so
 * `covers.first()` is both the visual front and the draggable book.
 *
 * Depth runs the other way — the last cover is drawn first — so a view draws `covers.asReversed()` and
 * finishes with the one it makes draggable. Tilt comes from each title through [DeterministicTilt],
 * ±[TILT_AMPLITUDE]°: enough to read as a handled pile, little enough that a cover stays a cover.
 */
class SortPile(books: List<SortBook>, limit: Int = SortGridMetrics.PILE_COVER_LIMIT) {
    constructor(section: SortSection) : this(section.books)

    /** One cover of the pile. [depth] is 0 for the front cover, growing towards the back. */
    data class Cover(val book: SortBook, val depth: Int, val tiltDegrees: Double) {
        val id: String get() = book.id
    }

    /** The covers to draw, front first. Empty for an étagère holding nothing — a draft's normal state. */
    val covers: List<Cover> = books.take(limit.coerceAtLeast(0)).mapIndexed { index, book ->
        Cover(book, depth = index, tiltDegrees = DeterministicTilt.degrees(book.title, TILT_AMPLITUDE))
    }

    /** How many books the étagère holds in total — what the card's title says. The pile shows at most five. */
    val bookCount: Int = books.size

    /** The book a drag from this card carries, or `null` for an empty étagère, which is only a drop target. */
    val draggableBook: SortBook? get() = covers.firstOrNull()?.book

    /** One book is not a pile of one: it is drawn face-on. */
    val isSingleCover: Boolean get() = covers.size == 1

    val isEmpty: Boolean get() = covers.isEmpty()

    companion object {
        /** The widest a piled cover leans, either way, in degrees. */
        const val TILT_AMPLITUDE: Double = 10.0
    }
}
