package studio.lunabee.exlibris.backend.images

/**
 * Where an image is filed, the `container` of `/api/images/upload` and the folder of `/img/<container>/<hash>`.
 * Groups (#72) add theirs; the entities' covers go to inventaire.io (#77).
 */
enum class ImageContainer(
    val parameter: String,
) {
    USERS("users"),
    ;

    /** The path the apps store and resolve against the base URL. */
    fun path(hash: String): String = "/img/$parameter/$hash"

    companion object {
        /** inventaire.io's `uploadContainersNames`, the values `container` accepts, served here or not. */
        val uploadable: List<String> = listOf("entities", "groups", "users")

        fun of(parameter: String): ImageContainer? = entries.firstOrNull { it.parameter == parameter }
    }
}
