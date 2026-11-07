package studio.lunabee.exlibris.backend.lists

import kotlinx.serialization.json.JsonObject
import studio.lunabee.exlibris.backend.items.InventaireEntities
import studio.lunabee.exlibris.backend.items.InventaireEntitiesReader
import studio.lunabee.exlibris.backend.items.text

/**
 * `by-creators`' `attributes=images`, as inventaire.io's `getSomeListingImages`: the best images inventaire.io knows
 * for a list's first [SAMPLED] elements, at most [KEPT] of them. Read from inventaire.io on each call, as it does.
 */
class ListImagesSampler(
    private val inventaire: InventaireEntitiesReader,
) {
    /** The images of each list of [elements], by list id, its elements in ordinal order. */
    suspend fun samples(
        elements: Map<String, List<ListElementRecord>>,
        lang: String,
    ): Map<String, List<String>> {
        val sampled: Map<String, List<String>> = elements.mapValues { (_, list) -> list.take(SAMPLED).map { it.uri } }
        val images: Map<String, String> =
            sampled.values
                .flatten()
                .distinct()
                .chunked(BATCH)
                .flatMap { uris -> imagesOf(uris, lang).entries }
                .associate { it.key to it.value }
        return sampled.mapValues { (_, uris) -> uris.mapNotNull { images[it] }.take(KEPT) }
    }

    private suspend fun imagesOf(
        uris: List<String>,
        lang: String,
    ): Map<String, String> {
        val entities: InventaireEntities =
            inventaire.read(uris, mapOf("attributes" to listOf("image"), "lang" to listOf(lang)))
        return uris
            .mapNotNull { uri -> (entities.entity(uri)?.get("image") as? JsonObject)?.text("url")?.let { uri to it } }
            .toMap()
    }

    private companion object {
        const val SAMPLED: Int = 12
        const val KEPT: Int = 10
        const val BATCH: Int = 50
    }
}
