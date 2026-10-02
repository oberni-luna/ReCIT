package studio.lunabee.nouveaurecit.network.dto

import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.doubleOrNull

@Serializable
data class EntityResultsDto(val entities: Map<String, EntityResultDto> = emptyMap())

/**
 * One entity of `/api/entities/by-uris`. Unlike iOS, `labels` and `claims` default to empty: a
 * missing one used to fail the whole batch.
 *
 * Claims are kept as raw JSON values — inventaire.io mixes strings, numbers and booleans — and read
 * through [claimStrings] / [claimNumber], the `ClaimValue` accessors.
 */
@Serializable
data class EntityResultDto(
    val uri: String,
    val lastrevid: Int? = null,
    val type: String? = null,
    val originalLang: String? = null,
    val labels: Map<String, String> = emptyMap(),
    val descriptions: Map<String, String>? = null,
    val image: EntityImageDto? = null,
    val claims: Map<String, List<JsonElement>> = emptyMap(),
) {
    fun claimStrings(property: String): List<String> =
        claims[property].orEmpty().mapNotNull { (it as? JsonPrimitive)?.takeIf { primitive -> primitive.isString }?.content }

    fun claimString(property: String): String? = claimStrings(property).firstOrNull()

    fun claimNumber(property: String): Double? =
        claims[property].orEmpty().firstNotNullOfOrNull { element ->
            (element as? JsonPrimitive)?.let { it.doubleOrNull ?: it.content.toDoubleOrNull() }
        }
}

@Serializable
data class EntityImageDto(
    val url: String? = null,
    val file: String? = null,
)

@Serializable
data class AuthorWorksDto(val works: List<AuthorWorkDto> = emptyList())

@Serializable
data class AuthorWorkDto(val uri: String, val score: Int? = null)

@Serializable
data class WorkEditionsDto(val uris: List<String> = emptyList())

@Serializable
data class SummariesDto(val summaries: List<SummaryDto> = emptyList())

@Serializable
data class SummaryDto(
    val key: String,
    val name: String? = null,
    val lang: String? = null,
    val link: String? = null,
    val sitelink: SitelinkDto? = null,
    val text: String? = null,
)

@Serializable
data class SitelinkDto(val title: String, val lang: String? = null)

@Serializable
data class ExtractDto(val extract: String = "", val url: String = "")

@Serializable
data class SearchResultsDto(val results: List<SearchResultDto> = emptyList())

@Serializable
data class SearchResultDto(
    val id: String,
    val type: String,
    val uri: String,
    val label: String,
    val description: String? = null,
    val image: String? = null,
    val score: Double? = null,
)

/** `wdt:` properties read by the app — `Model/Books/WikidataProperty.swift`. */
object WikidataProperty {
    const val AUTHOR: String = "wdt:P50"
    const val PUBLICATION_DATE: String = "wdt:P577"
    const val DATE_OF_BIRTH: String = "wdt:P569"
    const val DATE_OF_DEATH: String = "wdt:P570"
    const val EDITION_OF: String = "wdt:P629"
    const val TITLE: String = "wdt:P1476"
    const val NUMBER_OF_PAGES: String = "wdt:P1104"
    const val LANGUAGE: String = "wdt:P407"
    const val GENRE: String = "wdt:P136"
    const val SUMMARY: String = "wdt:P268"
}
