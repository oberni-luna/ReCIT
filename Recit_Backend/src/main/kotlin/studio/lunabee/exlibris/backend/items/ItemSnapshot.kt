package studio.lunabee.exlibris.backend.items

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * inventaire.io's item `snapshot`, built by its `buildSnapshot` from the entity, its works, their authors and series.
 * `entity:title` is always there: both apps' DTOs require it.
 */
@Serializable
data class ItemSnapshot(
    @SerialName("entity:title")
    val title: String,
    @SerialName("entity:subtitle")
    val subtitle: String? = null,
    @SerialName("entity:lang")
    val lang: String? = null,
    @SerialName("entity:authors")
    val authors: String? = null,
    @SerialName("entity:image")
    val image: String? = null,
    @SerialName("entity:series")
    val series: String? = null,
    @SerialName("entity:ordinal")
    val ordinal: String? = null,
    @SerialName("entity:worksUris")
    val worksUris: List<String>,
    @SerialName("entity:authorsUris")
    val authorsUris: List<String>,
    @SerialName("entity:seriesUris")
    val seriesUris: List<String>,
    @SerialName("entity:isbn13")
    val isbn13: String? = null,
    @SerialName("entity:isbn10")
    val isbn10: String? = null,
)
