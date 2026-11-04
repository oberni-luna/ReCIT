package studio.lunabee.nouveaurecit.ui.common

import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.LinkAnnotation
import androidx.compose.ui.text.TextLinkStyles
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.withLink

/**
 * `UserPresentationTab.linked`: every web address in a text the reader wrote made a link — « www.… » as well
 * as a full `https://` one, which is completed. The punctuation that closes a sentence after an address is
 * not part of it. A bare domain without `www.` stays text: `NSDataDetector` has no Android equivalent that
 * runs outside a device.
 */
object WebLinks {
    private val address: Regex = Regex("""(?:https?://|www\.)[^\s<>«»"]+""", RegexOption.IGNORE_CASE)
    private const val TRAILING: String = ".,;:!?)]}'’"

    /** Each address of [text]: where it sits, and the url it opens. */
    fun find(text: String): List<Pair<IntRange, String>> = address.findAll(text).mapNotNull { match ->
        val value: String = match.value.trimEnd { it in TRAILING }
        if (value.isEmpty()) return@mapNotNull null
        val url: String = if (value.startsWith("www.", ignoreCase = true)) "https://$value" else value
        (match.range.first until match.range.first + value.length) to url
    }.toList()

    /** [text] with each address a [LinkAnnotation.Url], drawn in [styles]. */
    fun annotate(text: String, styles: TextLinkStyles): AnnotatedString = buildAnnotatedString {
        var cursor: Int = 0
        find(text).forEach { (range, url) ->
            append(text.substring(cursor, range.first))
            withLink(LinkAnnotation.Url(url, styles)) { append(text.substring(range.first, range.last + 1)) }
            cursor = range.last + 1
        }
        append(text.substring(cursor))
    }
}
