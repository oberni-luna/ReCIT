package studio.lunabee.exlibris.backend.items

import kotlinx.serialization.Serializable

/**
 * inventaire.io's `worksTree`: the works by author, genre and subject (`unknown` for a work without one), and each
 * owner's books by work.
 */
@Serializable
data class WorksTree(
    val author: Map<String, List<String>>,
    val genre: Map<String, List<String>>,
    val subject: Map<String, List<String>>,
    val owner: Map<String, Map<String, List<String>>>,
)
