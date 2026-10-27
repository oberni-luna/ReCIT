package studio.lunabee.nouveaurecit.network.dto

import kotlinx.serialization.Serializable

/**
 * `EditableEditionsDTO` (iOS feature 0049): `by-uris` read to open « Modifier l'édition » — the edition's
 * canonical uri, its type and claims, and, in the same envelope, the entities its claims name, asked as
 * relatives. The envelope is keyed by the canonical uri; an `isbn:` uri asked for comes back under the
 * `inv:` one it redirects to, which [redirects] says.
 *
 * The works read with `relatives=wdt:P50` (`WorkSummaryDTO` on iOS) decode as the same envelope: a work
 * is read for its `wdt:P50` and `wdt:P577`, an author for its label.
 */
@Serializable
data class EditableEditionsDto(
    val entities: Map<String, EntityResultDto> = emptyMap(),
    val redirects: Map<String, String>? = null,
)

/**
 * `EntityCreationRequest` (iOS feature 0049): `POST /api/entities`, which creates one entity — an author,
 * a work, a publisher, a collection. One label in the edition's language; a collection has none, its
 * name being a `wdt:P1476` claim.
 */
@Serializable
data class EntityCreationRequest(
    val labels: Map<String, String>,
    val claims: Map<String, List<String>>,
)

/** The part of `POST /api/entities`' answer the app reads: the uri the entity was created under. */
@Serializable
data class CreatedEntityDto(val entity: CreatedEntity) {
    @Serializable
    data class CreatedEntity(val uri: String)
}
