package studio.lunabee.exlibris.backend.groups

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.jetbrains.exposed.v1.core.Op
import org.jetbrains.exposed.v1.core.ResultRow
import org.jetbrains.exposed.v1.core.SortOrder
import org.jetbrains.exposed.v1.core.and
import org.jetbrains.exposed.v1.core.eq
import org.jetbrains.exposed.v1.core.inList
import org.jetbrains.exposed.v1.core.neq
import org.jetbrains.exposed.v1.core.plus
import org.jetbrains.exposed.v1.core.statements.UpdateStatement
import org.jetbrains.exposed.v1.exceptions.ExposedSQLException
import org.jetbrains.exposed.v1.jdbc.Database
import org.jetbrains.exposed.v1.jdbc.deleteWhere
import org.jetbrains.exposed.v1.jdbc.insert
import org.jetbrains.exposed.v1.jdbc.select
import org.jetbrains.exposed.v1.jdbc.selectAll
import org.jetbrains.exposed.v1.jdbc.transactions.transaction
import org.jetbrains.exposed.v1.jdbc.update
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import studio.lunabee.exlibris.backend.db.GroupMembershipsTable
import studio.lunabee.exlibris.backend.db.GroupsTable
import studio.lunabee.exlibris.backend.db.UsersTable
import studio.lunabee.exlibris.backend.users.UserPosition

class GroupsRepository(
    private val database: Database,
) {
    suspend fun userExists(userId: String): Boolean =
        withContext(Dispatchers.IO) {
            transaction(database) {
                !UsersTable
                    .selectAll()
                    .where { UsersTable.id eq userId }
                    .empty()
            }
        }

    suspend fun findById(groupId: String): GroupRecord? =
        withContext(Dispatchers.IO) {
            transaction(database) { records(listOf(groupId)).singleOrNull() }
        }

    /** The groups where [userId] holds one of [roles], the oldest first. */
    suspend fun groupsOf(
        userId: String,
        roles: Set<GroupRole>,
    ): List<GroupRecord> =
        withContext(Dispatchers.IO) {
            transaction(database) {
                val ids: List<String> =
                    GroupMembershipsTable
                        .select(GroupMembershipsTable.groupId)
                        .where {
                            (GroupMembershipsTable.userId eq userId) and
                                (GroupMembershipsTable.role inList roles.map { it.storedName })
                        }.map { it[GroupMembershipsTable.groupId] }
                records(ids).sortedBy { it.created }
            }
        }

    /** Whether a group other than [exceptId] holds [slug]. */
    suspend fun isSlugTaken(
        slug: String,
        exceptId: String?,
    ): Boolean =
        withContext(Dispatchers.IO) {
            transaction(database) {
                val bySlug: Op<Boolean> = GroupsTable.slug eq slug
                !GroupsTable
                    .selectAll()
                    .where { exceptId?.let { bySlug and (GroupsTable.id neq it) } ?: bySlug }
                    .empty()
            }
        }

    /** The group and its memberships; `false` when its slug was taken in the meantime. */
    suspend fun insert(group: GroupRecord): Boolean =
        writing {
            GroupsTable.insert {
                it[id] = group.id
                it[version] = group.version
                it[name] = group.name
                it[slug] = group.slug
                it[description] = group.description
                it[searchable] = group.searchable
                it[open] = group.open
                it[picture] = group.picture
                it[latitude] = group.position?.latitude
                it[longitude] = group.position?.longitude
                it[creator] = group.creator
                it[created] = group.created
            }
            group.memberships.forEach { membership ->
                GroupMembershipsTable.insert {
                    it[groupId] = group.id
                    it[userId] = membership.userId
                    it[role] = membership.role.storedName
                    it[invitor] = membership.invitor
                    it[timestamp] = membership.timestamp
                    it[moved] = membership.timestamp
                }
            }
        }

    /** Writes [setting], with [slug] for a new name, and moves the revision; `false` when the slug was taken. */
    suspend fun write(
        groupId: String,
        setting: GroupSetting,
        slug: String?,
    ): Boolean =
        writing {
            GroupsTable.update({ GroupsTable.id eq groupId }) {
                it[version] = version + 1
                slug?.let { newSlug -> it[GroupsTable.slug] = newSlug }
                it.write(setting)
            }
        }

    /**
     * Applies what [change] decides from the group as it stands, the group's row locked meanwhile, so that two
     * actions on one group never decide from the same state. A group left without an admin is deleted with its
     * memberships. `null` when there is no such group; whatever [change] throws leaves the group as it was.
     */
    suspend fun transition(
        groupId: String,
        now: Long,
        change: (GroupRecord) -> List<MembershipChange>,
    ): GroupTransition? =
        withContext(Dispatchers.IO) {
            transaction(database) {
                records(listOf(groupId), forUpdate = true).singleOrNull()?.let { group ->
                    change(group).forEach { apply(groupId, it, now) }
                    val hasAdmin: Boolean =
                        !GroupMembershipsTable
                            .selectAll()
                            .where {
                                (GroupMembershipsTable.groupId eq groupId) and
                                    (GroupMembershipsTable.role eq GroupRole.ADMIN.storedName)
                            }.empty()
                    if (hasAdmin) {
                        GroupsTable.update({ GroupsTable.id eq groupId }) { it[version] = version + 1 }
                        GroupTransition.Kept
                    } else {
                        GroupsTable.deleteWhere { id eq groupId }
                        GroupTransition.Ended(group.picture)
                    }
                }
            }
        }

    private fun records(
        groupIds: List<String>,
        forUpdate: Boolean = false,
    ): List<GroupRecord> {
        val groups: List<ResultRow> =
            GroupsTable
                .selectAll()
                .where { GroupsTable.id inList groupIds }
                .let { if (forUpdate) it.forUpdate() else it }
                .toList()
        val memberships: Map<String, List<GroupMembership>> =
            GroupMembershipsTable
                .selectAll()
                .where { GroupMembershipsTable.groupId inList groups.map { it[GroupsTable.id] } }
                // Readers moved at once — members promoted together — by seniority.
                .orderBy(
                    GroupMembershipsTable.moved to SortOrder.ASC,
                    GroupMembershipsTable.timestamp to SortOrder.ASC,
                    GroupMembershipsTable.userId to SortOrder.ASC,
                ).groupBy({ it[GroupMembershipsTable.groupId] }, { it.toMembership() })
        return groups.map { it.toGroupRecord(memberships[it[GroupsTable.id]].orEmpty()) }
    }

    private fun apply(
        groupId: String,
        change: MembershipChange,
        now: Long,
    ) {
        val row: Op<Boolean> =
            (GroupMembershipsTable.groupId eq groupId) and (GroupMembershipsTable.userId eq change.userId)
        when (change) {
            is MembershipChange.Add -> {
                GroupMembershipsTable.insert {
                    it[GroupMembershipsTable.groupId] = groupId
                    it[userId] = change.userId
                    it[role] = change.role.storedName
                    it[invitor] = change.invitor
                    it[timestamp] = now
                    it[moved] = now
                }
            }

            is MembershipChange.Move -> {
                GroupMembershipsTable.update({ row }) {
                    it[role] = change.role.storedName
                    it[moved] = now
                    change.invitor?.let { invitorId -> it[invitor] = invitorId }
                }
            }

            is MembershipChange.Remove -> {
                GroupMembershipsTable.deleteWhere { row }
            }
        }
    }

    /** Runs [block] in a transaction; `false` when a unique index — the slug's — said no. */
    private suspend fun writing(block: () -> Unit): Boolean =
        withContext(Dispatchers.IO) {
            try {
                transaction(database) { block() }
                true
            } catch (error: ExposedSQLException) {
                if (error.sqlState != UNIQUE_VIOLATION) throw error
                logger.info("A group write lost a race on its slug: {}", error.message)
                false
            }
        }

    private companion object {
        /** Postgres's `unique_violation`. */
        const val UNIQUE_VIOLATION: String = "23505"

        val logger: Logger = LoggerFactory.getLogger(GroupsRepository::class.java)
    }
}

private fun UpdateStatement.write(setting: GroupSetting) {
    when (setting) {
        is GroupSetting.Name -> {
            this[GroupsTable.name] = setting.value
        }

        is GroupSetting.Description -> {
            this[GroupsTable.description] = setting.value
        }

        is GroupSetting.Searchable -> {
            this[GroupsTable.searchable] = setting.value
        }

        is GroupSetting.Open -> {
            this[GroupsTable.open] = setting.value
        }

        is GroupSetting.Picture -> {
            this[GroupsTable.picture] = setting.path
        }

        is GroupSetting.Position -> {
            this[GroupsTable.latitude] = setting.position?.latitude
            this[GroupsTable.longitude] = setting.position?.longitude
        }
    }
}

private fun ResultRow.toMembership(): GroupMembership =
    GroupMembership(
        userId = this[GroupMembershipsTable.userId],
        role = GroupRole.of(this[GroupMembershipsTable.role]),
        invitor = this[GroupMembershipsTable.invitor],
        timestamp = this[GroupMembershipsTable.timestamp],
    )

private fun ResultRow.toGroupRecord(memberships: List<GroupMembership>): GroupRecord {
    val latitude: Double? = this[GroupsTable.latitude]
    val longitude: Double? = this[GroupsTable.longitude]
    return GroupRecord(
        id = this[GroupsTable.id],
        version = this[GroupsTable.version],
        name = this[GroupsTable.name],
        slug = this[GroupsTable.slug],
        description = this[GroupsTable.description],
        searchable = this[GroupsTable.searchable],
        open = this[GroupsTable.open],
        picture = this[GroupsTable.picture],
        position = if (latitude != null && longitude != null) UserPosition(latitude, longitude) else null,
        creator = this[GroupsTable.creator],
        created = this[GroupsTable.created],
        memberships = memberships,
    )
}
