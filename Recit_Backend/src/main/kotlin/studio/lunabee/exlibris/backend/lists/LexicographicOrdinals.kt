package studio.lunabee.exlibris.backend.lists

/**
 * inventaire.io's `lexicographic_ordinals.ts`, the part its live API uses: the ordinal an element added last gets.
 * Ordinals are base-36 figures read as text, so that elements sort by ordinal in byte order.
 */
object LexicographicOrdinals {
    /** What `getListingHighestOrdinal` answers for a list without elements: its first element gets `11`. */
    const val EMPTY_LIST: String = "1"

    private const val BASE: Int = 36
    private const val SHORT_LENGTH: Int = 4
    private const val LONG_LENGTH: Int = 6
    private const val LAST_RANGE_START: Int = 24

    /** JavaScript's `Number.MAX_SAFE_INTEGER`. */
    private const val MAX_SAFE_INTEGER: Long = 9_007_199_254_740_991

    /** [MAX_SAFE_INTEGER] written in base 36, less one figure: the longest ordinal a double still holds. */
    private val safeMaxLength: Int = MAX_SAFE_INTEGER.toString(BASE).length - 1

    /** `findNextLastOrdinal`: what comes after [ordinal], kept short by starting the next range when it grows. */
    fun next(ordinal: String): String {
        val first: Int = ordinal.firstOrNull()?.digitToInt(BASE) ?: 0
        return when {
            ordinal.length < SHORT_LENGTH -> {
                ordinal + "1"
            }

            (ordinal.length > LONG_LENGTH && first < LAST_RANGE_START) || ordinal.length >= safeMaxLength -> {
                (first + 1).toString(BASE)
            }

            else -> {
                val following: String = (ordinal.toLong(BASE) + 1).toString(BASE)
                if (following.length > ordinal.length) ordinal + "1" else following
            }
        }
    }
}
