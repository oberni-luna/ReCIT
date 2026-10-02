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
}
