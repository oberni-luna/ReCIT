package studio.lunabee.exlibris.backend.relations

import io.ktor.http.HttpStatusCode
import studio.lunabee.exlibris.backend.db.DocumentId
import studio.lunabee.exlibris.backend.plugins.ApiException
import java.time.Clock

/** inventaire.io's `controllers/relations`: the four lists, and the five actions that move a pair between them. */
class RelationsService(
    private val repository: RelationsRepository,
    private val clock: Clock,
) {
    /** `GET /api/relations`. A session naming an account that is gone is refused like no session. */
    suspend fun relations(userId: String): UserRelations {
        if (!repository.userExists(userId)) throw ApiException.unauthorized()
        val byRelation: Map<UserRelation, List<String>> =
            repository
                .statusesOf(userId)
                .entries
                .groupBy({ (otherId, status) -> UserRelation.of(userId, otherId, status) }, { it.key })
                .mapValues { (_, ids) -> ids.sorted() }
        val friends: List<String> = byRelation[UserRelation.FRIENDS].orEmpty()
        return UserRelations(
            friends = friends,
            userRequested = byRelation[UserRelation.USER_REQUESTED].orEmpty(),
            otherRequested = byRelation[UserRelation.OTHER_REQUESTED].orEmpty(),
            network = friends,
        )
    }

    /** The readers [userId] is friends with: who may see the `network` part of their snapshot, and theirs. */
    suspend fun friendIds(userId: String): Set<String> =
        repository
            .statusesOf(userId)
            .filterValues { it == RelationStatus.FRIENDS }
            .keys

    /**
     * `POST /api/relations/<action>` with `{"user": otherId}`. Only a request checks that the other exists, as on
     * inventaire.io: any other action on someone unknown has no relation to change.
     */
    suspend fun act(
        action: RelationAction,
        userId: String,
        otherId: String,
    ) {
        val refusal: ApiException? =
            when {
                !DocumentId.isValid(otherId) -> {
                    ApiException.invalidParameter("user", otherId)
                }

                otherId == userId -> {
                    ApiException(
                        HttpStatusCode.BadRequest,
                        "cant create relation between identical ids",
                    )
                }

                !repository.userExists(userId) -> {
                    ApiException.unauthorized()
                }

                else -> {
                    null
                }
            }
        refusal?.let { throw it }
        if (repository.userExists(otherId)) {
            repository.transition(userId, otherId, clock.millis(), action::next)
        } else if (action == RelationAction.REQUEST) {
            throw ApiException(HttpStatusCode.NotFound, "user not found")
        }
    }
}
