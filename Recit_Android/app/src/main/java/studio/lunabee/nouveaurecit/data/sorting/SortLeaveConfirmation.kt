package studio.lunabee.nouveaurecit.data.sorting

/**
 * `SortLeaveConfirmation`: whether the close control asks before leaving the sorting surface.
 *
 * **Only when there is something unsaved, and only until it has been answered « Quitter » once.**
 * Closing keeps the draft — the session is app-scoped — so the question is not "lose your work?" but
 * "you know this is not saved yet?". Never while a run is writing: the writes carry on without the
 * screen. The acknowledgement itself is kept per device in `UserPreferences`.
 */
object SortLeaveConfirmation {
    fun isNeeded(hasPendingChanges: Boolean, isApplying: Boolean, isAcknowledged: Boolean): Boolean =
        hasPendingChanges && !isApplying && !isAcknowledged
}
