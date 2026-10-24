package studio.lunabee.nouveaurecit.data.groups

/**
 * `GroupTransitionError`: why a gesture cannot be applied to a group as it stands locally. Each case
 * is a refusal the server would answer too, caught before the call so the optimistic state never
 * lies. No message: the snackbar says « Une erreur s'est produite », never English prose.
 */
sealed class GroupTransitionError : Exception() {
    /** The person is not in the list the gesture moves them out of. */
    class NotInExpectedRole : GroupTransitionError()

    /** The person already has a role, and the gesture would give them a second one. */
    class AlreadyInGroup : GroupTransitionError()

    /** An invitation turned down cannot be sent again (`user already declined the invitation`). */
    class AlreadyDeclined : GroupTransitionError()

    /** The gesture needs someone else, and none was given. */
    class MissingTarget : GroupTransitionError()

    /** The last admin cannot leave while there are members left. */
    class LastAdmin : GroupTransitionError()
}
