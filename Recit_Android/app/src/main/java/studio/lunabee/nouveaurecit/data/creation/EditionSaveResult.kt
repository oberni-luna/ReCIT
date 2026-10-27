package studio.lunabee.nouveaurecit.data.creation

/**
 * What a save of « Modifier l'édition » came to. Either way it carries the edit as far as it got — what
 * landed has moved into it — so the form keeps it, and the book screen shows what the server holds.
 */
sealed interface EditionSaveResult {
    val edit: EditionEdit

    /** Everything landed. */
    data class Saved(override val edit: EditionEdit) : EditionSaveResult
}

/**
 * `EditionSaveFailure` (iOS feature 0049): a change that did not land in full — what went wrong, and the
 * edit as far as it got. The form takes the edit back so a retry sends only what is left.
 */
data class EditionSaveFailure(
    override val edit: EditionEdit,
    val underlying: Throwable,
) : EditionSaveResult {
    /** The banner's three cases: an expired session, a refusal, no answer. */
    val failure: CreateBookFailure get() = CreateBookFailure.from(underlying)
}
