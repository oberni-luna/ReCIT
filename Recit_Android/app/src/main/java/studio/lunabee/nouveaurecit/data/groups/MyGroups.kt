package studio.lunabee.nouveaurecit.data.groups

import java.text.Collator

/**
 * `MyGroups`: my groups sorted by where I stand in each — what the Groupes segment lists, section
 * by section, and what the Réseau tab's badge counts.
 *
 * A value built from values, so the sorting rule is the same for every screen that needs it, and
 * testable without a repository. A group where I hold no role, or that I declined, is in no section.
 */
data class MyGroups(
    /** Invitations waiting on my answer. */
    val invitations: List<ReaderGroup>,
    /** The groups I belong to, as an admin or a member. */
    val mine: List<ReaderGroup>,
    /** The requests to join I sent, waiting on an admin. */
    val sentRequests: List<ReaderGroup>,
    /** The requests to join waiting on me, in the groups I administer. */
    val requestsToReview: Int,
) {
    /** Everything in the Groupes segment that waits on an answer from me — what the badge adds to the friends'. */
    val pendingCount: Int get() = invitations.size + requestsToReview

    /** No section has anything to show. */
    val isEmpty: Boolean get() = invitations.isEmpty() && mine.isEmpty() && sentRequests.isEmpty()

    companion object {
        val Empty: MyGroups = MyGroups(emptyList(), emptyList(), emptyList(), 0)

        /**
         * @param groups Every group known, in any order.
         * @param me The signed-in reader, or `null` before anyone is: then no group is mine.
         */
        fun of(groups: Collection<ReaderGroup>, me: String?): MyGroups {
            val collator: Collator = Collator.getInstance()
            val sorted: List<ReaderGroup> = groups.sortedWith { lhs, rhs ->
                collator.compare(lhs.name, rhs.name).takeIf { it != 0 } ?: lhs.id.compareTo(rhs.id)
            }
            val mine: List<ReaderGroup> = sorted.filter { it.role(of = me)?.belongs == true }
            return MyGroups(
                invitations = sorted.filter { it.role(of = me) == GroupRole.Invited },
                mine = mine,
                sentRequests = sorted.filter { it.role(of = me) == GroupRole.Requested },
                requestsToReview = mine.sumOf { it.requestsToReview(by = me) },
            )
        }
    }
}
