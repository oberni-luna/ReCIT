package studio.lunabee.nouveaurecit.data.creation

import java.util.UUID

/**
 * `NewBookAuthor` (iOS features 0047, 0049): one author of a work — someone inventaire.io already has,
 * named by [uri], or someone nobody has entered yet, described by [name].
 *
 * That single distinction keeps the base free of twin authors: two « Ursula K. Le Guin » split her
 * bibliography in half, and only a human with merge rights can put it back.
 */
data class NewBookAuthor(
    /** The row's own identity, so two authors of the same name stay two rows. */
    val id: UUID = UUID.randomUUID(),
    /** The name as inventaire.io has it, or as typed. A label on a new author, only a display once [uri] is set. */
    val name: String,
    /** An author inventaire.io already has. `null` means the author is being created. */
    val uri: String? = null,
    /** What told this author apart from a namesake, kept only to show it back in the form. */
    val description: String? = null,
) {
    val trimmedName: String get() = name.trim()
}
