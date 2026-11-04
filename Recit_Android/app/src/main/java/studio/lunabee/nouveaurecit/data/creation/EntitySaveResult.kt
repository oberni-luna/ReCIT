package studio.lunabee.nouveaurecit.data.creation

/**
 * What a save of « Modifier l'œuvre » or « Modifier l'auteur·ice » came to (iOS `EntitySaveFailure`,
 * feature 0057). Either way it carries the edit as far as it got — what landed has moved into it — so the
 * form takes it back, and a retry sends only what is left.
 */
sealed interface EntitySaveResult {
    val edit: EntityEdit

    /** Everything landed. */
    data class Saved(override val edit: EntityEdit) : EntitySaveResult

    /** A change that did not land in full: what went wrong, and the edit as far as it got. */
    data class Failed(override val edit: EntityEdit, val underlying: Throwable) : EntitySaveResult {
        /** The banner's three cases: an expired session, a refusal, no answer. */
        val failure: CreateBookFailure get() = CreateBookFailure.from(underlying)
    }
}
