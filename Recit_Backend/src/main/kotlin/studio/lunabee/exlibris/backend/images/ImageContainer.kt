package studio.lunabee.exlibris.backend.images

/**
 * Where an image is filed, the `container` of `/api/images/upload` and the folder of `/img/<container>/<hash>`.
 * The entities' covers go to inventaire.io (#77).
 */
enum class ImageContainer(
    val parameter: String,
) {
    USERS("users"),
    GROUPS("groups"),
    ;

    /** The path the apps store and resolve against the base URL. */
    fun path(hash: String): String = "/img/$parameter/$hash"

    companion object {
        /** inventaire.io's `uploadContainersNames`, the values `container` accepts, served here or not. */
        val uploadable: List<String> = listOf("entities", "groups", "users")

        fun of(parameter: String): ImageContainer? = entries.firstOrNull { it.parameter == parameter }

        /** The container a stored path such as `/img/groups/<hash>` points into. */
        fun ofPath(path: String): ImageContainer? = entries.firstOrNull { path.startsWith(it.path("")) }
    }
}
