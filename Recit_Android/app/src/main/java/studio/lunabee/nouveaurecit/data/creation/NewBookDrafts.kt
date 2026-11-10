package studio.lunabee.nouveaurecit.data.creation

/**
 * `Model/Creation/NewBookDrafts.swift` (iOS feature 0087): the books being created and not yet published,
 * each kept under the [NewBookOrigin] it was started from, in memory only. Closing « Nouveau livre » keeps
 * what was typed: the same barcode, or the same query, reopens on it, and anything else starts blank.
 *
 * Held by whoever opens the form — the scanning session, Recherche's tab root — and lives as long as it.
 */
class NewBookDrafts {
    private val drafts: MutableMap<NewBookOrigin, NewBookDraft> = mutableMapOf()

    /** What the form opens on: the draft left from a previous attempt, or a blank one. */
    fun draft(origin: NewBookOrigin): NewBookDraft = drafts[origin] ?: origin.blankDraft

    /** Keeps what was typed, whatever took the form away. */
    fun remember(draft: NewBookDraft, origin: NewBookOrigin) {
        drafts[origin] = draft
    }

    /**
     * Forgets a draft that has become a book. Nothing else clears one: a session's worth of abandoned
     * drafts is a few hundred bytes, and losing one is worse than keeping it.
     */
    fun forget(origin: NewBookOrigin) {
        drafts.remove(origin)
    }
}
