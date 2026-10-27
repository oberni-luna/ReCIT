package studio.lunabee.nouveaurecit.data.creation

import java.util.UUID

/**
 * `EditionEntityValue` (iOS feature 0050): an entity an edition names — its publisher, collection,
 * language, one of the people who made it. One inventaire.io or Wikidata already has, named by [uri], or
 * one nobody has entered yet, described by the name typed, and created before the claim naming it is
 * sent.
 *
 * The same distinction as [NewBookAuthor]'s, for the same reason: a second « Gallimard » on inventaire.io
 * splits a catalogue in two, and only a human with merge rights can join it again.
 */
data class EditionEntityValue(
    /** The row's own identity, so two namesakes stay two rows, and a created entity is found again to receive its uri. */
    val id: UUID = UUID.randomUUID(),
    /** `null` while the entity is still to be created. */
    val uri: String? = null,
    /** What the form prints: the entity's label, or the name typed for one to create. */
    val label: String,
    /** What tells it apart from a namesake, as the search answered it. */
    val detail: String? = null,
) {
    val trimmedLabel: String get() = label.trim()

    /** The same entity: the same uri, or — for one still to be created — the same name. */
    fun isSame(other: EditionEntityValue): Boolean {
        if (uri != null && other.uri != null) return uri == other.uri
        if (uri != null || other.uri != null) return false
        return trimmedLabel.equals(other.trimmedLabel, ignoreCase = true)
    }
}
