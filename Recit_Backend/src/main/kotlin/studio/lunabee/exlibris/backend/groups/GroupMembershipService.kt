package studio.lunabee.exlibris.backend.groups

import io.ktor.http.HttpStatusCode
import studio.lunabee.exlibris.backend.db.DocumentId
import studio.lunabee.exlibris.backend.images.ImagesService
import studio.lunabee.exlibris.backend.plugins.ApiException
import java.time.Clock

/**
 * The membership actions, inventaire.io's `members_actions.ts`, and leaving every group when an account goes. A group
 * ends with its last admin, and with it its picture, unless another group shares the file.
 */
class GroupMembershipService(
    private val repository: GroupsRepository,
    private val images: ImagesService,
    private val clock: Clock,
) {
    /** `PUT /api/groups/<action>` with `{group, user?}`; [targetId] only for the actions about someone else. */
    suspend fun act(
        action: GroupMembershipAction,
        actorId: String,
        groupId: String,
        targetId: String?,
    ) {
        val refusal: ApiException? =
            when {
                !DocumentId.isValid(groupId) -> {
                    ApiException.invalidParameter("group", groupId)
                }

                targetId != null && !DocumentId.isValid(targetId) -> {
                    ApiException.invalidParameter("user", targetId)
                }

                !repository.userExists(actorId) -> {
                    ApiException.unauthorized()
                }

                // Only an invitation names someone who may not exist: every other target already holds a membership.
                action == GroupMembershipAction.INVITE && !repository.userExists(requireNotNull(targetId)) -> {
                    ApiException(HttpStatusCode.NotFound, "user not found")
                }

                else -> {
                    null
                }
            }
        refusal?.let { throw it }
        val transition: GroupTransition =
            repository.transition(groupId, clock.millis()) { group ->
                MembershipRights.check(action, group, actorId, targetId)
                MembershipMoves.change(action, group, actorId, targetId)
            } ?: throw notFound()
        release(transition)
    }

    /** Every group [userId] is named in, left before their account is deleted. */
    suspend fun leaveAll(userId: String) {
        repository.groupsOf(userId, GroupRole.entries.toSet()).forEach { named ->
            repository
                .transition(named.id, clock.millis()) { group -> MembershipMoves.departure(group, userId) }
                ?.let { release(it) }
        }
    }

    private suspend fun release(transition: GroupTransition) {
        if (transition is GroupTransition.Ended) transition.picture?.let { images.releasePicture(it) }
    }

    companion object {
        /** What inventaire.io answers for a group id CouchDB does not hold, its own words passed on. */
        fun notFound(): ApiException = ApiException(HttpStatusCode.NotFound, "not_found: missing")
    }
}
