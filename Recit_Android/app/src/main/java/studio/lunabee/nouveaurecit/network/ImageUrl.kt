package studio.lunabee.nouveaurecit.network

/**
 * `APIService.absoluteImageUrl(_:)`: an absolute url as is, an inventaire.io `/img/…` path on the
 * base url, and anything else as a Wikimedia Commons file name.
 *
 * One deliberate departure: an empty path is `null`, not a Commons url with no file name — the
 * iOS quirk never produced an image either.
 */
object ImageUrl {
    fun absolute(path: String?, baseUrl: String = ApiService.BASE_URL): String? = when {
        path.isNullOrEmpty() -> null
        path.startsWith("http") -> path
        path.startsWith("/img") -> "$baseUrl$path"
        else -> "https://commons.wikimedia.org/wiki/Special:FilePath/$path?width=512"
    }

    /**
     * Wide enough for any phone screen at its native scale; Wikimedia never upscales past the
     * file's own width.
     */
    const val FULL_SCREEN_WIKIMEDIA_WIDTH: Int = 2048

    /**
     * iOS `FullScreenImageURL.resolve(_:)`: [url] at the size worth showing on a whole screen.
     *
     * inventaire.io serves `/img/entities/<hash>` at its original size when no `WxH` is given,
     * which is already the best there is, so it is left alone. Wikimedia's `Special:FilePath` is
     * asked for a `width` — 512 or 1024 elsewhere in the app — raised here to
     * [FULL_SCREEN_WIKIMEDIA_WIDTH].
     */
    fun fullScreen(url: String): String {
        val fragmentStart: Int = url.indexOf('#').takeIf { it >= 0 } ?: url.length
        val fragment: String = url.substring(fragmentStart)
        val beforeFragment: String = url.substring(0, fragmentStart)
        val queryStart: Int = beforeFragment.indexOf('?').takeIf { it >= 0 } ?: beforeFragment.length
        val address: String = beforeFragment.substring(0, queryStart)
        val host: String = address.substringAfter("://", missingDelimiterValue = "").substringBefore('/').substringBefore(':')
        if (!host.equals("commons.wikimedia.org", ignoreCase = true) || !address.contains("Special:FilePath")) return url

        val query: List<String> = beforeFragment.substring(queryStart).removePrefix("?")
            .split('&')
            .filter { it.isNotEmpty() && it.substringBefore('=') != "width" }
        val items: List<String> = query + "width=$FULL_SCREEN_WIKIMEDIA_WIDTH"
        return "$address?${items.joinToString("&")}$fragment"
    }
}
