package studio.lunabee.nouveaurecit.ui.profile

/**
 * The `**…**` of the iOS catalogue, which SwiftUI's `Text` renders as Markdown. Android string
 * resources keep the same markers; this splits a sentence into runs, bold or not, so a composable
 * can build the `AnnotatedString`. An unclosed `**` is kept as literal text rather than swallowed.
 */
object BoldMarkup {
    data class Run(val text: String, val isBold: Boolean)

    fun parse(source: String): List<Run> {
        val runs: MutableList<Run> = mutableListOf()
        var index: Int = 0
        while (index < source.length) {
            val open: Int = source.indexOf(MARKER, index)
            val close: Int = if (open < 0) -1 else source.indexOf(MARKER, open + MARKER.length)
            if (open < 0 || close < 0) {
                runs += Run(source.substring(index), isBold = false)
                break
            }
            if (open > index) runs += Run(source.substring(index, open), isBold = false)
            if (close > open + MARKER.length) runs += Run(source.substring(open + MARKER.length, close), isBold = true)
            index = close + MARKER.length
        }
        return runs
    }

    private const val MARKER: String = "**"
}
