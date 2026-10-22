package studio.lunabee.nouveaurecit.ui.auth.coverwall

import kotlin.math.roundToInt

/**
 * `Model/CoverWall/CoverWallCatalog.swift`: sifts the image paths of `recent-public` — no cover,
 * the same edition owned twice, more than [COVER_LIMIT] — and builds each URL at the size the cover
 * is drawn, `/img/entities/<w>x<h>/<hash>` weighing a thirtieth of the full-size image.
 */
object CoverWallCatalog {
    const val COVER_LIMIT: Int = 60

    fun coverPaths(imagePaths: List<String?>, limit: Int = COVER_LIMIT): List<String> =
        imagePaths.asSequence().filterNotNull().filter { it.isNotEmpty() }.distinct().take(maxOf(0, limit)).toList()

    fun url(baseUrl: String, path: String, widthPx: Float, heightPx: Float): String {
        val sized: String = sizedPath(path, widthPx, heightPx)
        return if (sized.startsWith("http")) sized else "$baseUrl$sized"
    }

    /** `/img/<kind>/<hash>` becomes `/img/<kind>/<w>x<h>/<hash>`; any other shape is left alone. */
    fun sizedPath(path: String, widthPx: Float, heightPx: Float): String {
        val components: List<String> = path.split("/")
        if (components.size != 4 || components[1] != "img") return path
        val width: Int = if (widthPx.isFinite()) widthPx.roundToInt() else 0
        val height: Int = if (heightPx.isFinite()) heightPx.roundToInt() else 0
        if (width <= 0 || height <= 0) return path
        return "/${components[1]}/${components[2]}/${width}x$height/${components[3]}"
    }
}
