package studio.lunabee.nouveaurecit.data.creation

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * `EditionClaimUpdate` (iOS features 0049, 0050): one change to one claim — of the edition, or of one of
 * its works — as `PUT /api/entities/update-claim` takes it: the value it replaces and the one it puts in
 * its place.
 *
 * Either side can be missing, and is then **left out** of the body rather than sent as `null`
 * (`explicitNulls = false`): no old value adds a claim, no new value removes it. The values keep their
 * type — a number of pages goes out as a JSON number ([ClaimLiteral]).
 */
@Serializable
data class EditionClaimUpdate(
    val uri: String,
    /** The property's uri, `wdt:P123`. */
    val property: String,
    @SerialName("old-value") val oldValue: ClaimLiteral? = null,
    @SerialName("new-value") val newValue: ClaimLiteral? = null,
) {
    companion object {
        /** One of the claims whose values are strings — a title, a cover, a work, an author. */
        fun of(uri: String, property: EditableClaimProperty, oldValue: String?, newValue: String?): EditionClaimUpdate =
            EditionClaimUpdate(
                uri = uri,
                property = property.uri,
                oldValue = oldValue?.let { ClaimLiteral.Text(it) },
                newValue = newValue?.let { ClaimLiteral.Text(it) },
            )
    }
}

/**
 * `EntityLabelUpdate` (iOS feature 0049): a work renamed from « Modifier l'œuvre », as
 * `PUT /api/entities/update-label` takes it. A work's title is a label, not a claim — unlike an edition's,
 * which is `wdt:P1476`.
 */
@Serializable
data class EntityLabelUpdate(
    val uri: String,
    val lang: String,
    val value: String,
)
