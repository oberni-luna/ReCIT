package studio.lunabee.nouveaurecit.data.book

import studio.lunabee.nouveaurecit.data.model.Merges
import studio.lunabee.nouveaurecit.network.dto.EntityResultDto
import studio.lunabee.nouveaurecit.network.dto.WikidataProperty

/**
 * `EditionCandidateDTO`'s three computed properties and the ordering `WorkEditionResolver` applies,
 * as pure functions over the `by-uris` DTOs, so the ranking's inputs are testable without a network.
 */
object EditionCandidates {
    /** One DTO as a [EditionRelevance.Candidate]. */
    fun candidate(dto: EntityResultDto, heldEditionUris: Set<String>): EditionRelevance.Candidate =
        EditionRelevance.Candidate(
            id = dto.uri,
            lang = dto.originalLang,
            hasTitle = Merges.editionTitle(dto.labels, dto.claimString(WikidataProperty.TITLE)) != null,
            hasCover = !dto.image?.url.isNullOrEmpty(),
            isHeld = dto.uri in heldEditionUris,
            // An omnibus names every work it holds under `wdt:P629`; a novel names one.
            isSingleWork = (dto.claims[WikidataProperty.EDITION_OF]?.size ?: 1) <= 1,
        )

    /**
     * The candidates **in the order `reverse-claims` gave them**: the `by-uris` envelope is a map,
     * and iterating it would make the tie-break depend on hash order. Entities returned under a key
     * nobody asked for (a redirect resolving to its canonical uri) follow, sorted, rather than being
     * dropped.
     */
    fun ordered(requestedUris: List<String>, entities: Map<String, EntityResultDto>): List<EntityResultDto> {
        val byUri: Map<String, EntityResultDto> = entities.values.associateBy { it.uri }
        val head: List<EntityResultDto> = requestedUris.distinct().mapNotNull { byUri[it] }
        val seen: Set<String> = head.map { it.uri }.toSet()
        val tail: List<EntityResultDto> = byUri.values.filter { it.uri !in seen }.sortedBy { it.uri }
        return head + tail
    }
}
