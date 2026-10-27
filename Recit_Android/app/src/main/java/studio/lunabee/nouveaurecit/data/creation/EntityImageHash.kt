package studio.lunabee.nouveaurecit.data.creation

import studio.lunabee.nouveaurecit.network.ImageUrl

/**
 * `EntityImageHash` (iOS feature 0049): the name inventaire.io files an entity's picture under. An upload
 * answers a path, `/img/entities/<hash>`, and the claim that hangs the picture on an edition, `invp:P2`,
 * takes the hash alone — 40 lowercase hexadecimal characters, the SHA-1 of the file.
 */
object EntityImageHash {
    /** The hash at the end of an upload's path, or `null` when what came back is not one. */
    fun from(path: String?): String? {
        val last: String = path?.split("/")?.lastOrNull { it.isNotEmpty() } ?: return null
        val isHash: Boolean = last.length == 40 && last.all { it in '0'..'9' || it in 'a'..'f' }
        return last.takeIf { isHash }
    }

    /** The path a hash is served from, the shape [ImageUrl.absolute] resolves. */
    fun path(hash: String): String = "/img/entities/$hash"

    /** Where the picture filed under [hash] is served from. */
    fun url(hash: String): String? = ImageUrl.absolute(path(hash))
}
