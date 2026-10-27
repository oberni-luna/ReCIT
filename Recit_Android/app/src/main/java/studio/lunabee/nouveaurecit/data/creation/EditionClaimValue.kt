package studio.lunabee.nouveaurecit.data.creation

/**
 * `EditionClaimValue` (iOS feature 0050): one value of an edition's property as the form holds it — a
 * literal (a date, a count, an identifier, a format's uri) or an entity, which carries the name the form
 * shows beside the uri the claim sends.
 */
sealed interface EditionClaimValue {
    data class Literal(val literal: ClaimLiteral) : EditionClaimValue

    data class Entity(val entity: EditionEntityValue) : EditionClaimValue

    /** What goes on the wire; `null` for an entity still to be created — there is no uri to send yet. */
    val claim: ClaimLiteral?
        get() = when (this) {
            is Literal -> literal
            is Entity -> entity.uri?.let { ClaimLiteral.Text(it) }
        }

    val entityValue: EditionEntityValue? get() = (this as? Entity)?.entity
}
