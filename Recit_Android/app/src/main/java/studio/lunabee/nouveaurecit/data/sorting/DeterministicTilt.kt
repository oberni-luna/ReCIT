package studio.lunabee.nouveaurecit.data.sorting

/**
 * `DeterministicTilt`: how far something leans, derived from a piece of text and nothing else — so
 * nothing is persisted, and a pile leans the same way on every launch. Renaming re-rolls the lean.
 *
 * It produces **the same numbers as the iOS app**: djb2 over Unicode code points with 64-bit wrapping
 * arithmetic, then splitmix64's finalizer, then 2001 buckets. Two things it must not do, both invisible
 * by eye and both pinned by tests:
 * - fold over chars or ASCII bytes rather than code points — accented French names would then lean
 *   alike, and a character outside the BMP would hash as two;
 * - use `String.hashCode()` or any process-seeded hash.
 */
object DeterministicTilt {
    /** How many distinct angles the range is cut into. Odd, so dead upright is reachable. */
    private const val STEPS: ULong = 2001UL

    /** The lean, in degrees, for [text], within `-amplitude..amplitude`. */
    fun degrees(text: String, amplitude: Double): Double {
        val bucket: ULong = mix(hash(text)) % STEPS
        val unit: Double = bucket.toDouble() / (STEPS - 1UL).toDouble() * 2 - 1
        return unit * amplitude
    }

    /** djb2 over Unicode code points. */
    private fun hash(text: String): ULong {
        var hash: ULong = 5381UL
        var index: Int = 0
        while (index < text.length) {
            val codePoint: Int = text.codePointAt(index)
            hash = hash * 33UL + codePoint.toULong()
            index += Character.charCount(codePoint)
        }
        return hash
    }

    /**
     * splitmix64's finalizer. djb2 alone leaves neighbouring texts in neighbouring buckets, which on a
     * shelf of similarly-shaped French names reads as everything leaning the same way.
     */
    private fun mix(value: ULong): ULong {
        var z: ULong = value
        z = (z xor (z shr 30)) * 0xBF58476D1CE4E5B9UL
        z = (z xor (z shr 27)) * 0x94D049BB133111EBUL
        return z xor (z shr 31)
    }
}
