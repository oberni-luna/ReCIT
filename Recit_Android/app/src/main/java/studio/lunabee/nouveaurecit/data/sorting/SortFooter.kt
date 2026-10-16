package studio.lunabee.nouveaurecit.data.sorting

/**
 * `SortFooter`: what the line under the sorting surface's buttons says. One slot, several readings,
 * and **never empty**, so the buttons do not move the moment anything is done.
 *
 * The order is the rule: a finished run's account outranks the recap, because a present-tense recap
 * beside a past-tense report reads as a screen contradicting itself. **The recap doubles as the
 * progress**: the plan shrinks as each confirmed write leaves the stack, so during a run it counts
 * itself down. iOS's `notice` reading answers the automatic proposal only, and is not ported.
 */
sealed interface SortFooter {
    /** Nothing pending and nothing done: there is nothing to save. */
    data object Idle : SortFooter

    /** The same, on a collection with no étagère at all — where the instruction to drag stays written. */
    data object IdleWithoutShelves : SortFooter

    /** What saving would do — and, during a run, what is left of it. */
    data class Recap(val plan: SortWritePlan) : SortFooter

    /** What a settled run did: all landed, nothing to save, or the three-part account of a stop. */
    data class Report(val ledger: SortApplyLedger) : SortFooter

    companion object {
        /** [hasShelves] only separates the two idle readings. */
        fun of(plan: SortWritePlan, progress: SortApplyLedger?, hasShelves: Boolean): SortFooter = when {
            progress != null && progress.isFinished -> Report(progress)
            plan.hasPendingChanges -> Recap(plan)
            hasShelves -> Idle
            else -> IdleWithoutShelves
        }
    }
}
