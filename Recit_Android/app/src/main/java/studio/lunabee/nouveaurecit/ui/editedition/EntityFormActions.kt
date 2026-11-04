package studio.lunabee.nouveaurecit.ui.editedition

import studio.lunabee.nouveaurecit.data.creation.EditionProperties
import studio.lunabee.nouveaurecit.data.creation.EditionProperty

/**
 * What the forms of « Modifier l'œuvre » and « Modifier l'auteur·ice » do, handed down from the page:
 * each changes the entity's draft or pushes a page over it.
 */
class EntityFormActions(
    val onLabel: (language: String, value: String) -> Unit,
    val onAddLabel: (language: String) -> Unit,
    val onChange: (EditionProperties) -> Unit,
    /** Pushes what changes one property: its values, a date, a list of choices. */
    val onOpenProperty: (EditionProperty) -> Unit,
    /** Pushes the search for one more value of a property. */
    val onPick: (EditionProperty) -> Unit,
    /** Pushes the list of catalogues an identifier — or a link — is added to. */
    val onAddIdentifier: (EditionProperty.Group) -> Unit,
    /** Pushes « Modifier l'auteur·ice » for the person with this uri. */
    val onOpenEntity: (String) -> Unit,
)
