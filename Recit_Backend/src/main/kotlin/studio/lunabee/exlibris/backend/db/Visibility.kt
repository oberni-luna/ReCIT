package studio.lunabee.exlibris.backend.db

import org.jetbrains.exposed.v1.core.Alias
import org.jetbrains.exposed.v1.core.Column
import org.jetbrains.exposed.v1.core.JoinType
import org.jetbrains.exposed.v1.core.Op
import org.jetbrains.exposed.v1.core.alias
import org.jetbrains.exposed.v1.core.and
import org.jetbrains.exposed.v1.core.anyFrom
import org.jetbrains.exposed.v1.core.concat
import org.jetbrains.exposed.v1.core.eq
import org.jetbrains.exposed.v1.core.exists
import org.jetbrains.exposed.v1.core.inList
import org.jetbrains.exposed.v1.core.or
import org.jetbrains.exposed.v1.core.stringLiteral
import org.jetbrains.exposed.v1.core.stringParam
import org.jetbrains.exposed.v1.jdbc.select
import studio.lunabee.exlibris.backend.groups.GroupRole
import studio.lunabee.exlibris.backend.relations.RelationStatus

/**
 * inventaire.io's visibility keys, and its `filterVisibleDocs` as a condition on any table holding an owner and a
 * visibility — books, étagères, and the lists of #74. A document is seen by its owner; with `public` by anyone,
 * signed in or not; with `friends` by the owner's accepted friends; with `groups` by whoever is admin or member of a
 * group the owner is admin or member of; with `group:<id>` by that group's admins and members.
 */
object Visibility {
    const val PUBLIC: String = "public"
    const val FRIENDS: String = "friends"
    const val GROUPS: String = "groups"
    const val GROUP_PREFIX: String = "group:"

    private val inGroup: List<String> = GroupRole.entries.filter { it.isInGroup }.map { it.storedName }

    fun visibleTo(
        viewerId: String?,
        owner: Column<String>,
        visibility: Column<List<String>>,
    ): Op<Boolean> {
        val isPublic: Op<Boolean> = holds(visibility, PUBLIC)
        if (viewerId == null) return isPublic
        return (owner eq viewerId) or
            isPublic or
            (holds(visibility, FRIENDS) and areFriends(owner, viewerId)) or
            (holds(visibility, GROUPS) and shareAGroup(owner, viewerId)) or
            namesAGroupOf(visibility, viewerId)
    }

    /** Whether [visibility] holds one of [keys]: a group's inventory is read through its own keys alone. */
    fun holdsAnyOf(
        visibility: Column<List<String>>,
        keys: List<String>,
    ): Op<Boolean> = keys.map { holds(visibility, it) }.reduceOrNull { all, next -> all or next } ?: Op.FALSE

    private fun holds(
        visibility: Column<List<String>>,
        key: String,
    ): Op<Boolean> = stringParam(key) eq anyFrom(visibility)

    private fun areFriends(
        owner: Column<String>,
        viewerId: String,
    ): Op<Boolean> =
        exists(
            RelationsTable
                .select(RelationsTable.userA)
                .where {
                    (RelationsTable.status eq RelationStatus.FRIENDS.storedName) and
                        (
                            ((RelationsTable.userA eq owner) and (RelationsTable.userB eq viewerId)) or
                                ((RelationsTable.userA eq viewerId) and (RelationsTable.userB eq owner))
                        )
                },
        )

    private fun shareAGroup(
        owner: Column<String>,
        viewerId: String,
    ): Op<Boolean> {
        val viewers: Alias<GroupMembershipsTable> = GroupMembershipsTable.alias("viewer_membership")
        val owners: Alias<GroupMembershipsTable> = GroupMembershipsTable.alias("owner_membership")
        return exists(
            viewers
                .join(
                    owners,
                    JoinType.INNER,
                    viewers[GroupMembershipsTable.groupId],
                    owners[GroupMembershipsTable.groupId],
                ).select(viewers[GroupMembershipsTable.groupId])
                .where {
                    (viewers[GroupMembershipsTable.userId] eq viewerId) and
                        (viewers[GroupMembershipsTable.role] inList inGroup) and
                        (owners[GroupMembershipsTable.userId] eq owner) and
                        (owners[GroupMembershipsTable.role] inList inGroup)
                },
        )
    }

    private fun namesAGroupOf(
        visibility: Column<List<String>>,
        viewerId: String,
    ): Op<Boolean> =
        exists(
            GroupMembershipsTable
                .select(GroupMembershipsTable.groupId)
                .where {
                    (GroupMembershipsTable.userId eq viewerId) and
                        (GroupMembershipsTable.role inList inGroup) and
                        (concat(stringLiteral(GROUP_PREFIX), GroupMembershipsTable.groupId) eq anyFrom(visibility))
                },
        )
}
