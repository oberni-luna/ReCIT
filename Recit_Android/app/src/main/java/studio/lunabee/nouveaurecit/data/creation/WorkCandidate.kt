package studio.lunabee.nouveaurecit.data.creation

import studio.lunabee.nouveaurecit.data.model.EntityLabel
import studio.lunabee.nouveaurecit.network.dto.EntityResultDto
import studio.lunabee.nouveaurecit.network.dto.WikidataProperty

/**
 * `WorkCandidate` (iOS feature 0047): a work a search proposed — enough to recognise it (its cover, its
 * title, who wrote it and when) and the uri that names it once picked.
 *
 * A value, not a `WorkEntity`: a search result is shown and forgotten, and storing every candidate would
 * leave a trail of works nobody asked for. Only the one picked travels, in the draft.
 */
data class WorkCandidate(
    val uri: String,
    val title: String,
    /** Who wrote it, by name. Empty when the work names nobody, or the names could not be read. */
    val authors: List<String> = emptyList(),
    /** The year it came out, as four digits. */
    val year: String? = null,
    /** What the search said about the work, for when neither its authors nor its year are known. */
    val summary: String? = null,
    val imageUrl: String? = null,
) {
    /** The line under the title: « Kim Stanley Robinson · 2020 », or the search's description. */
    val detail: String? get() = byline(authors, year) ?: summary

    companion object {
        /** Authors and year, each half optional; both missing answers `null`. */
        fun byline(authors: List<String>, year: String?): String? {
            val names: String? = authors.takeIf { it.isNotEmpty() }?.joinToString(", ")
            val parts: List<String> = listOfNotNull(names, year)
            return parts.takeIf { it.isNotEmpty() }?.joinToString(" · ")
        }

        /**
         * The year of a `wdt:P577` value — `2020` from `2020-10-06`, `2020-10` and `2020`. Anything that does
         * not open on four digits answers `null`: a date before the common era is written `-0500`.
         */
        fun year(date: String?): String? {
            val prefix: String = date?.take(4) ?: return null
            return prefix.takeIf { it.length == 4 && it.all(Char::isDigit) }
        }

        /**
         * The candidates for a search, in the search's order, each completed by what `by-uris` answered:
         * its authors' names and its publication date. [entities] holds the works **and** their authors —
         * `relatives=wdt:P50` puts both in one envelope. A work it said nothing about keeps the description.
         */
        fun candidates(results: List<EntitySearchHit>, entities: Map<String, EntityResultDto>): List<WorkCandidate> {
            val byUri: Map<String, EntityResultDto> = entities.values.associateBy { it.uri } + entities
            return results.map { result ->
                val work: EntityResultDto? = byUri[result.uri]
                val authors: List<String> = work?.claimStrings(WikidataProperty.AUTHOR).orEmpty().mapNotNull { uri ->
                    byUri[uri]?.let { author -> EntityLabel.resolve(author.labels, author.originalLang) }
                }
                WorkCandidate(
                    uri = result.uri,
                    title = result.label,
                    authors = authors,
                    year = year(work?.claimString(WikidataProperty.PUBLICATION_DATE)),
                    summary = result.description,
                    imageUrl = result.image,
                )
            }
        }
    }
}
