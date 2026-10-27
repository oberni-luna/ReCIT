package studio.lunabee.nouveaurecit.data.creation

import java.util.UUID

/**
 * `EditionEditStep` (iOS feature 0049): one request of a save, as [EditionEdit.nextStep] lists them —
 * what has to exist before the claims can name it (a picture, an author, a work, a publisher), then the
 * claims one at a time, then the works' new titles.
 */
sealed interface EditionEditStep {
    /** Upload a new cover — the local JPEG at [path] — for the hash `invp:P2` takes. */
    data class UploadCover(val path: String) : EditionEditStep

    /** Create an author inventaire.io does not have, labelled with its name. */
    data class CreateAuthor(val id: UUID, val label: String, val language: String) : EditionEditStep

    /** Create a work the edition is an edition of, with its authors. */
    data class CreateWork(val id: UUID, val label: String, val language: String, val authorUris: List<String>) : EditionEditStep

    /** Create a publisher, a collection or a person the edition names, labelled with the name typed. */
    data class CreateEntity(val id: UUID, val label: String, val language: String, val kind: EntityCreationKind) : EditionEditStep

    /** Change one claim. */
    data class Claim(val update: EditionClaimUpdate) : EditionEditStep

    /** Rename a work. */
    data class Label(val update: EntityLabelUpdate) : EditionEditStep
}
